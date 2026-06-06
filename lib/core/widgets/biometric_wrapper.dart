import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../services/biometric_auth_service.dart';
import '../theme/app_theme.dart';

class BiometricWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const BiometricWrapper({super.key, required this.child});

  @override
  ConsumerState<BiometricWrapper> createState() => _BiometricWrapperState();
}

class _BiometricWrapperState extends ConsumerState<BiometricWrapper> {
  bool _isAuthenticated = false;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final useBiometrics = ref.read(settingsProvider).useBiometrics;
    if (!useBiometrics) {
      setState(() {
        _isAuthenticated = true;
      });
      return;
    }

    setState(() {
      _isAuthenticating = true;
    });

    final authService = BiometricAuthService();
    final authenticated = await authService.authenticate();

    if (mounted) {
      setState(() {
        _isAuthenticated = authenticated;
        _isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final useBiometrics = ref.watch(settingsProvider).useBiometrics;

    if (!useBiometrics || _isAuthenticated) {
      return widget.child;
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: AppTheme.primaryColor),
            const SizedBox(height: 24),
            const Text(
              'Ứng dụng đã bị khóa',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_isAuthenticating)
              const CircularProgressIndicator()
            else
              ElevatedButton.icon(
                onPressed: _checkAuth,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Mở khóa'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
