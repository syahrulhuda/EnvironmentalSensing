import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/telemetry_model.dart';

/// Widget Grafik Tren Real-Time Multi-Channel Desain Kurva Bezier Halus (Identik Web Sparkline)
class TelemetryChartWidget extends StatelessWidget {
  final List<TelemetryModel> history;

  const TelemetryChartWidget({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardOutline, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Legenda Grafik
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Tren Telemetri Real-Time',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Dinamika Fluktuasi Suhu, Gas CO, & Asap',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _legendItem('Suhu', AppColors.tempCyan),
                  const SizedBox(width: 8),
                  _legendItem('CO', AppColors.coPurple),
                  const SizedBox(width: 8),
                  _legendItem('Asap', AppColors.smokeAmber),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Area Canvas Grafik
          SizedBox(
            height: 155,
            width: double.infinity,
            child: history.length < 2
                ? const Center(
                    child: Text(
                      'Menghubungkan & mengumpulkan data streaming...',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  )
                : CustomPaint(
                    painter: _SmoothTelemetryPainter(history),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class _SmoothTelemetryPainter extends CustomPainter {
  final List<TelemetryModel> points;

  _SmoothTelemetryPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0x1538BDF8)
      ..strokeWidth = 1.0;

    // Grid horizontal tipis halus
    for (int i = 0; i <= 3; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (points.length < 2) return;

    // Gambar 3 series kurva dengan bezier interpolation
    _drawCurvedSeries(
      canvas,
      size,
      points.map((p) => p.temperature * 2.2).toList(),
      AppColors.tempCyan,
      120.0,
      withFill: true,
    );

    _drawCurvedSeries(
      canvas,
      size,
      points.map((p) => p.mq7CoPpm.toDouble() * 1.8).toList(),
      AppColors.coPurple,
      120.0,
      withFill: false,
    );

    _drawCurvedSeries(
      canvas,
      size,
      points.map((p) => p.mq2SmokePpm / 3.0).toList(),
      AppColors.smokeAmber,
      120.0,
      withFill: false,
    );
  }

  void _drawCurvedSeries(
    Canvas canvas,
    Size size,
    List<double> values,
    Color color,
    double maxVal, {
    required bool withFill,
  }) {
    final path = Path();
    final fillPath = Path();

    final List<Offset> coords = [];
    final double stepX = size.width / (values.length - 1);

    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      final normalized = (values[i] / maxVal).clamp(0.0, 1.0);
      final y = size.height * (1.0 - normalized);
      coords.add(Offset(x, y));
    }

    path.moveTo(coords[0].dx, coords[0].dy);
    fillPath.moveTo(coords[0].dx, size.height);
    fillPath.lineTo(coords[0].dx, coords[0].dy);

    for (int i = 0; i < coords.length - 1; i++) {
      final p0 = coords[i];
      final p1 = coords[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
      fillPath.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    // Gambar gradien area di bawah kurva primer
    if (withFill) {
      fillPath.lineTo(size.width, size.height);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 0),
          Offset(0, size.height),
          [
            color.withValues(alpha: 0.20),
            color.withValues(alpha: 0.0),
          ],
        )
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);
    }

    // Gambar garis kurva utama
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SmoothTelemetryPainter oldDelegate) => true;
}
