import 'package:cloud_firestore/cloud_firestore.dart';
import 'stock_item_model.dart';

enum TransactionType {
  incoming,
  outgoing,
  adjustment;

  String get label {
    switch (this) {
      case TransactionType.incoming:
        return 'Maal Aaya';
      case TransactionType.outgoing:
        return 'Maal Gaya';
      case TransactionType.adjustment:
        return 'Stock Sudhaar';
    }
  }

  static TransactionType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'incoming':
      case 'maal_aaya':
        return TransactionType.incoming;
      case 'outgoing':
      case 'maal_gaya':
        return TransactionType.outgoing;
      default:
        return TransactionType.adjustment;
    }
  }
}

class TransactionModel {
  final String id;
  final String shopId;
  final TransactionType type;
  final String cropName;
  final double quantity;
  final CropUnit unit;
  final String partyName;
  final String vehicleNumber;
  final String fromLocation;
  final String toLocation;
  final double? rate;
  final double? totalAmount;
  final String? notes;
  final String? billUrl;
  final bool isVoiceEntry;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionModel({
    required this.id,
    required this.shopId,
    required this.type,
    required this.cropName,
    required this.quantity,
    required this.unit,
    required this.partyName,
    required this.vehicleNumber,
    required this.fromLocation,
    required this.toLocation,
    this.rate,
    this.totalAmount,
    this.notes,
    this.billUrl,
    this.isVoiceEntry = false,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopId': shopId,
      'type': type.name,
      'cropName': cropName,
      'quantity': quantity,
      'unit': unit.name,
      'partyName': partyName,
      'vehicleNumber': vehicleNumber.toUpperCase().replaceAll(' ', ''),
      'fromLocation': fromLocation,
      'toLocation': toLocation,
      'rate': rate,
      'totalAmount': totalAmount,
      'notes': notes,
      'billUrl': billUrl,
      'isVoiceEntry': isVoiceEntry,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory TransactionModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      shopId: data['shopId'] ?? '',
      type: TransactionType.fromString(data['type'] ?? 'incoming'),
      cropName: data['cropName'] ?? '',
      quantity: (data['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: CropUnit.fromString(data['unit'] ?? 'quintal'),
      partyName: data['partyName'] ?? '',
      vehicleNumber: data['vehicleNumber'] ?? '',
      fromLocation: data['fromLocation'] ?? '',
      toLocation: data['toLocation'] ?? '',
      rate: (data['rate'] as num?)?.toDouble(),
      totalAmount: (data['totalAmount'] as num?)?.toDouble(),
      notes: data['notes'],
      billUrl: data['billUrl'],
      isVoiceEntry: data['isVoiceEntry'] ?? false,
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
