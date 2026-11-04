/// Model data respon versi aplikasi dari endpoint GET /api/app/version (DEVOPS-03 / DEVOPS-04)
class AppVersionModel {
  final String latestVersion;
  final String minRequiredVersion;
  final String downloadUrl;
  final String releaseNotes;
  final bool forceUpdate;

  const AppVersionModel({
    required this.latestVersion,
    required this.minRequiredVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.forceUpdate,
  });

  factory AppVersionModel.fromJson(Map<String, dynamic> json) {
    return AppVersionModel(
      latestVersion: json['latest_version'] as String? ?? '1.0.0',
      minRequiredVersion: json['min_required_version'] as String? ?? '1.0.0',
      downloadUrl: json['download_url'] as String? ?? '',
      releaseNotes: json['release_notes'] as String? ?? '',
      forceUpdate: json['force_update'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'latest_version': latestVersion,
    'min_required_version': minRequiredVersion,
    'download_url': downloadUrl,
    'release_notes': releaseNotes,
    'force_update': forceUpdate,
  };
}
