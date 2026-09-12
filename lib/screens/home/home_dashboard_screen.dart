import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/device_service.dart';
import '../../services/home_service.dart';
import '../setup/pair_device_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() =>
      _HomeDashboardScreenState();
}

class _HomeDashboardScreenState
    extends State<HomeDashboardScreen> {
  final HomeService _homeService = HomeService();
  final AuthService _authService = AuthService();
  final DeviceService _deviceService = DeviceService();

  List<Map<String, dynamic>> _homes = [];

  final Map<String, List<Map<String, dynamic>>> _rooms = {};

  final Map<String, List<Map<String, dynamic>>> _devices = {};

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHomes();
  }

  // ==========================================
  // LOAD HOMES, ROOMS & DEVICES
  // ==========================================

  Future<void> _loadHomes() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final homes = await _homeService.getHomes();

      final rooms =
          <String, List<Map<String, dynamic>>>{};

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
      });
    } catch (e) {
      debugPrint(
        'Dashboard loading error: $e',
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        'Could not load your homes.',
      );
    }
  }

  // ==========================================
  // ADD HOME
  // ==========================================

  Future<void> _addHome() async {
    final name = await _showNameDialog(
      title: 'Add Home',
      hint: 'Home name',
    );

    if (name == null || name.trim().isEmpty) {
      return;
    }

    try {
      await _homeService.createHome(name);

      await _loadHomes();

      if (!mounted) return;

      _showMessage(
        'Home created successfully.',
      );
    } catch (e) {
      debugPrint('Create home error: $e');

      _showMessage(
        'Could not create home.',
      );
    }
  }

  // ==========================================
  // ADD ROOM
  // ==========================================

  Future<void> _addRoom(
    String homeId,
  ) async {
    final name = await _showNameDialog(
      title: 'Add Room',
      hint: 'Room name',
    );

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

      _showMessage(
        'Room added successfully.',
      );
    } catch (e) {
      debugPrint('Create room error: $e');

      _showMessage(
        'Could not create room.',
      );
    }
  }

  // ==========================================
  // RENAME HOME
  // ==========================================

  Future<void> _renameHome(
    String homeId,
    String currentName,
  ) async {
    final name = await _showNameDialog(
      title: 'Rename Home',
      hint: 'Home name',
      initialValue: currentName,
    );

    if (name == null || name.trim().isEmpty) {
      return;
    }

    try {
      await _homeService.renameHome(
        homeId,
        name,
      );

      await _loadHomes();
    } catch (e) {
      debugPrint('Rename home error: $e');

      _showMessage(
        'Could not rename home.',
      );
    }
  }

  // ==========================================
  // RENAME ROOM
  // ==========================================

  Future<void> _renameRoom(
    String roomId,
    String currentName,
  ) async {
    final name = await _showNameDialog(
      title: 'Rename Room',
      hint: 'Room name',
      initialValue: currentName,
    );

    if (name == null || name.trim().isEmpty) {
      return;
    }

    try {
      await _homeService.renameRoom(
        roomId: roomId,
        name: name,
      );

      await _loadHomes();
    } catch (e) {
      debugPrint('Rename room error: $e');

      _showMessage(
        'Could not rename room.',
      );
    }
  }

  // ==========================================
  // DELETE HOME
  // ==========================================

  Future<void> _deleteHome(
    String homeId,
    String homeName,
  ) async {
    final confirmed = await _confirmDelete(
      title: 'Delete Home?',
      message:
          'Delete "$homeName" and all rooms inside it?',
    );

    if (!confirmed) return;

    try {
      await _homeService.deleteHome(homeId);

      await _loadHomes();
    } catch (e) {
      debugPrint('Delete home error: $e');

      _showMessage(
        'Could not delete home.',
      );
    }
  }

  // ==========================================
  // DELETE ROOM
  // ==========================================

  Future<void> _deleteRoom(
    String roomId,
    String roomName,
  ) async {
    final confirmed = await _confirmDelete(
      title: 'Delete Room?',
      message:
          'Delete "$roomName"?',
    );

    if (!confirmed) return;

    try {
      await _homeService.deleteRoom(roomId);

      await _loadHomes();
    } catch (e) {
      debugPrint('Delete room error: $e');

      _showMessage(
        'Could not delete room.',
      );
    }
  }

  // ==========================================
  // UNPAIR DEVICE
  // ==========================================

  Future<void> _unpairDevice(
    String deviceId,
    String roomName,
  ) async {
    final confirmed = await _confirmDelete(
      title: 'Unpair Device?',
      message:
          'Remove the ESP32 from "$roomName"?',
    );

    if (!confirmed) return;

    try {
      await _deviceService.deleteDevice(
        deviceId,
      );

      await _loadHomes();

      if (!mounted) return;

      _showMessage(
        'ESP32 unpaired successfully.',
      );
    } catch (e) {
      debugPrint(
        'Unpair device error: $e',
      );

      _showMessage(
        'Could not unpair device.',
      );
    }
  }

  // ==========================================
  // OPEN PAIRING
  // ==========================================

  Future<void> _openPairDevice(
    String roomId,
    String roomName,
  ) async {
    final paired =
        await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PairDeviceScreen(
          roomId: roomId,
          roomName: roomName,
        ),
      ),
    );

    if (paired == true) {
      await _loadHomes();
    }
  }

  // ==========================================
  // NAME DIALOG
  // ==========================================

  Future<String?> _showNameDialog({
    required String title,
    required String hint,
    String initialValue = '',
  }) async {
    final controller =
        TextEditingController(
      text: initialValue,
    );

    final result =
        await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              const Color(0xFF1E293B),
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization:
                TextCapitalization.words,
            decoration: InputDecoration(
              hintText: hint,
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
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  controller.text.trim(),
                );
              },
              child: const Text(
                'Save',
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    return result;
  }

  // ==========================================
  // CONFIRM DELETE
  // ==========================================

  Future<bool> _confirmDelete({
    required String title,
    required String message,
  }) async {
    final result =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              const Color(0xFF1E293B),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // ==========================================
  // LOGOUT
  // ==========================================

  Future<void> _logout() async {
    await _authService.signOut();
  }

  // ==========================================
  // MESSAGE
  // ==========================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final user =
        _authService.currentUser;

    final fullName =
        user?.userMetadata?['full_name']
            as String?;

    final displayName =
        fullName?.trim().isNotEmpty == true
            ? fullName!
            : 'SmartHomeX User';

    return Scaffold(
      backgroundColor:
          const Color(0xFF0F172A),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF0F172A),
        elevation: 0,
        title: const Text(
          'SmartHomeX',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(
              Icons.logout_rounded,
            ),
          ),
        ],
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: _addHome,
        backgroundColor:
            const Color(0xFF34B7F1),
        foregroundColor:
            Colors.white,
        icon: const Icon(
          Icons.add_home_rounded,
        ),
        label: const Text(
          'Add Home',
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _loadHomes,
        color:
            const Color(0xFF34B7F1),

        child: _loading
            ? const Center(
                child:
                    CircularProgressIndicator(
                  color: Color(
                    0xFF34B7F1,
                  ),
                ),
              )
            : ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),

                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  100,
                ),

                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(
                      color: Colors.white
                          .withOpacity(.55),
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    displayName,
                    style: const TextStyle(
                      color:
                          Colors.white,
                      fontSize: 28,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 28,
                  ),

                  if (_homes.isEmpty)
                    _emptyState()
                  else
                    ..._homes.map(
                      (home) =>
                          _homeCard(home),
                    ),
                ],
              ),
      ),
    );
  }

  // ==========================================
  // HOME CARD
  // ==========================================

  Widget _homeCard(
    Map<String, dynamic> home,
  ) {
    final homeId =
        home['id'] as String;

    final homeName =
        home['name'] as String? ??
            'My Home';

    final rooms =
        _rooms[homeId] ??
            <Map<String, dynamic>>[];

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 20,
      ),

      decoration: BoxDecoration(
        color:
            const Color(0xFF1E293B),
        borderRadius:
            BorderRadius.circular(
          24,
        ),
      ),

      child: Padding(
        padding:
            const EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFF34B7F1,
                    ).withOpacity(.12),
                    borderRadius:
                        BorderRadius.circular(
                      15,
                    ),
                  ),
                  child:
                      const Icon(
                    Icons.home_rounded,
                    color:
                        Color(0xFF34B7F1),
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
                        homeName,
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize: 19,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 3,
                      ),

                      Text(
                        '${rooms.length} room${rooms.length == 1 ? '' : 's'}',
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

                PopupMenuButton<String>(
                  onSelected:
                      (value) {
                    if (value ==
                        'rename') {
                      _renameHome(
                        homeId,
                        homeName,
                      );
                    } else if (value ==
                        'delete') {
                      _deleteHome(
                        homeId,
                        homeName,
                      );
                    }
                  },
                  itemBuilder:
                      (context) =>
                          const [
                    PopupMenuItem(
                      value:
                          'rename',
                      child:
                          Text(
                        'Rename',
                      ),
                    ),
                    PopupMenuItem(
                      value:
                          'delete',
                      child:
                          Text(
                        'Delete',
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(
              height: 18,
            ),

            const Divider(
              color: Colors.white10,
            ),

            const SizedBox(
              height: 10,
            ),

            if (rooms.isEmpty)
              Padding(
                padding:
                    const EdgeInsets
                        .symmetric(
                  vertical: 15,
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons
                          .meeting_room_outlined,
                      color:
                          Colors.white30,
                      size: 35,
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    const Text(
                      'No rooms yet',
                      style:
                          TextStyle(
                        color:
                            Colors.white54,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    const Text(
                      'Add your first room',
                      style:
                          TextStyle(
                        color:
                            Colors.white30,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...rooms.map(
                (room) =>
                    _roomTile(
                  homeId,
                  room,
                ),
              ),

            const SizedBox(
              height: 8,
            ),

            SizedBox(
              width:
                  double.infinity,
              child:
                  OutlinedButton.icon(
                onPressed: () =>
                    _addRoom(
                  homeId,
                ),

                icon:
                    const Icon(
                  Icons.add_rounded,
                ),

                label:
                    const Text(
                  'Add Room',
                ),

                style:
                    OutlinedButton.styleFrom(
                  foregroundColor:
                      const Color(
                    0xFF34B7F1,
                  ),
                  side:
                      const BorderSide(
                    color:
                        Color(
                      0xFF34B7F1,
                    ),
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // ROOM TILE
  // ==========================================

  Widget _roomTile(
    String homeId,
    Map<String, dynamic> room,
  ) {
    final roomId =
        room['id'] as String;

    final roomName =
        room['name'] as String? ??
            'Room';

    final devices =
        _devices[roomId] ??
            <Map<String, dynamic>>[];

    final hasDevice =
        devices.isNotEmpty;

    final device =
        hasDevice
            ? devices.first
            : null;

    final deviceName =
        device?['name']
                as String? ??
            'ESP32';

    final deviceUid =
        device?['device_uid']
                as String? ??
            '';

    final isOnline =
        device?['is_online']
                as bool? ??
            false;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 8,
      ),

      decoration: BoxDecoration(
        color: const Color(
          0xFF0F172A,
        ).withOpacity(.55),
        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),

      child: ListTile(
        onTap: () async {
          if (hasDevice) {
            _showDeviceInfo(
              roomName: roomName,
              deviceName: deviceName,
              deviceUid: deviceUid,
              ipAddress:
                  device?['ip_address']
                          as String? ??
                      '',
              isOnline: isOnline,
            );
          } else {
            await _openPairDevice(
              roomId,
              roomName,
            );
          }
        },

        leading: Container(
          width: 42,
          height: 42,
          decoration:
              BoxDecoration(
            color: hasDevice
                ? const Color(
                    0xFF34B7F1,
                  ).withOpacity(.12)
                : Colors.white
                    .withOpacity(.06),
            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),
          child: Icon(
            hasDevice
                ? Icons
                    .devices_rounded
                : Icons
                    .meeting_room_rounded,
            color: hasDevice
                ? const Color(
                    0xFF34B7F1,
                  )
                : Colors.white70,
          ),
        ),

        title: Text(
          roomName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight:
                FontWeight.w600,
          ),
        ),

        subtitle: hasDevice
            ? Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration:
                        BoxDecoration(
                      color: isOnline
                          ? Colors.green
                          : Colors.grey,
                      shape:
                          BoxShape.circle,
                    ),
                  ),

                  const SizedBox(
                    width: 6,
                  ),

                  Expanded(
                    child: Text(
                      isOnline
                          ? '$deviceName • Online'
                          : '$deviceName • Offline',
                      style:
                          const TextStyle(
                        color:
                            Colors.white54,
                        fontSize: 12,
                      ),
                      overflow:
                          TextOverflow
                              .ellipsis,
                    ),
                  ),
                ],
              )
            : const Text(
                'Tap to pair ESP32',
                style: TextStyle(
                  color:
                      Colors.white38,
                  fontSize: 12,
                ),
              ),

        trailing: hasDevice
            ? PopupMenuButton<String>(
                onSelected:
                    (value) {
                  if (value ==
                      'device_info') {
                    _showDeviceInfo(
                      roomName:
                          roomName,
                      deviceName:
                          deviceName,
                      deviceUid:
                          deviceUid,
                      ipAddress:
                          device?[
                                  'ip_address']
                              as String? ??
                          '',
                      isOnline:
                          isOnline,
                    );
                  }

                  if (value ==
                      'unpair') {
                    _unpairDevice(
                      device!['id']
                          as String,
                      roomName,
                    );
                  }
                },
                itemBuilder:
                    (context) =>
                        const [
                  PopupMenuItem(
                    value:
                        'device_info',
                    child:
                        Text(
                      'Device Info',
                    ),
                  ),
                  PopupMenuItem(
                    value:
                        'unpair',
                    child:
                        Text(
                      'Unpair Device',
                    ),
                  ),
                ],
              )
            : const Icon(
                Icons
                    .chevron_right_rounded,
                color:
                    Colors.white38,
              ),
      ),
    );
  }

  // ==========================================
  // DEVICE INFO
  // ==========================================

  void _showDeviceInfo({
    required String roomName,
    required String deviceName,
    required String deviceUid,
    required String ipAddress,
    required bool isOnline,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          const Color(0xFF1E293B),
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.all(24),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFF34B7F1,
                        ).withOpacity(.12),
                        borderRadius:
                            BorderRadius
                                .circular(
                          14,
                        ),
                      ),
                      child:
                          const Icon(
                        Icons
                            .devices_rounded,
                        color:
                            Color(
                          0xFF34B7F1,
                        ),
                      ),
                    ),

                    const SizedBox(
                      width: 14,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            deviceName,
                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              fontSize:
                                  19,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                          Text(
                            roomName,
                            style:
                                const TextStyle(
                              color:
                                  Colors.white54,
                              fontSize:
                                  12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 22,
                ),

                _deviceInfoRow(
                  'Status',
                  isOnline
                      ? 'Online'
                      : 'Offline',
                ),

                _deviceInfoRow(
                  'Device UID',
                  deviceUid.isEmpty
                      ? '-'
                      : deviceUid,
                ),

                _deviceInfoRow(
                  'IP Address',
                  ipAddress.isEmpty
                      ? '-'
                      : ipAddress,
                ),

                const SizedBox(
                  height: 12,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _deviceInfoRow(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              title,
              style:
                  const TextStyle(
                color:
                    Colors.white54,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
                  const TextStyle(
                color:
                    Colors.white,
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

  // ==========================================
  // EMPTY STATE
  // ==========================================

  Widget _emptyState() {
    return Container(
      padding:
          const EdgeInsets.all(30),

      decoration:
          BoxDecoration(
        color:
            const Color(0xFF1E293B),
        borderRadius:
            BorderRadius.circular(
          24,
        ),
      ),

      child: const Column(
        children: [
          Icon(
            Icons.home_work_outlined,
            color:
                Color(0xFF34B7F1),
            size: 55,
          ),

          SizedBox(
            height: 18,
          ),

          Text(
            'No homes yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          SizedBox(
            height: 8,
          ),

          Text(
            'Create your first home to start adding rooms and smart devices.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color:
                  Colors.white54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}