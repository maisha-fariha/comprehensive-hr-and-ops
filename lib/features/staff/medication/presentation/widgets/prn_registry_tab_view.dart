import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_client_medication_item.dart';
import 'administered_tab_view.dart';
import 'staff_medication_avatar.dart';
import '../../domain/entities/staff_medication_enums.dart';

/// Web PRN tab — `GET /prn-medications` registry.
class PrnRegistryTabView extends StatelessWidget {
  final List<StaffClientMedicationItem> items;
  final ValueChanged<StaffClientMedicationItem>? onGive;
  final ValueChanged<StaffClientMedicationItem>? onOpenChart;
  final ValueChanged<StaffClientMedicationItem>? onEdit;
  final bool canGive;

  /// The registry search + filters shared with the MAR tab.
  final Widget? filters;

  const PrnRegistryTabView({
    super.key,
    required this.items,
    this.onGive,
    this.onOpenChart,
    this.onEdit,
    this.canGive = true,
    this.filters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        Row(
          children: [
            const Expanded(
              child: Text(
                'PRN Medication Registry',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.textHeading,
                ),
              ),
            ),
            StaffMedicationCountLabel(
              text: '${items.length} available',
              background: const Color(0xFFE7F0FF),
              foreground: const Color(0xFF2A5DA6),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        if (filters != null) ...[
          filters!,
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        ],
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Text(
              'No PRN medicines available under these filters.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
          )
        else
          for (var i = 0; i < items.length; i++) ...[
            _PrnCard(
              item: items[i],
              canGive: canGive,
              onGive: onGive == null ? null : () => onGive!(items[i]),
              onOpenChart:
                  onOpenChart == null ? null : () => onOpenChart!(items[i]),
              onEdit: onEdit == null ? null : () => onEdit!(items[i]),
            ),
            if (i != items.length - 1)
              SizedBox(
                height: ResponsiveHelper.getResponsiveHeight(context, 12),
              ),
          ],
      ],
    );
  }
}

class _PrnCard extends StatelessWidget {
  final StaffClientMedicationItem item;
  final bool canGive;
  final VoidCallback? onGive;
  final VoidCallback? onOpenChart;
  final VoidCallback? onEdit;

  const _PrnCard({
    required this.item,
    required this.canGive,
    this.onGive,
    this.onOpenChart,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final resident = item.clientName.isEmpty
        ? 'Outside your access'
        : item.clientName;
    final initials = resident == 'Outside your access'
        ? '?'
        : resident
            .trim()
            .split(RegExp(r'\s+'))
            .where((p) => p.isNotEmpty)
            .take(2)
            .map((p) => p[0].toUpperCase())
            .join();

    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onOpenChart,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StaffMedicationAvatar(
                    initials: initials.isEmpty ? '?' : initials,
                    palette: AvatarPalette.green,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resident,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          item.residenceName.isEmpty
                              ? '—'
                              : item.residenceName,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.infoBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              if (item.dose.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item.dose,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                item.instructions?.isNotEmpty == true
                    ? 'As Needed. ${item.instructions}'
                    : 'As Needed.',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  color: AppColors.textBody,
                  height: 1.35,
                ),
              ),
              if ((canGive && onGive != null) || onEdit != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (onEdit != null)
                      TextButton.icon(
                        key: ValueKey('staff-prn-edit-${item.id}'),
                        onPressed: onEdit,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.secondaryTeal,
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit prescription'),
                      ),
                    if (canGive && onGive != null)
                      FilledButton(
                        onPressed: onGive,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.secondaryTeal,
                        ),
                        child: const Text('Give PRN'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
