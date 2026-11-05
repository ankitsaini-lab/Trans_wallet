import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/recharge_bills_screens.dart';

class BezierChartPainter extends CustomPainter {
  final List<double> values;
  final int? selectedIndex;
  final String? tooltipText;
  final Color lineColor;
  final String noDataMessage;

  BezierChartPainter({
    this.values = const [],
    this.selectedIndex,
    this.tooltipText,
    this.lineColor = primaryRed,
    this.noDataMessage = "No spending data for this period",
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bool hasNoData = values.isEmpty || values.every((v) => v == 0);

    final paint = Paint()
      ..color = hasNoData ? const Color(0xFFE2E8F0) : lineColor
      ..strokeWidth = hasNoData ? 2 : 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()..style = PaintingStyle.fill;

    List<Offset> points = [];

    if (hasNoData) {
      // Clean flat baseline at y = 0.85 * height (₹0) when no data from API
      final int count = values.isNotEmpty ? values.length : 4;
      final stepX = count > 1 ? size.width / (count - 1) : size.width;
      for (int i = 0; i < count; i++) {
        final x = count > 1 ? i * stepX : size.width / 2;
        points.add(Offset(x, size.height * 0.85));
      }
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

    final gradient = LinearGradient(
      colors: [
        lineColor.withValues(alpha: 0.28),
        lineColor.withValues(alpha: 0.0),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    fillPaint.shader = gradient.createShader(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );

    if (!hasNoData) {
      canvas.drawPath(fillPath, fillPaint);
    }
    canvas.drawPath(path, paint);

    // If there is no data, render a clean, subtle message in the chart area
    if (hasNoData) {
      final textSpan = TextSpan(
        text: noDataMessage,
        style: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(
          (size.width - textPainter.width) / 2,
          size.height * 0.35,
        ),
      );
    }

    // Draw subtle dots on all curve points
    final allDotsPaint = Paint()
      ..color = hasNoData
          ? const Color(0xFFCBD5E1)
          : lineColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < points.length; i++) {
      if (selectedIndex == null || i != selectedIndex) {
        canvas.drawCircle(points[i], 3, allDotsPaint);
      }
    }

    final outerHaloPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    final innerDotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    if (selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < points.length) {
      final selPoint = points[selectedIndex!];

      // Vertical dashed guideline to bottom
      final guidePaint = Paint()
        ..color = lineColor.withValues(alpha: 0.35)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      const double dashHeight = 4.0;
      const double dashSpace = 3.0;
      double startY = selPoint.dy;
      while (startY < size.height) {
        canvas.drawLine(
          Offset(selPoint.dx, startY),
          Offset(selPoint.dx, math.min(startY + dashHeight, size.height)),
          guidePaint,
        );
        startY += dashHeight + dashSpace;
      }

      // Highlight selected point with dual ring
      canvas.drawCircle(selPoint, 11, outerHaloPaint);
      canvas.drawCircle(
        selPoint,
        6,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(selPoint, 4, innerDotPaint);

      // Tooltip pill if text provided
      if (tooltipText != null && tooltipText!.isNotEmpty) {
        final textSpan = TextSpan(
          text: tooltipText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();

        const double hPadding = 8.0;
        const double vPadding = 4.0;
        final double bubbleWidth = textPainter.width + (hPadding * 2);
        final double bubbleHeight = textPainter.height + (vPadding * 2);

        final double bubbleCenterX = selPoint.dx.clamp(
          bubbleWidth / 2 + 4,
          size.width - bubbleWidth / 2 - 4,
        );
        double bubbleCenterY = selPoint.dy - bubbleHeight / 2 - 10;
        if (bubbleCenterY - bubbleHeight / 2 < 0) {
          bubbleCenterY = selPoint.dy + bubbleHeight / 2 + 14;
        }

        final bubbleRRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(bubbleCenterX, bubbleCenterY),
            width: bubbleWidth,
            height: bubbleHeight,
          ),
          const Radius.circular(8),
        );

        final bubbleBg = Paint()..color = const Color(0xFF1E293B);
        canvas.drawRRect(bubbleRRect, bubbleBg);

        textPainter.paint(
          canvas,
          Offset(
            bubbleCenterX - textPainter.width / 2,
            bubbleCenterY - textPainter.height / 2,
          ),
        );
      }
    } else {
      // Default: Peak point highlight
      Offset peakPoint = points.first;
      for (var p in points) {
        if (p.dy < peakPoint.dy) {
          peakPoint = p;
        }
      }

      canvas.drawCircle(peakPoint, 10, outerHaloPaint);
      canvas.drawCircle(peakPoint, 4, innerDotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BezierChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.tooltipText != tooltipText ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.noDataMessage != noDataMessage;
  }
}
