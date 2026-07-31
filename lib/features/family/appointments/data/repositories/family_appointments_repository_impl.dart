import 'package:gems_core/gems_core.dart';

import '../../domain/entities/family_appointment.dart';
import '../../domain/entities/family_appointments_enums.dart';
import '../../domain/repositories/family_appointments_repository.dart';

/// Local implementation of [FamilyAppointmentsRepository].
///
/// There is no backend endpoint for Family Appointments yet, so this
/// returns the exact static content shown in the Figma "All - Appointments"
/// / "Upcoming - Appointments" / "Completed - Appointments" screenshots.
class FamilyAppointmentsRepositoryImpl implements FamilyAppointmentsRepository {
  static const List<FamilyAppointment> _appointments = [
    // "Upcoming" section - shared by the "All" and "Upcoming" tabs.
    FamilyAppointment(
      id: 'cardiology-follow-up',
      dateTimeLabel: 'May 14, 2025 · 10:30 AM',
      status: FamilyAppointmentStatus.upcoming,
      title: 'Cardiology Follow-up',
      location: 'Cityview Medical Center',
      iconKind: FamilyAppointmentIconKind.medical,
    ),
    FamilyAppointment(
      id: 'dentist-appointment',
      dateTimeLabel: 'May 20, 2025 · 2:00 PM',
      status: FamilyAppointmentStatus.pending,
      title: 'Dentist Appointment',
      location: 'Bright Smiles Dental',
      iconKind: FamilyAppointmentIconKind.dental,
    ),
    FamilyAppointment(
      id: 'physiotherapy',
      dateTimeLabel: 'May 28, 2025 · 11:00 AM',
      status: FamilyAppointmentStatus.upcoming,
      title: 'Physiotherapy',
      location: 'Sunrise Home - Therapy Room',
      iconKind: FamilyAppointmentIconKind.physiotherapy,
    ),
    // "Family Visits" section - shared by the "All" and "Upcoming" tabs.
    FamilyAppointment(
      id: 'visit-with-emily-upcoming',
      dateTimeLabel: 'May 16, 2025 · 3:00 PM',
      status: FamilyAppointmentStatus.approved,
      title: 'Visit with Emily',
      location: 'Sunrise Home',
      iconKind: FamilyAppointmentIconKind.familyVisit,
    ),
    // "Completed" tab only.
    FamilyAppointment(
      id: 'visit-with-emily-completed',
      dateTimeLabel: 'Apr 30, 2025 · 4:00 PM',
      status: FamilyAppointmentStatus.completed,
      title: 'Visit with Emily',
      location: 'Sunrise Home',
      iconKind: FamilyAppointmentIconKind.familyVisit,
    ),
    FamilyAppointment(
      id: 'gp-check-up',
      dateTimeLabel: 'Apr 22, 2025 · 9:00 AM',
      status: FamilyAppointmentStatus.completed,
      title: 'GP Check-up',
      location: 'Cityview Medical Center',
      iconKind: FamilyAppointmentIconKind.medical,
    ),
    // NOTE: the Figma "Completed - Appointments" screenshot renders this
    // row's icon identically to the "GP Check-up" row above (a plain
    // medical-cross glyph), rather than an optometry-specific glyph, so it
    // is modeled with the same `medical` icon kind for pixel accuracy.
    FamilyAppointment(
      id: 'optometry-exam',
      dateTimeLabel: 'Apr 10, 2025 · 11:30 AM',
      status: FamilyAppointmentStatus.completed,
      title: 'Optometry Exam',
      location: 'Clearview Opticians',
      iconKind: FamilyAppointmentIconKind.medical,
    ),
  ];

  @override
  Future<Result<List<FamilyAppointment>>> getAppointments() async {
    return Result.success(_appointments);
  }
}
