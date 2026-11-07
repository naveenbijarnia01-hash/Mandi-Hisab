import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stock_item_model.dart';
import '../models/vehicle_model.dart';
import '../services/vehicle_service.dart';
import 'auth_provider.dart';

final vehicleServiceProvider = Provider<VehicleService>((ref) {
  return VehicleService();
});

final vehicleListStreamProvider = StreamProvider<List<VehicleModel>>((ref) {
  final currentShop = ref.watch(authProvider).currentShop;
  if (currentShop == null) {
    // Return mock vehicles
    return Stream.value([
      VehicleModel(
        id: 'v_1',
        shopId: 'SHOP_DEMO',
        vehicleNumber: 'RJ14GB4512',
        arrivalTime: DateTime.now().subtract(const Duration(hours: 1, minutes: 20)),
        sourceLocation: 'Chomu Mandi',
        destinationLocation: 'Dukaan Godam',
        items: [
          VehicleCargoItem(cropName: 'Gehun', quantity: 50, unit: CropUnit.quintal),
        ],
        partyName: 'Suresh Kumar Kisan',
        movementType: 'incoming',
        status: VehicleStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 20)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 20)),
      ),
      VehicleModel(
        id: 'v_2',
        shopId: 'SHOP_DEMO',
        vehicleNumber: 'RJ23U8810',
        arrivalTime: DateTime.now().subtract(const Duration(hours: 4)),
        departureTime: DateTime.now().subtract(const Duration(hours: 3)),
        sourceLocation: 'Dukaan Godam',
        destinationLocation: 'Sungna Oil Factory',
        items: [
          VehicleCargoItem(cropName: 'Sarson', quantity: 30, unit: CropUnit.quintal),
        ],
        partyName: 'Sungna Oil Factory',
        movementType: 'outgoing',
        status: VehicleStatus.completed,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ]);
  }
  return ref.watch(vehicleServiceProvider).getVehiclesStream(currentShop.shopId);
});
