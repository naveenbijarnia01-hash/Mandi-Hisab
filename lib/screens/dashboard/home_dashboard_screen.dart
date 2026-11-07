import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stock_provider.dart';
import '../transactions/maal_aaya_screen.dart';
import '../transactions/maal_gaya_screen.dart';
import '../vehicles/gaadi_register_screen.dart';
import '../vehicles/gaadi_entry_screen.dart';
import '../stock/stock_overview_screen.dart';
import '../voice/voice_assistant_screen.dart';
import '../reports/daily_reports_screen.dart';
import '../subscription/subscription_plans_screen.dart';
import '../settings/profile_settings_screen.dart';

class HomeDashboardScreen extends ConsumerStatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  ConsumerState<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final stockListAsync = ref.watch(stockListStreamProvider);
    final txListAsync = ref.watch(transactionsStreamProvider);

    final shop = authState.currentShop;
    final shopName = shop?.shopName ?? 'Shree Ganesh Mandi Traders';
    final mandiName = shop?.mandiName ?? 'Jaipur Anaj Mandi';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              shopName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              mandiName,
              style: const TextStyle(fontSize: 12, color: AppColors.accentLight),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.workspace_premium, color: AppColors.accent),
            tooltip: 'Subscription',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionPlansScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: stockListAsync.when(
        data: (stocks) {
          final totalAvailableStock = stocks.fold<double>(0.0, (sum, item) => sum + item.currentStock);
          final totalIncomingToday = stocks.fold<double>(0.0, (sum, item) => sum + item.totalIncoming);
          final totalOutgoingToday = stocks.fold<double>(0.0, (sum, item) => sum + item.totalOutgoing);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Highlight Card - Total Stock
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Kul Uplabdh Stock (Total Stock)',
                            style: TextStyle(color: AppColors.accentLight, fontSize: 14),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Live Mandi',
                              style: TextStyle(
                                color: AppColors.primaryDark,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${totalAvailableStock.toStringAsFixed(1)} Quintal',
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white24, height: 1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Aaj Aaya (In)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(
                                  '+${totalIncomingToday.toStringAsFixed(1)} Qtl',
                                  style: const TextStyle(color: Color(0xFF86EFAC), fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 30, color: Colors.white24),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Aaj Gaya (Out)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(
                                  '-${totalOutgoingToday.toStringAsFixed(1)} Qtl',
                                  style: const TextStyle(color: Color(0xFFFCA5A5), fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Action Buttons (6 key actions from Spec)
                const Text(
                  'Jaldi Karein (Quick Actions)',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: [
                    _buildActionButton(
                      icon: Icons.add_shopping_cart,
                      label: 'Maal Aaya',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MaalAayaScreen()));
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.local_shipping_outlined,
                      label: 'Maal Gaya',
                      color: const Color(0xFFC2410C),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MaalGayaScreen()));
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.directions_car,
                      label: 'Gaadi Entry',
                      color: const Color(0xFF1D4ED8),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const GaadiEntryScreen()));
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.inventory_2_outlined,
                      label: 'Stock Dekho',
                      color: const Color(0xFF047857),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const StockOverviewScreen()));
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.mic,
                      label: 'Voice Entry',
                      color: AppColors.accent,
                      textColor: AppColors.primaryDark,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceAssistantScreen()));
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.calculate_outlined,
                      label: 'Aaj Ka Hisaab',
                      color: const Color(0xFF4338CA),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyReportsScreen()));
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Live Crop Stock Summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Fasal-vaar Stock (Crop Stock)',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const StockOverviewScreen()));
                      },
                      child: const Text('Sabhi Dekhein', style: TextStyle(color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: stocks.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final item = stocks[index];
                      return Container(
                        width: 140,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.cropName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.currentStock.toStringAsFixed(1)} ${item.unit.label}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            if (item.isLowStock)
                              const Text(
                                '⚠️ Kam Stock',
                                style: TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w600),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Recent Transactions
                const Text(
                  'Haal Hi Ke Len-Den (Recent Transactions)',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                txListAsync.when(
                  data: (txs) {
                    if (txs.isEmpty) {
                      return const Center(child: Text('Koi transaction darz nahi hai'));
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: txs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final tx = txs[index];
                        final isIncoming = tx.type == TransactionType.incoming;
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: isIncoming
                                    ? AppColors.success.withOpacity(0.15)
                                    : AppColors.error.withOpacity(0.15),
                                child: Icon(
                                  isIncoming ? Icons.arrow_downward : Icons.arrow_upward,
                                  color: isIncoming ? AppColors.success : AppColors.error,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${tx.cropName} (${tx.quantity} ${tx.unit.label})',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    Text(
                                      '${tx.partyName} • ${tx.vehicleNumber}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    isIncoming ? '+ Aaya' : '- Gaya',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isIncoming ? AppColors.success : AppColors.error,
                                    ),
                                  ),
                                  if (tx.totalAmount != null)
                                    Text(
                                      '₹${tx.totalAmount!.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const StockOverviewScreen()));
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const GaadiRegisterScreen()));
          } else if (index == 3) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyReportsScreen()));
          } else if (index == 4) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Stock'),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Gaadi'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Hisaab'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceAssistantScreen()));
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.secondary,
        icon: const Icon(Icons.mic, color: AppColors.accent),
        label: const Text('Bol Kar Hisaab Likhein'),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textColor ?? AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
