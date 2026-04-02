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
        title: const Text('Daily Operations'),
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
                            title: 'Total sales',
                            value: AppFormatters.currency(summary.totalSales),
                            subtitle: '${summary.salesCount} sales recorded',
                            icon: Icons.trending_up_rounded,
                          ),
                          MetricCard(
                            title: 'Collections',
                            value: AppFormatters.currency(summary.totalCollections),
                            subtitle: '${summary.collectionCount} receipts recorded',
                            icon: Icons.account_balance_wallet_outlined,
                          ),
                          MetricCard(
                            title: 'Cash sales',
                            value: AppFormatters.currency(summary.cashSales),
                            subtitle: 'Closed immediately',
                            icon: Icons.payments_rounded,
                          ),
                          MetricCard(
                            title: 'Credit sales',
                            value: AppFormatters.currency(summary.creditSales),
                            subtitle: 'Outstanding balance tracked',
                            icon: Icons.receipt_long_outlined,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: 'Create new record',
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 720;
                        if (compact) {
                          return Column(
                            children: [
                              _ActionPanel(
                                title: 'Record a sale',
                                description: 'Add a shop, build the cart, choose cash or credit, and save it offline instantly.',
                                icon: Icons.add_shopping_cart_rounded,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const SaleEntryScreen()),
                                ),
                                primary: true,
                              ),
                              const SizedBox(height: 12),
                              _ActionPanel(
                                title: 'Record a collection',
                                description: 'Capture payments from shops and keep balances current for the next visit.',
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
                                title: 'Record a sale',
                                description: 'Add a shop, build the cart, choose cash or credit, and save it offline instantly.',
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
                                title: 'Record a collection',
                                description: 'Capture payments from shops and keep balances current for the next visit.',
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
                    title: 'Workspace',
                    child: GridView.count(
                      crossAxisCount: width >= 900 ? 3 : width >= 600 ? 2 : 1,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: width >= 600 ? 1.5 : 1.9,
                      children: [
                        _WorkspaceTile(
                          title: 'Reports',
                          subtitle: 'Generate PDF and export files for desktop entry.',
                          icon: Icons.picture_as_pdf_outlined,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
                        ),
                        _WorkspaceTile(
                          title: 'Sales history',
                          subtitle: 'Review invoices by date and void when necessary.',
                          icon: Icons.history_rounded,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesHistoryScreen())),
                        ),
                        _WorkspaceTile(
                          title: 'Collections history',
                          subtitle: 'Check daily receipts and adjust voided entries.',
                          icon: Icons.list_alt_rounded,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectionsHistoryScreen())),
                        ),
                        _WorkspaceTile(
                          title: 'Shops',
                          subtitle: 'Maintain searchable customer records and balances.',
                          icon: Icons.storefront_outlined,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopsScreen())),
                        ),
                        _WorkspaceTile(
                          title: 'Products',
                          subtitle: 'Keep prices, SKUs, and barcode-ready items organized.',
                          icon: Icons.inventory_2_outlined,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductsScreen())),
                        ),
                        _WorkspaceTile(
                          title: 'Settings',
                          subtitle: 'Configure company profile, PIN, and data management tools.',
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
            '$companyName daily recorder',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.86)),
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
              const _StaticPill(icon: Icons.offline_bolt_rounded, label: 'Offline mode'),
              const _StaticPill(icon: Icons.picture_as_pdf_outlined, label: 'PDF ready'),
            ],
          ),
        ],
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
            Text(primary ? 'Start sale' : 'Start collection', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700)),
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
