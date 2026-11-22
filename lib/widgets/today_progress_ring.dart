import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Progress ring for today's tasks (Design Spec section 2, 4, 6).
///
/// Animates its arc to new values over 400 ms with an ease-out curve.
/// Center displays the completed count in Display type scale (40 sp, 600 weight).
class TodayProgressRing extends StatelessWidget {
  const TodayProgressRing({
    super.key,
    required this.completed,
    required this.total,
    this.size = 150,
    this.strokeWidth = 14,
  });

  final int completed;
  final int total;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    final progress = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;
    final isComplete = total > 0 && completed >= total;

    return Semantics(
      label: '$completed of $total tasks completed today',
      value: '${(progress * 100).toInt()}%',
      child: Center(
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress),
                duration: disableAnimations
                    ? Duration.zero
                    : const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                builder: (context, animatedValue, child) {
                  return CustomPaint(
                    size: Size(size, size),
                    painter: _RingPainter(
                      progress: animatedValue,
                      strokeWidth: strokeWidth,
                      backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      progressColor: isComplete
                          ? (theme.extension<dynamic>() != null
                              ? scheme.primary
                              : const Color(0xFF1F6B3A))
                          : scheme.primary,
                    ),
                  );
                },
              ),
              if (size < 90)
                Text(
                  '${(progress * 100).toInt()}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isComplete ? scheme.primary : scheme.onSurface,
                  ),
                )
              else
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$completed',
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: isComplete ? scheme.primary : scheme.onSurface,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'of $total done',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
  });

  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final fgPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
