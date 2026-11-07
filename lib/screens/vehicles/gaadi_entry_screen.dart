import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/stock_item_model.dart';
import '../../models/vehicle_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vehicle_provider.dart';

class GaadiEntryScreen extends ConsumerStatefulWidget {
  const GaadiEntryScreen({super.key});

  @override
  ConsumerState<GaadiEntryScreen> createState() => _GaadiEntryScreenState();
}

class _GaadiEntryScreenState extends ConsumerState<GaadiEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  final _vehicleController = TextEditingController();
  final _partyController = TextEditingController();
  final _sourceController = TextEditingController();
  final _destController = TextEditingController();
  final _cropController = TextEditingController(text: 'Gehun');
  final _qtyController = TextEditingController();
  CropUnit _selectedUnit = CropUnit.quintal;
  String _movementType = 'incoming'; // incoming or outgoing
  bool _isSaving = false;

  @override
  void dispose() {
    _vehicleController.dispose();
    _partyController.dispose();
    _sourceController.dispose();
    _destController.dispose();
    _cropController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final shop = ref.read(authProvider).currentShop;
    final shopId = shop?.shopId ?? 'SHOP_DEMO';

    try {
      final cargoItem = VehicleCargoItem(
        cropName: _cropController.text.trim(),
        quantity: double.parse(_qtyController.text.trim()),
        unit: _selectedUnit,
      );

      await ref.read(vehicleServiceProvider).registerVehicle(
            shopId: shopId,
            vehicleNumber: _vehicleController.text.trim(),
            arrivalTime: DateTime.now(),
            sourceLocation: _sourceController.text.trim().isEmpty ? 'Mandi Gate' : _sourceController.text.trim(),
            destinationLocation: _destController.text.trim().isEmpty ? (shop?.shopName ?? 'Dukaan Godam') : _destController.text.trim(),
            items: [cargoItem],
            partyName: _partyController.text.trim(),
            movementType: _movementType,
            notes: 'Gaadi registered via app',
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('✅ Gaadi successfully register ho gayi!'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nayi Gaadi Entry'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Movement Type',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Aavak (Incoming)'),
                              value: 'incoming',
                              groupValue: _movementType,
                              onChanged: (v) => setState(() => _movementType = v!),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Javak (Outgoing)'),
                              value: 'outgoing',
                              groupValue: _movementType,
                              onChanged: (v) => setState(() => _movementType = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _vehicleController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Gaadi Number *',
                          hintText: 'RJ 14 AB 1234',
                          prefixIcon: Icon(Icons.directions_car, color: AppColors.primary),
                        ),
                        validator: (v) => v!.isEmpty ? 'Gaadi number zaroori hai' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _partyController,
                        decoration: const InputDecoration(
                          labelText: 'Associated Party / Kisan Naam *',
                          hintText: 'Ramesh Kisan',
                          prefixIcon: Icon(Icons.person, color: AppColors.primary),
                        ),
                        validator: (v) => v!.isEmpty ? 'Party naam zaroori hai' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _sourceController,
                        decoration: const InputDecoration(
                          labelText: 'Kahan Se Aayi (Source)',
                          hintText: 'Kisan Khet / Mandi',
                          prefixIcon: Icon(Icons.pin_drop, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _destController,
                        decoration: const InputDecoration(
                          labelText: 'Kahan Gayi (Destination)',
                          hintText: 'Dukaan Godam / Factory',
                          prefixIcon: Icon(Icons.location_on, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _cropController,
                              decoration: const InputDecoration(
                                labelText: 'Fasal (Crop)',
                                prefixIcon: Icon(Icons.eco, color: AppColors.primary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _qtyController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Quantity *',
                                prefixIcon: Icon(Icons.scale, color: AppColors.primary),
                              ),
                              validator: (v) => v!.isEmpty ? 'Qty dalein' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<CropUnit>(
                              value: _selectedUnit,
                              decoration: const InputDecoration(labelText: 'Unit'),
                              items: CropUnit.values.map((u) => DropdownMenuItem(value: u, child: Text(u.label))).toList(),
                              onChanged: (v) => setState(() => _selectedUnit = v!),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _handleSubmit,
                icon: const Icon(Icons.save),
                label: _isSaving
                    ? const CircularProgressIndicator(color: AppColors.secondary)
                    : const Text('Gaadi Register Save Karein'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
