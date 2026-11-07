import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/stock_item_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stock_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../services/voice_assistant_service.dart';
import '../../services/voice_parser_service.dart';
import 'voice_confirmation_dialog.dart';

class VoiceAssistantScreen extends ConsumerStatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  ConsumerState<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends ConsumerState<VoiceAssistantScreen> {
  final VoiceAssistantService _voiceService = VoiceAssistantService();
  bool _isListening = false;
  String _spokenText = '';
  String _assistantReply = '';

  final List<String> _examplePrompts = [
    'Aaj 50 quintal gehun Sungna Factory mein gaye hain, gaadi number RJ14U0010 se.',
    'Aaj 100 quintal sarson Suresh ji se aayi hai, gaadi RJ23AB1234 se.',
    'Aaj kitna gehun bacha hai?',
    'Aaj kitna maal nikla?',
    'Meri dukaan ka aaj ka poora hisaab batao.',
  ];

  @override
  void initState() {
    super.initState();
    _initVoice();
  }

  void _initVoice() async {
    await _voiceService.initSpeech();
  }

  void _toggleListening() async {
    if (_isListening) {
      await _voiceService.stopListening();
      setState(() => _isListening = false);
      _processVoiceInput(_spokenText);
    } else {
      setState(() {
        _isListening = true;
        _spokenText = '';
        _assistantReply = '';
      });

      await _voiceService.listen(
        onResult: (text) {
          setState(() => _spokenText = text);
        },
        onDone: () {
          setState(() => _isListening = false);
          _processVoiceInput(_spokenText);
        },
      );
    }
  }

  void _processVoiceInput(String text) {
    if (text.trim().isEmpty) return;

    final lower = text.toLowerCase();
    // Check if this is a query/question or a transaction command
    final isQuery = lower.contains('?') ||
        lower.contains('kitna') ||
        lower.contains('kab aayi') ||
        lower.contains('batao') ||
        lower.contains('bacha');

    if (isQuery) {
      final stocks = ref.read(stockListStreamProvider).value ?? [];
      final txs = ref.read(transactionsStreamProvider).value ?? [];
      final vehicles = ref.read(vehicleListStreamProvider).value ?? [];

      final reply = _voiceService.answerQuery(
        query: text,
        stocks: stocks,
        transactions: txs,
        vehicles: vehicles,
      );

      setState(() => _assistantReply = reply);
      _voiceService.speak(reply);
    } else {
      // It is a transaction command -> Parse into structured fields
      final parsed = VoiceParserService.parseCommand(text);

      // Never update stock directly from unconfirmed voice command!
      // Display confirmation screen containing all extracted fields:
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => VoiceConfirmationDialog(
          parsedTx: parsed,
          onConfirmed: (tx) async {
            final shop = ref.read(authProvider).currentShop;
            final shopId = shop?.shopId ?? 'SHOP_DEMO';

            if (tx.type == TransactionType.incoming) {
              await ref.read(stockServiceProvider).recordIncomingGoods(
                    shopId: shopId,
                    cropName: tx.cropName,
                    quantity: tx.quantity,
                    unit: tx.unit,
                    partyName: tx.partyName,
                    vehicleNumber: tx.vehicleNumber,
                    fromLocation: tx.fromLocation,
                    toLocation: tx.toLocation,
                    isVoiceEntry: true,
                    userId: 'owner',
                  );
            } else {
              await ref.read(stockServiceProvider).recordOutgoingGoods(
                    shopId: shopId,
                    cropName: tx.cropName,
                    quantity: tx.quantity,
                    unit: tx.unit,
                    partyName: tx.partyName,
                    vehicleNumber: tx.vehicleNumber,
                    fromLocation: tx.fromLocation,
                    toLocation: tx.toLocation,
                    isVoiceEntry: true,
                    allowNegativeStock: true,
                    userId: 'owner',
                  );
            }

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.success,
                  content: Text('✅ Voice Transaction darz kar diya gaya: ${tx.cropName} (${tx.quantity} ${tx.unit.label})'),
                ),
              );
              Navigator.pop(context);
            }
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Voice Digital Munim'),
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Voice Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              color: AppColors.primary,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _toggleListening,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: _isListening ? AppColors.error : AppColors.accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isListening ? AppColors.error : AppColors.accent).withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: _isListening ? 6 : 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.stop : Icons.mic,
                        size: 48,
                        color: _isListening ? Colors.white : AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isListening ? 'Aapki aawaz sun rahe hain... Bolte rahein' : 'Mic dabayein aur bolna shuru karein',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Hindi ya Hinglish mein aam bolchal mein boleis',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),

            // Live Captured & Spoken Text Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_spokenText.isNotEmpty) ...[
                      const Text(
                        'Aapne Kaha:',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Text(
                          _spokenText,
                          style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_assistantReply.isNotEmpty) ...[
                      const Text(
                        'Munim Ji Ka Jawab:',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF10B981)),
                        ),
                        child: Text(
                          _assistantReply,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF065F46)),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    const Text(
                      'Udaharan ke liye aise boleis (Examples):',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    ..._examplePrompts.map((example) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () {
                              setState(() => _spokenText = example);
                              _processVoiceInput(example);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.record_voice_over, size: 18, color: AppColors.primary),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '"$example"',
                                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                    ),
                                  ),
                                  const Icon(Icons.play_circle_outline, size: 18, color: AppColors.accent),
                                ],
                              ),
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
