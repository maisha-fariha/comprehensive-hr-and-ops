import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/staff_residence.dart';
import '../../domain/entities/staff_shift_handover.dart';
import '../../domain/repositories/staff_extras_repository.dart';
import '../widgets/staff_record_handover_dialog.dart';
import '../widgets/staff_shift_handover_card.dart';

class StaffShiftHandoversPage extends StatefulWidget {
  const StaffShiftHandoversPage({super.key});

  @override
  State<StaffShiftHandoversPage> createState() =>
      _StaffShiftHandoversPageState();
}

class _StaffShiftHandoversPageState extends State<StaffShiftHandoversPage> {
  late final StaffExtrasRepository _repository;
  late final UserSession _session;

  bool _loading = true;
  String? _error;
  List<StaffShiftHandover> _items = const [];
  List<StaffResidence> _residences = const [];
  List<StaffResidencePerson> _staffOptions = const [];

  /// Web parity filters: Any status / Anyone / start / end / All Residences.
  String _statusFilter = 'all';
  String _authorFilter = 'all';
  String _residenceFilter = 'all';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _repository = GetIt.instance<StaffExtrasRepository>();
    _session = Get.find<UserSession>();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.wait([_loadFilterOptions(), _load()]);
  }

  Future<void> _loadFilterOptions() async {
    final residencesResult = await _repository.getResidences();
    final staffResult = await _repository.getStaffDirectoryOptions();
    if (!mounted) return;
    setState(() {
      residencesResult.when(
        success: (items) => _residences = items,
        failure: (_) {},
      );
      staffResult.when(
        success: (items) => _staffOptions = items,
        failure: (_) {},
      );
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    DateTime? from = _startDate;
    DateTime? to;
    if (_endDate != null) {
      to = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
        23,
        59,
        59,
        999,
      );
    } else if (_startDate != null) {
      to = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        23,
        59,
        59,
        999,
      );
    }

    final result = await _repository.getHandovers(
      from: from,
      to: to,
      status: _statusFilter,
      residenceId: _residenceFilter,
      authorId: _authorFilter,
    );
    if (!mounted) return;
    result.when(
      success: (items) => setState(() {
        _items = items;
        _loading = false;
      }),
      failure: (err) => setState(() {
        _error = err.message;
        _loading = false;
      }),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_startDate ?? now)
        : (_endDate ?? _startDate ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 365 * 2)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = DateTime(picked.year, picked.month, picked.day);
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = _startDate;
        }
      } else {
        _endDate = DateTime(picked.year, picked.month, picked.day);
        if (_startDate != null && _endDate!.isBefore(_startDate!)) {
          _startDate = _endDate;
        }
      }
    });
    await _load();
  }

  Future<void> _createHandover() async {
    final saved = await StaffRecordHandoverDialog.show();
    if (saved == true) _load();
  }

  Future<void> _acknowledge(StaffShiftHandover handover) async {
    final result = await _repository.acknowledgeHandover(
      handoverId: handover.id,
      note: "I've read and taken this",
    );
    result.when(
      success: (_) {
        Get.snackbar(
          'Acknowledged',
          'Handover taken.',
          snackPosition: SnackPosition.BOTTOM,
        );
        _load();
      },
      failure: (error) => AppErrorDialog.showResultError(
        error,
        fallbackTitle: 'Could not acknowledge',
      ),
    );
  }

  Future<void> _delete(StaffShiftHandover handover) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete handover'),
        content: const Text('Remove this shift handover permanently?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.criticalRed),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final result = await _repository.deleteHandover(handover.id);
    result.when(
      success: (_) {
        Get.snackbar(
          'Deleted',
          'Handover removed.',
          snackPosition: SnackPosition.BOTTOM,
        );
        _load();
      },
      failure: (error) => AppErrorDialog.showResultError(
        error,
        fallbackTitle: 'Could not delete',
      ),
    );
  }

  String _mmDdYyyy(DateTime? date) {
    if (date == null) return 'mm/dd/yyyy';
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$m/$d/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final canWrite = _session.canAccessHandovers;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Shift Handovers'),
        backgroundColor: AppColors.surfaceWhite,
        foregroundColor: AppColors.textHeading,
        elevation: 0,
        actions: [
          if (canWrite)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                key: const Key('staff-handover-record-button'),
                onPressed: _createHandover,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Record Handover'),
              ),
            ),
        ],
      ),
      floatingActionButton: canWrite
          ? FloatingActionButton(
              backgroundColor: AppColors.primaryNavy,
              onPressed: _createHandover,
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: 16,
              top: 12,
              bottom: 8,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _FilterDropdown(
                        keyName: 'staff-handover-status-dropdown',
                        value: _statusFilter,
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('Any status'),
                          ),
                          DropdownMenuItem(
                            value: 'draft',
                            child: Text('Draft'),
                          ),
                          DropdownMenuItem(
                            value: 'submitted',
                            child: Text('Submitted'),
                          ),
                          DropdownMenuItem(
                            value: 'acknowledged',
                            child: Text('Acknowledged'),
                          ),
                        ],
                        onChanged: (value) async {
                          if (value == null) return;
                          setState(() => _statusFilter = value);
                          await _load();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _FilterDropdown(
                        keyName: 'staff-handover-anyone-dropdown',
                        value: _authorFilter,
                        items: [
                          const DropdownMenuItem(
                            value: 'all',
                            child: Text('Anyone'),
                          ),
                          for (final staff in _staffOptions)
                            DropdownMenuItem(
                              value: staff.id,
                              child: Text(staff.name),
                            ),
                        ],
                        onChanged: (value) async {
                          if (value == null) return;
                          setState(() => _authorFilter = value);
                          await _load();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _DateFilterField(
                        keyName: 'staff-handover-start-date-picker',
                        label: _mmDdYyyy(_startDate),
                        onTap: () => _pickDate(isStart: true),
                        onClear: () async {
                          setState(() => _startDate = null);
                          await _load();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DateFilterField(
                        keyName: 'staff-handover-end-date-picker',
                        label: _mmDdYyyy(_endDate),
                        onTap: () => _pickDate(isStart: false),
                        onClear: () async {
                          setState(() => _endDate = null);
                          await _load();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _FilterDropdown(
                  keyName: 'staff-handover-residence-dropdown',
                  value: _residenceFilter,
                  items: [
                    const DropdownMenuItem(
                      value: 'all',
                      child: Text('All Residences'),
                    ),
                    for (final residence in _residences)
                      DropdownMenuItem(
                        value: residence.id,
                        child: Text(residence.name),
                      ),
                  ],
                  onChanged: (value) async {
                    if (value == null) return;
                    setState(() => _residenceFilter = value);
                    await _load();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.secondaryTeal,
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _load,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.secondaryTeal,
                        onRefresh: _load,
                        child: _items.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: 120),
                                  Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 24,
                                      ),
                                      child: Text(
                                        'No handovers yet. What one shift tells the next will appear here.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding: ResponsiveHelper.getResponsivePadding(
                                  context,
                                  all: 16,
                                ),
                                itemCount: _items.length,
                                separatorBuilder: (_, _) => SizedBox(
                                  height: ResponsiveHelper.getResponsiveHeight(
                                    context,
                                    10,
                                  ),
                                ),
                                itemBuilder: (context, index) {
                                  final handover = _items[index];
                                  return StaffShiftHandoverCard(
                                    handover: handover,
                                    residenceFallback:
                                        _session.residenceName ?? '',
                                    onAcknowledge: canWrite
                                        ? () => _acknowledge(handover)
                                        : null,
                                    onDelete: canWrite
                                        ? () => _delete(handover)
                                        : null,
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String keyName;
  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.keyName,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = items.any((item) => item.value == value) ? value : 'all';
    return Container(
      key: Key(keyName),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.searchBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: resolved,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _DateFilterField extends StatelessWidget {
  final String keyName;
  final String label;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DateFilterField({
    required this.keyName,
    required this.label,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: Key(keyName),
        onTap: onTap,
        onLongPress: onClear,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.searchBorder),
          ),
          child: Row(
            children: [
              const AppSvgIcon(
                AppAssets.navCalendar,
                size: 16,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: label == 'mm/dd/yyyy'
                        ? AppColors.textMuted
                        : AppColors.textHeading,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
