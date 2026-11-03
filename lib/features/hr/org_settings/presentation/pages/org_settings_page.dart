import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../../core/time/tenant_clock.dart';
import '../../../hr_shell.dart';
import '../../../presentation/widgets/hr_bottom_nav_bar.dart';

/// Organisation Settings — the web `/dashboard/settings` tabs.
///
/// Residence managers can read these values (`settings:read`) and the web
/// leaves every control, including Save changes, disabled.
class OrgSettingsPage extends StatefulWidget {
  final Future<OrgSettingsSnapshot> Function()? load;

  /// Bottom navigation used by the other More-menu pages.
  final bool showShell;

  const OrgSettingsPage({super.key, this.load, this.showShell = true});

  @override
  State<OrgSettingsPage> createState() => _OrgSettingsPageState();
}

class OrgSettingsSnapshot {
  final Map<String, dynamic> settings;
  final int? defaultBreakMinutes;
  final bool canWrite;
  final String? error;

  const OrgSettingsSnapshot({
    required this.settings,
    this.defaultBreakMinutes,
    this.canWrite = false,
    this.error,
  });

  bool get failed => error != null;
}

Future<OrgSettingsSnapshot> loadOrgSettings() async {
  final api = GetIt.instance<AppApiClient>();
  final settings = await api.get(ApiEndpoints.settings, silent: true);
  if (!settings.isSuccess) {
    return OrgSettingsSnapshot(
      settings: const {},
      error: settings.error?.message ?? 'Could not load settings',
    );
  }
  final map = JsonCodec.unwrapMap(settings.value);
  final general = JsonCodec.asMap(map['general']);
  TenantClock.use(
    JsonCodec.string(general['timezone']),
    dateFmt: JsonCodec.string(general['dateFormat']),
    timeFmt: JsonCodec.string(general['timeFormat']),
  );

  int? breakMinutes;
  final scheduling = await api.get(ApiEndpoints.settingsScheduling, silent: true);
  if (scheduling.isSuccess) {
    breakMinutes = JsonCodec.integer(
      JsonCodec.unwrapMap(scheduling.value)['defaultBreakMinutes'],
    );
  }

  var canWrite = false;
  if (Get.isRegistered<UserSession>()) {
    canWrite = Get.find<UserSession>().can('settings:write');
  }
  return OrgSettingsSnapshot(
    settings: map,
    defaultBreakMinutes: breakMinutes,
    canWrite: canWrite,
  );
}

class _OrgSettingsPageState extends State<OrgSettingsPage> {
  static const _tabs = [
    'General',
    'Notifications',
    'Security',
    'Family portal',
    'Payroll',
    'Care & operations',
  ];

