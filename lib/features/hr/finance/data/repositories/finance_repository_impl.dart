import 'package:dio/dio.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/authorized_file.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/finance.dart';
import '../../domain/repositories/finance_repository.dart';
import '../finance_endpoints.dart';
import '../mappers/finance_mapper.dart';

class FinanceRepositoryImpl implements FinanceRepository {
  final AppApiClient _api;

  FinanceRepositoryImpl({required AppApiClient api}) : _api = api;

  @override
  Future<Result<FinancePageResult<PayrollRun>>> listRuns({
    int page = 1,
    int limit = 20,
  }) async {
    final result = await _api.get(
      '${FinanceEndpoints.payrollRuns}?page=$page&limit=$limit',
      silent: true,
    );
    return result.when(
      success: (body) async => Result.success(
        FinanceMapper.pageFrom(body, FinanceMapper.runsFrom,
            fallbackPage: page, fallbackLimit: limit),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<PayrollRun>> getRun(String id) async {
    final result = await _api.get(FinanceEndpoints.payrollRun(id), silent: true);
    return result.when(
      success: (body) async {
        final run = FinanceMapper.runFrom(body);
        if (run == null) {
          return Result.failure(
            const ApiError(message: 'Payroll run not found'),
          );
        }
        return Result.success(run);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<PayrollRun>> createRun({
    required String periodType,
    required String periodStart,
    required String periodEnd,
  }) async {
    final result = await _api.post(
      FinanceEndpoints.payrollRuns,
      data: {
        'periodType': periodType,
        'periodStart': periodStart,
        'periodEnd': periodEnd,
      },
      allowQueue: false,
    );
    return result.when(
      success: (body) async {
        final run = FinanceMapper.runFrom(body);
        if (run == null) {
          return Result.failure(const ApiError(message: 'Run create failed'));
        }
        return Result.success(run);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<PayrollRun>> finalizeRun(String id) async {
    final result = await _api.post(
      FinanceEndpoints.finalizeRun(id),
      data: const {},
      allowQueue: false,
    );
    return result.when(
      success: (body) async {
        final run = FinanceMapper.runFrom(body);
        if (run == null) {
          return Result.failure(const ApiError(message: 'Finalize failed'));
        }
        return Result.success(run);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<PayrollEntry>> adjustEntry({
    required String entryId,
    required double manualAdjustment,
    String? notes,
    String? adjustmentType,
    String? reason,
  }) async {
    final data = <String, dynamic>{
      'manualAdjustment': manualAdjustment,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      if (adjustmentType != null && adjustmentType.isNotEmpty)
        'adjustmentType': adjustmentType,
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    };
    final result = await _api.patch(
      FinanceEndpoints.payrollEntry(entryId),
      data: data,
      allowQueue: false,
    );
    return result.when(
      success: (body) async {
        final entry = FinanceMapper.entryFrom(JsonCodec.unwrap(body));
        if (entry == null) {
          return Result.failure(const ApiError(message: 'Adjust failed'));
        }
        return Result.success(entry);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<PayrollEngine>> engine() async {
    final result = await _api.get(FinanceEndpoints.payrollEngine, silent: true);
    return result.when(
      success: (body) async => Result.success(FinanceMapper.engineFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<PayrollEngine>> setEngine({required bool runHere}) async {
    final result = await _api.put(
      FinanceEndpoints.payrollEngine,
      data: {'runHere': runHere},
      allowQueue: false,
    );
    return result.when(
      success: (body) async => Result.success(FinanceMapper.engineFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<FinancePageResult<PayrollClaim>>> expenseClaims({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final q = StringBuffer('?page=$page&limit=$limit');
    if (status != null && status.isNotEmpty) q.write('&status=$status');
    final result =
        await _api.get('${FinanceEndpoints.expenseClaims}$q', silent: true);
    return result.when(
      success: (body) async => Result.success(
        FinanceMapper.pageFrom(body, FinanceMapper.expenseClaimsFrom,
            fallbackPage: page, fallbackLimit: limit),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<FinancePageResult<PayrollClaim>>> mileageClaims({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final q = StringBuffer('?page=$page&limit=$limit');
    if (status != null && status.isNotEmpty) q.write('&status=$status');
    final result =
        await _api.get('${FinanceEndpoints.mileageClaims}$q', silent: true);
    return result.when(
      success: (body) async => Result.success(
        FinanceMapper.pageFrom(body, FinanceMapper.mileageClaimsFrom,
            fallbackPage: page, fallbackLimit: limit),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<PayrollClaim>> approveExpenseClaim({
    required String id,
    required String status,
  }) async {
    final result = await _api.post(
      FinanceEndpoints.approveExpenseClaim(id),
      data: {'status': status},
      allowQueue: false,
    );
    return result.when(
      success: (body) async =>
          Result.success(_claimResult(body, kind: 'expense', id: id, status: status)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<PayrollClaim>> approveMileageClaim({
    required String id,
    required String status,
  }) async {
    final result = await _api.post(
      FinanceEndpoints.approveMileageClaim(id),
      data: {'status': status},
      allowQueue: false,
    );
    return result.when(
      success: (body) async =>
          Result.success(_claimResult(body, kind: 'mileage', id: id, status: status)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<PayrollClaim>> createExpenseClaim({
    required String staffId,
    required String residenceId,
    required double amount,
    String? description,
  }) async {
    final result = await _api.post(
      FinanceEndpoints.expenseClaims,
      data: {
        'staffId': staffId,
        'residenceId': residenceId,
        'amount': amount,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
      },
      allowQueue: false,
    );
    return result.when(
      success: (body) async => Result.success(
        _claimResult(body, kind: 'expense', id: '', status: 'pending'),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<PayrollClaim>> createMileageClaim({
    required String staffId,
    required String residenceId,
    required double distance,
    required String unit,
  }) async {
    final result = await _api.post(
      FinanceEndpoints.mileageClaims,
      data: {
        'staffId': staffId,
        'residenceId': residenceId,
        'entryMode': 'manual',
        'distance': distance,
        'unit': unit,
      },
      allowQueue: false,
    );
    return result.when(
      success: (body) async => Result.success(
        _claimResult(body, kind: 'mileage', id: '', status: 'pending'),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<MileageRate>>> mileageRates() async {
    final result = await _api.get(FinanceEndpoints.mileageRates, silent: true);
    return result.when(
      success: (body) async =>
          Result.success(FinanceMapper.mileageRatesFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<MileageRate>> createMileageRate({
    required String unit,
    required double rateAmount,
    required String effectiveFrom,
  }) async {
    final result = await _api.post(
      FinanceEndpoints.mileageRates,
      data: {
        'unit': unit,
        'rateAmount': rateAmount,
        'effectiveFrom': effectiveFrom,
      },
      allowQueue: false,
    );
    return result.when(
      success: (body) async {
        final rates = FinanceMapper.mileageRatesFrom({
          'data': [JsonCodec.unwrap(body)],
        });
        if (rates.isEmpty) {
          return Result.failure(const ApiError(message: 'Rate create failed'));
        }
        return Result.success(rates.first);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<MileageRate>> endMileageRate({
    required String rateId,
    required String effectiveTo,
  }) async {
    final result = await _api.patch(
      FinanceEndpoints.mileageRate(rateId),
      data: {'effectiveTo': effectiveTo},
      allowQueue: false,
    );
    return result.when(
      success: (body) async {
        final rates = FinanceMapper.mileageRatesFrom({
          'data': [JsonCodec.unwrap(body)],
        });
        if (rates.isEmpty) {
          return Result.failure(const ApiError(message: 'Rate update failed'));
        }
        return Result.success(rates.first);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<FinanceReport>> report({
    required String from,
    required String to,
    String? residenceId,
  }) async {
    final q = StringBuffer('?from=$from&to=$to');
    if (residenceId != null && residenceId.isNotEmpty) {
      q.write('&residenceId=$residenceId');
    }
    final result = await _api.get(
      '${FinanceEndpoints.financeReport}$q',
      silent: true,
    );
    return result.when(
      success: (body) async => Result.success(FinanceMapper.reportFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<FinanceLedgerEntry>>> ledgerEntries({
    required String from,
    required String to,
    String? residenceId,
  }) async {
    final q = StringBuffer('?from=$from&to=$to&limit=100');
    if (residenceId != null && residenceId.isNotEmpty) {
      q.write('&residenceId=$residenceId');
    }
    final result = await _api.get(
      '${FinanceEndpoints.financeEntries}$q',
      silent: true,
    );
    return result.when(
      success: (body) async =>
          Result.success(FinanceMapper.ledgerEntriesFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<FinanceLedgerEntry>> createLedgerEntry({
    required String residenceId,
    required String entryType,
    required String category,
    required double amount,
    required String occurredOn,
    String? description,
  }) async {
    final result = await _api.post(
      FinanceEndpoints.financeEntries,
      data: {
        'residenceId': residenceId,
        'entryType': entryType,
        'category': category,
        'amount': amount,
        'occurredOn': occurredOn,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
      },
      allowQueue: false,
    );
    return result.when(
      success: (body) async {
        final entries = FinanceMapper.ledgerEntriesFrom({
          'data': [JsonCodec.unwrap(body)],
        });
        if (entries.isEmpty) {
          return Result.failure(const ApiError(message: 'Entry create failed'));
        }
        return Result.success(entries.first);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> deleteLedgerEntry(String id) async {
    final result = await _api.delete(
      FinanceEndpoints.financeEntry(id),
      allowQueue: false,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<ClientCostSummary>> clientCost({
    required String clientId,
    required String from,
    required String to,
  }) async {
    final result = await _api.get(
      '${FinanceEndpoints.clientCost(clientId)}?from=$from&to=$to',
      silent: true,
    );
    return result.when(
      success: (body) async {
        final summary = FinanceMapper.clientCostFrom(body);
        if (summary == null) {
          return Result.failure(const ApiError(message: 'Cost not found'));
        }
        return Result.success(summary);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<BillingAddon>>> addons() async {
    final result = await _api.get(FinanceEndpoints.billingAddons, silent: true);
    return result.when(
      success: (body) async => Result.success(FinanceMapper.addonsFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<QuickBooksStatus>> quickBooksStatus() async {
    final result = await _api.get(FinanceEndpoints.quickbooks, silent: true);
    return result.when(
      success: (body) async =>
          Result.success(FinanceMapper.quickBooksFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<String>> quickBooksConnectUrl() async {
    final result = await _api.post(
      FinanceEndpoints.quickbooksConnect,
      data: const {},
      allowQueue: false,
    );
    return result.when(
      success: (body) async {
        final json = JsonCodec.unwrapMap(body);
        final url = JsonCodec.string(json['authorizeUrl'] ?? json['url']);
        if (url == null || url.isEmpty) {
          return Result.failure(
            const ApiError(message: 'No QuickBooks authorize URL returned'),
          );
        }
        return Result.success(url);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<StaffSensitiveInfo>> staffSensitive(
    String staffId, {
    bool reveal = false,
  }) async {
    final q = reveal ? '?reveal=true' : '';
    final result = await _api.get(
      '${FinanceEndpoints.staffSensitive(staffId)}$q',
      silent: true,
    );
    return result.when(
      success: (body) async =>
          Result.success(FinanceMapper.sensitiveFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<StaffSensitiveInfo>> updateStaffSensitive({
    required String staffId,
    String? sin,
    bool clearSin = false,
    Map<String, String>? banking,
    bool clearBanking = false,
  }) async {
    final data = <String, dynamic>{};
    if (clearSin) {
      data['sin'] = null;
    } else if (sin != null && sin.trim().isNotEmpty) {
      data['sin'] = sin.trim();
    }
    if (clearBanking) {
      data['banking'] = null;
    } else if (banking != null) {
      data['banking'] = banking;
    }
    final result = await _api.put(
      FinanceEndpoints.staffSensitive(staffId),
      data: data,
      allowQueue: false,
    );
    return result.when(
      success: (body) async =>
          Result.success(FinanceMapper.sensitiveFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<FinancePersonOption>>> staffOptions() async {
    final result = await _api.get(
      '${FinanceEndpoints.staff}?page=1&limit=100',
      silent: true,
    );
    return result.when(
      success: (body) async =>
          Result.success(FinanceMapper.staffOptionsFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<FinancePersonOption>>> residenceOptions() async {
    final result = await _api.get(
      '${FinanceEndpoints.residences}?page=1&limit=100',
      silent: true,
    );
    return result.when(
      success: (body) async =>
          Result.success(FinanceMapper.residenceOptionsFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<FinancePersonOption>>> clientOptions({
    String? residenceId,
  }) async {
    final q = StringBuffer('?page=1&limit=200');
    if (residenceId != null && residenceId.isNotEmpty) {
      q.write('&residenceId=$residenceId');
    }
    final result = await _api.get(
      '${FinanceEndpoints.clients}$q',
      silent: true,
    );
    return result.when(
      success: (body) async =>
          Result.success(FinanceMapper.clientOptionsFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<FinanceExportJob>> exportPayrollEntries() async {
    final result = await _api.post(
      FinanceEndpoints.reportsExports,
      data: {
        'reportKey': 'payroll_entries',
        'format': 'csv',
        'filters': <String, dynamic>{},
      },
      allowQueue: false,
    );
    return result.when(
      success: (body) async {
        final jobs = FinanceMapper.exportsFrom({
          'data': [JsonCodec.unwrap(body)],
        });
        if (jobs.isEmpty) {
          return Result.failure(const ApiError(message: 'Export failed'));
        }
        return Result.success(jobs.first);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<FinanceExportJob>>> listPayrollExports() async {
    final result = await _api.get(
      '${FinanceEndpoints.reportsExports}?page=1&limit=20',
      silent: true,
    );
    return result.when(
      success: (body) async {
        final jobs = FinanceMapper.exportsFrom(body)
            .where((j) => j.reportKey == 'payroll_entries')
            .toList();
        return Result.success(jobs);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<int>>> downloadPayrollExport(FinanceExportJob job) async {
    final preferred = job.preferredUrl?.trim().isNotEmpty == true
        ? job.preferredUrl!.trim()
        : FinanceEndpoints.reportsExportDownload(job.id);
    final usesSignedToken = preferred.contains('token=');
    try {
      final headers = <String, dynamic>{
        'Accept': 'text/csv, application/octet-stream, */*',
      };
      if (!usesSignedToken) {
        headers.addAll(AuthorizedFile.headers());
      }
      final response = await Dio().get<List<int>>(
        AuthorizedFile.resolveUrl(preferred),
        options: Options(
          responseType: ResponseType.bytes,
          headers: headers,
          validateStatus: (code) => code != null && code < 500,
        ),
      );
      final code = response.statusCode ?? 0;
      final bytes = response.data ?? const <int>[];
      if (code < 200 || code >= 300 || bytes.isEmpty) {
        return Result.failure(
          const ApiError(message: 'Could not download the export file.'),
        );
      }
      return Result.success(bytes);
    } catch (_) {
      return Result.failure(
        const ApiError(message: 'Could not download the export file.'),
      );
    }
  }

  @override
  Future<Result<PayrollEntry>> setEntryPayment({
    required String entryId,
    required String status,
  }) async {
    final result = await _api.post(
      FinanceEndpoints.entryPayment(entryId),
      data: {'status': status},
      allowQueue: false,
    );
    return result.when(
      success: (body) async {
        final entry = FinanceMapper.entryFrom(JsonCodec.unwrap(body));
        if (entry == null) {
          return Result.failure(
            const ApiError(message: 'Could not update payment status'),
          );
        }
        return Result.success(entry);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<QuickBooksRunStatus>> quickBooksRunStatus(String runId) async {
    final result = await _api.get(
      FinanceEndpoints.quickBooksRun(runId),
      silent: true,
    );
    return result.when(
      success: (body) async =>
          Result.success(FinanceMapper.quickBooksRunStatusFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<QuickBooksRunStatus>> sendRunToQuickBooks(String runId) async {
    final result = await _api.post(
      FinanceEndpoints.quickBooksSendRun(runId),
      data: const <String, dynamic>{},
      allowQueue: false,
    );
    return result.when(
      success: (body) async =>
          Result.success(FinanceMapper.quickBooksRunStatusFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  PayrollClaim _claimResult(
    dynamic body, {
    required String kind,
    required String id,
    required String status,
  }) {
    final unwrapped = JsonCodec.unwrap(body);
    final list = kind == 'expense'
        ? FinanceMapper.expenseClaimsFrom({
            'data': [unwrapped],
          })
        : FinanceMapper.mileageClaimsFrom({
            'data': [unwrapped],
          });
    if (list.isNotEmpty) return list.first;
    return PayrollClaim(
      id: id.isEmpty ? JsonCodec.stringOr(JsonCodec.asMap(unwrapped)['id'], '') : id,
      kind: kind,
      status: status,
      staffName: 'Staff',
      amount: 0,
    );
  }
}
