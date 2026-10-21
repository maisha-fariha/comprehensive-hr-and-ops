import 'package:flutter/material.dart';
import 'package:gems_core/gems_core.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_error_mapper.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../appointments/presentation/widgets/appointment_form_fields.dart';
import '../../../appointments/presentation/widgets/family_appointments_header.dart';
import '../../../appointments/presentation/widgets/family_primary_button.dart';
import '../../../profile_settings/presentation/widgets/family_settings_toggle_row.dart';

/// Family "Community Outings & Leave" — the web `/family/outings` screen.
class FamilyOutingsPage extends StatefulWidget {
  const FamilyOutingsPage({super.key});

  @override
  State<FamilyOutingsPage> createState() => _FamilyOutingsPageState();
}

class _Outing {
  final String id;
  final String clientName;
  final String destination;
  final String? purpose;
  final DateTime departAt;
  final DateTime returnAt;
  final String status;

  const _Outing({
    required this.id,
    required this.clientName,
    required this.destination,
    required this.purpose,
    required this.departAt,
    required this.returnAt,
    required this.status,
  });

  static _Outing? fromJson(dynamic raw) {
    final json = JsonCodec.asMap(raw);
    final id = JsonCodec.string(json['id']);
    final depart = DateTime.tryParse(JsonCodec.string(json['departAt']) ?? '');
    final back = DateTime.tryParse(JsonCodec.string(json['returnAt']) ?? '');
    if (id == null || depart == null || back == null) return null;
    return _Outing(
      id: id,
      clientName: JsonCodec.stringOr(json['clientName'], 'Resident'),
      destination: JsonCodec.stringOr(json['destination'], 'Outing'),
      purpose: JsonCodec.string(json['purpose']),
      departAt: depart.toLocal(),
      returnAt: back.toLocal(),
      status: JsonCodec.stringOr(json['status'], 'pending'),
    );
  }
}

class _Resident {
  final String id;
  final String name;

  const _Resident(this.id, this.name);
}

enum _OutingTab { upcoming, pending, history }

