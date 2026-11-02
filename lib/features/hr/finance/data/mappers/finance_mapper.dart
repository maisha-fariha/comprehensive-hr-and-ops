import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/finance.dart';

abstract final class FinanceMapper {
  static FinancePageResult<T> pageFrom<T>(
    dynamic body,
    List<T> Function(dynamic body) itemsFrom, {
    int fallbackPage = 1,
    int fallbackLimit = 20,
  }) {
    final meta = JsonCodec.metaOf(body) ?? const {};
    final items = itemsFrom(body);
    final total = JsonCodec.integer(meta['total']) ?? items.length;
    final limit = JsonCodec.integer(meta['limit']) ?? fallbackLimit;
    final page = JsonCodec.integer(meta['page']) ?? fallbackPage;
    final totalPages = JsonCodec.integer(meta['totalPages']) ??
        (limit <= 0 ? 1 : ((total + limit - 1) ~/ limit).clamp(1, 999999));
    return FinancePageResult(
      items: items,
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages < 1 ? 1 : totalPages,
    );
  }

  static PayrollEngine engineFrom(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    return PayrollEngine(
      engine: JsonCodec.stringOr(json['engine'], ''),
      provider: JsonCodec.stringOr(json['provider'], json['engine'] ?? ''),
      runHere: JsonCodec.boolean(json['runHere']) ?? false,
    );
  }

  static List<PayrollRun> runsFrom(dynamic body) {
    final rows = JsonCodec.unwrapList(body);
    return [
      for (final row in rows)
        if (runFrom(row) case final run?) run,
    ];
  }

  static PayrollRun? runFrom(dynamic body) {
    final json = JsonCodec.asMap(body is Map && body.containsKey('data')
        ? JsonCodec.unwrapMap(body)
        : body);
    final id = JsonCodec.string(json['id']);
    if (id == null) return null;
    final entries = <PayrollEntry>[];
    for (final row in JsonCodec.listAt(json, 'entries')) {
      final entry = entryFrom(row);
      if (entry != null) entries.add(entry);
    }
    final mileage = JsonCodec.listAt(json, 'mileageClaims');
    final expense = JsonCodec.listAt(json, 'expenseClaims');
    final hoursFromEntries =
        entries.fold<double>(0, (s, e) => s + e.hours + e.overtimeHours);
    return PayrollRun(
      id: id,
      periodType: JsonCodec.stringOr(json['periodType'], ''),
      periodStart: JsonCodec.dateTime(json['periodStart']),
      periodEnd: JsonCodec.dateTime(json['periodEnd']),
      status: JsonCodec.stringOr(json['status'], ''),
      createdAt: JsonCodec.dateTime(json['createdAt']),
      entries: entries,
      claimsCount: mileage.length + expense.length,
      hoursTotal: hoursFromEntries,
    );
  }

  static PayrollEntry? entryFrom(dynamic body) {
    final json = JsonCodec.asMap(body);
    final id = JsonCodec.string(json['id']);
    if (id == null) return null;
    final staff = JsonCodec.mapAt(json, 'staff') ?? const {};
    final first = JsonCodec.stringOr(staff['firstName'], '');
    final last = JsonCodec.stringOr(staff['lastName'], '');
    final name = '$first $last'.trim();
    final category = JsonCodec.mapAt(staff, 'category') ?? const {};
    final role = JsonCodec.string(category['name'] ?? staff['category']);
    String residence = '—';
    final allocations = JsonCodec.listAt(json, 'allocations');
    if (allocations.isNotEmpty) {
      final firstAlloc = JsonCodec.asMap(allocations.first);
      residence = JsonCodec.stringOr(
        firstAlloc['residenceName'],
        '—',
      );
    }
    return PayrollEntry(
      id: id,
      staffId: JsonCodec.stringOr(json['staffId'] ?? staff['id'], ''),
      staffName: name.isEmpty ? 'Staff' : name,
      staffRole: role,
      employmentBasis: JsonCodec.string(json['employmentBasis']),
      residenceName: residence,
      hours: JsonCodec.number(json['hours'])?.toDouble() ?? 0,
      overtimeHours: JsonCodec.number(json['overtimeHours'])?.toDouble() ?? 0,
      overtimeAmount: JsonCodec.number(json['overtimeAmount'])?.toDouble() ?? 0,
      hourlyRate: JsonCodec.number(json['hourlyRate'])?.toDouble(),
      baseAmount: JsonCodec.number(json['baseAmount'])?.toDouble() ?? 0,
      grossAmount: JsonCodec.number(json['grossAmount'])?.toDouble() ?? 0,
      netAmount: JsonCodec.number(json['netAmount'])?.toDouble() ?? 0,
      manualAdjustment:
          JsonCodec.number(json['manualAdjustment'])?.toDouble() ?? 0,
      allowances: JsonCodec.number(json['allowances'])?.toDouble() ?? 0,
      deductions: JsonCodec.number(json['deductions'])?.toDouble() ?? 0,
      paymentStatus: JsonCodec.stringOr(json['paymentStatus'], 'pending'),
    );
  }

