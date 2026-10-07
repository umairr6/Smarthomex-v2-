import 'package:flutter/material.dart';

import 'package:media_kit/media_kit.dart';

import 'package:media_kit_video/media_kit_video.dart';

import '../../core/colors.dart';

import '../../core/responsive.dart';

import '../../services/device_service.dart';

import '../../services/mqtt_service.dart';

import '../schedules/schedules_screen.dart';

import '../timers/timers_screen.dart';

class RoomControlScreen extends StatefulWidget {
  final String roomName;

  final String deviceId;

  final String deviceName;

  final String ipAddress;

  const RoomControlScreen({
    super.key,

    required this.roomName,

    required this.deviceId,

    required this.deviceName,

    required this.ipAddress,
  });

  @override
  State<RoomControlScreen> createState() => _RoomControlScreenState();
}

class _RoomControlScreenState extends State<RoomControlScreen> {
  final DeviceService _deviceService = DeviceService();

  final MqttService _mqttService = MqttService();

  late final Player _backgroundPlayer;

  late final VideoController _backgroundVideoController;

  List<Map<String, dynamic>> _relays = [];

  bool _loading = true;

  bool _busy = false;

  bool _online = false;

  double _horizontalPadding(BuildContext context) =>
      SmartHomeResponsive.horizontalPadding(context);

  double _spacing(BuildContext context) =>
      SmartHomeResponsive.cardSpacing(context);

  bool _isSmallPhone(BuildContext context) =>
      SmartHomeResponsive.isSmallPhone(context);

  @override
  void initState() {
    super.initState();

    // =====================================================

    // CINEMATIC ROOM BACKGROUND

    // =====================================================

    _backgroundPlayer = Player();

    _backgroundVideoController = VideoController(_backgroundPlayer);

    _startBackgroundVideo();

    _mqttService.setStateListener(_handleMqttState);

    _loadRoom();
  }

  // =====================================================

  // START ROOM BACKGROUND VIDEO

  // Plays once and remains on the final frame.

  // =====================================================

  Future<void> _startBackgroundVideo() async {
    try {
      await _backgroundPlayer.open(
        Media('asset:///assets/videos/smarthomex_intro.mp4'),
      );

      await _backgroundPlayer.setVolume(0);

      // No loop:

      // MediaKit stops at the end of the media.
    } catch (e) {
      debugPrint('SmartHomeX room background video error: $e');
    }
  }

  // =====================================================

  // LOAD ROOM

  // =====================================================

  Future<void> _loadRoom() async {
    try {
      final relays = await _deviceService.getDeviceRelays(widget.deviceId);

      if (!mounted) return;

      setState(() {
        _relays = relays;

        _loading = false;
      });

      await _connectMqtt();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;

        _online = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load device: $e'),

          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =====================================================

  // CONNECT MQTT

  // =====================================================

  Future<void> _connectMqtt() async {
    if (!mounted) return;

    setState(() {
      _online = false;
    });

    final connected = await _mqttService.connect(_getDeviceUid());

    if (!mounted) return;

    setState(() {
      _online = connected;
    });
  }

  // =====================================================

  // DEVICE UID

  // =====================================================

  String _getDeviceUid() {
    // Your current paired device UID is SHX-90F57630.

    //

    // Later this will come directly from the

    // Supabase devices.device_uid column.

    //

    // For the current device, use:

    return 'SHX-90F57630';
  }

  // =====================================================

  // RECEIVE ESP32 STATE

  // =====================================================

  void _handleMqttState(Map<String, dynamic> state) {
    if (!mounted) return;

    final receivedUid = state['device_uid'] as String?;

    if (receivedUid != null && receivedUid != _getDeviceUid()) {
      return;
    }

    // MQTT service sends explicit availability events.

    final availability = state['_availability'] as String?;

    if (availability == 'offline') {
      setState(() {
        _online = false;
      });

      return;
    }

    if (availability == 'online') {
      setState(() {
        _online = true;
      });

      return;
    }

    setState(() {
      _online = true;

      for (final relay in _relays) {
        final number = relay['relay_number'] as int;

        final value = state['relay$number'];

        if (value is bool) {
          relay['is_on'] = value;
        }
      }
    });
  }

  // =====================================================

  // TOGGLE RELAY

  // =====================================================

  Future<void> _toggleRelay(Map<String, dynamic> relay) async {
    if (_busy) return;

    if (!_mqttService.isConnected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connecting to SmartHomeX device...'),

            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      await _connectMqtt();

      if (!_mqttService.isConnected) {
        return;
      }
    }

    final relayNumber = relay['relay_number'] as int;

    final currentState = relay['is_on'] as bool? ?? false;

    final newState = !currentState;

    setState(() {
      _busy = true;

      // Optimistic UI update.

      relay['is_on'] = newState;
    });

    final success = _mqttService.setRelay(relayNumber, newState);

    if (!mounted) return;

    setState(() {
      _busy = false;

      if (!success) {
        relay['is_on'] = currentState;
      }
    });

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send command to ESP32.'),

          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =====================================================

  // ICON

  // =====================================================

  IconData _getRelayIcon(String? icon) {
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

  // =====================================================

  // ICON COLOR

  // =====================================================

  Color _getIconColor(bool isOn) {
    return isOn ? SmartHomeColors.gold : Colors.white38;
  }

  // =====================================================

  // DISPOSE

  // =====================================================

  @override
  void dispose() {
    _mqttService.disconnect();

    _backgroundPlayer.dispose();

    super.dispose();
  }

  int _relayColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width < 360) return 1;

    if (width < 700) return 2;

    if (width < 1050) return 3;

    return 4;
  }

  double _relayAspectRatio(BuildContext context) {
    final columns = _relayColumns(context);

    if (columns == 1) return 2.15;

    if (columns == 2) return 1.45;

    if (columns == 3) return 1.35;

    return 1.40;
  }

  // =====================================================

  // BUILD

  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SmartHomeColors.background,

      extendBodyBehindAppBar: true,

      appBar: AppBar(
        backgroundColor: Colors.transparent,

        elevation: 0,

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              widget.roomName,

              style: TextStyle(
                fontWeight: FontWeight.bold,

                fontSize: _isSmallPhone(context) ? 18 : 20,
              ),
            ),

            Row(
              children: [
                Container(
                  width: 7,

                  height: 7,

                  decoration: BoxDecoration(
                    color: _online ? Colors.green : Colors.red,

                    shape: BoxShape.circle,
                  ),
                ),

                SizedBox(width: _isSmallPhone(context) ? 4 : 6),

                Text(
                  _online ? 'Online' : 'Offline',

                  style: TextStyle(
                    color: Colors.white54,

                    fontSize: _isSmallPhone(context) ? 11 : 12,
                  ),
                ),
              ],
            ),
          ],
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',

            onPressed: _loading ? null : _loadRoom,

            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),

