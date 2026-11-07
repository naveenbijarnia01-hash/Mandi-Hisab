import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/stock_item_model.dart';
import '../models/transaction_model.dart';
import '../models/vehicle_model.dart';

class VoiceAssistantService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isInitialized = false;

  Future<bool> initSpeech() async {
    if (!_isInitialized) {
      _isInitialized = await _speech.initialize(
        onError: (val) => print('Speech Error: $val'),
        onStatus: (val) => print('Speech Status: $val'),
      );
      await _tts.setLanguage("hi-IN");
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.9);
    }
    return _isInitialized;
  }

  Future<void> listen({
    required Function(String text) onResult,
    required Function() onDone,
  }) async {
    final available = await initSpeech();
    if (available) {
      _speech.listen(
        onResult: (val) {
          onResult(val.recognizedWords);
        },
        localeId: 'hi_IN',
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 3),
      );
    }
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  // Answer Voice Query from live database records
  String answerQuery({
    required String query,
    required List<StockItemModel> stocks,
    required List<TransactionModel> transactions,
    required List<VehicleModel> vehicles,
  }) {
    final lower = query.toLowerCase();

    // Query 1: Stock balance
    if (lower.contains('bacha hai') || lower.contains('kitna stock') || lower.contains('balance')) {
      for (final s in stocks) {
        if (lower.contains(s.cropName.toLowerCase())) {
          return "Aapke paas ${s.cropName} ka abhi ${s.currentStock} ${s.unit.label} stock bacha hua hai.";
        }
      }
      final summary = stocks.map((e) => "${e.cropName}: ${e.currentStock} ${e.unit.label}").join(", ");
      return "Dukaan ka kul stock hai: $summary";
    }

    // Query 2: Aaj ka maal aaya / nikla
    if (lower.contains('aaj kitna maal nikla') || lower.contains('outgoing')) {
      final todayOut = transactions
          .where((t) =>
              t.type == TransactionType.outgoing &&
              t.createdAt.day == DateTime.now().day)
          .fold<double>(0.0, (sum, item) => sum + item.quantity);
      return "Aaj kul $todayOut quintal maal dispatch kiya gaya hai.";
    }

    if (lower.contains('kitna sarson aaya') || lower.contains('incoming')) {
      final todayIn = transactions
          .where((t) =>
              t.type == TransactionType.incoming &&
              t.createdAt.day == DateTime.now().day)
          .fold<double>(0.0, (sum, item) => sum + item.quantity);
      return "Aaj kul $todayIn quintal maal mandi mein prapt hua hai.";
    }

    // Query 3: Vehicle movement query
    if (lower.contains('gaadi') || lower.contains('vehicle')) {
      for (final v in vehicles) {
        final cleanNum = v.vehicleNumber.toLowerCase().replaceAll(' ', '');
        if (lower.replaceAll(' ', '').contains(cleanNum)) {
          return "Gaadi number ${v.vehicleNumber} ${v.sourceLocation} se ${v.arrivalTime.hour}:${v.arrivalTime.minute.toString().padLeft(2, '0')} par aayi thi. Status: ${v.status.label}.";
        }
      }
      return "Aaj total ${vehicles.length} gaadiyon ki entry register mein darz hai.";
    }

    // Query 4: Full Hisab Summary
    if (lower.contains('poora hisaab') || lower.contains('aaj ka hisaab')) {
      final totalIn = transactions
          .where((t) => t.type == TransactionType.incoming)
          .fold<double>(0.0, (sum, item) => sum + item.quantity);
      final totalOut = transactions
          .where((t) => t.type == TransactionType.outgoing)
          .fold<double>(0.0, (sum, item) => sum + item.quantity);

      return "Aaj ka hisaab: Total incoming $totalIn quintal, total outgoing $totalOut quintal, aur ${vehicles.length} gaadi movement record hui hai.";
    }

    return "Aapka sawal samajh aaya. Dukaan ka hisaab update hai.";
  }
}
