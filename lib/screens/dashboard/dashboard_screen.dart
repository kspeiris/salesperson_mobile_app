import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_controller.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/metric_card.dart';
import '../../core/widgets/section_card.dart';
import '../collections/collection_entry_screen.dart';
import '../collections/collections_history_screen.dart';
import '../products/products_screen.dart';
import '../reports/reports_screen.dart';
import '../sales/sale_entry_screen.dart';
import '../sales/sales_history_screen.dart';
import '../settings/settings_screen.dart';
import '../shops/shops_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 980 ? 4 : width >= 720 ? 2 : 1;
    final metricAspectRatio = width >= 980
        ? 1.18
        : width >= 720
            ? 1.08
            : 1.32;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bio Care Field Dashboard'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _HeroPanel(
                    salesperson: controller.currentSalesperson,
                    companyName: controller.settings.companyName,
                    selectedDate: _selectedDate,
                    onDateTap: _pickDate,
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder(
                    future: controller.dashboardFor(_selectedDate),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final summary = snapshot.data!;
                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: metricAspectRatio,
                        children: [
                          MetricCard(
                            title: 'Beverage sales',
                            value: AppFormatters.currency(summary.totalSales),
                            subtitle: '${summary.salesCount} outlet invoices recorded',
                            icon: Icons.trending_up_rounded,
                          ),
                          MetricCard(
                            title: 'Partner collections',
                            value: AppFormatters.currency(summary.totalCollections),
                            subtitle: '${summary.collectionCount} retailer receipts recorded',
                            icon: Icons.account_balance_wallet_outlined,
                          ),
                          MetricCard(
                            title: 'Immediate cash',
                            value: AppFormatters.currency(summary.cashSales),
                            subtitle: 'Settled during the visit',
                            icon: Icons.payments_rounded,
                          ),
                          MetricCard(
                            title: 'Credit exposure',
                            value: AppFormatters.currency(summary.creditSales),
                            subtitle: 'Outstanding balances in the route',
                            icon: Icons.receipt_long_outlined,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: 'Daily field actions',
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 720;
                        if (compact) {
                          return Column(
                            children: [
                              _ActionPanel(
                                title: 'Record a beverage order',
                                description: 'Add the outlet, build the order, choose cash or credit, and save the visit instantly.',
                                icon: Icons.add_shopping_cart_rounded,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const SaleEntryScreen()),
                                ),
                                primary: true,
                              ),
                              const SizedBox(height: 12),
                              _ActionPanel(
                                title: 'Record a partner payment',
                                description: 'Capture retailer collections and keep route balances accurate for the next Bio Care visit.',
                                icon: Icons.request_quote_outlined,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CollectionEntryScreen()),
                                ),
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(
                              child: _ActionPanel(
                                title: 'Record a beverage order',
                                description: 'Add the outlet, build the order, choose cash or credit, and save the visit instantly.',
                                icon: Icons.add_shopping_cart_rounded,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const SaleEntryScreen()),
                                ),
                                primary: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ActionPanel(
                                title: 'Record a partner payment',
                                description: 'Capture retailer collections and keep route balances accurate for the next Bio Care visit.',
                                icon: Icons.request_quote_outlined,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CollectionEntryScreen()),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: 'Bio Care workspace',
                    child: GridView.count(
                      crossAxisCount: width >= 900 ? 3 : width >= 600 ? 2 : 1,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: width >= 600 ? 1.5 : 1.9,
                      children: [
                        _WorkspaceTile(
                          title: 'Route reports',
                          subtitle: 'Generate PDF and export files for daily Bio Care field reporting.',
                          icon: Icons.picture_as_pdf_outlined,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
                        ),
                        _WorkspaceTile(
                          title: 'Invoice history',
                          subtitle: 'Review beverage orders by date and void when necessary.',
                          icon: Icons.history_rounded,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesHistoryScreen())),
                        ),
                        _WorkspaceTile(
                          title: 'Collection history',
                          subtitle: 'Check retailer receipts and adjust voided entries.',
                          icon: Icons.list_alt_rounded,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectionsHistoryScreen())),
                        ),
                        _WorkspaceTile(
                          title: 'Retail partners',
                          subtitle: 'Maintain searchable outlet records, balances, and visit targets.',
                          icon: Icons.storefront_outlined,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopsScreen())),
                        ),
                        _WorkspaceTile(
                          title: 'Beverage catalog',
                          subtitle: 'Keep aloe, fruit, and herbal SKUs, prices, and barcodes organized.',
                          icon: Icons.inventory_2_outlined,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductsScreen())),
                        ),
                        _WorkspaceTile(
                          title: 'Brand settings',
                          subtitle: 'Configure company identity, PIN access, and data management tools.',
                          icon: Icons.settings_outlined,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.salesperson,
    required this.companyName,
    required this.selectedDate,
    required this.onDateTap,
  });

  final String salesperson;
  final String companyName;
  final DateTime selectedDate;
  final VoidCallback onDateTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            scheme.primary.withValues(alpha: 0.86),
            const Color(0xFF0C3E38),
          ],
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, $salesperson',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            '$companyName wellness route operations',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.86)),
          ),
          const SizedBox(height: 12),
          Text(
            'Natural aloe vera, fruit, and herbal beverages with a field workflow that supports purity, consistency, and trusted retail supply.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.78)),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Pill(
                icon: Icons.calendar_today_outlined,
                label: AppFormatters.date(selectedDate),
                onTap: onDateTap,
              ),
              const _StaticPill(icon: Icons.eco_outlined, label: 'Pure ingredients'),
              const _StaticPill(icon: Icons.verified_outlined, label: 'Quality assured'),
            ],
          ),
          const SizedBox(height: 20),
          const Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _HighlightChip(label: 'Since 2009'),
              _HighlightChip(label: '100,000+ bottles/month'),
              _HighlightChip(label: 'No artificial additives'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HighlightChip extends StatelessWidget {
  const _HighlightChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _StaticPill extends StatelessWidget {
  const _StaticPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = primary ? scheme.primary.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.72);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: primary ? scheme.primary.withValues(alpha: 0.18) : const Color(0xFFE4DDD2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: primary ? scheme.primary : scheme.secondary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: primary ? Colors.white : scheme.secondary),
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 16),
            Text(primary ? 'Start order' : 'Start payment log', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceTile extends StatelessWidget {
  const _WorkspaceTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE4DDD2)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: scheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
