import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/stock_item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stock_provider.dart';

class MaalAayaScreen extends ConsumerStatefulWidget {
  const MaalAayaScreen({super.key});

  @override
  ConsumerState<MaalAayaScreen> createState() => _MaalAayaScreenState();
}

class _MaalAayaScreenState extends ConsumerState<MaalAayaScreen> {
  final _formKey = GlobalKey<FormState>();

  String _selectedCrop = 'Gehun';
  CropUnit _selectedUnit = CropUnit.quintal;
  final _quantityController = TextEditingController();
  final _partyController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _fromController = TextEditingController();
  final _rateController = TextEditingController();
  final _notesController = TextEditingController();

  final List<String> _crops = [
    'Gehun',
    'Sarson',
    'Bajra',
    'Chana',
    'Jau',
    'Makka',
    'Dhan',
    'Soybean',
    'Other Crop'
  ];

  bool _isSaving = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _partyController.dispose();
    _vehicleController.dispose();
    _fromController.dispose();
    _rateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final shop = ref.read(authProvider).currentShop;
    final shopId = shop?.shopId ?? 'SHOP_DEMO';

    try {
      await ref.read(stockServiceProvider).recordIncomingGoods(
            shopId: shopId,
            cropName: _selectedCrop,
            quantity: double.parse(_quantityController.text.trim()),
            unit: _selectedUnit,
            partyName: _partyController.text.trim(),
            vehicleNumber: _vehicleController.text.trim(),
            fromLocation: _fromController.text.trim().isEmpty ? 'Kisan / Mandi' : _fromController.text.trim(),
            toLocation: shop?.shopName ?? 'Dukaan Godam',
            rate: double.tryParse(_rateController.text.trim()),
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
            userId: 'owner',
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text('✅ $_selectedCrop (${_quantityController.text} ${_selectedUnit.label}) stock mein jod diya gaya!'),
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
        title: const Text('Maal Aaya (Aavak Entry)'),
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
                        'Fasal Chunein (Crop)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedCrop,
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.eco, color: AppColors.primary)),
                        items: _crops.map((crop) => DropdownMenuItem(value: crop, child: Text(crop))).toList(),
                        onChanged: (val) => setState(() => _selectedCrop = val!),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _quantityController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Maatra (Quantity) *',
                                prefixIcon: Icon(Icons.scale, color: AppColors.primary),
                              ),
                              validator: (v) => v!.isEmpty ? 'Quantity dalein' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<CropUnit>(
                              value: _selectedUnit,
                              decoration: const InputDecoration(labelText: 'Unit'),
                              items: CropUnit.values.map((u) => DropdownMenuItem(value: u, child: Text(u.label))).toList(),
                              onChanged: (val) => setState(() => _selectedUnit = val!),
                            ),
                          ),
                        ],
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
                        controller: _partyController,
                        decoration: const InputDecoration(
                          labelText: 'Kisan / Party Ka Naam *',
                          hintText: 'Suresh Kumar',
                          prefixIcon: Icon(Icons.person, color: AppColors.primary),
                        ),
                        validator: (v) => v!.isEmpty ? 'Party ka naam zaroori hai' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _vehicleController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Gaadi Number *',
                          hintText: 'RJ 14 AB 1234',
                          prefixIcon: Icon(Icons.directions_car, color: AppColors.primary),
                        ),
                        validator: (v) => v!.isEmpty ? 'Gaadi number dalein' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _fromController,
                        decoration: const InputDecoration(
                          labelText: 'Kahan Se Aaya (Source Location)',
                          hintText: 'Chomu Mandi ya Gaon',
                          prefixIcon: Icon(Icons.pin_drop, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _rateController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Kharid Bhaav / Rate (Optional)',
                          hintText: '₹ prati quintal',
                          prefixIcon: Icon(Icons.currency_rupee, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Tippani (Notes)',
                          hintText: 'Bori count ya anya jankari',
                          prefixIcon: Icon(Icons.note, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _handleSubmit,
                icon: const Icon(Icons.check_circle_outline),
                label: _isSaving
                    ? const CircularProgressIndicator(color: AppColors.secondary)
                    : const Text('Maal Aavak Save Karein (Add Stock)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
