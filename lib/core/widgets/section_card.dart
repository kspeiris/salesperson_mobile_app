import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.subtitle,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _SectionHeaderText(
                    title: title,
                    subtitle: subtitle,
                  ),
                ),
                if (trailing != null) ...[
                  SizedBox(width: 12.w),
                  trailing!,
                ],
              ],
            ),
            SizedBox(height: 16.h),
            child,
          ],
        ),
      ),
    );
  }
}

class _SectionHeaderText extends StatelessWidget {
  const _SectionHeaderText({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
                fontSize: 16.sp,
                letterSpacing: -0.2,
              ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: 4.h),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 12.sp),
          ),
        ],
      ],
    );
  }
}
