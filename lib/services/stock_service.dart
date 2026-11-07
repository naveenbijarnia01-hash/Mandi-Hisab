import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/stock_item_model.dart';
import '../models/transaction_model.dart';

class StockService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get stream of stock items for a shop
  Stream<List<StockItemModel>> getStockStream(String shopId) {
    return _firestore
        .collection('stocks')
        .where('shopId', isEqualTo: shopId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => StockItemModel.fromSnapshot(doc)).toList());
  }

  // Set opening stock for a crop
  Future<void> setOpeningStock({
    required String shopId,
    required String cropName,
    required double openingStock,
    required CropUnit unit,
  }) async {
    final docId = '${shopId}_${cropName.toLowerCase()}';
    final now = DateTime.now();

    final docRef = _firestore.collection('stocks').doc(docId);
    final doc = await docRef.get();

    if (doc.exists) {
      final current = StockItemModel.fromSnapshot(doc);
      final diff = openingStock - current.openingStock;
      final newCurrentStock = current.currentStock + diff;

      await docRef.update({
        'openingStock': openingStock,
        'currentStock': newCurrentStock > 0 ? newCurrentStock : 0,
        'unit': unit.name,
        'updatedAt': Timestamp.fromDate(now),
      });
    } else {
      final stockItem = StockItemModel(
        id: docId,
        shopId: shopId,
        cropName: cropName,
        openingStock: openingStock,
        totalIncoming: 0.0,
        totalOutgoing: 0.0,
        currentStock: openingStock,
        unit: unit,
        updatedAt: now,
      );
      await docRef.set(stockItem.toJson());
    }
  }

  // Record Incoming Goods (Maal Aaya)
  Future<void> recordIncomingGoods({
    required String shopId,
    required String cropName,
    required double quantity,
    required CropUnit unit,
    required String partyName,
    required String vehicleNumber,
    required String fromLocation,
    required String toLocation,
    double? rate,
    String? notes,
    String? billUrl,
    bool isVoiceEntry = false,
    required String userId,
  }) async {
    final stockDocId = '${shopId}_${cropName.toLowerCase()}';
    final now = DateTime.now();

    await _firestore.runTransaction((transaction) async {
      final stockRef = _firestore.collection('stocks').doc(stockDocId);
      final stockSnapshot = await transaction.get(stockRef);

      double currentStock = quantity;
      double totalIncoming = quantity;

      if (stockSnapshot.exists) {
        final data = stockSnapshot.data() as Map<String, dynamic>;
        final oldIncoming = (data['totalIncoming'] as num?)?.toDouble() ?? 0.0;
        final oldCurrent = (data['currentStock'] as num?)?.toDouble() ?? 0.0;
        totalIncoming = oldIncoming + quantity;
        currentStock = oldCurrent + quantity;

        transaction.update(stockRef, {
          'totalIncoming': totalIncoming,
          'currentStock': currentStock,
          'updatedAt': Timestamp.fromDate(now),
        });
      } else {
        transaction.set(stockRef, {
          'id': stockDocId,
          'shopId': shopId,
          'cropName': cropName,
          'openingStock': 0.0,
          'totalIncoming': quantity,
          'totalOutgoing': 0.0,
          'currentStock': quantity,
          'unit': unit.name,
          'lowStockThreshold': 10.0,
          'updatedAt': Timestamp.fromDate(now),
        });
      }

      // Create Transaction Ledger entry
      final txRef = _firestore.collection('transactions').doc();
      final tx = TransactionModel(
        id: txRef.id,
        shopId: shopId,
        type: TransactionType.incoming,
        cropName: cropName,
        quantity: quantity,
        unit: unit,
        partyName: partyName,
        vehicleNumber: vehicleNumber,
        fromLocation: fromLocation,
        toLocation: toLocation,
        rate: rate,
        totalAmount: rate != null ? rate * quantity : null,
        notes: notes,
        billUrl: billUrl,
        isVoiceEntry: isVoiceEntry,
        createdBy: userId,
        createdAt: now,
        updatedAt: now,
      );
      transaction.set(txRef, tx.toJson());
    });
  }

  // Record Outgoing Goods (Maal Gaya) with negative stock check
  Future<void> recordOutgoingGoods({
    required String shopId,
    required String cropName,
    required double quantity,
    required CropUnit unit,
    required String partyName,
    required String vehicleNumber,
    required String fromLocation,
    required String toLocation,
    double? rate,
    String? notes,
    String? billUrl,
    bool isVoiceEntry = false,
    bool allowNegativeStock = false,
    required String userId,
  }) async {
    final stockDocId = '${shopId}_${cropName.toLowerCase()}';
    final now = DateTime.now();

    await _firestore.runTransaction((transaction) async {
      final stockRef = _firestore.collection('stocks').doc(stockDocId);
      final stockSnapshot = await transaction.get(stockRef);

      if (!stockSnapshot.exists) {
        if (!allowNegativeStock) {
          throw Exception('Stock mein $cropName available nahi hai!');
        }
      }

      double oldCurrent = 0.0;
      double oldOutgoing = 0.0;
      if (stockSnapshot.exists) {
        final data = stockSnapshot.data() as Map<String, dynamic>;
        oldCurrent = (data['currentStock'] as num?)?.toDouble() ?? 0.0;
        oldOutgoing = (data['totalOutgoing'] as num?)?.toDouble() ?? 0.0;
      }

      final newCurrent = oldCurrent - quantity;
      if (newCurrent < 0 && !allowNegativeStock) {
        throw Exception('Stock insufficient hai! Current stock: $oldCurrent, Maang: $quantity');
      }

      final newOutgoing = oldOutgoing + quantity;

      if (stockSnapshot.exists) {
        transaction.update(stockRef, {
          'totalOutgoing': newOutgoing,
          'currentStock': newCurrent,
          'updatedAt': Timestamp.fromDate(now),
        });
      } else {
        transaction.set(stockRef, {
          'id': stockDocId,
          'shopId': shopId,
          'cropName': cropName,
          'openingStock': 0.0,
          'totalIncoming': 0.0,
          'totalOutgoing': newOutgoing,
          'currentStock': newCurrent,
          'unit': unit.name,
          'lowStockThreshold': 10.0,
          'updatedAt': Timestamp.fromDate(now),
        });
      }

      // Create Transaction Ledger entry
      final txRef = _firestore.collection('transactions').doc();
      final tx = TransactionModel(
        id: txRef.id,
        shopId: shopId,
        type: TransactionType.outgoing,
        cropName: cropName,
        quantity: quantity,
        unit: unit,
        partyName: partyName,
        vehicleNumber: vehicleNumber,
        fromLocation: fromLocation,
        toLocation: toLocation,
        rate: rate,
        totalAmount: rate != null ? rate * quantity : null,
        notes: notes,
        billUrl: billUrl,
        isVoiceEntry: isVoiceEntry,
        createdBy: userId,
        createdAt: now,
        updatedAt: now,
      );
      transaction.set(txRef, tx.toJson());
    });
  }
}
