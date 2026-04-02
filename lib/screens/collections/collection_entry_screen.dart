import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_controller.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/section_card.dart';
import '../../models/entities.dart';

class CollectionEntryScreen extends StatefulWidget {
  const CollectionEntryScreen({super.key});

  @override
  State<CollectionEntryScreen> createState() => _CollectionEntryScreenState();
}

class _CollectionEntryScreenState extends State<CollectionEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  Shop? _selectedShop;
  String? _paymentMethod;

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();

    return FutureBuilder<List<Shop>>(
      future: controller.fetchShops(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final shops = _distinctShops(snapshot.data!);
        final methods = controller.settings.paymentMethods;

        Shop? selectedShop;
        if (_selectedShop != null) {
          for (final shop in shops) {
            if (shop.id == _selectedShop!.id) {
              selectedShop = shop;
              break;
            }
          }
        }

        _paymentMethod ??= methods.isNotEmpty ? methods.first : 'Cash';

        final balanceAfter = (selectedShop?.balance ?? 0) -
            (double.tryParse(_amountController.text.trim()) ?? 0);

        return AppShell(
          title: 'New Collection',
          subtitle:
              'Capture payments received from shops and preserve a clean collection trail for reporting and desktop entry.',
          header: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _CollectionChip(
                  icon: Icons.schedule_outlined,
                  label: AppFormatters.dateTime(DateTime.now())),
              _CollectionChip(
                  icon: Icons.account_balance_wallet_outlined,
                  label: _paymentMethod ?? 'Cash'),
            ],
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                SectionCard(
                  title: 'Receipt details',
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
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (value) {
                          final amount = double.tryParse((value ?? '').trim());
                          if (amount == null || amount <= 0) {
                            return 'Enter a positive amount.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _paymentMethod,
                        decoration: const InputDecoration(
                          labelText: 'Payment method',
                          prefixIcon: Icon(Icons.credit_score_outlined),
                        ),
                        items: methods
                            .map((method) => DropdownMenuItem(
                                value: method, child: Text(method)))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _paymentMethod = value),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _referenceController,
                        decoration: const InputDecoration(
                          labelText: 'Reference note',
                          hintText:
                              'Cheque number, bank note, or internal remark',
                          prefixIcon: Icon(Icons.notes_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Outstanding before payment',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(AppFormatters.currency(
                            _selectedShop?.balance ?? 0)),
                        const SizedBox(height: 18),
                        Text('Balance after payment',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          AppFormatters.currency(
                              balanceAfter < 0 ? 0 : balanceAfter),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _saveCollection,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save collection offline'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveCollection() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedShop == null || _paymentMethod == null) return;

    final collection = CollectionRecord(
      shopId: _selectedShop!.id!,
      shopName: _selectedShop!.name,
      amount: double.parse(_amountController.text.trim()),
      paymentMethod: _paymentMethod!,
      referenceNote: _referenceController.text.trim(),
      status: 'active',
      createdAt: DateTime.now(),
    );

    await context.read<AppController>().createCollection(collection);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Collection saved offline.')));
    Navigator.pop(context);
  }
}

class _CollectionChip extends StatelessWidget {
  const _CollectionChip({
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
        color: scheme.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: scheme.secondary),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: scheme.secondary, fontWeight: FontWeight.w700)),
        ],
      ),
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
