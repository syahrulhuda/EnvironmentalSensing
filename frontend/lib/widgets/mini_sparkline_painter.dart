import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// CustomPainter untuk menggambar kurva sparkline mini real-time di dalam kartu sensor
/// Memiliki visualisasi 100% identik dengan canvas sparkline.js pada Web Dashboard
class MiniSparklinePainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;
  final double? minVal;
  final double? maxVal;

  MiniSparklinePainter({
    required this.values,
    required this.lineColor,
    this.minVal,
    this.maxVal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // 1. Gambar garis grid horizontal halus di tengah
    final gridPaint = Paint()
      ..color = AppColors.primaryLight.withValues(alpha: 0.12)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      gridPaint,
    );

    if (values.length < 2) return;

    // 2. Tentukan range nilai min dan max
    double computedMin = minVal ?? values.reduce((a, b) => a < b ? a : b);
    double computedMax = maxVal ?? values.reduce((a, b) => a > b ? a : b);
    if ((computedMax - computedMin).abs() < 0.001) {
      computedMax += 1.0;
      computedMin -= 1.0;
    }

    const double padX = 4.0;
    const double padY = 6.0;
    final double plotW = size.width - (padX * 2);
    final double plotH = size.height - (padY * 2);
    final double stepX = plotW / (values.length - 1);

    // Hitung posisi titik koordinat
    final points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final norm = (values[i] - computedMin) / (computedMax - computedMin);
      final clampedNorm = norm.clamp(0.0, 1.0);
      final x = padX + (i * stepX);
      final y = size.height - padY - (clampedNorm * plotH);
      points.add(Offset(x, y));
    }

    // 3. Bangun Path Kurva Bezier Halus (Spline)
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    // 4. Gambar Area Gradient di Bawah Kurva
    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, padY),
        Offset(0, size.height),
        [
          lineColor.withValues(alpha: 0.28),
          lineColor.withValues(alpha: 0.02),
        ],
      )
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // 5. Gambar Garis Kurva Utama
    final strokePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, strokePaint);

    // 6. Gambar Dot Glowing pada Titik Terakhir (Real-Time Current Point)
    final lastPoint = points.last;
    final glowPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(lastPoint, 5.0, glowPaint);

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(lastPoint, 2.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant MiniSparklinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.lineColor != lineColor;
  }
}
