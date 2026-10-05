import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/formatting/web_formats.dart';
import '../../../attendance/presentation/widgets/attendance_record_card.dart';
import '../../../daily_logs/presentation/pages/daily_logs_page.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../../presentation/widgets/hr_directory_widgets.dart';
import '../../../scheduling/presentation/pages/create_shift_page.dart';
import '../../domain/entities/residence_summary.dart';
import '../controllers/residences_controller.dart';
import '../residences_labels.dart';
import '../widgets/residence_detail_tabs.dart';
import '../widgets/residences_common.dart';
import 'residence_form_page.dart';

enum ResidenceDetailTab { overview, clients, rooms, staff, schedule, dailyLogs }

/// Web residence detail drawer: header, six tabs and the footer actions.
class ResidenceDetailPage extends StatefulWidget {
  final ResidenceSummary residence;

  const ResidenceDetailPage({super.key, required this.residence});

  @override
  State<ResidenceDetailPage> createState() => _ResidenceDetailPageState();
}

class _ResidenceDetailPageState extends State<ResidenceDetailPage>
    with SingleTickerProviderStateMixin {
  late final ResidencesController _controller = _resolveController();
  late final TabController _tabs =
      TabController(length: ResidenceDetailTab.values.length, vsync: this)
        ..addListener(_onTab);
  late ResidenceSummary _residence = widget.residence;
  ResidenceRoomBoard? _board;
  bool _boardLoaded = false;
  bool _payrollBusy = false;

  ResidenceDetailTab get _tab => ResidenceDetailTab.values[_tabs.index];

  static ResidencesController _resolveController() {
    if (Get.isRegistered<ResidencesController>()) {
      return Get.find<ResidencesController>();
    }
    return Get.put(GetIt.instance<ResidencesController>());
  }

  @override
  void initState() {
    super.initState();
    _loadResidence();
    _loadBoard();
  }

  @override
  void dispose() {
    _tabs
      ..removeListener(_onTab)
      ..dispose();
    super.dispose();
  }

  void _onTab() {
    if (!_tabs.indexIsChanging) setState(() {});
  }

  Future<void> _loadResidence() async {
    final repo = _controller.admin;
    if (repo == null) return;
    final result = await repo.getResidence(_residence.id);
    if (!mounted) return;
    result.when(success: (r) => setState(() => _residence = r), failure: (_) {});
  }

  Future<void> _loadBoard() async {
    final repo = _controller.admin;
    if (repo == null) {
      final rooms = await _controller.loadRooms(_residence.id);
      if (!mounted) return;
      setState(() {
        _boardLoaded = true;
        if (rooms != null) {
          final active = rooms.where((r) => r.isActive).toList();
          _board = ResidenceRoomBoard(
            rooms: rooms,
            roomCount: active.length,
            beds: active.fold(0, (s, r) => s + r.capacity),
            occupied: active.fold(0, (s, r) => s + r.occupied),
            available: active.fold(0, (s, r) => s + r.available),
          );
        }
      });
      return;
    }
    final result = await repo.getRoomBoard(_residence.id);
    if (!mounted) return;
    setState(() {
      _boardLoaded = true;
      if (result.isSuccess) _board = result.value;
    });
  }

  Future<void> _setPayroll({required bool outOfPocket, required bool mileage}) async {
    final repo = _controller.admin;
    if (repo == null || _payrollBusy) return;
    setState(() => _payrollBusy = true);
    final result = await repo.updatePayrollSettings(
      _residence.id,
      outOfPocketEnabled: outOfPocket,
      mileageEnabled: mileage,
    );
    if (!mounted) return;
    setState(() {
      _payrollBusy = false;
      if (result.isSuccess) {
        _residence = _residence.copyWith(outOfPocketEnabled: outOfPocket, mileageEnabled: mileage);
      }
    });
    AppSnackbar.show(result.isSuccess ? 'Claim settings saved' : result.error!.message, '');
  }

  Future<void> _edit() async {
    final saved = await Get.to<bool>(
      () => ResidenceFormPage(
        controller: _controller,
        editing: _residence,
        alwaysSendAssignments: true,
      ),
    );
    if (saved == true) await _loadResidence();
  }

  @override
  Widget build(BuildContext context) {
    final r = _residence;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: hrSubPageAppBar(context, r.name),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _header(context, r),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.secondaryTeal,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.secondaryTeal,
            dividerColor: AppColors.cardBorder,
            labelStyle: handoverText(context, 13.5, weight: FontWeight.w600),
            tabs: [
              const Tab(key: ValueKey('residence-tab-overview'), text: 'Overview'),
              Tab(key: const ValueKey('residence-tab-clients'), text: 'Clients · ${r.residents}'),
              const Tab(key: ValueKey('residence-tab-rooms'), text: 'Rooms'),
              Tab(key: const ValueKey('residence-tab-staff'), text: 'Staff · ${r.assignedStaffCount}'),
              const Tab(key: ValueKey('residence-tab-schedule'), text: 'Schedule'),
              const Tab(key: ValueKey('residence-tab-dailyLogs'), text: 'Daily Logs'),
            ],
          ),
          const SizedBox(height: 16),
          _tabContent(r),
        ],
      ),
      bottomNavigationBar: _footer(context, r),
    );
  }

  Widget _tabContent(ResidenceSummary r) {
    final repo = _controller.admin;
    return switch (_tab) {
      ResidenceDetailTab.overview => _overview(context, r),
      ResidenceDetailTab.clients => ResidenceClientsTab(repository: repo, residenceId: r.id),
      ResidenceDetailTab.rooms => ResidenceRoomsTab(
          repository: repo,
          residenceId: r.id,
          bedCapacity: r.bedCapacity,
          canManage: _controller.canUpdate,
          onChanged: _loadBoard,
        ),
      ResidenceDetailTab.staff => ResidenceStaffTab(repository: repo, residence: r),
      ResidenceDetailTab.schedule => ResidenceScheduleTab(repository: repo, residenceId: r.id),
      ResidenceDetailTab.dailyLogs => ResidenceDailyLogsTab(repository: repo, residenceId: r.id),
    };
  }

  Widget _header(BuildContext context, ResidenceSummary r) {
    Widget meta(IconData icon, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.textMuted),
            const SizedBox(width: 5),
            Flexible(child: Text(text, style: handoverText(context, 12, color: AppColors.textMuted))),
          ],
        );
    return HandoverPanel(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1C2E4A), Color(0xFF24406B)],
              ),
            ),
            child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(r.name, style: handoverText(context, 18, weight: FontWeight.w700)),
                    AttendancePill(
                      label: ResidencesLabels.humanise(r.status),
                      tone: ResidencesLabels.statusTone(r.status),
                    ),
                    if (r.nearCapacity)
                      const AttendancePill(label: 'Near Capacity', tone: AttendanceTone.warning),
                    AttendancePill(
                      label: '#${r.id.length > 8 ? r.id.substring(0, 8) : r.id}',
                      tone: AttendanceTone.neutral,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage residence operations, clients, staff, schedules and daily activities.',
                  style: handoverText(context, 12.5, color: AppColors.textMuted),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    meta(Icons.place_outlined, _text(r.address)),
                    meta(Icons.apartment_rounded, _text(r.residenceType)),
                    meta(Icons.phone_outlined, _text(r.phone)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _text(String? value) => value == null || value.isEmpty ? '—' : value;

  static String _claim(bool? enabled, ResidenceSummary r) {
    if (!r.hasPayrollSettings) return '—';
    return enabled == true ? 'Allowed' : 'Off';
  }

  Widget _overview(BuildContext context, ResidenceSummary r) {
    final free = r.bedsFree;
    final board = _board;
    final radius = r.gpsRadiusMeters;
    final roomsHint = !_boardLoaded
        ? 'Loading'
        : (board == null || board.roomCount == 0
            ? 'None recorded yet'
            : '${board.available} of ${board.beds} beds free');
    final canUpdate = _controller.canUpdate;
    final outOfPocket = r.outOfPocketEnabled ?? false;
    final mileage = r.mileageEnabled ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResidenceTileGrid(children: [
          ResidenceStatCard(
            icon: Icons.bed_outlined,
            label: 'Occupancy',
            value: '${r.residents} / ${r.bedCapacity}',
            hint: r.atCapacity ? 'At capacity' : '$free bed${free == 1 ? '' : 's'} free',
            critical: r.atCapacity,
          ),
          ResidenceStatCard(
            icon: Icons.door_front_door_outlined,
            label: 'Rooms',
            value: '${board?.roomCount ?? 0}',
            hint: roomsHint,
          ),
          ResidenceStatCard(
            icon: Icons.people_outline_rounded,
            label: 'People posted here',
            value: '${r.assignedStaffCount}',
            hint: r.primaryManager == null ? 'No primary manager' : 'Managed by ${r.primaryManager!.name}',
          ),
          ResidenceStatCard(
            icon: Icons.place_outlined,
            label: 'Geofence',
            value: radius == null ? 'Off' : '${radius}m',
            hint: radius == null ? 'No fence set up' : 'Around this address',
          ),
        ]),
        const SizedBox(height: 14),
        ResidenceSection(title: 'Contact', children: [
          ResidenceInfoLine(icon: Icons.place_outlined, label: 'Address', value: _text(r.address)),
          ResidenceInfoLine(icon: Icons.phone_outlined, label: 'Phone', value: _text(r.phone)),
          ResidenceInfoLine(icon: Icons.phone_outlined, label: 'Emergency', value: _text(r.emergencyPhone)),
          ResidenceInfoLine(icon: Icons.mail_outline_rounded, label: 'Email', value: _text(r.email)),
          ResidenceInfoLine(
              icon: Icons.phone_outlined, label: 'Management phone', value: _text(r.managementPhone)),
          ResidenceInfoLine(
              icon: Icons.mail_outline_rounded, label: 'Management email', value: _text(r.managementEmail)),
        ]),
        const SizedBox(height: 14),
        ResidenceSection(title: 'This home', children: [
          ResidenceInfoLine(label: 'Type', value: _text(ResidencesLabels.humanise(r.residenceType))),
          ResidenceInfoLine(label: 'Service', value: _text(r.serviceType)),
          ResidenceInfoLine(label: 'Licensed beds', value: '${r.bedCapacity}'),
          ResidenceInfoLine(icon: Icons.schedule_rounded, label: 'Timezone', value: _text(r.timezone)),
          ResidenceInfoLine(label: 'Out-of-pocket claims', value: _claim(r.outOfPocketEnabled, r)),
          ResidenceInfoLine(label: 'Mileage claims', value: _claim(r.mileageEnabled, r)),
        ]),
        const SizedBox(height: 14),
        ResidenceSection(title: 'Care level mix', children: [
          if (r.careLevelMix.isEmpty)
            Text('No residents assigned yet.', style: handoverText(context, 13, color: AppColors.textMuted))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in r.careLevelMix.entries)
                  AttendancePill(
                    label: '${ResidencesLabels.humanise(e.key)} · ${e.value}',
                    tone: AttendanceTone.info,
                  ),
              ],
            ),
        ]),
        const SizedBox(height: 14),
        ResidenceSection(title: 'Management', children: [
          ResidenceInfoLine(label: 'Primary manager', value: r.primaryManager?.name ?? '—'),
          ResidenceInfoLine(label: 'Assistant manager', value: r.assistantManager?.name ?? '—'),
          ResidenceInfoLine(
            label: 'Care team',
            value: r.careTeam.isEmpty ? '—' : r.careTeam.map((p) => p.name).join(', '),
          ),
        ]),
        const SizedBox(height: 14),
        ResidenceSection(title: 'Claims', children: [
          _claimToggle(
            context,
            key: const ValueKey('residence-claim-outOfPocket'),
            icon: Icons.receipt_long_outlined,
            label: 'Out-of-pocket expenses',
            description: 'Staff at this house can claim back what they have paid for themselves.',
            value: outOfPocket,
            onChanged: canUpdate && !_payrollBusy
                ? (v) => _setPayroll(outOfPocket: v, mileage: mileage)
                : null,
          ),
          _claimToggle(
            context,
            key: const ValueKey('residence-claim-mileage'),
            icon: Icons.directions_car_outlined,
            label: 'Mileage',
            description: "Journeys made for this house can be claimed at the tenant's rate.",
            value: mileage,
            onChanged: canUpdate && !_payrollBusy
                ? (v) => _setPayroll(outOfPocket: outOfPocket, mileage: v)
                : null,
          ),
          if (!canUpdate)
            Text('Ask an administrator to change these.',
                style: handoverText(context, 12.5, color: AppColors.textMuted)),
        ]),
        if (r.notes != null && r.notes!.isNotEmpty) ...[
          const SizedBox(height: 14),
          ResidenceSection(title: 'Notes', children: [
            Text(r.notes!, style: handoverText(context, 13.5, color: AppColors.textMuted)),
          ]),
        ],
      ],
    );
  }

  Widget _claimToggle(
    BuildContext context, {
    required Key key,
    required IconData icon,
    required String label,
    required String description,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: handoverText(context, 13.5, weight: FontWeight.w600)),
                Text(description, style: handoverText(context, 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          Switch(
            key: key,
            value: value,
            activeTrackColor: AppColors.secondaryTeal,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context, ResidenceSummary r) {
    final showEdit = (_tab == ResidenceDetailTab.overview || _tab == ResidenceDetailTab.clients) &&
        _controller.canUpdate;
    final action = switch (_tab) {
      ResidenceDetailTab.schedule when _controller.can('scheduling:write') => HandoverButton(
          key: const ValueKey('residence-create-schedule'),
          label: 'Create Schedule',
          icon: Icons.calendar_month_outlined,
          filled: true,
          onPressed: () => Get.to(() => CreateShiftPage(initialResidenceId: r.id)),
        ),
      ResidenceDetailTab.dailyLogs when _controller.can('daily-logs:write') => HandoverButton(
          key: const ValueKey('residence-add-daily-log'),
          label: 'Add Daily Log',
          icon: Icons.description_outlined,
          filled: true,
          onPressed: () => Get.to(() => const DailyLogsPage()),
        ),
      _ => null,
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Updated ${WebFormat.date(r.updatedAt)}',
                style: handoverText(context, 12, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                HandoverButton(
                  key: const ValueKey('residence-detail-close'),
                  label: 'Close',
                  onPressed: () => Get.back(),
                ),
                if (showEdit)
                  HandoverButton(
                    key: const ValueKey('residence-detail-edit'),
                    label: 'Edit Residence',
                    icon: Icons.edit_outlined,
                    onPressed: _edit,
                  ),
                ?action,
              ],
            ),
          ],
        ),
      ),
    );
  }
}
