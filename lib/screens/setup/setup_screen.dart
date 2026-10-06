import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../core/responsive.dart';
import '../../models/device_model.dart';
import '../../providers/device_provider.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../home/home_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final TextEditingController _ipController = TextEditingController();

  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  bool _isConnecting = false;

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _connectDevice() async {
    final ipAddress = _ipController.text.trim();

    if (ipAddress.isEmpty) {
      _showMessage('Please enter ESP32 IP address.');
      return;
    }

    setState(() {
      _isConnecting = true;
    });

    final connected = await _apiService.checkConnection(ipAddress);

    if (!mounted) return;

    if (connected) {
      final device = Device(
        id: 'esp32_$ipAddress',
        name: 'Living Room',
        ipAddress: ipAddress,
        isOnline: true,
        relayCount: 4,
      );

      context.read<DeviceProvider>().setDevice(device);

      await _storageService.saveDevice(device);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    } else {
      setState(() {
        _isConnecting = false;
      });

      _showMessage(
        'Unable to connect to ESP32. Check the IP address and Wi-Fi connection.',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
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

  InputDecoration _inputDecoration() {
    return InputDecoration(
      labelText: 'ESP32 IP Address',
      hintText: '192.168.1.100',
      labelStyle: const TextStyle(
        color: SmartHomeColors.textSecondary,
      ),
      floatingLabelStyle: const TextStyle(
        color: SmartHomeColors.goldLight,
      ),
      hintStyle: const TextStyle(
        color: SmartHomeColors.textDisabled,
      ),
      prefixIcon: const Icon(
        Icons.language_rounded,
        color: SmartHomeColors.gold,
      ),
      filled: true,
      fillColor: SmartHomeColors.background,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: SmartHomeColors.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: SmartHomeColors.gold,
          width: 1.2,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: SmartHomeColors.border,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding =
        SmartHomeResponsive.horizontalPadding(context);
    final isSmall = SmartHomeResponsive.isSmallPhone(context);
    final maxWidth =
        SmartHomeResponsive.isLargeScreen(context) ? 520.0 : 480.0;

    return Scaffold(
      backgroundColor: SmartHomeColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: SmartHomeColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Device Setup',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.15,
            colors: [
              Color(0xFF17120A),
              SmartHomeColors.background,
              Colors.black,
            ],
            stops: [0.0, 0.48, 1.0],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                20,
                horizontalPadding,
                32,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHero(context),
                    SizedBox(height: isSmall ? 26 : 34),
                    _buildConnectionCard(context),
                    const SizedBox(height: 20),
                    _buildNetworkTip(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final iconBoxSize =
        SmartHomeResponsive.isSmallPhone(context) ? 78.0 : 90.0;
    final iconSize =
        SmartHomeResponsive.isSmallPhone(context) ? 38.0 : 45.0;

    return Column(
      children: [
        Container(
          width: iconBoxSize,
          height: iconBoxSize,
          decoration: BoxDecoration(
            color: SmartHomeColors.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: SmartHomeColors.borderGold,
            ),
            boxShadow: [
              BoxShadow(
                color: SmartHomeColors.gold.withOpacity(.14),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            Icons.router_rounded,
            size: iconSize,
            color: SmartHomeColors.goldLight,
          ),
        ),
        const SizedBox(height: 26),
        Text(
          'Connect Your ESP32',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: SmartHomeColors.textPrimary,
            fontSize: SmartHomeResponsive.titleSize(context),
            fontWeight: FontWeight.w700,
            letterSpacing: -.3,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Make sure your ESP32 and phone are connected to the same Wi-Fi network.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: SmartHomeColors.textSecondary,
            fontSize: 14,
            height: 1.55,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        SmartHomeResponsive.isSmallPhone(context) ? 16 : 20,
      ),
      decoration: BoxDecoration(
        color: SmartHomeColors.surface.withOpacity(.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: SmartHomeColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.38),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                Icons.wifi_rounded,
                color: SmartHomeColors.gold,
                size: 20,
              ),
              SizedBox(width: 10),
              Text(
                'Device Connection',
                style: TextStyle(
                  color: SmartHomeColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter the local IP address shown by your ESP32.',
            style: TextStyle(
              color: SmartHomeColors.textMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _ipController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            textInputAction: TextInputAction.done,
            enabled: !_isConnecting,
            style: const TextStyle(
              color: SmartHomeColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            decoration: _inputDecoration(),
            onSubmitted: (_) {
              if (!_isConnecting) {
                _connectDevice();
              }
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [
                    SmartHomeColors.goldLight,
                    SmartHomeColors.gold,
                    SmartHomeColors.goldDark,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: SmartHomeColors.gold.withOpacity(.16),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isConnecting ? null : _connectDevice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.transparent,
                  disabledForegroundColor: Colors.black54,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isConnecting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.black87,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.link_rounded,
                            size: 21,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Connect Device',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .4,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkTip() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SmartHomeColors.surface.withOpacity(.72),
        borderRadius: BorderRadius.circular(18),
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
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Example: 192.168.1.100\n'
              'Both your phone and ESP32 must be on the same Wi-Fi network.',
              style: TextStyle(
                color: SmartHomeColors.textSecondary,
                fontSize: 12.5,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
