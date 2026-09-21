import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../services/auth_service.dart';
import '../../services/device_service.dart';
import '../../services/home_service.dart';
import '../setup/pair_device_screen.dart';
import 'room_control_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() =>
      _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen>
    with SingleTickerProviderStateMixin {
  final HomeService _homeService = HomeService();
  final DeviceService _deviceService = DeviceService();
  final AuthService _authService = AuthService();

  // =========================================================
  // CINEMATIC BACKGROUND
  // =========================================================

  late final Player _backgroundPlayer;
  late final VideoController _backgroundVideoController;

  List<Map<String, dynamic>> _homes = [];

  final Map<String, List<Map<String, dynamic>>> _rooms = {};
  final Map<String, List<Map<String, dynamic>>> _devices = {};

  bool _loading = true;
  bool _refreshing = false;

  late AnimationController _animationController;

  // =========================================================
  // LUXURY COLORS
  // =========================================================

  static const Color bg = Color(0xff070707);
  static const Color surface = Color(0xff111111);
  static const Color surface2 = Color(0xff171717);

  static const Color primary = Color(0xFFD6B36A);
  static const Color primaryLight = Color(0xFFF2D18B);

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Start the cinematic background.
    _backgroundPlayer = Player();
    _backgroundVideoController =
        VideoController(_backgroundPlayer);

    _startBackgroundVideo();

    _loadHomes();
  }

  // =========================================================
  // START BACKGROUND VIDEO
  // =========================================================

  Future<void> _startBackgroundVideo() async {
    try {
      await _backgroundPlayer.open(
        Media(
          'asset:///assets/videos/smarthomex_intro.mp4',
        ),
      );

      await _backgroundPlayer.setVolume(0);

    } catch (e) {
      debugPrint(
        'SmartHomeX background video error: $e',
      );
    }
  }

  @override
  void dispose() {
    _backgroundPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // =========================================================
  // LOAD HOMES
  // =========================================================

  Future<void> _loadHomes() async {
    if (!_loading) {
      setState(() {
        _refreshing = true;
      });
    }

    try {
      final homes = await _homeService.getHomes();

      final rooms = <String, List<Map<String, dynamic>>>{};
      final devices = <String, List<Map<String, dynamic>>>{};

      for (final home in homes) {
        final homeId = home['id'] as String;

        final homeRooms =
            await _homeService.getRooms(homeId);

        rooms[homeId] = homeRooms;

        for (final room in homeRooms) {
          final roomId = room['id'] as String;

          final roomDevices =
              await _deviceService.getRoomDevices(roomId);

          devices[roomId] = roomDevices;
        }
      }

      if (!mounted) return;

      setState(() {
        _homes = homes;

        _rooms
          ..clear()
          ..addAll(rooms);

        _devices
          ..clear()
          ..addAll(devices);

        _loading = false;
        _refreshing = false;
      });

      _animationController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _refreshing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load your home: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // ADD HOME
  // =========================================================

  Future<void> _addHome() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return _modernDialog(
          title: 'Create Home',
          icon: Icons.home_work_rounded,
          child: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Home name',
              prefixIcon: Icon(Icons.home_rounded),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();

                if (value.isEmpty) return;

                Navigator.pop(dialogContext, value);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (name == null || name.trim().isEmpty) return;

    try {
      await _homeService.createHome(name);
      await _loadHomes();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Home created successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not create home: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // ADD ROOM
  // =========================================================

  Future<void> _addRoom(String homeId) async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return _modernDialog(
          title: 'Add Room',
          icon: Icons.meeting_room_rounded,
          child: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Room name',
              prefixIcon: Icon(Icons.meeting_room_rounded),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();

                if (value.isEmpty) return;

                Navigator.pop(dialogContext, value);
              },
              child: const Text('Add Room'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (name == null || name.trim().isEmpty) return;

    try {
      await _homeService.createRoom(
        homeId: homeId,
        name: name,
      );

      await _loadHomes();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Room added successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not add room: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // RENAME HOME
  // =========================================================

  Future<void> _renameHome(
    Map<String, dynamic> home,
  ) async {
    final controller = TextEditingController(
      text: home['name'] as String? ?? '',
    );

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return _modernDialog(
          title: 'Rename Home',
          icon: Icons.edit_rounded,
          child: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Home name',
              prefixIcon: Icon(Icons.home_rounded),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();

                if (value.isEmpty) return;

                Navigator.pop(dialogContext, value);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (name == null || name.trim().isEmpty) return;

    try {
      await _homeService.renameHome(
        home['id'] as String,
        name,
      );

      await _loadHomes();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not rename home: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // RENAME ROOM
  // =========================================================

  Future<void> _renameRoom(
    Map<String, dynamic> room,
  ) async {
    final controller = TextEditingController(
      text: room['name'] as String? ?? '',
    );

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return _modernDialog(
          title: 'Rename Room',
          icon: Icons.edit_rounded,
          child: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Room name',
              prefixIcon: Icon(Icons.meeting_room_rounded),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();

                if (value.isEmpty) return;

                Navigator.pop(dialogContext, value);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (name == null || name.trim().isEmpty) return;

    try {
      await _homeService.renameRoom(
        roomId: room['id'] as String,
        name: name,
      );

      await _loadHomes();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not rename room: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // DELETE HOME
  // =========================================================

  Future<void> _deleteHome(
    Map<String, dynamic> home,
  ) async {
    final homeName =
        home['name'] as String? ?? 'this home';

    final confirmed = await _confirmDialog(
      title: 'Delete Home?',
      message:
          'Delete "$homeName" and all rooms inside it?',
      icon: Icons.delete_outline_rounded,
      destructive: true,
      confirmText: 'Delete',
    );

    if (confirmed != true) return;

    try {
      await _homeService.deleteHome(
        home['id'] as String,
      );

      await _loadHomes();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Home deleted.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete home: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // DELETE ROOM
  // =========================================================

  Future<void> _deleteRoom(
    Map<String, dynamic> room,
  ) async {
    final roomName =
        room['name'] as String? ?? 'this room';

    final confirmed = await _confirmDialog(
      title: 'Delete Room?',
      message:
          'Delete "$roomName"? Any paired ESP32 in this room will also be removed.',
      icon: Icons.delete_outline_rounded,
      destructive: true,
      confirmText: 'Delete',
    );

    if (confirmed != true) return;

    try {
      await _homeService.deleteRoom(
        room['id'] as String,
      );

      await _loadHomes();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Room deleted.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete room: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // UNPAIR DEVICE
  // =========================================================

  Future<void> _unpairDevice(
    Map<String, dynamic> device,
  ) async {
    final deviceName =
        device['name'] as String? ??
            'SmartHomeX ESP32';

    final confirmed = await _confirmDialog(
      title: 'Unpair ESP32?',
      message:
          'Remove "$deviceName" from this room?',
      icon: Icons.link_off_rounded,
      destructive: true,
      confirmText: 'Unpair',
    );

    if (confirmed != true) return;

    try {
      await _deviceService.deleteDevice(
        device['id'] as String,
      );

      await _loadHomes();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ESP32 unpaired successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not unpair device: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // PAIR DEVICE
  // =========================================================

  Future<void> _pairDevice(
    Map<String, dynamic> room,
  ) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PairDeviceScreen(
          roomId: room['id'] as String,
          roomName:
              room['name'] as String? ?? 'Room',
        ),
      ),
    );

    if (result == true) {
      await _loadHomes();
    }
  }

  // =========================================================
  // OPEN ROOM
  // =========================================================

  Future<void> _openRoomControl(
    Map<String, dynamic> room,
    Map<String, dynamic> device,
  ) async {
    final ipAddress =
        device['ip_address'] as String? ?? '';

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoomControlScreen(
          roomName:
              room['name'] as String? ?? 'Room',
          deviceId: device['id'] as String,
          deviceName:
              device['name'] as String? ??
                  'SmartHomeX ESP32',
          ipAddress: ipAddress,
        ),
      ),
    );
  }

  // =========================================================
  // HOME MENU
  // =========================================================

  void _showHomeMenu(
    Map<String, dynamic> home,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: surface2,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              18,
              4,
              18,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _bottomSheetTitle(
                  Icons.home_rounded,
                  home['name'] as String? ??
                      'Home',
                ),
                const SizedBox(height: 8),
                _sheetTile(
                  icon: Icons.edit_rounded,
                  title: 'Rename Home',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _renameHome(home);
                  },
                ),
                _sheetTile(
                  icon: Icons.delete_outline_rounded,
                  title: 'Delete Home',
                  color: Colors.redAccent,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _deleteHome(home);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // ROOM MENU
  // =========================================================

  void _showRoomMenu(
    Map<String, dynamic> room,
  ) {
    final roomDevices =
        _devices[room['id'] as String] ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: surface2,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              18,
              4,
              18,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _bottomSheetTitle(
                  Icons.meeting_room_rounded,
                  room['name'] as String? ??
                      'Room',
                ),
                const SizedBox(height: 8),
                _sheetTile(
                  icon: Icons.edit_rounded,
                  title: 'Rename Room',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _renameRoom(room);
                  },
                ),
                if (roomDevices.isNotEmpty)
                  _sheetTile(
                    icon: Icons.router_rounded,
                    title: 'Device Information',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _showDeviceInfo(
                        roomDevices.first,
                        room,
                      );
                    },
                  ),
                if (roomDevices.isNotEmpty)
                  _sheetTile(
                    icon: Icons.link_off_rounded,
                    title: 'Unpair ESP32',
                    color: Colors.orangeAccent,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _unpairDevice(
                        roomDevices.first,
                      );
                    },
                  ),
                _sheetTile(
                  icon: Icons.delete_outline_rounded,
                  title: 'Delete Room',
                  color: Colors.redAccent,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _deleteRoom(room);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // DEVICE INFORMATION
  // =========================================================

  void _showDeviceInfo(
    Map<String, dynamic> device,
    Map<String, dynamic> room,
  ) {
    final name =
        device['name'] as String? ??
            'SmartHomeX ESP32';

    final uid =
        device['device_uid'] as String? ??
            'Unknown';

    final ip =
        device['ip_address'] as String? ??
            'Unknown';

    final relayCount =
        device['relay_count'] as int? ?? 4;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return _modernDialog(
          title: name,
          icon: Icons.router_rounded,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _infoRow(
                'Room',
                room['name'] as String? ?? 'Room',
              ),
              _infoRow('Device UID', uid),
              _infoRow('IP Address', ip),
              _infoRow('Relays', '$relayCount'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // DIALOG HELPERS
  // =========================================================

  Widget _modernDialog({
    required String title,
    required IconData icon,
    required Widget child,
    required List<Widget> actions,
  }) {
    return AlertDialog(
      backgroundColor: surface2,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primary.withOpacity(.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: child,
      actions: actions,
    );
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
    required IconData icon,
    required bool destructive,
    required String confirmText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return _modernDialog(
          title: title,
          icon: icon,
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white60,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    destructive ? Colors.redAccent : primary,
                foregroundColor: Colors.black,
              ),
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // BOTTOM SHEET HELPERS
  // =========================================================

  Widget _bottomSheetTitle(
    IconData icon,
    String title,
  ) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: primary.withOpacity(.10),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            icon,
            color: primary,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sheetTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final iconColor = color ?? primary;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(vertical: 3),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(.10),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Colors.white24,
      ),
      onTap: onTap,
    );
  }

  // =========================================================
  // HOME CARD
  // =========================================================

  Widget _homeCard(
    Map<String, dynamic> home,
  ) {
    final homeId = home['id'] as String;

    final homeName =
        home['name'] as String? ?? 'My Home';

    final homeRooms =
        _rooms[homeId] ?? [];

    int connectedDevices = 0;

    for (final room in homeRooms) {
      final roomDevices =
          _devices[room['id'] as String] ?? [];

      for (final device in roomDevices) {
        if (device['is_online'] == true) {
          connectedDevices++;
        }
      }
    }

    final roomCount = homeRooms.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.48),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(.13),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.35),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Column(
          children: [
            _homeHero(
              homeName,
              roomCount,
              connectedDevices,
              home,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                16,
              ),
              child: Column(
                children: [
                  if (homeRooms.isEmpty)
                    _emptyRooms()
                  else
                    _roomGrid(homeRooms),
                  const SizedBox(height: 12),
                  _addRoomButton(homeId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // HOME HERO
  // =========================================================

  Widget _homeHero(
    String homeName,
    int roomCount,
    int connectedDevices,
    Map<String, dynamic> home,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withOpacity(.16),
            Colors.black.withOpacity(.05),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: primary.withOpacity(.14),
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(
                    color: primary.withOpacity(.30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(.12),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.home_work_rounded,
                  color: primaryLight,
                  size: 29,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      homeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: connectedDevices > 0
                                ? Colors.greenAccent
                                : Colors.white30,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          connectedDevices > 0
                              ? 'System connected'
                              : 'No devices online',
                          style: TextStyle(
                            color: connectedDevices > 0
                                ? Colors.greenAccent
                                : Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.07),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  onPressed: () =>
                      _showHomeMenu(home),
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  Icons.meeting_room_rounded,
                  '$roomCount',
                  roomCount == 1 ? 'Room' : 'Rooms',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  Icons.router_rounded,
                  '$connectedDevices',
                  connectedDevices == 1
                      ? 'Device online'
                      : 'Devices online',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  Icons.cloud_done_rounded,
                  'MQTT',
                  'Cloud ready',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    IconData icon,
    String value,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.28),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withOpacity(.08),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 18,
            color: primaryLight,
          ),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 8.5,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ROOM GRID
  // =========================================================

  Widget _roomGrid(
    List<Map<String, dynamic>> rooms,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final columns = width >= 800
            ? 3
            : width >= 500
                ? 2
                : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          itemCount: rooms.length,
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio:
                columns == 2 ? 1.32 : 1.45,
          ),
          itemBuilder: (context, index) {
            return _roomCard(rooms[index]);
          },
        );
      },
    );
  }

  // =========================================================
  // ROOM CARD
  // =========================================================

  Widget _roomCard(
    Map<String, dynamic> room,
  ) {
    final roomId = room['id'] as String;

    final roomName =
        room['name'] as String? ?? 'Room';

    final roomDevices =
        _devices[roomId] ?? [];

    final hasDevice =
        roomDevices.isNotEmpty;

    final device =
        hasDevice ? roomDevices.first : null;

    final isOnline =
        device?['is_online'] as bool? ?? false;

    final deviceName =
        device?['name'] as String? ??
            'SmartHomeX ESP32';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: hasDevice
            ? () => _openRoomControl(
                room,
                device!,
              )
            : () => _pairDevice(room),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(.42),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: hasDevice
                  ? primary.withOpacity(.20)
                  : Colors.white.withOpacity(.08),
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: hasDevice
                          ? primary.withOpacity(.13)
                          : Colors.white.withOpacity(.06),
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _roomIcon(roomName),
                      color: hasDevice
                          ? primaryLight
                          : Colors.white38,
                      size: 21,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    onPressed: () =>
                        _showRoomMenu(room),
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      color: Colors.white38,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                roomName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              if (hasDevice)
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isOnline
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isOnline
                            ? '$deviceName • Online'
                            : '$deviceName • Offline',
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isOnline
                              ? Colors.greenAccent
                                  .withOpacity(.75)
                              : Colors.redAccent
                                  .withOpacity(.75),
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    const Icon(
                      Icons.add_circle_outline_rounded,
                      size: 13,
                      color: primaryLight,
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Tap to pair ESP32',
                      style: TextStyle(
                        color: primaryLight,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // ADD ROOM BUTTON
  // =========================================================

  Widget _addRoomButton(String homeId) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: () => _addRoom(homeId),
          child: Container(
            decoration: BoxDecoration(
              color: primary.withOpacity(.09),
              borderRadius:
                  BorderRadius.circular(17),
              border: Border.all(
                color: primary.withOpacity(.25),
              ),
            ),
            child: const Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_rounded,
                  color: primaryLight,
                  size: 19,
                ),
                SizedBox(width: 7),
                Text(
                  'Add Room',
                  style: TextStyle(
                    color: primaryLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // EMPTY ROOMS
  // =========================================================

  Widget _emptyRooms() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 28,
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: primary.withOpacity(.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.meeting_room_outlined,
              color: primaryLight,
              size: 28,
            ),
          ),
          const SizedBox(height: 13),
          const Text(
            'No rooms yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Create your first room and connect your ESP32.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // EMPTY HOME
  // =========================================================

  Widget _emptyHomeState() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.fromLTRB(
        25,
        35,
        25,
        32,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.48),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(.10),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary.withOpacity(.12),
              border: Border.all(
                color: primary.withOpacity(.22),
              ),
            ),
            child: const Icon(
              Icons.home_work_rounded,
              color: primaryLight,
              size: 38,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Welcome to SmartHomeX',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first home and start building your smart environment.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _addHome,
              icon: const Icon(
                Icons.add_home_rounded,
              ),
              label: const Text(
                'Create Your Home',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.black,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(17),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // INFO ROW
  // =========================================================

  Widget _infoRow(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 9,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ROOM ICON
  // =========================================================

  IconData _roomIcon(String name) {
    final value = name.toLowerCase();

    if (value.contains('bed')) {
      return Icons.bed_rounded;
    }

    if (value.contains('living')) {
      return Icons.weekend_rounded;
    }

    if (value.contains('kitchen')) {
      return Icons.soup_kitchen_rounded;
    }

    if (value.contains('bath')) {
      return Icons.bathtub_rounded;
    }

    if (value.contains('office')) {
      return Icons.desk_rounded;
    }

    if (value.contains('dining')) {
      return Icons.restaurant_rounded;
    }

    if (value.contains('garden')) {
      return Icons.yard_rounded;
    }

    if (value.contains('garage')) {
      return Icons.garage_rounded;
    }

    return Icons.meeting_room_rounded;
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    final fullName =
        user?.userMetadata?['full_name'] as String?;

    final displayName =
        fullName?.trim().isNotEmpty == true
            ? fullName!.trim()
            : 'there';

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,

      // =======================================================
      // APP BAR
      // =======================================================

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,

        titleSpacing: 20,

        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(.45),
                borderRadius:
                    BorderRadius.circular(12),
                border: Border.all(
                  color: primary.withOpacity(.35),
                ),
              ),
              child: const Icon(
                Icons.home_rounded,
                color: primaryLight,
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            const Text(
              'SmartHomeX',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -.5,
              ),
            ),
          ],
        ),

        actions: [
          Container(
            margin: const EdgeInsets.only(right: 5),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(.40),
              borderRadius:
                  BorderRadius.circular(13),
              border: Border.all(
                color: Colors.white.withOpacity(.10),
              ),
            ),
            child: IconButton(
              tooltip: 'Refresh',
              onPressed:
                  _refreshing ? null : _loadHomes,
              icon: _refreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primaryLight,
                      ),
                    )
                  : const Icon(
                      Icons.refresh_rounded,
                      size: 21,
                    ),
            ),
          ),

          Container(
            margin:
                const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(.40),
              borderRadius:
                  BorderRadius.circular(13),
              border: Border.all(
                color: Colors.white.withOpacity(.10),
              ),
            ),
            child: IconButton(
              tooltip: 'Sign out',
              onPressed: () async {
                await _authService.signOut();
              },
              icon: const Icon(
                Icons.logout_rounded,
                size: 20,
              ),
            ),
          ),
        ],
      ),

      // =======================================================
      // BODY
      // =======================================================

      body: Stack(
        fit: StackFit.expand,
        children: [

          // ---------------------------------------------------
          // FULL SCREEN CINEMATIC VIDEO
          // ---------------------------------------------------

          Positioned.fill(
            child: Video(
              controller: _backgroundVideoController,
              fit: BoxFit.cover,
            ),
          ),

          // ---------------------------------------------------
          // DARK CINEMATIC OVERLAY
          // ---------------------------------------------------

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(.48),
                    Colors.black.withOpacity(.18),
                    Colors.black.withOpacity(.38),
                    Colors.black.withOpacity(.88),
                  ],
                  stops: const [
                    0.0,
                    0.28,
                    0.62,
                    1.0,
                  ],
                ),
              ),
            ),
          ),

          // ---------------------------------------------------
          // CONTENT
          // ---------------------------------------------------

          SafeArea(
            bottom: false,
            child: _loading
                ? const Center(
                    child:
                        CircularProgressIndicator(
                      color: primaryLight,
                    ),
                  )
                : RefreshIndicator(
                    color: primaryLight,
                    backgroundColor: surface2,
                    onRefresh: _loadHomes,
                    child: ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding:
                          const EdgeInsets.fromLTRB(
                        18,
                        72,
                        18,
                        35,
                      ),
                      children: [
                        FadeTransition(
                          opacity:
                              _animationController,
                          child: SlideTransition(
                            position:
                                Tween<Offset>(
                              begin:
                                  const Offset(0, .12),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent:
                                    _animationController,
                                curve: Curves
                                    .easeOutCubic,
                              ),
                            ),
                            child: _greeting(
                              displayName,
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        if (_homes.isEmpty)
                          _emptyHomeState()
                        else
                          ..._homes.map(
                            (home) => _homeCard(home),
                          ),

                        _addHomeButton(),

                        const SizedBox(height: 35),

                        const Center(
                          child: Text(
                            'SMARTHOMEX',
                            style: TextStyle(
                              color: Colors.white24,
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        const Center(
                          child: Text(
                            'Smart living. Simple control.',
                            style: TextStyle(
                              color: Colors.white12,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // GREETING
  // =========================================================

  Widget _greeting(String name) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 5,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primaryLight,
                    primary,
                  ],
                ),
                borderRadius:
                    BorderRadius.circular(5),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'WELCOME BACK',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.7,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.7,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 13),
        const Text(
          'Control your home from anywhere.',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // ADD HOME BUTTON
  // =========================================================

  Widget _addHomeButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius:
              BorderRadius.circular(19),
          onTap: _addHome,
          child: Container(
            decoration: BoxDecoration(
              color: primary.withOpacity(.12),
              borderRadius:
                  BorderRadius.circular(19),
              border: Border.all(
                color: primary.withOpacity(.35),
              ),
            ),
            child: const Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_home_rounded,
                  color: primaryLight,
                  size: 20,
                ),
                SizedBox(width: 9),
                Text(
                  'Add Another Home',
                  style: TextStyle(
                    color: primaryLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}