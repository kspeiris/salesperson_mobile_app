import 'dart:io';

import 'package:flutter/material.dart';

class SalespersonAvatar extends StatelessWidget {
  const SalespersonAvatar({
    super.key,
    required this.name,
    this.imagePath,
    this.size = 56,
    this.iconSize,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
  });

  final String name;
  final String? imagePath;
  final double size;
  final double? iconSize;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? scheme.primary.withValues(alpha: 0.10);
    final fg = foregroundColor ?? scheme.primary;
    final border = borderColor ?? Colors.white.withValues(alpha: 0.75);
    final path = imagePath?.trim() ?? '';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: Border.all(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: path.isNotEmpty
          ? Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _AvatarFallback(
                initials: _buildInitials(name),
                foregroundColor: fg,
                iconSize: iconSize ?? (size * 0.42),
              ),
            )
          : _AvatarFallback(
              initials: _buildInitials(name),
              foregroundColor: fg,
              iconSize: iconSize ?? (size * 0.42),
            ),
    );
  }

  String _buildInitials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) return 'BC';
    return parts.map((part) => part.substring(0, 1).toUpperCase()).join();
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({
    required this.initials,
    required this.foregroundColor,
    required this.iconSize,
  });

  final String initials;
  final Color foregroundColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: foregroundColor,
          fontWeight: FontWeight.w800,
          fontSize: iconSize * 0.52,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
