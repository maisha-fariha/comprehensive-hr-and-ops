import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../outbox_item.dart';

/// Small status pill for a change that has not reached the server yet.
class PendingSyncChip extends StatelessWidget {
  final OutboxStatus status;
  final String? label;

  const PendingSyncChip({
    super.key,
    this.status = OutboxStatus.pending,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final attention = status.needsAttention;
    final sending = status == OutboxStatus.sending;
    final fg = attention ? AppColors.criticalRed : AppColors.urgentAmber;
    final bg = attention
        ? AppColors.criticalBackgroundSoft
        : AppColors.urgentBackgroundSoft;
    final text = label ??
        switch (status) {
          OutboxStatus.pending => 'Pending sync',
          OutboxStatus.sending => 'Sending…',
          OutboxStatus.failed => 'Not sent',
          OutboxStatus.conflict => 'Conflict',
        };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            attention
                ? Icons.error_outline_rounded
                : sending
                    ? Icons.cloud_upload_outlined
                    : Icons.cloud_off_rounded,
            size: 12,
            color: fg,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