class _FamilyOutingsPageState extends State<FamilyOutingsPage> {
  final _api = GetIt.instance<AppApiClient>();
  List<_Outing> _rows = const [];
  List<_Resident> _residents = const [];
  var _loading = true;
  String? _error;
  _OutingTab _tab = _OutingTab.upcoming;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final outings = await _api.get(
      ApiEndpoints.familyOutings,
      query: const {'page': 1, 'limit': 100},
      silent: true,
    );
    final home = await _api.get(ApiEndpoints.familyHome, silent: true);
    if (!mounted) return;
    outings.when(
      success: (body) {
        _rows = [
          for (final raw in JsonCodec.unwrapList(body))
            if (_Outing.fromJson(raw) case final row?) row,
        ];
      },
      failure: (error) {
        _error = AppErrorMapper.from(error).message;
        _rows = const [];
      },
    );
    home.when(
      success: (body) {
        final data = JsonCodec.unwrapMap(body);
        final people = data['linkedClients'];
        _residents = [
          if (people is List)
            for (final raw in people)
              if (_resident(raw) case final person?) person,
        ];
      },
      failure: (_) {},
    );
    setState(() => _loading = false);
  }

  _Resident? _resident(dynamic raw) {
    final json = JsonCodec.asMap(raw);
    final id = JsonCodec.string(json['id']);
    if (id == null) return null;
    final visibility = json['visibility'];
    if (visibility is Map && visibility['appointments'] == false) return null;
    final name = JsonCodec.string(json['name']) ??
        [
          JsonCodec.string(json['firstName']),
          JsonCodec.string(json['lastName']),
        ].whereType<String>().join(' ');
    if (name.trim().isEmpty) return null;
    return _Resident(id, name.trim());
  }

  List<_Outing> get _pending {
    final now = DateTime.now();
    return [
      for (final row in _rows)
        if (row.status == 'pending' && !row.returnAt.isBefore(now)) row,
    ];
  }

  List<_Outing> get _upcoming {
    final now = DateTime.now();
    return [
      for (final row in _rows)
        if (row.status == 'approved' && !row.returnAt.isBefore(now)) row,
    ];
  }

  List<_Outing> get _history {
    final pending = _pending.map((row) => row.id).toSet();
    final upcoming = _upcoming.map((row) => row.id).toSet();
    return [
      for (final row in _rows)
        if (!pending.contains(row.id) && !upcoming.contains(row.id)) row,
    ];
  }

  List<_Outing> get _visible {
    switch (_tab) {
      case _OutingTab.upcoming:
        return _upcoming;
      case _OutingTab.pending:
        return _pending;
      case _OutingTab.history:
        return _history;
    }
  }

  Future<void> _withdraw(_Outing row) async {
    final result = await _api.post(
      ApiEndpoints.familyOutingCancel(row.id),
      data: const {},
      silent: true,
      allowQueue: false,
    );
    if (!mounted) return;
    result.when(
      success: (_) => _load(),
      failure: (error) => setState(() {
        _error = AppErrorMapper.from(error).message;
      }),
    );
  }

  Future<void> _request() async {
    final created = await showAppBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _RequestOutingSheet(
        residents: _residents,
        onSubmit: (body) => _api.post(
          ApiEndpoints.familyOutings,
          data: body,
          silent: true,
          allowQueue: false,
        ),
      ),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _visible;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            FamilyAppointmentsHeader(
              title: 'Community Outings & Leave',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: FamilyPrimaryButton(
                label: 'Request an Outing',
                icon: Icons.add,
                onTap: _request,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: _OutingTabs(
                selected: _tab,
                upcoming: _upcoming.length,
                pending: _pending.length,
                history: _history.length,
                onSelected: (tab) => setState(() => _tab = tab),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    color: AppColors.criticalRed,
                  ),
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : rows.isEmpty
                      ? _EmptyOutings(tab: _tab, onRequest: _request)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                          itemCount: rows.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final row = rows[index];
                            final canWithdraw =
                                (row.status == 'pending' ||
                                    row.status == 'approved') &&
                                row.departAt.isAfter(DateTime.now());
                            return _OutingCard(
                              outing: row,
                              showResident: _residents.length > 1,
                              onWithdraw: canWithdraw
                                  ? () => _withdraw(row)
                                  : null,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutingTabs extends StatelessWidget {
  final _OutingTab selected;
  final int upcoming;
  final int pending;
  final int history;
  final ValueChanged<_OutingTab> onSelected;

  const _OutingTabs({
    required this.selected,
    required this.upcoming,
    required this.pending,
    required this.history,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F9),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          _chip('Confirmed', upcoming, _OutingTab.upcoming),
          _chip('Pending', pending, _OutingTab.pending),
          _chip('History', history, _OutingTab.history),
        ],
      ),
    );
  }

  Widget _chip(String label, int count, _OutingTab tab) {
    final active = selected == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelected(tab),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: const Color(0xFF142846).withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            '$label ($count)',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: active ? const Color(0xFF0E7C7B) : const Color(0xFF8E9BAE),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyOutings extends StatelessWidget {
  final _OutingTab tab;
  final VoidCallback onRequest;

  const _EmptyOutings({required this.tab, required this.onRequest});

  @override
  Widget build(BuildContext context) {
    final title = switch (tab) {
      _OutingTab.upcoming => 'No upcoming approved outings',
      _OutingTab.pending => 'No pending approvals',
      _OutingTab.history => 'No past outing records',
    };
    final body = tab == _OutingTab.upcoming
        ? 'Planning a family dinner, day trip, or weekend celebration? Request an outing above.'
        : 'Requests you make appear here while the care home reviews them.';
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: AppColors.primaryNavy,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13,
            height: 1.35,
            color: AppColors.textMuted,
          ),
        ),
        if (tab == _OutingTab.upcoming) ...[
          const SizedBox(height: 12),
          Center(
            child: FamilyPrimaryButton(
              label: 'Plan an Outing Now',
              icon: Icons.add,
              onTap: onRequest,
            ),
          ),
        ],
      ],
    );
  }
}

class _OutingCard extends StatelessWidget {
  final _Outing outing;
  final bool showResident;
  final VoidCallback? onWithdraw;

  const _OutingCard({
    required this.outing,
    required this.showResident,
    required this.onWithdraw,
  });

