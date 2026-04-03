import 'package:flutter/material.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.bottom,
    this.showBack = true,
    this.subtitle,
    this.header,
    this.floatingActionButton,
    this.headerImageAsset,
    this.pageBackgroundAsset,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool showBack;
  final String? subtitle;
  final Widget? header;
  final Widget? floatingActionButton;
  final String? headerImageAsset;
  final String? pageBackgroundAsset;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 560;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: showBack,
        title: Text(title),
        actions: actions,
        bottom: bottom,
      ),
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            image: pageBackgroundAsset == null
                ? null
                : DecorationImage(
                    image: AssetImage(pageBackgroundAsset!),
                    fit: BoxFit.cover,
                    opacity: 0.05,
                  ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Padding(
                padding: EdgeInsets.fromLTRB(compact ? 16 : 24, 8, compact ? 16 : 24, compact ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (subtitle != null || header != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: _ShellHeaderCard(
                          title: title,
                          subtitle: subtitle,
                          header: header,
                          compact: compact,
                          headerImageAsset: headerImageAsset,
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
    );
  }
}

class _ShellHeaderCard extends StatelessWidget {
  const _ShellHeaderCard({
    required this.title,
    required this.subtitle,
    required this.header,
    required this.compact,
    required this.headerImageAsset,
  });

  final String title;
  final String? subtitle;
  final Widget? header;
  final bool compact;
  final String? headerImageAsset;

  @override
  Widget build(BuildContext context) {
    final hasImage = headerImageAsset != null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8F5E9)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 6),
            color: Color(0x080F172A),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
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
                    colors: hasImage
                        ? [
                            Colors.white,
                            Colors.white.withValues(alpha: 0.95),
                            Colors.white.withValues(alpha: 0.72),
                          ]
                        : [Colors.white, Colors.white],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(compact ? 24 : 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: hasImage && !compact ? 560 : double.infinity),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(height: 1.1, fontWeight: FontWeight.w800),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: const Color(0xFF64748B)),
                      ),
                    ],
                    if (header != null) ...[
                      const SizedBox(height: 24),
                      header!,
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
