import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/telemetry_model.dart';
import '../services/telemetry_service.dart';
import '../services/esi_chat_service.dart';
import '../services/ota_update_service.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/emergency_banner_widget.dart';
import '../widgets/sensor_metric_card.dart';
import '../widgets/telemetry_chart_widget.dart';
import '../widgets/campus_carousel_slider.dart';
import '../widgets/esi_fab_button.dart';
import '../widgets/esi_chat_bottom_sheet.dart';
import '../widgets/node_selector_sheet.dart';
import '../widgets/update_dialog.dart';

/// Halaman Dashboard Utama ESS: Full Dart Native 100% Web Parity (TD-F20)
/// Menghadirkan performa 120 FPS native tanpa lag WebView dengan visual 100% identik Web Dashboard
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TelemetryService _telemetryService = TelemetryService();
  final EsiChatService _chatService = EsiChatService();
  TelemetryModel _current = TelemetryModel.initial();
  final List<TelemetryModel> _history = [];

  @override
  void initState() {
    super.initState();
    _telemetryService.telemetryStream.listen((data) {
      if (!mounted) return;
      setState(() {
        _current = data;
        // Hanya rekam ke riwayat grafik jika data benar-benar aktif (bukan offline kosong)
        if (data.isOnline) {
          _history.add(_current);
          if (_history.length > 25) _history.removeAt(0);
        }
      });
    });
    _telemetryService.startPolling();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOtaUpdate());
  }

  Future<void> _checkOtaUpdate() async {
    final v = await OtaUpdateService.checkForUpdate();
    if (v != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: !v.forceUpdate,
        builder: (_) => UpdateAvailableDialog(versionInfo: v),
      );
    }
  }

  @override
  void dispose() {
    _telemetryService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDanger = _current.isOnline &&
        (_current.status == 'DANGER' || _current.mq7CoPpm >= 50 || _current.mq2SmokePpm >= 300);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Atmosfer Background: bg_campus.jpg + Deep Midnight Navy Gradient
          Image.asset(
            'assets/bg_campus.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background.withValues(alpha: 0.88),
                  AppColors.background.withValues(alpha: 0.96),
                ],
              ),
            ),
          ),

          // 2. Konten Utama Dashboard
          SafeArea(
            child: NestedScrollView(
              headerSliverBuilder: (context, _) => [
                DashboardHeader(
                  nodeId: _current.nodeId,
                  isOnline: _current.isOnline,
                  isDanger: isDanger,
                  onSelectNode: _openNodeSelector,
                ),
              ],
              body: ListView(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 90),
                children: [
                  const CampusCarouselSlider(),
                  const SizedBox(height: 12),
                  EmergencyBannerWidget(isDanger: isDanger, statusText: _current.status),
                  const SizedBox(height: 12),
                  _buildSensorCards(),
                  const SizedBox(height: 6),
                  TelemetryChartWidget(history: _history),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: EsiFabButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => EsiChatBottomSheet(chatService: _chatService),
        ),
      ),
    );
  }

  Widget _buildSensorCards() {
    final isOnline = _current.isOnline;
    final t = _current.temperature;
    final co = _current.mq7CoPpm;
    final smoke = _current.mq2SmokePpm;

    final tempHist = _history.map((e) => e.temperature).toList();
    final coHist = _history.map((e) => e.mq7CoPpm.toDouble()).toList();
    final smokeHist = _history.map((e) => e.mq2SmokePpm.toDouble()).toList();

    final tempDisplay = (t > 0 || isOnline) ? '${t.toStringAsFixed(1)}°C' : '--°C';
    final humDisplay = (t > 0 || isOnline) ? '${_current.humidity.toStringAsFixed(0)}% RH' : '--% RH';
    final coDisplay = (co > 0 || isOnline) ? '$co' : '--';
    final smokeDisplay = (smoke > 0 || isOnline) ? '$smoke' : '--';

    return Column(
      children: [
        SensorMetricCard(
          title: 'Suhu & Kelembapan',
          value: tempDisplay,
          unit: humDisplay,
          badgeText: t >= 35 ? 'Overheat' : (t >= 30 ? 'Hangat' : 'Optimal'),
          thresholdInfo: 'Batas K3: < 35.0°C',
          isDanger: isOnline && t >= 35,
          isWarning: isOnline && t >= 30 && t < 35,
          isOnline: isOnline,
          icon: Icons.thermostat_rounded,
          sparklineTitle: 'TREN SUHU REAL-TIME',
          sparklineValues: tempHist,
        ),
        SensorMetricCard(
          title: 'Karbon Monoksida (CO)',
          value: coDisplay,
          unit: 'PPM',
          badgeText: co >= 50 ? 'Bahaya' : (co >= 25 ? 'Waspada' : 'Aman'),
          thresholdInfo: 'Batas K3: < 50 PPM',
          isDanger: isOnline && co >= 50,
          isWarning: isOnline && co >= 25 && co < 50,
          isOnline: isOnline,
          icon: Icons.crisis_alert_rounded,
          sparklineTitle: 'TREN GAS CO REAL-TIME',
          sparklineValues: coHist,
        ),
        SensorMetricCard(
          title: 'Gas Asap & Pengelasan',
          value: smokeDisplay,
          unit: 'PPM',
          badgeText: smoke >= 300 ? 'Bahaya' : (smoke >= 150 ? 'Waspada' : 'Clean Air'),
          thresholdInfo: 'Batas K3: < 150 PPM',
          isDanger: isOnline && smoke >= 300,
          isWarning: isOnline && smoke >= 150 && smoke < 300,
          isOnline: isOnline,
          icon: Icons.cloud_outlined,
          sparklineTitle: 'TREN GAS & ASAP REAL-TIME',
          sparklineValues: smokeHist,
        ),
      ],
    );
  }

  void _openNodeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => NodeSelectorSheet(
        currentNodeId: _current.nodeId,
        onNodeSelected: (newNode) {
          setState(() {
            _telemetryService.nodeId = newNode;
            _history.clear();
          });
          _telemetryService.fetchLatest();
        },
      ),
    );
  }
}
