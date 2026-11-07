import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../dashboard/home_dashboard_screen.dart';

class ShopSetupScreen extends ConsumerStatefulWidget {
  final String mobileNumber;
  const ShopSetupScreen({super.key, required this.mobileNumber});

  @override
  ConsumerState<ShopSetupScreen> createState() => _ShopSetupScreenState();
}

class _ShopSetupScreenState extends ConsumerState<ShopSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ownerController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _mandiNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController(text: 'Rajasthan');
  final _addressController = TextEditingController();
  final _gstController = TextEditingController();

  @override
  void dispose() {
    _ownerController.dispose();
    _shopNameController.dispose();
    _mandiNameController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _addressController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authProvider.notifier).registerShop(
            ownerName: _ownerController.text.trim(),
            mobileNumber: widget.mobileNumber,
            shopName: _shopNameController.text.trim(),
            mandiName: _mandiNameController.text.trim(),
            city: _cityController.text.trim(),
            stateName: _stateController.text.trim(),
            address: _addressController.text.trim(),
            gstNumber: _gstController.text.trim().isEmpty ? null : _gstController.text.trim(),
          );

      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeDashboardScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dukaan Profile Setup'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Apni Anaj Mandi Dukaan ki Jankari Bharein',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 20),

                // Owner Name
                TextFormField(
                  controller: _ownerController,
                  decoration: const InputDecoration(
                    labelText: 'Vyapari / Owner Naam *',
                    prefixIcon: Icon(Icons.person, color: AppColors.primary),
                  ),
                  validator: (v) => v!.isEmpty ? 'Naam zaroori hai' : null,
                ),
                const SizedBox(height: 16),

                // Shop Name
                TextFormField(
                  controller: _shopNameController,
                  decoration: const InputDecoration(
                    labelText: 'Dukaan / Firm Ka Naam *',
                    prefixIcon: Icon(Icons.store, color: AppColors.primary),
                  ),
                  validator: (v) => v!.isEmpty ? 'Dukaan ka naam zaroori hai' : null,
                ),
                const SizedBox(height: 16),

                // Mandi Name
                TextFormField(
                  controller: _mandiNameController,
                  decoration: const InputDecoration(
                    labelText: 'Anaj Mandi Ka Naam *',
                    hintText: 'Jaipur Krishi Upaj Mandi',
                    prefixIcon: Icon(Icons.location_city, color: AppColors.primary),
                  ),
                  validator: (v) => v!.isEmpty ? 'Mandi ka naam zaroori hai' : null,
                ),
                const SizedBox(height: 16),

                // City & State
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          labelText: 'Shehar (City) *',
                          prefixIcon: Icon(Icons.map, color: AppColors.primary),
                        ),
                        validator: (v) => v!.isEmpty ? 'Zaroori hai' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _stateController,
                        decoration: const InputDecoration(
                          labelText: 'Rajya (State) *',
                          prefixIcon: Icon(Icons.flag, color: AppColors.primary),
                        ),
                        validator: (v) => v!.isEmpty ? 'Zaroori hai' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Address
                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Poora Pata (Address)',
                    prefixIcon: Icon(Icons.place, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 16),

                // GST Number (Optional)
                TextFormField(
                  controller: _gstController,
                  decoration: const InputDecoration(
                    labelText: 'GST Number (Optional)',
                    hintText: '08AAAAA0000A1Z5',
                    prefixIcon: Icon(Icons.receipt_long, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: authState.isLoading ? null : _handleRegister,
                  child: authState.isLoading
                      ? const CircularProgressIndicator(color: AppColors.secondary)
                      : const Text('Dukaan Register Karein & Free Trial Shuru Karein'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
