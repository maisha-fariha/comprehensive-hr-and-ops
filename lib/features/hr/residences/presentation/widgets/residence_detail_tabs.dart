import 'package:flutter/material.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/formatting/web_formats.dart';
import '../../../attendance/presentation/widgets/attendance_pagination.dart';
import '../../../attendance/presentation/widgets/attendance_record_card.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/residence_detail_tabs.dart';
import '../../domain/entities/residence_summary.dart';
import '../../domain/repositories/residences_repository.dart';
import '../residences_labels.dart';
import 'residence_form_inputs.dart';
import 'residences_common.dart';

const _tabPageSizes = [10, 25, 50];

Future<Result<T>> _unavailable<T>() async =>
    Result.failure(const ApiError(message: 'Not available'));

/// Web `eY` tones: (background, foreground).
abstract final class ResidenceStatTone {
  static const blue = (Color(0xFFEAF0F9), Color(0xFF2A5DA6));
  static const green = (Color(0xFFEAF6F0), Color(0xFF2E8C58));
  static const amber = (Color(0xFFFBF3E9), Color(0xFFB4791C));
  static const red = (Color(0xFFFBEAEC), Color(0xFFC6485C));
}

/// Web `eY` stat: tinted icon, big value, label.
class ResidenceMiniStat extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final (Color, Color) tone;

  const ResidenceMiniStat({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return HandoverPanel(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: tone.$1, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 17, color: tone.$2),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$value', style: handoverText(context, 20, weight: FontWeight.w800)),
                Text(label,
                    style: handoverText(context, 11.5, weight: FontWeight.w600, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Mobile stand-in for one web table row.
class ResidenceRowTile extends StatelessWidget {
  final int index;
  final String? initials;
  final String title;
  final String? subtitle;
  final List<(String, String)> facts;
  final Widget? trailing;

  const ResidenceRowTile({
    super.key,
    required this.index,
    required this.title,
    this.initials,
    this.subtitle,
    this.facts = const [],
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: HandoverPanel(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (initials != null) ...[
                  ResidenceInitials(initials: initials!, index: index),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: handoverText(context, 13.5, weight: FontWeight.w600)),
                      if (subtitle != null && subtitle!.isNotEmpty)
                        Text(subtitle!, style: handoverText(context, 12, color: AppColors.infoBlue)),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
            if (facts.isNotEmpty) ...[
              const SizedBox(height: 6),
              for (final (label, value) in facts) ResidenceInfoLine(label: label, value: value),
            ],
          ],
        ),
      ),
    );
  }
}

Widget _pager(int page, int limit, int total, ValueChanged<int> onPage, ValueChanged<int> onLimit) {
  if (total == 0) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(top: 4),
    child: AttendancePagination(
      page: page,
      limit: limit,
      total: total,
      totalPages: (total + limit - 1) ~/ limit,
      limitOptions: _tabPageSizes,
      onPage: onPage,
      onLimit: onLimit,
    ),
  );
}

Widget _loading() => const Padding(
      padding: EdgeInsets.all(24),
      child: Center(child: CircularProgressIndicator(color: AppColors.secondaryTeal)),
    );

/// Web drawer "Clients" tab.
class ResidenceClientsTab extends StatefulWidget {
  final ResidenceAdminRepository? repository;
  final String residenceId;

  const ResidenceClientsTab({super.key, required this.repository, required this.residenceId});

  @override
  State<ResidenceClientsTab> createState() => _ResidenceClientsTabState();
}

class _ResidenceClientsTabState extends State<ResidenceClientsTab> {
  int _page = 1;
  int _limit = _tabPageSizes.first;
  bool _loadingNow = true;
  bool _failed = false;
  ResidenceTabPage<ResidenceResident, ResidentsSummary>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadingNow = true);
    final repo = widget.repository;
    final result = repo == null
        ? await _unavailable<ResidenceTabPage<ResidenceResident, ResidentsSummary>>()
        : await repo.getResidents(widget.residenceId, page: _page, limit: _limit);
    if (!mounted) return;
    setState(() {
      _loadingNow = false;
      _failed = result.isFailure;
      _data = result.isSuccess ? result.value : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rows = _data?.items ?? const <ResidenceResident>[];
    final total = _data?.total ?? rows.length;
    final summary = _data?.summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (summary != null) ...[
          ResidenceTileGrid(children: [
            ResidenceMiniStat(
                label: 'Residents', value: summary.clients, icon: Icons.people_outline_rounded, tone: ResidenceStatTone.blue),
            ResidenceMiniStat(
                label: 'Active', value: summary.active, icon: Icons.check_circle_outline_rounded, tone: ResidenceStatTone.green),
            ResidenceMiniStat(
                label: 'On leave', value: summary.onLeave, icon: Icons.flight_outlined, tone: ResidenceStatTone.amber),
            ResidenceMiniStat(
              label: 'Care level not set',
              value: summary.unrated,
              icon: Icons.bed_outlined,
              tone: summary.unrated > 0 ? ResidenceStatTone.amber : ResidenceStatTone.green,
            ),
          ]),
          const SizedBox(height: 12),
        ],
        if (_loadingNow)
          _loading()
        else if (rows.isEmpty)
          ResidenceMutedMessage(
            title: _failed ? 'Residents could not be loaded.' : 'No residents live here yet.',
          )
        else
          for (var i = 0; i < rows.length; i++)
            ResidenceRowTile(
              key: ValueKey('residence-resident-${rows[i].id}'),
              index: i,
              initials: rows[i].initials,
              title: rows[i].name,
              trailing: AttendancePill(label: rows[i].statusLabel, tone: AttendanceTone.neutral),
              facts: [
                ('Care level', rows[i].level ?? '—'),
                ('Room', rows[i].roomNumber?.isNotEmpty == true ? rows[i].roomNumber! : 'No room'),
                ('DOB', WebFormat.date(rows[i].dateOfBirth)),
                ('Admitted', WebFormat.date(rows[i].admissionDate)),
              ],
            ),
        if (!_loadingNow)
          _pager(_page, _limit, total, (p) {
            _page = p;
            _load();
          }, (l) {
            _limit = l;
            _page = 1;
            _load();
          }),
        if (total > rows.length && rows.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Showing ${rows.length} of $total. The full list is on the Clients page.',
              style: handoverText(context, 12.5, color: AppColors.textMuted),
            ),
          ),
      ],
    );
  }
}

