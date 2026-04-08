import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_sizes.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.subtitle,
  });

  final String title;
  final String value;
  final IconData icon;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 170;
        final cardPadding = isCompact ? 12.w : 16.w;
        final iconBoxSize = isCompact ? 38.w : 44.w;
        final iconSize = isCompact ? 18.w : 22.w;
        final arrowSize = isCompact ? 16.w : 18.w;
        final valueFontSize = isCompact ? 18.sp : 22.sp;
        final subtitleFontSize =
            isCompact ? (theme.textTheme.bodySmall?.fontSize ?? 12.sp) - 1 : null;

        return Container(
          constraints: BoxConstraints(minHeight: 168.h),
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: scheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.18 : 0.03,
                ),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: iconBoxSize,
                    height: iconBoxSize,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Icon(icon, color: scheme.primary, size: iconSize),
                  ),
                  Icon(Icons.arrow_outward_rounded,
                      color: scheme.outline, size: arrowSize),
                ],
              ),
              SizedBox(height: isCompact ? 10.h : 12.h),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.textTheme.bodySmall?.color,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4.h),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: valueFontSize,
                    color: scheme.onSurface,
                  ),
                  maxLines: 1,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                SizedBox(height: isCompact ? 8.h : 10.h),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    fontSize: subtitleFontSize,
                  ),
                  maxLines: isCompact ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
