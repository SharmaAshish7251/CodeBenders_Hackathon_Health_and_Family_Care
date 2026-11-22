import 'package:flutter/material.dart';

/// Semantic colors beyond standard Material 3 colorScheme
/// as specified in Design Spec section 3.1.
class CareCustomColors extends ThemeExtension<CareCustomColors> {
  const CareCustomColors({
    required this.emergency,
    required this.onEmergency,
    required this.warning,
    required this.onWarning,
    required this.success,
    required this.onSuccess,
  });

  final Color emergency;
  final Color onEmergency;
  final Color warning;
  final Color onWarning;
  final Color success;
  final Color onSuccess;

  @override
  CareCustomColors copyWith({
    Color? emergency,
    Color? onEmergency,
    Color? warning,
    Color? onWarning,
    Color? success,
    Color? onSuccess,
  }) {
    return CareCustomColors(
      emergency: emergency ?? this.emergency,
      onEmergency: onEmergency ?? this.onEmergency,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
    );
  }

  @override
  CareCustomColors lerp(ThemeExtension<CareCustomColors>? other, double t) {
    if (other is! CareCustomColors) return this;
    return CareCustomColors(
      emergency: Color.lerp(emergency, other.emergency, t)!,
      onEmergency: Color.lerp(onEmergency, other.onEmergency, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
    );
  }
}

/// Exact color tokens from Design Spec section 3.1.
class CareTheme {
  const CareTheme._();

  static const lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF2F6F6A),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFEEF4F3),
    onPrimaryContainer: Color(0xFF171D1C),
    secondary: Color(0xFF4B6563),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE7EFED),
    onSecondaryContainer: Color(0xFF171D1C),
    tertiary: Color(0xFF4D5D7A),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFE0E9E7),
    onTertiaryContainer: Color(0xFF171D1C),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFF7FAF9),
    onSurface: Color(0xFF171D1C),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFEEF4F3),
    surfaceContainer: Color(0xFFE7EFED),
    surfaceContainerHigh: Color(0xFFE0E9E7),
    surfaceContainerHighest: Color(0xFFD9E3E1),
    onSurfaceVariant: Color(0xFF3F4947),
    outline: Color(0xFF6F7977),
    outlineVariant: Color(0xFFBEC8C6),
  );

  static const darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF8CD5CC),
    onPrimary: Color(0xFF00302C),
    primaryContainer: Color(0xFF1E2A2E),
    onPrimaryContainer: Color(0xFFDEE4E2),
    secondary: Color(0xFFB1CCC9),
    onSecondary: Color(0xFF1C3534),
    secondaryContainer: Color(0xFF263438),
    onSecondaryContainer: Color(0xFFDEE4E2),
    tertiary: Color(0xFFB5C6E9),
    onTertiary: Color(0xFF1E304C),
    tertiaryContainer: Color(0xFF263438),
    onTertiaryContainer: Color(0xFFDEE4E2),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF12191C), // Deep blue-grey, never pure black
    onSurface: Color(0xFFDEE4E2),
    surfaceContainerLowest: Color(0xFF0D1316),
    surfaceContainerLow: Color(0xFF1A2326),
    surfaceContainer: Color(0xFF1E2A2E),
    surfaceContainerHigh: Color(0xFF263438),
    surfaceContainerHighest: Color(0xFF2F3E42),
    onSurfaceVariant: Color(0xFFBEC8C6),
    outline: Color(0xFF899390),
    outlineVariant: Color(0xFF3F4947),
  );

  static const lightCustomColors = CareCustomColors(
    emergency: Color(0xFFC62828),
    onEmergency: Color(0xFFFFFFFF),
    warning: Color(0xFF8A5A00),
    onWarning: Color(0xFFFFFFFF),
    success: Color(0xFF1F6B3A),
    onSuccess: Color(0xFFFFFFFF),
  );

  static const darkCustomColors = CareCustomColors(
    emergency: Color(0xFFFF8A80),
    onEmergency: Color(0xFF5C0000),
    warning: Color(0xFFF5C15A),
    onWarning: Color(0xFF452B00),
    success: Color(0xFF8BD9A4),
    onSuccess: Color(0xFF003919),
  );

  /// Typography scale following Design Spec section 3.3.
  static TextTheme _buildTextTheme(ColorScheme scheme) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: scheme.onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: scheme.onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: scheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: scheme.onSurface,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.4, // At least 1.4 line-height for Devanagari clarity
        color: scheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.4,
        color: scheme.onSurfaceVariant,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: scheme.onSurface,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        color: scheme.onSurfaceVariant,
      ),
    );
  }

  static ThemeData light() {
    return _buildTheme(lightColorScheme, lightCustomColors);
  }

  static ThemeData dark() {
    return _buildTheme(darkColorScheme, darkCustomColors);
  }

  static ThemeData _buildTheme(
    ColorScheme scheme,
    CareCustomColors customColors,
  ) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: _buildTextTheme(scheme),
      extensions: [customColors],
      // Cards: corner radius 20, soft tonal elevation (Section 3.4)
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
      ),
      // Bottom sheets: corner radius 28 at the top (Section 3.4)
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainer,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
