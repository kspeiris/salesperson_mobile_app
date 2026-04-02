import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_controller.dart';
import '../../core/widgets/app_shell.dart';
import '../../models/entities.dart';
import '../shared/barcode_scanner_screen.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});

  final Product? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _skuController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _barcodeController;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _skuController = TextEditingController(text: product?.sku ?? '');
    _priceController = TextEditingController(text: product != null ? product.unitPrice.toStringAsFixed(2) : '');
    _descriptionController = TextEditingController(text: product?.description ?? '');
    _barcodeController = TextEditingController(text: product?.barcode ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final existing = widget.product;
    final product = Product(
      id: existing?.id,
      name: _nameController.text.trim(),
      sku: _skuController.text.trim(),
      unitPrice: double.parse(_priceController.text.trim()),
      description: _descriptionController.text.trim(),
      barcode: _barcodeController.text.trim(),
      isActive: true,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await context.read<AppController>().saveProduct(product);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product saved locally.')));
    Navigator.pop(context);
  }

  Future<void> _scanBarcode() async {
    final scannedValue = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (scannedValue != null && scannedValue.trim().isNotEmpty) {
      _barcodeController.text = scannedValue.trim();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Barcode captured: $scannedValue')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: widget.product == null ? 'Add Product' : 'Edit Product',
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Product Name'),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Product name is required.' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _skuController,
              decoration: const InputDecoration(labelText: 'SKU'),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'SKU is required.' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _barcodeController,
              decoration: InputDecoration(
                labelText: 'Barcode',
                suffixIcon: IconButton(
                  onPressed: _scanBarcode,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  tooltip: 'Scan Barcode',
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Unit Price'),
              validator: (value) {
                final price = double.tryParse((value ?? '').trim());
                if (price == null || price <= 0) return 'Enter a valid unit price.';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(onPressed: _save, icon: const Icon(Icons.save_outlined), label: const Text('Save Product')),
          ],
        ),
      ),
    );
  }
}