  String get _status {
    final now = DateTime.now();
    switch (outing.status) {
      case 'pending':
        return 'Awaiting care home approval';
      case 'approved':
        return outing.returnAt.isBefore(now)
            ? 'Completed'
            : 'Approved by the care home';
      case 'declined':
        return 'Declined';
      default:
        return 'Withdrawn';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  outing.destination,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                    fontSize: 15.5,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ),
              if (onWithdraw != null)
                TextButton(
                  onPressed: onWithdraw,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.criticalRed,
                    textStyle: const TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                  child: const Text('Withdraw'),
                ),
            ],
          ),
          if (showResident)
            Text(
              outing.clientName,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AppColors.secondaryTeal,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            'Depart: ${_when(outing.departAt)}  ·  Return by: ${_when(outing.returnAt)}',
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12.5,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _status,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              color: AppColors.primaryNavy,
            ),
          ),
          if (outing.purpose != null) ...[
            const SizedBox(height: 6),
            Text(
              outing.purpose!,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                color: AppColors.textHeading,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _when(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/${value.year} $hour:$minute';
  }
}

class _RequestOutingSheet extends StatefulWidget {
  final List<_Resident> residents;
  final Future<Result<dynamic>> Function(Map<String, dynamic> body) onSubmit;

  const _RequestOutingSheet({
    required this.residents,
    required this.onSubmit,
  });

  @override
  State<_RequestOutingSheet> createState() => _RequestOutingSheetState();
}

class _RequestOutingSheetState extends State<_RequestOutingSheet> {
  static const _transport = [
    ('private_car', 'Private Family Car'),
    ('wheelchair_van', 'Wheelchair Accessible Van / Taxi'),
    ('walking', 'Accompanied Walk in Local Neighborhood'),
    ('public_transit', 'Public Transit / Bus'),
  ];

  final _destination = TextEditingController();
  final _purpose = TextEditingController();
  final _adult = TextEditingController();
  final _phone = TextEditingController();
  final _notes = TextEditingController();
  String? _clientId;
  DateTime? _date;
  TimeOfDay _depart = const TimeOfDay(hour: 11, minute: 0);
  TimeOfDay _back = const TimeOfDay(hour: 16, minute: 0);
  String _transportType = 'private_car';
  var _needsMeds = true;
  var _consent = false;
  var _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.residents.isNotEmpty) _clientId = widget.residents.first.id;
  }

  @override
  void dispose() {
    _destination.dispose();
    _purpose.dispose();
    _adult.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  String _clock(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime({required bool depart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: depart ? _depart : _back,
    );
    if (picked == null) return;
    setState(() {
      if (depart) {
        _depart = picked;
      } else {
        _back = picked;
      }
    });
  }

  Future<void> _submit() async {
    final clientId = _clientId;
    if (clientId == null || clientId.isEmpty) {
      setState(() => _error = 'Choose the resident this outing is for.');
      return;
    }
    if (_destination.text.trim().isEmpty) {
      setState(
        () => _error = 'Please provide the destination for the outing.',
      );
      return;
    }
    final date = _date;
    if (date == null) {
      setState(() => _error = 'Please select the date of the outing.');
      return;
    }
    if (_adult.text.trim().isEmpty || _phone.text.trim().isEmpty) {
      setState(
        () => _error =
            "Please enter the accompanying adult's full name and mobile phone.",
      );
      return;
    }
    if (!_consent) {
      setState(
        () => _error =
            'Please review and confirm the digital safety and curfew consent.',
      );
      return;
    }
    final depart = DateTime(
      date.year,
      date.month,
      date.day,
      _depart.hour,
      _depart.minute,
    );
    final back = DateTime(
      date.year,
      date.month,
      date.day,
      _back.hour,
      _back.minute,
    );
    if (!back.isAfter(depart)) {
      setState(
        () => _error = 'The return time has to be after the pickup time.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await widget.onSubmit({
      'clientId': clientId,
      'destination': _destination.text.trim(),
      if (_purpose.text.trim().isNotEmpty) 'purpose': _purpose.text.trim(),
      'departAt': depart.toUtc().toIso8601String(),
      'returnAt': back.toUtc().toIso8601String(),
      'responsibleAdultName': _adult.text.trim(),
      'responsibleAdultPhone': _phone.text.trim(),
      'transportType': _transportType,
      'needsMedicationPack': _needsMeds,
      if (_notes.text.trim().isNotEmpty)
        'specialInstructions': _notes.text.trim(),
    });
    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      success: (_) => Navigator.of(context).pop(true),
      failure: (error) => setState(() {
        _error = AppErrorMapper.from(error).message;
      }),
    );
  }

  String? get _residentName {
    for (final person in widget.residents) {
      if (person.id == _clientId) return person.name;
    }
    return null;
  }

  String get _transportLabel {
    for (final option in _transport) {
      if (option.$1 == _transportType) return option.$2;
    }
    return 'Private Family Car';
  }

  Future<void> _pickChoice({
    required String title,
    required List<(String, String)> options,
    required String? selected,
    required ValueChanged<String> onPicked,
  }) async {
    final value = await showAppBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ),
            ),
            for (final option in options)
              ListTile(
                title: Text(
                  option.$2,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textHeading,
                  ),
                ),
                trailing: option.$1 == selected
                    ? const Icon(Icons.check_rounded, color: AppColors.secondaryTeal)
                    : null,
                onTap: () => Navigator.pop(ctx, option.$1),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (value != null) onPicked(value);
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _date == null
        ? 'Select the date'
        : '${_date!.day.toString().padLeft(2, '0')}/'
            '${_date!.month.toString().padLeft(2, '0')}/${_date!.year}';
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final gap = SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16));
    final radius = ResponsiveHelper.getResponsiveRadius(context, 12);
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.explore_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Request Community Outing',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: AppColors.primaryNavy,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "The care home's management approves every outing before it happens.",
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w500,
                              fontSize: 12.5,
                              color: AppColors.textMuted,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: AppColors.filterButtonBackground,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _busy ? null : () => Navigator.of(context).pop(false),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_error != null) ...[
                        AppointmentFormErrorBanner(message: _error!),
                        gap,
                      ],
                      const AppointmentFieldLabel('Resident', required: true),
                      AppointmentDropdownField(
                        value: _residentName ?? 'Choose a resident',
                        isPlaceholder: _residentName == null,
                        onTap: () => _pickChoice(
                          title: 'Resident',
                          options: [
                            for (final person in widget.residents)
                              (person.id, person.name),
                          ],
                          selected: _clientId,
                          onPicked: (value) => setState(() => _clientId = value),
                        ),
                      ),
                      gap,
                      const AppointmentFieldLabel('Destination', required: true),
                      AppointmentTextField(
                        controller: _destination,
                        hint: 'Where are you going?',
                      ),
                      gap,
                      const AppointmentFieldLabel('Purpose'),
                      AppointmentTextField(
                        controller: _purpose,
                        hint: 'Family dinner, appointment, celebration',
                      ),
                      gap,
                      const AppointmentFieldLabel('Date', required: true),
                      AppointmentDropdownField(
                        value: dateLabel,
                        isPlaceholder: _date == null,
                        trailingIcon: Icons.calendar_month_outlined,
                        onTap: _pickDate,
                      ),
                      gap,
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const AppointmentFieldLabel('Pickup', required: true),
                                AppointmentDropdownField(
                                  value: _clock(_depart),
                                  trailingIcon: Icons.schedule_outlined,
                                  onTap: () => _pickTime(depart: true),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const AppointmentFieldLabel('Return', required: true),
                                AppointmentDropdownField(
                                  value: _clock(_back),
                                  trailingIcon: Icons.schedule_outlined,
                                  onTap: () => _pickTime(depart: false),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      gap,
                      const AppointmentFieldLabel('Accompanying adult', required: true),
                      AppointmentTextField(
                        controller: _adult,
                        hint: 'Full name',
                      ),
                      gap,
                      const AppointmentFieldLabel('Mobile phone', required: true),
                      AppointmentTextField(
                        controller: _phone,
                        hint: 'Phone number',
                        keyboardType: TextInputType.phone,
                      ),
                      gap,
                      const AppointmentFieldLabel('Transport'),
                      AppointmentDropdownField(
                        value: _transportLabel,
                        onTap: () => _pickChoice(
                          title: 'Transport',
                          options: _transport,
                          selected: _transportType,
                          onPicked: (value) =>
                              setState(() => _transportType = value),
                        ),
                      ),
                      gap,
                      FamilySettingsToggleRow(
                        label: 'Medication pack needed',
                        value: _needsMeds,
                        onChanged: (value) => setState(() => _needsMeds = value),
                      ),
                      gap,
                      const AppointmentFieldLabel('Special instructions'),
                      AppointmentNoteField(
                        controller: _notes,
                        hint: 'Wheelchair, meal, or anything the home should know',
                      ),
                      gap,
                      InkWell(
                        onTap: _busy
                            ? null
                            : () => setState(() => _consent = !_consent),
                        borderRadius: BorderRadius.circular(radius),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceWhite,
                            borderRadius: BorderRadius.circular(radius),
                            border: Border.all(color: AppColors.searchBorder),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _consent,
                                activeColor: AppColors.secondaryTeal,
                                onChanged: _busy
                                    ? null
                                    : (value) =>
                                        setState(() => _consent = value ?? false),
                              ),
                              const Expanded(
                                child: Text(
                                  'Safety & Curfew Consent: I agree to supervise the resident throughout the outing, ensure safe transportation, and return to the care home by the agreed curfew time.',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textHeading,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textHeading,
                          side: const BorderSide(color: AppColors.searchBorder),
                          backgroundColor: AppColors.surfaceWhite,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(radius),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _busy ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryNavy,
                          disabledBackgroundColor:
                              AppColors.primaryNavy.withValues(alpha: 0.5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(radius),
                          ),
                        ),
                        child: Text(
                          _busy ? 'Submitting...' : 'Submit Outing Request',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
