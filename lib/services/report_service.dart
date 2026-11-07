import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/stock_item_model.dart';
import '../models/transaction_model.dart';
import '../models/vehicle_model.dart';

class DailySummaryReport {
  final DateTime date;
  final double totalIncomingQuantity;
  final double totalOutgoingQuantity;
  final int totalVehicleArrivals;
  final int totalVehicleDepartures;
  final Map<String, double> cropWiseIncoming;
  final Map<String, double> cropWiseOutgoing;
  final List<StockItemModel> currentStockSnapshot;

  DailySummaryReport({
    required this.date,
    required this.totalIncomingQuantity,
    required this.totalOutgoingQuantity,
    required this.totalVehicleArrivals,
    required this.totalVehicleDepartures,
    required this.cropWiseIncoming,
    required this.cropWiseOutgoing,
    required this.currentStockSnapshot,
  });
}

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DailySummaryReport generateDailySummary({
    required DateTime date,
    required List<StockItemModel> stocks,
    required List<TransactionModel> transactions,
    required List<VehicleModel> vehicles,
  }) {
    final dayTxs = transactions.where((tx) =>
        tx.createdAt.year == date.year &&
        tx.createdAt.month == date.month &&
        tx.createdAt.day == date.day).toList();

    double totalIn = 0.0;
    double totalOut = 0.0;
    final Map<String, double> cropIn = {};
    final Map<String, double> cropOut = {};

    for (final tx in dayTxs) {
      if (tx.type == TransactionType.incoming) {
        totalIn += tx.quantity;
        cropIn[tx.cropName] = (cropIn[tx.cropName] ?? 0.0) + tx.quantity;
      } else if (tx.type == TransactionType.outgoing) {
        totalOut += tx.quantity;
        cropOut[tx.cropName] = (cropOut[tx.cropName] ?? 0.0) + tx.quantity;
      }
    }

    final dayVehicles = vehicles.where((v) =>
        v.arrivalTime.year == date.year &&
        v.arrivalTime.month == date.month &&
        v.arrivalTime.day == date.day).toList();

    final arrivals = dayVehicles.where((v) => v.movementType == 'incoming').length;
    final departures = dayVehicles.where((v) => v.movementType == 'outgoing').length;

    return DailySummaryReport(
      date: date,
      totalIncomingQuantity: totalIn,
      totalOutgoingQuantity: totalOut,
      totalVehicleArrivals: arrivals,
      totalVehicleDepartures: departures,
      cropWiseIncoming: cropIn,
      cropWiseOutgoing: cropOut,
      currentStockSnapshot: stocks,
    );
  }
}
