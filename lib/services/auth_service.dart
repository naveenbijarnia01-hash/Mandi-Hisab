import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/shop_model.dart';
import '../models/subscription_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  String? _verificationId;

  // Send OTP to Indian mobile number
  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      final formattedPhone = phoneNumber.startsWith('+91')
          ? phoneNumber
          : '+91$phoneNumber';

      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'OTP verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  // Verify OTP
  Future<UserCredential?> verifyOtp({
    required String smsCode,
    String? verificationId,
  }) async {
    final vId = verificationId ?? _verificationId;
    if (vId == null) throw Exception('Verification ID not found');

    final credential = PhoneAuthProvider.credential(
      verificationId: vId,
      smsCode: smsCode,
    );
    return await _auth.signInWithCredential(credential);
  }

  // Check if shop profile exists for current user
  Future<ShopModel?> getShopProfile(String userId) async {
    final doc = await _firestore.collection('shops').doc(userId).get();
    if (doc.exists) {
      return ShopModel.fromSnapshot(doc);
    }
    return null;
  }

  // Create Shop Profile and automatically initiate 7-day Free Trial
  Future<ShopModel> registerShop({
    required String ownerName,
    required String mobileNumber,
    required String shopName,
    required String mandiName,
    required String city,
    required String state,
    required String address,
    String? gstNumber,
  }) async {
    final userId = _auth.currentUser?.uid ?? 'SHOP_${DateTime.now().millisecondsSinceEpoch}';
    final shopId = 'MH-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final now = DateTime.now();
    final shop = ShopModel(
      shopId: shopId,
      ownerName: ownerName,
      mobileNumber: mobileNumber,
      shopName: shopName,
      mandiName: mandiName,
      city: city,
      state: state,
      address: address,
      gstNumber: gstNumber,
      createdAt: now,
      updatedAt: now,
    );

    // Save shop profile
    await _firestore.collection('shops').doc(shopId).set(shop.toJson());
    // Map user to shop
    await _firestore.collection('users').doc(userId).set({
      'userId': userId,
      'shopId': shopId,
      'mobileNumber': mobileNumber,
      'role': 'owner',
      'createdAt': Timestamp.fromDate(now),
    });

    // Automatically create 7-day Free Trial
    final trialEnd = now.add(const Duration(days: 7));
    final subscription = SubscriptionModel(
      id: 'sub_$shopId',
      shopId: shopId,
      plan: SubscriptionPlan.freeTrial,
      status: SubscriptionStatus.trial,
      startDate: now,
      endDate: trialEnd,
      createdAt: now,
      updatedAt: now,
    );
    await _firestore.collection('subscriptions').doc(shopId).set(subscription.toJson());

    return shop;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
