import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stock_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../services/pdf_export_service.dart';

class DailyReportsScreen extends ConsumerStatefulWidget {
  const DailyReportsScreen({super.key});

  @override
  ConsumerState<DailyReportsScreen> createState() => _DailyReportsScreenState();
}

class _DailyReportsScreenState extends ConsumerState<DailyReportsScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedRange = 'Aaj (Today)';

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final stockListAsync = ref.watch(stockListStreamProvider);
    final txListAsync = ref.watch(transactionsStreamProvider);
    final vehicleListAsync = ref.watch(vehicleListStreamProvider);

    final shop = authState.currentShop;
    final shopName = shop?.shopName ?? 'Shree Ganesh Mandi Traders';
    final mandiName = shop?.mandiName ?? 'Jaipur Mandi';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Aaj Ka Hisaab & Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'PDF Export Karein',
            onPressed: () async {
              final stocks = stockListAsync.value ?? [];
              final txs = txListAsync.value ?? [];
              await PdfExportService.printOrSharePdf(
                shopName: shopName,
                mandiName: mandiName,
                stocks: stocks,
                transactions: txs,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Filter Card
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Text(
                          DateFormat('dd MMMM yyyy').format(_selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    DropdownButton<String>(
                      value: _selectedRange,
                      underline: const SizedBox(),
                      items: ['Aaj (Today)', 'Is Hafte (Week)', 'Is Mahine (Month)', 'Is Saal (Year)']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedRange = v!),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Accounting Snapshot Card
            stockListAsync.when(
              data: (stocks) {
                final totalStock = stocks.fold<double>(0.0, (sum, i) => sum + i.currentStock);
                final totalIn = stocks.fold<double>(0.0, (sum, i) => sum + i.totalIncoming);
                final totalOut = stocks.fold<double>(0.0, (sum, i) => sum + i.totalOutgoing);
                final totalOpening = stocks.fold<double>(0.0, (sum, i) => sum + i.openingStock);

                return Card(
                  color: AppColors.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dukaan Ka Kul Stock Hisaab',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        _buildHisabRow('Opening Stock:', '${totalOpening.toStringAsFixed(1)} Quintal'),
                        const Divider(height: 16),
                        _buildHisabRow('Kul Aavak (Total Incoming):', '+${totalIn.toStringAsFixed(1)} Quintal', color: AppColors.success),
                        const Divider(height: 16),
                        _buildHisabRow('Kul Javak (Total Outgoing):', '-${totalOut.toStringAsFixed(1)} Quintal', color: AppColors.error),
                        const Divider(height: 20, thickness: 1.5),
                        _buildHisabRow(
                          'Closing / Uplabdh Stock:',
                          '${totalStock.toStringAsFixed(1)} Quintal',
                          isBold: true,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),

            const SizedBox(height: 16),

            // Vehicle Movement Summary
            vehicleListAsync.when(
              data: (vehicles) {
                final inVehicles = vehicles.where((v) => v.movementType == 'incoming').length;
                final outVehicles = vehicles.where((v) => v.movementType == 'outgoing').length;
                final pendingVehicles = vehicles.where((v) => v.status == 'pending').length;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gaadi Aava-Jaahi Summary',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildVehicleSummaryItem('Aayi Gaadiyan', '$inVehicles', AppColors.success),
                            _buildVehicleSummaryItem('Gayi Gaadiyan', '$outVehicles', const Color(0xFFC2410C)),
                            _buildVehicleSummaryItem('Pending Gaadiyan', '$pendingVehicles', AppColors.warning),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),

            const SizedBox(height: 24),

            // Export Actions
            ElevatedButton.icon(
              icon: const Icon(Icons.share),
              label: const Text('WhatsApp / PDF Par Hisaab Bhejein'),
              onPressed: () async {
                final stocks = stockListAsync.value ?? [];
                final txs = txListAsync.value ?? [];
                await PdfExportService.printOrSharePdf(
                  shopName: shopName,
                  mandiName: mandiName,
                  stocks: stocks,
                  transactions: txs,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHisabRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleSummaryItem(String label, String count, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
