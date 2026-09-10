import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/device_provider.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../schedules/schedules_screen.dart';
import '../settings/settings_screen.dart';
import '../timers/timers_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState
    extends State<HomeScreen> {
  final ApiService _apiService =
      ApiService();

  final StorageService _storageService =
      StorageService();

  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      _loadSavedSettings();
    });
  }

  Future<void> _loadSavedSettings() async {
    final provider =
        context.read<DeviceProvider>();

    final savedRelays =
        await _storageService.loadRelays();

    if (savedRelays != null && mounted) {
      provider.loadSavedRelays(
        savedRelays,
      );
    }

    final savedTimers =
        await _storageService.loadTimers();

    if (mounted) {
      provider.loadSavedTimers(
        savedTimers,
      );
    }

    await _syncWithEsp32();
  }

  Future<void> _syncWithEsp32() async {
    final provider =
        context.read<DeviceProvider>();

    final device = provider.device;

    if (device == null) return;

    final status =
        await _apiService.getStatus(
      device.ipAddress,
    );

    if (!mounted) return;

    if (status == null) {
      provider.updateDeviceStatus(
        false,
      );
      return;
    }

    provider.updateDeviceStatus(
      true,
    );

    provider.syncRelayStates(
      status,
    );
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    await _syncWithEsp32();

    if (!mounted) return;

    setState(() {
      _isRefreshing = false;
    });
  }

  Future<void> _toggleRelay(
    int relayId,
    bool turnOn,
  ) async {
    final provider =
        context.read<DeviceProvider>();

    final device = provider.device;

    if (device == null) return;

    if (!provider.isOnline) {
      _showMessage(
        'ESP32 is offline.',
      );
      return;
    }

    bool success;

    if (turnOn) {
      success =
          await _apiService.turnRelayOn(
        device.ipAddress,
        relayId,
      );
    } else {
      success =
          await _apiService.turnRelayOff(
        device.ipAddress,
        relayId,
      );
    }

    if (!mounted) return;

    if (success) {
      provider.updateRelayState(
        relayId,
        turnOn,
      );
    } else {
      provider.updateDeviceStatus(
        false,
      );

      _showMessage(
        'Failed to control the switch.',
      );
    }
  }

  IconData _getRelayIcon(
    String icon,
  ) {
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

  void _openTimers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const TimersScreen(),
      ),
    );
  }

  void _openSchedules() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const SchedulesScreen(),
      ),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const SettingsScreen(),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SmartHomeX',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _isRefreshing
                ? null
                : _refresh,
            tooltip: 'Refresh',
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.refresh,
                  ),
          ),

          IconButton(
            onPressed: _openTimers,
            tooltip: 'Timers',
            icon: const Icon(
              Icons.timer_outlined,
            ),
          ),

          IconButton(
            onPressed: _openSchedules,
            tooltip: 'Schedules',
            icon: const Icon(
              Icons.calendar_month_outlined,
            ),
          ),

          IconButton(
            onPressed: _openSettings,
            tooltip: 'Settings',
            icon: const Icon(
              Icons.settings_outlined,
            ),
          ),

          const SizedBox(
            width: 6,
          ),
        ],
      ),

      body: Consumer<DeviceProvider>(
        builder: (
          context,
          provider,
          child,
        ) {
          final device =
              provider.device;

          if (device == null) {
            return _noDeviceState();
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.all(16),
              children: [
                _deviceStatusCard(
                  provider,
                ),

                const SizedBox(
                  height: 22,
                ),

                const Text(
                  'Switches',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                _relayGrid(
                  provider,
                ),

                const SizedBox(
                  height: 20,
                ),

                _quickTimerCard(),

                const SizedBox(
                  height: 12,
                ),

                _quickScheduleCard(),

                const SizedBox(
                  height: 100,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _deviceStatusCard(
    DeviceProvider provider,
  ) {
    final device =
        provider.device!;

    return Container(
      padding:
          const EdgeInsets.all(20),
      decoration:
          BoxDecoration(
        color:
            const Color(0xff1E293B),
        borderRadius:
            BorderRadius.circular(24),
        border: Border.all(
          color: provider.isOnline
              ? Colors.green.withValues(
                  alpha: 0.25,
                )
              : Colors.red.withValues(
                  alpha: 0.25,
                ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
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
                child: const Icon(
                  Icons.home_outlined,
                  color:
                      Color(0xff34B7F1),
                  size: 28,
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
                      device.name,
                      style:
                          const TextStyle(
                        fontSize: 19,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      device.ipAddress,
                      style:
                          TextStyle(
                        fontSize: 13,
                        color: Colors
                            .white
                            .withValues(
                          alpha: 0.55,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              _statusBadge(
                provider.isOnline,
              ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          Row(
            children: [
              Icon(
                provider.isOnline
                    ? Icons.wifi
                    : Icons.wifi_off,
                size: 17,
                color:
                    provider.isOnline
                        ? Colors.green
                        : Colors.red,
              ),

              const SizedBox(
                width: 7,
              ),

              Text(
                provider.isOnline
                    ? 'ESP32 Connected'
                    : 'ESP32 Offline',
                style: TextStyle(
                  fontSize: 13,
                  color:
                      provider.isOnline
                          ? Colors.green
                          : Colors.red,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(
    bool online,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration:
          BoxDecoration(
        color: online
            ? Colors.green.withValues(
                alpha: 0.12,
              )
            : Colors.red.withValues(
                alpha: 0.12,
              ),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration:
                BoxDecoration(
              color: online
                  ? Colors.green
                  : Colors.red,
              shape:
                  BoxShape.circle,
            ),
          ),

          const SizedBox(
            width: 6,
          ),

          Text(
            online
                ? 'Online'
                : 'Offline',
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
              color: online
                  ? Colors.green
                  : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _relayGrid(
    DeviceProvider provider,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      itemCount:
          provider.relays.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemBuilder:
          (context, index) {
        final relay =
            provider.relays[index];

        return _relayCard(
          provider,
          relay.id,
          relay.name,
          relay.icon,
          relay.isOn,
        );
      },
    );
  }

  Widget _relayCard(
    DeviceProvider provider,
    int relayId,
    String name,
    String icon,
    bool isOn,
  ) {
    return AnimatedContainer(
      duration:
          const Duration(
        milliseconds: 250,
      ),
      padding:
          const EdgeInsets.all(17),
      decoration:
          BoxDecoration(
        color: isOn
            ? const Color(
                0xff34B7F1,
              ).withValues(
                alpha: 0.10,
              )
            : const Color(
                0xff1E293B,
              ),
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        border: Border.all(
          color: isOn
              ? const Color(
                  0xff34B7F1,
                ).withValues(
                  alpha: 0.45,
                )
              : Colors.white.withValues(
                  alpha: 0.05,
                ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration:
                    BoxDecoration(
                  color: isOn
                      ? const Color(
                          0xff34B7F1,
                        ).withValues(
                          alpha: 0.15,
                        )
                      : Colors.black
                          .withValues(
                          alpha: 0.15,
                        ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  _getRelayIcon(
                    icon,
                  ),
                  color: isOn
                      ? const Color(
                          0xff34B7F1,
                        )
                      : Colors.white54,
                  size: 25,
                ),
              ),

              const Spacer(),

              Switch(
                value: isOn,
                onChanged:
                    provider.isOnline
                        ? (value) {
                            _toggleRelay(
                              relayId,
                              value,
                            );
                          }
                        : null,
              ),
            ],
          ),

          const Spacer(),

          Text(
            name,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
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
            isOn ? 'ON' : 'OFF',
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
              color: isOn
                  ? const Color(
                      0xff34B7F1,
                    )
                  : Colors.white54,
            ),
          ),

          const SizedBox(
            height: 3,
          ),

          Text(
            'Relay $relayId',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white
                  .withValues(
                alpha: 0.40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickTimerCard() {
    return _quickFeatureCard(
      icon: Icons.timer_outlined,
      title: 'Timers',
      subtitle:
          'Automatically turn switches off',
      onTap: _openTimers,
    );
  }

  Widget _quickScheduleCard() {
    return _quickFeatureCard(
      icon:
          Icons.calendar_month_outlined,
      title: 'Schedules',
      subtitle:
          'Automate switches by time',
      onTap: _openSchedules,
    );
  }

  Widget _quickFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(22),
      child: Container(
        padding:
            const EdgeInsets.all(20),
        decoration:
            BoxDecoration(
          color:
              const Color(0xff1E293B),
          borderRadius:
              BorderRadius.circular(
            22,
          ),
          border: Border.all(
            color:
                const Color(
              0xff34B7F1,
            ).withValues(
              alpha: 0.12,
            ),
          ),
        ),
        child: Row(
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
                icon,
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
                    title,
                    style:
                        const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    subtitle,
                    style:
                        const TextStyle(
                      fontSize: 12,
                      color:
                          Colors.white54,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right,
              color:
                  Colors.white54,
            ),
          ],
        ),
      ),
    );
  }

  Widget _noDeviceState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.devices_other_outlined,
              size: 70,
              color:
                  Color(0xff34B7F1),
            ),

            const SizedBox(
              height: 20,
            ),

            const Text(
              'No Device Connected',
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Text(
              'Connect an ESP32 device to start controlling your home.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color: Colors.white
                    .withValues(
                  alpha: 0.60,
                ),
                height: 1.5,
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            FilledButton.icon(
              onPressed:
                  _openSettings,
              icon: const Icon(
                Icons.settings_outlined,
              ),
              label: const Text(
                'Settings',
              ),
            ),
          ],
        ),
      ),
    );
  }
}