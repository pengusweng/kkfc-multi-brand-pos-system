import 'package:flutter/material.dart';

/// Font families used in the app.
///
/// Schibsted Grotesk (SIL OFL 1.1), self-hosted in the app across all roles.
abstract final class KkfcFonts {
  /// Primary Schibsted Grotesk font family used across the app.
  static const schibstedGrotesk = 'Schibsted_Grotesk';

  /// Display / UI font family (aliased to Schibsted_Grotesk).
  static const ibmPlexSans = 'Schibsted_Grotesk';

  /// Tabular numerals for money, times, and quantities.
  static const numeric = 'Schibsted_Grotesk';

  /// General text font family.
  static const text = 'Schibsted_Grotesk';

  /// Reference and code font family.
  static const mono = 'Schibsted_Grotesk';

  /// System font stack alias.
  static const systemMono = 'Schibsted_Grotesk';
}

/// Font weights specified in the design system:
/// Weights: 400, 500, 600, 680 (Bold in Figma -> FontWeight.w700).
abstract final class KkfcFontWeights {
  static const regular = FontWeight.w400;
  static const medium = FontWeight.w500;
  static const semiBold = FontWeight.w600;
  static const bold = FontWeight.w700; // 680 in Figma
}

/// Tabular digits keep columns aligned; slashed zero separates 0 from O.
/// Used for money, times, and quantities.
const tabularNumberFeatures = [
  FontFeature.tabularFigures(),
  FontFeature.slashedZero(),
];

TextStyle _style(
  String family,
  FontWeight weight,
  double size,
  double lineHeight,
  double letterSpacing, {
  List<FontFeature>? features,
}) {
  return TextStyle(
    fontFamily: family,
    fontWeight: weight,
    fontSize: size,
    height: lineHeight / size,
    letterSpacing: letterSpacing,
    fontFeatures: features,
  );
}

/// Token constants for type scale sizes matching the design system:
/// Fixed rem scale at about 1.15; no fluid headings in operational UI.
abstract final class KkfcTextSizes {
  /// `--k-text-3xl`: 30px (Sign-in display)
  static const double text3xl = 30.0;

  /// `--k-text-2xl`: 24px (Page titles)
  static const double text2xl = 24.0;

  /// `--k-text-xl`: 20px (Card and sheet titles)
  static const double textXl = 20.0;

  /// `--k-text-lg`: 18px (Section titles)
  static const double textLg = 18.0;

  /// `--k-text-base`: 16px (POS body, inputs - prevents iOS zoom)
  static const double textBase = 16.0;

  /// `--k-text-md`: 14px (Web body, table cells)
  static const double textMd = 14.0;

  /// `--k-text-sm`: 13px (Dense table meta)
  static const double textSm = 13.0;

  /// `--k-text-xs`: 12px (Captions, meta minimum)
  static const double textXs = 12.0;
}

abstract final class KkfcTypography {
  // --- New Typography Scale (Fixed rem ~1.15) ---

  /// `--k-text-3xl`: 30px, Bold (Sign-in display)
  static final text3xl = _style(
    KkfcFonts.ibmPlexSans,
    KkfcFontWeights.bold,
    KkfcTextSizes.text3xl,
    36,
    0,
  );

  /// `--k-text-2xl`: 24px, Bold (Page titles)
  static final text2xl = _style(
    KkfcFonts.ibmPlexSans,
    KkfcFontWeights.bold,
    KkfcTextSizes.text2xl,
    32,
    0,
  );

  /// `--k-text-xl`: 20px, Bold (Card and sheet titles)
  static final textXl = _style(
    KkfcFonts.ibmPlexSans,
    KkfcFontWeights.bold,
    KkfcTextSizes.textXl,
    28,
    0,
  );

  /// `--k-text-lg`: 18px, Bold (Section titles)
  static final textLg = _style(
    KkfcFonts.ibmPlexSans,
    KkfcFontWeights.bold,
    KkfcTextSizes.textLg,
    26,
    0,
  );

  /// `--k-text-base`: 16px, Regular (POS body, inputs - prevents iOS zoom)
  static final textBase = _style(
    KkfcFonts.ibmPlexSans,
    KkfcFontWeights.regular,
    KkfcTextSizes.textBase,
    24,
    0,
  );

  /// `--k-text-md`: 14px, Regular (Web body, table cells)
  static final textMd = _style(
    KkfcFonts.ibmPlexSans,
    KkfcFontWeights.regular,
    KkfcTextSizes.textMd,
    20,
    0,
  );

  /// `--k-text-sm`: 13px, Regular (Dense table meta)
  static final textSm = _style(
    KkfcFonts.ibmPlexSans,
    KkfcFontWeights.regular,
    KkfcTextSizes.textSm,
    18,
    0,
  );

  /// `--k-text-xs`: 12px, Regular (Captions, meta minimum)
  static final textXs = _style(
    KkfcFonts.ibmPlexSans,
    KkfcFontWeights.regular,
    KkfcTextSizes.textXs,
    16,
    0,
  );

