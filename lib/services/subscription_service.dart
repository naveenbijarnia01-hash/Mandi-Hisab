import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../models/subscription_model.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Razorpay _razorpay;

  SubscriptionService() {
    _razorpay = Razorpay();
  }

  void initializeRazorpay({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
    required Function(ExternalWalletResponse) onExternalWallet,
  }) {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onFailure);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  // Stream current shop's subscription
  Stream<SubscriptionModel?> getSubscriptionStream(String shopId) {
    return _firestore.collection('subscriptions').doc(shopId).snapshots().map((doc) {
      if (doc.exists) {
        return SubscriptionModel.fromSnapshot(doc);
      }
      return null;
    });
  }

  // Open Razorpay Checkout for SaaS Subscription
  void openCheckout({
    required SubscriptionPlan plan,
    required String shopName,
    required String mobileNumber,
    required String shopId,
    required String razorpayKey,
  }) {
    final amountInPaise = (plan.price * 100).toInt();

    final options = {
      'key': razorpayKey,
      'amount': amountInPaise,
      'name': 'Mandi Hisab',
      'description': plan.label,
      'prefill': {
        'contact': mobileNumber,
        'email': 'shop_$shopId@mandihisab.in',
      },
      'external': {
        'wallets': ['paytm']
      },
      'notes': {
        'shopId': shopId,
        'plan': plan.name,
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print('Razorpay Open Error: $e');
    }
  }

  // Handle client-side success callback - notifies backend Cloud Function for signature verification
  Future<void> submitPaymentForVerification({
    required String shopId,
    required SubscriptionPlan plan,
    required String paymentId,
    required String? orderId,
    required String? signature,
  }) async {
    final now = DateTime.now();
    // Record pending payment in Firestore for backend verification
    final paymentDoc = _firestore.collection('payments').doc(paymentId);
    await paymentDoc.set({
      'paymentId': paymentId,
      'shopId': shopId,
      'plan': plan.name,
      'amount': plan.price,
      'orderId': orderId,
      'signature': signature,
      'status': 'pending_verification',
      'createdAt': Timestamp.fromDate(now),
    });
  }
}
