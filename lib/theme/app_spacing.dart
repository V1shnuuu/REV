import 'package:flutter/widgets.dart';

/// 4pt-based spacing scale. Widgets use these instead of literal numbers so
/// rhythm stays consistent and a global density change is a one-file edit.
class AppSpacing {
  AppSpacing._();

  static const double none = 0;
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double massive = 48;
  static const double giant = 64;

  /// Standard horizontal page gutter.
  static const double pageGutter = xxl;

  // Common EdgeInsets, pre-built to avoid re-allocating in build().
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: pageGutter,
  );
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(md);
  static const EdgeInsets dialogPadding = EdgeInsets.all(xxl);

  /// Vertical gaps, pre-built as SizedBox for use in Column children.
  static const Widget gapXs = SizedBox(height: xs);
  static const Widget gapSm = SizedBox(height: sm);
  static const Widget gapMd = SizedBox(height: md);
  static const Widget gapLg = SizedBox(height: lg);
  static const Widget gapXl = SizedBox(height: xl);
  static const Widget gapXxl = SizedBox(height: xxl);
  static const Widget gapXxxl = SizedBox(height: xxxl);

  /// Horizontal gaps, for use in Row children.
  static const Widget hGapXs = SizedBox(width: xs);
  static const Widget hGapSm = SizedBox(width: sm);
  static const Widget hGapMd = SizedBox(width: md);
  static const Widget hGapLg = SizedBox(width: lg);
}

/// Minimum interactive target sizes. Platform floors are 44pt (iOS) and
/// 48dp (Android); [critical] is deliberately larger because the live CPR
/// controls are operated one-handed, under stress, possibly with wet hands.
class AppTouchTarget {
  AppTouchTarget._();

  static const double minimum = 48;
  static const double comfortable = 56;
  static const double critical = 64;
}
