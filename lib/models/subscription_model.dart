import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionStatus {
  trial,
  active,
  pending,
  gracePeriod,
  expired,
  cancelled;

  String get label {
    switch (this) {
      case SubscriptionStatus.trial:
        return 'Free Trial (7 Din)';
      case SubscriptionStatus.active:
        return 'Active Premium';
      case SubscriptionStatus.pending:
        return 'Payment Pending';
      case SubscriptionStatus.gracePeriod:
        return 'Grace Period (3 Din)';
      case SubscriptionStatus.expired:
        return 'Expired (Read-Only)';
      case SubscriptionStatus.cancelled:
        return 'Cancelled';
    }
  }

  static SubscriptionStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'active':
        return SubscriptionStatus.active;
      case 'pending':
        return SubscriptionStatus.pending;
      case 'grace_period':
      case 'graceperiod':
        return SubscriptionStatus.gracePeriod;
      case 'expired':
        return SubscriptionStatus.expired;
      case 'cancelled':
        return SubscriptionStatus.cancelled;
      case 'trial':
      default:
        return SubscriptionStatus.trial;
    }
  }
}

enum SubscriptionPlan {
  freeTrial,
  monthly,
  yearly;

  String get label {
    switch (this) {
      case SubscriptionPlan.freeTrial:
        return 'Free Trial (7 Din)';
      case SubscriptionPlan.monthly:
        return 'Monthly (₹199 / Mahina)';
      case SubscriptionPlan.yearly:
        return 'Yearly (₹1,999 / Saal)';
    }
  }

  double get price {
    switch (this) {
      case SubscriptionPlan.freeTrial:
        return 0.0;
      case SubscriptionPlan.monthly:
        return 199.0;
      case SubscriptionPlan.yearly:
        return 1999.0;
    }
  }
}

class SubscriptionModel {
  final String id;
  final String shopId;
  final SubscriptionPlan plan;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? gracePeriodEndDate;
  final String? razorpaySubscriptionId;
  final String? razorpayPaymentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubscriptionModel({
    required this.id,
    required this.shopId,
    required this.plan,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.gracePeriodEndDate,
    this.razorpaySubscriptionId,
    this.razorpayPaymentId,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get canPerformTransactions {
    final now = DateTime.now();
    if (status == SubscriptionStatus.active || status == SubscriptionStatus.trial) {
      return now.isBefore(endDate);
    }
    if (status == SubscriptionStatus.gracePeriod) {
      return gracePeriodEndDate != null && now.isBefore(gracePeriodEndDate!);
    }
    return false;
  }

  int get remainingDays {
    final now = DateTime.now();
    final target = (status == SubscriptionStatus.gracePeriod && gracePeriodEndDate != null)
        ? gracePeriodEndDate!
        : endDate;
    final diff = target.difference(now).inDays;
    return diff > 0 ? diff : 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopId': shopId,
      'plan': plan.name,
      'status': status.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'gracePeriodEndDate':
          gracePeriodEndDate != null ? Timestamp.fromDate(gracePeriodEndDate!) : null,
      'razorpaySubscriptionId': razorpaySubscriptionId,
      'razorpayPaymentId': razorpayPaymentId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory SubscriptionModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubscriptionModel(
      id: doc.id,
      shopId: data['shopId'] ?? '',
      plan: SubscriptionPlan.values.firstWhere(
        (e) => e.name == data['plan'],
        orElse: () => SubscriptionPlan.freeTrial,
      ),
      status: SubscriptionStatus.fromString(data['status'] ?? 'trial'),
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 7)),
      gracePeriodEndDate: (data['gracePeriodEndDate'] as Timestamp?)?.toDate(),
      razorpaySubscriptionId: data['razorpaySubscriptionId'],
      razorpayPaymentId: data['razorpayPaymentId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
