import 'package:flutter/widgets.dart';

/// Simple breakpoint helpers so UI scales across phones, tablets, and desktop.
class ResponsiveLayout {
  static const double tabletWidth = 700;
  static const double desktopWidth = 1100;

  static bool isMobile(BuildContext context) => MediaQuery.sizeOf(context).width < tabletWidth;
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= tabletWidth && width < desktopWidth;
  }

  static bool isDesktop(BuildContext context) => MediaQuery.sizeOf(context).width >= desktopWidth;

  static T value<T>(BuildContext context, {required T mobile, required T tablet, required T desktop}) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }

  static double horizontalPadding(BuildContext context, {double mobile = 20, double tablet = 28, double desktop = 40}) {
    return value<double>(context, mobile: mobile, tablet: tablet, desktop: desktop);
  }

  static double verticalSpacing(BuildContext context, {double mobile = 12, double tablet = 16, double desktop = 20}) {
    return value<double>(context, mobile: mobile, tablet: tablet, desktop: desktop);
  }

  static int gridColumns(BuildContext context, {int mobile = 2, int tablet = 3, int desktop = 4}) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktopWidth) return desktop;
    if (width >= tabletWidth) return tablet;
    return mobile;
  }

  /// Constrains content to a readable width and centers it while keeping responsive side padding.
  static Widget constrain({required BuildContext context, required Widget child, double maxWidth = 1100}) {
    final horizontal = horizontalPadding(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontal),
          child: child,
        ),
      ),
    );
  }
}
