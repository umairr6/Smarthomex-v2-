import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/responsive.dart';
import '../../services/auth_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _authService = AuthService();

  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter email and password.');
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await _authService.signIn(
        email: email,
        password: password,
      );

      if (!mounted) return;

      _showMessage('Welcome back!');
    } catch (e) {
      if (!mounted) return;

      _showMessage(_cleanError(e.toString()));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showMessage('Enter your email first.');
      return;
    }

    try {
      await _authService.resetPassword(email);

      if (!mounted) return;

      _showMessage('Password reset email sent.');
    } catch (e) {
      if (!mounted) return;

      _showMessage(_cleanError(e.toString()));
    }
  }

  String _cleanError(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'Invalid email or password.';
    }

    if (error.contains('Email not confirmed')) {
      return 'Please confirm your email before logging in.';
    }

    return error
        .replaceFirst('AuthException(message: ', '')
        .replaceFirst(')', '');
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

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: SmartHomeColors.textSecondary,
      ),
      floatingLabelStyle: const TextStyle(
        color: SmartHomeColors.goldLight,
      ),
      prefixIcon: Icon(
        icon,
        color: SmartHomeColors.gold,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: SmartHomeColors.background,
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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = SmartHomeResponsive.horizontalPadding(context);
    final maxWidth = SmartHomeResponsive.isLargeScreen(context) ? 480.0 : 460.0;
    final titleSize = SmartHomeResponsive.titleSize(context);

    return Scaffold(
      backgroundColor: SmartHomeColors.background,
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
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 28,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildBrandHeader(context, titleSize),
                    const SizedBox(height: 34),
                    _buildLoginCard(context),
                    const SizedBox(height: 22),
                    _buildSignupPrompt(context),
                    const SizedBox(height: 26),
                    const Text(
                      'Smart living. Simple control.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: SmartHomeColors.textMuted,
                        fontSize: 13,
                        letterSpacing: .2,
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

  Widget _buildBrandHeader(BuildContext context, double titleSize) {
    final logoSize = SmartHomeResponsive.isSmallPhone(context) ? 72.0 : 84.0;
    final iconSize = SmartHomeResponsive.isSmallPhone(context) ? 36.0 : 42.0;

    return Column(
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: SmartHomeColors.gold.withValues(alpha: 0.08),
            border: Border.all(
              color: SmartHomeColors.gold.withValues(alpha: 0.55),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: SmartHomeColors.gold.withValues(alpha: 0.16),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            Icons.home_rounded,
            color: SmartHomeColors.goldLight,
            size: iconSize,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'WELCOME TO',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: SmartHomeColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 6),
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
            'SmartHomeX',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: titleSize + 5,
              fontWeight: FontWeight.w700,
              letterSpacing: -.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Control your smart home,\nanytime, anywhere.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: SmartHomeColors.textMuted,
            fontSize: 14,
            height: 1.55,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        SmartHomeResponsive.isSmallPhone(context) ? 16 : 20,
      ),
      decoration: BoxDecoration(
        color: SmartHomeColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: SmartHomeColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.38),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Sign in',
            style: TextStyle(
              color: SmartHomeColors.textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Enter your credentials to continue.',
            style: TextStyle(
              color: SmartHomeColors.textMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !_loading,
            style: const TextStyle(
              color: SmartHomeColors.textPrimary,
            ),
            decoration: _inputDecoration(
              label: 'Email',
              icon: Icons.email_outlined,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            enabled: !_loading,
            onSubmitted: (_) {
              if (!_loading) {
                _login();
              }
            },
            style: const TextStyle(
              color: SmartHomeColors.textPrimary,
            ),
            decoration: _inputDecoration(
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
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
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _loading ? null : _forgotPassword,
              style: TextButton.styleFrom(
                foregroundColor: SmartHomeColors.goldLight,
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
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
                    color: SmartHomeColors.gold.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
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
                            'LOGIN',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
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

  Widget _buildSignupPrompt(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          "Don't have an account? ",
          style: TextStyle(
            color: SmartHomeColors.textMuted,
            fontSize: 13,
          ),
        ),
        TextButton(
          onPressed: _loading
              ? null
              : () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SignupScreen(),
                    ),
                  );
                },
          style: TextButton.styleFrom(
            foregroundColor: SmartHomeColors.goldLight,
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 8,
            ),
          ),
          child: const Text(
            'Create Account',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
