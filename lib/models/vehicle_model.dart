import 'package:cloud_firestore/cloud_firestore.dart';
import 'stock_item_model.dart';

class VehicleCargoItem {
  final String cropName;
  final double quantity;
  final CropUnit unit;

  VehicleCargoItem({
    required this.cropName,
    required this.quantity,
    this.unit = CropUnit.quintal,
  });

  Map<String, dynamic> toJson() => {
    'cropName': cropName,
    'quantity': quantity,
    'unit': unit.name,
  };

  factory VehicleCargoItem.fromJson(Map<String, dynamic> json) => VehicleCargoItem(
    cropName: json['cropName'] ?? '',
    quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
    unit: CropUnit.fromString(json['unit'] ?? 'quintal'),
  );
}

enum VehicleStatus {
  pending,
  completed;

  String get label => this == VehicleStatus.pending ? 'Chalu (Pending)' : 'Pura (Completed)';
}

class VehicleModel {
  final String id;
  final String shopId;
  final String vehicleNumber;
  final DateTime arrivalTime;
  final DateTime? departureTime;
  final String sourceLocation;
  final String destinationLocation;
  final List<VehicleCargoItem> items;
  final String partyName;
  final String movementType; // 'incoming' or 'outgoing'
  final VehicleStatus status;
  final List<String> linkedTransactionIds;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  VehicleModel({
    required this.id,
    required this.shopId,
    required this.vehicleNumber,
    required this.arrivalTime,
    this.departureTime,
    required this.sourceLocation,
    required this.destinationLocation,
    required this.items,
    required this.partyName,
    required this.movementType,
    this.status = VehicleStatus.pending,
    this.linkedTransactionIds = const [],
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopId': shopId,
      'vehicleNumber': vehicleNumber.toUpperCase().replaceAll(' ', ''),
      'arrivalTime': Timestamp.fromDate(arrivalTime),
      'departureTime': departureTime != null ? Timestamp.fromDate(departureTime!) : null,
      'sourceLocation': sourceLocation,
      'destinationLocation': destinationLocation,
      'items': items.map((e) => e.toJson()).toList(),
      'partyName': partyName,
      'movementType': movementType,
      'status': status.name,
      'linkedTransactionIds': linkedTransactionIds,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory VehicleModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VehicleModel(
      id: doc.id,
      shopId: data['shopId'] ?? '',
      vehicleNumber: data['vehicleNumber'] ?? '',
      arrivalTime: (data['arrivalTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      departureTime: (data['departureTime'] as Timestamp?)?.toDate(),
      sourceLocation: data['sourceLocation'] ?? '',
      destinationLocation: data['destinationLocation'] ?? '',
      items: (data['items'] as List<dynamic>?)
              ?.map((e) => VehicleCargoItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      partyName: data['partyName'] ?? '',
      movementType: data['movementType'] ?? 'incoming',
      status: data['status'] == 'completed' ? VehicleStatus.completed : VehicleStatus.pending,
      linkedTransactionIds: List<String>.from(data['linkedTransactionIds'] ?? []),
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
