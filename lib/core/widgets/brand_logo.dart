import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.height = 72,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    this.showPlate = true,
    this.alignment = Alignment.centerLeft,
    this.plateDecoration,
  });

  final double height;
  final EdgeInsetsGeometry padding;
  final bool showPlate;
  final Alignment alignment;
  final BoxDecoration? plateDecoration;

  static const String lightAssetPath = 'assets/branding/biocare logo1.png';
  static const String darkAssetPath = 'assets/branding/biocare logo1_dark.png';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final assetPath =
        theme.brightness == Brightness.dark ? darkAssetPath : lightAssetPath;
    final image = Image.asset(
      assetPath,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return SizedBox(
          height: height,
          child: const Center(child: Icon(Icons.broken_image_outlined)),
        );
      },
    );

    Widget content = image;

    if (showPlate) {
      content = Container(
        padding: padding,
        decoration: plateDecoration ??
            BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.18 : 0.02,
                  ),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
        child: image,
      );
    }

    return Align(
      alignment: alignment,
      widthFactor: 1.0,
      heightFactor: 1.0,
      child: content,
    );
  }
}


