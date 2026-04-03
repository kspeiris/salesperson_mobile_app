import 'dart:ui';

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
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        automaticallyImplyLeading: showBack,
        title: Text(title),
        actions: actions,
        bottom: bottom,
      ),
      floatingActionButton: floatingActionButton,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              image: pageBackgroundAsset == null
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
                    compact ? 16 : 24,
                    8,
                    compact ? 16 : 24,
                    (compact ? 16 : 24) +
                        MediaQuery.of(context).viewInsets.bottom,
                  ),
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
    final imageMinHeight = compact ? 176.0 : 224.0;
    final panelRadius = BorderRadius.circular(24);

    return Container(
      constraints: hasImage ? BoxConstraints(minHeight: imageMinHeight) : null,
      decoration: BoxDecoration(
        borderRadius: panelRadius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7FCF7), Color(0xFFEAF5EB)],
        ),
        border: Border.all(color: const Color(0xFFD6E7D8)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 28,
            offset: Offset(0, 14),
            color: Color(0x122E7D32),
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
                  alignment:
                      compact ? Alignment.centerRight : Alignment.centerRight,
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
                            const Color(0xFF1F6A36).withValues(alpha: 0.92),
                            const Color(0xFF3E9250).withValues(alpha: 0.58),
                            Colors.white.withValues(alpha: 0.06),
                          ]
                        : const [Color(0xFFF7FCF7), Color(0xFFEAF5EB)],
                  ),
                ),
              ),
            ),
            Positioned(
              right: compact ? -30 : -12,
              top: compact ? -20 : -12,
              child: Container(
                width: compact ? 120 : 160,
                height: compact ? 120 : 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.14),
                ),
              ),
            ),
            Positioned(
              left: compact ? -22 : -10,
              bottom: compact ? -42 : -54,
              child: Container(
                width: compact ? 100 : 136,
                height: compact ? 100 : 136,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF9FD9A9).withValues(alpha: 0.14),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(compact ? 18 : 22),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth:
                            hasImage ? (compact ? 238 : 430) : double.infinity,
                      ),
                      padding: EdgeInsets.all(compact ? 18 : 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        color: Colors.white
                            .withValues(alpha: hasImage ? 0.18 : 0.72),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.28),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 18,
                            offset: Offset(0, 10),
                            color: Color(0x120F172A),
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
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  height: 1.05,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              subtitle!,
                              maxLines: compact ? 4 : 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.84),
                                    height: 1.45,
                                  ),
                            ),
                          ],
                          if (header != null) ...[
                            const SizedBox(height: 20),
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
