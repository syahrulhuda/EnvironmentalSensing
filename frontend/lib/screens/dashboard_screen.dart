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

/// Halaman Dashboard Utama ESS (Web & Mobile Modern Navy Layout)
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

  List<Widget> _buildCardsList() {
    final t = _current.temperature;
    final co = _current.mq7CoPpm;
    final smoke = _current.mq2SmokePpm;

    return [
      SensorMetricCard(
        title: 'Suhu & Kelembapan',
        pinLabel: 'DHT22 • GPIO 10',
        value: '${t.toStringAsFixed(1)}°C',
        unit: '${_current.humidity.toStringAsFixed(0)}% RH',
        badgeText: t >= 35 ? 'Overheat' : (t >= 30 ? 'Hangat' : 'Optimal'),
        thresholdInfo: 'Batas K3: < 35.0°C',
        isDanger: t >= 35,
        isWarning: t >= 30 && t < 35,
        icon: Icons.thermostat_rounded,
      ),
      SensorMetricCard(
        title: 'Karbon Monoksida (CO)',
        pinLabel: 'MQ-7 • GPIO 1',
        value: '$co',
        unit: 'PPM',
        badgeText: co >= 50 ? 'Bahaya' : (co >= 25 ? 'Waspada' : 'Aman'),
        thresholdInfo: 'Batas K3: < 50 PPM',
        isDanger: co >= 50,
        isWarning: co >= 25 && co < 50,
        icon: Icons.crisis_alert_rounded,
      ),
      SensorMetricCard(
        title: 'Gas & Asap Las',
        pinLabel: 'MQ-2 • GPIO 0',
        value: '$smoke',
        unit: 'PPM',
        badgeText: smoke >= 300 ? 'Bahaya' : (smoke >= 150 ? 'Waspada' : 'Aman'),
        thresholdInfo: 'Batas K3: < 150 PPM',
        isDanger: smoke >= 300,
        isWarning: smoke >= 150 && smoke < 300,
        icon: Icons.cloud_rounded,
      ),
    ];
  }

  Widget _buildMetricLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = _buildCardsList();
        if (constraints.maxWidth > 750) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: cards.map((c) => Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: c,
            ))).toList(),
          );
        }
        return Column(
          children: cards.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: c,
          )).toList(),
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
    final isDesktopWeb = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Environmental Sensing System',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.2),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'NODE-MRS01',
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.primaryLight, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            const Text('Bengkel Mekatronika POLTEKOM', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
          ],
        ),
        actions: [
          StatusPillBadge(isLive: _current.isOnline, label: _current.isOnline ? 'ONLINE' : 'OFFLINE'),
          IconButton(
            icon: Icon(Icons.bolt, size: 20, color: _isDangerSimulated ? AppColors.dangerRed : AppColors.textMuted),
            tooltip: 'Simulasi Bahaya K3',
            onPressed: () => setState(() => _isDangerSimulated = !_isDangerSimulated),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20, color: AppColors.textSecondary),
            onPressed: () => _openSettings(),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: isDesktopWeb
          ? Row(
              children: [
                Expanded(
                  flex: 7,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        EmergencyBannerWidget(isDanger: isDanger, statusText: _current.status),
                        const SizedBox(height: 14),
                        _buildMetricLayout(),
                        const SizedBox(height: 14),
                        TelemetryChartWidget(history: _history),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                    child: EsiChatPanel(chatService: _chatService, showHeaderClose: false),
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  EmergencyBannerWidget(isDanger: isDanger, statusText: _current.status),
                  const SizedBox(height: 14),
                  _buildMetricLayout(),
                  const SizedBox(height: 14),
                  TelemetryChartWidget(history: _history),
                  const SizedBox(height: 70), // Spasi aman untuk FAB
                ],
              ),
            ),
      floatingActionButton: isDesktopWeb ? null : Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          elevation: 0,
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
          label: const Text('Tanya ESI AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => EsiChatBottomSheet(chatService: _chatService),
          ),
        ),
      ),
    );
  }

  void _openSettings() {
    showDialog(
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
    );
  }
}