  static List<PayrollClaim> expenseClaimsFrom(dynamic body) =>
      _claimsFrom(body, kind: 'expense');

  static List<PayrollClaim> mileageClaimsFrom(dynamic body) =>
      _claimsFrom(body, kind: 'mileage');

  static List<PayrollClaim> _claimsFrom(dynamic body, {required String kind}) {
    final rows = JsonCodec.unwrapList(body);
    return [
      for (final row in rows)
        if (_claimFrom(row, kind: kind) case final claim?) claim,
    ];
  }

  static PayrollClaim? _claimFrom(dynamic body, {required String kind}) {
    final json = JsonCodec.asMap(body);
    final id = JsonCodec.string(json['id']);
    if (id == null) return null;
    final staff = JsonCodec.mapAt(json, 'staff') ?? const {};
    final first = JsonCodec.stringOr(
      staff['firstName'] ?? json['staffFirstName'],
      '',
    );
    final last = JsonCodec.stringOr(
      staff['lastName'] ?? json['staffLastName'],
      '',
    );
    final staffName = JsonCodec.string(json['staffName']) ??
        ('$first $last'.trim().isEmpty ? 'Staff' : '$first $last'.trim());
    final run = JsonCodec.mapAt(json, 'payrollRun') ?? const {};
    final runId = JsonCodec.string(json['payrollRunId'] ?? run['id']);
    String? runLabel;
    if (run.isNotEmpty) {
      runLabel = FinanceLabels.periodLabel(
        JsonCodec.dateTime(run['periodStart']),
        JsonCodec.dateTime(run['periodEnd']),
      );
    }
    return PayrollClaim(
      id: id,
      kind: kind,
      status: JsonCodec.stringOr(json['status'], 'pending'),
      staffName: staffName,
      staffId: JsonCodec.string(json['staffId'] ?? staff['id']),
      amount: JsonCodec.number(json['amount'] ?? json['total'] ?? json['cost'])
              ?.toDouble() ??
          0,
      description: JsonCodec.string(json['description'] ?? json['notes']),
      category: JsonCodec.string(json['category'] ?? json['type']),
      createdAt: JsonCodec.dateTime(json['createdAt'] ?? json['occurredOn']),
      distance: JsonCodec.number(json['distance'] ?? json['miles'] ?? json['km'])
          ?.toDouble(),
      distanceUnit: JsonCodec.string(json['unit'] ?? json['distanceUnit']),
      payrollRunId: runId,
      payrollRunLabel: runLabel,
    );
  }

  static List<MileageRate> mileageRatesFrom(dynamic body) {
    final rows = JsonCodec.unwrapList(body);
    return [
      for (final row in rows)
        if (_mileageRateFrom(row) case final rate?) rate,
    ];
  }

  static MileageRate? _mileageRateFrom(dynamic body) {
    final json = JsonCodec.asMap(body);
    final id = JsonCodec.string(json['id']);
    if (id == null) return null;
    return MileageRate(
      id: id,
      unit: JsonCodec.stringOr(json['unit'], 'km'),
      rateAmount: JsonCodec.number(json['rateAmount'])?.toDouble() ?? 0,
      currency: JsonCodec.stringOr(json['currency'], 'USD'),
      effectiveFrom: JsonCodec.dateTime(json['effectiveFrom']),
      effectiveTo: JsonCodec.dateTime(json['effectiveTo']),
    );
  }

