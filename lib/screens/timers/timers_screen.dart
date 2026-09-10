import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/timer_model.dart';
import '../../providers/device_provider.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';

class TimersScreen extends StatefulWidget {
  const TimersScreen({super.key});

  @override
  State<TimersScreen> createState() => _TimersScreenState();
}

class _TimersScreenState extends State<TimersScreen> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTimers();
    });

    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;

        final provider = context.read<DeviceProvider>();
        final now = DateTime.now();

        final expiredTimers = provider.timers
            .where((timer) => !timer.endTime.isAfter(now))
            .toList();

        if (expiredTimers.isNotEmpty) {
          _handleExpiredTimers(expiredTimers);
        }
      },
    );
  }

  Future<void> _loadTimers() async {
    final savedTimers = await _storageService.loadTimers();

    if (!mounted) return;

    context.read<DeviceProvider>().loadSavedTimers(savedTimers);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  // =========================
  // CREATE TIMER
  // =========================

  Future<void> _showCreateTimerDialog() async {
    final provider = context.read<DeviceProvider>();

    if (provider.device == null) {
      _showMessage('No ESP32 device connected.');
      return;
    }

    int selectedRelayId = 1;
    int selectedDuration = 1800;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final relays = provider.relays;

            return AlertDialog(
              backgroundColor: const Color(0xff1E293B),
              title: const Text(
                'Set Timer',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedRelayId,
                    decoration: const InputDecoration(
                      labelText: 'Select Switch',
                      border: OutlineInputBorder(),
                    ),
                    items: relays.map((relay) {
                      return DropdownMenuItem<int>(
                        value: relay.id,
                        child: Row(
                          children: [
                            Icon(
                              _getRelayIcon(relay.icon),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(relay.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        selectedRelayId = value;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  DropdownButtonFormField<int>(
                    value: selectedDuration,
                    decoration: const InputDecoration(
                      labelText: 'Duration',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 300,
                        child: Text('5 minutes'),
                      ),
                      DropdownMenuItem(
                        value: 600,
                        child: Text('10 minutes'),
                      ),
                      DropdownMenuItem(
                        value: 1800,
                        child: Text('30 minutes'),
                      ),
                      DropdownMenuItem(
                        value: 3600,
                        child: Text('1 hour'),
                      ),
                      DropdownMenuItem(
                        value: 7200,
                        child: Text('2 hours'),
                      ),
                      DropdownMenuItem(
                        value: 10800,
                        child: Text('3 hours'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        selectedDuration = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);

                    await _createTimer(
                      selectedRelayId,
                      selectedDuration,
                    );
                  },
                  child: const Text('Start Timer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createTimer(
    int relayId,
    int durationSeconds,
  ) async {
    final provider = context.read<DeviceProvider>();
    final device = provider.device;

    if (device == null) return;

    final relay = provider.getRelay(relayId);

    if (relay == null) return;

    // First turn the relay ON.
    final success = await _apiService.turnRelayOn(
      device.ipAddress,
      relayId,
    );

    if (!success) {
      _showMessage(
        'Could not turn on ${relay.name}.',
      );
      return;
    }

    provider.updateRelayState(
      relayId,
      true,
    );

    final timer = RelayTimer(
      id: '${DateTime.now().millisecondsSinceEpoch}_$relayId',
      relayId: relayId,
      relayName: relay.name,
      durationSeconds: durationSeconds,
      endTime: DateTime.now().add(
        Duration(seconds: durationSeconds),
      ),
    );

    provider.addTimer(timer);

    await _saveCurrentTimers();

    _showMessage(
      '${relay.name} timer started.',
    );
  }

  // =========================
  // EXPIRED TIMER
  // =========================

  Future<void> _handleExpiredTimers(
    List<RelayTimer> expiredTimers,
  ) async {
    final provider = context.read<DeviceProvider>();
    final device = provider.device;

    if (device == null) return;

    for (final timer in expiredTimers) {
      final success = await _apiService.turnRelayOff(
        device.ipAddress,
        timer.relayId,
      );

      if (success) {
        provider.updateRelayState(
          timer.relayId,
          false,
        );
      }

      provider.removeTimer(timer.id);
    }

    await _saveCurrentTimers();
  }

  // =========================
  // CANCEL TIMER
  // =========================

  Future<void> _cancelTimer(
    RelayTimer timer,
  ) async {
    final provider = context.read<DeviceProvider>();
    final device = provider.device;

    if (device == null) return;

    final success = await _apiService.turnRelayOff(
      device.ipAddress,
      timer.relayId,
    );

    if (!success) {
      _showMessage(
        'Could not turn off ${timer.relayName}.',
      );
      return;
    }

    provider.updateRelayState(
      timer.relayId,
      false,
    );

    provider.removeTimer(
      timer.id,
    );

    await _saveCurrentTimers();

    _showMessage(
      '${timer.relayName} timer cancelled.',
    );
  }

  // =========================
  // STORAGE
  // =========================

  Future<void> _saveCurrentTimers() async {
    final provider = context.read<DeviceProvider>();

    await _storageService.saveTimers(
      provider.timers,
    );
  }

  // =========================
  // COUNTDOWN
  // =========================

  String _formatRemaining(
    DateTime endTime,
  ) {
    final difference = endTime.difference(
      DateTime.now(),
    );

    if (difference.isNegative) {
      return '00:00:00';
    }

    final hours = difference.inHours
        .toString()
        .padLeft(2, '0');

    final minutes = (difference.inMinutes % 60)
        .toString()
        .padLeft(2, '0');

    final seconds = (difference.inSeconds % 60)
        .toString()
        .padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  // =========================
  // ICON
  // =========================

  IconData _getRelayIcon(String icon) {
    switch (icon) {
      case 'fan':
        return Icons.air;
      case 'socket':
        return Icons.power;
      case 'light':
      default:
        return Icons.lightbulb_outline;
    }
  }

  // =========================
  // MESSAGE
  // =========================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // =========================
  // UI
  // =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Timers',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTimerDialog,
        icon: const Icon(Icons.add_alarm),
        label: const Text('New Timer'),
      ),

      body: Consumer<DeviceProvider>(
        builder: (context, provider, child) {
          final timers = provider.timers;

          if (timers.isEmpty) {
            return _emptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              100,
            ),
            itemCount: timers.length,
            itemBuilder: (context, index) {
              final timer = timers[index];

              return _timerCard(
                timer,
                provider,
              );
            },
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xff1E293B),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.timer_outlined,
                size: 45,
                color: Color(0xff34B7F1),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'No Active Timers',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Create a timer to automatically turn a switch off after a selected duration.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _showCreateTimerDialog,
              icon: const Icon(Icons.add_alarm),
              label: const Text('Create Timer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timerCard(
    RelayTimer timer,
    DeviceProvider provider,
  ) {
    final relay = provider.getRelay(
      timer.relayId,
    );

    final icon = relay == null
        ? Icons.timer
        : _getRelayIcon(relay.icon);

    return Card(
      color: const Color(0xff1E293B),
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xff34B7F1)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xff34B7F1),
                    size: 27,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        timer.relayName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Turns OFF when timer ends',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white
                              .withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  onPressed: () {
                    _cancelTimer(timer);
                  },
                  icon: const Icon(
                    Icons.close,
                  ),
                  tooltip: 'Cancel Timer',
                ),
              ],
            ),

            const SizedBox(height: 18),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(
                  alpha: 0.15,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'TIME REMAINING',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    _formatRemaining(
                      timer.endTime,
                    ),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}