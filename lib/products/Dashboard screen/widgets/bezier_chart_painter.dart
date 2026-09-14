import 'package:flutter/material.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/recharge_bills_screens.dart';

class BezierChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryRed
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    // Adjusted points to somewhat match the line shape in the image
    final points = [
      Offset(0, size.height * 0.7),
      Offset(size.width * 0.2, size.height * 0.55),
      Offset(size.width * 0.4, size.height * 0.65),
      Offset(size.width * 0.6, size.height * 0.35),
      Offset(size.width * 0.8, size.height * 0.45),
      Offset(size.width * 0.9, size.height * 0.3),
      Offset(size.width, size.height * 0.1),
    ];

    path.moveTo(points[0].dx, points[0].dy);
    fillPath.moveTo(points[0].dx, size.height);
    fillPath.lineTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
      fillPath.lineTo(points[i].dx, points[i].dy);
    }

    fillPath.lineTo(size.width, size.height);
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

    final peakPoint = points.last;
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
