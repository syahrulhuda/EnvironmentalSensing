import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/telemetry_model.dart';

/// Widget Grafik Tren Real-Time Multi-Channel Sensor ESS
class TelemetryChartWidget extends StatelessWidget {
  final List<TelemetryModel> history;

  const TelemetryChartWidget({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Real-time Telemetry Stream',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Multi-channel sensor progression (MQ-7, MQ-2, Suhu)',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _legendItem('Suhu', AppColors.tempCyan),
                  const SizedBox(width: 8),
                  _legendItem('MQ-7 (CO)', AppColors.coPurple),
                  const SizedBox(width: 8),
                  _legendItem('MQ-2', AppColors.smokeAmber),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            width: double.infinity,
            child: history.length < 2
                ? const Center(
                    child: Text(
                      'Menunggu data telemetri...',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  )
                : CustomPaint(
                    painter: _TelemetryChartPainter(history),
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
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class _TelemetryChartPainter extends CustomPainter {
  final List<TelemetryModel> points;

  _TelemetryChartPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 3; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (points.isEmpty) return;

    _drawSeries(
      canvas,
      size,
      points.map((p) => p.temperature * 3).toList(),
      AppColors.tempCyan,
      120.0,
    );
    _drawSeries(
      canvas,
      size,
      points.map((p) => p.mq7CoPpm.toDouble() * 2.0).toList(),
      AppColors.coPurple,
      120.0,
    );
    _drawSeries(
      canvas,
      size,
      points.map((p) => (p.mq2SmokePpm / 3.0)).toList(),
      AppColors.smokeAmber,
      120.0,
    );
  }

  void _drawSeries(Canvas canvas, Size size, List<double> values, Color color, double maxVal) {
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y = size.height * (1.0 - (values[i] / maxVal).clamp(0.0, 1.0));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _TelemetryChartPainter oldDelegate) => true;
}
