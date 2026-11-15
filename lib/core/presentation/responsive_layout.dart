import 'package:flutter/material.dart';

/// Form factor categories for cross-platform UI adaptation.
enum FormFactor { compact, medium, expanded }

/// Breakpoints standard across tablets, mobile devices, and desktops.
class ResponsiveBreakpoints {
  static const double compactMax = 600.0;
  static const double mediumMax = 1024.0;
}

/// Extension on [BuildContext] for clean responsive layout checks.
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  FormFactor get formFactor {
    final width = screenWidth;
    if (width < ResponsiveBreakpoints.compactMax) {
      return FormFactor.compact;
    } else if (width < ResponsiveBreakpoints.mediumMax) {
      return FormFactor.medium;
    } else {
      return FormFactor.expanded;
    }
  }

  bool get isCompact => formFactor == FormFactor.compact;
  bool get isMedium => formFactor == FormFactor.medium;
  bool get isExpanded => formFactor == FormFactor.expanded;

  /// Returns recommended grid column count for notebook dashboard.
  int get recommendedGridColumns {
    final width = screenWidth;
    if (width < 500) return 1;
    if (width < 768) return 2;
    if (width < 1100) return 3;
    if (width < 1440) return 4;
    return 5;
  }
}

/// Adaptive layout builder widget providing form factor and constraints.
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    FormFactor formFactor,
    BoxConstraints constraints,
  )
  builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final FormFactor factor;
        if (width < ResponsiveBreakpoints.compactMax) {
          factor = FormFactor.compact;
        } else if (width < ResponsiveBreakpoints.mediumMax) {
          factor = FormFactor.medium;
        } else {
          factor = FormFactor.expanded;
        }

        return builder(context, factor, constraints);
      },
    );
  }
}

/// Declarative widget choosing between compact, medium, and expanded layouts.
class ResponsiveLayout extends StatelessWidget {
  final Widget compact;
  final Widget? medium;
  final Widget expanded;

  const ResponsiveLayout({
    super.key,
    required this.compact,
    this.medium,
    required this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, factor, constraints) {
        switch (factor) {
          case FormFactor.compact:
            return compact;
          case FormFactor.medium:
            return medium ?? expanded;
          case FormFactor.expanded:
            return expanded;
        }
      },
    );
  }
}
