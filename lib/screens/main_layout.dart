import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_controller.dart';
import 'collections/collections_history_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'more/more_screen.dart';
import 'reports/reports_screen.dart';
import 'sales/sales_history_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final List<Widget> _screens = [
    const DashboardScreen(),
    const SalesHistoryScreen(),
    const CollectionsHistoryScreen(),
    const ReportsScreen(),
    const MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final compact = MediaQuery.of(context).size.width < 430;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: IndexedStack(
        index: controller.currentTab,
        children: _screens,
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 10 : 12,
          0,
          compact ? 10 : 12,
          (compact ? 8 : 12) + bottomInset,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(compact ? 24 : 28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surface.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.92 : 0.86,
                ),
                borderRadius: BorderRadius.circular(compact ? 24 : 28),
                border: Border.all(color: scheme.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 24,
                    offset: Offset(0, 10),
                    color: Colors.black.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.18 : 0.06,
                    ),
                  ),
                ],
              ),
              child: NavigationBar(
                height: compact ? 58 : 72,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                indicatorColor: scheme.primary.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.22 : 0.10,
                ),
                labelBehavior: compact
                    ? NavigationDestinationLabelBehavior.alwaysHide
                    : NavigationDestinationLabelBehavior.alwaysShow,
                selectedIndex: controller.currentTab,
                onDestinationSelected: (index) => controller.currentTab = index,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.receipt_long_outlined),
                    selectedIcon: Icon(Icons.receipt_long_rounded),
                    label: 'Sales',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.account_balance_wallet_outlined),
                    selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                    label: 'Collections',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.bar_chart_outlined),
                    selectedIcon: Icon(Icons.bar_chart_rounded),
                    label: 'Reports',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.more_horiz_outlined),
                    selectedIcon: Icon(Icons.more_horiz_rounded),
                    label: 'More',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
