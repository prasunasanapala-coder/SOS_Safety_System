import 'package:flutter/widgets.dart';

/// Screen-size classes used across the app (Experiment 3).
enum ScreenSize { mobile, tablet, desktop }

class Breakpoints {
  const Breakpoints._();

  /// Width (logical pixels) from which a screen counts as a tablet.
  static const double tablet = 600;

  /// Width (logical pixels) from which a screen counts as desktop/browser.
  static const double desktop = 1024;

  /// Pure function so it can be unit tested without a widget tree.
  static ScreenSize fromWidth(double width) {
    if (width >= desktop) return ScreenSize.desktop;
    if (width >= tablet) return ScreenSize.tablet;
    return ScreenSize.mobile;
  }

  /// Reads the window width with MediaQuery (Experiment 3b).
  static ScreenSize of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  /// Page padding that grows with the screen size.
  static double pagePadding(ScreenSize size) {
    switch (size) {
      case ScreenSize.mobile:
        return 16;
      case ScreenSize.tablet:
        return 24;
      case ScreenSize.desktop:
        return 32;
    }
  }
}