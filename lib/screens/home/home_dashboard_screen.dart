import 'package:flutter/material.dart';

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

class _HomeDashboardScreenState
    extends State<HomeDashboardScreen> {
  final HomeService _homeService = HomeService();
  final DeviceService _deviceService = DeviceService();
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> _homes = [];

  final Map<String, List<Map<String, dynamic>>> _rooms = {};

  final Map<String, List<Map<String, dynamic>>> _devices = {};

  bool _loading = true;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _loadHomes();
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
      final devices =
          <String, List<Map<String, dynamic>>>{};

      for (final home in homes) {
        final homeId = home['id'] as String;

        final homeRooms =
            await _homeService.getRooms(homeId);

        rooms[homeId] = homeRooms;

        for (final room in homeRooms) {
          final roomId = room['id'] as String;

          final roomDevices =
              await _deviceService.getRoomDevices(
            roomId,
          );

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
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _refreshing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not load your home: $e',
          ),
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
        return AlertDialog(
          backgroundColor: const Color(0xff1E293B),
          title: const Text('Add Home'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization:
                TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Home name',
              prefixIcon:
                  Icon(Icons.home_rounded),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value =
                    controller.text.trim();

                if (value.isEmpty) return;

                Navigator.pop(
                  dialogContext,
                  value,
                );
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (name == null || name.trim().isEmpty) {
      return;
    }

    try {
      await _homeService.createHome(name);

      await _loadHomes();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text('Home added successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Could not add home: $e',
          ),
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
        return AlertDialog(
          backgroundColor: const Color(0xff1E293B),
          title: const Text('Add Room'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization:
                TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Room name',
              prefixIcon:
                  Icon(Icons.meeting_room_rounded),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value =
                    controller.text.trim();

                if (value.isEmpty) return;

                Navigator.pop(
                  dialogContext,
                  value,
                );
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (name == null || name.trim().isEmpty) {
      return;
    }

    try {
      await _homeService.createRoom(
        homeId: homeId,
        name: name,
      );

      await _loadHomes();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text('Room added successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Could not add room: $e',
          ),
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
        return AlertDialog(
          backgroundColor: const Color(0xff1E293B),
          title: const Text('Rename Home'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization:
                TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Home name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value =
                    controller.text.trim();

                if (value.isEmpty) return;

                Navigator.pop(
                  dialogContext,
                  value,
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (name == null || name.trim().isEmpty) {
      return;
    }

    try {
      await _homeService.renameHome(
        home['id'] as String,
        name,
      );

      await _loadHomes();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Could not rename home: $e',
          ),
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
        return AlertDialog(
          backgroundColor: const Color(0xff1E293B),
          title: const Text('Rename Room'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization:
                TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Room name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value =
                    controller.text.trim();

                if (value.isEmpty) return;

                Navigator.pop(
                  dialogContext,
                  value,
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (name == null || name.trim().isEmpty) {
      return;
    }

    try {
      await _homeService.renameRoom(
        roomId: room['id'] as String,
        name: name,
      );

      await _loadHomes();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Could not rename room: $e',
          ),
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              const Color(0xff1E293B),
          title: const Text('Delete Home?'),
          content: Text(
            'Delete "$homeName" and all rooms '
            'inside it?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _homeService.deleteHome(
        home['id'] as String,
      );

      await _loadHomes();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text('Home deleted.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Could not delete home: $e',
          ),
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              const Color(0xff1E293B),
          title: const Text('Delete Room?'),
          content: Text(
            'Delete "$roomName"? '
            'Any paired ESP32 in this room '
            'will also be removed.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _homeService.deleteRoom(
        room['id'] as String,
      );

      await _loadHomes();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text('Room deleted.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Could not delete room: $e',
          ),
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              const Color(0xff1E293B),
          title: const Text('Unpair ESP32?'),
          content: Text(
            'Remove "$deviceName" from this room?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Unpair'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _deviceService.deleteDevice(
        device['id'] as String,
      );

      await _loadHomes();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'ESP32 unpaired successfully.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Could not unpair device: $e',
          ),
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
  // OPEN ROOM CONTROL
  // =========================================================

  Future<void> _openRoomControl(
    Map<String, dynamic> room,
    Map<String, dynamic> device,
  ) async {
    final ipAddress =
        device['ip_address'] as String? ?? '';

    if (ipAddress.trim().isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'This device does not have an IP address.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

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
  // ROOM MENU
  // =========================================================

  void _showRoomMenu(
    Map<String, dynamic> room,
  ) {
    final roomDevices =
        _devices[room['id'] as String] ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor:
          const Color(0xff1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              14,
              20,
              20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 45,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 20),

                ListTile(
                  leading: _menuIcon(
                    Icons.edit_rounded,
                  ),
                  title: const Text(
                    'Rename Room',
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _renameRoom(room);
                  },
                ),

                if (roomDevices.isNotEmpty)
                  ListTile(
                    leading: _menuIcon(
                      Icons.router_rounded,
                    ),
                    title: const Text(
                      'Device Information',
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);

                      _showDeviceInfo(
                        roomDevices.first,
                        room,
                      );
                    },
                  ),

                if (roomDevices.isNotEmpty)
                  ListTile(
                    leading: _menuIcon(
                      Icons.link_off_rounded,
                      color: Colors.red,
                    ),
                    title: const Text(
                      'Unpair ESP32',
                      style: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);

                      _unpairDevice(
                        roomDevices.first,
                      );
                    },
                  ),

                ListTile(
                  leading: _menuIcon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'Delete Room',
                    style: TextStyle(
                      color: Colors.red,
                    ),
                  ),
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
        return AlertDialog(
          backgroundColor:
              const Color(0xff1E293B),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(
                    0xff34B7F1,
                  ).withOpacity(.12),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.router_rounded,
                  color:
                      Color(0xff34B7F1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _infoRow(
                'Room',
                room['name'] as String? ??
                    'Room',
              ),
              _infoRow(
                'Device UID',
                uid,
              ),
              _infoRow(
                'IP Address',
                ip,
              ),
              _infoRow(
                'Relays',
                '$relayCount',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
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
      backgroundColor:
          const Color(0xff1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              14,
              20,
              20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 45,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 20),

                ListTile(
                  leading: _menuIcon(
                    Icons.edit_rounded,
                  ),
                  title: const Text(
                    'Rename Home',
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _renameHome(home);
                  },
                ),

                ListTile(
                  leading: _menuIcon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'Delete Home',
                    style: TextStyle(
                      color: Colors.red,
                    ),
                  ),
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
  // ICON HELPERS
  // =========================================================

  Widget _menuIcon(
    IconData icon, {
    Color? color,
  }) {
    final iconColor =
        color ?? const Color(0xff34B7F1);

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(.10),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: 21,
      ),
    );
  }

  Widget _infoRow(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ROOM TILE
  // =========================================================

  Widget _roomTile(
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

    final deviceName =
        device?['name'] as String? ??
            'SmartHomeX ESP32';

    final deviceUid =
        device?['device_uid'] as String? ??
            '';

    final isOnline =
        device?['is_online'] as bool? ??
            false;

    return Container(
      margin:
          const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xff0F172A)
            .withOpacity(.65),
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius:
              BorderRadius.circular(18),
          onTap: hasDevice
              ? () => _openRoomControl(
                    room,
                    device!,
                  )
              : () => _pairDevice(room),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(
                      0xff34B7F1,
                    ).withOpacity(.10),
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.meeting_room_rounded,
                    color:
                        Color(0xff34B7F1),
                    size: 25,
                  ),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        roomName,
                        style:
                            const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 4),

                      if (hasDevice)
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration:
                                  BoxDecoration(
                                color: isOnline
                                    ? Colors.green
                                    : Colors.red,
                                shape:
                                    BoxShape.circle,
                              ),
                            ),

                            const SizedBox(
                              width: 6,
                            ),

                            Expanded(
                              child: Text(
                                '$deviceName • '
                                '${isOnline ? 'Online' : 'Offline'}',
                                maxLines: 1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        const Text(
                          'Tap to pair ESP32',
                          style: TextStyle(
                            color:
                                Colors.white38,
                            fontSize: 11,
                          ),
                        ),

                      if (hasDevice &&
                          deviceUid.isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.only(
                            top: 3,
                          ),
                          child: Text(
                            deviceUid,
                            style:
                                const TextStyle(
                              color:
                                  Colors.white24,
                              fontSize: 9,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                if (!hasDevice)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration:
                        BoxDecoration(
                      border: Border.all(
                        color:
                            const Color(
                          0xff34B7F1,
                        ).withOpacity(.45),
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                    ),
                    child: const Text(
                      'PAIR',
                      style: TextStyle(
                        color:
                            Color(0xff34B7F1),
                        fontSize: 10,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),

                if (hasDevice)
                  const Icon(
                    Icons
                        .arrow_forward_ios_rounded,
                    color: Colors.white24,
                    size: 15,
                  ),

                const SizedBox(width: 4),

                IconButton(
                  onPressed: () {
                    _showRoomMenu(room);
                  },
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white38,
                    size: 20,
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

    return Container(
      margin:
          const EdgeInsets.only(bottom: 18),
      padding:
          const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        18,
      ),
      decoration: BoxDecoration(
        color: const Color(0xff111827),
        borderRadius:
            BorderRadius.circular(24),
        border: Border.all(
          color:
              Colors.white.withOpacity(.025),
        ),
      ),
      child: Column(
        children: [
          // ===================================
          // HOME HEADER
          // ===================================

          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(
                    0xff34B7F1,
                  ).withOpacity(.10),
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.home_rounded,
                  color:
                      Color(0xff34B7F1),
                  size: 28,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      homeName,
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '${homeRooms.length} '
                      '${homeRooms.length == 1 ? 'room' : 'rooms'}',
                      style:
                          const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                onPressed: () {
                  _showHomeMenu(home);
                },
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: Colors.white54,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Container(
            height: 1,
            color: Colors.white.withOpacity(.04),
          ),

          const SizedBox(height: 14),

          // ===================================
          // ROOMS
          // ===================================

          if (homeRooms.isEmpty)
            Padding(
              padding:
                  const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.meeting_room_outlined,
                    color: Colors.white24,
                    size: 40,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'No rooms yet',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Add a room to get started.',
                    style: TextStyle(
                      color: Colors.white30,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            )
          else
            ...homeRooms.map(
              (room) => _roomTile(room),
            ),

          const SizedBox(height: 4),

          // ===================================
          // ADD ROOM
          // ===================================

          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton.icon(
              onPressed: () {
                _addRoom(homeId);
              },
              icon: const Icon(
                Icons.add_rounded,
                size: 18,
              ),
              label: const Text(
                'Add Room',
              ),
              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    const Color(
                  0xff34B7F1,
                ),
                side: BorderSide(
                  color:
                      const Color(
                    0xff34B7F1,
                  ).withOpacity(.55),
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    final fullName =
        user?.userMetadata?['full_name']
            as String?;

    final displayName =
        fullName?.trim().isNotEmpty == true
            ? fullName!.trim()
            : 'there';

    return Scaffold(
      backgroundColor:
          const Color(0xff0F172A),

      // =====================================================
      // APP BAR
      // =====================================================

      appBar: AppBar(
        backgroundColor:
            const Color(0xff0F172A),
        elevation: 0,

        title: const Text(
          'SmartHomeX',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshing
                ? null
                : _loadHomes,
            icon: _refreshing
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                      color:
                          Color(0xff34B7F1),
                    ),
                  )
                : const Icon(
                    Icons.refresh_rounded,
                  ),
          ),

          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await _authService.signOut();
            },
            icon: const Icon(
              Icons.logout_rounded,
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),

      // =====================================================
      // BODY
      // =====================================================

      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color:
                    Color(0xff34B7F1),
              ),
            )
          : RefreshIndicator(
              color:
                  const Color(0xff34B7F1),

              onRefresh: _loadHomes,

              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),

                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  30,
                ),

                children: [
                  // =========================================
                  // WELCOME
                  // =========================================

                  const Text(
                    'Welcome back,',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    displayName,
                    style:
                        const TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // =========================================
                  // HOMES
                  // =========================================

                  if (_homes.isEmpty)
                    _emptyHomeState()
                  else
                    ..._homes.map(
                      (home) => _homeCard(home),
                    ),

                  // =========================================
                  // ADD HOME
                  // =========================================

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _addHome,
                      icon: const Icon(
                        Icons.add_home_rounded,
                      ),
                      label: const Text(
                        'Add Home',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(
                          0xff34B7F1,
                        ),
                        foregroundColor:
                            const Color(
                          0xff0F172A,
                        ),
                        elevation: 0,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            17,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 35),

                  const Center(
                    child: Text(
                      'SmartHomeX',
                      style: TextStyle(
                        color: Colors.white24,
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Center(
                    child: Text(
                      'Smart living. Simple control.',
                      style: TextStyle(
                        color: Colors.white12,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // =========================================================
  // EMPTY HOME STATE
  // =========================================================

  Widget _emptyHomeState() {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 20),
      padding:
          const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color:
            const Color(0xff1E293B),
        borderRadius:
            BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(
                0xff34B7F1,
              ).withOpacity(.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.home_rounded,
              color:
                  Color(0xff34B7F1),
              size: 35,
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Create your first home',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            'Add your home and then create '
            'rooms for your ESP32 devices.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 20),

          OutlinedButton.icon(
            onPressed: _addHome,
            icon: const Icon(
              Icons.add_rounded,
            ),
            label: const Text(
              'Create Home',
            ),
            style:
                OutlinedButton.styleFrom(
              foregroundColor:
                  const Color(
                0xff34B7F1,
              ),
              side: BorderSide(
                color:
                    const Color(
                  0xff34B7F1,
                ).withOpacity(.5),
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}