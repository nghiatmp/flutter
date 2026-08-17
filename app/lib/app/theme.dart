import 'package:flutter/material.dart';

/// Theme dùng chung cho toàn app.
/// Hầu hết widget đọc style qua Theme.of(context) nên sửa ở đây sẽ áp dụng
/// đồng loạt cho mọi màn hình, không cần sửa từng nơi.
ThemeData buildAppTheme({Brightness brightness = Brightness.light}) {
  final isDark = brightness == Brightness.dark;
  const primary = Color(0xFFC7658A);
  const secondary = Color(0xFF86B7A8);
  const tertiary = Color(0xFF9A8BC4);
  final surface = isDark ? const Color(0xFF211A1E) : const Color(0xFFFBF6F3);
  final surfaceContainer = isDark
      ? const Color(0xFF33282E)
      : const Color(0xFFF4EEEA);
  final outline = isDark ? const Color(0xFF55444C) : const Color(0xFFEAE0DB);
  final ink = isDark ? const Color(0xFFF8EDF2) : const Color(0xFF3D2A32);
  final cardColor = isDark ? const Color(0xFF2B2227) : Colors.white;

  /// Một scale bo góc duy nhất cho toàn app: phần tử càng lớn thì bo góc
  /// càng rộng, tạo cảm giác mềm mại đồng bộ thay vì mỗi nơi một kiểu.
  const radiusInput = 16.0;
  const radiusButton = 18.0;
  const radiusCard = 22.0;

  final colorScheme =
      ColorScheme.fromSeed(seedColor: primary, brightness: brightness).copyWith(
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: isDark
            ? const Color(0xFF61344A)
            : const Color(0xFFF7DCE7),
        onPrimaryContainer: isDark
            ? const Color(0xFFFFE8F1)
            : const Color(0xFF522438),
        secondary: secondary,
        onSecondary: Colors.white,
        secondaryContainer: isDark
            ? const Color(0xFF314D46)
            : const Color(0xFFDDEFE9),
        onSecondaryContainer: isDark
            ? const Color(0xFFE5FFF7)
            : const Color(0xFF24483F),
        tertiary: tertiary,
        onTertiary: isDark ? Colors.white : const Color(0xFF143B32),
        tertiaryContainer: isDark
            ? const Color(0xFF463D5D)
            : const Color(0xFFE8E3F6),
        surface: surface,
        surfaceContainerHighest: surfaceContainer,
        outline: outline,
      );

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: surface,
    textTheme: Typography.blackCupertino.apply(
      bodyColor: ink,
      displayColor: ink,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: surface,
      surfaceTintColor: primary,
      foregroundColor: ink,
      titleTextStyle: TextStyle(
        color: ink,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: const IconThemeData(color: primary),
      actionsIconTheme: const IconThemeData(color: primary),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 74,
      elevation: 3,
      backgroundColor: cardColor,
      surfaceTintColor: cardColor,
      shadowColor: primary.withValues(alpha: 0.14),
      indicatorColor: isDark
          ? const Color(0xFF61344A)
          : const Color(0xFFF3D7E3),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return TextStyle(
          color: isSelected
              ? primary
              : (isDark ? const Color(0xFFBBA8B1) : const Color(0xFF8C7A83)),
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: isSelected
              ? primary
              : (isDark ? const Color(0xFFBBA8B1) : const Color(0xFF9C8790)),
        );
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: BorderSide(color: outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: BorderSide(color: outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: const BorderSide(color: primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: BorderSide(color: colorScheme.error, width: 1.8),
      ),
      filled: true,
      fillColor: surfaceContainer,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),
      prefixIconColor: primary,
      floatingLabelStyle: const TextStyle(
        color: primary,
        fontWeight: FontWeight.w700,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,

        /// Chỉ ép chiều cao, không ép chiều rộng (Size.fromHeight sẽ set
        /// width = infinity, phá layout của bất kỳ ElevatedButton nào không
        /// nằm trong Column co giãn — kể cả nút nội bộ của package khác
        /// như Chucker).
        minimumSize: const Size(64, 52),
        elevation: 1,
        shadowColor: primary.withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusButton),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        minimumSize: const Size(64, 52),
        side: BorderSide(color: outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusButton),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusButton),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: primary),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: primary),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected) ? primary : Colors.white;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? primary.withValues(alpha: 0.32)
            : outline;
      }),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shadowColor: primary.withValues(alpha: 0.14),
      color: cardColor,
      surfaceTintColor: cardColor,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusCard),
      ),
    ),
    dividerTheme: DividerThemeData(color: outline),
    listTileTheme: ListTileThemeData(
      iconColor: primary,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 10,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusCard),
      ),
    ),
  );
}
