import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../attendance/presentation/widgets/attendance_record_card.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/hr_document_row.dart';
import 'hr_documents_common.dart';

/// The web document "View" modal.
class HrDocumentDetailSheet extends StatelessWidget {
  final HrDocumentRow row;
  final bool canWrite;
  final VoidCallback onDownload;
  final VoidCallback onEdit;

  const HrDocumentDetailSheet({
    super.key,
    required this.row,
    required this.canWrite,
    required this.onDownload,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, fg, _) = hrFileStyle(row.fileKind);
    Widget field(String label, String value) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: handoverText(context, 11, weight: FontWeight.w600, color: AppColors.textMuted),
            ),
            const SizedBox(height: 4),
            Text(
              value.isEmpty ? '—' : value,
              style: handoverText(context, 13.5, weight: FontWeight.w600, color: AppColors.primaryNavy),
            ),
            const SizedBox(height: 14),
          ],
        );
    Widget section(String title, List<Widget> children) => HandoverPanel(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: handoverText(context, 13, weight: FontWeight.w700)),
              const SizedBox(height: 14),
              ...children,
            ],
          ),
        );

    return HrSheetFrame(
      key: const ValueKey('document-detail'),
      icon: icon,
      iconBackground: row.fileKind == HrFileKind.file ? AppColors.filterButtonBackground : fg,
      iconForeground: row.fileKind == HrFileKind.file ? AppColors.textMuted : AppColors.surfaceWhite,
      title: row.name,
      badges: [
        HrDocPill.owner(row.ownerType, row.ownerTypeLabel),
        AttendancePill(label: row.statusLabel, tone: hrStatusTone(row.statusTone), dot: true),
      ],
      description: 'Filed against ${row.ownerName}',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          section('Document Details', [
            field('Owner', '${row.ownerName} · ${row.ownerTypeLabel}'),
            field('Category', row.category),
            field('Visible to', row.visibilityLabel),
            field('Held as', row.isStaffCertificate ? 'Staff certificate' : 'Document'),
          ]),
          const SizedBox(height: 16),
          section('Filing & Expiry', [
            field('Filed', row.uploadedDate),
            field('Expiry Date', row.expiryDate ?? 'Not tracked'),
            field('Status', row.withdrawn ? 'Withdrawn' : row.statusLabel),
            if (row.notes != null) ...[
              Text(row.notes!, style: handoverText(context, 13.5)),
              const SizedBox(height: 14),
            ],
          ]),
          if (row.isStaffCertificate) ...[
            const SizedBox(height: 16),
            Text(
              'Certificates are held on the staff record and are edited there, not in the registry.',
              style: handoverText(context, 13, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
      footer: [
        HandoverButton(
          key: const ValueKey('document-detail-close'),
          label: 'Close',
          onPressed: () => Navigator.of(context).pop(),
        ),
        if (row.fileUrl != null)
          HandoverButton(
            key: const ValueKey('document-detail-download'),
            label: 'Download',
            icon: Icons.download_rounded,
            onPressed: onDownload,
          ),
        if (row.canEdit(canWrite))
          HandoverButton(
            key: const ValueKey('document-detail-edit'),
            label: 'Edit',
            icon: Icons.edit_outlined,
            filled: true,
            onPressed: onEdit,
          ),
      ],
    );
  }
}
