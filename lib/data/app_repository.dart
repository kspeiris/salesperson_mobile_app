import 'dart:io';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../models/entities.dart';
import 'app_database.dart';

class AppRepository {
  AppRepository({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<Database> get _db async => _database.database;

  Future<void> initialize() async {
    final db = await _db;
    await _seedSettings(db);
  }

  Future<String> getDatabasePath() => _database.databasePath;
  Future<void> closeDatabase() => _database.close();
  Future<void> replaceDatabaseWithFilePath(String path) =>
      _database.replaceWith(File(path));

  Future<void> _seedSettings(Database db) async {
    final existing = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM settings')) ??
        0;
    if (existing > 0) return;

    final defaults = <String, String>{
      'company_name': 'Bio Care Sales',
      'default_salesperson': 'Route Salesperson',
      'payment_methods': 'Cash,Bank,Cheque',
      'pin_enabled': '0',
      'pin_hash': '',
      'profile_image_path': '',
    };
    final batch = db.batch();
    defaults.forEach((key, value) {
      batch.insert('settings', {'key': key, 'value': value});
    });
    await batch.commit(noResult: true);
  }

  Future<AppSettings> getSettings() async {
    final db = await _db;
    final rows = await db.query('settings');
    final map = <String, String>{};
    for (final row in rows) {
      map[row['key'] as String] = row['value'] as String? ?? '';
    }
    return AppSettings(
      companyName: map['company_name'] ?? 'Bio Care Consumers',
      defaultSalesperson: map['default_salesperson'] ?? 'Bio Care Route Team',
      paymentMethods: (map['payment_methods'] ?? 'Cash,Bank,Cheque')
          .split(',')
          .map((entry) => entry.trim())
          .where((entry) => entry.isNotEmpty)
          .toList(),
      pinEnabled: (map['pin_enabled'] ?? '0') == '1',
      pinHash: (map['pin_hash'] ?? '').isEmpty ? null : map['pin_hash'],
      profileImagePath: (map['profile_image_path'] ?? '').trim().isEmpty
          ? null
          : map['profile_image_path'],
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    final db = await _db;
    final payload = <String, String>{
      'company_name': settings.companyName,
      'default_salesperson': settings.defaultSalesperson,
      'payment_methods': settings.paymentMethods.join(','),
      'pin_enabled': settings.pinEnabled ? '1' : '0',
      'pin_hash': settings.pinHash ?? '',
      'profile_image_path': settings.profileImagePath ?? '',
    };

    final batch = db.batch();
    payload.forEach((key, value) {
      batch.insert(
        'settings',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
    await batch.commit(noResult: true);
  }

  Future<List<Shop>> getShops(
      {String query = '', bool activeOnly = true}) async {
    final db = await _db;
    final clauses = <String>[];
    final args = <Object?>[];

    if (activeOnly) clauses.add('is_active = 1');
    if (query.trim().isNotEmpty) {
      clauses.add('(name LIKE ? OR area LIKE ? OR owner_contact LIKE ?)');
      final pattern = '%${query.trim()}%';
      args
        ..add(pattern)
        ..add(pattern)
        ..add(pattern);
    }

    final rows = await db.query(
      'shops',
      where: clauses.isEmpty ? null : clauses.join(' AND '),
      whereArgs: args,
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return rows.map(Shop.fromMap).toList();
  }

  Future<void> saveShop(Shop shop) async {
    final db = await _db;
    final data = shop.toMap()..remove('id');
    final duplicate = await db.query(
      'shops',
      columns: ['id'],
      where: 'LOWER(name) = LOWER(?) AND id != ?',
      whereArgs: [shop.name.trim(), shop.id ?? -1],
      limit: 1,
    );
    if (duplicate.isNotEmpty) {
      throw StateError('A shop with this name already exists.');
    }
    if (shop.id == null) {
      await db.insert('shops', data);
    } else {
      await db.update('shops', data, where: 'id = ?', whereArgs: [shop.id]);
    }
  }

  Future<void> deactivateShop(int id) async {
    final db = await _db;
    await db.update(
      'shops',
      {
        'is_active': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Product>> getProducts(
      {String query = '', bool activeOnly = true}) async {
    final db = await _db;
    final clauses = <String>[];
    final args = <Object?>[];

    if (activeOnly) clauses.add('is_active = 1');
    if (query.trim().isNotEmpty) {
      clauses.add('(name LIKE ? OR sku LIKE ? OR barcode LIKE ?)');
      final pattern = '%${query.trim()}%';
      args
        ..add(pattern)
        ..add(pattern)
        ..add(pattern);
    }

    final rows = await db.query(
      'products',
      where: clauses.isEmpty ? null : clauses.join(' AND '),
      whereArgs: args,
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return rows.map(Product.fromMap).toList();
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final normalized = barcode.trim();
    if (normalized.isEmpty) return null;
    final db = await _db;
    final rows = await db.query(
      'products',
      where: 'barcode = ? AND is_active = 1',
      whereArgs: [normalized],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first);
  }

  Future<void> saveProduct(Product product) async {
    final db = await _db;
    final data = product.toMap()..remove('id');
    final duplicateSku = await db.query(
      'products',
      columns: ['id'],
      where: 'LOWER(sku) = LOWER(?) AND id != ?',
      whereArgs: [product.sku.trim(), product.id ?? -1],
      limit: 1,
    );
    if (duplicateSku.isNotEmpty) {
      throw StateError('A product with this SKU already exists.');
    }
    if (product.barcode.trim().isNotEmpty) {
      final duplicateBarcode = await db.query(
        'products',
        columns: ['id'],
        where: 'barcode = ? AND id != ?',
        whereArgs: [product.barcode.trim(), product.id ?? -1],
        limit: 1,
      );
      if (duplicateBarcode.isNotEmpty) {
        throw StateError('A product with this barcode already exists.');
      }
    }
    if (product.id == null) {
      await db.insert('products', data);
    } else {
      await db
          .update('products', data, where: 'id = ?', whereArgs: [product.id]);
    }
  }

  Future<void> deactivateProduct(int id) async {
    final db = await _db;
    await db.update(
      'products',
      {
        'is_active': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> createSale(SaleRecord sale) async {
    final db = await _db;
    await db.transaction((txn) async {
      final saleId = await txn.insert('sales', sale.toMap()..remove('id'));
      for (final item in sale.items) {
        await txn.insert(
            'sale_items', item.copyWith(saleId: saleId).toMap()..remove('id'));
      }
      if (sale.paymentType.toLowerCase() == 'credit') {
        await txn.rawUpdate(
          'UPDATE shops SET balance = balance + ?, updated_at = ? WHERE id = ?',
          [sale.total, DateTime.now().toIso8601String(), sale.shopId],
        );
      }
    });
  }

  Future<void> updateSale(SaleRecord sale) async {
    final db = await _db;
    if (sale.id == null) {
      throw ArgumentError('Sale id is required for updates.');
    }

    await db.transaction((txn) async {
      final existingRows = await txn.query(
        'sales',
        where: 'id = ?',
        whereArgs: [sale.id],
        limit: 1,
      );
      if (existingRows.isEmpty) {
        throw StateError('The selected sale could not be found.');
      }

      final existing = SaleRecord.fromMap(existingRows.first);
      if (existing.isVoided) {
        throw StateError('Voided sales cannot be edited.');
      }

      if (existing.paymentType.toLowerCase() == 'credit') {
        await txn.rawUpdate(
          'UPDATE shops SET balance = CASE WHEN balance - ? < 0 THEN 0 ELSE balance - ? END, updated_at = ? WHERE id = ?',
          [
            existing.total,
            existing.total,
            DateTime.now().toIso8601String(),
            existing.shopId,
          ],
        );
      }

      await txn.update(
        'sales',
        sale.toMap()..remove('id'),
        where: 'id = ?',
        whereArgs: [sale.id],
      );

      await txn.delete(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [sale.id],
      );

      for (final item in sale.items) {
        await txn.insert(
          'sale_items',
          item.copyWith(saleId: sale.id).toMap()..remove('id'),
        );
      }

      if (sale.paymentType.toLowerCase() == 'credit') {
        await txn.rawUpdate(
          'UPDATE shops SET balance = balance + ?, updated_at = ? WHERE id = ?',
          [sale.total, DateTime.now().toIso8601String(), sale.shopId],
        );
      }
    });
  }

  Future<List<SaleRecord>> getSales(
      {DateTime? start,
      DateTime? end,
      int? shopId,
      bool activeOnly = true}) async {
    final db = await _db;
    final clauses = <String>[];
    final args = <Object?>[];

    if (start != null) {
      clauses.add('created_at >= ?');
      args.add(start.toIso8601String());
    }
    if (end != null) {
      clauses.add('created_at < ?');
      args.add(end.toIso8601String());
    }
    if (shopId != null) {
      clauses.add('shop_id = ?');
      args.add(shopId);
    }
    if (activeOnly) {
      clauses.add('status = ?');
      args.add('active');
    }

    final rows = await db.query(
      'sales',
      where: clauses.isEmpty ? null : clauses.join(' AND '),
      whereArgs: args,
      orderBy: 'created_at DESC',
    );

    if (rows.isEmpty) {
      return const <SaleRecord>[];
    }

    final saleIds = rows
        .map((row) => row['id'])
        .whereType<int>()
        .toList(growable: false);
    final placeholders = List.filled(saleIds.length, '?').join(',');
    final itemsRows = await db.query(
      'sale_items',
      where: 'sale_id IN ($placeholders)',
      whereArgs: saleIds,
      orderBy: 'sale_id ASC, id ASC',
    );

    final itemsBySaleId = <int, List<SaleItem>>{};
    for (final itemRow in itemsRows) {
      final item = SaleItem.fromMap(itemRow);
      final saleId = item.saleId;
      if (saleId == null) continue;
      itemsBySaleId.putIfAbsent(saleId, () => <SaleItem>[]).add(item);
    }

    return rows
        .map(
          (row) => SaleRecord.fromMap(
            row,
            items: itemsBySaleId[row['id']] ?? const <SaleItem>[],
          ),
        )
        .toList(growable: false);
  }

  Future<void> voidSale(int id, String reason) async {
    final db = await _db;
    await db.transaction((txn) async {
      final rows =
          await txn.query('sales', where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isEmpty) return;
      final sale = SaleRecord.fromMap(rows.first);
      if (sale.isVoided) return;

      await txn.update('sales', {'status': 'voided', 'void_reason': reason},
          where: 'id = ?', whereArgs: [id]);

      if (sale.paymentType.toLowerCase() == 'credit') {
        await txn.rawUpdate(
          'UPDATE shops SET balance = balance - ?, updated_at = ? WHERE id = ?',
          [sale.total, DateTime.now().toIso8601String(), sale.shopId],
        );
      }
    });
  }

  Future<void> createCollection(CollectionRecord collection) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.insert('collections', collection.toMap()..remove('id'));
      await txn.rawUpdate(
        'UPDATE shops SET balance = CASE WHEN balance - ? < 0 THEN 0 ELSE balance - ? END, updated_at = ? WHERE id = ?',
        [
          collection.amount,
          collection.amount,
          DateTime.now().toIso8601String(),
          collection.shopId
        ],
      );
    });
  }

  Future<void> updateCollection(CollectionRecord collection) async {
    final db = await _db;
    if (collection.id == null) {
      throw ArgumentError('Collection id is required for updates.');
    }

    await db.transaction((txn) async {
      final existingRows = await txn.query(
        'collections',
        where: 'id = ?',
        whereArgs: [collection.id],
        limit: 1,
      );
      if (existingRows.isEmpty) {
        throw StateError('The selected collection could not be found.');
      }

      final existing = CollectionRecord.fromMap(existingRows.first);
      if (existing.isVoided) {
        throw StateError('Voided collections cannot be edited.');
      }

      await txn.rawUpdate(
        'UPDATE shops SET balance = balance + ?, updated_at = ? WHERE id = ?',
        [
          existing.amount,
          DateTime.now().toIso8601String(),
          existing.shopId,
        ],
      );

      await txn.update(
        'collections',
        collection.toMap()..remove('id'),
        where: 'id = ?',
        whereArgs: [collection.id],
      );

      await txn.rawUpdate(
        'UPDATE shops SET balance = CASE WHEN balance - ? < 0 THEN 0 ELSE balance - ? END, updated_at = ? WHERE id = ?',
        [
          collection.amount,
          collection.amount,
          DateTime.now().toIso8601String(),
          collection.shopId,
        ],
      );
    });
  }

  Future<List<CollectionRecord>> getCollections(
      {DateTime? start,
      DateTime? end,
      int? shopId,
      bool activeOnly = true}) async {
    final db = await _db;
    final clauses = <String>[];
    final args = <Object?>[];

    if (start != null) {
      clauses.add('created_at >= ?');
      args.add(start.toIso8601String());
    }
    if (end != null) {
      clauses.add('created_at < ?');
      args.add(end.toIso8601String());
    }
    if (shopId != null) {
      clauses.add('shop_id = ?');
      args.add(shopId);
    }
    if (activeOnly) {
      clauses.add('status = ?');
      args.add('active');
    }

    final rows = await db.query(
      'collections',
      where: clauses.isEmpty ? null : clauses.join(' AND '),
      whereArgs: args,
      orderBy: 'created_at DESC',
    );

    return rows.map(CollectionRecord.fromMap).toList();
  }

  Future<void> voidCollection(int id, String reason) async {
    final db = await _db;
    await db.transaction((txn) async {
      final rows = await txn.query('collections',
          where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isEmpty) return;
      final collection = CollectionRecord.fromMap(rows.first);
      if (collection.isVoided) return;

      await txn.update(
          'collections', {'status': 'voided', 'void_reason': reason},
          where: 'id = ?', whereArgs: [id]);
      await txn.rawUpdate(
        'UPDATE shops SET balance = balance + ?, updated_at = ? WHERE id = ?',
        [
          collection.amount,
          DateTime.now().toIso8601String(),
          collection.shopId
        ],
      );
    });
  }

  Future<DashboardSummary> getDashboardSummary(DateTime date) async {
    final db = await _db;
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final salesRows = await db.rawQuery('''
      SELECT
        COALESCE(SUM(total), 0) AS total_sales,
        COALESCE(SUM(CASE WHEN LOWER(payment_type) = 'cash' THEN total ELSE 0 END), 0) AS cash_sales,
        COALESCE(SUM(CASE WHEN LOWER(payment_type) = 'credit' THEN total ELSE 0 END), 0) AS credit_sales,
        COUNT(*) AS sales_count
      FROM sales
      WHERE status = 'active' AND created_at >= ? AND created_at < ?
    ''', [start.toIso8601String(), end.toIso8601String()]);

    final collectionRows = await db.rawQuery('''
      SELECT
        COALESCE(SUM(amount), 0) AS total_collections,
        COUNT(*) AS collection_count
      FROM collections
      WHERE status = 'active' AND created_at >= ? AND created_at < ?
    ''', [start.toIso8601String(), end.toIso8601String()]);

    final sales = salesRows.first;
    final collections = collectionRows.first;
    return DashboardSummary(
      totalSales: ((sales['total_sales'] as num?) ?? 0).toDouble(),
      cashSales: ((sales['cash_sales'] as num?) ?? 0).toDouble(),
      creditSales: ((sales['credit_sales'] as num?) ?? 0).toDouble(),
      totalCollections:
          ((collections['total_collections'] as num?) ?? 0).toDouble(),
      salesCount: (sales['sales_count'] as int?) ?? 0,
      collectionCount: (collections['collection_count'] as int?) ?? 0,
    );
  }

  Future<DailyReportData> getDailyReportData(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final dashboard = await getDashboardSummary(date);
    final sales = await getSales(start: start, end: end, activeOnly: true);
    final collections =
        await getCollections(start: start, end: end, activeOnly: true);
    return DailyReportData(
        date: date,
        dashboard: dashboard,
        sales: sales,
        collections: collections);
  }

  Future<Map<String, Object?>> getDailyExportMap(DateTime date) async {
    final report = await getDailyReportData(date);
    return {
      'date': report.date.toIso8601String(),
      'summary': {
        'totalSales': report.dashboard.totalSales,
        'cashSales': report.dashboard.cashSales,
        'creditSales': report.dashboard.creditSales,
        'totalCollections': report.dashboard.totalCollections,
        'salesCount': report.dashboard.salesCount,
        'collectionCount': report.dashboard.collectionCount,
      },
      'sales': report.sales
          .map((sale) => {
                ...sale.toMap(),
                'items': sale.items.map((item) => item.toMap()).toList(),
              })
          .toList(),
      'collections': report.collections.map((entry) => entry.toMap()).toList(),
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }

  Future<ImportResult> importShopsFromText(String rawText,
      {bool replaceExisting = false}) async {
    final rows = _parseDelimitedText(rawText);
    if (rows.isEmpty) {
      return const ImportResult(
          importedCount: 0,
          updatedCount: 0,
          skippedCount: 0,
          errors: ['No valid rows found.']);
    }

    final db = await _db;
    int imported = 0;
    int updated = 0;
    int skipped = 0;
    final errors = <String>[];

    await db.transaction((txn) async {
      if (replaceExisting) {
        await txn.delete('shops');
      }

      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        final name = row['name']?.trim() ?? '';
        final ownerContact = row['owner_contact']?.trim().isNotEmpty == true
            ? row['owner_contact']!.trim()
            : (row['owner']?.trim() ?? '');
        final area = row['area']?.trim() ?? '';
        final phone = row['phone']?.trim() ?? '';

        if (name.isEmpty || area.isEmpty || phone.isEmpty) {
          skipped++;
          errors.add('Row ${i + 2}: name, area, and phone are required.');
          continue;
        }

        final existing = await txn.query('shops',
            where: 'LOWER(name) = LOWER(?)', whereArgs: [name], limit: 1);
        final now = DateTime.now().toIso8601String();
        final payload = {
          'name': name,
          'owner_contact': ownerContact,
          'area': area,
          'phone': phone,
          'credit_limit': double.tryParse(row['credit_limit'] ?? '') ?? 0,
          'balance': double.tryParse(row['balance'] ?? '') ?? 0,
          'is_active': 1,
          'created_at': existing.isEmpty
              ? now
              : (existing.first['created_at'] as String? ?? now),
          'updated_at': now,
        };

        if (existing.isEmpty) {
          await txn.insert('shops', payload);
          imported++;
        } else {
          await txn.update('shops', payload,
              where: 'id = ?', whereArgs: [existing.first['id']]);
          updated++;
        }
      }
    });

    return ImportResult(
        importedCount: imported,
        updatedCount: updated,
        skippedCount: skipped,
        errors: errors);
  }

  Future<ImportResult> importProductsFromText(String rawText,
      {bool replaceExisting = false}) async {
    final rows = _parseDelimitedText(rawText);
    if (rows.isEmpty) {
      return const ImportResult(
          importedCount: 0,
          updatedCount: 0,
          skippedCount: 0,
          errors: ['No valid rows found.']);
    }

    final db = await _db;
    int imported = 0;
    int updated = 0;
    int skipped = 0;
    final errors = <String>[];

    await db.transaction((txn) async {
      if (replaceExisting) {
        await txn.delete('products');
      }

      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        final name = row['name']?.trim() ?? '';
        final sku = row['sku']?.trim() ?? '';
        final unitPrice = double.tryParse(row['unit_price'] ?? '');

        if (name.isEmpty ||
            sku.isEmpty ||
            unitPrice == null ||
            unitPrice <= 0) {
          skipped++;
          errors.add(
              'Row ${i + 2}: name, sku, and a positive unit_price are required.');
          continue;
        }

        final existing = await txn.query('products',
            where: 'LOWER(sku) = LOWER(?)', whereArgs: [sku], limit: 1);
        final now = DateTime.now().toIso8601String();
        final payload = {
          'name': name,
          'sku': sku,
          'unit_price': unitPrice,
          'description': row['description']?.trim() ?? '',
          'barcode': row['barcode']?.trim() ?? '',
          'is_active': 1,
          'created_at': existing.isEmpty
              ? now
              : (existing.first['created_at'] as String? ?? now),
          'updated_at': now,
        };

        if (existing.isEmpty) {
          await txn.insert('products', payload);
          imported++;
        } else {
          await txn.update('products', payload,
              where: 'id = ?', whereArgs: [existing.first['id']]);
          updated++;
        }
      }
    });

    return ImportResult(
        importedCount: imported,
        updatedCount: updated,
        skippedCount: skipped,
        errors: errors);
  }

  List<Map<String, String>> _parseDelimitedText(String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) return [];

    final lines = const LineSplitter()
        .convert(normalized)
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return [];

    final delimiter = lines.first.contains('\t') ? '\t' : ',';
    final headers =
        _splitCsvLine(lines.first, delimiter).map(_normalizeHeader).toList();
    final rows = <Map<String, String>>[];

    for (final line in lines.skip(1)) {
      final values = _splitCsvLine(line, delimiter);
      if (values.every((value) => value.trim().isEmpty)) continue;
      final row = <String, String>{};
      for (var i = 0; i < headers.length; i++) {
        row[headers[i]] = i < values.length ? values[i].trim() : '';
      }
      rows.add(row);
    }
    return rows;
  }

  List<String> _splitCsvLine(String line, String delimiter) {
    final cells = <String>[];
    var buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        final isEscapedQuote =
            inQuotes && i + 1 < line.length && line[i + 1] == '"';
        if (isEscapedQuote) {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
        continue;
      }

      if (!inQuotes && char == delimiter) {
        cells.add(buffer.toString());
        buffer = StringBuffer();
      } else {
        buffer.write(char);
      }
    }
    cells.add(buffer.toString());
    return cells;
  }

  String _normalizeHeader(String value) {
    return value.trim().toLowerCase().replaceAll(' ', '_');
  }
}
