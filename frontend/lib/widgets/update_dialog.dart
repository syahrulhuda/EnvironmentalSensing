import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/app_version_model.dart';
import '../services/ota_update_service.dart';

/// Modal dialog pembaruan versi aplikasi mobile ESS (DEVOPS-04)
/// Selaras dengan palet 4-warna AppColors dan standar K3
class UpdateAvailableDialog extends StatefulWidget {
  final AppVersionModel versionInfo;
  const UpdateAvailableDialog({super.key, required this.versionInfo});

  @override
  State<UpdateAvailableDialog> createState() => _UpdateAvailableDialogState();
}

class _UpdateAvailableDialogState extends State<UpdateAvailableDialog> {
  bool _downloading = false;
  double _progress = 0.0;
  String? _error;

  void _triggerUpdate() {
    setState(() {
      _downloading = true;
      _error = null;
    });

    OtaUpdateService.downloadAndInstall(
      downloadUrl: widget.versionInfo.downloadUrl,
      onProgress: (p) => setState(() => _progress = p),
      onError: (err) => setState(() {
        _downloading = false;
        _error = err;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.versionInfo;
    return PopScope(
      canPop: !v.forceUpdate && !_downloading,
      child: Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.system_update_alt, color: AppColors.primaryLight, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Pembaruan ESS',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Versi Baru: ${v.latestVersion}',
                style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  v.releaseNotes,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                ),
              ),
              if (_downloading) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    '${(_progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.dangerRed, fontSize: 11),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!v.forceUpdate && !_downloading)
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Nanti', style: TextStyle(color: AppColors.textMuted)),
                    ),
                  if (!_downloading)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _triggerUpdate,
                      child: const Text(
                        'Perbarui Sekarang',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
