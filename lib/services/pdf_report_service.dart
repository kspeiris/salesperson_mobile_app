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
          margin: const pw.EdgeInsets.all(28),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
        ),
        build: (context) => [
          _buildHeader(companyName, salespersonName, report.date),
          pw.SizedBox(height: 18),
          _buildSummary(report.dashboard),
          pw.SizedBox(height: 18),
          _buildSalesTable(report.sales),
          pw.SizedBox(height: 18),
          _buildCollectionsTable(report.collections),
          pw.SizedBox(height: 32),
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
    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F1F5F9'),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(companyName, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text('Daily Sales & Collections Report', style: const pw.TextStyle(fontSize: 13)),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Salesperson: $salespersonName'),
              pw.Text('Report Date: ${AppFormatters.date(date)}'),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummary(DashboardSummary summary) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Summary', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            _summaryRow('Cash Sales', AppFormatters.currency(summary.cashSales)),
            _summaryRow('Credit Sales', AppFormatters.currency(summary.creditSales)),
            _summaryRow('Total Sales', AppFormatters.currency(summary.totalSales)),
            _summaryRow('Collections', AppFormatters.currency(summary.totalCollections)),
            _summaryRow('Sales Transactions', '${summary.salesCount}'),
            _summaryRow('Collection Transactions', '${summary.collectionCount}'),
          ],
        ),
      ],
    );
  }

  pw.TableRow _summaryRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(label)),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text(value)),
        ),
      ],
    );
  }

  pw.Widget _buildSalesTable(List<SaleRecord> sales) {
    if (sales.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Sales Transactions', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
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
        pw.Text('Sales Transactions', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: const ['Time', 'Shop', 'Payment', 'Total'],
          data: rows,
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
          cellAlignment: pw.Alignment.centerLeft,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellPadding: const pw.EdgeInsets.all(6),
        ),
      ],
    );
  }

  pw.Widget _buildCollectionsTable(List<CollectionRecord> collections) {
    if (collections.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Collections', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
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
        pw.Text('Collections', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: const ['Time', 'Shop', 'Method', 'Amount'],
          data: rows,
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellPadding: const pw.EdgeInsets.all(6),
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
      width: 220,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Divider(color: PdfColors.grey500),
          pw.Text(label),
        ],
      ),
    );
  }
}
