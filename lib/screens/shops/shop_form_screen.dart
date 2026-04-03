import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_controller.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/section_card.dart';
import '../../models/entities.dart';

class ShopFormScreen extends StatefulWidget {
  const ShopFormScreen({super.key, this.shop});

  final Shop? shop;

  @override
  State<ShopFormScreen> createState() => _ShopFormScreenState();
}

class _ShopFormScreenState extends State<ShopFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _ownerController;
  late final TextEditingController _areaController;
  late final TextEditingController _phoneController;
  late final TextEditingController _creditLimitController;

  @override
  void initState() {
    super.initState();
    final shop = widget.shop;
    _nameController = TextEditingController(text: shop?.name ?? '');
    _ownerController = TextEditingController(text: shop?.ownerContact ?? '');
    _areaController = TextEditingController(text: shop?.area ?? '');
    _phoneController = TextEditingController(text: shop?.phone ?? '');
    _creditLimitController = TextEditingController(text: shop != null ? shop.creditLimit.toStringAsFixed(2) : '0');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerController.dispose();
    _areaController.dispose();
    _phoneController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final existing = widget.shop;
    final shop = Shop(
      id: existing?.id,
      name: _nameController.text.trim(),
      ownerContact: _ownerController.text.trim(),
      area: _areaController.text.trim(),
      phone: _phoneController.text.trim(),
      creditLimit: double.tryParse(_creditLimitController.text.trim()) ?? 0,
      balance: existing?.balance ?? 0,
      isActive: true,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await context.read<AppController>().saveShop(shop);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shop saved locally.')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: widget.shop == null ? 'Add Shop' : 'Edit Shop',
      subtitle: 'Keep shop records complete so sales, collections, and balance tracking stay accurate in the field.',
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            SectionCard(
              title: 'Shop details',
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Shop name',
                      prefixIcon: Icon(Icons.storefront_outlined),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Shop name is required.' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _ownerController,
                    decoration: const InputDecoration(
                      labelText: 'Owner / contact',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Owner/contact is required.' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _areaController,
                    decoration: const InputDecoration(
                      labelText: 'Area',
                      prefixIcon: Icon(Icons.place_outlined),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Area is required.' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Phone number is required.' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Credit setup',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set the shop credit limit used during sales and follow-up collections.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _creditLimitController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Credit limit',
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                    ),
                    validator: (value) {
                      final amount = double.tryParse((value ?? '').trim());
                      if (amount == null || amount < 0) return 'Enter a valid credit limit.';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(onPressed: _save, icon: const Icon(Icons.save_outlined), label: const Text('Save Shop')),
          ],
        ),
      ),
    );
  }
}
