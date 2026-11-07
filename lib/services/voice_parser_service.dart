import '../models/stock_item_model.dart';
import '../models/transaction_model.dart';

class ParsedVoiceTransaction {
  final TransactionType type;
  final String cropName;
  final double quantity;
  final CropUnit unit;
  final String partyName;
  final String vehicleNumber;
  final String fromLocation;
  final String toLocation;
  final String rawText;

  ParsedVoiceTransaction({
    required this.type,
    required this.cropName,
    required this.quantity,
    required this.unit,
    required this.partyName,
    required this.vehicleNumber,
    required this.fromLocation,
    required this.toLocation,
    required this.rawText,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'cropName': cropName,
        'quantity': quantity,
        'unit': unit.name,
        'partyName': partyName,
        'vehicleNumber': vehicleNumber,
        'fromLocation': fromLocation,
        'toLocation': toLocation,
        'rawText': rawText,
      };
}

class VoiceParserService {
  // Robust Rule-Based & Keyword NLP Parser for Hindi / Hinglish Mandi Speech
  static ParsedVoiceTransaction parseCommand(String text) {
    final lower = text.toLowerCase();

    // 1. Detect Transaction Type
    TransactionType type = TransactionType.incoming;
    if (lower.contains('gaye') ||
        lower.contains('bheja') ||
        lower.contains('nikla') ||
        lower.contains('sell') ||
        lower.contains('out') ||
        lower.contains('ja raha')) {
      type = TransactionType.outgoing;
    } else if (lower.contains('aayi') ||
        lower.contains('aaya') ||
        lower.contains('mili') ||
        lower.contains('purchase') ||
        lower.contains('in')) {
      type = TransactionType.incoming;
    }

    // 2. Detect Crop Name
    String cropName = 'Gehun';
    if (lower.contains('sarson') || lower.contains('mustard')) {
      cropName = 'Sarson';
    } else if (lower.contains('bajra')) {
      cropName = 'Bajra';
    } else if (lower.contains('chana') || lower.contains('gram')) {
      cropName = 'Chana';
    } else if (lower.contains('jau') || lower.contains('barley')) {
      cropName = 'Jau';
    } else if (lower.contains('makka') || lower.contains('maize')) {
      cropName = 'Makka';
    } else if (lower.contains('dhan') || lower.contains('rice') || lower.contains('paddy')) {
      cropName = 'Dhan';
    } else if (lower.contains('soybean')) {
      cropName = 'Soybean';
    } else if (lower.contains('gehun') || lower.contains('wheat')) {
      cropName = 'Gehun';
    }

    // 3. Detect Quantity & Unit
    double quantity = 50.0;
    CropUnit unit = CropUnit.quintal;

    final regexNum = RegExp(r'(\d+(?:\.\d+)?)');
    final matchNum = regexNum.firstMatch(text);
    if (matchNum != null) {
      quantity = double.tryParse(matchNum.group(1) ?? '50') ?? 50.0;
    }

    if (lower.contains('kg') || lower.contains('kilogram')) {
      unit = CropUnit.kilogram;
    } else if (lower.contains('ton') || lower.contains('tonne')) {
      unit = CropUnit.ton;
    } else {
      unit = CropUnit.quintal;
    }

    // 4. Detect Vehicle Number (e.g. RJ14U0010 or RJ 14 AB 1234)
    String vehicleNumber = 'RJ14U0010';
    final vehicleRegex = RegExp(r'([a-z]{2}\s?\d{1,2}\s?[a-z]{1,2}\s?\d{4})', caseSensitive: false);
    final matchVehicle = vehicleRegex.firstMatch(text);
    if (matchVehicle != null) {
      vehicleNumber = matchVehicle.group(1)!.toUpperCase().replaceAll(' ', '');
    }

    // 5. Detect Party Name (e.g. "Suresh ji se", "Sungna Factory")
    String partyName = 'Local Party';
    if (lower.contains(' se ')) {
      final parts = text.split(RegExp(r'\s+se\s+', caseSensitive: false));
      if (parts.isNotEmpty) {
        final subParts = parts[0].split(' ');
        if (subParts.length >= 2) {
          partyName = '${subParts[subParts.length - 2]} ${subParts[subParts.length - 1]}';
        } else {
          partyName = subParts.last;
        }
      }
    } else if (lower.contains(' mein ') || lower.contains(' ko ')) {
      final parts = text.split(RegExp(r'\s+(mein|ko)\s+', caseSensitive: false));
      if (parts.isNotEmpty) {
        final subParts = parts[0].split(' ');
        if (subParts.length >= 2) {
          partyName = '${subParts[subParts.length - 2]} ${subParts[subParts.length - 1]}';
        }
      }
    }

    // 6. Locations
    String fromLocation = type == TransactionType.incoming ? partyName : 'Mandi Dukaan';
    String toLocation = type == TransactionType.outgoing ? partyName : 'Mandi Dukaan';

    return ParsedVoiceTransaction(
      type: type,
      cropName: cropName,
      quantity: quantity,
      unit: unit,
      partyName: partyName.trim(),
      vehicleNumber: vehicleNumber,
      fromLocation: fromLocation,
      toLocation: toLocation,
      rawText: text,
    );
  }
}
