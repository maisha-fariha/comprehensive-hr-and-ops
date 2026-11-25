/// Canadian public holidays shown on the Scheduling calendars and the
/// Appointments calendar (web parity: Canada Day on July 1, plus provincial
/// holidays when a residence has a Canadian province set).
abstract final class CanadianHolidays {
  CanadianHolidays._();

  static const _provinceNames = <String, String>{
    'alberta': 'AB',
    'british columbia': 'BC',
    'manitoba': 'MB',
    'new brunswick': 'NB',
    'newfoundland and labrador': 'NL',
    'newfoundland': 'NL',
    'nova scotia': 'NS',
    'northwest territories': 'NT',
    'nunavut': 'NU',
    'ontario': 'ON',
    'prince edward island': 'PE',
    'quebec': 'QC',
    'québec': 'QC',
    'saskatchewan': 'SK',
    'yukon': 'YT',
  };

  /// Two-letter code for a province name/abbreviation, else `null`.
  static String? provinceCode(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;
    final upper = value.toUpperCase();
    if (_provinceNames.values.contains(upper)) return upper;
    return _provinceNames[value.toLowerCase()];
  }

  /// Holiday name for [date], or `null`. [province] is a name or code; without
  /// a Canadian province only the national holidays apply.
  static String? on(DateTime date, {String? province}) {
    final names = allOn(date, province: province);
    return names.isEmpty ? null : names.join(' · ');
  }

  static List<String> allOn(DateTime date, {String? province}) {
    final code = provinceCode(province);
    final y = date.year;
    final m = date.month;
    final d = date.day;
    final out = <String>[];

    bool isDay(DateTime other) =>
        other.year == y && other.month == m && other.day == d;

    if (m == 1 && d == 1) out.add("New Year's Day");
    if (m == 7 && d == 1) out.add('Canada Day');
    if (m == 12 && d == 25) out.add('Christmas Day');
    if (isDay(_easter(y).subtract(const Duration(days: 2)))) {
      out.add('Good Friday');
    }
    if (isDay(_nthWeekday(y, 9, DateTime.monday, 1))) out.add('Labour Day');
    if (m == 9 && d == 30) {
      out.add('National Day for Truth and Reconciliation');
    }

    if (code == null) return out;

    // Family Day family (third Monday of February).
    if (isDay(_nthWeekday(y, 2, DateTime.monday, 3))) {
      final name = switch (code) {
        'MB' => 'Louis Riel Day',
        'PE' => 'Islander Day',
        'NS' => 'Heritage Day',
        'AB' || 'BC' || 'ON' || 'SK' || 'NB' => 'Family Day',
        _ => null,
      };
      if (name != null) out.add(name);
    }
    // Victoria Day / National Patriots' Day: Monday before May 25.
    final victoria = _mondayBefore(DateTime(y, 5, 25));
    if (isDay(victoria)) {
      if (code == 'QC') {
        out.add("National Patriots' Day");
      } else if (code != 'NB' && code != 'NS' && code != 'PE') {
        out.add('Victoria Day');
      }
    }
    if (code == 'QC' && m == 6 && d == 24) out.add('Saint-Jean-Baptiste Day');
    if (isDay(_nthWeekday(y, 8, DateTime.monday, 1)) &&
        {'BC', 'SK', 'NB', 'NT', 'NU', 'ON', 'AB'}.contains(code)) {
      out.add(switch (code) {
        'SK' => 'Saskatchewan Day',
        'NT' => 'Civic Holiday',
        'NU' => 'Civic Holiday',
        'BC' => 'British Columbia Day',
        'NB' => 'New Brunswick Day',
        _ => 'Civic Holiday',
      });
    }
    if (isDay(_nthWeekday(y, 10, DateTime.monday, 2)) &&
        !{'NB', 'NS', 'NL', 'PE'}.contains(code)) {
      out.add('Thanksgiving');
    }
    if (m == 11 &&
        d == 11 &&
        {'AB', 'BC', 'NB', 'NL', 'NT', 'NU', 'PE', 'SK', 'YT'}.contains(code)) {
      out.add('Remembrance Day');
    }
    if (m == 12 && d == 26 && {'ON'}.contains(code)) out.add('Boxing Day');
    if (code == 'QC' && isDay(_easter(y).add(const Duration(days: 1)))) {
      out.add('Easter Monday');
    }
    return out;
  }

  /// Holidays inside [year]-[month] as `(day, name)`, in day order.
  static List<(int, String)> inMonth(int year, int month, {String? province}) {
    final days = DateTime(year, month + 1, 0).day;
    return [
      for (var day = 1; day <= days; day++)
        if (on(DateTime(year, month, day), province: province)
            case final name?)
          (day, name),
    ];
  }

  static DateTime _nthWeekday(int year, int month, int weekday, int n) {
    final first = DateTime(year, month, 1);
    final offset = (weekday - first.weekday + 7) % 7;
    return DateTime(year, month, 1 + offset + (n - 1) * 7);
  }

  static DateTime _mondayBefore(DateTime date) {
    var d = date.subtract(const Duration(days: 1));
    while (d.weekday != DateTime.monday) {
      d = d.subtract(const Duration(days: 1));
    }
    return d;
  }

  /// Western Easter Sunday (anonymous Gregorian algorithm).
  static DateTime _easter(int year) {
    final a = year % 19;
    final b = year ~/ 100;
    final c = year % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31;
    final day = ((h + l - 7 * m + 114) % 31) + 1;
    return DateTime(year, month, day);
  }
}
