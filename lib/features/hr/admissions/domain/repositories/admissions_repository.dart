import 'package:gems_core/gems_core.dart';

import '../entities/referral.dart';

abstract class AdmissionsRepository {
  /// `GET /referrals/board` - the four KPI counts.
  Future<Result<ReferralBoard>> board();

  /// `GET /referrals` - [status] null lists every stage.
  Future<Result<ReferralPage>> referrals({
    required int page,
    required int limit,
    String? search,
    String? status,
  });

  /// `GET /referrals/:id` with assessments, contacts, events and documents.
  Future<Result<Referral>> referral(String id);

  /// `POST /referrals`.
  Future<Result<void>> createReferral(Map<String, dynamic> body);

  /// `PATCH /referrals/:id` - details or `{status}`.
  Future<Result<void>> updateReferral(String id, Map<String, dynamic> body);

  /// `PUT /referrals/:id/contacts` - replaces the whole list.
  Future<Result<void>> setContacts(String id, List<Map<String, dynamic>> contacts);

  /// `PUT /referrals/:id/checklist`.
  Future<Result<void>> setChecklist(String id, List<String> completed);

  /// `POST /referrals/:id/assessments`.
  Future<Result<void>> addAssessment(
    String id, {
    required String summary,
    String? outcome,
  });

  /// `POST /referrals/:id/admit` - creates the resident record.
  Future<Result<void>> admit(
    String id, {
    required String residenceId,
    String? roomId,
    String? level,
  });

  /// `POST /referrals/:id/decline`.
  Future<Result<void>> decline(String id, String reason);

  /// `DELETE /referrals/:id` - soft delete.
  Future<Result<void>> deleteReferral(String id);

  /// `GET /intake-templates?activeOnly=`.
  Future<Result<List<IntakeTemplate>>> templates({bool activeOnly = false});

  /// `POST /intake-templates`.
  Future<Result<void>> createTemplate(Map<String, dynamic> body);

  /// `PATCH /intake-templates/:id` - the whole form or `{isActive}`.
  Future<Result<void>> updateTemplate(String id, Map<String, dynamic> body);

  Future<Result<List<AdmissionOption>>> residences();

  Future<Result<List<AdmissionRoom>>> rooms(String residenceId);
}
