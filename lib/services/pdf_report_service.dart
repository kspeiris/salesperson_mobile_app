import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/utils/formatters.dart';
import '../models/entities.dart';

class PdfReportService {
  Future<File> generateDailyReport({
    required DailyReportData report,
    required String companyName,
    required String salespersonName,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
        ),
        build: (context) => [
          _buildHeader(companyName, salespersonName, report.date),
          pw.SizedBox(height: 24),
          _buildSummary(report.dashboard),
          pw.SizedBox(height: 24),
          _buildSalesTable(report.sales),
          pw.SizedBox(height: 24),
          _buildCollectionsTable(report.collections),
          pw.SizedBox(height: 48),
          _buildSignatureArea(),
        ],
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final reportsDir = Directory(p.join(directory.path, 'reports'));
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }
    final filename = 'daily_report_${AppFormatters.fileDate(report.date)}.pdf';
    final file = File(p.join(reportsDir.path, filename));
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _buildHeader(String companyName, String salespersonName, DateTime date) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(companyName, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#2E7D32'))),
        pw.SizedBox(height: 2),
        pw.Text('Panadura, Sri Lanka', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
        pw.SizedBox(height: 12),
        pw.Container(height: 2, color: PdfColor.fromHex('#2E7D32')),
        pw.SizedBox(height: 16),
        pw.Text('Daily Sales Report', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            pw.Expanded(child: pw.Text('Date: ${AppFormatters.date(date)}')),
            pw.Expanded(child: pw.Text('Salesperson: $salespersonName')),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildSummary(DashboardSummary summary) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Summary', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#2E7D32'))),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColor.fromHex('#E8F5E9')),
          ),
          child: pw.Column(
            children: [
              _summaryRow('Cash Sales', AppFormatters.currency(summary.cashSales)),
              _summaryRow('Credit Sales', AppFormatters.currency(summary.creditSales)),
              _summaryRow('Total Sales', AppFormatters.currency(summary.totalSales)),
              _summaryRow('Collections', AppFormatters.currency(summary.totalCollections)),
              _summaryRow('Sales Transactions', '${summary.salesCount}'),
              _summaryRow('Collection Transactions', '${summary.collectionCount}'),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _summaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _buildSalesTable(List<SaleRecord> sales) {
    if (sales.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Sales Transactions', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#2E7D32'))),
          pw.SizedBox(height: 8),
          pw.Text('No sales recorded for the selected date.'),
        ],
      );
    }

    final rows = sales
        .map(
          (sale) => [
            AppFormatters.time(sale.createdAt),
            sale.shopName,
            sale.paymentType,
            AppFormatters.currency(sale.total),
          ],
        )
        .toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Sales Transactions', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#2E7D32'))),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: const ['Time', 'Shop', 'Payment', 'Total'],
          data: rows,
          headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#F8FDF8')),
          cellAlignment: pw.Alignment.centerLeft,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#2E7D32')),
          cellPadding: const pw.EdgeInsets.all(6),
          border: pw.TableBorder.all(color: PdfColor.fromHex('#E8F5E9')),
        ),
      ],
    );
  }

  pw.Widget _buildCollectionsTable(List<CollectionRecord> collections) {
    if (collections.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Collections', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#2E7D32'))),
          pw.SizedBox(height: 8),
          pw.Text('No collections recorded for the selected date.'),
        ],
      );
    }

    final rows = collections
        .map(
          (collection) => [
            AppFormatters.time(collection.createdAt),
            collection.shopName,
            collection.paymentMethod,
            AppFormatters.currency(collection.amount),
          ],
        )
        .toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Collections', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#2E7D32'))),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: const ['Time', 'Shop', 'Method', 'Amount'],
          data: rows,
          headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#F8FDF8')),
          cellAlignment: pw.Alignment.centerLeft,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#2E7D32')),
          cellPadding: const pw.EdgeInsets.all(6),
          border: pw.TableBorder.all(color: PdfColor.fromHex('#E8F5E9')),
        ),
      ],
    );
  }

  pw.Widget _buildSignatureArea() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _signature('Salesperson Signature'),
        _signature('Supervisor Signature'),
      ],
    );
  }

  pw.Widget _signature(String label) {
    return pw.SizedBox(
      width: 200,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 4),
          pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey700)),
        ],
      ),
    );
  }
}
