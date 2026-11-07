import 'package:cloud_firestore/cloud_firestore.dart';

class PartyModel {
  final String id;
  final String shopId;
  final String partyName;
  final String mobileNumber;
  final String address;
  final double totalIncoming;
  final double totalOutgoing;
  final DateTime createdAt;
  final DateTime updatedAt;

  PartyModel({
    required this.id,
    required this.shopId,
    required this.partyName,
    required this.mobileNumber,
    required this.address,
    this.totalIncoming = 0.0,
    this.totalOutgoing = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopId': shopId,
      'partyName': partyName,
      'mobileNumber': mobileNumber,
      'address': address,
      'totalIncoming': totalIncoming,
      'totalOutgoing': totalOutgoing,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory PartyModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PartyModel(
      id: doc.id,
      shopId: data['shopId'] ?? '',
      partyName: data['partyName'] ?? '',
      mobileNumber: data['mobileNumber'] ?? '',
      address: data['address'] ?? '',
      totalIncoming: (data['totalIncoming'] as num?)?.toDouble() ?? 0.0,
      totalOutgoing: (data['totalOutgoing'] as num?)?.toDouble() ?? 0.0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
