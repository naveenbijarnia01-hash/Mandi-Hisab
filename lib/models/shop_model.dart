import 'package:cloud_firestore/cloud_firestore.dart';

class ShopModel {
  final String shopId;
  final String ownerName;
  final String mobileNumber;
  final String shopName;
  final String mandiName;
  final String city;
  final String state;
  final String address;
  final String? gstNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShopModel({
    required this.shopId,
    required this.ownerName,
    required this.mobileNumber,
    required this.shopName,
    required this.mandiName,
    required this.city,
    required this.state,
    required this.address,
    this.gstNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'shopId': shopId,
      'ownerName': ownerName,
      'mobileNumber': mobileNumber,
      'shopName': shopName,
      'mandiName': mandiName,
      'city': city,
      'state': state,
      'address': address,
      'gstNumber': gstNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ShopModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShopModel(
      shopId: data['shopId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      mobileNumber: data['mobileNumber'] ?? '',
      shopName: data['shopName'] ?? '',
      mandiName: data['mandiName'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      address: data['address'] ?? '',
      gstNumber: data['gstNumber'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
