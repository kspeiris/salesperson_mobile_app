import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.height = 72,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    this.showPlate = true,
    this.alignment = Alignment.centerLeft,
  });

  final double height;
  final EdgeInsetsGeometry padding;
  final bool showPlate;
  final Alignment alignment;

  static const String assetPath = 'biocare logo1.png';

  @override
  Widget build(BuildContext context) {
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 12,
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
