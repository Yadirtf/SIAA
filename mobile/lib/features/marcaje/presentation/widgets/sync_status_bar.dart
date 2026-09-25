// sync_status_bar.dart — Banner de cola offline y botón de sincronización (US-MAR-11)
import 'package:flutter/material.dart';

class SyncStatusBar extends StatelessWidget {
  final int count;
  final VoidCallback onSyncPressed;

  const SyncStatusBar({
    super.key,
    required this.count,
    required this.onSyncPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade400),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_upload_outlined, color: Colors.amber.shade900),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count marcaje(s) local(es) pendiente(s)',
              style: TextStyle(
                color: Colors.amber.shade900,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: onSyncPressed,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              backgroundColor: Colors.amber.shade800,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Sincronizar', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
