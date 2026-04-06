import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_controller.dart';
import '../../core/theme/app_assets.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/section_card.dart';
import '../../models/entities.dart';
import '../shared/barcode_scanner_screen.dart';

class SaleEntryScreen extends StatefulWidget {
  const SaleEntryScreen({super.key, this.sale});

  final SaleRecord? sale;

  @override
  State<SaleEntryScreen> createState() => _SaleEntryScreenState();
}

class _SaleEntryScreenState extends State<SaleEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  final _discountController = TextEditingController();
  Shop? _selectedShop;
  String _paymentType = 'Cash';
  final List<_LineDraft> _lines = [_LineDraft()];

  @override
  void initState() {
    super.initState();
    final existing = widget.sale;
    _discountController.text = existing?.discount.toStringAsFixed(2) ?? '0';
    _noteController.text = existing?.note ?? '';

    if (existing != null) {
      _paymentType = existing.paymentType;
      _lines
        ..clear()
        ..addAll(
          existing.items.isEmpty
              ? [_LineDraft()]
              : existing.items.map(_LineDraft.fromSaleItem),
        );
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _discountController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  double get _subtotal => _lines.fold(0, (sum, line) => sum + line.total);
  double get _discount => double.tryParse(_discountController.text.trim()) ?? 0;
  double get _grandTotal => (_subtotal - _discount).clamp(0, double.infinity);

  @override
  Widget build(BuildContext context) {
    final controller = context.read<AppController>();
    final scheme = Theme.of(context).colorScheme;
    final compact = MediaQuery.of(context).size.width < 640;

    return FutureBuilder<List<dynamic>>(
      future: Future.wait<dynamic>(
          [controller.fetchShops(), controller.fetchProducts()]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final shops = _distinctShops(snapshot.data![0] as List<Shop>);
        final products = snapshot.data![1] as List<Product>;

        for (final line in _lines) {
          final productId = line.product?.id;
          if (productId == null) continue;
          Product? matchedProduct;
          for (final product in products) {
            if (product.id == productId) {
              matchedProduct = product;
              if (line.priceController.text.trim().isEmpty) {
                line.priceController.text = product.unitPrice.toStringAsFixed(2);
              }
              break;
            }
          }
          line.product = matchedProduct;
        }

        Shop? selectedShop;
        final selectedShopId = _selectedShop?.id ?? widget.sale?.shopId;
        if (selectedShopId != null) {
          for (final shop in shops) {
            if (shop.id == selectedShopId) {
              selectedShop = shop;
              break;
            }
          }
        }
        _selectedShop ??= selectedShop;

        return Form(
          key: _formKey,
          child: AppShell(
            title: widget.sale == null ? 'New Sale' : 'Edit Sale',
            subtitle:
                'Capture shop orders with product lines, payment type, and totals in one focused flow.',
            headerImageAsset: AppAssets.salesHero,
            pageBackgroundAsset: AppAssets.pageTexture,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                SectionCard(
                  title: 'Select Shop',
                  subtitle:
                      'Choose the customer before adding line items so totals stay linked to the right account.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<Shop>(
                        initialValue: selectedShop,
                        isExpanded: true,
                        items: shops
                            .map((shop) => DropdownMenuItem<Shop>(
                                  value: shop,
                                  child: Text('${shop.name} - ${shop.area}'),
                                ))
                            .toList(),
                        decoration: const InputDecoration(
                          labelText: 'Customer shop',
                          prefixIcon: Icon(Icons.storefront_rounded),
                        ),
                        onChanged: (value) =>
                            setState(() => _selectedShop = value),
                        validator: (value) =>
                            value == null ? 'Select a shop.' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SectionCard(
                  title: 'Add Products',
                  subtitle:
                      'Build the sale with one or more products, then adjust quantity or price when needed.',
                  trailing: TextButton.icon(
                    onPressed: () => _scanAndAttachProduct(products),
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: const Text('Scan'),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var index = 0; index < _lines.length; index++) ...[
                        _SaleLineCard(
                          index: index,
                          line: _lines[index],
                          products: products,
                          onChanged: () => setState(() {}),
                          onRemove: _lines.length == 1
                              ? null
                              : () {
                                  setState(() {
                                    _lines[index].dispose();
                                    _lines.removeAt(index);
                                  });
                                },
                        ),
                        if (index < _lines.length - 1)
                          const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: () =>
                            setState(() => _lines.add(_LineDraft())),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Another Product'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SectionCard(
                  title: 'Payment Details',
                  subtitle:
                      'Confirm payment type, discount, and any internal note before saving.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Payment method',
                          style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 10),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'Cash',
                            label: Text('Cash'),
                            icon: Icon(Icons.payments_rounded),
                          ),
                          ButtonSegment(
                            value: 'Credit',
                            label: Text('Credit'),
                            icon: Icon(Icons.timer_rounded),
                          ),
                        ],
                        selected: {_paymentType},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() => _paymentType = newSelection.first);
                        },
                        showSelectedIcon: false,
                        style: SegmentedButton.styleFrom(
                          backgroundColor: Colors.white,
                          selectedBackgroundColor:
                              scheme.primary.withValues(alpha: 0.1),
                          selectedForegroundColor: scheme.primary,
                          side: BorderSide(
                              color: scheme.primary.withValues(alpha: 0.2)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _discountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Discount amount',
                          prefixIcon: Icon(Icons.money_off_rounded),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _noteController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Invoice note',
                          hintText: 'Optional internal note for this sale',
                          prefixIcon: Icon(Icons.notes_rounded),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SectionCard(
                  title: 'Review & Save',
                  subtitle:
                      'Confirm the total before saving this sale to the device.',
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked = constraints.maxWidth < 380;

                      final totalBlock = Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Grand total',
                              style: Theme.of(context).textTheme.labelMedium),
                          const SizedBox(height: 2),
                          Text(
                            AppFormatters.currency(_grandTotal),
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      );

                      final saveButton = ElevatedButton.icon(
                        onPressed: () => _saveSale(),
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('Save Record'),
                      );

                      if (stacked) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            totalBlock,
                            const SizedBox(height: 14),
                            saveButton,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          totalBlock,
                          const SizedBox(width: 24),
                          Expanded(child: saveButton),
                        ],
                      );
                    },
                  ),
                ),
                if (!compact) const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _scanAndAttachProduct(List<Product> products) async {
    final controller = context.read<AppController>();
    final messenger = ScaffoldMessenger.of(context);

    final scannedValue = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (scannedValue == null || scannedValue.trim().isEmpty) return;

    final product = await controller.findProductByBarcode(scannedValue.trim());
    if (!mounted) return;
    if (product == null) {
      messenger.showSnackBar(SnackBar(
          content: Text('No active product found for barcode $scannedValue')));
      return;
    }

    setState(() {
      _LineDraft? target;
      for (final line in _lines) {
        if (line.product == null) {
          target = line;
          break;
        }
      }
      target ??= _createAdditionalLine();
      target.product = product;
      target.qty = 1;
      target.priceController.text = product.unitPrice.toStringAsFixed(2);
    });

    messenger.showSnackBar(
        SnackBar(content: Text('${product.name} added from barcode scan.')));
  }

  _LineDraft _createAdditionalLine() {
    final line = _LineDraft();
    _lines.add(line);
    return line;
  }

  Future<void> _saveSale() async {
    final messenger = ScaffoldMessenger.of(context);

    if (!_formKey.currentState!.validate()) return;
    if (_selectedShop == null) return;

    final validLines = _lines
        .where((line) => line.product != null && line.quantity > 0)
        .toList();
    if (validLines.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Add at least one item with quantity above zero.')),
      );
      return;
    }

    final items = validLines
        .map(
          (line) => SaleItem(
            productId: line.product!.id!,
            productName: line.product!.name,
            quantity: line.quantity,
            unitPrice: line.price,
            lineTotal: line.total,
          ),
        )
        .toList();

    final sale = SaleRecord(
      id: widget.sale?.id,
      shopId: _selectedShop!.id!,
      shopName: _selectedShop!.name,
      paymentType: _paymentType,
      note: _noteController.text.trim(),
      subtotal: _subtotal,
      discount: _discount,
      total: _grandTotal,
      status: widget.sale?.status ?? 'active',
      createdAt: widget.sale?.createdAt ?? DateTime.now(),
      items: items,
    );

    final controller = context.read<AppController>();

    try {
      if (widget.sale == null) {
        await controller.createSale(sale);
      } else {
        await controller.updateSale(sale);
      }
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(widget.sale == null
              ? 'Sale saved offline.'
              : 'Sale updated offline.'),
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

List<Shop> _distinctShops(List<Shop> shops) {
  final seen = <String>{};
  final unique = <Shop>[];
  for (final shop in shops) {
    final key = '${shop.id ?? 'null'}|${shop.name}|${shop.area}';
    if (seen.add(key)) unique.add(shop);
  }
  return unique;
}

class _SaleLineCard extends StatelessWidget {
  const _SaleLineCard({
    required this.index,
    required this.line,
    required this.products,
    required this.onChanged,
    this.onRemove,
  });

  final int index;
  final _LineDraft line;
  final List<Product> products;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8F5E9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Line item ${index + 1}',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<Product>(
                  initialValue: line.product,
                  isExpanded: true,
                  items: products
                      .map((product) => DropdownMenuItem<Product>(
                            value: product,
                            child: Text(product.name),
                          ))
                      .toList(),
                  decoration: const InputDecoration(
                    labelText: 'Product',
                    prefixIcon: Icon(Icons.local_drink_rounded),
                  ),
                  onChanged: (value) {
                    line.product = value;
                    if (value != null) {
                      line.priceController.text =
                          value.unitPrice.toStringAsFixed(2);
                    }
                    onChanged();
                  },
                  validator: (value) => value == null ? 'Required' : null,
                ),
              ),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Qty', style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FDF8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE8F5E9)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_rounded),
                          onPressed: () {
                            if (line.quantity > 1) {
                              line.qty = line.quantity - 1;
                              onChanged();
                            }
                          },
                          color: scheme.primary,
                        ),
                        Text('${line.quantity}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(
                          icon: const Icon(Icons.add_rounded),
                          onPressed: () {
                            line.qty = line.quantity + 1;
                            onChanged();
                          },
                          color: scheme.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(
                width: 220,
                child: TextFormField(
                  controller: line.priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Unit Price',
                    prefixText: 'Rs ',
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Total: ${AppFormatters.currency(line.total)}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800, color: scheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineDraft {
  Product? product;
  int _qty = 1;
  final priceController = TextEditingController();

  _LineDraft();

  factory _LineDraft.fromSaleItem(SaleItem item) {
    final draft = _LineDraft();
    draft.product = Product(
      id: item.productId,
      name: item.productName,
      sku: '',
      unitPrice: item.unitPrice,
      description: '',
      barcode: '',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    draft.qty = item.quantity;
    draft.priceController.text = item.unitPrice.toStringAsFixed(2);
    return draft;
  }

  int get quantity => _qty;

  set qty(int value) {
    _qty = value;
  }

  double get price => double.tryParse(priceController.text.trim()) ?? 0;
  double get total => quantity * price;

  void dispose() {
    priceController.dispose();
  }
}

