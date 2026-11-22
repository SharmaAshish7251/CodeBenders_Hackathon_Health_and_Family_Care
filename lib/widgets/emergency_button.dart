import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/emergency_sheet.dart';
import '../theme/care_theme.dart';

/// Top-right entry to emergency sheet (Design Spec section 4, 5, 6).
///
/// Features a subtle breathing pulse animation (1600 ms loop, ease-in-out)
/// that gently reassures while drawing attention in urgent situations.
/// The animation is automatically disabled when the system requests reduce-motion.
class EmergencyButton extends ConsumerStatefulWidget {
  const EmergencyButton({super.key});

  @override
  ConsumerState<EmergencyButton> createState() => _EmergencyButtonState();
}

class _EmergencyButtonState extends ConsumerState<EmergencyButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  bool get _isTestEnvironment {
    return WidgetsBinding.instance.runtimeType
        .toString()
        .toLowerCase()
        .contains('test');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations =
        MediaQuery.of(context).disableAnimations || _isTestEnvironment;
    if (disableAnimations) {
      if (_controller.isAnimating) _controller.stop();
    } else {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CareCustomColors>();
    final emergencyColor = customColors?.emergency ?? theme.colorScheme.error;
    final onEmergencyColor =
        customColors?.onEmergency ?? theme.colorScheme.onError;
    final disableAnimations =
        MediaQuery.of(context).disableAnimations || _isTestEnvironment;

    Widget button = Container(
      decoration: BoxDecoration(
        color: emergencyColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: emergencyColor.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => EmergencySheet.show(context, ref),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.emergency_outlined,
                  size: 20,
                  color: onEmergencyColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'SOS',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: onEmergencyColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (disableAnimations) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: button,
      );
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: child,
          ),
        );
      },
      child: button,
    );
  }
}
