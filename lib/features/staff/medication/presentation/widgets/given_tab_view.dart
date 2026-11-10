import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/administered_dose.dart';
import 'administered_tab_view.dart';
import 'staff_medication_avatar.dart';

/// Web Given tab — history from `GET /mar/administrations`.
class GivenTabView extends StatefulWidget {
  final List<AdministeredDose> doses;

  const GivenTabView({super.key, required this.doses});

  @override
  State<GivenTabView> createState() => _GivenTabViewState();
}

class _GivenTabViewState extends State<GivenTabView> {
  /// Web "Off duty only — doses to review".
  bool _offDutyOnly = false;

  List<AdministeredDose> get _visible {
    if (!_offDutyOnly) return widget.doses;
    return [
      for (final d in widget.doses)
        if (d.isOffDutyReview) d,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final doses = _visible;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Given',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.textHeading,
                ),
              ),
            ),
            StaffMedicationCountLabel(
              text: '${doses.length} recorded',
              background: const Color(0xFFE8F6EF),
              foreground: const Color(0xFF2D8A56),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          key: const ValueKey('mar-given-off-duty-only'),
          onTap: () => setState(() => _offDutyOnly = !_offDutyOnly),
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _offDutyOnly,
                  activeColor: AppColors.secondaryTeal,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  onChanged: (v) =>
                      setState(() => _offDutyOnly = v ?? false),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Off duty only — doses to review',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        if (doses.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(
              _offDutyOnly
                  ? 'No off-duty doses to review.'
                  : 'No administrations recorded yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
          )
        else
          for (var i = 0; i < doses.length; i++) ...[
            _GivenCard(dose: doses[i]),
            if (i != doses.length - 1)
              SizedBox(
                height: ResponsiveHelper.getResponsiveHeight(context, 12),
              ),
          ],
      ],
    );
  }
}

class _GivenCard extends StatelessWidget {
  final AdministeredDose dose;

  const _GivenCard({required this.dose});

  (Color bg, Color fg) get _outcomeTone {
    final label = dose.outcomeLabel.toLowerCase();
    if (label.contains('miss')) {
      return (AppColors.criticalBackground, AppColors.criticalRed);
    }
    if (label.contains('refus')) {
      return (AppColors.urgentBackgroundSoft, AppColors.urgentAmber);
    }
    if (label.contains('withheld') || label.contains('not available')) {
      return (AppColors.filterButtonBackground, AppColors.textSecondary);
    }
    return (const Color(0xFFE8F6EF), const Color(0xFF2D8A56));
  }

  @override
  Widget build(BuildContext context) {
    final tone = _outcomeTone;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dose.givenTimeLabel.isEmpty ? '—' : dose.givenTimeLabel,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          if (dose.wasLate)
            const Text(
              'After its round',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.urgentAmber,
              ),
            ),
          if (dose.administeredOnDuty == false)
            const Text(
              'Given off duty',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.criticalRed,
              ),
            ),
          if (dose.witnessOnDuty == false)
            const Text(
              'Witness off duty',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.criticalRed,
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              StaffMedicationAvatar(
                initials: dose.residentInitials,
                palette: dose.avatarColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dose.residentName,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      dose.dose.isEmpty
                          ? dose.medicationName
                          : '${dose.medicationName} · ${dose.dose}',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tone.$1,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  dose.outcomeLabel,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: tone.$2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Signed · ${dose.administeredByName}',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
