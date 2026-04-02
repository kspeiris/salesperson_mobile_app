class Shop {
  const Shop({
    this.id,
    required this.name,
    required this.ownerContact,
    required this.area,
    required this.phone,
    required this.creditLimit,
    required this.balance,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final String ownerContact;
  final String area;
  final String phone;
  final double creditLimit;
  final double balance;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Shop &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          area == other.area;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ area.hashCode;

  Shop copyWith({
    int? id,
    String? name,
    String? ownerContact,
    String? area,
    String? phone,
    double? creditLimit,
    double? balance,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Shop(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerContact: ownerContact ?? this.ownerContact,
      area: area ?? this.area,
      phone: phone ?? this.phone,
      creditLimit: creditLimit ?? this.creditLimit,
      balance: balance ?? this.balance,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Shop.fromMap(Map<String, Object?> map) {
    return Shop(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      ownerContact: map['owner_contact'] as String? ?? '',
      area: map['area'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      creditLimit: ((map['credit_limit'] as num?) ?? 0).toDouble(),
      balance: ((map['balance'] as num?) ?? 0).toDouble(),
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'owner_contact': ownerContact,
      'area': area,
      'phone': phone,
      'credit_limit': creditLimit,
      'balance': balance,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Product {
  const Product({
    this.id,
    required this.name,
    required this.sku,
    required this.unitPrice,
    required this.description,
    required this.barcode,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final String sku;
  final double unitPrice;
  final String description;
  final String barcode;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sku == other.sku;

  @override
  int get hashCode => id.hashCode ^ sku.hashCode;

  Product copyWith({
    int? id,
    String? name,
    String? sku,
    double? unitPrice,
    String? description,
    String? barcode,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      unitPrice: unitPrice ?? this.unitPrice,
      description: description ?? this.description,
      barcode: barcode ?? this.barcode,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Product.fromMap(Map<String, Object?> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      sku: map['sku'] as String? ?? '',
      unitPrice: ((map['unit_price'] as num?) ?? 0).toDouble(),
      description: map['description'] as String? ?? '',
      barcode: map['barcode'] as String? ?? '',
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'unit_price': unitPrice,
      'description': description,
      'barcode': barcode,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class SaleItem {
  const SaleItem({
    this.id,
    this.saleId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  final int? id;
  final int? saleId;
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  SaleItem copyWith({
    int? id,
    int? saleId,
    int? productId,
    String? productName,
    int? quantity,
    double? unitPrice,
    double? lineTotal,
  }) {
    return SaleItem(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      lineTotal: lineTotal ?? this.lineTotal,
    );
  }

  factory SaleItem.fromMap(Map<String, Object?> map) {
    return SaleItem(
      id: map['id'] as int?,
      saleId: map['sale_id'] as int?,
      productId: map['product_id'] as int? ?? 0,
      productName: map['product_name'] as String? ?? '',
      quantity: map['quantity'] as int? ?? 0,
      unitPrice: ((map['unit_price'] as num?) ?? 0).toDouble(),
      lineTotal: ((map['line_total'] as num?) ?? 0).toDouble(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'sale_id': saleId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'line_total': lineTotal,
    };
  }
}

class SaleRecord {
  const SaleRecord({
    this.id,
    required this.shopId,
    required this.shopName,
    required this.paymentType,
    required this.note,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.status,
    required this.createdAt,
    this.voidReason,
    this.items = const [],
  });

  final int? id;
  final int shopId;
  final String shopName;
  final String paymentType;
  final String note;
  final double subtotal;
  final double discount;
  final double total;
  final String status;
  final DateTime createdAt;
  final String? voidReason;
  final List<SaleItem> items;

  bool get isVoided => status == 'voided';

  SaleRecord copyWith({
    int? id,
    int? shopId,
    String? shopName,
    String? paymentType,
    String? note,
    double? subtotal,
    double? discount,
    double? total,
    String? status,
    DateTime? createdAt,
    String? voidReason,
    List<SaleItem>? items,
  }) {
    return SaleRecord(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      paymentType: paymentType ?? this.paymentType,
      note: note ?? this.note,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      voidReason: voidReason ?? this.voidReason,
      items: items ?? this.items,
    );
  }

  factory SaleRecord.fromMap(Map<String, Object?> map, {List<SaleItem> items = const []}) {
    return SaleRecord(
      id: map['id'] as int?,
      shopId: map['shop_id'] as int? ?? 0,
      shopName: map['shop_name'] as String? ?? '',
      paymentType: map['payment_type'] as String? ?? 'Cash',
      note: map['note'] as String? ?? '',
      subtotal: ((map['subtotal'] as num?) ?? 0).toDouble(),
      discount: ((map['discount'] as num?) ?? 0).toDouble(),
      total: ((map['total'] as num?) ?? 0).toDouble(),
      status: map['status'] as String? ?? 'active',
      voidReason: map['void_reason'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      items: items,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'shop_id': shopId,
      'shop_name': shopName,
      'payment_type': paymentType,
      'note': note,
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'status': status,
      'void_reason': voidReason,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class CollectionRecord {
  const CollectionRecord({
    this.id,
    required this.shopId,
    required this.shopName,
    required this.amount,
    required this.paymentMethod,
    required this.referenceNote,
    required this.status,
    required this.createdAt,
    this.voidReason,
  });

  final int? id;
  final int shopId;
  final String shopName;
  final double amount;
  final String paymentMethod;
  final String referenceNote;
  final String status;
  final DateTime createdAt;
  final String? voidReason;

  bool get isVoided => status == 'voided';

  CollectionRecord copyWith({
    int? id,
    int? shopId,
    String? shopName,
    double? amount,
    String? paymentMethod,
    String? referenceNote,
    String? status,
    DateTime? createdAt,
    String? voidReason,
  }) {
    return CollectionRecord(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      referenceNote: referenceNote ?? this.referenceNote,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      voidReason: voidReason ?? this.voidReason,
    );
  }

  factory CollectionRecord.fromMap(Map<String, Object?> map) {
    return CollectionRecord(
      id: map['id'] as int?,
      shopId: map['shop_id'] as int? ?? 0,
      shopName: map['shop_name'] as String? ?? '',
      amount: ((map['amount'] as num?) ?? 0).toDouble(),
      paymentMethod: map['payment_method'] as String? ?? 'Cash',
      referenceNote: map['reference_note'] as String? ?? '',
      status: map['status'] as String? ?? 'active',
      voidReason: map['void_reason'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'shop_id': shopId,
      'shop_name': shopName,
      'amount': amount,
      'payment_method': paymentMethod,
      'reference_note': referenceNote,
      'status': status,
      'void_reason': voidReason,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class DashboardSummary {
  const DashboardSummary({
    required this.totalSales,
    required this.cashSales,
    required this.creditSales,
    required this.totalCollections,
    required this.salesCount,
    required this.collectionCount,
  });

  final double totalSales;
  final double cashSales;
  final double creditSales;
  final double totalCollections;
  final int salesCount;
  final int collectionCount;
}

class AppSettings {
  const AppSettings({
    required this.companyName,
    required this.defaultSalesperson,
    required this.paymentMethods,
    required this.pinEnabled,
    this.pinHash,
  });

  final String companyName;
  final String defaultSalesperson;
  final List<String> paymentMethods;
  final bool pinEnabled;
  final String? pinHash;

  AppSettings copyWith({
    String? companyName,
    String? defaultSalesperson,
    List<String>? paymentMethods,
    bool? pinEnabled,
    String? pinHash,
  }) {
    return AppSettings(
      companyName: companyName ?? this.companyName,
      defaultSalesperson: defaultSalesperson ?? this.defaultSalesperson,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      pinEnabled: pinEnabled ?? this.pinEnabled,
      pinHash: pinHash ?? this.pinHash,
    );
  }
}

class DailyReportData {
  const DailyReportData({
    required this.date,
    required this.dashboard,
    required this.sales,
    required this.collections,
  });

  final DateTime date;
  final DashboardSummary dashboard;
  final List<SaleRecord> sales;
  final List<CollectionRecord> collections;
}

class ImportResult {
  const ImportResult({
    required this.importedCount,
    required this.updatedCount,
    required this.skippedCount,
    required this.errors,
  });

  final int importedCount;
  final int updatedCount;
  final int skippedCount;
  final List<String> errors;

  String get summary =>
      'Imported: $importedCount, Updated: $updatedCount, Skipped: $skippedCount';
}

class ExportBundle {
  const ExportBundle({
    required this.csvFile,
    required this.jsonFile,
  });

  final String csvFile;
  final String jsonFile;
}
