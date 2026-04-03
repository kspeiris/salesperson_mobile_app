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
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool showBack;
  final String? subtitle;
  final Widget? header;
  final Widget? floatingActionButton;

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
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFE8F5E9)),
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 16,
                                offset: Offset(0, 4),
                                color: Color(0x050F172A),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(compact ? 24 : 32),
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
