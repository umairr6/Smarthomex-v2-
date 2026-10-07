import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../core/responsive.dart';
import '../../models/timer_model.dart';
import '../../providers/device_provider.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/timer_manager.dart';

class TimersScreen extends StatefulWidget {
  const TimersScreen({super.key});

  @override
  State<TimersScreen> createState() => _TimersScreenState();
}

class _TimersScreenState extends State<TimersScreen> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  Timer? _uiTimer;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await TimerManager.instance.initialize();
      await TimerManager.instance.rescheduleAll();
      await _loadTimers();
    });
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadTimers() async {
    final timers = await _storageService.loadTimers();
    if (!mounted) return;
    context.read<DeviceProvider>().loadSavedTimers(timers);
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    super.dispose();
  }

  Future<bool> _ensureExactAlarmPermission() async {
    try {
      var status = await Permission.scheduleExactAlarm.status;
      if (status.isGranted) return true;
      status = await Permission.scheduleExactAlarm.request();
      return status.isGranted;
    } catch (_) {
      return true;
    }
  }

  Future<void> _showCreateTimerDialog() async {
    final provider = context.read<DeviceProvider>();
    if (provider.device == null) {
      _showMessage('No ESP32 device connected.');
      return;
    }

    final relays = provider.relays;
    if (relays.isEmpty) {
      _showMessage('No switches found.');
      return;
    }

    int selectedRelayId = relays.first.id;
    int selectedDuration = 1800;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: SmartHomeColors.surfaceElevated,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'New Timer',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedRelayId,
                    dropdownColor: SmartHomeColors.surfaceElevated,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Select Switch'),
                    items: relays.map((relay) {
                      return DropdownMenuItem<int>(
                        value: relay.id,
                        child: Row(
                          children: [
                            Icon(
                              _getRelayIcon(relay.icon),
                              color: SmartHomeColors.gold,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(relay.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedRelayId = value);
                      }
                    },
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<int>(
                    value: selectedDuration,
                    dropdownColor: SmartHomeColors.surfaceElevated,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Duration'),
                    items: const [
                      DropdownMenuItem(value: 60, child: Text('1 minute')),
                      DropdownMenuItem(value: 300, child: Text('5 minutes')),
                      DropdownMenuItem(value: 600, child: Text('10 minutes')),
                      DropdownMenuItem(value: 1800, child: Text('30 minutes')),
                      DropdownMenuItem(value: 3600, child: Text('1 hour')),
                      DropdownMenuItem(value: 7200, child: Text('2 hours')),
                      DropdownMenuItem(value: 10800, child: Text('3 hours')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedDuration = value);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: SmartHomeColors.gold,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await _createTimer(selectedRelayId, selectedDuration);
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

  Future<void> _createTimer(int relayId, int durationSeconds) async {
    if (_working) return;
    setState(() => _working = true);

    try {
      final provider = context.read<DeviceProvider>();
      final device = provider.device;
      final relay = provider.getRelay(relayId);

      if (device == null || relay == null) {
        _showMessage('Device or switch not available.');
        return;
      }

      final permission = await _ensureExactAlarmPermission();
      if (!permission) {
        _showMessage('Exact alarm permission is required for timers.');
        return;
      }

      final success = await _apiService.turnRelayOn(device.ipAddress, relayId);
      if (!success) {
        _showMessage('Could not turn on ${relay.name}.');
        return;
      }

      provider.updateRelayState(relayId, true);

      final timer = RelayTimer(
        id: '${DateTime.now().millisecondsSinceEpoch}_$relayId',
        relayId: relayId,
        relayName: relay.name,
        durationSeconds: durationSeconds,
        endTime: DateTime.now().add(Duration(seconds: durationSeconds)),
      );

      provider.addTimer(timer);
      await _storageService.saveTimers(provider.timers);

      final scheduled = await TimerManager.instance.scheduleOne(timer);
      if (!scheduled) {
        provider.removeTimer(timer.id);
        await _storageService.saveTimers(provider.timers);
        _showMessage('Could not schedule the timer.');
        return;
      }

      _showMessage('${relay.name} timer started.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _cancelTimer(RelayTimer timer) async {
    if (_working) return;
    setState(() => _working = true);

    try {
      final provider = context.read<DeviceProvider>();
      final device = provider.device;
      if (device == null) return;

      await TimerManager.instance.delete(timer);

      final success = await _apiService.turnRelayOff(
        device.ipAddress,
        timer.relayId,
      );

      if (!success) {
        await TimerManager.instance.scheduleOne(timer);
        _showMessage('Could not turn off ${timer.relayName}.');
        return;
      }

      provider.updateRelayState(timer.relayId, false);
      provider.removeTimer(timer.id);
      await _storageService.saveTimers(provider.timers);
      _showMessage('${timer.relayName} timer cancelled.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  String _formatRemaining(DateTime endTime) {
    final seconds = endTime.difference(DateTime.now()).inSeconds;
    if (seconds <= 0) return '00:00:00';

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  IconData _getRelayIcon(String icon) {
    switch (icon) {
      case 'fan':
        return Icons.air_rounded;
      case 'socket':
        return Icons.power_rounded;
      default:
        return Icons.lightbulb_rounded;
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: SmartHomeColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: SmartHomeColors.gold),
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final horizontal = SmartHomeResponsive.horizontalPadding(context);

    return Scaffold(
      backgroundColor: SmartHomeColors.background,
      appBar: AppBar(
        backgroundColor: SmartHomeColors.background,
        elevation: 0,
        title: const Text(
          'Timers',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _working ? null : _showCreateTimerDialog,
        backgroundColor: SmartHomeColors.gold,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('New Timer'),
      ),
      body: Consumer<DeviceProvider>(
        builder: (context, provider, _) {
          final timers = provider.timers;

          if (timers.isEmpty) return _emptyState();

          return ListView.builder(
            padding: EdgeInsets.fromLTRB(horizontal, 18, horizontal, 110),
            itemCount: timers.length,
            itemBuilder: (context, index) {
              return _timerCard(timers[index], provider);
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
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: SmartHomeColors.gold.withOpacity(.10),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: SmartHomeColors.borderGold),
              ),
              child: const Icon(
                Icons.timer_outlined,
                size: 44,
                color: SmartHomeColors.gold,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Active Timers',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Turn on a switch and let SmartHomeX turn it off automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, height: 1.5),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _working ? null : _showCreateTimerDialog,
              style: FilledButton.styleFrom(
                backgroundColor: SmartHomeColors.gold,
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.add_alarm_rounded),
              label: const Text('Create Timer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timerCard(RelayTimer timer, DeviceProvider provider) {
    final relay = provider.getRelay(timer.relayId);
    final icon = relay == null ? Icons.timer_rounded : _getRelayIcon(relay.icon);
    final remaining = timer.endTime.difference(DateTime.now()).inSeconds;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SmartHomeColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SmartHomeColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: SmartHomeColors.gold.withOpacity(.11),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: SmartHomeColors.gold, size: 27),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timer.relayName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Turns OFF when timer ends',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _working ? null : () => _cancelTimer(timer),
                tooltip: 'Cancel Timer',
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 17),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(.22),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Column(
              children: [
                const Text(
                  'TIME REMAINING',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  remaining <= 0 ? '00:00:00' : _formatRemaining(timer.endTime),
                  style: const TextStyle(
                    color: SmartHomeColors.goldLight,
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
    );
  }
}
