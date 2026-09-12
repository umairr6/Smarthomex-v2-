import 'package:flutter/material.dart';

import '../../services/device_service.dart';

class PairDeviceScreen extends StatefulWidget {
  final String roomId;
  final String roomName;

  const PairDeviceScreen({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  State<PairDeviceScreen> createState() =>
      _PairDeviceScreenState();
}

class _PairDeviceScreenState
    extends State<PairDeviceScreen> {
  final DeviceService _deviceService =
      DeviceService();

  final TextEditingController _ipController =
      TextEditingController();

  final TextEditingController _nameController =
      TextEditingController();

  bool _checking = false;
  bool _pairing = false;

  Map<String, dynamic>? _deviceInfo;

  @override
  void dispose() {
    _ipController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // ==========================================
  // CHECK DEVICE
  // ==========================================

  Future<void> _checkDevice() async {
    FocusScope.of(context).unfocus();

    final ip = _ipController.text.trim();

    if (ip.isEmpty) {
      _showMessage(
        'Enter the ESP32 IP address.',
      );
      return;
    }

    setState(() {
      _checking = true;
      _deviceInfo = null;
    });

    try {
      final info =
          await _deviceService.getDeviceInfo(
        ip,
      );

      if (!mounted) return;

      setState(() {
        _deviceInfo = info;

        _nameController.text =
            info['name'] as String? ??
                'SmartHomeX ESP32';
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _checking = false;
      });
    }
  }

  // ==========================================
  // PAIR
  // ==========================================

  Future<void> _pairDevice() async {
    if (_deviceInfo == null) return;

    final deviceUid =
        _deviceInfo!['device_uid']
            as String;

    final relayCount =
        (_deviceInfo!['relay_count']
                as num?)
            ?.toInt() ??
        4;

    setState(() {
      _pairing = true;
    });

    try {
      await _deviceService.pairDevice(
        roomId: widget.roomId,
        ipAddress:
            _ipController.text.trim(),
        deviceUid: deviceUid,
        name:
            _nameController.text.trim(),
        relayCount: relayCount,
      );

      if (!mounted) return;

      _showMessage(
        'ESP32 paired successfully!',
      );

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _pairing = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF0F172A),
        title: const Text(
          'Pair Device',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(20),
        children: [
          // ====================================
          // ROOM
          // ====================================

          Container(
            padding:
                const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color:
                  const Color(0xFF1E293B),
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFF34B7F1,
                    ).withOpacity(.12),
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                  child: const Icon(
                    Icons.meeting_room_rounded,
                    color:
                        Color(0xFF34B7F1),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pairing to room',
                        style:
                            TextStyle(
                          color:
                              Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.roomName,
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          const Text(
            'ESP32 IP Address',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: _ipController,
            keyboardType:
                TextInputType.url,
            decoration:
                InputDecoration(
              hintText:
                  'Example: 10.159.167.161',
              prefixIcon:
                  const Icon(
                Icons.wifi_rounded,
              ),
              filled: true,
              fillColor:
                  const Color(
                0xFF1E293B,
              ),
              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
                borderSide:
                    BorderSide.none,
              ),
            ),
            onSubmitted: (_) =>
                _checkDevice(),
          ),

          const SizedBox(height: 15),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _checking
                  ? null
                  : _checkDevice,
              icon: _checking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.search_rounded,
                    ),
              label: Text(
                _checking
                    ? 'Checking Device...'
                    : 'Find Device',
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFF34B7F1,
                ),
                foregroundColor:
                    Colors.white,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),
            ),
          ),

          // ====================================
          // DEVICE FOUND
          // ====================================

          if (_deviceInfo != null) ...[
            const SizedBox(height: 25),

            Container(
              padding:
                  const EdgeInsets.all(20),
              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFF1E293B,
                ),
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
                border: Border.all(
                  color:
                      const Color(
                    0xFF34B7F1,
                  ).withOpacity(.35),
                ),
              ),
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
                              Colors.green
                                  .withOpacity(
                            .12,
                          ),
                          shape:
                              BoxShape.circle,
                        ),
                        child:
                            const Icon(
                          Icons
                              .check_circle_rounded,
                          color:
                              Colors.green,
                          size: 30,
                        ),
                      ),
                      const SizedBox(
                        width: 14,
                      ),
                      const Expanded(
                        child: Text(
                          'ESP32 Found',
                          style:
                              TextStyle(
                            color:
                                Colors.white,
                            fontSize: 19,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  _infoRow(
                    'Device UID',
                    _deviceInfo![
                            'device_uid']
                        ?.toString() ??
                        '-',
                  ),

                  _infoRow(
                    'IP Address',
                    _deviceInfo![
                            'ip_address']
                        ?.toString() ??
                        _ipController
                            .text,
                  ),

                  _infoRow(
                    'Relays',
                    '${_deviceInfo!['relay_count'] ?? 4}',
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  const Text(
                    'Device Name',
                    style:
                        TextStyle(
                      color:
                          Colors.white70,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(
                    height: 7,
                  ),

                  TextField(
                    controller:
                        _nameController,
                    decoration:
                        InputDecoration(
                      filled: true,
                      fillColor:
                          const Color(
                        0xFF0F172A,
                      ),
                      prefixIcon:
                          const Icon(
                        Icons
                            .devices_other_rounded,
                      ),
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          14,
                        ),
                        borderSide:
                            BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  SizedBox(
                    width:
                        double.infinity,
                    height: 52,
                    child:
                        ElevatedButton.icon(
                      onPressed:
                          _pairing
                              ? null
                              : _pairDevice,
                      icon: _pairing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2,
                                color:
                                    Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons
                                  .link_rounded,
                            ),
                      label: Text(
                        _pairing
                            ? 'Pairing...'
                            : 'Pair This Device',
                      ),
                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            Colors.green,
                        foregroundColor:
                            Colors.white,
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
          ],

          const SizedBox(height: 25),

          Container(
            padding:
                const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  Colors.white.withOpacity(
                .04,
              ),
              borderRadius:
                  BorderRadius.circular(
                16,
              ),
            ),
            child: const Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color:
                      Colors.white38,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Make sure your phone/computer and ESP32 are connected to the same Wi-Fi network.',
                    style: TextStyle(
                      color:
                          Colors.white54,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
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
}