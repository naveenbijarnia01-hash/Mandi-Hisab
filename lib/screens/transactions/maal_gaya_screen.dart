import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/stock_item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stock_provider.dart';

class MaalGayaScreen extends ConsumerStatefulWidget {
  const MaalGayaScreen({super.key});

  @override
  ConsumerState<MaalGayaScreen> createState() => _MaalGayaScreenState();
}

class _MaalGayaScreenState extends ConsumerState<MaalGayaScreen> {
  final _formKey = GlobalKey<FormState>();

  String _selectedCrop = 'Gehun';
  CropUnit _selectedUnit = CropUnit.quintal;
  final _quantityController = TextEditingController();
  final _partyController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _toController = TextEditingController();
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
    _toController.dispose();
    _rateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleSubmit({bool overrideNegativeStock = false}) async {
    if (!_formKey.currentState!.validate()) return;

    final reqQty = double.parse(_quantityController.text.trim());
    final stocksAsync = ref.read(stockListStreamProvider);

    // Validate available stock
    stocksAsync.whenData((stocks) {
      final matchingStock = stocks.firstWhere(
        (s) => s.cropName.toLowerCase() == _selectedCrop.toLowerCase(),
        orElse: () => StockItemModel(
          id: 'temp',
          shopId: '',
          cropName: _selectedCrop,
          openingStock: 0,
          currentStock: 0,
          updatedAt: DateTime.now(),
        ),
      );

      if (matchingStock.currentStock < reqQty && !overrideNegativeStock) {
        // Show Explicit Warning Dialog as required by specification
        _showNegativeStockWarningDialog(matchingStock.currentStock, reqQty);
        return;
      }

      _performSave(overrideNegativeStock);
    });
  }

  void _showNegativeStockWarningDialog(double currentAvailable, double requestedQty) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 48),
        title: const Text('Savdhani: Stock Kam Hai!'),
        content: Text(
          'Aapke paas $_selectedCrop ka sirf $currentAvailable Quintal stock uplabdh hai, jabki aap $requestedQty Quintal dispatch kar rahe hain.\n\nNegative stock create ho sakta hai. Kya aap sure hain?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel Karein'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              _performSave(true);
            },
            child: const Text('Confirm (Allow Negative)'),
          ),
        ],
      ),
    );
  }

  void _performSave(bool allowNegative) async {
    setState(() => _isSaving = true);
    final shop = ref.read(authProvider).currentShop;
    final shopId = shop?.shopId ?? 'SHOP_DEMO';

    try {
      await ref.read(stockServiceProvider).recordOutgoingGoods(
            shopId: shopId,
            cropName: _selectedCrop,
            quantity: double.parse(_quantityController.text.trim()),
            unit: _selectedUnit,
            partyName: _partyController.text.trim(),
            vehicleNumber: _vehicleController.text.trim(),
            fromLocation: shop?.shopName ?? 'Dukaan Godam',
            toLocation: _toController.text.trim().isEmpty ? 'Factory / Mandi' : _toController.text.trim(),
            rate: double.tryParse(_rateController.text.trim()),
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
            allowNegativeStock: allowNegative,
            userId: 'owner',
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text('✅ $_selectedCrop (${_quantityController.text} ${_selectedUnit.label}) dispatch ho gaya!'),
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
        title: const Text('Maal Gaya (Javak Entry)'),
        backgroundColor: const Color(0xFFC2410C),
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
                        'Dispatch Fasal Chunein',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedCrop,
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.eco, color: Color(0xFFC2410C))),
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
                                labelText: 'Nikaasi Maatra (Qty) *',
                                prefixIcon: Icon(Icons.scale, color: Color(0xFFC2410C)),
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
                          labelText: 'Receiver / Factory / Vyapari Naam *',
                          hintText: 'Sungna Factory',
                          prefixIcon: Icon(Icons.business, color: Color(0xFFC2410C)),
                        ),
                        validator: (v) => v!.isEmpty ? 'Party ka naam zaroori hai' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _vehicleController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Gaadi Number *',
                          hintText: 'RJ 14 U 0010',
                          prefixIcon: Icon(Icons.local_shipping, color: Color(0xFFC2410C)),
                        ),
                        validator: (v) => v!.isEmpty ? 'Gaadi number dalein' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _toController,
                        decoration: const InputDecoration(
                          labelText: 'Kahan Bheja (Destination Location)',
                          hintText: 'Sungna Factory, Jaipur',
                          prefixIcon: Icon(Icons.pin_drop, color: Color(0xFFC2410C)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _rateController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Bikri Bhaav / Selling Rate (Optional)',
                          hintText: '₹ prati quintal',
                          prefixIcon: Icon(Icons.currency_rupee, color: Color(0xFFC2410C)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Tippani (Notes)',
                          hintText: 'Bilti number ya driver number',
                          prefixIcon: Icon(Icons.note, color: Color(0xFFC2410C)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC2410C)),
                onPressed: _isSaving ? null : () => _handleSubmit(),
                icon: const Icon(Icons.send_rounded),
                label: _isSaving
                    ? const CircularProgressIndicator(color: AppColors.secondary)
                    : const Text('Maal Dispatch Save Karein (Minus Stock)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
