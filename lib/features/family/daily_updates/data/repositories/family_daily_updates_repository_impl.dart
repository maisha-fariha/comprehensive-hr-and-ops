import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/family_care_journal_models.dart';
import '../../domain/entities/family_daily_updates_overview.dart';
import '../../domain/repositories/family_daily_updates_repository.dart';
import '../mappers/family_daily_updates_mapper.dart';

class FamilyDailyUpdatesRepositoryImpl implements FamilyDailyUpdatesRepository {
  final AppApiClient _api;
  final UserSession _session;

  FamilyDailyUpdatesRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
  })  : _api = api,
        _session = session;

  @override
  Future<Result<FamilyDailyUpdatesOverview>> getOverview() async {
    final journal = await getCareJournal();
    return journal.when(
      success: (data) async => Result.success(
        FamilyDailyUpdatesOverview(
          screenTitle: 'Care Journal',
          screenSubtitle:
              'A transparent view of daily routines, nourishment, physical wellbeing, and moments.',
          dateSectionLabel: data.days.isEmpty
              ? 'No notes yet'
              : data.days.first.dateLabel,
          entries: data.allNotes,
          footerNote: data.footerNote,
        ),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<FamilyCareJournalOverview>> getCareJournal({
    String? clientId,
  }) async {
    final clientsResult = await _api.get(ApiEndpoints.familyClients, silent: true);
    final clientsBody = clientsResult.isSuccess
        ? clientsResult.value
        : await _clientsFromHome();

    final clients = FamilyDailyUpdatesMapper.careJournalFrom(
      clientsBody: clientsBody,
      dailyUpdatesBody: const [],
    ).clients;

    if (clients.isEmpty) {
      return Result.success(
        const FamilyCareJournalOverview(
          clients: [],
          selectedClientId: '',
          days: [],
          footerNote:
              'The care home links your account to your relative. Contact reception if you expected access.',
        ),
      );
    }

    final selected = () {
      final want = (clientId ?? _session.selectedClientId ?? '').trim();
      if (want.isNotEmpty && clients.any((c) => c.id == want)) return want;
      return clients.first.id;
    }();

    _session.applyFamilyHome(clientId: selected);

    final selectedClient = clients.firstWhere((c) => c.id == selected);
    final visibility = _session.familyVisibility;

    final daily = await _api.get(
      ApiEndpoints.familyDailyUpdates(selected),
      silent: true,
    );
    if (daily.isFailure &&
        _isDisabled(daily.error?.code, 'FAMILY_DAILY_LOGS_DISABLED')) {
      return Result.success(
        FamilyCareJournalOverview(
          clients: clients,
          selectedClientId: selected,
          days: const [],
          footerNote: daily.error?.message ??
              'Daily care notes are not shared for this resident.',
        ),
      );
    }

    Result<dynamic>? conditionsResult;
    Result<dynamic>? medsResult;
    Result<dynamic>? momentsResult;
    Result<dynamic>? activitiesResult;

    if (selectedClient.medicalConditions || visibility.medicalConditions) {
      conditionsResult = await _api.get(
        ApiEndpoints.familyClientMedicalConditions(selected),
        silent: true,
      );
    }
    if (selectedClient.medications || visibility.medications) {
      medsResult = await _api.get(
        ApiEndpoints.familyClientMedications(selected),
        silent: true,
      );
    }
    momentsResult = await _api.get(
      ApiEndpoints.familyClientMoments(selected),
      silent: true,
    );
    if (selectedClient.activities || visibility.activities) {
      activitiesResult = await _api.get(
        ApiEndpoints.familyClientActivities(selected),
        silent: true,
      );
    }

    final medsDisabled = medsResult != null &&
        medsResult.isFailure &&
        _isDisabled(medsResult.error?.code, 'FAMILY_MEDICATIONS_DISABLED');
    final conditionsDisabled = conditionsResult != null &&
        conditionsResult.isFailure &&
        _isDisabled(
          conditionsResult.error?.code,
          'FAMILY_MEDICAL_CONDITIONS_DISABLED',
        );

    if (daily.isFailure && !medsDisabled && conditionsResult == null) {
      // Hard failure loading notes when that is the only source.
      return Result.failure(
        daily.error ?? const ApiError(message: 'Could not load Care Journal.'),
      );
    }

    return Result.success(
      FamilyDailyUpdatesMapper.careJournalFrom(
        clientsBody: clientsBody,
        dailyUpdatesBody: daily.isSuccess ? daily.value : const [],
        medicalConditionsBody: (conditionsResult?.isSuccess ?? false)
            ? conditionsResult!.value
            : null,
        medicationsBody:
            (medsResult?.isSuccess ?? false) ? medsResult!.value : null,
        momentsBody:
            momentsResult.isSuccess ? momentsResult.value : null,
        activitiesBody: (activitiesResult?.isSuccess ?? false)
            ? activitiesResult!.value
            : null,
        selectedClientId: selected,
        visibility: visibility,
        medicationsDisabled: medsDisabled || !selectedClient.medications,
        medicalConditionsDisabled:
            conditionsDisabled || !selectedClient.medicalConditions,
        medicationsError: medsDisabled ? medsResult.error?.message : null,
        medicalConditionsError:
            conditionsDisabled ? conditionsResult.error?.message : null,
      ),
    );
  }

  Future<dynamic> _clientsFromHome() async {
    final home = await _api.get(ApiEndpoints.familyHome, silent: true);
    if (home.isFailure) return const [];
    final map = JsonCodec.unwrapMap(home.value);
    return JsonCodec.listAt(map, 'linkedClients');
  }

  bool _isDisabled(String? code, String expected) {
    final c = (code ?? '').toUpperCase();
    return c == expected || c.contains('DISABLED');
  }
}
