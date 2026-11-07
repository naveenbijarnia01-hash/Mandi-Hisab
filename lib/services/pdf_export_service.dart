import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/stock_item_model.dart';
import '../models/transaction_model.dart';

class PdfExportService {
  static Future<Uint8List> generateStockReportPdf({
    required String shopName,
    required String mandiName,
    required List<StockItemModel> stocks,
    required List<TransactionModel> transactions,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'MANDI HISAB - STOCK REPORT',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#1B4D3E'),
                        ),
                      ),
                      pw.Text('$shopName ($mandiName)'),
                      pw.Text('Report Date: ${dateFormat.format(DateTime.now())}'),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Stock Table
            pw.Text(
              'Live Stock Summary',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              headers: ['Fasal (Crop)', 'Opening', 'Total Aaya', 'Total Gaya', 'Available Stock', 'Unit'],
              data: stocks.map((s) => [
                s.cropName,
                s.openingStock.toStringAsFixed(1),
                s.totalIncoming.toStringAsFixed(1),
                s.totalOutgoing.toStringAsFixed(1),
                s.currentStock.toStringAsFixed(1),
                s.unit.label,
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromHex('#1B4D3E')),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            pw.SizedBox(height: 24),

            // Recent Transactions Table
            pw.Text(
              'Recent Transactions',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              headers: ['Tarikh', 'Type', 'Fasal', 'Qty', 'Party', 'Gaadi No'],
              data: transactions.take(15).map((t) => [
                DateFormat('dd/MM/yyyy').format(t.createdAt),
                t.type.label,
                t.cropName,
                '${t.quantity} ${t.unit.label}',
                t.partyName,
                t.vehicleNumber,
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromHex('#1B4D3E')),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> printOrSharePdf({
    required String shopName,
    required String mandiName,
    required List<StockItemModel> stocks,
    required List<TransactionModel> transactions,
  }) async {
    final pdfBytes = await generateStockReportPdf(
      shopName: shopName,
      mandiName: mandiName,
      stocks: stocks,
      transactions: transactions,
    );
    await Printing.sharePdf(bytes: pdfBytes, filename: 'MandiHisab_${DateTime.now().millisecondsSinceEpoch}.pdf');
  }
}
