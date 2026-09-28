import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Dialog Pengaturan Endpoint Cloud & Node ID
class SettingsDialog extends StatefulWidget {
  final String currentFirebaseUrl;
  final String currentBackendUrl;
  final String currentNodeId;
  final Function(String firebaseUrl, String backendUrl, String nodeId) onSave;

  const SettingsDialog({
    super.key,
    required this.currentFirebaseUrl,
    required this.currentBackendUrl,
    required this.currentNodeId,
    required this.onSave,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late TextEditingController _firebaseCtrl;
  late TextEditingController _backendCtrl;
  late TextEditingController _nodeCtrl;

  @override
  void initState() {
    super.initState();
    _firebaseCtrl = TextEditingController(text: widget.currentFirebaseUrl);
    _backendCtrl = TextEditingController(text: widget.currentBackendUrl);
    _nodeCtrl = TextEditingController(text: widget.currentNodeId);
  }

  @override
  void dispose() {
    _firebaseCtrl.dispose();
    _backendCtrl.dispose();
    _nodeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      title: const Row(
        children: [
          Icon(Icons.tune, color: AppColors.tempCyan, size: 20),
          SizedBox(width: 8),
          Text('Pengaturan Sistem ESS', style: TextStyle(fontSize: 16)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field('Firebase RTDB Buffer URL', _firebaseCtrl),
            const SizedBox(height: 12),
            _field('FastAPI Gateway URL', _backendCtrl),
            const SizedBox(height: 12),
            _field('Node ID Bengkel', _nodeCtrl),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.tempCyan),
          onPressed: () {
            widget.onSave(_firebaseCtrl.text, _backendCtrl.text, _nodeCtrl.text);
            Navigator.pop(context);
          },
          child: const Text('Simpan', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'monospace'),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontFamily: 'monospace'),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.card,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }
}
