import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/stock_item_model.dart';
import '../../models/transaction_model.dart';
import '../../services/voice_parser_service.dart';

class VoiceConfirmationDialog extends StatefulWidget {
  final ParsedVoiceTransaction parsedTx;
  final Function(ParsedVoiceTransaction confirmedTx) onConfirmed;

  const VoiceConfirmationDialog({
    super.key,
    required this.parsedTx,
    required this.onConfirmed,
  });

  @override
  State<VoiceConfirmationDialog> createState() => _VoiceConfirmationDialogState();
}

class _VoiceConfirmationDialogState extends State<VoiceConfirmationDialog> {
  late TransactionType _type;
  late TextEditingController _cropController;
  late TextEditingController _qtyController;
  late CropUnit _unit;
  late TextEditingController _partyController;
  late TextEditingController _vehicleController;
  late TextEditingController _fromController;
  late TextEditingController _toController;

  @override
  void initState() {
    super.initState();
    _type = widget.parsedTx.type;
    _cropController = TextEditingController(text: widget.parsedTx.cropName);
    _qtyController = TextEditingController(text: widget.parsedTx.quantity.toString());
    _unit = widget.parsedTx.unit;
    _partyController = TextEditingController(text: widget.parsedTx.partyName);
    _vehicleController = TextEditingController(text: widget.parsedTx.vehicleNumber);
    _fromController = TextEditingController(text: widget.parsedTx.fromLocation);
    _toController = TextEditingController(text: widget.parsedTx.toLocation);
  }

  @override
  void dispose() {
    _cropController.dispose();
    _qtyController.dispose();
    _partyController.dispose();
    _vehicleController.dispose();
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    final updated = ParsedVoiceTransaction(
      type: _type,
      cropName: _cropController.text.trim(),
      quantity: double.tryParse(_qtyController.text.trim()) ?? widget.parsedTx.quantity,
      unit: _unit,
      partyName: _partyController.text.trim(),
      vehicleNumber: _vehicleController.text.trim(),
      fromLocation: _fromController.text.trim(),
      toLocation: _toController.text.trim(),
      rawText: widget.parsedTx.rawText,
    );
    Navigator.pop(context);
    widget.onConfirmed(updated);
  }

  @override
  Widget build(BuildContext context) {
    final isIncoming = _type == TransactionType.incoming;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isIncoming ? AppColors.success : const Color(0xFFC2410C),
                  child: Icon(
                    isIncoming ? Icons.arrow_downward : Icons.arrow_upward,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isIncoming ? 'Aavak Entry (Maal Aaya)' : 'Javak Entry (Maal Gaya)',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Aawaz se nikali gayi jankari check karein aur confirm karein',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Raw Spoken Prompt
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.divider),
              ),
              child: Text(
                '🎙️ "${widget.parsedTx.rawText}"',
                style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 16),

            // Editable Fields
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cropController,
                    decoration: const InputDecoration(labelText: 'Fasal (Crop)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Maatra (Qty)'),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<CropUnit>(
                  value: _unit,
                  items: CropUnit.values
                      .map((u) => DropdownMenuItem(value: u, child: Text(u.label)))
                      .toList(),
                  onChanged: (v) => setState(() => _unit = v!),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _partyController,
              decoration: const InputDecoration(labelText: 'Party / Kisan / Factory'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _vehicleController,
              decoration: const InputDecoration(labelText: 'Gaadi Number'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _fromController,
                    decoration: const InputDecoration(labelText: 'From Location'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _toController,
                    decoration: const InputDecoration(labelText: 'To Location'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Confirmation and Cancel buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Radd Karein (Cancel)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isIncoming ? AppColors.success : const Color(0xFFC2410C),
                    ),
                    onPressed: _handleConfirm,
                    child: const Text('Confirm & Save Stock'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
