import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/utils/formatters.dart';
import '../models/entities.dart';

class ExportService {
  Future<ExportBundle> exportDailyData({
    required DateTime date,
    required Map<String, Object?> exportMap,
    required String companyName,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(directory.path, 'exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final baseName = 'desktop_import_${AppFormatters.fileDate(date)}';
    final csvPath = p.join(exportDir.path, '$baseName.csv');
    final jsonPath = p.join(exportDir.path, '$baseName.json');

    await File(csvPath).writeAsString(_buildCsv(exportMap, companyName));
    await File(jsonPath).writeAsString(const JsonEncoder.withIndent('  ').convert(exportMap));

    return ExportBundle(csvFile: csvPath, jsonFile: jsonPath);
  }

  Future<String?> saveCopyToUserLocation(String sourcePath) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException('Export file not found.', sourcePath);
    }
    final selected = await FilePicker.platform.saveFile(
      dialogTitle: 'Save exported file',
      fileName: p.basename(sourcePath),
    );
    if (selected == null) return null;
    if (p.equals(selected, sourcePath)) return selected;
    final targetFile = File(selected);
    if (await targetFile.exists()) {
      await targetFile.delete();
    }
    await sourceFile.copy(selected);
    return selected;
  }

  String _buildCsv(Map<String, Object?> exportMap, String companyName) {
    final buffer = StringBuffer();
    final date = exportMap['date']?.toString() ?? '';
    final summary = exportMap['summary'] as Map<String, Object?>? ?? const {};
    final sales = (exportMap['sales'] as List?)?.cast<Map>() ?? const [];
    final collections = (exportMap['collections'] as List?)?.cast<Map>() ?? const [];

    buffer.writeln('section,company,date,key,value');
    _writeCsvRow(buffer, ['summary', companyName, date, 'total_sales', '${summary['totalSales'] ?? 0}']);
    _writeCsvRow(buffer, ['summary', companyName, date, 'cash_sales', '${summary['cashSales'] ?? 0}']);
    _writeCsvRow(buffer, ['summary', companyName, date, 'credit_sales', '${summary['creditSales'] ?? 0}']);
    _writeCsvRow(buffer, ['summary', companyName, date, 'total_collections', '${summary['totalCollections'] ?? 0}']);
    _writeCsvRow(buffer, ['summary', companyName, date, 'sales_count', '${summary['salesCount'] ?? 0}']);
    _writeCsvRow(buffer, ['summary', companyName, date, 'collection_count', '${summary['collectionCount'] ?? 0}']);

    buffer.writeln();
    buffer.writeln('sales_id,created_at,shop_name,payment_type,subtotal,discount,total,note,item_count');
    for (final sale in sales) {
      final items = (sale['items'] as List?) ?? const [];
      _writeCsvRow(buffer, [
        '${sale['id'] ?? ''}',
        '${sale['created_at'] ?? ''}',
        '${sale['shop_name'] ?? ''}',
        '${sale['payment_type'] ?? ''}',
        '${sale['subtotal'] ?? 0}',
        '${sale['discount'] ?? 0}',
        '${sale['total'] ?? 0}',
        '${sale['note'] ?? ''}',
        '${items.length}',
      ]);
    }

    buffer.writeln();
    buffer.writeln('sales_id,product_id,product_name,quantity,unit_price,line_total');
    for (final sale in sales) {
      final items = (sale['items'] as List?)?.cast<Map>() ?? const [];
      for (final item in items) {
        _writeCsvRow(buffer, [
          '${sale['id'] ?? ''}',
          '${item['product_id'] ?? ''}',
          '${item['product_name'] ?? ''}',
          '${item['quantity'] ?? 0}',
          '${item['unit_price'] ?? 0}',
          '${item['line_total'] ?? 0}',
        ]);
      }
    }

    buffer.writeln();
    buffer.writeln('collection_id,created_at,shop_name,payment_method,amount,reference_note');
    for (final entry in collections) {
      _writeCsvRow(buffer, [
        '${entry['id'] ?? ''}',
        '${entry['created_at'] ?? ''}',
        '${entry['shop_name'] ?? ''}',
        '${entry['payment_method'] ?? ''}',
        '${entry['amount'] ?? 0}',
        '${entry['reference_note'] ?? ''}',
      ]);
    }

    return buffer.toString();
  }

  void _writeCsvRow(StringBuffer buffer, List<String> values) {
    final escaped = values.map((value) {
      final safe = value.replaceAll('"', '""');
      if (safe.contains(',') || safe.contains('"') || safe.contains('\n')) {
        return '"$safe"';
      }
      return safe;
    }).join(',');
    buffer.writeln(escaped);
  }
}
