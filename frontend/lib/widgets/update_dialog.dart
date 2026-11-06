import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/app_version_model.dart';
import '../services/ota_update_service.dart';

/// Modal dialog pembaruan versi aplikasi mobile ESS (DEVOPS-04)
/// Selaras dengan palet 4-warna AppColors dan standar K3
class UpdateAvailableDialog extends StatelessWidget {
  final AppVersionModel versionInfo;
  const UpdateAvailableDialog({super.key, required this.versionInfo});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !versionInfo.forceUpdate,
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
                      color: AppColors.primary.withValues(alpha: 0.15),
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
                'Versi Baru: ${versionInfo.latestVersion}',
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
                  versionInfo.releaseNotes,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!versionInfo.forceUpdate)
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Nanti', style: TextStyle(color: AppColors.textMuted)),
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await OtaUpdateService.openDownloadPage(versionInfo.downloadUrl);
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.open_in_browser_rounded, size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Perbarui Sekarang',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
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