/// Web drawer "Rooms" tab.
class ResidenceRoomsTab extends StatefulWidget {
  final ResidenceAdminRepository? repository;
  final String residenceId;
  final int bedCapacity;
  final bool canManage;
  final VoidCallback? onChanged;

  const ResidenceRoomsTab({
    super.key,
    required this.repository,
    required this.residenceId,
    required this.bedCapacity,
    required this.canManage,
    this.onChanged,
  });

  @override
  State<ResidenceRoomsTab> createState() => _ResidenceRoomsTabState();
}

class _ResidenceRoomsTabState extends State<ResidenceRoomsTab> {
  bool _includeArchived = false;
  bool _adding = false;
  bool _loadingNow = true;
  String? _error;
  ResidenceRoomBoard? _board;
  final Set<String> _busy = {};
  final Map<String, String> _roomErrors = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadingNow = true);
    final repo = widget.repository;
    final result = repo == null
        ? await _unavailable<ResidenceRoomBoard>()
        : await repo.getRoomBoard(widget.residenceId, includeArchived: _includeArchived);
    if (!mounted) return;
    setState(() {
      _loadingNow = false;
      _error = result.error?.message;
      if (result.isSuccess) _board = result.value;
    });
  }

  Future<void> _roomAction(ResidenceRoom room, Future<Result<void>> Function() call) async {
    setState(() {
      _busy.add(room.id);
      _roomErrors.remove(room.id);
    });
    final result = await call();
    if (!mounted) return;
    setState(() {
      _busy.remove(room.id);
      if (result.isFailure) _roomErrors[room.id] = result.error!.message;
    });
    if (result.isSuccess) {
      widget.onChanged?.call();
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final board = _board;
    final rooms = board?.rooms ?? const <ResidenceRoom>[];
    final mismatch = board != null && rooms.isNotEmpty && board.beds != widget.bedCapacity;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResidenceTileGrid(children: [
          ResidenceStatCard(label: 'Rooms', value: '${board?.roomCount ?? 0}', hint: 'In this home'),
          ResidenceStatCard(label: 'Beds', value: '${board?.beds ?? 0}', hint: 'Across the rooms in use'),
          ResidenceStatCard(label: 'Occupied', value: '${board?.occupied ?? 0}', hint: 'Residents placed'),
          ResidenceStatCard(label: 'Free', value: '${board?.available ?? 0}', hint: 'Beds somebody could move into'),
        ]),
        if (mismatch) ...[
          const SizedBox(height: 12),
          Container(
            key: const ValueKey('residence-rooms-mismatch'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFFFF7E8), borderRadius: BorderRadius.circular(8)),
            child: Text(
              'This home is licensed for ${widget.bedCapacity} ${widget.bedCapacity == 1 ? 'bed' : 'beds'}, '
              'but its rooms add up to ${board.beds}. Admission is measured against the licensed count.',
              style: handoverText(context, 12.5, color: const Color(0xFF8A5A12)),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const ValueKey('residence-rooms-archived'),
                  onPressed: () {
                    _includeArchived = !_includeArchived;
                    _load();
                  },
                  child: Text(
                    (_includeArchived ? 'Hide rooms out of use' : 'Show rooms out of use').toUpperCase(),
                    style: handoverText(context, 12, weight: FontWeight.w600, color: AppColors.textMuted),
                  ),
                ),
              ),
            ),
            if (widget.canManage && !_adding)
              HandoverButton(
                key: const ValueKey('residence-room-add'),
                label: 'Add room',
                icon: Icons.add_rounded,
                compact: true,
                onPressed: () => setState(() => _adding = true),
              ),
          ],
        ),
        if (_adding) ...[
          const SizedBox(height: 8),
          _AddRoomForm(
            repository: widget.repository,
            residenceId: widget.residenceId,
            onDone: (created) {
              setState(() => _adding = false);
              if (created) {
                widget.onChanged?.call();
                _load();
              }
            },
          ),
        ],
        const SizedBox(height: 8),
        if (_loadingNow && board == null)
          const ResidenceMutedMessage(title: 'Loading rooms…')
        else if (_error != null && board == null)
          ResidenceMutedMessage(title: _error!)
        else if (rooms.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                const Icon(Icons.bed_outlined, size: 20, color: AppColors.textMuted),
                const SizedBox(height: 4),
                Text('No rooms recorded for this home yet.',
                    textAlign: TextAlign.center, style: handoverText(context, 13.5, color: AppColors.textMuted)),
                if (widget.canManage)
                  Text(
                    'Add them and admission can place residents by room instead of a typed number.',
                    textAlign: TextAlign.center,
                    style: handoverText(context, 12.5, color: AppColors.textMuted),
                  ),
              ],
            ),
          )
        else
          for (final room in rooms) _roomCard(context, room),
      ],
    );
  }

  Widget _roomCard(BuildContext context, ResidenceRoom room) {
    final repo = widget.repository;
    final busy = _busy.contains(room.id);
    final closable = room.isActive && room.occupied == 0;
    final place = [room.floor, room.wing].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
    final line = [
      if (room.roomType != null && room.roomType!.isNotEmpty) ResidencesLabels.humanise(room.roomType),
      if (place.isNotEmpty) place,
    ].join(' — ');
    return Padding(
      key: ValueKey('residence-room-${room.id}'),
      padding: const EdgeInsets.only(bottom: 10),
      child: HandoverPanel(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(room.name, style: handoverText(context, 16, weight: FontWeight.w700)),
                      Text(line.isEmpty ? 'No floor or type recorded' : line,
                          style: handoverText(context, 11.5, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                if (!room.isActive)
                  const AttendancePill(label: 'Out of use', tone: AttendanceTone.neutral)
                else if (room.available > 0)
                  AttendancePill(label: '${room.available} free', tone: AttendanceTone.success)
                else
                  const AttendancePill(label: 'Full', tone: AttendanceTone.warning),
              ],
            ),
            const SizedBox(height: 8),
            if (room.residentNames.isEmpty)
              Text(
                'Empty — ${room.capacity == 1 ? 'one bed' : '${room.capacity} beds'}',
                style: handoverText(context, 12.5, color: AppColors.textMuted),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final name in room.residentNames) AttendancePill(label: name, tone: AttendanceTone.info),
                ],
              ),
            if (widget.canManage && repo != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text('${room.occupied} of ${room.capacity}',
                        style: handoverText(context, 11.5, color: AppColors.textMuted)),
                  ),
                  if (room.isActive)
                    Tooltip(
                      message: closable ? 'Take this room out of use' : 'Move the residents out first',
                      child: TextButton.icon(
                        key: ValueKey('residence-room-close-${room.id}'),
                        onPressed: !closable || busy
                            ? null
                            : () => _roomAction(room, () => repo.archiveRoom(widget.residenceId, room.id)),
                        icon: const Icon(Icons.door_front_door_outlined, size: 14),
                        label: const Text('Close'),
                      ),
                    )
                  else
                    TextButton.icon(
                      key: ValueKey('residence-room-reopen-${room.id}'),
                      onPressed:
                          busy ? null : () => _roomAction(room, () => repo.reactivateRoom(widget.residenceId, room.id)),
                      icon: const Icon(Icons.restart_alt_rounded, size: 14),
                      label: const Text('Bring back'),
                    ),
                ],
              ),
            ],
            if (_roomErrors[room.id] != null)
              Text(_roomErrors[room.id]!, style: handoverText(context, 12, color: AppColors.criticalRed)),
          ],
        ),
      ),
    );
  }
}