  static FinanceReport reportFrom(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    final period = JsonCodec.mapAt(json, 'period') ?? const {};
    final totals = JsonCodec.mapAt(json, 'totals') ?? const {};
    final residences = <ResidencePnL>[];
    for (final row in JsonCodec.listAt(json, 'residences')) {
      final r = _residencePnLFrom(row);
      if (r != null) residences.add(r);
    }
    final revenueFromResidences =
        residences.fold<double>(0, (s, r) => s + r.revenueTotal);
    final expenseFromResidences =
        residences.fold<double>(0, (s, r) => s + r.expenseTotal);
    final payrollFromResidences =
        residences.fold<double>(0, (s, r) => s + r.payrollExpense);
    final bedNights =
        residences.fold<int>(0, (s, r) => s + r.occupiedBedNights);
    final avgResidents = residences.fold<double>(
          0,
          (s, r) => s + (r.averageResidents ?? r.residents.toDouble()),
        ) /
        (residences.isEmpty ? 1 : residences.length);
    final revenue = JsonCodec.number(totals['revenue'] ?? totals['revenueTotal'])
            ?.toDouble() ??
        revenueFromResidences;
    final expense =
        JsonCodec.number(totals['expenses'] ?? totals['expenseTotal'])
                ?.toDouble() ??
            expenseFromResidences;
    final net = JsonCodec.number(totals['netProfit'] ?? totals['net'])
            ?.toDouble() ??
        (revenue - expense);
    final margin = revenue == 0 ? null : (net / revenue) * 100;
    return FinanceReport(
      from: JsonCodec.dateTime(period['from']),
      to: JsonCodec.dateTime(period['to']),
      residences: residences,
      revenueTotal: revenue,
      expenseTotal: expense,
      payrollTotal: payrollFromResidences,
      netProfit: net,
      margin: JsonCodec.number(totals['margin'])?.toDouble() ?? margin,
      costPerBedNight: bedNights == 0 ? null : expense / bedNights,
      costPerResident: avgResidents == 0 ? null : expense / avgResidents,
      bedNights: bedNights,
      averageResidents: residences.isEmpty ? 0 : avgResidents,
    );
  }

  static ResidencePnL? _residencePnLFrom(dynamic body) {
    final json = JsonCodec.asMap(body);
    final id = JsonCodec.string(json['residenceId'] ?? json['id']);
    if (id == null) return null;
    final revenue = JsonCodec.mapAt(json, 'revenue') ?? const {};
    final expenses = JsonCodec.mapAt(json, 'expenses') ?? const {};
    final occupancy = JsonCodec.mapAt(json, 'occupancy') ?? const {};
    final unitCosts = JsonCodec.mapAt(json, 'unitCosts') ?? const {};
    final byCategory = JsonCodec.listAt(revenue, 'byCategory');
    String? revenueDetail;
    if (byCategory.isNotEmpty) {
      final first = JsonCodec.asMap(byCategory.first);
      final label = JsonCodec.string(first['category'] ?? first['label']);
      final amount = JsonCodec.number(first['amount'] ?? first['total']);
      if (label != null && amount != null) {
        revenueDetail = '${FinanceLabels.money(amount)} $label';
      }
    } else if ((JsonCodec.number(revenue['accruedFees'])?.toDouble() ?? 0) >
        0) {
      revenueDetail =
          '${FinanceLabels.money(revenue['accruedFees'])} from day rates';
    }
    return ResidencePnL(
      residenceId: id,
      residenceName: JsonCodec.stringOr(
        json['residenceName'] ?? json['name'],
        'Residence',
      ),
      revenueTotal: JsonCodec.number(revenue['total'])?.toDouble() ?? 0,
      expenseTotal: JsonCodec.number(expenses['total'])?.toDouble() ?? 0,
      payrollExpense: JsonCodec.number(expenses['payroll'])?.toDouble() ?? 0,
      inventoryExpense: JsonCodec.number(expenses['inventory'])?.toDouble() ?? 0,
      otherExpense: JsonCodec.number(expenses['other'])?.toDouble() ?? 0,
      netProfit: JsonCodec.number(json['netProfit'])?.toDouble() ?? 0,
      margin: JsonCodec.number(json['margin'])?.toDouble(),
      occupancyPercent:
          JsonCodec.number(occupancy['occupancyPercent'])?.toDouble() ?? 0,
      occupiedBedNights:
          JsonCodec.integer(occupancy['occupiedBedDays']) ?? 0,
      residents: JsonCodec.integer(occupancy['residents']) ?? 0,
      averageResidents:
          JsonCodec.number(unitCosts['averageResidents'])?.toDouble(),
      costPerBedNight:
          JsonCodec.number(unitCosts['perOccupiedBedDay'])?.toDouble(),
      costPerResident: JsonCodec.number(unitCosts['perResident'])?.toDouble(),
      revenueDetail: revenueDetail,
    );
  }

