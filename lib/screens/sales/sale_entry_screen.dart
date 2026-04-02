import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_controller.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_shell.dart';
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

        return AppShell(
          title: 'New Sale',
          subtitle:
              'Create an item-based sale, keep it offline, and include all details needed for end-of-day reporting.',
          header: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(
                  icon: Icons.schedule_outlined,
                  label: AppFormatters.dateTime(DateTime.now())),
              _InfoChip(
                  icon: Icons.shopping_bag_outlined,
                  label: '${_lines.length} line items'),
              _InfoChip(icon: Icons.payments_outlined, label: _paymentType),
            ],
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                SectionCard(
                  title: 'Customer and payment',
                  child: Column(
                    children: [
                      DropdownButtonFormField<Shop>(
                        initialValue: selectedShop,
                        isExpanded: true,
                        items: shops
                            .map((shop) => DropdownMenuItem<Shop>(
                                value: shop,
                                child: Text('${shop.name} - ${shop.area}')))
                            .toList(),
                        decoration: const InputDecoration(
                          labelText: 'Shop',
                          prefixIcon: Icon(Icons.storefront_outlined),
                        ),
                        onChanged: (value) =>
                            setState(() => _selectedShop = value),
                        validator: (value) =>
                            value == null ? 'Select a shop.' : null,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _paymentType,
                        items: const [
                          DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                          DropdownMenuItem(
                              value: 'Credit', child: Text('Credit')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Payment type',
                          prefixIcon:
                              Icon(Icons.account_balance_wallet_outlined),
                        ),
                        onChanged: (value) =>
                            setState(() => _paymentType = value ?? 'Cash'),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _noteController,
                        decoration: const InputDecoration(
                          labelText: 'Invoice note',
                          hintText: 'Optional delivery or billing note',
                          prefixIcon: Icon(Icons.sticky_note_2_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Sale items',
                  trailing: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: () => _scanAndAttachProduct(products),
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                        label: const Text('Scan'),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            setState(() => _lines.add(_LineDraft())),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add item'),
                      ),
                    ],
                  ),
                  child: Column(
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
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _summary('Subtotal', AppFormatters.currency(_subtotal)),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _discountController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Discount',
                            prefixIcon: Icon(Icons.sell_outlined),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (value) {
                            final discount =
                                double.tryParse((value ?? '').trim());
                            if (discount == null || discount < 0) {
                              return 'Enter a valid discount.';
                            }
                            if (discount > _subtotal) {
                              return 'Discount cannot exceed subtotal.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _summary('Payment type', _paymentType),
                        const Divider(height: 28),
                        _summary(
                            'Grand total', AppFormatters.currency(_grandTotal),
                            strong: true),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _saveSale(products),
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save sale offline'),
                ),
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
      target.qtyController.text = target.qtyController.text.trim().isEmpty
          ? '1'
          : target.qtyController.text;
      target.priceController.text = product.unitPrice.toStringAsFixed(2);
    });

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} added from barcode scan.')));
  }

  _LineDraft _createAdditionalLine() {
    final line = _LineDraft();
    _lines.add(line);
    return line;
  }

  Future<void> _saveSale(List<Product> products) async {
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

    await controller.createSale(sale);
    if (!mounted) return;
    messenger
        .showSnackBar(const SnackBar(content: Text('Sale saved offline.')));
    Navigator.pop(context);
  }

  Widget _summary(String label, String value, {bool strong = false}) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          value,
          style: TextStyle(
              fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
              fontSize: strong ? 18 : 14),
        ),
      ],
    );
  }
}

List<Shop> _distinctShops(List<Shop> shops) {
  final seen = <String>{};
  final unique = <Shop>[];

  for (final shop in shops) {
    final key = '${shop.id ?? 'null'}|${shop.name}|${shop.area}';
    if (seen.add(key)) {
      unique.add(shop);
    }
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE1D9CC)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: Text('Item ${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w700))),
              if (onRemove != null)
                IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline_rounded)),
            ],
          ),
          DropdownButtonFormField<Product>(
            initialValue: line.product,
            isExpanded: true,
            items: products
                .map((product) => DropdownMenuItem<Product>(
                    value: product,
                    child: Text('${product.name} - ${product.sku}')))
                .toList(),
            decoration: const InputDecoration(
              labelText: 'Product',
              prefixIcon: Icon(Icons.inventory_2_outlined),
            ),
            onChanged: (value) {
              line.product = value;
              if (value != null) {
                line.priceController.text = value.unitPrice.toStringAsFixed(2);
              }
              onChanged();
            },
            validator: (value) => value == null ? 'Select a product.' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: line.qtyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Qty',
                    prefixIcon: Icon(Icons.numbers_rounded),
                  ),
                  onChanged: (_) => onChanged(),
                  validator: (value) {
                    final qty = int.tryParse((value ?? '').trim());
                    if (qty == null || qty <= 0) return 'Qty > 0';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: line.priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Unit price',
                    prefixIcon: Icon(Icons.currency_exchange_outlined),
                  ),
                  onChanged: (_) => onChanged(),
                  validator: (value) {
                    final price = double.tryParse((value ?? '').trim());
                    if (price == null || price <= 0) return 'Price > 0';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text('Line total: ${AppFormatters.currency(line.total)}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
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
        color: scheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: scheme.primary, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _LineDraft {
  Product? product;
  final qtyController = TextEditingController(text: '1');
  final priceController = TextEditingController();

  int get quantity => int.tryParse(qtyController.text.trim()) ?? 0;
  double get price => double.tryParse(priceController.text.trim()) ?? 0;
  double get total => quantity * price;

  void dispose() {
    qtyController.dispose();
    priceController.dispose();
  }
}
