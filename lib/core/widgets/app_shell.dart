import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_sizes.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.bottom,
    this.bottomNavigationBar,
    this.showBack = true,
    this.subtitle,
    this.header,
    this.floatingActionButton,
    this.headerImageAsset,
    this.pageBackgroundAsset,
    this.showHeaderImage = true,
    this.showPageBackground = true,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? bottomNavigationBar;
  final bool showBack;
  final String? subtitle;
  final Widget? header;
  final Widget? floatingActionButton;
  final String? headerImageAsset;
  final String? pageBackgroundAsset;
  final bool showHeaderImage;
  final bool showPageBackground;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final keyboardOpen = bottomInset > 0;
    final showHeaderCard = !keyboardOpen && (subtitle != null || header != null);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        automaticallyImplyLeading: showBack,
        title: Text(title),
        actions: actions,
        bottom: bottom,
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: bottomNavigationBar,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              image: !showPageBackground || pageBackgroundAsset == null
                  ? null
                  : DecorationImage(
                      image: AssetImage(pageBackgroundAsset!),
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      opacity: 0.06,
                    ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.fromLTRB(
                    16.w,
                    12.h,
                    16.w,
                    (20.h) + bottomSafeArea,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showHeaderCard)
                        Padding(
                          padding: EdgeInsets.only(bottom: 24.h),
                          child: _ShellHeaderCard(
                            title: title,
                            subtitle: subtitle,
                            header: header,
                            headerImageAsset:
                                showHeaderImage ? headerImageAsset : null,
                          ),
                        ),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShellHeaderCard extends StatelessWidget {
  const _ShellHeaderCard({
    required this.title,
    required this.subtitle,
    required this.header,
    required this.headerImageAsset,
  });

  final String title;
  final String? subtitle;
  final Widget? header;
  final String? headerImageAsset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final hasImage = headerImageAsset != null;
    final imageMinHeight = 180.h;
    final panelRadius = BorderRadius.circular(24.r);

    return Container(
      constraints: hasImage ? BoxConstraints(minHeight: imageMinHeight) : null,
      decoration: BoxDecoration(
        borderRadius: panelRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF15231B), Color(0xFF1C2E23)]
              : const [Color(0xFFF7FCF7), Color(0xFFEAF5EB)],
        ),
        border: Border.all(
          color: isDark ? scheme.outlineVariant : const Color(0xFFD6E7D8),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 28,
            offset: const Offset(0, 14),
            color: isDark
                ? Colors.black.withValues(alpha: 0.24)
                : const Color(0x1293B620),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: panelRadius,
        child: Stack(
          children: [
            if (hasImage)
              Positioned.fill(
                child: Image.asset(
                  headerImageAsset!,
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                ),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: hasImage ? const [0.0, 0.42, 1.0] : null,
                    colors: hasImage
                        ? [
                            const Color(0xFF708D18).withValues(alpha: 0.92),
                            const Color(0xFF93B620).withValues(alpha: 0.58),
                            Colors.white.withValues(alpha: 0.06),
                          ]
                        : isDark
                            ? const [Color(0xFF15231B), Color(0xFF1C2E23)]
                            : const [Color(0xFFF7FCF7), Color(0xFFEAF5EB)],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -30.w,
              top: -20.h,
              child: Container(
                width: 110.w,
                height: 110.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.14),
                ),
              ),
            ),
            Positioned(
              left: -20.w,
              bottom: -40.h,
              child: Container(
                width: 90.w,
                height: 90.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD6E68F).withValues(alpha: 0.14),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22.r),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: hasImage ? 280.w : double.infinity,
                      ),
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22.r),
                        color: Colors.white.withValues(
                            alpha: hasImage ? 0.18 : (isDark ? 0.08 : 0.72)),
                        border: Border.all(
                          color: Colors.white
                              .withValues(alpha: isDark ? 0.12 : 0.28),
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.26)
                                : const Color(0x120F172A),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              height: 1.05,
                              fontWeight: FontWeight.w800,
                              color: hasImage || isDark
                                  ? Colors.white
                                  : theme.primaryColor,
                              fontSize: 22.sp,
                            ),
                          ),
                          if (subtitle != null) ...[
                            SizedBox(height: 8.h),
                            Text(
                              subtitle!,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: hasImage || isDark
                                    ? Colors.white.withValues(alpha: 0.84)
                                    : theme.textTheme.bodyMedium?.color,
                                height: 1.35,
                                fontSize: 13.sp,
                              ),
                            ),
                          ],
                          if (header != null) ...[
                            SizedBox(height: 16.h),
                            header!,
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
