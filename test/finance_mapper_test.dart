import 'package:comprehensive_hr_and_ops/features/hr/finance/data/mappers/finance_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('runsFrom maps payroll run entries with residence allocation', () {
    final runs = FinanceMapper.runsFrom({
      'data': [
        {
          'id': 'run-1',
          'periodType': 'semi_monthly',
          'periodStart': '2026-10-29T00:00:00.000Z',
          'periodEnd': '2026-11-07T00:00:00.000Z',
          'status': 'finalized',
          'entries': [
            {
              'id': 'e1',
              'staffId': 's1',
              'hours': 8,
              'overtimeHours': 1,
              'overtimeAmount': 25,
              'baseAmount': 100,
              'grossAmount': 125,
              'manualAdjustment': -5,
              'netAmount': 120,
              'allowances': 0,
              'deductions': 5,
              'paymentStatus': 'pending',
              'staff': {'firstName': 'Ada', 'lastName': 'Lovelace'},
              'allocations': [
                {
                  'residenceId': 'r1',
                  'residenceName': 'Cozzy Cottege',
                  'percent': 100,
                },
              ],
            },
          ],
        },
      ],
    });

    expect(runs, hasLength(1));
    expect(runs.single.status, 'finalized');
    expect(runs.single.grossTotal, 120);
    expect(runs.single.entries.single.staffName, 'Ada Lovelace');
    expect(runs.single.entries.single.overtimeAmount, 25);
    expect(runs.single.entries.single.residenceName, 'Cozzy Cottege');
    expect(runs.single.entries.single.manualAdjustment, -5);
  });

  test('reportFrom maps residence P&L totals and unit costs', () {
    final report = FinanceMapper.reportFrom({
      'data': {
        'period': {'from': '2026-01-01', 'to': '2026-12-31'},
        'totals': {
          'revenue': 10.26,
          'expenses': 400,
          'netProfit': -389.74,
        },
        'residences': [
          {
            'residenceId': 'r1',
            'residenceName': 'Cozzy',
            'revenue': {
              'total': 10.26,
              'accruedFees': 10.26,
              'ledger': 0,
            },
            'expenses': {
              'total': 400,
              'payroll': 300,
              'inventory': 100,
              'other': 0,
              'manualPayroll': 0,
              'manualInventory': 0,
            },
            'netProfit': -389.74,
            'occupancy': {
              'occupancyPercent': 1.18,
              'residents': 2,
              'occupiedBedDays': 4,
            },
            'unitCosts': {
              'perOccupiedBedDay': 100,
              'perResident': 200,
              'averageResidents': 2,
            },
          },
        ],
      },
    });

    expect(report.residences, hasLength(1));
    expect(report.revenueTotal, 10.26);
    expect(report.residences.single.payrollExpense, 300);
    expect(report.residences.single.residenceName, 'Cozzy');
    expect(report.residences.single.occupiedBedNights, 4);
    expect(report.bedNights, 4);
  });

  test('expenseClaimsFrom maps claim rows', () {
    final claims = FinanceMapper.expenseClaimsFrom({
      'data': [
        {
          'id': 'c1',
          'status': 'pending',
          'amount': 42.5,
          'category': 'travel',
          'description': 'Taxi',
          'staff': {'firstName': 'Sam', 'lastName': 'Lee'},
        },
      ],
    });
    expect(claims.single.kind, 'expense');
    expect(claims.single.staffName, 'Sam Lee');
    expect(claims.single.amount, 42.5);
  });

  test('overviewFrom aggregates latest run and pending claims', () {
    final runs = FinanceMapper.runsFrom({
      'data': [
        {
          'id': 'run-old',
          'periodType': 'weekly',
          'periodStart': '2026-01-01T00:00:00.000Z',
          'periodEnd': '2026-01-07T00:00:00.000Z',
          'status': 'finalized',
          'entries': [
            {
              'id': 'e0',
              'staffId': 's0',
              'hours': 1,
              'overtimeHours': 0,
              'overtimeAmount': 0,
              'baseAmount': 10,
              'grossAmount': 10,
              'netAmount': 10,
              'allowances': 0,
              'deductions': 0,
              'paymentStatus': 'paid',
              'staff': {'firstName': 'Old', 'lastName': 'Run'},
            },
          ],
        },
        {
          'id': 'run-new',
          'periodType': 'weekly',
          'periodStart': '2026-10-01T00:00:00.000Z',
          'periodEnd': '2026-10-07T00:00:00.000Z',
          'status': 'draft',
          'entries': [
            {
              'id': 'e1',
              'staffId': 's1',
              'hours': 8,
              'overtimeHours': 2,
              'overtimeAmount': 40,
              'baseAmount': 100,
              'grossAmount': 140,
              'netAmount': 140,
              'allowances': 0,
              'deductions': 0,
              'paymentStatus': 'pending',
              'staff': {'firstName': 'New', 'lastName': 'Run'},
            },
          ],
        },
      ],
    });
    final expenses = FinanceMapper.expenseClaimsFrom({
      'data': [
        {
          'id': 'c1',
          'status': 'pending',
          'amount': 5,
          'staff': {'firstName': 'A', 'lastName': 'B'},
        },
      ],
    });
    final stats = FinanceMapper.overviewFrom(
      runs: runs,
      expenseClaims: expenses,
      mileageClaims: const [],
      residentCount: 2,
    );
    expect(stats.totalPayroll, 140);
    expect(stats.overtimeCost, 40);
    expect(stats.pendingApprovals, 1);
    expect(stats.draftRuns, 1);
    expect(stats.staffOnRun, 1);
    expect(stats.costPerClient, 70);
  });

  test('pageFrom reads list meta for pagination', () {
    final page = FinanceMapper.pageFrom(
      {
        'data': [
          {
            'id': 'run-1',
            'periodType': 'bi_weekly',
            'status': 'finalized',
            'entries': [],
          },
        ],
        'meta': {
          'page': 2,
          'limit': 10,
          'total': 25,
          'totalPages': 3,
        },
      },
      FinanceMapper.runsFrom,
    );
    expect(page.page, 2);
    expect(page.limit, 10);
    expect(page.total, 25);
    expect(page.totalPages, 3);
    expect(page.items, hasLength(1));
  });

  test('addons and sensitive banking map from API envelopes', () {
    final addons = FinanceMapper.addonsFrom({
      'data': [
        {
          'key': 'quickbooks',
          'name': 'QuickBooks Online',
          'description': 'Send hours',
          'state': 'active',
          'billingMode': 'yearly',
          'price': 150,
          'grantedByUs': true,
          'canBuy': false,
        },
      ],
    });
    expect(addons.single.key, 'quickbooks');
    expect(FinanceLabels.addonBadge(addons.single), 'Given by us — free');

    final sensitive = FinanceMapper.sensitiveFrom({
      'data': {
        'staffId': 's1',
        'revealed': false,
        'sin': {'onFile': false, 'masked': null, 'value': null},
        'banking': {
          'onFile': false,
          'accountMasked': null,
          'institutionNumber': null,
          'transitNumber': null,
          'accountNumber': null,
        },
      },
    });
    expect(sensitive.staffId, 's1');
    expect(sensitive.sinOnFile, isFalse);
    expect(sensitive.bankingOnFile, isFalse);
  });

  test('mileageRatesFrom maps active rates', () {
    final rates = FinanceMapper.mileageRatesFrom({
      'data': [
        {
          'id': 'rate-1',
          'unit': 'km',
          'rateAmount': 0.72,
          'currency': 'CAD',
          'effectiveFrom': '2026-11-01',
          'effectiveTo': null,
        },
      ],
    });
    expect(rates.single.unit, 'km');
    expect(rates.single.rateAmount, 0.72);
    expect(rates.single.isActive, isTrue);
  });
}
