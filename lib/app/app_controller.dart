import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
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
    _currentSalesperson = salesperson.trim().isEmpty ? _settings.defaultSalesperson : salesperson.trim();
    _authenticated = true;
    notifyListeners();
    return null;
  }

  void logout() {
    _authenticated = false;
    notifyListeners();
  }

  Future<DashboardSummary> dashboardFor(DateTime date) => _repository.getDashboardSummary(date);
  Future<List<Shop>> fetchShops({String query = ''}) => _repository.getShops(query: query);
  Future<List<Product>> fetchProducts({String query = ''}) => _repository.getProducts(query: query);
  Future<Product?> findProductByBarcode(String barcode) => _repository.getProductByBarcode(barcode);
  Future<List<SaleRecord>> fetchSales({DateTime? start, DateTime? end, int? shopId}) =>
      _repository.getSales(start: start, end: end, shopId: shopId);
  Future<List<CollectionRecord>> fetchCollections({DateTime? start, DateTime? end, int? shopId}) =>
      _repository.getCollections(start: start, end: end, shopId: shopId);

  Future<void> saveShop(Shop shop) async {
    await _repository.saveShop(shop);
    notifyListeners();
  }

  Future<void> deactivateShop(int id) async {
    await _repository.deactivateShop(id);
    notifyListeners();
  }

  Future<void> saveProduct(Product product) async {
    await _repository.saveProduct(product);
    notifyListeners();
  }

  Future<void> deactivateProduct(int id) async {
    await _repository.deactivateProduct(id);
    notifyListeners();
  }

  Future<void> createSale(SaleRecord sale) async {
    await _repository.createSale(sale);
    notifyListeners();
  }

  Future<void> voidSale(int id, String reason) async {
    await _repository.voidSale(id, reason);
    notifyListeners();
  }

  Future<void> createCollection(CollectionRecord collection) async {
    await _repository.createCollection(collection);
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
  }) async {
    final normalizedPin = rawPin?.trim() ?? '';
    final pinHash = normalizedPin.isEmpty ? _settings.pinHash : sha256.convert(utf8.encode(normalizedPin)).toString();

    _settings = _settings.copyWith(
      companyName: companyName.trim(),
      defaultSalesperson: defaultSalesperson.trim(),
      paymentMethods: paymentMethods,
      pinEnabled: pinEnabled,
      pinHash: pinEnabled ? pinHash : '',
    );
    _currentSalesperson = _settings.defaultSalesperson;
    await _repository.saveSettings(_settings);
    notifyListeners();
  }

  Future<DailyReportData> reportPreview(DateTime date) => _repository.getDailyReportData(date);

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
    await Share.shareXFiles([XFile(file.path)], text: 'Daily report from ${_settings.companyName}');
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
    await Share.shareXFiles(
      [XFile(bundle.csvFile), XFile(bundle.jsonFile)],
      text: 'Desktop import files from ${_settings.companyName}',
    );
  }

  Future<String?> saveExportCopy(String path) => _exportService.saveCopyToUserLocation(path);

  Future<String?> createBackup() async {
    final dbPath = await _repository.getDatabasePath();
    final backupPath = await _backupService.createBackup(dbPath);
    _lastBackupPath = backupPath;
    notifyListeners();
    return backupPath;
  }

  Future<String?> saveBackupCopy(String sourcePath) => _backupService.saveBackupCopy(sourcePath);
  Future<String?> pickBackupFile() => _backupService.pickBackupFile();

  Future<void> restoreBackup(String backupPath) async {
    await _repository.closeDatabase();
    await _repository.replaceDatabaseWithFilePath(backupPath);
    _settings = await _repository.getSettings();
    _currentSalesperson = _settings.defaultSalesperson;
    notifyListeners();
  }

  Future<ImportResult> importShopsFromFile(String path, {bool replaceExisting = false}) async {
    final rawText = await File(path).readAsString();
    final result = await _repository.importShopsFromText(rawText, replaceExisting: replaceExisting);
    notifyListeners();
    return result;
  }

  Future<ImportResult> importProductsFromFile(String path, {bool replaceExisting = false}) async {
    final rawText = await File(path).readAsString();
    final result = await _repository.importProductsFromText(rawText, replaceExisting: replaceExisting);
    notifyListeners();
    return result;
  }
}
