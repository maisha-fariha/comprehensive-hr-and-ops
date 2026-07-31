import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/widgets/surface_card.dart';
import '../../../domain/entities/visit_request_detail.dart';
import 'visit_request_info_row.dart';

/// "Patient & Family Information" card: "Patient" / "Assigned Staff" /
/// "Room / Location" info rows.
///
/// Icon note: no patient/assigned-staff/room glyphs exist in
/// `assets/icons/*` yet, so this uses Material `Icons.*` placeholders for
/// all 3 rows.
class PatientFamilyInfoCard extends StatelessWidget {
  final VisitRequestDetail detail;

  const PatientFamilyInfoCard({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard.card(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
      child: Column(
        children: [
          VisitRequestInfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Patient',
            value: detail.patientName,
          ),
          _rowDivider(context),
          VisitRequestInfoRow(
            icon: Icons.people_outline_rounded,
            label: 'Assigned Staff',
            value: detail.assignedStaffLabel,
          ),
          _rowDivider(context),
          VisitRequestInfoRow(
            icon: Icons.home_work_outlined,
            label: 'Room / Location',
            value: detail.roomLocationLabel,
          ),
        ],
      ),
    );
  }

  Widget _rowDivider(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: ResponsiveHelper.getResponsiveHeight(context, 14)),
      child: Divider(height: 1, color: AppColors.dividerLight),
    );
  }
}
