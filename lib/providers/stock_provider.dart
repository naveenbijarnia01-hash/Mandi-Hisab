import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stock_item_model.dart';
import '../models/transaction_model.dart';
import '../services/stock_service.dart';
import 'auth_provider.dart';

final stockServiceProvider = Provider<StockService>((ref) {
  return StockService();
});

// Stream of current shop's stocks
final stockListStreamProvider = StreamProvider<List<StockItemModel>>((ref) {
  final currentShop = ref.watch(authProvider).currentShop;
  if (currentShop == null) {
    // Return sample/mock crops if not logged in
    return Stream.value([
      StockItemModel(
        id: '1',
        shopId: 'SHOP_DEMO',
        cropName: 'Gehun',
        openingStock: 200,
        totalIncoming: 150,
        totalOutgoing: 80,
        currentStock: 270,
        unit: CropUnit.quintal,
        updatedAt: DateTime.now(),
      ),
      StockItemModel(
        id: '2',
        shopId: 'SHOP_DEMO',
        cropName: 'Sarson',
        openingStock: 100,
        totalIncoming: 50,
        totalOutgoing: 60,
        currentStock: 90,
        unit: CropUnit.quintal,
        updatedAt: DateTime.now(),
      ),
      StockItemModel(
        id: '3',
        shopId: 'SHOP_DEMO',
        cropName: 'Bajra',
        openingStock: 80,
        totalIncoming: 40,
        totalOutgoing: 30,
        currentStock: 90,
        unit: CropUnit.quintal,
        updatedAt: DateTime.now(),
      ),
      StockItemModel(
        id: '4',
        shopId: 'SHOP_DEMO',
        cropName: 'Chana',
        openingStock: 50,
        totalIncoming: 20,
        totalOutgoing: 15,
        currentStock: 55,
        unit: CropUnit.quintal,
        updatedAt: DateTime.now(),
      ),
    ]);
  }
  return ref.watch(stockServiceProvider).getStockStream(currentShop.shopId);
});

// Transactions Stream
final transactionsStreamProvider = StreamProvider<List<TransactionModel>>((ref) {
  final currentShop = ref.watch(authProvider).currentShop;
  // Return sample transactions
  return Stream.value([
    TransactionModel(
      id: 'tx_1',
      shopId: currentShop?.shopId ?? 'SHOP_DEMO',
      type: TransactionType.incoming,
      cropName: 'Gehun',
      quantity: 50,
      unit: CropUnit.quintal,
      partyName: 'Suresh Kumar Kisan',
      vehicleNumber: 'RJ14GB4512',
      fromLocation: 'Chomu Mandi',
      toLocation: 'Dukaan Godam',
      rate: 2450,
      totalAmount: 122500,
      createdBy: 'Owner',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    TransactionModel(
      id: 'tx_2',
      shopId: currentShop?.shopId ?? 'SHOP_DEMO',
      type: TransactionType.outgoing,
      cropName: 'Sarson',
      quantity: 30,
      unit: CropUnit.quintal,
      partyName: 'Sungna Oil Factory',
      vehicleNumber: 'RJ23U8810',
      fromLocation: 'Dukaan Godam',
      toLocation: 'Sungna Factory',
      rate: 5400,
      totalAmount: 162000,
      createdBy: 'Owner',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ]);
});
