import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/app_repository.dart';
import '../models/entities.dart';
import '../services/backup_service.dart';
import '../services/export_service.dart';
import '../services/pdf_report_service.dart';

class AppController extends ChangeNotifier {
  AppController({
    AppRepository? repository,
    PdfReportService? pdfReportService,
    ExportService? exportService,
    BackupService? backupService,
  })  : _repository = repository ?? AppRepository(),
        _pdfReportService = pdfReportService ?? PdfReportService(),
        _exportService = exportService ?? ExportService(),
        _backupService = backupService ?? BackupService();

  final AppRepository _repository;
  final PdfReportService _pdfReportService;
  final ExportService _exportService;
  final BackupService _backupService;

  bool _initialized = false;
  bool _authenticated = false;
  String _currentSalesperson = 'Salesperson';
  AppSettings _settings = const AppSettings(
    companyName: 'Bio Care Consumers',
    defaultSalesperson: 'Bio Care Route Team',
    paymentMethods: ['Cash', 'Bank', 'Cheque'],
    pinEnabled: false,
  );
  File? _lastGeneratedReport;
  ExportBundle? _lastExportBundle;
  String? _lastBackupPath;
  int _currentTab = 0;

  bool get initialized => _initialized;
  bool get authenticated => _authenticated;
  String get currentSalesperson => _currentSalesperson;
  AppSettings get settings => _settings;
  String? get profileImagePath => _settings.profileImagePath;
  File? get lastGeneratedReport => _lastGeneratedReport;
  ExportBundle? get lastExportBundle => _lastExportBundle;
  String? get lastBackupPath => _lastBackupPath;
  int get currentTab => _currentTab;

  set currentTab(int index) {
    _currentTab = index;
    notifyListeners();
  }

  Future<void> initialize() async {
    await _repository.initialize();
    _settings = await _repository.getSettings();
    final seededImagePath = p.join(Directory.current.path, 'My Image.jpeg');
    if ((_settings.profileImagePath ?? '').trim().isEmpty &&
        await File(seededImagePath).exists()) {
      _settings = _settings.copyWith(profileImagePath: seededImagePath);
      await _repository.saveSettings(_settings);
    }
    _currentSalesperson = _settings.defaultSalesperson;
    _initialized = true;
    notifyListeners();
  }

  String? login({required String salesperson, String pin = ''}) {
    if (_settings.pinEnabled && (_settings.pinHash?.isNotEmpty ?? false)) {
      final hash = sha256.convert(utf8.encode(pin.trim())).toString();
      if (hash != _settings.pinHash) {
        return 'Incorrect PIN. Please try again.';
      }
    }
    _currentSalesperson = salesperson.trim().isEmpty
        ? _settings.defaultSalesperson
        : salesperson.trim();
    _authenticated = true;
    notifyListeners();
    return null;
  }

  void logout() {
    _authenticated = false;
    notifyListeners();
  }

  Future<DashboardSummary> dashboardFor(DateTime date) =>
      _repository.getDashboardSummary(date);
  Future<List<Shop>> fetchShops({String query = ''}) =>
      _repository.getShops(query: query);
  Future<List<Product>> fetchProducts({String query = ''}) =>
      _repository.getProducts(query: query);
  Future<Product?> findProductByBarcode(String barcode) =>
      _repository.getProductByBarcode(barcode);
  Future<List<SaleRecord>> fetchSales(
          {DateTime? start, DateTime? end, int? shopId, bool activeOnly = true}) =>
      _repository.getSales(
          start: start, end: end, shopId: shopId, activeOnly: activeOnly);
  Future<List<CollectionRecord>> fetchCollections(
          {DateTime? start,
          DateTime? end,
          int? shopId,
          bool activeOnly = true}) =>
      _repository.getCollections(
          start: start, end: end, shopId: shopId, activeOnly: activeOnly);

  Future<void> saveShop(Shop shop) async {
    _validateShop(shop);
    await _repository.saveShop(shop);
    notifyListeners();
  }

  Future<void> deactivateShop(int id) async {
    await _repository.deactivateShop(id);
    notifyListeners();
  }

  Future<void> saveProduct(Product product) async {
    _validateProduct(product);
    await _repository.saveProduct(product);
    notifyListeners();
  }

  Future<void> deactivateProduct(int id) async {
    await _repository.deactivateProduct(id);
    notifyListeners();
  }

  Future<void> createSale(SaleRecord sale) async {
    _validateSale(sale);
    await _repository.createSale(sale);
    notifyListeners();
  }

  Future<void> updateSale(SaleRecord sale) async {
    _validateSale(sale);
    await _repository.updateSale(sale);
    notifyListeners();
  }

