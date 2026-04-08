import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: IndexedStack(
        index: controller.currentTab,
        children: _screens,
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          12.w,
          0,
          12.w,
          (12.h) + bottomInset,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: 64.h,
              decoration: BoxDecoration(
                color: scheme.surface.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.92 : 0.86,
                ),
                borderRadius: BorderRadius.circular(28.r),
                border: Border.all(color: scheme.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                    color: Colors.black.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.18 : 0.06,
                    ),
                  ),
                ],
              ),
              child: NavigationBar(
                height: 64.h,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                indicatorColor: scheme.primary.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.22 : 0.10,
                ),
                selectedIndex: controller.currentTab,
                onDestinationSelected: (index) => controller.currentTab = index,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined, size: 24.w),
                    selectedIcon: Icon(Icons.home_rounded, size: 24.w),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.receipt_long_outlined, size: 24.w),
                    selectedIcon: Icon(Icons.receipt_long_rounded, size: 24.w),
                    label: 'Sales',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.account_balance_wallet_outlined, size: 24.w),
                    selectedIcon: Icon(Icons.account_balance_wallet_rounded, size: 24.w),
                    label: 'Collections',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.bar_chart_outlined, size: 24.w),
                    selectedIcon: Icon(Icons.bar_chart_rounded, size: 24.w),
                    label: 'Reports',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.more_horiz_outlined, size: 24.w),
                    selectedIcon: Icon(Icons.more_horiz_rounded, size: 24.w),
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
