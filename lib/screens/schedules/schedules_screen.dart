import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/schedule_model.dart';
import '../../providers/device_provider.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() =>
      _SchedulesScreenState();
}

class _SchedulesScreenState
    extends State<SchedulesScreen> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService =
      StorageService();

  Timer? _scheduleTimer;

  String _lastExecutedKey = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSchedules();
    });

    _scheduleTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _checkSchedules(),
    );
  }

  @override
  void dispose() {
    _scheduleTimer?.cancel();
    super.dispose();
  }

  // =========================
  // LOAD
  // =========================

  Future<void> _loadSchedules() async {
    final schedules =
        await _storageService.loadSchedules();

    if (!mounted) return;

    context
        .read<DeviceProvider>()
        .loadSavedSchedules(schedules);
  }

  // =========================
  // CHECK SCHEDULES
  // =========================

  Future<void> _checkSchedules() async {
    if (!mounted) return;

    final provider =
        context.read<DeviceProvider>();

    final device = provider.device;

    if (device == null || !provider.isOnline) {
      return;
    }

    final now = DateTime.now();

    for (final schedule in provider.schedules) {
      if (!schedule.enabled) continue;

      final weekday = now.weekday;

      if (!schedule.weekdays.contains(weekday)) {
        continue;
      }

      if (schedule.hour != now.hour ||
          schedule.minute != now.minute) {
        continue;
      }

      final executionKey =
          '${schedule.id}_${now.year}_${now.month}_${now.day}_${now.hour}_${now.minute}';

      if (_lastExecutedKey == executionKey) {
        continue;
      }

      _lastExecutedKey = executionKey;

      await _executeSchedule(schedule);
    }
  }

  // =========================
  // EXECUTE
  // =========================

  Future<void> _executeSchedule(
    RelaySchedule schedule,
  ) async {
    final provider =
        context.read<DeviceProvider>();

    final device = provider.device;

    if (device == null) return;

    bool success;

    if (schedule.turnOn) {
      success = await _apiService.turnRelayOn(
        device.ipAddress,
        schedule.relayId,
      );
    } else {
      success = await _apiService.turnRelayOff(
        device.ipAddress,
        schedule.relayId,
      );
    }

    if (!mounted) return;

    if (success) {
      provider.updateRelayState(
        schedule.relayId,
        schedule.turnOn,
      );
    } else {
      provider.updateDeviceStatus(false);
    }
  }

  // =========================
  // CREATE
  // =========================

  Future<void> _showCreateScheduleDialog() async {
    final provider =
        context.read<DeviceProvider>();

    if (provider.device == null) {
      _showMessage(
        'No ESP32 device connected.',
      );
      return;
    }

    int selectedRelayId = 1;
    bool turnOn = true;

    TimeOfDay selectedTime =
        TimeOfDay.now();

    List<int> selectedDays = [
      1,
      2,
      3,
      4,
      5,
      6,
      7,
    ];

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              backgroundColor:
                  const Color(0xff1E293B),
              title: const Text(
                'Create Schedule',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    // RELAY
                    DropdownButtonFormField<int>(
                      value: selectedRelayId,
                      decoration:
                          const InputDecoration(
                        labelText: 'Select Switch',
                        border:
                            OutlineInputBorder(),
                      ),
                      items: provider.relays
                          .map(
                            (relay) =>
                                DropdownMenuItem<int>(
                              value: relay.id,
                              child: Text(
                                relay.name,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setDialogState(() {
                          selectedRelayId =
                              value;
                        });
                      },
                    ),

                    const SizedBox(height: 18),

                    // TIME
                    InkWell(
                      onTap: () async {
                        final picked =
                            await showTimePicker(
                          context: context,
                          initialTime:
                              selectedTime,
                        );

                        if (picked == null) {
                          return;
                        }

                        setDialogState(() {
                          selectedTime =
                              picked;
                        });
                      },
                      borderRadius:
                          BorderRadius.circular(
                        8,
                      ),
                      child: InputDecorator(
                        decoration:
                            const InputDecoration(
                          labelText: 'Time',
                          border:
                              OutlineInputBorder(),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Text(
                              selectedTime.format(
                                context,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ACTION
                    DropdownButtonFormField<bool>(
                      value: turnOn,
                      decoration:
                          const InputDecoration(
                        labelText: 'Action',
                        border:
                            OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: true,
                          child: Text(
                            'Turn ON',
                          ),
                        ),
                        DropdownMenuItem(
                          value: false,
                          child: Text(
                            'Turn OFF',
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setDialogState(() {
                          turnOn = value;
                        });
                      },
                    ),

                    const SizedBox(height: 18),

                    Align(
                      alignment:
                          Alignment.centerLeft,
                      child: Text(
                        'Repeat',
                        style: TextStyle(
                          color: Colors.white
                              .withValues(
                            alpha: 0.8,
                          ),
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _dayChip(
                          context,
                          'M',
                          1,
                          selectedDays,
                          setDialogState,
                        ),
                        _dayChip(
                          context,
                          'T',
                          2,
                          selectedDays,
                          setDialogState,
                        ),
                        _dayChip(
                          context,
                          'W',
                          3,
                          selectedDays,
                          setDialogState,
                        ),
                        _dayChip(
                          context,
                          'T',
                          4,
                          selectedDays,
                          setDialogState,
                        ),
                        _dayChip(
                          context,
                          'F',
                          5,
                          selectedDays,
                          setDialogState,
                        ),
                        _dayChip(
                          context,
                          'S',
                          6,
                          selectedDays,
                          setDialogState,
                        ),
                        _dayChip(
                          context,
                          'S',
                          7,
                          selectedDays,
                          setDialogState,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child: const Text(
                    'Cancel',
                  ),
                ),
                FilledButton(
                  onPressed:
                      selectedDays.isEmpty
                          ? null
                          : () async {
                              Navigator.pop(
                                dialogContext,
                              );

                              await _createSchedule(
                                relayId:
                                    selectedRelayId,
                                time:
                                    selectedTime,
                                turnOn:
                                    turnOn,
                                weekdays:
                                    selectedDays,
                              );
                            },
                  child: const Text(
                    'Save Schedule',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _dayChip(
    BuildContext context,
    String label,
    int day,
    List<int> selectedDays,
    StateSetter setDialogState,
  ) {
    final selected =
        selectedDays.contains(day);

    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (value) {
        setDialogState(() {
          if (value) {
            selectedDays.add(day);
          } else {
            selectedDays.remove(day);
          }

          selectedDays.sort();
        });
      },
    );
  }

  // =========================
  // SAVE NEW SCHEDULE
  // =========================

  Future<void> _createSchedule({
    required int relayId,
    required TimeOfDay time,
    required bool turnOn,
    required List<int> weekdays,
  }) async {
    final provider =
        context.read<DeviceProvider>();

    final relay =
        provider.getRelay(relayId);

    if (relay == null) return;

    final schedule = RelaySchedule(
      id: '${DateTime.now().millisecondsSinceEpoch}_$relayId',
      relayId: relayId,
      relayName: relay.name,
      hour: time.hour,
      minute: time.minute,
      weekdays: List<int>.from(
        weekdays,
      ),
      turnOn: turnOn,
      enabled: true,
    );

    provider.addSchedule(schedule);

    await _storageService.saveSchedules(
      provider.schedules,
    );

    _showMessage(
      'Schedule created for ${relay.name}.',
    );
  }

  // =========================
  // DELETE
  // =========================

  Future<void> _deleteSchedule(
    RelaySchedule schedule,
  ) async {
    final provider =
        context.read<DeviceProvider>();

    provider.removeSchedule(
      schedule.id,
    );

    await _storageService.saveSchedules(
      provider.schedules,
    );

    _showMessage(
      'Schedule deleted.',
    );
  }

  // =========================
  // ENABLE / DISABLE
  // =========================

  Future<void> _toggleSchedule(
    RelaySchedule schedule,
    bool enabled,
  ) async {
    final provider =
        context.read<DeviceProvider>();

    provider.toggleSchedule(
      schedule.id,
      enabled,
    );

    await _storageService.saveSchedules(
      provider.schedules,
    );
  }

  // =========================
  // FORMAT TIME
  // =========================

  String _formatTime(
    BuildContext context,
    RelaySchedule schedule,
  ) {
    final time = TimeOfDay(
      hour: schedule.hour,
      minute: schedule.minute,
    );

    return time.format(context);
  }

  // =========================
  // DAYS
  // =========================

  String _formatDays(
    RelaySchedule schedule,
  ) {
    if (schedule.weekdays.length == 7) {
      return 'Every day';
    }

    if (schedule.weekdays.length == 5 &&
        schedule.weekdays.every(
          (day) => day >= 1 && day <= 5,
        )) {
      return 'Weekdays';
    }

    if (schedule.weekdays.length == 2 &&
        schedule.weekdays.contains(6) &&
        schedule.weekdays.contains(7)) {
      return 'Weekends';
    }

    const names = [
      '',
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

    return schedule.weekdays
        .map((day) => names[day])
        .join(', ');
  }

  // =========================
  // MESSAGE
  // =========================

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
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
          'Schedules',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            _showCreateScheduleDialog,
        icon: const Icon(
          Icons.add_alarm,
        ),
        label: const Text(
          'New Schedule',
        ),
      ),
      body: Consumer<DeviceProvider>(
        builder: (
          context,
          provider,
          child,
        ) {
          if (provider.schedules.isEmpty) {
            return _emptyState();
          }

          return ListView.builder(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              100,
            ),
            itemCount:
                provider.schedules.length,
            itemBuilder:
                (context, index) {
              final schedule =
                  provider.schedules[index];

              return _scheduleCard(
                schedule,
              );
            },
          );
        },
      ),
    );
  }

  // =========================
  // EMPTY STATE
  // =========================

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration:
                  BoxDecoration(
                color:
                    const Color(0xff1E293B),
                borderRadius:
                    BorderRadius.circular(
                  28,
                ),
              ),
              child: const Icon(
                Icons.calendar_month_outlined,
                size: 45,
                color:
                    Color(0xff34B7F1),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'No Schedules',
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Create automatic ON or OFF schedules for your switches.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color: Colors.white
                    .withValues(
                  alpha: 0.65,
                ),
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed:
                  _showCreateScheduleDialog,
              icon: const Icon(
                Icons.add_alarm,
              ),
              label: const Text(
                'Create Schedule',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // SCHEDULE CARD
  // =========================

  Widget _scheduleCard(
    RelaySchedule schedule,
  ) {
    return Card(
      color:
          const Color(0xff1E293B),
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xff34B7F1,
                    ).withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                  child: Icon(
                    schedule.turnOn
                        ? Icons.power_settings_new
                        : Icons.power_off,
                    color:
                        const Color(
                      0xff34B7F1,
                    ),
                    size: 27,
                  ),
                ),

                const SizedBox(
                  width: 14,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule.relayName,
                        style:
                            const TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      Text(
                        schedule.turnOn
                            ? 'Turn ON'
                            : 'Turn OFF',
                        style:
                            TextStyle(
                          fontSize: 13,
                          color: schedule
                                  .turnOn
                              ? Colors.green
                              : Colors.orange,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                Switch(
                  value:
                      schedule.enabled,
                  onChanged: (value) {
                    _toggleSchedule(
                      schedule,
                      value,
                    );
                  },
                ),
              ],
            ),

            const SizedBox(
              height: 16,
            ),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(16),
              decoration:
                  BoxDecoration(
                color:
                    Colors.black.withValues(
                  alpha: 0.15,
                ),
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 20,
                    color:
                        Color(0xff34B7F1),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Text(
                    _formatTime(
                      context,
                      schedule,
                    ),
                    style:
                        const TextStyle(
                      fontSize: 24,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const Spacer(),

                  Text(
                    _formatDays(
                      schedule,
                    ),
                    style:
                        const TextStyle(
                      color:
                          Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    _deleteSchedule(
                      schedule,
                    );
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 19,
                  ),
                  label: const Text(
                    'Delete',
                  ),
                  style:
                      TextButton.styleFrom(
                    foregroundColor:
                        Colors.redAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}