  Future<void> voidSale(int id, String reason) async {
    await _repository.voidSale(id, reason);
    notifyListeners();
  }

  Future<void> createCollection(CollectionRecord collection) async {
    _validateCollection(collection);
    await _repository.createCollection(collection);
    notifyListeners();
  }

  Future<void> updateCollection(CollectionRecord collection) async {
    _validateCollection(collection);
    await _repository.updateCollection(collection);
    notifyListeners();
  }

  Future<void> voidCollection(int id, String reason) async {
    await _repository.voidCollection(id, reason);
    notifyListeners();
  }

  Future<void> saveSettings({
    required String companyName,
    required String defaultSalesperson,
    required List<String> paymentMethods,
    required bool pinEnabled,
    String? rawPin,
    String? profileImagePath,
  }) async {
    final trimmedCompany = companyName.trim();
    final trimmedSalesperson = defaultSalesperson.trim();
    final normalizedMethods = paymentMethods
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toSet()
        .toList();
    final normalizedPin = rawPin?.trim() ?? '';
    if (trimmedCompany.isEmpty) {
      throw ArgumentError('Company name is required.');
    }
    if (trimmedSalesperson.isEmpty) {
      throw ArgumentError('Default salesperson is required.');
    }
    if (normalizedMethods.isEmpty) {
      throw ArgumentError('At least one payment method is required.');
    }
    if (pinEnabled &&
        normalizedPin.isEmpty &&
        (_settings.pinHash == null || _settings.pinHash!.isEmpty)) {
      throw ArgumentError('Set a PIN before enabling device protection.');
    }
    if (normalizedPin.isNotEmpty && normalizedPin.length < 4) {
      throw ArgumentError('PIN must be at least 4 digits.');
    }
    final pinHash = normalizedPin.isEmpty
        ? _settings.pinHash
        : sha256.convert(utf8.encode(normalizedPin)).toString();

    _settings = _settings.copyWith(
      companyName: trimmedCompany,
      defaultSalesperson: trimmedSalesperson,
      paymentMethods: normalizedMethods,
      pinEnabled: pinEnabled,
      pinHash: pinEnabled ? pinHash : '',
      profileImagePath: profileImagePath ?? _settings.profileImagePath,
    );
    _currentSalesperson = _settings.defaultSalesperson;
    await _repository.saveSettings(_settings);
    notifyListeners();
  }

  Future<DailyReportData> reportPreview(DateTime date) =>
      _repository.getDailyReportData(date);

  Future<File> generateReport(DateTime date) async {
    final report = await _repository.getDailyReportData(date);
    final file = await _pdfReportService.generateDailyReport(
      report: report,
      companyName: _settings.companyName,
      salespersonName: _currentSalesperson,
    );
    _lastGeneratedReport = file;
    notifyListeners();
    return file;
  }

  Future<void> shareLastReport() async {
    final file = _lastGeneratedReport;
    if (file == null) return;
    if (!await file.exists()) {
      throw FileSystemException('The generated PDF could not be found.', file.path);
    }
    await Share.shareXFiles([XFile(file.path)],
        text: 'Daily report from ${_settings.companyName}');
  }

  Future<ExportBundle> exportDesktopImportBundle(DateTime date) async {
    final exportMap = await _repository.getDailyExportMap(date);
    final bundle = await _exportService.exportDailyData(
      date: date,
      exportMap: exportMap,
      companyName: _settings.companyName,
    );
    _lastExportBundle = bundle;
    notifyListeners();
    return bundle;
  }

  Future<void> shareExportBundle() async {
    final bundle = _lastExportBundle;
    if (bundle == null) return;
    if (!await File(bundle.csvFile).exists() ||
        !await File(bundle.jsonFile).exists()) {
      throw FileSystemException(
          'One or more export files could not be found.');
    }
    await Share.shareXFiles(
      [XFile(bundle.csvFile), XFile(bundle.jsonFile)],
      text: 'Desktop import files from ${_settings.companyName}',
    );
  }

  Future<String?> saveExportCopy(String path) =>
      _exportService.saveCopyToUserLocation(path);

  Future<String?> createBackup() async {
    final dbPath = await _repository.getDatabasePath();
    final backupPath = await _backupService.createBackup(dbPath);
    _lastBackupPath = backupPath;
    notifyListeners();
    return backupPath;
  }

  Future<String?> saveBackupCopy(String sourcePath) =>
      _backupService.saveBackupCopy(sourcePath);
  Future<String?> pickBackupFile() => _backupService.pickBackupFile();

