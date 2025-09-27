import 'package:flutter/material.dart';

class ResponsiveUtils {
  // Breakpoints
  static const double mobileBreakpoint = 768;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1200;
  
  // Device type detection
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }
  
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }
  
  static bool isWeb(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }
  
  // Get responsive values
  static T getResponsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }
  
  // Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    return getResponsiveValue(
      context,
      mobile: const EdgeInsets.all(16),
      tablet: const EdgeInsets.all(24),
      desktop: const EdgeInsets.all(32),
    );
  }
  
  // Get responsive font sizes
  static double getResponsiveFontSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return getResponsiveValue(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
  
  // Get responsive grid columns
  static int getResponsiveGridColumns(BuildContext context) {
    return getResponsiveValue(
      context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );
  }
  
  // Get responsive card width
  static double getResponsiveCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return getResponsiveValue(
      context,
      mobile: screenWidth - 32,
      tablet: (screenWidth - 64) / 2,
      desktop: (screenWidth - 96) / 3,
    );
  }
  
  // Get responsive sidebar width
  static double getResponsiveSidebarWidth(BuildContext context) {
    return getResponsiveValue(
      context,
      mobile: MediaQuery.of(context).size.width * 0.8,
      tablet: 300,
      desktop: 350,
    );
  }
  
  // Get responsive content width for forms
  static double getResponsiveFormWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return getResponsiveValue(
      context,
      mobile: screenWidth - 32,
      tablet: screenWidth * 0.7,
      desktop: 600,
    );
  }
  
  // Get responsive margin
  static EdgeInsets getResponsiveMargin(BuildContext context) {
    return getResponsiveValue(
      context,
      mobile: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      tablet: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      desktop: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    );
  }
  
  // Get responsive icon size
  static double getResponsiveIconSize(BuildContext context) {
    return getResponsiveValue(
      context,
      mobile: 20,
      tablet: 24,
      desktop: 28,
    );
  }
  
  // Get responsive button height
  static double getResponsiveButtonHeight(BuildContext context) {
    return getResponsiveValue(
      context,
      mobile: 48,
      tablet: 52,
      desktop: 56,
    );
  }
  
  // Get responsive app bar height
  static double getResponsiveAppBarHeight(BuildContext context) {
    return getResponsiveValue(
      context,
      mobile: kToolbarHeight,
      tablet: kToolbarHeight + 8,
      desktop: kToolbarHeight + 16,
    );
  }
  
  // Check if should use layout direction (for split views)
  static bool shouldUseSplitView(BuildContext context) {
    return isTablet(context) || isDesktop(context);
  }
  
  // Get responsive question navigation button size
  static double getQuestionNavButtonSize(BuildContext context, int totalQuestions) {
    final baseSize = getResponsiveValue(
      context,
      mobile: 40.0,
      tablet: 45.0,
      desktop: 50.0,
    );
    
    // Adjust based on number of questions
    if (totalQuestions > 50) {
      return baseSize * 0.7;
    } else if (totalQuestions > 25) {
      return baseSize * 0.85;
    }
    return baseSize;
  }
  
  // Get responsive dialog width
  static double getResponsiveDialogWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return getResponsiveValue(
      context,
      mobile: screenWidth * 0.9,
      tablet: screenWidth * 0.7,
      desktop: 500,
    );
  }
  
  // Get responsive layout type
  static ResponsiveLayoutType getLayoutType(BuildContext context) {
    if (isMobile(context)) {
      return ResponsiveLayoutType.mobile;
    } else if (isTablet(context)) {
      return ResponsiveLayoutType.tablet;
    } else {
      return ResponsiveLayoutType.desktop;
    }
  }
}

enum ResponsiveLayoutType {
  mobile,
  tablet,
  desktop,
}

// Responsive layout builder widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ResponsiveLayoutType layoutType) builder;
  final Widget? mobile;
  final Widget? tablet;
  final Widget? desktop;
  
  const ResponsiveBuilder({
    super.key,
    required this.builder,
    this.mobile,
    this.tablet,
    this.desktop,
  });
  
  @override
  Widget build(BuildContext context) {
    final layoutType = ResponsiveUtils.getLayoutType(context);
    
    if (mobile != null || tablet != null || desktop != null) {
      switch (layoutType) {
        case ResponsiveLayoutType.mobile:
          return mobile ?? tablet ?? desktop ?? const SizedBox();
        case ResponsiveLayoutType.tablet:
          return tablet ?? desktop ?? mobile ?? const SizedBox();
        case ResponsiveLayoutType.desktop:
          return desktop ?? tablet ?? mobile ?? const SizedBox();
      }
    }
    
    return builder(context, layoutType);
  }
}

// Responsive card widget
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? elevation;
  
  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation ?? (ResponsiveUtils.isDesktop(context) ? 4 : 2),
      margin: margin ?? ResponsiveUtils.getResponsiveMargin(context),
      child: Padding(
        padding: padding ?? ResponsiveUtils.getResponsivePadding(context),
        child: child,
      ),
    );
  }
}

// Responsive container with max width
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.margin,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? ResponsiveUtils.getResponsiveFormWidth(context),
      ),
      padding: padding ?? ResponsiveUtils.getResponsivePadding(context),
      margin: margin ?? ResponsiveUtils.getResponsiveMargin(context),
      child: child,
    );
  }
}


