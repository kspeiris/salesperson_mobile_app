import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../app/app_controller.dart';
import '../../core/theme/app_assets.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/metric_card.dart';
import '../../core/widgets/salesperson_avatar.dart';
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bio Care Consumers'),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => controller.logout(),
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            color: theme.hintColor,
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

              final activities = _combineActivity(sales, collections);

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(AppAssets.pageTexture),
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        opacity: 0.06,
                      ),
                    ),
                    child: ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 32.h),
                      children: [
                        _HeroPanel(
                          salesperson: controller.currentSalesperson,
                          companyName: controller.settings.companyName,
                          profileImagePath: controller.profileImagePath,
                          selectedDate: _selectedDate,
                          totalOrders: totalOrders,
                          todaySales: summary.totalSales,
                          onDateTap: _pickDate,
                          onNewSale: _openSaleEntry,
                          onNewCollection: _openCollectionEntry,
                        ),
                        SizedBox(height: 24.h),
                        _SmartSuggestionBanner(
                          onNewSale: _openSaleEntry,
                          onNewCollection: _openCollectionEntry,
                        ),
                        SizedBox(height: 20.h),
                        SectionCard(
                          title: 'Today at a glance',
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final availableWidth = constraints.maxWidth;
                              final metricCrossAxisCount =
                                  availableWidth < 260 ? 1 : 2;
                              final metricMainAxisExtent = availableWidth < 360
                                  ? 172.h
                                  : availableWidth < 460
                                      ? 184.h
                                      : 196.h;

                              return Column(
                                children: [
                                  GridView(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: metricCrossAxisCount,
                                      crossAxisSpacing: 12.w,
                                      mainAxisSpacing: 12.h,
                                      mainAxisExtent: metricMainAxisExtent,
                                    ),
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
                                        icon: Icons
                                            .account_balance_wallet_outlined,
                                      ),
                                      MetricCard(
                                        title: 'Cash sales',
                                        value: AppFormatters.currency(
                                            summary.cashSales),
                                        subtitle:
                                            '${cashShare.toStringAsFixed(0)}% of today\'s sales',
                                        icon: Icons.payments_rounded,
                                      ),
                                      MetricCard(
                                        title: 'Credit balance',
                                        value: AppFormatters.currency(
                                            summary.creditSales),
                                        subtitle:
                                            'Pending from recorded orders',
                                        icon: Icons.receipt_long_outlined,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 18.h),
                                  Column(
                                    children: [
                                      _InsightCard(
                                        title: 'Collection coverage',
                                        value:
                                            '${collectionCoverage.toStringAsFixed(0)}%',
                                        description:
                                            'A quick comparison of collections against today\'s sales value.',
                                        icon: Icons.ssid_chart_rounded,
                                      ),
                                      SizedBox(height: 12.h),
                                      _InsightCard(
                                        title: 'Route activity',
                                        value: '$totalOrders actions',
                                        description:
                                            'Combined orders and receipts captured for the selected date.',
                                        icon: Icons.route_rounded,
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 20.h),
                        SectionCard(
                          title: 'Recent activity',
                          child: activities.isEmpty
                              ? Padding(
                                  padding: EdgeInsets.symmetric(vertical: 32.h),
                                  child: const Center(
                                      child:
                                          Text('No recorded activity found.')),
                                )
                              : Column(
                                  children: [
                                    for (var i = 0;
                                        i < activities.length;
                                        i++) ...[
                                      _ActivityItem(activity: activities[i]),
                                      if (i < activities.length - 1)
                                        Divider(
                                            height: 24.h,
                                            color: scheme.outlineVariant),
                                    ],
                                  ],
                                ),
                        ),
                      ],
                    ),
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
    FocusScope.of(context).unfocus();
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

  Future<void> _openSaleEntry() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SaleEntryScreen()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openCollectionEntry() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CollectionEntryScreen()),
    );
    if (mounted) setState(() {});
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({required this.activity});

  final dynamic activity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
          width: 42.w,
          height: 42.w,
          decoration: BoxDecoration(
            color: isSale
                ? scheme.primary.withValues(alpha: 0.14)
                : scheme.secondary.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(
            isSale ? Icons.receipt_long_rounded : Icons.request_quote_rounded,
            color: isSale ? scheme.primary : scheme.secondary,
            size: 20.w,
          ),
        ),
        SizedBox(width: 14.w),
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
                style: TextStyle(color: theme.hintColor, fontSize: 12.sp),
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
  const _SmartSuggestionBanner({
    required this.onNewSale,
    required this.onNewCollection,
  });

  final VoidCallback onNewSale;
  final VoidCallback onNewCollection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: theme.brightness == Brightness.dark
              ? [scheme.surface, scheme.surfaceContainerHighest]
              : const [
                  Color(0xFFF7FBF3),
                  Color(0xFFE8F3E4),
                ],
        ),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.18 : 0.06,
            ),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(18.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.18 : 0.04,
                  ),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: scheme.primary,
              size: 24.w,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Route strategy tip',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  "Review today's sales and collections to decide which shops need follow-up first, then capture the next route action from here.",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 18.h),
                Wrap(
                  spacing: 10.w,
                  runSpacing: 10.h,
                  children: [
                    FilledButton.icon(
                      onPressed: onNewSale,
                      icon: Icon(Icons.add_shopping_cart_rounded, size: 18.w),
                      label: const Text('New Sale'),
                      style: FilledButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: onNewCollection,
                      icon: Icon(Icons.request_quote_outlined, size: 18.w),
                      label: const Text('Record Collection'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size.zero,
                        backgroundColor: theme.brightness == Brightness.dark
                            ? scheme.surface.withValues(alpha: 0.18)
                            : Colors.transparent,
                        foregroundColor: theme.brightness == Brightness.dark
                            ? Colors.white
                            : scheme.primary,
                        side: BorderSide(
                          color: theme.brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.22)
                              : scheme.outlineVariant,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.salesperson,
    required this.companyName,
    required this.profileImagePath,
    required this.selectedDate,
    required this.totalOrders,
    required this.todaySales,
    required this.onDateTap,
    required this.onNewSale,
    required this.onNewCollection,
  });

  final String salesperson;
  final String companyName;
  final String? profileImagePath;
  final DateTime selectedDate;
  final int totalOrders;
  final double todaySales;
  final VoidCallback onDateTap;
  final VoidCallback onNewSale;
  final VoidCallback onNewCollection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final greeting = _greetingForHour(DateTime.now().hour);

    return Container(
      constraints: BoxConstraints(minHeight: 320.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26.r),
        image: const DecorationImage(
          image: AssetImage(AppAssets.dashboardHero),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 30,
            offset: const Offset(0, 16),
            color: Colors.black.withValues(alpha: 0.10),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.55, 1.0],
            colors: [
              const Color(0xFF143C1E).withValues(alpha: 0.58),
              const Color(0xFF1D5B2B).withValues(alpha: 0.42),
              const Color(0xFF4CAF50).withValues(alpha: 0.24),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12.w,
                runSpacing: 12.h,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  BrandLogo(
                    height: 28.h,
                    padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h),
                    showPlate: true,
                    alignment: Alignment.centerLeft,
                    plateDecoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? theme.colorScheme.surface.withValues(alpha: 0.86)
                          : const Color(0xFFF7FBF4),
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                          color: Colors.black.withValues(alpha: 0.12),
                        ),
                      ],
                    ),
                  ),
                  _HeroDateChip(
                    label: AppFormatters.date(selectedDate),
                    onTap: onDateTap,
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SalespersonAvatar(
                    name: salesperson,
                    imagePath: profileImagePath,
                    size: 48.w,
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                    foregroundColor: Colors.white,
                    borderColor: Colors.white.withValues(alpha: 0.32),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting, $salesperson',
                          style: textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            fontSize: 20.sp,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          companyName,
                          style: textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.86),
                              fontWeight: FontWeight.w500,
                              fontSize: 14.sp),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                'Your daily route summary and next best actions.',
                style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                    height: 1.5,
                    fontSize: 13.sp),
              ),
              SizedBox(height: 16.h),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _HeroStatChip(
                          label: '$totalOrders actions',
                          icon: Icons.sync_alt_rounded,
                          fullWidth: true,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      const Expanded(
                        child: _HeroStatChip(
                          label: 'Offline ready',
                          icon: Icons.wifi_off_rounded,
                          fullWidth: true,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  _HeroStatChip(
                    label: '${AppFormatters.currency(todaySales)} today',
                    icon: Icons.payments_outlined,
                    fullWidth: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _greetingForHour(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
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
      child: _HeroGlassBadge(
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today_outlined, size: 16.w, color: Colors.white),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroStatChip extends StatelessWidget {
  const _HeroStatChip({
    required this.label,
    required this.icon,
    this.fullWidth = false,
  });

  final String label;
  final IconData icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: _HeroGlassBadge(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          child: Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment:
                fullWidth ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(icon, size: 16.w, color: Colors.white),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroGlassBadge extends StatelessWidget {
  const _HeroGlassBadge({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
          ),
          child: child,
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: scheme.primary.withValues(alpha: 0.05),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(icon, color: Colors.white, size: 24.w),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium?.copyWith(fontSize: 14.sp)),
                SizedBox(height: 6.h),
                Text(
                  value,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800, fontSize: 20.sp),
                ),
                SizedBox(height: 6.h),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


