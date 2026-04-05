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
  const SaleEntryScreen({super.key});

  @override
  State<SaleEntryScreen> createState() => _SaleEntryScreenState();
}

class _SaleEntryScreenState extends State<SaleEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  Shop? _selectedShop;
  String _paymentType = 'Cash';
  final List<_LineDraft> _lines = [_LineDraft()];

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

        Shop? selectedShop;
        if (_selectedShop != null) {
          for (final shop in shops) {
            if (shop.id == _selectedShop!.id) {
              selectedShop = shop;
              break;
            }
          }
        }

        return Form(
          key: _formKey,
          child: AppShell(
            title: 'New Sale',
            subtitle:
                'Capture shop orders with product lines, payment type, and totals in one focused flow.',
            headerImageAsset: AppAssets.salesHero,
            pageBackgroundAsset: AppAssets.pageTexture,
            header: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _EntryChip(
                  icon: Icons.schedule_outlined,
                  label: AppFormatters.dateTime(DateTime.now()),
                ),
                _EntryChip(
                  icon: Icons.payments_outlined,
                  label: _paymentType,
                ),
                _EntryChip(
                  icon: Icons.inventory_2_outlined,
                  label: '${_lines.length} line${_lines.length == 1 ? '' : 's'}',
                ),
              ],
            ),
            bottomNavigationBar: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Color(0x0A000000),
                        offset: Offset(0, -4),
                        blurRadius: 16),
                  ],
                ),
                child: Row(
                  children: [
                    Column(
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
                                  fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _saveSale(),
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('Save Record'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            child: ListView(
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
      shopId: _selectedShop!.id!,
      shopName: _selectedShop!.name,
      paymentType: _paymentType,
      note: _noteController.text.trim(),
      subtotal: _subtotal,
      discount: _discount,
      total: _grandTotal,
      status: 'active',
      createdAt: DateTime.now(),
      items: items,
    );

    final controller = context.read<AppController>();

    try {
      await controller.createSale(sale);
      if (!mounted) return;
      messenger
          .showSnackBar(const SnackBar(content: Text('Sale saved offline.')));
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

class _EntryChip extends StatelessWidget {
  const _EntryChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
