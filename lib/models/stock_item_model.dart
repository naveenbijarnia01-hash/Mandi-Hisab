import 'package:cloud_firestore/cloud_firestore.dart';

enum CropUnit {
  quintal,
  kilogram,
  ton;

  String get label {
    switch (this) {
      case CropUnit.quintal:
        return 'Quintal';
      case CropUnit.kilogram:
        return 'KG';
      case CropUnit.ton:
        return 'Ton';
    }
  }

  static CropUnit fromString(String val) {
    switch (val.toLowerCase()) {
      case 'kg':
      case 'kilogram':
        return CropUnit.kilogram;
      case 'ton':
        return CropUnit.ton;
      case 'quintal':
      case 'qtl':
      default:
        return CropUnit.quintal;
    }
  }
}

class StockItemModel {
  final String id;
  final String shopId;
  final String cropName;
  final double openingStock;
  final double totalIncoming;
  final double totalOutgoing;
  final double currentStock;
  final CropUnit unit;
  final double lowStockThreshold;
  final DateTime updatedAt;

  StockItemModel({
    required this.id,
    required this.shopId,
    required this.cropName,
    required this.openingStock,
    this.totalIncoming = 0.0,
    this.totalOutgoing = 0.0,
    required this.currentStock,
    this.unit = CropUnit.quintal,
    this.lowStockThreshold = 10.0,
    required this.updatedAt,
  });

  bool get isLowStock => currentStock <= lowStockThreshold;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopId': shopId,
      'cropName': cropName,
      'openingStock': openingStock,
      'totalIncoming': totalIncoming,
      'totalOutgoing': totalOutgoing,
      'currentStock': currentStock,
      'unit': unit.name,
      'lowStockThreshold': lowStockThreshold,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory StockItemModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StockItemModel(
      id: doc.id,
      shopId: data['shopId'] ?? '',
      cropName: data['cropName'] ?? '',
      openingStock: (data['openingStock'] as num?)?.toDouble() ?? 0.0,
      totalIncoming: (data['totalIncoming'] as num?)?.toDouble() ?? 0.0,
      totalOutgoing: (data['totalOutgoing'] as num?)?.toDouble() ?? 0.0,
      currentStock: (data['currentStock'] as num?)?.toDouble() ?? 0.0,
      unit: CropUnit.fromString(data['unit'] ?? 'quintal'),
      lowStockThreshold: (data['lowStockThreshold'] as num?)?.toDouble() ?? 10.0,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
