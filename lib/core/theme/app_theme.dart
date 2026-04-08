import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_sizes.dart';

class AppTheme {
  static ThemeData get lightTheme => _buildTheme(brightness: Brightness.light);

  static ThemeData get darkTheme => _buildTheme(brightness: Brightness.dark);

  static ThemeData _buildTheme({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;
    const primary = Color(0xFF93B620);
    const secondary = Color(0xFFB7CF3A);
    const tertiary = Color(0xFFDCE89A);
    final scaffold = isDark ? const Color(0xFF0D1510) : const Color(0xFFF8FDF8);
    final surface = isDark ? const Color(0xFF132019) : Colors.white;
    final surfaceHigh =
        isDark ? const Color(0xFF1A2A21) : const Color(0xFFF3FAF4);
    final textPrimary =
        isDark ? const Color(0xFFF3F8F3) : const Color(0xFF263238);
    final textMuted =
        isDark ? const Color(0xFF9FB3A5) : const Color(0xFF78909C);
    final outline = isDark ? const Color(0xFF294136) : const Color(0xFFE8F5E9);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
      surface: surface,
    );

    final baseTextTheme = GoogleFonts.interTextTheme(
      ThemeData(brightness: brightness).textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffold,
      visualDensity: VisualDensity.standard,
      textTheme: baseTextTheme.copyWith(
        displaySmall: baseTextTheme.displaySmall?.copyWith(
          fontSize: AppSizes.h1,
          fontWeight: FontWeight.w700,
          height: 1.1,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontSize: AppSizes.h2,
          fontWeight: FontWeight.w700,
          height: 1.1,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          fontSize: AppSizes.h3,
          fontWeight: FontWeight.w700,
          height: 1.15,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontSize: AppSizes.h4,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontSize: AppSizes.bodyLarge,
          fontWeight: FontWeight.w600,
          height: 1.25,
          color: textPrimary,
          letterSpacing: -0.2,
        ),
        titleSmall: baseTextTheme.titleSmall?.copyWith(
          fontSize: AppSizes.bodyMedium,
          fontWeight: FontWeight.w700,
          height: 1.25,
          color: textPrimary,
          letterSpacing: -0.1,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontSize: AppSizes.bodyLarge,
          height: 1.5,
          color: textPrimary,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontSize: AppSizes.bodyMedium,
          height: 1.5,
          color: textMuted,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          fontSize: AppSizes.bodySmall,
          height: 1.4,
          color: textMuted,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontSize: AppSizes.labelLarge,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        labelMedium: baseTextTheme.labelMedium?.copyWith(
          fontSize: AppSizes.labelMedium,
          fontWeight: FontWeight.w700,
          color: textMuted,
          letterSpacing: 0.2,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          color: textPrimary,
          fontSize: AppSizes.h4,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: isDark ? colorScheme.onSurface : primary,
          backgroundColor: surfaceHigh,
          minimumSize: Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: outline),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFFEEF7EF) : textPrimary,
        contentTextStyle: GoogleFonts.inter(
          color: isDark ? const Color(0xFF132019) : Colors.white,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        elevation: isDark ? 0 : 2,
        color: surface,
        surfaceTintColor: Colors.transparent,
        shadowColor:
            isDark ? Colors.black.withValues(alpha: 0.22) : const Color(0x0A93B620),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          side: BorderSide(color: outline),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding:
            EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge, vertical: 18),
        labelStyle: TextStyle(color: textMuted, fontWeight: FontWeight.w500),
        hintStyle: TextStyle(color: textMuted),
        prefixIconColor: primary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          borderSide:
              BorderSide(color: secondary.withValues(alpha: 0.6), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: Size.fromHeight(AppSizes.buttonHeight),
          backgroundColor: primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: EdgeInsets.symmetric(
              horizontal: AppSizes.paddingLarge, vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.buttonRadius)),
          textStyle: GoogleFonts.inter(
              fontSize: AppSizes.bodyLarge, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size.fromHeight(AppSizes.buttonHeight),
          backgroundColor: primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.buttonRadius)),
          textStyle: GoogleFonts.inter(
              fontSize: AppSizes.bodyMedium, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size.fromHeight(AppSizes.buttonHeight),
          foregroundColor: isDark ? colorScheme.onSurface : primary,
          side: BorderSide(
              color: isDark ? outline : const Color(0xFFC8DA67), width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.buttonRadius)),
          padding: EdgeInsets.symmetric(
              horizontal: AppSizes.paddingMedium, vertical: 14),
          textStyle: GoogleFonts.inter(
              fontSize: AppSizes.bodyMedium, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? colorScheme.secondary : primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceHigh,
        selectedColor:
            isDark ? const Color(0xFF3D4A19) : const Color(0xFFE7EFBE),
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFE7F6E8) : primary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: Colors.transparent),
      ),
      dividerTheme: DividerThemeData(space: 1, color: outline),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.cardRadius)),
        iconColor: isDark ? colorScheme.secondary : primary,
        contentPadding:
            EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium, vertical: 8),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        elevation: isDark ? 0 : 8,
        indicatorColor: primary.withValues(alpha: isDark ? 0.24 : 0.1),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: AppSizes.bodySmall,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? (isDark ? Colors.white : primary) : textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: AppSizes.iconSizeMedium,
            color: isSelected ? (isDark ? Colors.white : primary) : textMuted,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        extendedTextStyle:
            GoogleFonts.inter(fontSize: AppSizes.labelLarge, fontWeight: FontWeight.w700),
      ),
    );
  }
}

