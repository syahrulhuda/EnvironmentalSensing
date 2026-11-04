import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/constants/app_colors.dart';
import '../models/telemetry_model.dart';
import '../services/telemetry_service.dart';
import '../services/esi_chat_service.dart';
import '../widgets/status_pill_badge.dart';
import '../widgets/emergency_banner_widget.dart';
import '../widgets/sensor_metric_card.dart';
import '../widgets/telemetry_chart_widget.dart';
import '../widgets/esi_chat_bottom_sheet.dart';
import '../widgets/esi_chat_panel.dart';
import 'settings_dialog.dart';
import '../services/ota_update_service.dart';
import '../widgets/update_dialog.dart';

/// Halaman Dashboard Utama ESS (Web & Mobile Responsive)
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
  bool _isDangerSimulated = false;

  @override
  void initState() {
    super.initState();
    _telemetryService.telemetryStream.listen((data) {
      if (!mounted) return;
      setState(() {
        _current = _isDangerSimulated ? _getDangerMock() : data;
        _history.add(_current);
        if (_history.length > 30) _history.removeAt(0);
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

  TelemetryModel _getDangerMock() => TelemetryModel(
    temperature: 42.0, humidity: 35.0, mq7CoPpm: 85, mq2SmokePpm: 520,
    mq7Volt: 1.45, mq7Raw: 1420, nodeId: _current.nodeId, status: 'DANGER',
    timestamp: DateTime.now(), isOnline: _current.isOnline,
  );

  @override
  void dispose() {
    _telemetryService.dispose();
    super.dispose();
  }

  Widget _buildMetricGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;
        double childAspectRatio = 2.6;
        if (constraints.maxWidth > 700) {
          crossAxisCount = 3;
          childAspectRatio = 1.25;
        } else if (constraints.maxWidth > 480) {
          crossAxisCount = 2;
          childAspectRatio = 1.35;
        }

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: childAspectRatio,
          children: [
            SensorMetricCard(
              title: 'Suhu & Kelembapan',
              pinLabel: 'DHT22 • GPIO 10',
              value: '${_current.temperature.toStringAsFixed(1)}°C',
              unit: '${_current.humidity.toStringAsFixed(0)}% RH',
              badgeText: _current.temperature >= 35 ? 'Overheat' : 'Optimal',
              isDanger: _current.temperature >= 35,
              accentColor: AppColors.primary,
              icon: Icons.thermostat,
              progressPercent: (_current.temperature / 50),
            ),
            SensorMetricCard(
              title: 'Karbon Monoksida (CO)',
              pinLabel: 'MQ-7 • GPIO 1',
              value: '${_current.mq7CoPpm}',
              unit: 'PPM',
              badgeText: _current.mq7CoPpm >= 50 ? 'TOXIC HAZARD!' : 'Safe (<50 PPM)',
              isDanger: _current.mq7CoPpm >= 50,
              accentColor: _current.mq7CoPpm >= 50 ? AppColors.dangerRed : AppColors.primary,
              icon: Icons.warning_rounded,
              progressPercent: (_current.mq7CoPpm / 80),
            ),
            SensorMetricCard(
              title: 'Asap & Gas Las',
              pinLabel: 'MQ-2 • GPIO 0',
              value: '${_current.mq2SmokePpm}',
              unit: 'PPM',
              badgeText: _current.mq2SmokePpm >= 300 ? 'SMOKE DETECTED!' : 'Clean Air',
              isDanger: _current.mq2SmokePpm >= 300,
              accentColor: _current.mq2SmokePpm >= 300 ? AppColors.warningAmber : AppColors.primary,
              icon: Icons.cloud,
              progressPercent: (_current.mq2SmokePpm / 500),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDanger = _current.temperature >= ApiConstants.tempMaxThreshold ||
        _current.mq7CoPpm >= ApiConstants.mq7MaxThreshold ||
        _current.mq2SmokePpm >= ApiConstants.mq2MaxThreshold ||
        _current.status == 'DANGER';
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopWeb = screenWidth > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Smart Environmental Sensing (ESS)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text('Bengkel Mekatronika POLTEKOM', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
        actions: [
          StatusPillBadge(
            isLive: _current.isOnline,
            label: _current.isOnline ? 'ONLINE' : 'OFFLINE',
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.bolt,
              color: _isDangerSimulated ? AppColors.dangerRed : AppColors.textSecondary,
            ),
            tooltip: 'Simulasi Bahaya K3',
            onPressed: () => setState(() => _isDangerSimulated = !_isDangerSimulated),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textSecondary),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => SettingsDialog(
                currentFirebaseUrl: _telemetryService.firebaseUrl,
                currentBackendUrl: _telemetryService.backendUrl,
                currentNodeId: _telemetryService.nodeId,
                onSave: (fb, be, node) {
                  setState(() {
                    _telemetryService.firebaseUrl = fb;
                    _telemetryService.backendUrl = be;
                    _telemetryService.nodeId = node;
                    _chatService.backendUrl = be;
                  });
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isDesktopWeb
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Kolom Kiri: Metriks Sensor & Grafik Tren (Bisa Di-scroll)
                Expanded(
                  flex: 7,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        EmergencyBannerWidget(isDanger: isDanger, statusText: _current.status),
                        const SizedBox(height: 16),
                        _buildMetricGrid(),
                        const SizedBox(height: 16),
                        TelemetryChartWidget(history: _history),
                      ],
                    ),
                  ),
                ),
                // Kolom Kanan: Pinned ESI AI Chat Panel (Stay in Place, Tidak Ikut Scroll)
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                    child: EsiChatPanel(
                      chatService: _chatService,
                      showHeaderClose: false,
                    ),
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  EmergencyBannerWidget(isDanger: isDanger, statusText: _current.status),
                  const SizedBox(height: 16),
                  _buildMetricGrid(),
                  const SizedBox(height: 16),
                  TelemetryChartWidget(history: _history),
                ],
              ),
            ),
      floatingActionButton: isDesktopWeb
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.smart_toy, color: Colors.white),
              label: const Text('Tanya ESI AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => EsiChatBottomSheet(chatService: _chatService),
              ),
            ),
    );
  }
}
