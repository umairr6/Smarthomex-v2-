import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/device_provider.dart';
import '../../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();

  final Set<int> _loadingRelays = {};

  bool _isSyncing = true;

  @override
  void initState() {
    super.initState();

    // Wait until the first frame is built,
    // then synchronize with ESP32.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncWithEsp32();
    });
  }

  // ==========================================
  // SYNC WITH ESP32
  // ==========================================

  Future<void> _syncWithEsp32() async {
    final deviceProvider = context.read<DeviceProvider>();
    final device = deviceProvider.device;

    if (device == null) {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
      return;
    }

    final status = await _apiService.getStatus(
      device.ipAddress,
    );

    if (!mounted) return;

    if (status != null && status['status'] == 'online') {
      // ESP32 is online
      deviceProvider.updateDeviceStatus(true);

      // Update all relay states
      deviceProvider.syncRelayStates(status);
    } else {
      // ESP32 is offline
      deviceProvider.updateDeviceStatus(false);
    }

    if (mounted) {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  // ==========================================
  // TOGGLE RELAY
  // ==========================================

  Future<void> _toggleRelay(
    int relayId,
    bool currentState,
  ) async {
    final deviceProvider = context.read<DeviceProvider>();
    final device = deviceProvider.device;

    if (device == null) {
      return;
    }

    // Prevent multiple requests to same relay
    if (_loadingRelays.contains(relayId)) {
      return;
    }

    setState(() {
      _loadingRelays.add(relayId);
    });

    bool success;

    if (currentState) {
      success = await _apiService.turnRelayOff(
        device.ipAddress,
        relayId,
      );
    } else {
      success = await _apiService.turnRelayOn(
        device.ipAddress,
        relayId,
      );
    }

    if (!mounted) return;

    if (success) {
      // Only update UI after ESP32 confirms command
      deviceProvider.updateRelayState(
        relayId,
        !currentState,
      );

      deviceProvider.updateDeviceStatus(true);
    } else {
      // ESP32 didn't respond
      deviceProvider.updateDeviceStatus(false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ESP32 is not responding.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    setState(() {
      _loadingRelays.remove(relayId);
    });
  }

  // ==========================================
  // RELAY ICON
  // ==========================================

  IconData _getRelayIcon(String icon) {
    switch (icon) {
      case 'fan':
        return Icons.mode_fan_off_rounded;

      case 'socket':
        return Icons.power_rounded;

      case 'light':
      default:
        return Icons.lightbulb_rounded;
    }
  }

  // ==========================================
  // REFRESH
  // ==========================================

  Future<void> _refreshStatus() async {
    setState(() {
      _isSyncing = true;
    });

    await _syncWithEsp32();
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceProvider>(
      builder: (context, deviceProvider, child) {
        final device = deviceProvider.device;
        final relays = deviceProvider.relays;

        return Scaffold(
          backgroundColor: const Color(0xff0F172A),

          appBar: AppBar(
            backgroundColor: const Color(0xff0F172A),
            elevation: 0,

            title: const Text(
              'SmartHomeX',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            actions: [
              IconButton(
                onPressed: _refreshStatus,
                icon: const Icon(
                  Icons.refresh_rounded,
                ),
              ),

              const SizedBox(width: 8),
            ],
          ),

          body: RefreshIndicator(
            onRefresh: _refreshStatus,

            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),

              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  // ==================================
                  // DEVICE STATUS
                  // ==================================

                  Container(
                    width: double.infinity,

                    padding: const EdgeInsets.all(20),

                    decoration: BoxDecoration(
                      color: const Color(0xff1E293B),
                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,

                          decoration: BoxDecoration(
                            color: deviceProvider.isOnline
                                ? Colors.green.withOpacity(0.15)
                                : Colors.red.withOpacity(0.15),

                            borderRadius: BorderRadius.circular(15),
                          ),

                          child: Icon(
                            Icons.router_rounded,

                            color: deviceProvider.isOnline
                                ? Colors.green
                                : Colors.red,

                            size: 28,
                          ),
                        ),

                        const SizedBox(width: 15),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [
                              Text(
                                device?.name ?? 'ESP32',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 5),

                              Text(
                                device?.ipAddress ?? '',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.end,

                          children: [
                            Icon(
                              Icons.circle,

                              size: 11,

                              color: deviceProvider.isOnline
                                  ? Colors.green
                                  : Colors.red,
                            ),

                            const SizedBox(height: 5),

                            Text(
                              deviceProvider.isOnline
                                  ? 'Online'
                                  : 'Offline',

                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: deviceProvider.isOnline
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ==================================
                  // TITLE
                  // ==================================

                  const Text(
                    'Your Devices',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  // ==================================
                  // LOADING STATUS
                  // ==================================

                  if (_isSyncing)
                    const Padding(
                      padding: EdgeInsets.only(
                        bottom: 15,
                      ),

                      child: Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,

                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xff34B7F1),
                            ),
                          ),

                          SizedBox(width: 10),

                          Text(
                            'Syncing with ESP32...',
                            style: TextStyle(
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ==================================
                  // RELAY GRID
                  // ==================================

                  GridView.builder(
                    shrinkWrap: true,

                    physics:
                        const NeverScrollableScrollPhysics(),

                    itemCount: relays.length,

                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,

                      crossAxisSpacing: 15,

                      mainAxisSpacing: 15,

                      childAspectRatio: 0.95,
                    ),

                    itemBuilder: (context, index) {
                      final relay = relays[index];

                      final isLoading =
                          _loadingRelays.contains(relay.id);

                      return _buildRelayCard(
                        relay.id,
                        relay.name,
                        relay.isOn,
                        relay.icon,
                        isLoading,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // RELAY CARD
  // ==========================================

  Widget _buildRelayCard(
    int relayId,
    String name,
    bool isOn,
    String icon,
    bool isLoading,
  ) {
    return GestureDetector(
      onTap: isLoading
          ? null
          : () {
              _toggleRelay(
                relayId,
                isOn,
              );
            },

      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 200,
        ),

        padding: const EdgeInsets.all(18),

        decoration: BoxDecoration(
          color: isOn
              ? const Color(0xff1E293B)
              : const Color(0xff162235),

          borderRadius: BorderRadius.circular(22),

          border: Border.all(
            color: isOn
                ? const Color(0xff34B7F1)
                : Colors.white10,

            width: isOn ? 1.5 : 1,
          ),
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // Icon + switch
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

              children: [
                Container(
                  width: 48,
                  height: 48,

                  decoration: BoxDecoration(
                    color: isOn
                        ? const Color(0xff34B7F1)
                            .withOpacity(0.15)
                        : Colors.white10,

                    borderRadius:
                        BorderRadius.circular(15),
                  ),

                  child: isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(14),

                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xff34B7F1),
                          ),
                        )
                      : Icon(
                          _getRelayIcon(icon),

                          color: isOn
                              ? const Color(0xff34B7F1)
                              : Colors.white54,

                          size: 25,
                        ),
                ),

                Switch(
                  value: isOn,

                  onChanged: isLoading
                      ? null
                      : (value) {
                          _toggleRelay(
                            relayId,
                            isOn,
                          );
                        },

                  activeThumbColor:
                      const Color(0xff34B7F1),
                ),
              ],
            ),

            const Spacer(),

            Text(
              name,

              maxLines: 1,

              overflow: TextOverflow.ellipsis,

              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              isOn ? 'ON' : 'OFF',

              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,

                color: isOn
                    ? Colors.green
                    : Colors.white54,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              'Relay $relayId',

              style: const TextStyle(
                fontSize: 11,
                color: Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}