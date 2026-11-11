import 'package:flutter/material.dart';

import 'color_schemes.dart';
import 'semantic_colors.dart';
import 'status_colors.dart';
import 'typography.dart';
import 'tokens.dart';

ThemeData _buildTheme(
  ColorScheme scheme,
  KkfcSemanticColors semantic,
  KkfcStatusColors status,
) {
  OutlineInputBorder inputBorder(Color color, double width) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(KkfcRadius.md),
        borderSide: BorderSide(color: color, width: width),
      );

  return ThemeData(
    useMaterial3: true,
    fontFamily: KkfcFonts.schibstedGrotesk,
    colorScheme: scheme,
    textTheme: kkfcTextTheme,
    scaffoldBackgroundColor: semantic.bgCanvas,
    extensions: [semantic, status],
    dividerColor: semantic.borderDefault,
    dividerTheme: DividerThemeData(
      color: semantic.borderDefault,
      thickness: KkfcBorderWidth.thin,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: semantic.bgSurface,
      border: inputBorder(semantic.borderStrong, KkfcBorderWidth.thin),
      enabledBorder: inputBorder(semantic.borderStrong, KkfcBorderWidth.thin),
      focusedBorder: inputBorder(semantic.borderFocus, KkfcBorderWidth.focus),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(
          Size(0, KkfcSizing.controlMd),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KkfcRadius.md),
          ),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return null;
          }
          if (states.contains(WidgetState.pressed)) {
            return semantic.actionPressed;
          }
          if (states.contains(WidgetState.hovered)) {
            return semantic.actionHover;
          }
          return semantic.action;
        }),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
      ),
    ),
  );
}

final ThemeData counterTheme = _buildTheme(
  kkfcCounterScheme,
  KkfcSemanticColors.light,
  KkfcStatusColors.light,
);

final ThemeData kitchenTheme = _buildTheme(
  kkfcKitchenScheme,
  KkfcSemanticColors.dark,
  KkfcStatusColors.dark,
);
