import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/device_provider.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/app_lock_service.dart';
import '../app_lock/app_lock_setup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  final AppLockService _appLockService = AppLockService();

  bool _checkingConnection = false;
  bool _appLockEnabled = false;
  bool _loadingAppLock = true;

  @override
  void initState() {
    super.initState();
    _loadAppLockStatus();
  }

  // ==========================================
  // APP LOCK
  // ==========================================

  Future<void> _loadAppLockStatus() async {
    final enabled = await _appLockService.isEnabled();

    if (!mounted) return;

    setState(() {
      _appLockEnabled = enabled;
      _loadingAppLock = false;
    });
  }

  Future<void> _enableAppLock() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const AppLockSetupScreen(),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await _loadAppLockStatus();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('App Lock enabled successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _disableAppLock() async {
    final verified = await _verifyCurrentPin(
      title: 'Disable App Lock',
      message: 'Enter your current PIN to disable App Lock.',
    );

    if (!verified || !mounted) return;

    await _appLockService.setEnabled(false);

    if (!mounted) return;

    setState(() {
      _appLockEnabled = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('App Lock disabled.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _changePin() async {
    final verified = await _verifyCurrentPin(
      title: 'Change PIN',
      message: 'Enter your current PIN to continue.',
    );

    if (!verified || !mounted) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const AppLockSetupScreen(),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await _loadAppLockStatus();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN changed successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool> _verifyCurrentPin({
    required String title,
    required String message,
  }) async {
    final controller = TextEditingController();
    String? errorMessage;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xff1E293B),
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Current PIN',
                      counterText: '',
                      errorText: errorMessage,
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final pin = controller.text.trim();

                    if (pin.length != 4) {
                      setDialogState(() {
                        errorMessage = 'Enter a 4-digit PIN.';
                      });
                      return;
                    }

                    final correct =
                        await _appLockService.verifyPin(pin);

                    if (!dialogContext.mounted) return;

                    if (correct) {
                      Navigator.pop(dialogContext, true);
                    } else {
                      setDialogState(() {
                        errorMessage = 'Incorrect PIN.';
                      });
                    }
                  },
                  child: const Text('Verify'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    return result == true;
  }

  // ==========================================
  // CHECK CONNECTION
  // ==========================================

  Future<void> _checkConnection() async {
    final deviceProvider = context.read<DeviceProvider>();
    final device = deviceProvider.device;

    if (device == null) return;

    setState(() {
      _checkingConnection = true;
    });

    final online = await _apiService.checkConnection(
      device.ipAddress,
    );

    if (!mounted) return;

    deviceProvider.updateDeviceStatus(online);

    setState(() {
      _checkingConnection = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          online
              ? 'ESP32 is connected.'
              : 'ESP32 is not responding.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================
  // RENAME ROOM
  // ==========================================

  void _renameRoom() {
    final deviceProvider = context.read<DeviceProvider>();
    final device = deviceProvider.device;

    if (device == null) return;

    final controller = TextEditingController(
      text: device.name,
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xff1E293B),
          title: const Text('Rename Room'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Enter room name',
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
              onPressed: () async {
                final newName = controller.text.trim();

                if (newName.isEmpty) return;

                device.name = newName;

                deviceProvider.setDevice(device);

                await _storageService.saveDevice(device);

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // RENAME RELAY
  // ==========================================

  void _renameRelay(int relayId) {
    final deviceProvider = context.read<DeviceProvider>();
    final relay = deviceProvider.getRelay(relayId);

    if (relay == null) return;

    final controller = TextEditingController(
      text: relay.name,
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xff1E293B),
          title: const Text('Rename Switch'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Enter switch name',
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
              onPressed: () async {
                final newName = controller.text.trim();

                if (newName.isEmpty) return;

                deviceProvider.renameRelay(
                  relayId,
                  newName,
                );

                await _storageService.saveRelays(
                  deviceProvider.relays,
                );

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // REMOVE DEVICE
  // ==========================================

  Future<void> _removeDevice() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xff1E293B),
          title: const Text('Remove Device?'),
          content: const Text(
            'This will remove the saved ESP32 connection '
            'from this device. You can connect again later.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _storageService.clearDevice();
    await _storageService.clearRelays();

    if (!mounted) return;

    context.read<DeviceProvider>().clearDevice();

    Navigator.of(context).popUntil(
      (route) => route.isFirst,
    );
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceProvider>(
      builder: (context, deviceProvider, child) {
        final device = deviceProvider.device;

        return Scaffold(
          backgroundColor: const Color(0xff0F172A),

          appBar: AppBar(
            backgroundColor: const Color(0xff0F172A),
            elevation: 0,
            title: const Text(
              'Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ==================================
              // DEVICE
              // ==================================

              _sectionTitle('DEVICE'),

              _settingsCard(
                children: [
                  _settingsTile(
                    icon: Icons.home_rounded,
                    title: device?.name ?? 'Room',
                    subtitle: 'Room name',
                    onTap: _renameRoom,
                  ),

                  const Divider(height: 1),

                  _settingsTile(
                    icon: Icons.router_rounded,
                    title: 'ESP32',
                    subtitle:
                        device?.ipAddress ?? 'Not connected',
                    showArrow: false,
                  ),

                  const Divider(height: 1),

                  _settingsTile(
                    icon: deviceProvider.isOnline
                        ? Icons.check_circle_rounded
                        : Icons.error_rounded,
                    iconColor: deviceProvider.isOnline
                        ? Colors.green
                        : Colors.red,
                    title: deviceProvider.isOnline
                        ? 'Connected'
                        : 'Offline',
                    subtitle: 'Connection status',
                    showArrow: false,
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ==================================
              // SWITCHES
              // ==================================

              _sectionTitle('SWITCHES'),

              _settingsCard(
                children: [
                  ...deviceProvider.relays.map(
                    (relay) {
                      return Column(
                        children: [
                          _settingsTile(
                            icon: _getRelayIcon(
                              relay.icon,
                            ),
                            title: relay.name,
                            subtitle: 'Relay ${relay.id}',
                            onTap: () {
                              _renameRelay(
                                relay.id,
                              );
                            },
                          ),

                          if (relay.id !=
                              deviceProvider.relays.last.id)
                            const Divider(height: 1),
                        ],
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ==================================
              // SECURITY
              // ==================================

              _sectionTitle('SECURITY'),

              _settingsCard(
                children: [
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 6,
                    ),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xff34B7F1)
                            .withOpacity(0.12),
                        borderRadius:
                            BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: Color(0xff34B7F1),
                        size: 22,
                      ),
                    ),
                    title: const Text(
                      'App Lock',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      _loadingAppLock
                          ? 'Checking status...'
                          : _appLockEnabled
                              ? 'PIN protection enabled'
                              : 'Protect SmartHomeX with a PIN',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    trailing: _loadingAppLock
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xff34B7F1),
                            ),
                          )
                        : Switch(
                            value: _appLockEnabled,
                            activeThumbColor:
                                const Color(0xff34B7F1),
                            onChanged: (value) {
                              if (value) {
                                _enableAppLock();
                              } else {
                                _disableAppLock();
                              }
                            },
                          ),
                  ),

                  if (!_loadingAppLock && _appLockEnabled) ...[
                    const Divider(height: 1),

                    _settingsTile(
                      icon: Icons.password_rounded,
                      title: 'Change PIN',
                      subtitle: 'Create a new 4-digit PIN',
                      onTap: _changePin,
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 28),

              // ==================================
              // CONNECTION
              // ==================================

              _sectionTitle('CONNECTION'),

              _settingsCard(
                children: [
                  _settingsTile(
                    icon: Icons.refresh_rounded,
                    title: 'Check Connection',
                    subtitle: 'Test ESP32 connection',
                    showLoading: _checkingConnection,
                    onTap: _checkingConnection
                        ? null
                        : _checkConnection,
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ==================================
              // DEVICE MANAGEMENT
              // ==================================

              _sectionTitle('DEVICE MANAGEMENT'),

              _settingsCard(
                children: [
                  _settingsTile(
                    icon: Icons.delete_outline_rounded,
                    iconColor: Colors.red,
                    title: 'Remove Device',
                    subtitle: 'Forget this ESP32',
                    titleColor: Colors.red,
                    onTap: _removeDevice,
                  ),
                ],
              ),

              const SizedBox(height: 40),

              const Center(
                child: Text(
                  'SmartHomeX',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 6),

              const Center(
                child: Text(
                  'Smart Control. Simplified.',
                  style: TextStyle(
                    color: Colors.white24,
                    fontSize: 11,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // SECTION TITLE
  // ==========================================

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 10,
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ==========================================
  // SETTINGS CARD
  // ==========================================

  Widget _settingsCard({
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  // ==========================================
  // SETTINGS TILE
  // ==========================================

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconColor,
    Color? titleColor,
    bool showArrow = true,
    bool showLoading = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 6,
      ),

      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: (iconColor ??
                  const Color(0xff34B7F1))
              .withOpacity(0.12),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(
          icon,
          color: iconColor ??
              const Color(0xff34B7F1),
          size: 22,
        ),
      ),

      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: titleColor,
        ),
      ),

      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
      ),

      trailing: showLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xff34B7F1),
              ),
            )
          : showArrow
              ? const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white38,
                )
              : null,

      onTap: onTap,
    );
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
}