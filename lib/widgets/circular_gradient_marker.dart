import 'package:flutter/material.dart';
import 'dart:math' as math;

class CircularGradientMarker extends CustomPainter {
  final double intensity;
  final int reportCount;

  CircularGradientMarker({
    required this.intensity,
    required this.reportCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2;

    // Draw multiple gradient layers for a smoother effect
    for (int i = 6; i >= 0; i--) {
      final radius = maxRadius * (0.4 + (i * 0.1) * intensity);
      final opacity = 0.2 + (0.1 * i) * intensity;

      // Create gradient from red to yellow
      final gradient = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          Colors.red.withOpacity(opacity),
          Colors.yellow.withOpacity(opacity * 0.7),
        ],
        stops: [0.0, 1.0],
      );

      final paint = Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: radius),
        )
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * intensity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, radius, paint);
    }

    final centerRadius = maxRadius * 0.3;
    final centerColor = Color.lerp(
      Colors.yellow,
      Colors.red,
      intensity,
    )!
        .withOpacity(0.8);

    final centerPaint = Paint()
      ..color = centerColor
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(center, centerRadius, centerPaint);
  }

  @override
  bool shouldRepaint(CircularGradientMarker oldDelegate) {
    return oldDelegate.intensity != intensity ||
        oldDelegate.reportCount != reportCount;
  }
}
