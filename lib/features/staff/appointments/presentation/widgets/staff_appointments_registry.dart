import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_appointment.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

class StaffAppointmentsRegistry extends StatelessWidget {
  final List<StaffAppointment> appointments;
  final int totalCount;
  final bool canWrite;
  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final void Function(StaffAppointment item) onView;
  final Future<void> Function(StaffAppointment item) onApprove;
  final Future<void> Function(StaffAppointment item) onReject;
  final void Function(StaffAppointment item) onEdit;
  final Future<void> Function(StaffAppointment item) onCancel;
  final Future<void> Function(StaffAppointment item) onDelete;
  final Future<void> Function(StaffAppointment item) onRestore;

  const StaffAppointmentsRegistry({
    super.key,
    required this.appointments,
    required this.totalCount,
    required this.canWrite,
    required this.page,
    required this.totalPages,
    required this.onPageChanged,
    required this.onView,
    required this.onApprove,
    required this.onReject,
    required this.onEdit,
    required this.onCancel,
    required this.onDelete,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Requests & Appointments',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$totalCount request${totalCount == 1 ? '' : 's'} · Sorted by the time they are due — earliest first.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          if (appointments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Text(
                'No appointments match these filters.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.textMuted,
                ),
              ),
            )
          else
            for (final item in appointments) ...[
              _AppointmentCard(
                item: item,
                canWrite: canWrite,
                onView: () => onView(item),
                onApprove: () => onApprove(item),
                onReject: () => onReject(item),
                onEdit: () => onEdit(item),
                onCancel: () => onCancel(item),
                onDelete: () => onDelete(item),
                onRestore: () => onRestore(item),
              ),
              const SizedBox(height: 10),
            ],
          if (totalPages > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
                  child: const Text('Prev'),
                ),
                Text(
                  '$page / $totalPages',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHeading,
                  ),
                ),
                TextButton(
                  onPressed:
                      page < totalPages ? () => onPageChanged(page + 1) : null,
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final StaffAppointment item;
  final bool canWrite;
  final VoidCallback onView;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final VoidCallback onRestore;

  const _AppointmentCard({
    required this.item,
    required this.canWrite,
    required this.onView,
    required this.onApprove,
    required this.onReject,
    required this.onEdit,
    required this.onCancel,
    required this.onDelete,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final purposeOrNotes = [
      if (item.purpose != null && item.purpose!.trim().isNotEmpty) item.purpose!,
      if (item.notes != null && item.notes!.trim().isNotEmpty) item.notes!,
    ].join(' · ');

    return Material(
      color: AppColors.scaffoldBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: item.isFamilyVisit
                          ? AppColors.quickActionCreateShiftBg
                          : AppColors.infoBackground,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      item.isFamilyVisit
                          ? Icons.family_restroom_rounded
                          : Icons.local_hospital_outlined,
                      color: item.isFamilyVisit
                          ? AppColors.secondaryTeal
                          : AppColors.infoBlue,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.shortId,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textHeading,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.residenceName.isEmpty
                              ? '—'
                              : item.residenceName,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(
                    status: item.normalizedStatus,
                    label: item.statusLabel,
                  ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: AppColors.textMuted,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: AppColors.surfaceWhite,
                    elevation: 4,
                    onSelected: (value) {
                      switch (value) {
                        case 'view':
                          onView();
                        case 'approve':
                          onApprove();
                        case 'reject':
                          onReject();
                        case 'edit':
                          onEdit();
                        case 'cancel':
                          onCancel();
                        case 'delete':
                          onDelete();
                        case 'restore':
                          onRestore();
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: _MenuRow(
                          icon: Icons.visibility_outlined,
                          label: 'View Details',
                        ),
                      ),
                      if (canWrite && item.isPending)
                        const PopupMenuItem(
                          value: 'approve',
                          child: _MenuRow(
                            icon: Icons.check_rounded,
                            label: 'Approve',
                            color: AppColors.activeGreen,
                          ),
                        ),
                      if (canWrite && item.isPending)
                        const PopupMenuItem(
                          value: 'reject',
                          child: _MenuRow(
                            icon: Icons.close_rounded,
                            label: 'Reject',
                          ),
                        ),
                      if (canWrite && !item.isCancelled)
                        const PopupMenuItem(
                          value: 'edit',
                          child: _MenuRow(
                            icon: Icons.edit_outlined,
                            label: 'Edit',
                          ),
                        ),
                      if (canWrite &&
                          !item.isCancelled &&
                          !item.isRejected &&
                          item.normalizedStatus != 'completed')
                        const PopupMenuItem(
                          value: 'cancel',
                          child: _MenuRow(
                            icon: Icons.block_rounded,
                            label: 'Cancel',
                            color: AppColors.criticalRed,
                          ),
                        ),
                      if (canWrite && item.canRestore)
                        const PopupMenuItem(
                          value: 'restore',
                          child: _MenuRow(
                            icon: Icons.restart_alt_rounded,
                            label: 'Restore',
                            color: AppColors.secondaryTeal,
                          ),
                        ),
                      if (canWrite)
                        const PopupMenuItem(
                          value: 'delete',
                          child: _MenuRow(
                            icon: Icons.delete_outline_rounded,
                            label: 'Delete',
                            color: AppColors.criticalRed,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _Meta(label: 'Resident', value: item.clientName),
                  _Meta(label: 'Requested by', value: item.requesterLabel),
                  _TypeBadge(
                    label: item.typeLabel,
                    isFamily: item.isFamilyVisit,
                  ),
                  _Meta(label: 'When', value: item.dateTimeLabel),
                ],
              ),
              if (purposeOrNotes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  purposeOrNotes,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
              if (item.deciderName != null && item.deciderName!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  [
                    'Reviewed by ${item.deciderName}',
                    if (item.decidedAtLabel.isNotEmpty) item.decidedAtLabel,
                  ].join(' · '),
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MenuRow({
    required this.icon,
    required this.label,
    this.color = AppColors.textHeading,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  final String label;
  final String value;

  const _Meta({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label · ',
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.5,
                color: AppColors.textMuted,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
                color: AppColors.textHeading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String label;
  final bool isFamily;

  const _TypeBadge({required this.label, required this.isFamily});

  @override
  Widget build(BuildContext context) {
    final fg = isFamily ? AppColors.secondaryTeal : AppColors.infoBlue;
    final bg =
        isFamily ? AppColors.quickActionCreateShiftBg : AppColors.infoBackground;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w600,
          fontSize: 11.5,
          color: fg,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final String label;

  const _StatusBadge({required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    final (Color fg, Color bg) = switch (status) {
      'pending' => (AppColors.urgentAmber, AppColors.urgentBackgroundSoft),
      'approved' => (AppColors.activeGreen, AppColors.activeBackground),
      'rejected' || 'cancelled' => (
          AppColors.criticalRed,
          AppColors.criticalBackgroundSoft,
        ),
      'completed' => (AppColors.infoBlue, AppColors.infoBackground),
      _ => (AppColors.textSecondary, AppColors.filterButtonBackground),
    };
    return Container(
      margin: const EdgeInsets.only(right: 4, top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w600,
          fontSize: 11,
          color: fg,
        ),
      ),
    );
  }
}

Future<void> showStaffAppointmentDetailsSheet(
  BuildContext context,
  StaffAppointment item,
) {
  return showAppBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.shortId,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppColors.textHeading,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _TypeBadge(
                    label: item.typeLabel,
                    isFamily: item.isFamilyVisit,
                  ),
                  _StatusBadge(
                    status: item.normalizedStatus,
                    label: item.statusLabel,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _DetailRow('Resident', item.clientName),
              _DetailRow(
                'Residence',
                item.residenceName.isEmpty ? '—' : item.residenceName,
              ),
              _DetailRow('Requested by', item.requesterLabel),
              _DetailRow('When', item.dateTimeLabel),
              _DetailRow(
                'Location',
                (item.location == null || item.location!.isEmpty)
                    ? 'Not set'
                    : item.location!,
              ),
              _DetailRow(
                'Purpose',
                (item.purpose == null || item.purpose!.isEmpty)
                    ? '—'
                    : item.purpose!,
              ),
              _DetailRow(
                'Notes',
                (item.notes == null || item.notes!.isEmpty)
                    ? '—'
                    : item.notes!,
              ),
              if (item.deciderName != null && item.deciderName!.isNotEmpty)
                _DetailRow(
                  'Reviewed by',
                  [
                    item.deciderName!,
                    if (item.decidedAtLabel.isNotEmpty) item.decidedAtLabel,
                  ].join(' · '),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                color: AppColors.textHeading,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
