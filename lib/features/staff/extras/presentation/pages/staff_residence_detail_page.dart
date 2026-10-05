import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/staff_residence.dart';
import '../../domain/repositories/staff_extras_repository.dart';
import 'staff_residence_edit_page.dart';

/// Web-matched Residence View with Overview / Clients / Rooms / Staff /
/// Schedule / Daily Logs tabs.
class StaffResidenceDetailPage extends StatefulWidget {
  final String residenceId;
  final String? fallbackName;

  const StaffResidenceDetailPage({
    super.key,
    required this.residenceId,
    this.fallbackName,
  });

  @override
  State<StaffResidenceDetailPage> createState() =>
      _StaffResidenceDetailPageState();
}

class _StaffResidenceDetailPageState extends State<StaffResidenceDetailPage>
    with SingleTickerProviderStateMixin {
  late final StaffExtrasRepository _repository;
  late final TabController _tabs;
  bool _loading = true;
  String? _error;
  StaffResidence? _residence;
  List<Map<String, String>> _clients = const [];
  List<Map<String, String>> _rooms = const [];
  List<Map<String, String>> _staff = const [];
  List<Map<String, String>> _shifts = const [];
  List<Map<String, String>> _logs = const [];

  @override
  void initState() {
    super.initState();
    _repository = GetIt.instance<StaffExtrasRepository>();
    _tabs = TabController(length: 6, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final id = widget.residenceId;
    final detail = await _repository.getResidenceDetail(id);
    if (!mounted) return;

    StaffResidence? residence;
    String? error;
    detail.when(
      success: (value) => residence = value,
      failure: (err) => error = err.message,
    );

    if (residence == null) {
      setState(() {
        _error = error;
        _loading = false;
      });
      return;
    }

    final clientsResult = await _repository.getResidenceClients(id);
    final roomsResult = await _repository.getResidenceRooms(id);
    final staffResult = await _repository.getResidenceStaffMembers(id);
    final shiftsResult = await _repository.getResidenceShifts(id);
    final logsResult = await _repository.getResidenceDailyLogs(id);
    if (!mounted) return;

    List<Map<String, String>> clients = const [];
    List<Map<String, String>> rooms = const [];
    List<Map<String, String>> staff = const [];
    List<Map<String, String>> shifts = const [];
    List<Map<String, String>> logs = const [];

    clientsResult.when(success: (v) => clients = v, failure: (_) {});
    roomsResult.when(success: (v) => rooms = v, failure: (_) {});
    staffResult.when(success: (v) => staff = v, failure: (_) {});
    shiftsResult.when(success: (v) => shifts = v, failure: (_) {});
    logsResult.when(success: (v) => logs = v, failure: (_) {});

    setState(() {
      _residence = residence;
      _clients = clients;
      _rooms = rooms;
      _staff = staff;
      _shifts = shifts;
      _logs = logs;
      _loading = false;
    });
  }

  Future<void> _openEdit() async {
    final residence = _residence;
    if (residence == null) return;
    final updated = await Get.to<bool>(
      () => StaffResidenceEditPage(residence: residence),
    );
    if (updated == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final residence = _residence;
    final title = (residence?.name ?? widget.fallbackName ?? 'Residence').trim();

    return Scaffold(
      key: const Key('staff-residence-detail-page'),
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.secondaryTeal),
              )
            : residence == null
                ? _ErrorBody(message: _error ?? 'Residence not found', onRetry: _load)
                : Column(
                    children: [
                      _Header(
                        residence: residence,
                        title: title,
                        onClose: Get.back,
                      ),
                      ColoredBox(
                        color: AppColors.surfaceWhite,
                        child: TabBar(
                          controller: _tabs,
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          labelColor: AppColors.secondaryTeal,
                          unselectedLabelColor: AppColors.textSecondary,
                          indicatorColor: AppColors.secondaryTeal,
                          labelStyle: const TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          tabs: [
                            const Tab(text: 'Overview'),
                            Tab(text: 'Clients (${_clients.length})'),
                            const Tab(text: 'Rooms'),
                            Tab(
                              text:
                                  'Staff (${_staff.isNotEmpty ? _staff.length : residence.totalStaffCount})',
                            ),
                            const Tab(text: 'Schedule'),
                            const Tab(text: 'Daily Logs'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabs,
                          children: [
                            _OverviewTab(residence: residence),
                            _RowsTab(
                              emptyLabel: 'No clients assigned yet.',
                              items: _clients,
                            ),
                            _RowsTab(
                              emptyLabel: 'None recorded yet.',
                              items: _rooms,
                            ),
                            _RowsTab(
                              emptyLabel: 'No staff posted here yet.',
                              items: _staff.isNotEmpty
                                  ? _staff
                                  : [
                                      ...[
                                        if (residence.primaryManager != null)
                                          {
                                            'id': residence.primaryManager!.id,
                                            'title':
                                                residence.primaryManager!.name,
                                            'subtitle': 'Primary manager',
                                            'status': '',
                                          },
                                        ...residence.careTeam.map(
                                          (p) => {
                                            'id': p.id,
                                            'title': p.name,
                                            'subtitle': p.role,
                                            'status': '',
                                          },
                                        ),
                                        ...residence.assignedStaff.map(
                                          (p) => {
                                            'id': p.id,
                                            'title': p.name,
                                            'subtitle': p.role,
                                            'status': '',
                                          },
                                        ),
                                      ],
                                    ],
                            ),
                            _RowsTab(
                              emptyLabel: 'No shifts scheduled.',
                              items: _shifts,
                            ),
                            _RowsTab(
                              emptyLabel: 'No daily logs for this home.',
                              items: _logs,
                            ),
                          ],
                        ),
                      ),
                      _Footer(
                        updatedAt: residence.updatedAt,
                        onClose: Get.back,
                        onEdit: Get.find<UserSession>().can('residences:update')
                            ? _openEdit
                            : null,
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final StaffResidence residence;
  final String title;
  final VoidCallback onClose;

  const _Header({
    required this.residence,
    required this.title,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surfaceWhite,
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryNavy,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.apartment_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              18,
                            ),
                            color: AppColors.textHeading,
                          ),
                        ),
                        if (residence.status.trim().isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: residence.isActive
                                  ? AppColors.activeBackground
                                  : AppColors.filterButtonBackground,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  residence.isActive
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  size: 12,
                                  color: residence.isActive
                                      ? AppColors.activeGreen
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  residence.statusLabel,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                    color: residence.isActive
                                        ? AppColors.activeGreen
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.filterButtonBackground,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '#${residence.shortId}',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Manage residence operations, clients, staff, schedules and daily activities.',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              if (residence.listAddress.isNotEmpty)
                _MetaChip(Icons.place_outlined, residence.listAddress),
              if (residence.residenceType.isNotEmpty)
                _MetaChip(Icons.home_work_outlined, residence.typePrimaryLabel),
              if ((residence.phone ?? '').isNotEmpty)
                _MetaChip(Icons.phone_outlined, residence.phone!),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaChip(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.7,
          ),
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final StaffResidence residence;

  const _OverviewTab({required this.residence});

  @override
  Widget build(BuildContext context) {
    final free = residence.availableBeds;
    final mix = residence.careLevelMix.entries.toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final gap = 8.0;
            final width = (constraints.maxWidth - gap) / 2;
            final cards = [
              _StatCard(
                label: 'Occupancy',
                value: residence.occupancyShort,
                subtitle: free == null
                    ? 'Beds'
                    : '$free bed${free == 1 ? '' : 's'} free',
              ),
              _StatCard(
                label: 'Rooms',
                value: '${residence.roomCount}',
                subtitle: residence.roomCount == 0
                    ? 'None recorded yet'
                    : 'Recorded rooms',
              ),
              _StatCard(
                label: 'People Posted Here',
                value: '${residence.totalStaffCount}',
                subtitle: residence.primaryManager == null
                    ? 'Assigned staff'
                    : 'Managed by ${residence.primaryManager!.name}',
              ),
              _StatCard(
                label: 'Geofence',
                value: residence.gpsRadiusLabel,
                subtitle: residence.gpsRadiusLabel == '—'
                    ? 'Not set'
                    : 'Around this address',
              ),
            ];
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final card in cards)
                  SizedBox(width: width, child: card),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Contact',
          children: [
            _kv('Address', residence.listAddress.isEmpty ? '—' : residence.listAddress),
            _kv('Phone', _dash(residence.phone)),
            _kv('Emergency', _dash(residence.emergencyPhone)),
            _kv('Email', _dash(residence.email)),
            _kv('Management phone', _dash(residence.managementPhone)),
            _kv('Management email', _dash(residence.managementEmail)),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'This home',
          children: [
            _kv('Type', residence.typeDisplayLabel),
            _kv('Service', residence.serviceType.trim().isEmpty
                ? '—'
                : residence.serviceType),
            _kv(
              'Licensed beds',
              residence.bedCapacity?.toString() ?? '—',
            ),
            _kv('Timezone', _dash(residence.timezone)),
            _kv(
              'Out-of-pocket claims',
              residence.outOfPocketEnabled ? 'On' : 'Off',
            ),
            _kv(
              'Mileage claims',
              residence.mileageEnabled ? 'On' : 'Off',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _SectionCard(
                title: 'Care level mix',
                children: [
                  if (mix.isEmpty)
                    const Text(
                      '—',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: AppColors.textMuted,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final entry in mix)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.infoBackground,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${entry.key} • ${entry.value}',
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: AppColors.infoBlue,
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SectionCard(
                title: 'Management',
                children: [
                  _kv(
                    'Primary manager',
                    residence.primaryManager?.name ?? '—',
                  ),
                  if (residence.assistantManager != null)
                    _kv(
                      'Assistant manager',
                      residence.assistantManager!.name,
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _dash(String? value) {
    final text = (value ?? '').trim();
    return text.isEmpty ? '—' : text;
  }

  static Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textHeading,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;

  const _StatCard({
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11.5,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _RowsTab extends StatelessWidget {
  final List<Map<String, String>> items;
  final String emptyLabel;

  const _RowsTab({required this.items, required this.emptyLabel});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          emptyLabel,
          style: const TextStyle(
            fontFamily: 'Outfit',
            color: AppColors.textMuted,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] ?? '',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHeading,
                      ),
                    ),
                    if ((item['subtitle'] ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          item['subtitle']!,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    if ((item['status'] ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          item['status']!,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryTeal,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Footer extends StatelessWidget {
  final DateTime? updatedAt;
  final VoidCallback onClose;
  final VoidCallback? onEdit;

  const _Footer({
    required this.updatedAt,
    required this.onClose,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final local = updatedAt?.toLocal();
    final updated = local == null
        ? null
        : '${local.day.toString().padLeft(2, '0')}/'
            '${local.month.toString().padLeft(2, '0')}/'
            '${local.year}';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          if (updated != null)
            Expanded(
              child: Text(
                'Updated $updated',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            )
          else
            const Spacer(),
          OutlinedButton(
            onPressed: onClose,
            child: const Text('Close'),
          ),
          if (onEdit != null) ...[
            const SizedBox(width: 8),
            OutlinedButton.icon(
              key: const Key('staff-residence-detail-edit'),
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit Residence'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBody({required this.message, required this.onRetry});

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
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