class _AddRoomForm extends StatefulWidget {
  final ResidenceAdminRepository? repository;
  final String residenceId;
  final ValueChanged<bool> onDone;

  const _AddRoomForm({required this.repository, required this.residenceId, required this.onDone});

  @override
  State<_AddRoomForm> createState() => _AddRoomFormState();
}

class _AddRoomFormState extends State<_AddRoomForm> {
  final _name = TextEditingController();
  final _floor = TextEditingController();
  final _wing = TextEditingController();
  final _sleeps = TextEditingController(text: '1');
  String _type = 'single';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _floor.dispose();
    _wing.dispose();
    _sleeps.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final repo = widget.repository;
    final name = _name.text.trim();
    if (repo == null || name.isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    String? opt(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    final result = await repo.createRoom(
      widget.residenceId,
      name: name,
      capacity: (int.tryParse(_sleeps.text.trim()) ?? 0) == 0 ? 1 : int.parse(_sleeps.text.trim()),
      floor: opt(_floor),
      wing: opt(_wing),
      roomType: _type,
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = result.error?.message;
    });
    if (result.isSuccess) widget.onDone(true);
  }

  @override
  Widget build(BuildContext context) {
    return HandoverPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ResidenceTextInput(
            field: 'roomName',
            label: 'Room name',
            required: true,
            placeholder: '204',
            helper: 'What is on the door',
            controller: _name,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          ResidenceTextInput(
              field: 'roomFloor', label: 'Floor', placeholder: 'Ground', controller: _floor, onChanged: (_) {}),
          const SizedBox(height: 10),
          ResidenceTextInput(field: 'roomWing', label: 'Wing', placeholder: 'East', controller: _wing, onChanged: (_) {}),
          const SizedBox(height: 10),
          ResidenceSelectInput(
            field: 'roomType',
            label: 'Type',
            value: _type,
            options: ResidencesLabels.roomTypes,
            onChanged: (v) => setState(() {
              _type = v;
              _sleeps.text = v == 'double' || v == 'twin' ? '2' : '1';
            }),
          ),
          const SizedBox(height: 10),
          ResidenceTextInput(
              field: 'roomSleeps', label: 'Sleeps', numeric: true, controller: _sleeps, onChanged: (_) {}),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: handoverText(context, 12, color: AppColors.criticalRed)),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => widget.onDone(false), child: const Text('Cancel')),
              const SizedBox(width: 8),
              HandoverButton(
                key: const ValueKey('residence-room-save'),
                label: _saving ? 'Adding…' : 'Add room',
                filled: true,
                compact: true,
                onPressed: _name.text.trim().isEmpty || _saving ? null : _save,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Web drawer "Staff" tab.
class ResidenceStaffTab extends StatefulWidget {
  final ResidenceAdminRepository? repository;
  final ResidenceSummary residence;

  const ResidenceStaffTab({super.key, required this.repository, required this.residence});

  @override
  State<ResidenceStaffTab> createState() => _ResidenceStaffTabState();
}

class _ResidenceStaffTabState extends State<ResidenceStaffTab> {
  int _page = 1;
  int _limit = _tabPageSizes.first;
  bool _loadingNow = true;
  bool _failed = false;
  ResidenceTabPage<ResidenceStaffMember, StaffSummary>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadingNow = true);
    final repo = widget.repository;
    final result = repo == null
        ? await _unavailable<ResidenceTabPage<ResidenceStaffMember, StaffSummary>>()
        : await repo.getStaff(widget.residence.id, page: _page, limit: _limit);
    if (!mounted) return;
    setState(() {
      _loadingNow = false;
      _failed = result.isFailure;
      _data = result.isSuccess ? result.value : null;
    });
  }

