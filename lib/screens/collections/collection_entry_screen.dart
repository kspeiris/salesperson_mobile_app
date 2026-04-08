import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../app/app_controller.dart';
import '../../core/theme/app_assets.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/section_card.dart';
import '../../models/entities.dart';

class CollectionEntryScreen extends StatefulWidget {
  const CollectionEntryScreen({super.key, this.collection});

  final CollectionRecord? collection;

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
  void initState() {
    super.initState();
    final existing = widget.collection;
    if (existing != null) {
      _amountController.text = existing.amount.toStringAsFixed(2);
      _referenceController.text = existing.referenceNote;
      _paymentMethod = existing.paymentMethod;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return FutureBuilder<List<Shop>>(
      future: controller.fetchShops(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final shops = _distinctShops(snapshot.data!);
        final methods = controller.settings.paymentMethods;

        Shop? selectedShop;
        final selectedShopId = _selectedShop?.id ?? widget.collection?.shopId;
        if (selectedShopId != null) {
          for (final shop in shops) {
            if (shop.id == selectedShopId) {
              selectedShop = shop;
              break;
            }
          }
        }
        _selectedShop ??= selectedShop;

        _paymentMethod ??= methods.isNotEmpty ? methods.first : 'Cash';

        final amount = double.tryParse(_amountController.text.trim()) ?? 0;
        final currentBalance = selectedShop?.balance ?? 0;
        final balanceAfter = currentBalance - amount;

        return Form(
          key: _formKey,
          child: AppShell(
            title: widget.collection == null
                ? 'New Collection'
                : 'Edit Collection',
            subtitle:
                'Capture payments received from shops and preserve a clean collection trail for reporting.',
            headerImageAsset: AppAssets.collectionsHero,
            pageBackgroundAsset: AppAssets.pageTexture,
            bottomNavigationBar: keyboardOpen
                ? null
                : SafeArea(
                    child: Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: theme.brightness == Brightness.dark
                                  ? 0.20
                                  : 0.06,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _saveCollection,
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('Confirm Payment'),
                      ),
                    ),
                  ),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(bottom: 24.h),
              children: [
                SectionCard(
                  title: 'Receipt details',
                  subtitle:
                      'Choose the shop, enter the amount received, and note how the payment was made.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            DropdownButtonFormField<Shop>(
                              initialValue: selectedShop,
                              isExpanded: true,
                              items: shops
                                  .map(
                                    (shop) => DropdownMenuItem<Shop>(
                                      value: shop,
                                      child: Text('${shop.name} - ${shop.area}'),
                                    ),
                                  )
                                  .toList(),
                              decoration: const InputDecoration(
                                labelText: 'Customer shop',
                                prefixIcon: Icon(Icons.storefront_outlined),
                              ),
                              onChanged: (value) =>
                                  setState(() => _selectedShop = value),
                              validator: (value) =>
                                  value == null ? 'Select a shop.' : null,
                            ),
                            SizedBox(height: 16.h),
                            TextFormField(
                              controller: _amountController,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Collected amount',
                                prefixIcon: Icon(Icons.payments_outlined),
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (value) {
                                final amount =
                                    double.tryParse((value ?? '').trim());
                                if (amount == null || amount <= 0) {
                                  return 'Enter a positive amount.';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16.h),
                            DropdownButtonFormField<String>(
                              initialValue: _paymentMethod,
                              decoration: const InputDecoration(
                                labelText: 'Payment method',
                                prefixIcon: Icon(Icons.credit_score_outlined),
                              ),
                              items: methods
                                  .map(
                                    (method) => DropdownMenuItem<String>(
                                      value: method,
                                      child: Text(method),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _paymentMethod = value),
                            ),
                            SizedBox(height: 16.h),
                            TextFormField(
                              controller: _referenceController,
                              minLines: 2,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Reference note',
                                hintText:
                                    'Cheque number, bank note, or internal remark',
                                alignLabelWithHint: true,
                                prefixIcon: Icon(Icons.notes_outlined),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                SectionCard(
                  title: 'Balance impact',
                  subtitle:
                      'Preview how this collection changes the selected shop balance before you save it.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _BalanceMetric(
                              label: 'Outstanding now',
                              value: AppFormatters.currency(currentBalance),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _BalanceMetric(
                              label: 'After payment',
                              value: AppFormatters.currency(
                                balanceAfter < 0 ? 0 : balanceAfter,
                              ),
                              emphasized: true,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark
                              ? scheme.surfaceContainerHighest
                              : const Color(0xFFF8FDF8),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            _summary(
                              'Selected payment method',
                              _paymentMethod ?? '-',
                            ),
                            SizedBox(height: 10.h),
                            _summary(
                              'Entered amount',
                              AppFormatters.currency(amount),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
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
      id: widget.collection?.id,
      shopId: _selectedShop!.id!,
      shopName: _selectedShop!.name,
      amount: double.parse(_amountController.text.trim()),
      paymentMethod: _paymentMethod!,
      referenceNote: _referenceController.text.trim(),
      status: widget.collection?.status ?? 'active',
      createdAt: widget.collection?.createdAt ?? DateTime.now(),
    );

    try {
      if (widget.collection == null) {
        await context.read<AppController>().createCollection(collection);
      } else {
        await context.read<AppController>().updateCollection(collection);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.collection == null
              ? 'Collection saved offline.'
              : 'Collection updated offline.'),
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Widget _summary(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: Theme.of(context).hintColor)),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _BalanceMetric extends StatelessWidget {
  const _BalanceMetric({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: emphasized ? scheme.primary : scheme.outlineVariant,
        ),
        boxShadow: emphasized
            ? [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: emphasized ? scheme.primary : null, fontSize: 11.sp),
          ),
          SizedBox(height: 6.h),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: emphasized ? scheme.primary : null,
                  fontSize: 18.sp,
                ),
          ),
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
