import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

      // Save device in provider
      context.read<DeviceProvider>().setDevice(device);

      // Save device permanently
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 500,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xff1E293B),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(
                      Icons.router_rounded,
                      size: 45,
                      color: Color(0xff34B7F1),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Title
                  const Text(
                    'Connect Your ESP32',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Make sure your ESP32 and phone are connected to the same Wi-Fi network.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // IP field
                  TextField(
                    controller: _ipController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    enabled: !_isConnecting,
                    decoration: InputDecoration(
                      labelText: 'ESP32 IP Address',
                      hintText: '192.168.1.100',
                      prefixIcon: const Icon(
                        Icons.language_rounded,
                      ),
                      filled: true,
                      fillColor: const Color(0xff1E293B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) {
                      if (!_isConnecting) {
                        _connectDevice();
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  // Connect button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isConnecting ? null : _connectDevice,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff34B7F1),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            const Color(0xff34B7F1).withOpacity(0.5),
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
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.link_rounded),
                                SizedBox(width: 10),
                                Text(
                                  'Connect Device',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Example: 192.168.1.100',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}