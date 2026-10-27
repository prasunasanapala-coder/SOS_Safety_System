import 'package:flutter/material.dart';

/// Central colour palette. Red is reserved for SOS actions only.
class AppColors {
  const AppColors._();

  static const Color brand = Color(0xFF1F4E79); // calm navy blue
  static const Color sos = Color(0xFFC62828); // reserved for SOS
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFEF6C00);
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color darkBackground = Color(0xFF10151B);
}

class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Shared custom styles (Experiment 6b).
class AppStyles {
  const AppStyles._();

  static const double radius = 16;

  static const BorderRadius borderRadius = BorderRadius.all(Radius.circular(radius));

  /// Same look for every text field in the app.
  static InputDecoration input(String label, {IconData? icon, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    );
  }

  /// Rounded card shape without elevation shadow noise.
  static RoundedRectangleBorder cardShape(BuildContext context) {
    return RoundedRectangleBorder(
      borderRadius: borderRadius,
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    );
  }
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? AppColors.lightBackground
          : AppColors.darkBackground,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}