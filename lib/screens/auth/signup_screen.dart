import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/responsive.dart';
import '../../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  final _authService = AuthService();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty) {
      _showMessage('Please fill all fields.');
      return;
    }

    if (password.length < 6) {
      _showMessage('Password must be at least 6 characters.');
      return;
    }

    if (password != confirm) {
      _showMessage('Passwords do not match.');
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final response = await _authService.signUp(
        email: email,
        password: password,
        fullName: name,
      );

      if (!mounted) return;

      if (response.session == null) {
        _showMessage(
          'Account created. Please check your email to confirm your account.',
        );
        Navigator.of(context).pop();
      } else {
        _showMessage('Account created successfully!');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString()
            .replaceFirst('AuthException(message: ', '')
            .replaceFirst(')', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
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
          side: const BorderSide(color: SmartHomeColors.borderGold),
        ),
      ),
    );
  }

  InputDecoration _decoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: SmartHomeColors.textSecondary),
      floatingLabelStyle: const TextStyle(color: SmartHomeColors.goldLight),
      prefixIcon: Icon(icon, color: SmartHomeColors.gold),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: SmartHomeColors.background,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: SmartHomeColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: SmartHomeColors.gold,
          width: 1.2,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding =
        SmartHomeResponsive.horizontalPadding(context);
    final maxWidth =
        SmartHomeResponsive.isLargeScreen(context) ? 500.0 : 460.0;
    final titleSize = SmartHomeResponsive.titleSize(context);

    return Scaffold(
      backgroundColor: SmartHomeColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: SmartHomeColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Create Account',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [
              Color(0xFF17120A),
              SmartHomeColors.background,
              Colors.black,
            ],
            stops: [0.0, 0.46, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                72,
                horizontalPadding,
                28,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context, titleSize),
                    const SizedBox(height: 30),
                    _buildForm(context),
                    const SizedBox(height: 22),
                    const Text(
                      'By creating an account, your SmartHomeX data can be '
                      'synchronized securely across your devices.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: SmartHomeColors.textMuted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double titleSize) {
    final logoSize = SmartHomeResponsive.isSmallPhone(context) ? 66.0 : 76.0;
    final iconSize = SmartHomeResponsive.isSmallPhone(context) ? 32.0 : 38.0;

    return Column(
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: SmartHomeColors.gold.withOpacity(.08),
            border: Border.all(
              color: SmartHomeColors.gold.withOpacity(.55),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: SmartHomeColors.gold.withOpacity(.14),
                blurRadius: 26,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            Icons.person_add_alt_1_rounded,
            color: SmartHomeColors.goldLight,
            size: iconSize,
          ),
        ),
        const SizedBox(height: 20),
        ShaderMask(
          shaderCallback: (bounds) {
            return const LinearGradient(
              colors: [
                SmartHomeColors.goldLight,
                SmartHomeColors.gold,
                SmartHomeColors.goldDark,
              ],
            ).createShader(bounds);
          },
          child: Text(
            'Create your SmartHomeX account',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: titleSize,
              fontWeight: FontWeight.w700,
              letterSpacing: -.3,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Keep your homes, rooms and devices connected.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: SmartHomeColors.textMuted,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        SmartHomeResponsive.isSmallPhone(context) ? 16 : 20,
      ),
      decoration: BoxDecoration(
        color: SmartHomeColors.surface.withOpacity(.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SmartHomeColors.border),
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
          const Text(
            'Your details',
            style: TextStyle(
              color: SmartHomeColors.textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Set up your account in a few simple steps.',
            style: TextStyle(
              color: SmartHomeColors.textMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            enabled: !_loading,
            style: const TextStyle(color: SmartHomeColors.textPrimary),
            decoration: _decoration(
              label: 'Full Name',
              icon: Icons.person_outline_rounded,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !_loading,
            style: const TextStyle(color: SmartHomeColors.textPrimary),
            decoration: _decoration(
              label: 'Email',
              icon: Icons.email_outlined,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            enabled: !_loading,
            style: const TextStyle(color: SmartHomeColors.textPrimary),
            decoration: _decoration(
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                onPressed: _loading
                    ? null
                    : () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: SmartHomeColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _confirmController,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            enabled: !_loading,
            onSubmitted: (_) {
              if (!_loading) {
                _signup();
              }
            },
            style: const TextStyle(color: SmartHomeColors.textPrimary),
            decoration: _decoration(
              label: 'Confirm Password',
              icon: Icons.lock_reset_outlined,
              suffixIcon: IconButton(
                onPressed: _loading
                    ? null
                    : () {
                        setState(() {
                          _obscureConfirm = !_obscureConfirm;
                        });
                      },
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: SmartHomeColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: const LinearGradient(
                  colors: [
                    SmartHomeColors.goldLight,
                    SmartHomeColors.gold,
                    SmartHomeColors.goldDark,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: SmartHomeColors.gold.withOpacity(.18),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _loading ? null : _signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.transparent,
                  disabledForegroundColor: Colors.black54,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.black87,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'CREATE ACCOUNT',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(width: 10),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 19,
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
}