  static List<FinanceLedgerEntry> ledgerEntriesFrom(dynamic body) {
    final rows = JsonCodec.unwrapList(body);
    return [
      for (final row in rows)
        if (_ledgerEntryFrom(row) case final entry?) entry,
    ];
  }

  static FinanceLedgerEntry? _ledgerEntryFrom(dynamic body) {
    final json = JsonCodec.asMap(body);
    final id = JsonCodec.string(json['id']);
    if (id == null) return null;
    final residence = JsonCodec.mapAt(json, 'residence') ?? const {};
    return FinanceLedgerEntry(
      id: id,
      entryType: JsonCodec.stringOr(json['entryType'] ?? json['type'], ''),
      category: JsonCodec.stringOr(json['category'], ''),
      amount: JsonCodec.number(json['amount'])?.toDouble() ?? 0,
      description: JsonCodec.string(json['description']),
      residenceId: JsonCodec.string(json['residenceId'] ?? residence['id']),
      residenceName: JsonCodec.string(residence['name'] ?? json['residenceName']),
      occurredOn: JsonCodec.dateTime(json['occurredOn'] ?? json['date']),
    );
  }

  static List<BillingAddon> addonsFrom(dynamic body) {
    final rows = JsonCodec.unwrapList(body);
    return [
      for (final row in rows)
        if (_addonFrom(row) case final addon?) addon,
    ];
  }

  static BillingAddon? _addonFrom(dynamic body) {
    final json = JsonCodec.asMap(body);
    final key = JsonCodec.string(json['key']);
    if (key == null) return null;
    return BillingAddon(
      key: key,
      name: JsonCodec.stringOr(json['name'], key),
      description: JsonCodec.stringOr(json['description'], ''),
      state: JsonCodec.stringOr(json['state'], 'available'),
      price: JsonCodec.number(json['price'])?.toDouble(),
      billingMode: JsonCodec.stringOr(json['billingMode'], 'yearly'),
      grantedByUs: JsonCodec.boolean(json['grantedByUs']) ?? false,
      canBuy: JsonCodec.boolean(json['canBuy']) ?? false,
    );
  }

  static QuickBooksStatus quickBooksFrom(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    return QuickBooksStatus(
      configured: JsonCodec.boolean(json['configured']) ?? false,
      connected: JsonCodec.boolean(json['connected']) ?? false,
      status: JsonCodec.stringOr(json['status'], 'disconnected'),
      companyName: JsonCodec.string(json['companyName']),
      lastError: JsonCodec.string(json['lastError']),
    );
  }

  static StaffSensitiveInfo sensitiveFrom(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    final sin = JsonCodec.mapAt(json, 'sin') ?? const {};
    final banking = JsonCodec.mapAt(json, 'banking') ?? const {};
    return StaffSensitiveInfo(
      staffId: JsonCodec.stringOr(json['staffId'], ''),
      revealed: JsonCodec.boolean(json['revealed']) ?? false,
      sinOnFile: JsonCodec.boolean(sin['onFile']) ?? false,
      sinMasked: JsonCodec.string(sin['masked']),
      sinValue: JsonCodec.string(sin['value']),
      bankingOnFile: JsonCodec.boolean(banking['onFile']) ?? false,
      institutionNumber: JsonCodec.string(banking['institutionNumber']),
      transitNumber: JsonCodec.string(banking['transitNumber']),
      accountNumber: JsonCodec.string(banking['accountNumber']),
      accountMasked: JsonCodec.string(banking['accountMasked']),
    );
  }

  static List<FinancePersonOption> staffOptionsFrom(dynamic body) {
    final rows = JsonCodec.unwrapList(body);
    final out = <FinancePersonOption>[];
    for (final row in rows) {
      final json = JsonCodec.asMap(row);
      final id = JsonCodec.string(json['id']);
      if (id == null) continue;
      final first = JsonCodec.stringOr(json['firstName'], '');
      final last = JsonCodec.stringOr(json['lastName'], '');
      final name = '$first $last'.trim();
      out.add(
        FinancePersonOption(
          id: id,
          name: name.isEmpty ? 'Staff' : name,
          paymentDuration: JsonCodec.string(json['paymentDuration']),
        ),
      );
    }
    return out;
  }