  final ScrollController _scroll = ScrollController();
  int _tab = 0;
  bool _loading = true;
  OrgSettingsSnapshot? _snapshot;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final snapshot = await (widget.load ?? loadOrgSettings)();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _snapshot = snapshot;
    });
  }

  void _selectTab(int index) {
    setState(() => _tab = index);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        foregroundColor: AppColors.textHeading,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            color: AppColors.textHeading,
          ),
        ),
      ),
      bottomNavigationBar: widget.showShell
          ? HrBottomNavBar(
              currentIndex: 4,
              onTap: (index) => Get.offAll(() => HrShell(initialIndex: index)),
              alertsBadgeCount: hrAlertsBadgeCount(),
            )
          : null,
      body: SafeArea(
        top: false,
        bottom: !widget.showShell,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _snapshot?.failed == true
                ? _Error(message: _snapshot!.error!, onRetry: _reload)
                : Column(
                    children: [
                      ColoredBox(
                        color: AppColors.surfaceWhite,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              for (var index = 0; index < _tabs.length; index++) ...[
                                if (index > 0) const SizedBox(width: 8),
                                ChoiceChip(
                                  label: Text(_tabs[index]),
                                  selected: index == _tab,
                                  onSelected: (_) => _selectTab(index),
                                  labelStyle: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.w600,
                                    color: index == _tab
                                        ? Colors.white
                                        : AppColors.textHeading,
                                  ),
                                  selectedColor: AppColors.secondaryTeal,
                                  backgroundColor: AppColors.scaffoldBackground,
                                  side: BorderSide(
                                    color: index == _tab
                                        ? AppColors.secondaryTeal
                                        : AppColors.cardBorder,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          key: const ValueKey('org-settings-scroll'),
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ..._tabBody(_snapshot!),
                              const SizedBox(height: 16),
                              const FilledButton(
                                onPressed: null,
                                child: Text('Save changes'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  List<Widget> _tabBody(OrgSettingsSnapshot snapshot) {
    final settings = snapshot.settings;
    return switch (_tab) {
      0 => _general(JsonCodec.asMap(settings['general'])),
      1 => _notifications(snapshot),
      2 => _security(JsonCodec.asMap(settings['security'])),
      3 => _family(JsonCodec.asMap(settings['family_portal_visibility'])),
      4 => _payroll(JsonCodec.asMap(settings['payroll'])),
      _ => _care(snapshot),
    };
  }

  List<Widget> _general(Map<String, dynamic> general) {
    final name = JsonCodec.string(general['platformName']);
    final logo = JsonCodec.string(general['logoUrl']);
    return [
      const _Intro(
        'What this tenant calls itself, and how dates and times are shown.',
      ),
      const _Heading('IDENTITY'),
      _ValueRow('Platform name', name ?? 'Not set'),
      _ValueRow('Logo', logo == null ? 'Not set' : 'On file'),
      const _Help(
        "Shown beside your organisation's name in the sidebar. Save the page to apply it.",
      ),
      const _Heading('DISPLAY'),
      _ValueRow('Timezone', _timezoneLabel(JsonCodec.string(general['timezone']))),
      const _Help(
        'Every screen, email and report shows dates and times in this timezone, for everyone in the organisation. Times are still stored in UTC.',
      ),
      _ValueRow('Date format', _dateExample(JsonCodec.string(general['dateFormat']))),
      _ValueRow('Time format', _timeExample(JsonCodec.string(general['timeFormat']))),
      _ValueRow(
        'Rows per page',
        general['itemsPerPage'] == null ? 'Not set' : '${general['itemsPerPage']}',
      ),
      const _Help(
        'Between 5 and 100 — the API refuses to return more than 100 rows at once',
      ),
    ];
  }

  List<Widget> _notifications(OrgSettingsSnapshot snapshot) {
    final notes = JsonCodec.asMap(snapshot.settings['notifications']);
    final quiet = JsonCodec.asMap(notes['quietHours']);
    final digest = JsonCodec.asMap(notes['digest']);
    final format =
        JsonCodec.string(JsonCodec.asMap(snapshot.settings['general'])['timeFormat']) ??
            '12h';
    final zone =
        JsonCodec.string(JsonCodec.asMap(snapshot.settings['general'])['timezone']) ??
            'the organisation timezone';
    return [
      const _Intro('When an alert may reach a phone, and when it waits.'),
      const _Heading('QUIET HOURS'),
      _BoolRow('Hold notifications overnight', JsonCodec.boolean(quiet['enabled'])),
      _Help('Times are shown in $zone and stored as UTC.'),
      _ValueRow('From', _clock(JsonCodec.string(quiet['start']), format)),
      _ValueRow('Until', _clock(JsonCodec.string(quiet['end']), format)),
      _ValueRow(
        'Always send immediately from',
        _severity(JsonCodec.string(notes['alwaysImmediateFrom'])),
      ),
      const _Help(
        'These break through quiet hours and digesting — a missed dose at 3am is why someone carries the phone',
      ),
      const _Heading('DIGEST'),
      _BoolRow(
        'Batch the rest into one daily digest',
        JsonCodec.boolean(digest['enabled']),
      ),
      _ValueRow('Send at', _clock(JsonCodec.string(digest['sendAt']), format)),
      const _Heading('EMAIL'),
      const _Help(
        'Off by default — staff are mobile-first, and mailing every event is a flood nobody reads.',
      ),
      _BoolRow(
        'Send notifications by email as well',
        JsonCodec.boolean(notes['emailEnabled']),
      ),
      _ValueRow(
        'Email from severity',
        _severity(JsonCodec.string(notes['emailFromSeverity'])),
      ),
      const _Heading('DELIVERY'),
      _BoolRow(
        'Name the subject in push previews',
        JsonCodec.boolean(notes['detailedPushPreview']),
      ),
      const _Help(
        'Off by default: a preview reading "Karim refused Risperidone" is readable by whoever holds the phone.',
      ),
      _ValueRow(
        'Re-alert unacknowledged criticals after (minutes)',
        _number(notes['escalateAfterMinutes']),
      ),
      const _Help(
        '0 is off — escalation without an on-call rota behind it only doubles the noise',
      ),
      _ValueRow(
        'Remind before a scheduled dose (minutes)',
        _number(notes['doseReminderMinutes']),
      ),
      const _Help(
        '0 is off. Every scheduled dose for every resident is one notification a day.',
      ),
      _ValueRow(
        'Delete read notifications after (days)',
        _number(notes['retentionDays']),
      ),
      const _Help('0 keeps them forever'),
    ];
  }

  List<Widget> _security(Map<String, dynamic> security) {
    return [
      const _Intro(
        'Session lifetime, password rules and where sessions may be held from.',
      ),
      const _Heading('SESSIONS'),
      _ValueRow(
        'Sign out after inactivity (minutes)',
        _number(security['idleTimeoutMinutes']),
      ),
      const _Help(
        "0 is off. This is idle time, separate from the cookie's own 8-hour lifetime — the setting a shared workstation in a care home actually needs.",
      ),
      const _Heading('PASSWORDS'),
      _BoolRow(
        'Require strong passwords',
        JsonCodec.boolean(security['requireStrongPasswords']),
      ),
      const _Help(
        'Upper, lower, digit, symbol and at least 12 characters. Applies to passwords set after it is turned on — existing ones keep working, because locking a care team out on a policy change is an outage.',
      ),
      const _Heading('NETWORK'),
      _ValueRow('IP allowlist', _allowlist(security['ipAllowlist'])),
      const _Help(
        'Empty means no restriction. IPv4 CIDR or exact addresses; a mobile workforce usually should not have one. An entry the API cannot parse is ignored rather than treated as a block.',
      ),
    ];
  }

  List<Widget> _family(Map<String, dynamic> family) {
    const rows = [
      (
        'activities',
        'Activities & daily journal',
        "Activities shared with the family, their photos, and the day's care notes.",
      ),
      (
        'incidents',
        'Incident summaries',
        'Resolved and closed incidents only: when, what kind, and the outcome.',
      ),
      (
        'medications',
        'Current medications',
        'What is prescribed and when — never whether a particular dose was given.',
      ),
      (
        'medicalConditions',
        'Medical conditions',
        'Diagnoses, allergies and dietary requirements.',
      ),
      (
        'documents',
        'Documents',
        'Documents filed as visible to family, and what families send in.',
      ),
      (
        'appointments',
        'Appointments & outings',
        'Visits and outings families request, and the decision on each.',
      ),
      (
        'messages',
        'Messages',
        "Conversations with the home's manager and administration.",
      ),
    ];
    return [
      const _Intro(
        "The default for every resident. A resident's own record can share less, never more.",
      ),
      const _Heading('VISIBLE SECTIONS'),
      for (final row in rows) ...[
        _BoolRow(row.$2, JsonCodec.boolean(family[row.$1])),
        _Help(row.$3),
      ],
    ];
  }

  List<Widget> _payroll(Map<String, dynamic> payroll) {
    return [
      const _Intro(
        'How pay periods are cut, whether overtime is calculated, and whether staff see their own payslips.',
      ),
      const _Heading('PAY PERIODS'),
      _ValueRow('Period type', _period(JsonCodec.string(payroll['payPeriodType']))),
      _BoolRow('Calculate overtime', JsonCodec.boolean(payroll['overtimeEnabled'])),
      const _Help(
        'Applies to runs generated after this is turned on; runs already calculated keep their figures.',
      ),
      const _Heading('STAFF PAYSLIPS'),
      _BoolRow(
        'Staff can see their own payslips',
        JsonCodec.boolean(payroll['staffSelfServiceEnabled']),
      ),
      const _Help(
        'Each member of staff sees only their own, on their profile. Turn off if you pay through a separate payroll bureau and the figures here are not the final ones.',
      ),
    ];
  }

  List<Widget> _care(OrgSettingsSnapshot snapshot) {
    final scoring = JsonCodec.asMap(snapshot.settings['compliance_scoring']);
    final weights = JsonCodec.asMap(scoring['weights']);
    final stock = JsonCodec.asMap(snapshot.settings['inventory_client_tagging']);
    final attendance = JsonCodec.asMap(snapshot.settings['attendance_verification']);
    final tasks = JsonCodec.asMap(snapshot.settings['tasks']);
    final categories = tasks['signOffCategories'] ?? tasks['categories'];
    return [
      const _Intro(
        'What your compliance score measures, what a stock record may say about a resident, which tasks need signing off, what clock-in asks for, and the break a new shift starts with.',
      ),
      const _Heading('COMPLIANCE SCORE'),
      const _Help(
        'Every home starts at 100. Each gap below takes points off, up to the limit shown for that kind of gap.',
      ),
      _ValueRow(
        'Each expired document — up to 30 points',
        _number(weights['expiredDocuments']),
      ),
      const _Help('A certificate or policy past its date.'),
      _ValueRow(
        'Each open incident — up to 25 points',
        _number(weights['openIncidents']),
      ),
      const _Help('Something that happened to a resident and is not closed.'),
      _ValueRow(
        'Each open finding — up to 10 points',
        _number(weights['openFindings']),
      ),
      const _Help(
        'A problem your own audit found. Lighter than an incident on purpose — a home that audits itself should not score worse for it.',
      ),
      _ValueRow(
        'Each incomplete training — up to 20 points',
        _number(weights['incompleteTraining']),
      ),
      const _Help('An assignment a staff member has not finished.'),
      _ValueRow(
        'Each medication needing a refill — up to 15 points',
        _number(weights['medicationRefillNeeded']),
      ),
      const _Help('Stock at or below its reorder level.'),
      const _Heading('STOCK AND RESIDENTS'),
      _ValueRow(
        'What a stock record may say about a resident',
        _stock(JsonCodec.string(stock['mode'])),
      ),
      const _Help(
        'Naming a resident records who a purchase was for, so personal-care spend can be attributed. It is not ownership — a bottle of shampoo is not set aside per resident — and it is never shown to families. Medication is outside this: a resident\'s own medication has its own stock.',
      ),
      const _Heading('SHIFTS'),
      _ValueRow('Default break (minutes)', _number(snapshot.defaultBreakMinutes)),
      const _Help(
        'The unpaid break every new shift starts with. It can still be changed on any shift; shifts already on the rota keep theirs.',
      ),
      const _Heading('CLOCK-IN'),
      const _Help(
        'What staff are asked for when they clock in or out. Neither ever stops somebody clocking in — these only decide whether they are asked.',
      ),
      _BoolRow('Ask for location', JsonCodec.boolean(attendance['locationRequired'])),
      const _Help(
        "Records where a clock-in was made and flags one outside the residence's geofence. Off: staff are not asked, and nothing is flagged — useful when staff work in the community or on home visits.",
      ),
      _BoolRow('Ask for a photo', JsonCodec.boolean(attendance['photoRequired'])),
      const _Help(
        'Offers a photo at clock-in for a manager to look at later. Staff can always skip it, and nothing compares the face to anything. Off: the camera is not opened and no photo is kept.',
      ),
      const _Heading('TASK SIGN-OFF'),
      const _Help(
        'Tasks of these kinds always need the person completing them to sign them off — their name and the time are recorded. Any other task can still be set to need it one by one. Applies to tasks created from now on, including each recurring chore\'s next occurrences.',
      ),
      for (final name in const [
        'Administrative',
        'Maintenance',
        'Inventory',
        'Compliance',
        'Follow-up',
        'Other',
      ])
        _BoolRow(name, _categoryOn(categories, name)),
    ];
  }
}

class _Error extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _Error({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Outfit',
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  final String text;
  const _Intro(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14,
          height: 1.4,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;
  const _Heading(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 0.4,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

class _Help extends StatelessWidget {
  final String text;
  const _Help(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 12.5,
          height: 1.35,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  final String label;
  final String value;

  const _ValueRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                color: AppColors.textHeading,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoolRow extends StatelessWidget {
  final String label;
  final bool? value;

  const _BoolRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    if (value == null) return _ValueRow(label, 'Not set');
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w600,
          fontSize: 13.5,
          color: AppColors.textHeading,
        ),
      ),
      value: value!,
      onChanged: null,
    );
  }
}

String _timezoneLabel(String? iana) {
  if (iana == null || iana.isEmpty) return 'Not set';
  try {
    final now = tz.TZDateTime.now(tz.getLocation(iana));
    final offset = now.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    return '(GMT$sign$hours:$minutes) $iana';
  } catch (_) {
    return iana;
  }
}

String _dateExample(String? format) {
  return switch (format) {
    'DD/MM/YYYY' => '31/12/2026',
    'MM/DD/YYYY' => '12/31/2026',
    'YYYY-MM-DD' => '2026-12-31',
    null => 'Not set',
    _ => format,
  };
}

String _timeExample(String? format) {
  return switch (format) {
    '12h' => '12-hour',
    '24h' => '24-hour',
    null => 'Not set',
    _ => format,
  };
}

String _clock(String? hhmm, String format) {
  if (hhmm == null || hhmm.isEmpty) return 'Not set';
  final parts = hhmm.split(':');
  if (parts.length < 2) return hhmm;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return hhmm;
  if (format == '24h') {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
  final suffix = hour >= 12 ? 'PM' : 'AM';
  final h = hour % 12 == 0 ? 12 : hour % 12;
  return '$h:${minute.toString().padLeft(2, '0')} $suffix';
}

String _severity(String? raw) {
  return switch (raw) {
    'low' => 'Low and above',
    'medium' => 'Medium and above',
    'high' => 'High and above',
    'critical' => 'Critical',
    null => 'Not set',
    _ => raw,
  };
}

String _number(Object? value) {
  if (value == null) return 'Not set';
  return '$value';
}

String _period(String? value) {
  return switch (value) {
    'weekly' => 'Every week',
    'bi_weekly' => 'Every two weeks',
    'semi_monthly' => 'Twice a month',
    'monthly' => 'Every month',
    null => 'Not set',
    _ => value,
  };
}

String _stock(String? mode) {
  return switch (mode) {
    'client_and_remark' => 'Name the resident, or write a remark',
    null => 'Not set',
    _ => mode,
  };
}

String _allowlist(Object? value) {
  if (value == null) return 'Not set';
  if (value is List && value.isEmpty) return 'Empty';
  if (value is List) return value.join(', ');
  final text = value.toString().trim();
  return text.isEmpty ? 'Empty' : text;
}

bool? _categoryOn(Object? categories, String name) {
  if (categories is! List) return null;
  final key = name.toLowerCase();
  for (final item in categories) {
    if (item is String && item.toLowerCase() == key) return true;
    if (item is Map) {
      final label = JsonCodec.string(item['name'] ?? item['category']);
      if (label != null && label.toLowerCase() == key) {
        return JsonCodec.boolean(item['required'] ?? item['enabled']) ?? true;
      }
    }
  }
  return null;
}
