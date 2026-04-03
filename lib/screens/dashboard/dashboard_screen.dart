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
    final metricCrossAxisCount = width >= 980 ? 4 : width >= 640 ? 2 : 1;
    final workspaceCrossAxisCount = width >= 900 ? 3 : width >= 620 ? 2 : 1;
    final metricAspectRatio = width >= 980
        ? 1.16
        : width >= 640
            ? 1.14
            : 1.34;
    final workspaceAspectRatio = width >= 620 ? 1.26 : 1.52;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Dashboard'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: FutureBuilder(
            future: controller.dashboardFor(_selectedDate),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final summary = snapshot.data!;
              final totalOrders = summary.salesCount + summary.collectionCount;
              final cashShare = summary.totalSales == 0 ? 0 : (summary.cashSales / summary.totalSales) * 100;
              final collectionCoverage =
                  summary.totalSales == 0 ? 0 : (summary.totalCollections / summary.totalSales) * 100;

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                    children: [
                      _HeroPanel(
                        salesperson: controller.currentSalesperson,
                        companyName: controller.settings.companyName,
                        selectedDate: _selectedDate,
                        totalOrders: totalOrders,
                        onDateTap: _pickDate,
                        onNewSale: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SaleEntryScreen()),
                        ),
                        onNewCollection: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CollectionEntryScreen()),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SectionCard(
                        title: 'Today at a glance',
                        child: Column(
                          children: [
                            GridView.count(
                              crossAxisCount: metricCrossAxisCount,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: metricAspectRatio,
                              children: [
                                MetricCard(
                                  title: 'Sales value',
                                  value: AppFormatters.currency(summary.totalSales),
                                  subtitle: '${summary.salesCount} orders captured',
                                  icon: Icons.trending_up_rounded,
                                ),
                                MetricCard(
                                  title: 'Collections',
                                  value: AppFormatters.currency(summary.totalCollections),
                                  subtitle: '${summary.collectionCount} receipts logged',
                                  icon: Icons.account_balance_wallet_outlined,
                                ),
                                MetricCard(
                                  title: 'Cash sales',
                                  value: AppFormatters.currency(summary.cashSales),
                                  subtitle: '${cashShare.toStringAsFixed(0)}% of today\'s sales',
                                  icon: Icons.payments_rounded,
                                ),
                                MetricCard(
                                  title: 'Credit balance',
                                  value: AppFormatters.currency(summary.creditSales),
                                  subtitle: 'Pending from recorded orders',
                                  icon: Icons.receipt_long_outlined,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final stacked = constraints.maxWidth < 720;
                                if (stacked) {
                                  return Column(
                                    children: [
                                      _InsightCard(
                                        title: 'Collection coverage',
                                        value: '${collectionCoverage.toStringAsFixed(0)}%',
                                        description:
                                            'A quick comparison of collections against today\'s sales value for the selected date.',
                                        icon: Icons.ssid_chart_rounded,
                                      ),
                                      const SizedBox(height: 12),
                                      _InsightCard(
                                        title: 'Route activity',
                                        value: '$totalOrders actions',
                                        description:
                                            'Combined orders and receipts captured so far, giving you a clean pulse on route momentum.',
                                        icon: Icons.route_rounded,
                                      ),
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(
                                      child: _InsightCard(
                                        title: 'Collection coverage',
                                        value: '${collectionCoverage.toStringAsFixed(0)}%',
                                        description:
                                            'A quick comparison of collections against today\'s sales value for the selected date.',
                                        icon: Icons.ssid_chart_rounded,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _InsightCard(
                                        title: 'Route activity',
                                        value: '$totalOrders actions',
                                        description:
                                            'Combined orders and receipts captured so far, giving you a clean pulse on route momentum.',
                                        icon: Icons.route_rounded,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SectionCard(
                        title: 'Quick actions',
                        child: GridView.count(
                          crossAxisCount: width >= 740 ? 4 : 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: width >= 740 ? 1.15 : 1.02,
                          children: [
                            _QuickActionTile(
                              title: 'New sale',
                              subtitle: 'Capture an order',
                              icon: Icons.add_shopping_cart_rounded,
                              accent: const Color(0xFF155C4A),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SaleEntryScreen()),
                              ),
                            ),
                            _QuickActionTile(
                              title: 'Collection',
                              subtitle: 'Log a payment',
                              icon: Icons.request_quote_outlined,
                              accent: const Color(0xFFE28A2B),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CollectionEntryScreen()),
                              ),
                            ),
                            _QuickActionTile(
                              title: 'History',
                              subtitle: 'Review orders',
                              icon: Icons.history_rounded,
                              accent: const Color(0xFF2F7A6B),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SalesHistoryScreen()),
                              ),
                            ),
                            _QuickActionTile(
                              title: 'Reports',
                              subtitle: 'Export daily files',
                              icon: Icons.picture_as_pdf_outlined,
                              accent: const Color(0xFF336C88),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ReportsScreen()),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SectionCard(
                        title: 'Workspace',
                        child: GridView.count(
                          crossAxisCount: workspaceCrossAxisCount,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: workspaceAspectRatio,
                          children: [
                            _WorkspaceTile(
                              title: 'Sales history',
                              subtitle: 'Review saved orders and void entries when needed.',
                              icon: Icons.receipt_long_rounded,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SalesHistoryScreen()),
                              ),
                            ),
                            _WorkspaceTile(
                              title: 'Collections history',
                              subtitle: 'Track receipts, balances, and payment updates.',
                              icon: Icons.account_balance_wallet_outlined,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CollectionsHistoryScreen()),
                              ),
                            ),
                            _WorkspaceTile(
                              title: 'Shops',
                              subtitle: 'Manage retail partners, balances, and route targets.',
                              icon: Icons.storefront_outlined,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ShopsScreen()),
                              ),
                            ),
                            _WorkspaceTile(
                              title: 'Products',
                              subtitle: 'Keep item pricing, barcodes, and catalog details organized.',
                              icon: Icons.inventory_2_outlined,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ProductsScreen()),
                              ),
                            ),
                            _WorkspaceTile(
                              title: 'Reports',
                              subtitle: 'Generate PDFs and share export files from the device.',
                              icon: Icons.insert_drive_file_outlined,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ReportsScreen()),
                              ),
                            ),
                            _WorkspaceTile(
                              title: 'Settings',
                              subtitle: 'Update identity, security, and data tools.',
                              icon: Icons.settings_outlined,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SettingsScreen()),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
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
    required this.totalOrders,
    required this.onDateTap,
    required this.onNewSale,
    required this.onNewCollection,
  });

  final String salesperson;
  final String companyName;
  final DateTime selectedDate;
  final int totalOrders;
  final VoidCallback onDateTap;
  final VoidCallback onNewSale;
  final VoidCallback onNewCollection;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.of(context).size.width;
    final compact = width < 620;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF155C4A),
            Color(0xFF2F7A6B),
            Color(0xFF0D3B35),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 28,
            offset: Offset(0, 14),
            color: Color(0x1F0F231D),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 20 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: compact ? 52 : 58,
                  height: compact ? 52 : 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initialsFor(salesperson),
                    style: textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, $salesperson',
                        style: textTheme.headlineSmall?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        companyName,
                        style: textTheme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.86)),
                      ),
                    ],
                  ),
                ),
                _HeroDateChip(label: AppFormatters.date(selectedDate), onTap: onDateTap),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Stay on top of the route with clean daily totals, fast entry points, and a layout designed for quick mobile use in the field.',
              style: textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.82)),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _HeroStatChip(label: '$totalOrders actions', icon: Icons.route_rounded),
                const _HeroStatChip(label: 'Offline ready', icon: Icons.offline_bolt_rounded),
                const _HeroStatChip(label: 'Share reports later', icon: Icons.share_outlined),
              ],
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 560;
                if (stacked) {
                  return Column(
                    children: [
                      _HeroActionButton(
                        label: 'Record new sale',
                        icon: Icons.add_shopping_cart_rounded,
                        filled: true,
                        onTap: onNewSale,
                      ),
                      const SizedBox(height: 10),
                      _HeroActionButton(
                        label: 'Record collection',
                        icon: Icons.request_quote_outlined,
                        onTap: onNewCollection,
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: _HeroActionButton(
                        label: 'Record new sale',
                        icon: Icons.add_shopping_cart_rounded,
                        filled: true,
                        onTap: onNewSale,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HeroActionButton(
                        label: 'Record collection',
                        icon: Icons.request_quote_outlined,
                        onTap: onNewCollection,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static String _initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'SR';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }
}

class _HeroDateChip extends StatelessWidget {
  const _HeroDateChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStatChip extends StatelessWidget {
  const _HeroStatChip({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  const _HeroActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final background = filled ? Colors.white : Colors.white.withValues(alpha: 0.10);
    final foreground = filled ? const Color(0xFF155C4A) : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: filled ? 0.0 : 0.16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: foreground),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.value,
    required this.description,
    required this.icon,
  });

  final String title;
  final String value;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: scheme.primary.withValues(alpha: 0.05),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(description),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              accent.withValues(alpha: 0.08),
            ],
          ),
          border: Border.all(color: accent.withValues(alpha: 0.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const Spacer(),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
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
          border: Border.all(color: const Color(0xFFDDE6DF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: scheme.primary),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
            const Spacer(),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              subtitle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
