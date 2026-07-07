import 'package:flutter/material.dart';

ThemeData buildAppTheme({Brightness brightness = Brightness.light}) {
  final isDark = brightness == Brightness.dark;
  const primary = Color(0xFFC7658A);
  const secondary = Color(0xFF86B7A8);
  const tertiary = Color(0xFF9A8BC4);
  final surface = isDark ? const Color(0xFF211A1E) : const Color(0xFFFCFAF8);
  final surfaceContainer = isDark
      ? const Color(0xFF33282E)
      : const Color(0xFFF4F0EC);
  final outline = isDark ? const Color(0xFF55444C) : const Color(0xFFE7DCD5);
  final ink = isDark ? const Color(0xFFF8EDF2) : const Color(0xFF402A34);
  final cardColor = isDark ? const Color(0xFF2B2227) : Colors.white;

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
      scrolledUnderElevation: 0,
      backgroundColor: surface,
      foregroundColor: ink,
      titleTextStyle: TextStyle(
        color: ink,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
      iconTheme: const IconThemeData(color: primary),
      actionsIconTheme: const IconThemeData(color: primary),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: cardColor,
      indicatorColor: isDark
          ? const Color(0xFF61344A)
          : const Color(0xFFF3D7E3),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return TextStyle(
          color: isSelected
              ? primary
              : (isDark ? const Color(0xFFBBA8B1) : const Color(0xFF6B7787)),
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: isSelected
              ? primary
              : (isDark ? const Color(0xFFBBA8B1) : const Color(0xFF8C6F7D)),
        );
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primary, width: 1.6),
      ),
      filled: true,
      fillColor: cardColor,
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
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
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
      elevation: 1,
      shadowColor: primary.withValues(alpha: 0.10),
      color: cardColor,
      surfaceTintColor: cardColor,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: outline),
      ),
    ),
    dividerTheme: DividerThemeData(color: outline),
    listTileTheme: const ListTileThemeData(
      iconColor: primary,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),
  );
}
