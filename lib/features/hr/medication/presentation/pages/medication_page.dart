import '../../../../staff/medication/presentation/pages/staff_medication_page.dart';

/// Manager Medication entry — same MAR UI as staff and web.
///
/// Prefer this (or [StaffMedicationPage]) from every role so KPIs, Given flags
/// (Given off duty / After its round), and actions stay identical.
class MedicationPage extends StaffMedicationPage {
  const MedicationPage({super.key}) : super(showStaffBottomNav: false);
}
