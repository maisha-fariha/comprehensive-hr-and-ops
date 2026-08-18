import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../domain/entities/staff_medication_enums.dart';
import '../../staff_medication_constants.dart';

/// "Tablet  •  Oral" / "Capsule  •  Oral" / "Injection  •  Subcut." caption
/// under a dose card's medication name.
class MedicationRouteRow extends StatelessWidget {
  final MedicationRoute route;

  static const Color _metaColor = Color(0xFF7E8B9A);

  const MedicationRouteRow({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    final label = StaffMedicationConstants.routeLabel(route).replaceAll(' · ', '  •  ');

    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w400,
        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
        color: _metaColor,
        height: 1.25,
      ),
    );
  }
}
