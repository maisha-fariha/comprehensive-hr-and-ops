import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../attendance/presentation/widgets/attendance_record_card.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/hr_document_row.dart';
import 'hr_documents_common.dart';

enum HrDocumentAction { view, download, edit, restore, withdraw }

/// One registry row: the web table columns stacked into a card, with the
/// same row-actions menu.
class HrDocumentRowCard extends StatelessWidget {
  final HrDocumentRow row;
  final bool canWrite;
  final bool busy;
  final ValueChanged<HrDocumentAction> onAction;

  const HrDocumentRowCard({
    super.key,
    required this.row,
    required this.canWrite,
    required this.onAction,
    this.busy = false,
  });

  List<(HrDocumentAction, IconData, String)> get _actions => [
        (HrDocumentAction.view, Icons.visibility_outlined, 'View'),
        if (row.fileUrl != null) (HrDocumentAction.download, Icons.download_rounded, 'Download'),
        if (row.canEdit(canWrite)) (HrDocumentAction.edit, Icons.edit_outlined, 'Edit'),
        if (row.canRestore(canWrite)) (HrDocumentAction.restore, Icons.restore_rounded, 'Restore'),
        if (row.canWithdraw(canWrite))
          (HrDocumentAction.withdraw, Icons.delete_outline_rounded, 'Withdraw'),
      ];

  @override
  Widget build(BuildContext context) {
    final (icon, fg, bg) = hrFileStyle(row.fileKind);
    final (visIcon, visColor) = hrVisibilityStyle(row.visibility);
    final expiryColor = switch (row.expiryTone) {
      HrExpiryTone.critical => AppColors.criticalRed,
      HrExpiryTone.warning => AppColors.urgentAmber,
      HrExpiryTone.normal => AppColors.textHeading,
    };
    final muted = handoverText(context, 12, color: AppColors.textMuted);
    final value = handoverText(context, 13);

    Widget fact(String label, Widget child) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 92, child: Text(label, style: muted)),
              Expanded(child: child),
            ],
          ),
        );

    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => onAction(HrDocumentAction.view),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  HrIconTile(icon: icon, foreground: fg, background: bg),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      row.name,
                      style: handoverText(
                        context,
                        14,
                        weight: FontWeight.w600,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ),
                  Opacity(
                    opacity: busy ? 0.5 : 1,
                    child: PopupMenuButton<HrDocumentAction>(
                      key: ValueKey('document-actions-${row.id}'),
                      tooltip: 'Row actions',
                      enabled: !busy,
                      color: AppColors.surfaceWhite,
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                      onSelected: onAction,
                      itemBuilder: (_) => [
                        for (final (action, actionIcon, label) in _actions)
                          PopupMenuItem(
                            value: action,
                            child: Row(
                              children: [
                                Icon(
                                  actionIcon,
                                  size: 16,
                                  color: action == HrDocumentAction.withdraw
                                      ? AppColors.criticalRed
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  label,
                                  style: handoverText(
                                    context,
                                    13.5,
                                    color: action == HrDocumentAction.withdraw
                                        ? AppColors.criticalRed
                                        : AppColors.textHeading,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        HrDocPill.owner(row.ownerType, row.ownerTypeLabel),
                        AttendancePill(
                          label: row.statusLabel,
                          tone: hrStatusTone(row.statusTone),
                          dot: true,
                        ),
                      ],
                    ),
                    fact('Owner Name', Text(row.ownerName, style: value)),
                    fact('Category', Text(row.category, style: value)),
                    fact(
                      'Expiry Date',
                      Text(
                        row.expiryDate ?? 'No expiry',
                        style: handoverText(
                          context,
                          13,
                          weight: row.expiryTone == HrExpiryTone.normal
                              ? FontWeight.w400
                              : FontWeight.w500,
                          color: expiryColor,
                        ),
                      ),
                    ),
                    fact(
                      'Visibility',
                      Row(
                        children: [
                          Icon(visIcon, size: 13, color: visColor),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              row.visibilityLabel,
                              style: handoverText(context, 13, color: visColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    fact('Uploaded', Text(row.uploadedDate, style: value)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