  Map<String, String> get _roles {
    final r = widget.residence;
    final roles = <String, String>{};
    if (r.primaryManager != null) roles[r.primaryManager!.id] = 'primary_manager';
    if (r.assistantManager != null) roles[r.assistantManager!.id] = 'assistant_manager';
    for (final p in r.careTeam) {
      roles[p.id] = 'care_team';
    }
    for (final p in r.assignedStaff) {
      roles[p.id] = 'staff';
    }
    return roles;
  }

  @override
  Widget build(BuildContext context) {
    final roles = _roles;
    final order = ResidencesLabels.residenceRoleOrder;
    int rank(String id) => order.indexOf(roles[id] ?? '');
    final rows = [...?_data?.items]..sort((a, b) {
        final byRole = rank(a.id).compareTo(rank(b.id));
        return byRole != 0 ? byRole : a.name.compareTo(b.name);
      });
    final total = _data?.total ?? rows.length;
    final summary = _data?.summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (summary != null) ...[
          ResidenceTileGrid(children: [
            ResidenceMiniStat(
                label: 'Staff here', value: summary.staff, icon: Icons.people_outline_rounded, tone: ResidenceStatTone.blue),
            ResidenceMiniStat(
                label: 'Active', value: summary.active, icon: Icons.check_circle_outline_rounded, tone: ResidenceStatTone.green),
            ResidenceMiniStat(
                label: 'On leave', value: summary.onLeave, icon: Icons.flight_outlined, tone: ResidenceStatTone.amber),
            ResidenceMiniStat(
              label: 'MAR certified',
              value: summary.medAdminCertified,
              icon: Icons.verified_user_outlined,
              tone: summary.medAdminCertified > 0 ? ResidenceStatTone.green : ResidenceStatTone.red,
            ),
          ]),
          const SizedBox(height: 12),
        ],
        if (_loadingNow)
          _loading()
        else if (rows.isEmpty)
          ResidenceMutedMessage(
            title: _failed ? 'Staff could not be loaded.' : 'Nobody is assigned to this residence yet.',
          )
        else
          for (var i = 0; i < rows.length; i++)
            ResidenceRowTile(
              key: ValueKey('residence-staff-${rows[i].id}'),
              index: i,
              initials: rows[i].initials,
              title: rows[i].name,
              subtitle: rows[i].employeeCode,
              trailing: AttendancePill(label: rows[i].statusLabel, tone: AttendanceTone.neutral),
              facts: [
                (
                  'Role here',
                  roles[rows[i].id] == null
                      ? 'Not assigned'
                      : ResidencesLabels.residenceRoles[roles[rows[i].id]] ?? roles[rows[i].id]!,
                ),
                ('Category', rows[i].category.isEmpty ? '—' : rows[i].category),
                ('Employment', rows[i].employmentType.isEmpty ? '—' : rows[i].employmentType),
                ('MAR certified', rows[i].medAdminCertified ? 'Certified' : '—'),
              ],
            ),
        if (!_loadingNow)
          _pager(_page, _limit, total, (p) {
            _page = p;
            _load();
          }, (l) {
            _limit = l;
            _page = 1;
            _load();
          }),
        if (total > rows.length && rows.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Showing ${rows.length} of $total. The full list is on the Staff page.',
              style: handoverText(context, 12.5, color: AppColors.textMuted),
            ),
          ),
      ],
    );
  }
}

