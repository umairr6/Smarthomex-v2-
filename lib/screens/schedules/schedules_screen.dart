import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../core/responsive.dart';
import '../../models/schedule_model.dart';
import '../../providers/device_provider.dart';
import '../../services/storage_service.dart';
import '../../services/schedule_manager.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSchedules();
    });
  }

  Future<void> _loadSchedules() async {
    final schedules = await _storageService.loadSchedules();

    if (!mounted) return;

    context.read<DeviceProvider>().loadSavedSchedules(schedules);

    await ScheduleManager.instance.initialize();
  }

  Future<void> _showCreateScheduleDialog() async {
    final provider = context.read<DeviceProvider>();

    if (provider.device == null) {
      _showMessage('No ESP32 device connected.');
      return;
    }

    int selectedRelayId = 1;
    bool turnOn = true;
    TimeOfDay selectedTime = TimeOfDay.now();

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
          builder: (context, setDialogState) {
            final inputBorder = OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: SmartHomeColors.border,
              ),
            );

            final focusedBorder = OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: SmartHomeColors.gold,
                width: 1.2,
              ),
            );

            return AlertDialog(
              backgroundColor: SmartHomeColors.surfaceElevated,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(
                  color: SmartHomeColors.border,
                ),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              actionsPadding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              title: const Row(
                children: [
                  Icon(
                    Icons.add_alarm_rounded,
                    color: SmartHomeColors.gold,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Create Schedule',
                    style: TextStyle(
                      color: SmartHomeColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: selectedRelayId,
                      dropdownColor: SmartHomeColors.surfaceElevated,
                      style: const TextStyle(
                        color: SmartHomeColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Select Switch',
                        labelStyle: const TextStyle(
                          color: SmartHomeColors.textSecondary,
                        ),
                        prefixIcon: const Icon(
                          Icons.toggle_on_outlined,
                          color: SmartHomeColors.gold,
                        ),
                        enabledBorder: inputBorder,
                        focusedBorder: focusedBorder,
                      ),
                      items: provider.relays
                          .map(
                            (relay) => DropdownMenuItem<int>(
                              value: relay.id,
                              child: Text(relay.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          selectedRelayId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: SmartHomeColors.gold,
                                  onPrimary: Colors.black,
                                  surface: SmartHomeColors.surfaceElevated,
                                  onSurface: SmartHomeColors.textPrimary,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );

                        if (picked == null) return;

                        setDialogState(() {
                          selectedTime = picked;
                        });
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Time',
                          labelStyle: const TextStyle(
                            color: SmartHomeColors.textSecondary,
                          ),
                          prefixIcon: const Icon(
                            Icons.access_time_rounded,
                            color: SmartHomeColors.gold,
                          ),
                          enabledBorder: inputBorder,
                          focusedBorder: focusedBorder,
                        ),
                        child: Text(
                          selectedTime.format(context),
                          style: const TextStyle(
                            color: SmartHomeColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<bool>(
                      value: turnOn,
                      dropdownColor: SmartHomeColors.surfaceElevated,
                      style: const TextStyle(
                        color: SmartHomeColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Action',
                        labelStyle: const TextStyle(
                          color: SmartHomeColors.textSecondary,
                        ),
                        prefixIcon: const Icon(
                          Icons.power_settings_new_rounded,
                          color: SmartHomeColors.gold,
                        ),
                        enabledBorder: inputBorder,
                        focusedBorder: focusedBorder,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: true,
                          child: Text('Turn ON'),
                        ),
                        DropdownMenuItem(
                          value: false,
                          child: Text('Turn OFF'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          turnOn = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Repeat',
                        style: TextStyle(
                          color: SmartHomeColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
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
                    Navigator.pop(dialogContext);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: SmartHomeColors.textSecondary,
                  ),
                  child: const Text('Cancel'),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [
                        SmartHomeColors.goldLight,
                        SmartHomeColors.gold,
                      ],
                    ),
                  ),
                  child: TextButton(
                    onPressed: selectedDays.isEmpty
                        ? null
                        : () async {
                            Navigator.pop(dialogContext);

                            await _createSchedule(
                              relayId: selectedRelayId,
                              time: selectedTime,
                              turnOn: turnOn,
                              weekdays: selectedDays,
                            );
                          },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black,
                      disabledForegroundColor: Colors.black38,
                    ),
                    child: const Text(
                      'Save Schedule',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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
    final selected = selectedDays.contains(day);

    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: SmartHomeColors.gold.withOpacity(.18),
      backgroundColor: SmartHomeColors.background,
      side: BorderSide(
        color: selected
            ? SmartHomeColors.gold
            : SmartHomeColors.border,
      ),
      labelStyle: TextStyle(
        color: selected
            ? SmartHomeColors.goldLight
            : SmartHomeColors.textSecondary,
        fontWeight: FontWeight.w700,
      ),
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

  Future<void> _createSchedule({
    required int relayId,
    required TimeOfDay time,
    required bool turnOn,
    required List<int> weekdays,
  }) async {
    final provider = context.read<DeviceProvider>();
    final relay = provider.getRelay(relayId);

    if (relay == null) return;

    final scheduler = ScheduleManager.instance;

    final permissionGranted =
        await scheduler.requestExactAlarmPermission();

    if (!permissionGranted) {
      _showMessage(
        'Exact alarm permission is required for reliable schedules. Enable it in Android settings.',
      );
      return;
    }

    final schedule = RelaySchedule(
      id: '${DateTime.now().millisecondsSinceEpoch}_$relayId',
      relayId: relayId,
      relayName: relay.name,
      hour: time.hour,
      minute: time.minute,
      weekdays: List<int>.from(weekdays),
      turnOn: turnOn,
      enabled: true,
    );

    provider.addSchedule(schedule);

    await _storageService.saveSchedules(provider.schedules);

    final armed = await scheduler.scheduleOne(schedule);

    if (!armed) {
      provider.removeSchedule(schedule.id);
      await _storageService.saveSchedules(provider.schedules);
      _showMessage('Could not arm the schedule. Please try again.');
      return;
    }

    _showMessage('Schedule created for ${relay.name}.');
  }

  Future<void> _deleteSchedule(RelaySchedule schedule) async {
    final provider = context.read<DeviceProvider>();

    await ScheduleManager.instance.delete(schedule);

    provider.removeSchedule(schedule.id);

    await _storageService.saveSchedules(provider.schedules);

    _showMessage('Schedule deleted.');
  }

  Future<void> _toggleSchedule(
    RelaySchedule schedule,
    bool enabled,
  ) async {
    final provider = context.read<DeviceProvider>();

    provider.toggleSchedule(
      schedule.id,
      enabled,
    );

    await _storageService.saveSchedules(provider.schedules);

    await ScheduleManager.instance.syncSchedule(schedule);
  }

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

  String _formatDays(RelaySchedule schedule) {
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

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: SmartHomeColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(
              color: SmartHomeColors.borderGold,
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding =
        SmartHomeResponsive.horizontalPadding(context);
    final maxWidth =
        SmartHomeResponsive.isLargeScreen(context) ? 1000.0 : 760.0;

    return Scaffold(
      backgroundColor: SmartHomeColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: SmartHomeColors.textPrimary,
        elevation: 0,
        title: const Text(
          'Schedules',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateScheduleDialog,
        backgroundColor: SmartHomeColors.gold,
        foregroundColor: Colors.black,
        elevation: 8,
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text(
          'New Schedule',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [
              Color(0xFF17120A),
              SmartHomeColors.background,
              Colors.black,
            ],
            stops: [0.0, 0.48, 1.0],
          ),
        ),
        child: Consumer<DeviceProvider>(
          builder: (context, provider, child) {
            if (provider.schedules.isEmpty) {
              return _emptyState();
            }

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                ),
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    14,
                    horizontalPadding,
                    110,
                  ),
                  itemCount: provider.schedules.length,
                  itemBuilder: (context, index) {
                    final schedule = provider.schedules[index];

                    return _scheduleCard(
                      context,
                      schedule,
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 460,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: SmartHomeColors.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: SmartHomeColors.borderGold,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: SmartHomeColors.gold.withOpacity(.12),
                      blurRadius: 28,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  size: 46,
                  color: SmartHomeColors.goldLight,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No Schedules',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: SmartHomeColors.textPrimary,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Create automatic ON or OFF schedules for your switches.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: SmartHomeColors.textSecondary,
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 24),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [
                      SmartHomeColors.goldLight,
                      SmartHomeColors.gold,
                    ],
                  ),
                ),
                child: TextButton.icon(
                  onPressed: _showCreateScheduleDialog,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 13,
                    ),
                  ),
                  icon: const Icon(Icons.add_alarm_rounded),
                  label: const Text(
                    'Create Schedule',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scheduleCard(
    BuildContext context,
    RelaySchedule schedule,
  ) {
    final isOnAction = schedule.turnOn;

    return Container(
      margin: EdgeInsets.only(
        bottom: SmartHomeResponsive.cardSpacing(context),
      ),
      decoration: BoxDecoration(
        color: SmartHomeColors.surface.withOpacity(.95),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: schedule.enabled
              ? SmartHomeColors.borderGold
              : SmartHomeColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(
          SmartHomeResponsive.isSmallPhone(context) ? 15 : 18,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: SmartHomeColors.gold.withOpacity(.10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: SmartHomeColors.gold.withOpacity(.22),
                    ),
                  ),
                  child: Icon(
                    isOnAction
                        ? Icons.power_settings_new_rounded
                        : Icons.power_off_rounded,
                    color: SmartHomeColors.goldLight,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule.relayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SmartHomeColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        isOnAction ? 'Turn ON' : 'Turn OFF',
                        style: TextStyle(
                          color: isOnAction
                              ? SmartHomeColors.online
                              : SmartHomeColors.warning,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: schedule.enabled,
                  onChanged: (value) {
                    _toggleSchedule(
                      schedule,
                      value,
                    );
                  },
                  activeColor: SmartHomeColors.gold,
                  activeTrackColor:
                      SmartHomeColors.gold.withOpacity(.28),
                  inactiveThumbColor: SmartHomeColors.textMuted,
                  inactiveTrackColor:
                      SmartHomeColors.background,
                ),
              ],
            ),
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: SmartHomeColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: SmartHomeColors.border,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 20,
                    color: SmartHomeColors.gold,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _formatTime(
                      context,
                      schedule,
                    ),
                    style: const TextStyle(
                      color: SmartHomeColors.textPrimary,
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      _formatDays(schedule),
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SmartHomeColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  _deleteSchedule(schedule);
                },
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 19,
                ),
                label: const Text('Delete'),
                style: TextButton.styleFrom(
                  foregroundColor: SmartHomeColors.offline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
