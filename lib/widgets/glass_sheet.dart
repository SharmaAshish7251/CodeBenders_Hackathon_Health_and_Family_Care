import 'dart:ui';

import 'package:flutter/material.dart';

/// Translucent overlay surface for the dark theme (Design Spec section 3.2).
///
/// Use for overlays only (bottom sheets, dialogs, popovers), never for lists
/// or long body text. Falls back to a solid surface when the theme is not
/// dark, or when the platform requests reduced animations or high contrast.
class GlassSheet extends StatelessWidget {
  const GlassSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  static const double _blurSigma = 16;
  static const double _glassOpacity = 0.75;
  static const double _borderOpacity = 0.12;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final media = MediaQuery.maybeOf(context);

    final solidFallback = theme.brightness != Brightness.dark ||
        (media?.disableAnimations ?? false) ||
        (media?.highContrast ?? false);

    final border = Border.all(
      color: scheme.onSurface.withValues(alpha: _borderOpacity),
      width: 1,
    );

    if (solidFallback) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          border: border,
          borderRadius: borderRadius,
        ),
        child: child,
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: scheme.surfaceContainer.withValues(alpha: _glassOpacity),
            border: border,
            borderRadius: borderRadius,
          ),
          child: child,
        ),
      ),
    );
  }
}
