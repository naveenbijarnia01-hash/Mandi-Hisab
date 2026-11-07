import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vehicle_model.dart';

class VehicleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<VehicleModel>> getVehiclesStream(String shopId) {
    return _firestore
        .collection('vehicles')
        .where('shopId', isEqualTo: shopId)
        .orderBy('arrivalTime', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => VehicleModel.fromSnapshot(doc)).toList());
  }

  Future<void> registerVehicle({
    required String shopId,
    required String vehicleNumber,
    required DateTime arrivalTime,
    required String sourceLocation,
    required String destinationLocation,
    required List<VehicleCargoItem> items,
    required String partyName,
    required String movementType,
    String? notes,
  }) async {
    final now = DateTime.now();
    final docRef = _firestore.collection('vehicles').doc();

    final vehicle = VehicleModel(
      id: docRef.id,
      shopId: shopId,
      vehicleNumber: vehicleNumber,
      arrivalTime: arrivalTime,
      sourceLocation: sourceLocation,
      destinationLocation: destinationLocation,
      items: items,
      partyName: partyName,
      movementType: movementType,
      status: VehicleStatus.pending,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(vehicle.toJson());
  }

  Future<void> markVehicleCompleted({
    required String vehicleId,
    required String transactionId,
  }) async {
    await _firestore.collection('vehicles').doc(vehicleId).update({
      'status': VehicleStatus.completed.name,
      'departureTime': Timestamp.fromDate(DateTime.now()),
      'linkedTransactionIds': FieldValue.arrayUnion([transactionId]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
