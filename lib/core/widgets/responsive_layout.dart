import 'package:flutter/material.dart';

/// Responsive breakpoints for the app.
class Breakpoints {
  Breakpoints._();

  /// Compact: small tablets in portrait (600–899dp)
  static const double compact = 600;

  /// Medium: tablets, small desktops (900–1199dp)
  static const double medium = 900;

  /// Expanded: large desktops (1200dp+)
  static const double expanded = 1200;
}

/// Determines the current screen size category.
enum ScreenSize { compact, medium, expanded }

ScreenSize screenSizeOf(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= Breakpoints.expanded) return ScreenSize.expanded;
  if (width >= Breakpoints.medium) return ScreenSize.medium;
  return ScreenSize.compact;
}

/// A widget that builds different layouts based on available width.
///
/// Provide [compact], [medium], and [expanded] builders.
/// Falls back: expanded → medium → compact.
class ResponsiveLayout extends StatelessWidget {
  final Widget Function(BuildContext context) compact;
  final Widget Function(BuildContext context)? medium;
  final Widget Function(BuildContext context)? expanded;

  const ResponsiveLayout({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Breakpoints.expanded && expanded != null) {
          return expanded!(context);
        }
        if (constraints.maxWidth >= Breakpoints.medium && medium != null) {
          return medium!(context);
        }
        return compact(context);
      },
    );
  }
}

/// Responsive column count helper for grids.
int responsiveColumns(BuildContext context, {int compact = 1, int medium = 2, int expanded = 3}) {
  switch (screenSizeOf(context)) {
    case ScreenSize.compact:
      return compact;
    case ScreenSize.medium:
      return medium;
    case ScreenSize.expanded:
      return expanded;
  }
}
