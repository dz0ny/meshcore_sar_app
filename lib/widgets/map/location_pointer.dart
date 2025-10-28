import 'package:flutter/material.dart';

/// A navigation arrow pointer that indicates the user's location and direction of travel.
///
/// The pointer consists of:
/// - An outer semi-transparent circle representing GPS accuracy
/// - An inner triangular arrow pointing in the direction of travel/heading
/// - Optional rotation based on compass or GPS heading
class LocationPointer extends StatelessWidget {
  /// The heading in degrees (0-360, where 0 = North, 90 = East)
  /// If null or -1, the pointer will not rotate
  final double? heading;

  /// The primary color for the pointer
  final Color color;

  /// The size of the entire widget
  final double size;

  const LocationPointer({
    super.key,
    this.heading,
    required this.color,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if we have valid heading data
    final hasValidHeading = heading != null && heading! >= 0;

    // Calculate rotation angle (convert heading to radians)
    final rotationAngle = hasValidHeading ? (heading! * 3.14159 / 180.0) : 0.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer accuracy circle (very subtle, uses theme color)
          Container(
            width: size * 0.6,
            height: size * 0.6,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
          ),
          // Inner rotatable arrow pointer (much larger - 90% of size)
          Transform.rotate(
            angle: rotationAngle,
            child: CustomPaint(
              size: Size(size * 0.9, size * 0.9),
              painter: _NavigationPointerPainter(
                color: color,
                hasValidHeading: hasValidHeading,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter that draws a navigation arrow pointer
class _NavigationPointerPainter extends CustomPainter {
  final Color color;
  final bool hasValidHeading;

  _NavigationPointerPainter({
    required this.color,
    required this.hasValidHeading,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final width = size.width;
    final height = size.height;

    if (hasValidHeading) {
      // Create navigation arrow with V-shaped cutout at bottom
      final arrowPath = Path();

      // Top point (sharp tip)
      arrowPath.moveTo(center.dx, height * 0.08);

      // Right side down to bottom right
      arrowPath.lineTo(center.dx + width * 0.42, height * 0.92);

      // V-cutout at bottom - right side to center
      arrowPath.lineTo(center.dx, height * 0.70);

      // V-cutout - center to left side
      arrowPath.lineTo(center.dx - width * 0.42, height * 0.92);

      // Left side back up to top
      arrowPath.lineTo(center.dx, height * 0.08);

      arrowPath.close();

      // Draw shadow for depth
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.save();
      canvas.translate(2, 2);
      canvas.drawPath(arrowPath, shadowPaint);
      canvas.restore();

      // Left side (lighter - 70% opacity of theme color)
      final leftSidePath = Path();
      leftSidePath.moveTo(center.dx, height * 0.08);
      leftSidePath.lineTo(center.dx - width * 0.42, height * 0.92);
      leftSidePath.lineTo(center.dx, height * 0.70);
      leftSidePath.close();

      final leftPaint = Paint()
        ..color = color.withValues(alpha: 0.7)
        ..style = PaintingStyle.fill;
      canvas.drawPath(leftSidePath, leftPaint);

      // Right side (darker - full theme color)
      final rightSidePath = Path();
      rightSidePath.moveTo(center.dx, height * 0.08);
      rightSidePath.lineTo(center.dx, height * 0.70);
      rightSidePath.lineTo(center.dx + width * 0.42, height * 0.92);
      rightSidePath.close();

      final rightPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawPath(rightSidePath, rightPaint);

      // Optional: Draw white border for contrast
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(arrowPath, borderPaint);

    } else {
      // No heading available - draw a circle with white border (uses theme color)
      final circlePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, width * 0.4, circlePaint);

      // White border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(center, width * 0.4, borderPaint);

      // Center white dot
      final centerDot = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, width * 0.15, centerDot);
    }
  }

  @override
  bool shouldRepaint(_NavigationPointerPainter oldDelegate) {
    return oldDelegate.color != color ||
           oldDelegate.hasValidHeading != hasValidHeading;
  }
}
