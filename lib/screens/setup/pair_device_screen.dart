import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/responsive.dart';
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
  State<PairDeviceScreen> createState() => _PairDeviceScreenState();
}

class _PairDeviceScreenState extends State<PairDeviceScreen> {
  final DeviceService _deviceService = DeviceService();

  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

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
      _showMessage('Enter the ESP32 IP address.');
      return;
    }

    setState(() {
      _checking = true;
      _deviceInfo = null;
    });

    try {
      final info = await _deviceService.getDeviceInfo(ip);

      if (!mounted) return;

      setState(() {
        _deviceInfo = info;
        _nameController.text =
            info['name'] as String? ?? 'SmartHomeX ESP32';
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
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

    final deviceUid = _deviceInfo!['device_uid'] as String;

    final relayCount =
        (_deviceInfo!['relay_count'] as num?)?.toInt() ?? 4;

    setState(() {
      _pairing = true;
    });

    try {
      await _deviceService.pairDevice(
        roomId: widget.roomId,
        ipAddress: _ipController.text.trim(),
        deviceUid: deviceUid,
        name: _nameController.text.trim(),
        relayCount: relayCount,
      );

      if (!mounted) return;

      _showMessage('ESP32 paired successfully!');

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _pairing = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: SmartHomeColors.textPrimary,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: SmartHomeColors.surfaceElevated,
        margin: EdgeInsets.symmetric(
          horizontal: SmartHomeResponsive.horizontalPadding(context),
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(
            color: SmartHomeColors.border,
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
        SmartHomeResponsive.maxContentWidth(context);

    return Scaffold(
      backgroundColor: SmartHomeColors.background,
      appBar: AppBar(
        backgroundColor: SmartHomeColors.background,
        foregroundColor: SmartHomeColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: horizontalPadding,
        title: const Text(
          'Pair Device',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -.2,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
            ),
            child: ListView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                12,
                horizontalPadding,
                32,
              ),
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildRoomCard(),
                const SizedBox(height: 26),
                _sectionLabel('DEVICE CONNECTION'),
                const SizedBox(height: 10),
                _buildIpField(),
                const SizedBox(height: 12),
                _buildFindButton(),
                if (_deviceInfo != null) ...[
                  const SizedBox(height: 28),
                  _sectionLabel('DEVICE FOUND'),
                  const SizedBox(height: 10),
                  _buildDeviceFoundCard(),
                ],
                const SizedBox(height: 24),
                _buildInfoCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connect your ESP32',
          style: TextStyle(
            color: SmartHomeColors.textPrimary,
            fontSize: SmartHomeResponsive.titleSize(context),
            fontWeight: FontWeight.w800,
            letterSpacing: -.7,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Find your SmartHomeX controller on the local network, verify its details, and pair it with this room.',
          style: TextStyle(
            color: SmartHomeColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRoomCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SmartHomeColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: SmartHomeColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: SmartHomeColors.gold.withOpacity(.11),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: SmartHomeColors.gold.withOpacity(.25),
              ),
            ),
            child: const Icon(
              Icons.meeting_room_rounded,
              color: SmartHomeColors.goldLight,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PAIRING TO ROOM',
                  style: TextStyle(
                    color: SmartHomeColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.roomName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SmartHomeColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: SmartHomeColors.gold,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildIpField() {
    return TextField(
      controller: _ipController,
      keyboardType: TextInputType.url,
      textInputAction: TextInputAction.search,
      style: const TextStyle(
        color: SmartHomeColors.textPrimary,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: 'Example: 10.159.167.161',
        hintStyle: const TextStyle(
          color: SmartHomeColors.textMuted,
        ),
        prefixIcon: const Icon(
          Icons.wifi_rounded,
          color: SmartHomeColors.gold,
        ),
        filled: true,
        fillColor: SmartHomeColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: SmartHomeColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: SmartHomeColors.gold,
            width: 1.2,
          ),
        ),
      ),
      onSubmitted: (_) => _checkDevice(),
    );
  }

  Widget _buildFindButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _checking ? null : _checkDevice,
        icon: _checking
            ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: SmartHomeColors.background,
                ),
              )
            : const Icon(Icons.search_rounded),
        label: Text(
          _checking ? 'Checking Device...' : 'Find Device',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: SmartHomeColors.gold,
          foregroundColor: SmartHomeColors.background,
          disabledBackgroundColor:
              SmartHomeColors.gold.withOpacity(.35),
          disabledForegroundColor:
              SmartHomeColors.background.withOpacity(.7),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceFoundCard() {
    final deviceUid =
        _deviceInfo!['device_uid']?.toString() ?? '-';
    final ipAddress =
        _deviceInfo!['ip_address']?.toString() ??
            _ipController.text;
    final relayCount =
        '${_deviceInfo!['relay_count'] ?? 4}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SmartHomeColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: SmartHomeColors.gold.withOpacity(.42),
        ),
        boxShadow: [
          BoxShadow(
            color: SmartHomeColors.gold.withOpacity(.06),
            blurRadius: 25,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: SmartHomeColors.online.withOpacity(.11),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: SmartHomeColors.online.withOpacity(.22),
                  ),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: SmartHomeColors.online,
                  size: 28,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESP32 Found',
                      style: TextStyle(
                        color: SmartHomeColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Controller is reachable',
                      style: TextStyle(
                        color: SmartHomeColors.online,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _infoRow('Device UID', deviceUid),
          _infoRow('IP Address', ipAddress),
          _infoRow('Relays', relayCount),
          const SizedBox(height: 10),
          const Text(
            'DEVICE NAME',
            style: TextStyle(
              color: SmartHomeColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            textInputAction: TextInputAction.done,
            style: const TextStyle(
              color: SmartHomeColors.textPrimary,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'SmartHomeX ESP32',
              hintStyle: const TextStyle(
                color: SmartHomeColors.textMuted,
              ),
              filled: true,
              fillColor: SmartHomeColors.surfaceElevated,
              prefixIcon: const Icon(
                Icons.devices_other_rounded,
                color: SmartHomeColors.gold,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 15,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: SmartHomeColors.border,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: SmartHomeColors.gold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _pairing ? null : _pairDevice,
              icon: _pairing
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: SmartHomeColors.background,
                      ),
                    )
                  : const Icon(Icons.link_rounded),
              label: Text(
                _pairing ? 'Pairing...' : 'Pair This Device',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: SmartHomeColors.gold,
                foregroundColor: SmartHomeColors.background,
                disabledBackgroundColor:
                    SmartHomeColors.gold.withOpacity(.35),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              title,
              style: const TextStyle(
                color: SmartHomeColors.textMuted,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: SmartHomeColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SmartHomeColors.surface.withOpacity(.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: SmartHomeColors.border,
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: SmartHomeColors.gold,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Make sure your phone/computer and ESP32 are connected to the same Wi-Fi network.',
              style: TextStyle(
                color: SmartHomeColors.textSecondary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
