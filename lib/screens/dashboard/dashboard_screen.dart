import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_controller.dart';
import '../../core/theme/app_assets.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/metric_card.dart';
import '../../core/widgets/section_card.dart';
import '../../models/entities.dart';
import '../collections/collection_entry_screen.dart';
import '../sales/sale_entry_screen.dart';

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
    final metricCrossAxisCount = width >= 980
        ? 4
        : width >= 640
            ? 2
            : 1;
    final metricAspectRatio = width >= 980
        ? 1.36
        : width >= 640
            ? 1.32
            : 1.54;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bio Care Hub'),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => controller.logout(),
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: FutureBuilder(
            future: Future.wait([
              controller.dashboardFor(_selectedDate),
              controller.fetchSales(),
              controller.fetchCollections(),
            ]),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final summary = snapshot.data![0] as DashboardSummary;
              final sales = snapshot.data![1] as List<SaleRecord>;
              final collections = snapshot.data![2] as List<CollectionRecord>;

              final totalOrders = summary.salesCount + summary.collectionCount;
              final cashShare = summary.totalSales == 0
                  ? 0
                  : (summary.cashSales / summary.totalSales) * 100;
              final collectionCoverage = summary.totalSales == 0
                  ? 0
                  : (summary.totalCollections / summary.totalSales) * 100;

              // Combined activity, limited to 5
              final activities = _combineActivity(sales, collections);

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      _HeroPanel(
                        salesperson: controller.currentSalesperson,
                        companyName: controller.settings.companyName,
                        selectedDate: _selectedDate,
                        totalOrders: totalOrders,
                        onDateTap: _pickDate,
                        onNewSale: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SaleEntryScreen()),
                        ),
                        onNewCollection: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CollectionEntryScreen()),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _SmartSuggestionBanner(),
                      const SizedBox(height: 20),
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
                                  value: AppFormatters.currency(
                                      summary.totalSales),
                                  subtitle:
                                      '${summary.salesCount} orders captured',
                                  icon: Icons.trending_up_rounded,
                                ),
                                MetricCard(
                                  title: 'Collections',
                                  value: AppFormatters.currency(
                                      summary.totalCollections),
                                  subtitle:
                                      '${summary.collectionCount} receipts logged',
                                  icon: Icons.account_balance_wallet_outlined,
                                ),
                                MetricCard(
                                  title: 'Cash sales',
                                  value:
                                      AppFormatters.currency(summary.cashSales),
                                  subtitle:
                                      '${cashShare.toStringAsFixed(0)}% of today\'s sales',
                                  icon: Icons.payments_rounded,
                                ),
                                MetricCard(
                                  title: 'Credit balance',
                                  value: AppFormatters.currency(
                                      summary.creditSales),
                                  subtitle: 'Pending from recorded orders',
                                  icon: Icons.receipt_long_outlined,
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final stacked = constraints.maxWidth < 720;
                                if (stacked) {
                                  return Column(
                                    children: [
                                      _InsightCard(
                                        title: 'Collection coverage',
                                        value:
                                            '${collectionCoverage.toStringAsFixed(0)}%',
                                        description:
                                            'A quick comparison of collections against today\'s sales value.',
                                        icon: Icons.ssid_chart_rounded,
                                      ),
                                      const SizedBox(height: 12),
                                      _InsightCard(
                                        title: 'Route activity',
                                        value: '$totalOrders actions',
                                        description:
                                            'Combined orders and receipts captured for the selected date.',
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
                                        value:
                                            '${collectionCoverage.toStringAsFixed(0)}%',
                                        description:
                                            'A quick comparison of collections against today\'s sales value.',
                                        icon: Icons.ssid_chart_rounded,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _InsightCard(
                                        title: 'Route activity',
                                        value: '$totalOrders actions',
                                        description:
                                            'Combined orders and receipts captured for the selected date.',
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
                      const SizedBox(height: 20),
                      SectionCard(
                        title: 'Recent activity',
                        child: activities.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 32),
                                child: Center(
                                    child: Text('No recorded activity found.')),
                              )
                            : Column(
                                children: [
                                  for (var i = 0;
                                      i < activities.length;
                                      i++) ...[
                                    _ActivityItem(activity: activities[i]),
                                    if (i < activities.length - 1)
                                      const Divider(
                                          height: 24, color: Color(0xFFF1F4F1)),
                                  ],
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

  List<dynamic> _combineActivity(
      List<SaleRecord> sales, List<CollectionRecord> collections) {
    final list = <dynamic>[...sales, ...collections];
    list.sort((a, b) {
      final DateTime da =
          (a is SaleRecord) ? a.createdAt : (a as CollectionRecord).createdAt;
      final DateTime db =
          (b is SaleRecord) ? b.createdAt : (b as CollectionRecord).createdAt;
      return db.compareTo(da);
    });
    return list.take(5).toList();
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

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({required this.activity});

  final dynamic activity;

  @override
  Widget build(BuildContext context) {
    final isSale = activity is SaleRecord;
    final String shopName = isSale
        ? (activity as SaleRecord).shopName
        : (activity as CollectionRecord).shopName;
    final double amount = isSale
        ? (activity as SaleRecord).total
        : (activity as CollectionRecord).amount;
    final DateTime createdAt = isSale
        ? (activity as SaleRecord).createdAt
        : (activity as CollectionRecord).createdAt;

    final dateStr = AppFormatters.date(createdAt);
    final timeStr = AppFormatters.time(createdAt);

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isSale ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isSale ? Icons.receipt_long_rounded : Icons.request_quote_rounded,
            color: isSale ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shopName,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '$dateStr • $timeStr',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
        Text(
          AppFormatters.currency(amount),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _SmartSuggestionBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC8E6C9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A2E7D32),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                )
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Color(0xFF2E7D32), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Route Strategy Tip',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B5E20),
                      fontSize: 13,
                      letterSpacing: 0.2),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your area "Colombo 07" has 3 shops with overdue balances. Prioritize collections today to maintain account limits.',
                  style: TextStyle(
                      fontSize: 14, color: Colors.grey.shade800, height: 1.4),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF2E7D32)),
        ],
      ),
    );
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
      constraints: BoxConstraints(minHeight: compact ? 340 : 380),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: AssetImage(AppAssets.dashboardHero),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2E7D32),
            Color(0xFF1B5E20),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 32,
            offset: Offset(0, 16),
            color: Color(0x1F2E7D32),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            stops: const [0.0, 0.55, 1.0],
            colors: [
              const Color(0xFF16311A).withValues(alpha: 0.84),
              const Color(0xFF2E7D32).withValues(alpha: 0.58),
              const Color(0xFF2E7D32).withValues(alpha: 0.18),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(compact ? 24 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: BrandLogo(
                      height: compact ? 40 : 48,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _HeroDateChip(
                      label: AppFormatters.date(selectedDate),
                      onTap: onDateTap),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Good morning, $salesperson',
                style: (compact
                        ? textTheme.headlineSmall
                        : textTheme.headlineMedium)
                    ?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                companyName,
                style: textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
              Text(
                'Your daily route summary and quick actions. Keep delivering health and trusted quality to our customers.',
                style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8), height: 1.6),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _HeroStatChip(
                      label: '$totalOrders actions', icon: Icons.route_rounded),
                  const _HeroStatChip(
                      label: 'Offline ready', icon: Icons.offline_bolt_rounded),
                  const _HeroStatChip(
                      label: 'Share reports later', icon: Icons.share_outlined),
                ],
              ),
              const SizedBox(height: 36),
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
                        const SizedBox(height: 12),
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
                      const SizedBox(width: 16),
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
      ),
    );
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
            const Icon(Icons.calendar_today_outlined,
                size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
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
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700),
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
    final background =
        filled ? Colors.white : Colors.white.withValues(alpha: 0.08);
    final foreground = filled ? const Color(0xFF155C4A) : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Colors.white.withValues(alpha: filled ? 0.0 : 0.18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: foreground, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                  color: foreground, fontWeight: FontWeight.w800, fontSize: 16),
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
        borderRadius: BorderRadius.circular(16),
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
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
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