      body: Stack(
        fit: StackFit.expand,

        children: [
          // ==================================================

          // CINEMATIC VIDEO BACKGROUND

          // ==================================================
          Positioned.fill(
            child: Video(
              controller: _backgroundVideoController,

              fit: BoxFit.cover,
            ),
          ),

          // ==================================================

          // DARK OVERLAY

          // ==================================================
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,

                  end: Alignment.bottomCenter,

                  colors: [
                    Colors.black.withValues(alpha: 0.28),

                    Colors.black.withValues(alpha: 0.42),

                    Colors.black.withValues(alpha: 0.72),

                    Colors.black.withValues(alpha: 0.88),
                  ],

                  stops: const [0.0, 0.35, 0.70, 1.0],
                ),
              ),
            ),
          ),

          // ==================================================

          // ROOM CONTROLS

          // ==================================================
          SafeArea(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: SmartHomeColors.gold,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadRoom,

                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),

                      padding: EdgeInsets.fromLTRB(
                        _horizontalPadding(context),

                        _isSmallPhone(context) ? 12 : 20,

                        _horizontalPadding(context),

                        _isSmallPhone(context) ? 22 : 30,
                      ),

                      children: [
                        // =================================

                        // DEVICE HEADER

                        // =================================
                        Container(
                          padding: EdgeInsets.all(
                            _isSmallPhone(context) ? 15 : 20,
                          ),

                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.34),

                            borderRadius: BorderRadius.circular(22),

                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.10),

                              width: 1,
                            ),

                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.22),

                                blurRadius: 24,

                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),

                          child: Row(
                            children: [
                              Container(
                                width: 56,

                                height: 56,

                                decoration: BoxDecoration(
                                  color: SmartHomeColors.gold.withValues(alpha: 0.12),

                                  borderRadius: BorderRadius.circular(17),
                                ),

                                child: Icon(
                                  Icons.router_rounded,

                                  color: SmartHomeColors.gold,

                                  size: _isSmallPhone(context) ? 24 : 28,
                                ),
                              ),

                              const SizedBox(width: 15),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [
                                    Text(
                                      widget.deviceName,

                                      style: const TextStyle(
                                        color: Colors.white,

                                        fontSize: 17,

                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 5),

                                    Text(
                                      'Internet • MQTT',

                                      style: const TextStyle(
                                        color: Colors.white54,

                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,

                                  vertical: 6,
                                ),

                                decoration: BoxDecoration(
                                  color: _online
                                      ? Colors.green.withValues(alpha: 0.12)
                                      : Colors.red.withValues(alpha: 0.12),

                                  borderRadius: BorderRadius.circular(20),
                                ),

                                child: Text(
                                  _online ? 'ONLINE' : 'OFFLINE',

                                  style: TextStyle(
                                    color: _online ? Colors.green : Colors.red,

                                    fontSize: 10,

                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // =================================

                        // SWITCHES

                        // =================================
                        const Text(
                          'SWITCHES',

                          style: TextStyle(
                            color: Colors.white54,

                            fontSize: 12,

                            fontWeight: FontWeight.bold,

                            letterSpacing: 1.3,
                          ),
                        ),

                        const SizedBox(height: 12),

                        if (_relays.isEmpty)
                          Container(
                            padding: EdgeInsets.all(
                              _isSmallPhone(context) ? 22 : 30,
                            ),

                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.34),

                              borderRadius: BorderRadius.circular(20),

                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.10),
                              ),
                            ),

                            child: const Center(
                              child: Text(
                                'No switches found.',

                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,

                            physics: const NeverScrollableScrollPhysics(),

                            itemCount: _relays.length,

                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: _relayColumns(context),

                                  crossAxisSpacing: _spacing(context),

                                  mainAxisSpacing: _spacing(context),

                                  childAspectRatio: _relayAspectRatio(context),
                                ),

                            itemBuilder: (context, index) {
                              final relay = _relays[index];

                              final isOn = relay['is_on'] as bool? ?? false;

                              final relayNumber = relay['relay_number'] as int;

                              final name =
                                  relay['name'] as String? ??
                                  'Switch $relayNumber';

                              final icon = relay['icon'] as String? ?? 'light';

                              return GestureDetector(
                                onTap: _busy ? null : () => _toggleRelay(relay),

                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),

                                  padding: const EdgeInsets.all(18),

                                  decoration: BoxDecoration(
                                    color: isOn
                                        ? SmartHomeColors.gold.withValues(alpha: 0.12)
                                        : Colors.black.withValues(alpha: 0.34),

                                    borderRadius: BorderRadius.circular(22),

                                    border: Border.all(
                                      color: isOn
                                          ? SmartHomeColors.gold.withValues(alpha: 0.65)
                                          : Colors.white.withValues(alpha: 0.10),

                                      width: isOn ? 1.3 : 1.0,
                                    ),

                                    boxShadow: [
                                      BoxShadow(
                                        color: isOn
                                            ? SmartHomeColors.gold.withValues(alpha: 0.10)
                                            : Colors.black.withValues(alpha: 0.18),

                                        blurRadius: isOn ? 24 : 18,

                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),

                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,

                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,

                                        children: [
                                          Container(
                                            width: 48,

                                            height: 48,

                                            decoration: BoxDecoration(
                                              color: isOn
                                                  ? SmartHomeColors.gold
                                                        .withValues(alpha: 0.18)
                                                  : Colors.white.withValues(alpha: 0.07),

                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),

                                            child: Icon(
                                              _getRelayIcon(icon),

                                              color: _getIconColor(isOn),

                                              size: 25,
                                            ),
                                          ),

                                          Switch(
                                            value: isOn,

                                            onChanged: _busy
                                                ? null
                                                : (_) => _toggleRelay(relay),

                                            activeThumbColor:
                                                SmartHomeColors.goldLight,

                                            activeTrackColor:
                                                SmartHomeColors.goldDark,

                                            inactiveThumbColor:
                                                SmartHomeColors.textMuted,

                                            inactiveTrackColor: Colors.white
                                                .withValues(alpha: 0.10),
                                          ),
                                        ],
                                      ),

                                      const Spacer(),

                                      Text(
                                        name,

                                        maxLines: 1,

                                        overflow: TextOverflow.ellipsis,

                                        style: const TextStyle(
                                          color: Colors.white,

                                          fontSize: 16,

                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      Text(
                                        isOn ? 'ON' : 'OFF',

                                        style: TextStyle(
                                          color: isOn
                                              ? SmartHomeColors.gold
                                              : Colors.white38,

                                          fontSize: 11,

                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                        const SizedBox(height: 28),

                        // =================================

                        // AUTOMATION

                        // =================================
                        const Text(
                          'AUTOMATION',

                          style: TextStyle(
                            color: Colors.white54,

                            fontSize: 12,

                            fontWeight: FontWeight.bold,

                            letterSpacing: 1.3,
                          ),
                        ),

                        const SizedBox(height: 12),

                        _automationTile(
                          icon: Icons.timer_outlined,

                          title: 'Timers',

                          subtitle: 'Turn switches off automatically',

                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const TimersScreen(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 10),

                        _automationTile(
                          icon: Icons.schedule_rounded,

                          title: 'Schedules',

                          subtitle: 'Automate switches by time',

                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SchedulesScreen(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // =====================================================

  // AUTOMATION TILE

  // =====================================================

  Widget _automationTile({
    required IconData icon,

    required String title,

    required String subtitle,

    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.34),

      borderRadius: BorderRadius.circular(18),

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(18),

        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),

            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),

          child: Padding(
            padding: const EdgeInsets.all(17),

            child: Row(
              children: [
                Container(
                  width: 46,

                  height: 46,

                  decoration: BoxDecoration(
                    color: SmartHomeColors.gold.withValues(alpha: 0.10),

                    borderRadius: BorderRadius.circular(14),
                  ),

                  child: Icon(icon, color: SmartHomeColors.gold),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        title,

                        style: const TextStyle(
                          color: Colors.white,

                          fontSize: 15,

                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        subtitle,

                        style: const TextStyle(
                          color: Colors.white54,

                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(Icons.chevron_right_rounded, color: Colors.white38),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