  static List<FinancePersonOption> residenceOptionsFrom(dynamic body) {
    final rows = JsonCodec.unwrapList(body);
    final out = <FinancePersonOption>[];
    for (final row in rows) {
      final json = JsonCodec.asMap(row);
      final id = JsonCodec.string(json['id']);
      if (id == null) continue;
      final settings = JsonCodec.mapAt(json, 'payrollSettings') ?? const {};
      out.add(
        FinancePersonOption(
          id: id,
          name: JsonCodec.stringOr(json['name'], 'Residence'),
          mileageEnabled: JsonCodec.boolean(settings['mileageEnabled']) ?? false,
          outOfPocketEnabled:
              JsonCodec.boolean(settings['outOfPocketEnabled']) ?? false,
        ),
      );
    }
    return out;
  }

  static List<FinancePersonOption> clientOptionsFrom(dynamic body) {
    final rows = JsonCodec.unwrapList(body);
    final out = <FinancePersonOption>[];
    for (final row in rows) {
      final json = JsonCodec.asMap(row);
      final id = JsonCodec.string(json['id']);
      if (id == null) continue;
      final first = JsonCodec.stringOr(json['firstName'], '');
      final last = JsonCodec.stringOr(json['lastName'], '');
      final name = '$first $last'.trim();
      out.add(
        FinancePersonOption(
          id: id,
          name: name.isEmpty
              ? JsonCodec.stringOr(json['preferredName'], 'Resident')
              : name,
        ),
      );
    }
    return out;
  }

  static ClientCostSummary? clientCostFrom(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    final id = JsonCodec.string(json['clientId']);
    if (id == null) return null;
    final cost = JsonCodec.mapAt(json, 'cost') ?? const {};
    final revenue = JsonCodec.mapAt(json, 'revenue') ?? const {};
    final billTo = JsonCodec.mapAt(json, 'billTo') ?? const {};
    return ClientCostSummary(
      clientId: id,
      clientName: JsonCodec.stringOr(json['clientName'], 'Resident'),
      residenceName: JsonCodec.string(json['residenceName']),
      nights: JsonCodec.integer(json['nights']) ?? 0,
      costTotal: JsonCodec.number(cost['total'])?.toDouble() ?? 0,
      revenueTotal: JsonCodec.number(revenue['total'])?.toDouble() ?? 0,
      variance: JsonCodec.number(json['variance'])?.toDouble() ?? 0,
      overheadShare: JsonCodec.number(cost['overheadShare'])?.toDouble() ?? 0,
      fundingSource: JsonCodec.string(billTo['fundingSource']),
    );
  }

  static List<FinanceExportJob> exportsFrom(dynamic body) {
    final rows = JsonCodec.unwrapList(body);
    return [
      for (final row in rows)
        if (_exportFrom(row) case final job?) job,
    ];
  }

  static FinanceExportJob? _exportFrom(dynamic body) {
    final json = JsonCodec.asMap(body is Map && body.containsKey('data')
        ? JsonCodec.unwrapMap(body)
        : body);
    final id = JsonCodec.string(json['id']);
    if (id == null) return null;
    return FinanceExportJob(
      id: id,
      reportKey: JsonCodec.stringOr(json['reportKey'], ''),
      status: JsonCodec.stringOr(json['status'], ''),
      createdAt: JsonCodec.dateTime(json['createdAt']),
      fileUrl: JsonCodec.string(json['fileUrl']),
    );
  }

