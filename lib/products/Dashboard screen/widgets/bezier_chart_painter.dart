import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/recharge_bills_screens.dart';

class BezierChartPainter extends CustomPainter {
  final List<double> values;

  BezierChartPainter({this.values = const []});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryRed
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()..style = PaintingStyle.fill;

    List<Offset> points = [];

    if (values.isEmpty || values.every((v) => v == 0)) {
      // Default placeholder smooth curve if values list is empty or all 0s
      points = [
        Offset(0, size.height * 0.7),
        Offset(size.width * 0.25, size.height * 0.55),
        Offset(size.width * 0.5, size.height * 0.65),
        Offset(size.width * 0.75, size.height * 0.35),
        Offset(size.width, size.height * 0.45),
      ];
    } else {
      double maxVal = values.reduce(math.max);
      if (maxVal <= 0) maxVal = 1.0;

      final count = values.length;
      final stepX = count > 1 ? size.width / (count - 1) : size.width;

      for (int i = 0; i < count; i++) {
        final x = count > 1 ? i * stepX : size.width / 2;
        final norm = (values[i] / maxVal).clamp(0.0, 1.0);
        // Map 0 to bottom (0.85 * height), maxVal to top (0.15 * height)
        final y = size.height * 0.85 - (norm * (size.height * 0.70));
        points.add(Offset(x, y));
      }
    }

    if (points.isEmpty) return;

    final path = Path();
    final fillPath = Path();

    path.moveTo(points[0].dx, points[0].dy);
    fillPath.moveTo(points[0].dx, size.height);
    fillPath.lineTo(points[0].dx, points[0].dy);

    if (points.length == 1) {
      path.lineTo(size.width, points[0].dy);
      fillPath.lineTo(size.width, points[0].dy);
    } else {
      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
        final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);

        path.cubicTo(
          controlPoint1.dx, controlPoint1.dy,
          controlPoint2.dx, controlPoint2.dy,
          p1.dx, p1.dy,
        );
        fillPath.cubicTo(
          controlPoint1.dx, controlPoint1.dy,
          controlPoint2.dx, controlPoint2.dy,
          p1.dx, p1.dy,
        );
      }
    }

    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    const gradient = LinearGradient(
      colors: [
        Color.fromRGBO(237, 41, 42, 0.28),
        Color.fromRGBO(237, 41, 42, 0),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    fillPaint.shader = gradient.createShader(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Peak point highlight
    Offset peakPoint = points.first;
    for (var p in points) {
      if (p.dy < peakPoint.dy) {
        peakPoint = p;
      }
    }

    final outerHaloPaint = Paint()
      ..color = const Color.fromRGBO(237, 41, 42, 0.28)
      ..style = PaintingStyle.fill;
    final innerDotPaint = Paint()
      ..color = primaryRed
      ..style = PaintingStyle.fill;

    canvas.drawCircle(peakPoint, 10, outerHaloPaint);
    canvas.drawCircle(peakPoint, 4, innerDotPaint);
  }

  @override
  bool shouldRepaint(covariant BezierChartPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}
