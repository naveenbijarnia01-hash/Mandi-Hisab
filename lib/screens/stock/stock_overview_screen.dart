import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/stock_item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stock_provider.dart';

class StockOverviewScreen extends ConsumerStatefulWidget {
  const StockOverviewScreen({super.key});

  @override
  ConsumerState<StockOverviewScreen> createState() => _StockOverviewScreenState();
}

class _StockOverviewScreenState extends ConsumerState<StockOverviewScreen> {
  void _showAddCropDialog() {
    final cropController = TextEditingController();
    final qtyController = TextEditingController();
    CropUnit unit = CropUnit.quintal;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nayi Fasal / Opening Stock Jodein'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: cropController,
                decoration: const InputDecoration(labelText: 'Fasal Ka Naam', hintText: 'Jaise: Makka, Moong'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Opening Stock Maatra'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<CropUnit>(
                value: unit,
                decoration: const InputDecoration(labelText: 'Unit'),
                items: CropUnit.values.map((u) => DropdownMenuItem(value: u, child: Text(u.label))).toList(),
                onChanged: (v) => setDialogState(() => unit = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (cropController.text.isNotEmpty && qtyController.text.isNotEmpty) {
                  final shop = ref.read(authProvider).currentShop;
                  await ref.read(stockServiceProvider).setOpeningStock(
                        shopId: shop?.shopId ?? 'SHOP_DEMO',
                        cropName: cropController.text.trim(),
                        openingStock: double.parse(qtyController.text.trim()),
                        unit: unit,
                      );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Save Karein'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stockListAsync = ref.watch(stockListStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kul Fasal Stock (Stock Register)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Fasal Jodein',
            onPressed: _showAddCropDialog,
          ),
        ],
      ),
      body: stockListAsync.when(
        data: (stocks) {
          if (stocks.isEmpty) {
            return const Center(child: Text('Koi crop stock darz nahi hai'));
          }

          final totalBalance = stocks.fold<double>(0.0, (sum, item) => sum + item.currentStock);

          return Column(
            children: [
              // Summary Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                color: AppColors.primary,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Kul Stock Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          '${totalBalance.toStringAsFixed(1)} Quintal',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.secondary),
                        ),
                      ],
                    ),
                    Text(
                      '${stocks.length} Faslein',
                      style: const TextStyle(color: AppColors.accentLight, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              // Stock Items List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: stocks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = stocks[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.cropName,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: item.isLowStock
                                        ? AppColors.error.withOpacity(0.12)
                                        : AppColors.success.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item.isLowStock ? 'Kam Stock' : 'Paryapt Stock',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: item.isLowStock ? AppColors.error : AppColors.success,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStockStat('Opening', '${item.openingStock.toStringAsFixed(1)} ${item.unit.label}'),
                                _buildStockStat('Kul Aaya', '+${item.totalIncoming.toStringAsFixed(1)}', color: AppColors.success),
                                _buildStockStat('Kul Gaya', '-${item.totalOutgoing.toStringAsFixed(1)}', color: AppColors.error),
                                _buildStockStat(
                                  'Current',
                                  '${item.currentStock.toStringAsFixed(1)} ${item.unit.label}',
                                  isHighlight: true,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildStockStat(String label, String value, {Color? color, bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 15 : 13,
            fontWeight: FontWeight.bold,
            color: color ?? (isHighlight ? AppColors.primary : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