  static PayrollOverviewStats overviewFrom({
    required List<PayrollRun> runs,
    required List<PayrollClaim> expenseClaims,
    required List<PayrollClaim> mileageClaims,
    PayrollEngine? engine,
    int residentCount = 0,
  }) {
    final active = _latestPeriodRun(runs);
    final entries = active?.entries ?? const <PayrollEntry>[];
    final pending = [
      ...expenseClaims.where((c) => c.status.toLowerCase() == 'pending'),
      ...mileageClaims.where((c) => c.status.toLowerCase() == 'pending'),
    ];
    final draftRuns =
        runs.where((r) => r.status.toLowerCase() == 'draft').length;
    final reimbursements = [
      ...expenseClaims.where((c) => c.status.toLowerCase() == 'approved'),
      ...mileageClaims.where((c) => c.status.toLowerCase() == 'approved'),
    ];
    final reimburseTotal =
        reimbursements.fold<double>(0, (s, c) => s + c.amount);
    final label = active == null
        ? null
        : FinanceLabels.periodLabel(active.periodStart, active.periodEnd);
    final provider = (engine?.provider ?? engine?.engine ?? '').trim();
    final payroll =
        entries.fold<double>(0, (s, e) => s + e.grossAmount + e.manualAdjustment);
    final hours = entries.fold<double>(0, (s, e) => s + e.hours);
    final otHours = entries.fold<double>(0, (s, e) => s + e.overtimeHours);
    final otCost = entries.fold<double>(0, (s, e) => s + e.overtimeAmount);
    return PayrollOverviewStats(
      totalPayroll: payroll,
      staffHours: hours,
      overtimeHours: otHours,
      overtimeCost: otCost,
      pendingApprovals: pending.length,
      draftRuns: draftRuns,
      staffOnRun: entries.length,
      reimbursements: reimburseTotal,
      reimbursementClaims: reimbursements.length,
      costPerClient: residentCount <= 0 ? 0 : payroll / residentCount,
      residentCount: residentCount,
      runStatus: active?.status ?? '',
      payPeriodLabel: label,
      engineLabel: provider.isEmpty ? null : provider,
    );
  }

  static PayrollRun? _latestPeriodRun(List<PayrollRun> runs) {
    if (runs.isEmpty) return null;
    final sorted = [...runs]..sort((a, b) {
        final aStart = a.periodStart ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bStart = b.periodStart ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bStart.compareTo(aStart);
      });
    return sorted.first;
  }
}

/// Formatting helpers kept next to the mapper for tests.
abstract final class FinanceLabels {
  static const pageSizes = [10, 20, 50];

  static const periodTypes = [
    ('bi_weekly', 'Every two weeks'),
    ('semi_monthly', 'Twice a month'),
  ];

  static const revenueCategories = [
    ('resident_fees', 'Resident fees'),
    ('funding', 'Funding'),
    ('grants', 'Grants'),
    ('donations', 'Donations'),
    ('other', 'Other'),
  ];

  static const expenseCategories = [
    ('rent', 'Rent'),
    ('utilities', 'Utilities'),
    ('maintenance', 'Maintenance'),
    ('food', 'Food & catering'),
    ('transport', 'Transport'),
    ('insurance', 'Insurance'),
    ('licensing', 'Licensing'),
    ('training', 'Training'),
    ('professional_fees', 'Professional fees'),
    ('other', 'Other'),
  ];

  static String money(num? value) {
    if (value == null) return '—';
    final negative = value < 0;
    final fixed = value.abs().toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return '${negative ? '-' : ''}\$$whole.${parts[1]}';
  }

  static String periodLabel(DateTime? from, DateTime? to) {
    if (from == null && to == null) return '—';
    String d(DateTime v) =>
        '${v.day.toString().padLeft(2, '0')}/${v.month.toString().padLeft(2, '0')}/${v.year}';
    if (from != null && to != null) return '${d(from)} – ${d(to)}';
    return d(from ?? to!);
  }

  static String statusLabel(String raw) {
    final v = raw.trim().toLowerCase().replaceAll('_', ' ');
    if (v.isEmpty) return '—';
    return v[0].toUpperCase() + v.substring(1);
  }

  static String periodTypeLabel(String raw) {
    return switch (raw.trim().toLowerCase()) {
      'weekly' => 'Weekly',
      'bi_weekly' || 'biweekly' => 'Bi weekly',
      'semi_monthly' || 'semimonthly' => 'Semi monthly',
      'monthly' => 'Monthly',
      _ => statusLabel(raw),
    };
  }

  static String addonBadge(BillingAddon addon) {
    if (addon.grantedByUs) return 'Given by us — free';
    return switch (addon.state.toLowerCase()) {
      'included' => 'Included in your plan',
      'active' => 'Active',
      'available' => 'Available',
      _ => statusLabel(addon.state),
    };
  }

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static String ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
