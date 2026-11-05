import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../core/constants/app_colors.dart';
import '../services/ota_update_service.dart';
import '../widgets/update_dialog.dart';

/// Halaman Dashboard Utama ESS: Hybrid Container yang Memuat Langsung Web Dashboard (Opsi A)
/// Memadukan kesempurnaan 100% UI/UX Web Dashboard dengan In-App OTA Update Engine Android.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _loadingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initWebView();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOtaUpdate());
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.background)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress / 100.0;
                if (progress >= 100) _isLoading = false;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('[WebView Error] ${error.errorCode}: ${error.description}');
          },
        ),
      )
      ..loadFlutterAsset('index.html');
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
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _controller.canGoBack()) {
          await _controller.goBack();
        } else {
          if (context.mounted) Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_isLoading)
                LinearProgressIndicator(
                  value: _loadingProgress > 0 ? _loadingProgress : null,
                  backgroundColor: AppColors.card,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
                  minHeight: 2.5,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