  Future<void> restoreBackup(String backupPath) async {
    final backupFile = File(backupPath);
    if (!await backupFile.exists()) {
      throw ArgumentError('Selected backup file could not be found.');
    }
    await _repository.closeDatabase();
    await _repository.replaceDatabaseWithFilePath(backupPath);
    _settings = await _repository.getSettings();
    _currentSalesperson = _settings.defaultSalesperson;
    _lastBackupPath = backupPath;
    notifyListeners();
  }

  Future<ImportResult> importShopsFromFile(String path,
      {bool replaceExisting = false}) async {
    final file = File(path);
    if (!await file.exists()) {
      throw ArgumentError('Selected import file could not be found.');
    }
    final rawText = await file.readAsString();
    final result = await _repository.importShopsFromText(rawText,
        replaceExisting: replaceExisting);
    notifyListeners();
    return result;
  }

  Future<ImportResult> importProductsFromFile(String path,
      {bool replaceExisting = false}) async {
    final file = File(path);
    if (!await file.exists()) {
      throw ArgumentError('Selected import file could not be found.');
    }
    final rawText = await file.readAsString();
    final result = await _repository.importProductsFromText(rawText,
        replaceExisting: replaceExisting);
    notifyListeners();
    return result;
  }

  Future<String?> pickAndSaveProfileImage() async {
    if (kIsWeb) return null;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    final sourcePath = result?.files.single.path;
    if (sourcePath == null || sourcePath.trim().isEmpty) return null;

    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) return null;

    final appDir = await getApplicationDocumentsDirectory();
    final ext = p.extension(sourcePath).toLowerCase();
    final safeExt = ext.isEmpty ? '.png' : ext;
    final targetPath = p.join(appDir.path, 'salesperson_avatar$safeExt');

    if ((_settings.profileImagePath ?? '').isNotEmpty &&
        _settings.profileImagePath != targetPath) {
      final previousFile = File(_settings.profileImagePath!);
      if (await previousFile.exists()) {
        await previousFile.delete();
      }
    }

    final copiedFile = await sourceFile.copy(targetPath);
    _settings = _settings.copyWith(profileImagePath: copiedFile.path);
    await _repository.saveSettings(_settings);
    notifyListeners();
    return copiedFile.path;
  }

  Future<void> clearProfileImage() async {
    final currentPath = _settings.profileImagePath;
    if (currentPath != null && currentPath.isNotEmpty) {
      final file = File(currentPath);
      if (await file.exists()) {
        await file.delete();
      }
    }

    _settings = _settings.copyWith(profileImagePath: '');
    await _repository.saveSettings(_settings);
    notifyListeners();
  }

  void _validateShop(Shop shop) {
    if (shop.name.trim().isEmpty) {
      throw ArgumentError('Shop name is required.');
    }
    if (shop.ownerContact.trim().isEmpty) {
      throw ArgumentError('Owner/contact is required.');
    }
    if (shop.area.trim().isEmpty) {
      throw ArgumentError('Area is required.');
    }
    if (shop.phone.trim().isEmpty) {
      throw ArgumentError('Phone number is required.');
    }
    if (shop.creditLimit < 0) {
      throw ArgumentError('Credit limit cannot be negative.');
    }
    if (shop.balance < 0) {
      throw ArgumentError('Shop balance cannot be negative.');
    }
  }

  void _validateProduct(Product product) {
    if (product.name.trim().isEmpty) {
      throw ArgumentError('Product name is required.');
    }
    if (product.sku.trim().isEmpty) {
      throw ArgumentError('SKU is required.');
    }
    if (product.unitPrice <= 0) {
      throw ArgumentError('Unit price must be greater than zero.');
    }
  }

  void _validateSale(SaleRecord sale) {
    if (sale.shopId <= 0 || sale.shopName.trim().isEmpty) {
      throw ArgumentError('A valid shop is required.');
    }
    if (sale.items.isEmpty) {
      throw ArgumentError('Add at least one item to the sale.');
    }
    if (sale.discount < 0) {
      throw ArgumentError('Discount cannot be negative.');
    }
    for (final item in sale.items) {
      if (item.productId <= 0 || item.productName.trim().isEmpty) {
        throw ArgumentError('Each sale item must reference a valid product.');
      }
      if (item.quantity <= 0) {
        throw ArgumentError('Item quantity must be greater than zero.');
      }
      if (item.unitPrice < 0 || item.lineTotal < 0) {
        throw ArgumentError('Item prices cannot be negative.');
      }
    }
  }

  void _validateCollection(CollectionRecord collection) {
    if (collection.shopId <= 0 || collection.shopName.trim().isEmpty) {
      throw ArgumentError('A valid shop is required.');
    }
    if (collection.amount <= 0) {
      throw ArgumentError('Collection amount must be greater than zero.');
    }
    if (collection.paymentMethod.trim().isEmpty) {
      throw ArgumentError('Payment method is required.');
    }
  }
}