  // --- Tabular variants for numbers, money, times, quantities ---

  /// Helper to apply tabular numerals (tabularFigures and slashedZero) to any style.
  static TextStyle withTabular(TextStyle style) {
    return style.copyWith(fontFeatures: tabularNumberFeatures);
  }

  // --- Operational / Kitchen Display Styles ---

  /// Kitchen display ticket number (read from 1 to 1.5 m)
  static final kdsTicket = _style(
    KkfcFonts.numeric,
    KkfcFontWeights.bold,
    48,
    52,
    0,
    features: tabularNumberFeatures,
  );

  /// Kitchen display timer
  static final kdsTimer = _style(
    KkfcFonts.numeric,
    KkfcFontWeights.semiBold,
    32,
    36,
    0,
    features: tabularNumberFeatures,
  );

  static final kdsItem = _style(
    KkfcFonts.text,
    KkfcFontWeights.semiBold,
    24,
    30,
    0,
  );

  static final kdsModifier = _style(
    KkfcFonts.text,
    KkfcFontWeights.medium,
    20,
    26,
    0,
  );

  // Four-lane kitchen board
  static final kdsTicketCompact = _style(
    KkfcFonts.numeric,
    KkfcFontWeights.bold,
    32,
    36,
    0,
    features: tabularNumberFeatures,
  );

  static final kdsTimerCompact = _style(
    KkfcFonts.numeric,
    KkfcFontWeights.semiBold,
    22,
    28,
    0,
    features: tabularNumberFeatures,
  );

  static final kdsItemCompact = _style(
    KkfcFonts.text,
    KkfcFontWeights.semiBold,
    18,
    24,
    0,
  );

  static final kdsModifierCompact = _style(
    KkfcFonts.text,
    KkfcFontWeights.medium,
    16,
    22,
    0,
  );

  static final kdsGroup = _style(
    KkfcFonts.text,
    KkfcFontWeights.bold,
    20,
    26,
    0,
  );

  static final kdsGroupCompact = _style(
    KkfcFonts.text,
    KkfcFontWeights.bold,
    16,
    22,
    0,
  );

  // --- Aliases & Semantic Roles ---

  /// Sign-in display (`--k-text-3xl`)
  static final display = text3xl;

  /// Page titles (`--k-text-2xl`)
  static final headline = text2xl;

  /// Card and sheet titles (`--k-text-xl`)
  static final title = textXl;

  /// Section titles (`--k-text-lg`)
  static final sectionTitle = textLg;

  /// Large body text
  static final bodyLg = _style(
    KkfcFonts.ibmPlexSans,
    KkfcFontWeights.regular,
    KkfcTextSizes.textLg,
    26,
    0,
  );

  /// Primary POS body / inputs (`--k-text-base`)
  static final body = textBase;

  /// Web body, table cells (`--k-text-md`)
  static final bodyMd = textMd;

  /// Dense table meta (`--k-text-sm`)
  static final bodySm = textSm;

  static final labelLg = _style(
    KkfcFonts.ibmPlexSans,
    KkfcFontWeights.semiBold,
    16,
    24,
    0.2,
  );

  static final label = _style(
    KkfcFonts.ibmPlexSans,
    KkfcFontWeights.semiBold,
    14,
    20,
    0.2,
  );

  /// Captions, meta (`--k-text-xs`)
  static final caption = textXs;

  /// Price display with tabular figures
  static final price = _style(
    KkfcFonts.numeric,
    KkfcFontWeights.semiBold,
    18,
    24,
    0,
    features: tabularNumberFeatures,
  );

  /// Monospace for codes only (the app uses system mono stack)
  static final reference = _style(
    KkfcFonts.mono,
    KkfcFontWeights.medium,
    16,
    22,
    0,
  );
}

/// Maps Material's text roles to the design's type scale.
final TextTheme kkfcTextTheme = TextTheme(
  displayLarge: KkfcTypography.text3xl, // 30px Bold (Sign-in display)
  headlineLarge: KkfcTypography.text3xl,
  headlineMedium: KkfcTypography.text2xl, // 24px Bold (Page titles)
  headlineSmall: KkfcTypography.textXl, // 20px Bold (Card and sheet titles)
  titleLarge: KkfcTypography.textXl, // 20px Bold
  titleMedium: KkfcTypography.textLg, // 18px Bold (Section titles)
  titleSmall: KkfcTypography.kdsGroupCompact, // 16px Bold
  bodyLarge: KkfcTypography.textBase, // 16px Regular (POS body, inputs)
  bodyMedium: KkfcTypography.textMd, // 14px Regular (Web body, table cells)
  bodySmall: KkfcTypography.textXs, // 12px Regular (Captions, meta minimum)
  labelLarge: KkfcTypography.labelLg, // 16px SemiBold
  labelMedium: KkfcTypography.label, // 14px SemiBold
  labelSmall: KkfcTypography.caption, // 12px Regular
);
