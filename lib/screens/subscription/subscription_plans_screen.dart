import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/subscription_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/subscription_service.dart';

class SubscriptionPlansScreen extends ConsumerStatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  ConsumerState<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends ConsumerState<SubscriptionPlansScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  SubscriptionPlan _selectedPlan = SubscriptionPlan.monthly;

  @override
  void initState() {
    super.initState();
    _subscriptionService.initializeRazorpay(
      onSuccess: (res) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text('✅ Payment Safalta Purvak Hua! Payment ID: ${res.paymentId}'),
          ),
        );
      },
      onFailure: (err) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('❌ Payment Asafal Raha: ${err.message}'),
          ),
        );
      },
      onExternalWallet: (res) {},
    );
  }

  @override
  void dispose() {
    _subscriptionService.dispose();
    super.dispose();
  }

  void _handlePay() {
    final shop = ref.read(authProvider).currentShop;
    _subscriptionService.openCheckout(
      plan: _selectedPlan,
      shopName: shop?.shopName ?? 'Mandi Traders',
      mobileNumber: shop?.mobileNumber ?? '9876543210',
      shopId: shop?.shopId ?? 'SHOP_DEMO',
      razorpayKey: 'rzp_test_placeholder_key',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mandi Hisab Subscription'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Plan Status Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accent),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: AppColors.accent, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Aapka Free Trial Chalu Hai',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF92400E)),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '7 dinon ke liye sabhi premium features muft uplabdh hain.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF78350F)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Apna Plan Chunein (Choose Plan)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 14),

            // Plan 1: Monthly
            _buildPlanCard(
              plan: SubscriptionPlan.monthly,
              title: 'Monthly Premium Plan',
              price: '₹199',
              period: '/ mahina',
              description: 'Chhoti dukaan ke liye behtar. Har mahine aasan hisaab.',
              isPopular: false,
            ),
            const SizedBox(height: 14),

            // Plan 2: Yearly (Best Value)
            _buildPlanCard(
              plan: SubscriptionPlan.yearly,
              title: 'Yearly Super Saver Plan',
              price: '₹1,999',
              period: '/ saal',
              description: 'Sabse lokpriya! ₹389 ki bachat + Poora saal befikr hisaab.',
              isPopular: true,
            ),

            const SizedBox(height: 24),

            // Feature Highlights
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Premium Mein Shamil Hai:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    SizedBox(height: 10),
                    _FeatureRow(text: 'Asimit (Unlimited) Stock & Crop Management'),
                    _FeatureRow(text: 'Voice Munim (Bol kar hisaab darz karein)'),
                    _FeatureRow(text: 'Gaadi Aavak-Javak Register & Live Tracking'),
                    _FeatureRow(text: 'Rozana PDF & WhatsApp Hisaab Export'),
                    _FeatureRow(text: '100% Safe Cloud Backup & Multi-Device Access'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _handlePay,
              child: Text('₹${_selectedPlan.price.toInt()} Payment Karein (UPI / Cards / Netbanking)'),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                '🔒 Secured by Razorpay India. 3 Din Grace Period Supported.',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required SubscriptionPlan plan,
    required String title,
    required String price,
    required String period,
    required String description,
    required bool isPopular,
  }) {
    final isSelected = _selectedPlan == plan;

    return InkWell(
      onTap: () => setState(() => _selectedPlan = plan),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.04) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Bachat 16%',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  price,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                Text(period, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 6),
            Text(description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String text;
  const _FeatureRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
