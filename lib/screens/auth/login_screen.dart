import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'shop_setup_screen.dart';
import '../dashboard/home_dashboard_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _handleSendOtp() {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kripya 10 digit ka mobile number dalein')),
      );
      return;
    }
    setState(() => _otpSent = true);
    ref.read(authProvider.notifier).sendOtp(phone);
  }

  void _handleVerifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kripya sahi OTP dalein')),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).verifyOtp(otp);
    if (success && mounted) {
      final currentShop = ref.read(authProvider).currentShop;
      if (currentShop == null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ShopSetupScreen(mobileNumber: _phoneController.text.trim()),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeDashboardScreen()),
        );
      }
    } else if (mounted) {
      // In development / demo preview, allow direct progression to setup
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ShopSetupScreen(mobileNumber: _phoneController.text.trim().isEmpty ? '9876543210' : _phoneController.text.trim()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.store_mall_directory_rounded,
                    size: 56,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Mandi Hisab Mein Swagat Hai',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Apna mobile number darz karein aur hisaab shuru karein',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 36),

              // Phone Number Field
              const Text(
                'Mobile Number',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.phone_android, color: AppColors.primary),
                  prefixText: '+91 ',
                  hintText: '98765 43210',
                  counterText: '',
                  suffixIcon: _otpSent
                      ? IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => setState(() => _otpSent = false),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              // OTP Field (conditional)
              if (_otpSent) ...[
                const Text(
                  'OTP Darz Karein',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, letterSpacing: 6, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: '• • • • • •',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _handleSendOtp,
                    child: const Text('OTP Phir Se Bhejein', style: TextStyle(color: AppColors.primary)),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Action Button
              ElevatedButton(
                onPressed: authState.isLoading
                    ? null
                    : (_otpSent ? _handleVerifyOtp : _handleSendOtp),
                child: authState.isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: AppColors.secondary, strokeWidth: 2),
                      )
                    : Text(
                        _otpSent ? 'OTP Verify Karein & Aage Badhein' : 'OTP Prapt Karein',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),

              const SizedBox(height: 32),
              const Center(
                child: Text(
                  '🔒 100% Safe & Secure Cloud Accounting\nSirf Mandi Vyapariyon Ke Liye',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