/// Web drawer "Schedule" tab: the week (Monday first) of shifts at the home.
class ResidenceScheduleTab extends StatefulWidget {
  final ResidenceAdminRepository? repository;
  final String residenceId;
  final DateTime Function() now;

  const ResidenceScheduleTab({
    super.key,
    required this.repository,
    required this.residenceId,
    this.now = DateTime.now,
  });

  @override
  State<ResidenceScheduleTab> createState() => _ResidenceScheduleTabState();
}

class _ResidenceScheduleTabState extends State<ResidenceScheduleTab> {
  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  int _offset = 0;
  bool _loadingNow = true;
  String? _error;
  List<ResidenceShift> _shifts = const [];

  DateTime get _weekStart {
    final n = widget.now();
    final today = DateTime(n.year, n.month, n.day);
    return DateTime(today.year, today.month, today.day - (today.weekday - 1) + 7 * _offset);
  }

  DateTime get _weekEnd {
    final s = _weekStart;
    return DateTime(s.year, s.month, s.day + 7).subtract(const Duration(milliseconds: 1));
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadingNow = true);
    final repo = widget.repository;
    final result = repo == null
        ? await _unavailable<List<ResidenceShift>>()
        : await repo.getShifts(widget.residenceId, from: _weekStart, to: _weekEnd);
    if (!mounted) return;
    setState(() {
      _loadingNow = false;
      _error = result.error?.message;
      _shifts = result.isSuccess ? result.value! : const [];
    });
  }

  void _move(int offset) {
    _offset = offset;
    _load();
  }

  static bool _sameDay(DateTime a, DateTime b) {
    final x = a.toLocal();
    final y = b.toLocal();
    return x.year == y.year && x.month == y.month && x.day == y.day;
  }

  @override
  Widget build(BuildContext context) {
    final start = _weekStart;
    final end = _weekEnd;
    final label = '${start.day} ${_months[start.month - 1]} – ${end.day} ${_months[end.month - 1]} ${end.year}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, key: const ValueKey('residence-week-label'), style: handoverText(context, 14, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            HandoverButton(
                key: const ValueKey('residence-week-prev'), label: 'Previous', compact: true, onPressed: () => _move(_offset - 1)),
            if (_offset != 0)
              HandoverButton(
                  key: const ValueKey('residence-week-this'), label: 'This week', compact: true, onPressed: () => _move(0)),
            HandoverButton(
                key: const ValueKey('residence-week-next'), label: 'Next', compact: true, onPressed: () => _move(_offset + 1)),
          ],
        ),
        const SizedBox(height: 12),
        if (_loadingNow)
          _loading()
        else if (_shifts.isEmpty)
          HandoverPanel(
            child: Column(
              children: [
                const Icon(Icons.calendar_month_outlined, size: 20, color: AppColors.textMuted),
                const SizedBox(height: 4),
                Text(
                  _error != null ? 'The rota could not be loaded' : 'Nothing rostered this week',
                  textAlign: TextAlign.center,
                  style: handoverText(context, 15, weight: FontWeight.w600),
                ),
                Text(
                  _error ?? 'Shifts created for this home appear here.',
                  textAlign: TextAlign.center,
                  style: handoverText(context, 13.5, color: AppColors.textMuted),
                ),
              ],
            ),
          )
        else
          for (var d = 0; d < 7; d++) _day(context, DateTime(start.year, start.month, start.day + d)),
      ],
    );
  }

  Widget _day(BuildContext context, DateTime date) {
    final shifts = _shifts.where((s) => s.startsAt != null && _sameDay(s.startsAt!, date)).toList()
      ..sort((a, b) => a.startsAt!.compareTo(b.startsAt!));
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ResidenceCaption('${_weekdays[date.weekday - 1]} ${date.day} ${_months[date.month - 1]}'),
          const SizedBox(height: 6),
          if (shifts.isEmpty)
            Text('Nobody rostered.', style: handoverText(context, 12.5, color: AppColors.textMuted))
          else
            for (final s in shifts) _shift(context, s),
        ],
      ),
    );
  }

  Widget _shift(BuildContext context, ResidenceShift s) {
    final open = s.status == 'open';
    final nextDay = s.endsAt != null && !_sameDay(s.endsAt!, s.startsAt!);
    final time = '${WebFormat.time(s.startsAt, empty: '')}'
        '${s.endsAt != null ? ' – ${WebFormat.time(s.endsAt, empty: '')}' : ''}'
        '${nextDay ? ' (next day)' : ''}';
    return Padding(
      key: ValueKey('residence-shift-${s.id}'),
      padding: const EdgeInsets.only(bottom: 6),
      child: HandoverPanel(
        padding: const EdgeInsets.all(12),
        borderColor: open ? AppColors.urgentAmber.withValues(alpha: 0.4) : AppColors.cardBorder,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  [s.title, s.shiftType].firstWhere((v) => v != null && v.isNotEmpty, orElse: () => 'Shift')!,
                  style: handoverText(context, 13, weight: FontWeight.w600),
                ),
                AttendancePill(label: s.status ?? '—', tone: ResidencesLabels.shiftTone(s.status)),
                Text(time, style: handoverText(context, 12, color: AppColors.textMuted)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${s.assignedCount} of ${s.requiredStaffCount} assigned'
              '${s.requiredCategoryName != null && s.requiredCategoryName!.isNotEmpty ? ' · ${s.requiredCategoryName}' : ''}',
              style: handoverText(context, 12.5, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Web drawer "Daily Logs" tab.
class ResidenceDailyLogsTab extends StatefulWidget {
  final ResidenceAdminRepository? repository;
  final String residenceId;

  const ResidenceDailyLogsTab({super.key, required this.repository, required this.residenceId});

  @override
  State<ResidenceDailyLogsTab> createState() => _ResidenceDailyLogsTabState();
}

class _ResidenceDailyLogsTabState extends State<ResidenceDailyLogsTab> {
  int _reviewPage = 1;
  int _reviewLimit = _tabPageSizes.first;
  int _missingPage = 1;
  int _missingLimit = _tabPageSizes.first;
  bool _reviewLoading = true;
  bool _missingLoading = true;
  String? _reviewError;
  ResidenceTabPage<ResidenceLogDay, void>? _review;
  ResidenceTabPage<ResidenceLogDay, void>? _missing;

  @override
  void initState() {
    super.initState();
    _loadReview();
    _loadMissing();
  }

  Future<void> _loadReview() async {
    setState(() => _reviewLoading = true);
    final repo = widget.repository;
    final result = repo == null
        ? await _unavailable<ResidenceTabPage<ResidenceLogDay, void>>()
        : await repo.getReviewQueue(widget.residenceId, page: _reviewPage, limit: _reviewLimit);
    if (!mounted) return;
    setState(() {
      _reviewLoading = false;
      _reviewError = result.error?.message;
      _review = result.isSuccess ? result.value : null;
    });
  }

  Future<void> _loadMissing() async {
    setState(() => _missingLoading = true);
    final repo = widget.repository;
    final result = repo == null
        ? await _unavailable<ResidenceTabPage<ResidenceLogDay, void>>()
        : await repo.getMissingLogs(widget.residenceId, page: _missingPage, limit: _missingLimit);
    if (!mounted) return;
    setState(() {
      _missingLoading = false;
      _missing = result.isSuccess ? result.value : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final review = _review?.items ?? const <ResidenceLogDay>[];
    final missing = _missing?.items ?? const <ResidenceLogDay>[];
    final entries = review.fold<int>(0, (s, d) => s + d.entriesCount);
    final reviewTotal = _review?.total ?? review.length;
    final missingTotal = _missing?.total ?? missing.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResidenceStatCard(label: 'Entries written', value: '$entries', hint: 'In the last 7 days'),
        const SizedBox(height: 10),
        ResidenceStatCard(
            label: 'Days to review', value: '$reviewTotal', hint: 'Resident-days with entries on them'),
        const SizedBox(height: 10),
        ResidenceStatCard(label: 'Missing', value: '$missingTotal', hint: 'Resident-days with nothing written'),
        if (missingTotal > 0) ...[
          const SizedBox(height: 16),
          const ResidenceCaption('Nothing written'),
          const SizedBox(height: 8),
          if (_missingLoading)
            _loading()
          else
            for (var i = 0; i < missing.length; i++)
              ResidenceRowTile(
                index: i,
                title: missing[i].clientName,
                trailing: AttendancePill(label: WebFormat.date(missing[i].logDate), tone: AttendanceTone.danger),
              ),
          _pager(_missingPage, _missingLimit, missingTotal, (p) {
            _missingPage = p;
            _loadMissing();
          }, (l) {
            _missingLimit = l;
            _missingPage = 1;
            _loadMissing();
          }),
        ],
        const SizedBox(height: 16),
        const ResidenceCaption('To review'),
        const SizedBox(height: 8),
        if (_reviewLoading)
          _loading()
        else if (review.isEmpty)
          ResidenceMutedMessage(
            icon: Icons.description_outlined,
            title: _reviewError ?? 'Nothing waiting to be reviewed.',
          )
        else
          for (var i = 0; i < review.length; i++)
            ResidenceRowTile(
              index: i,
              title: review[i].clientName,
              subtitle: WebFormat.date(review[i].logDate),
              trailing: AttendancePill(label: '${review[i].entriesCount}', tone: AttendanceTone.info),
            ),
        if (!_reviewLoading)
          _pager(_reviewPage, _reviewLimit, reviewTotal, (p) {
            _reviewPage = p;
            _loadReview();
          }, (l) {
            _reviewLimit = l;
            _reviewPage = 1;
            _loadReview();
          }),
      ],
    );
  }
}
