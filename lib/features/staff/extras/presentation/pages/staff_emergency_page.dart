import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/staff_emergency_alert.dart';
import '../widgets/staff_emergency_alert_card.dart';
import '../widgets/staff_emergency_details_sheet.dart';
import '../widgets/staff_raise_emergency_dialog.dart';

enum _EmergencyStatusFilter {
  all,
  active,
  acknowledged,
  inProgress,
  resolved,
  cancelled,
}

/// Staff Emergency list — cards from `GET /emergency-alerts`.
class StaffEmergencyPage extends StatefulWidget {
  const StaffEmergencyPage({super.key});

  @override
  State<StaffEmergencyPage> createState() => _StaffEmergencyPageState();
}

class _StaffEmergencyPageState extends State<StaffEmergencyPage> {
  late final AppApiClient _api;
  late final UserSession _session;
  bool _loading = true;
  String? _error;
  List<StaffEmergencyAlert> _items = const [];
  _EmergencyStatusFilter _filter = _EmergencyStatusFilter.all;

  @override
  void initState() {
    super.initState();
    _api = GetIt.instance<AppApiClient>();
    _session = Get.find<UserSession>();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _api.get(ApiEndpoints.emergencyAlerts, silent: true);
    if (!mounted) return;
    result.when(
      success: (body) {
        final items = JsonCodec.unwrapList(body)
            .whereType<Map>()
            .map((item) => StaffEmergencyAlert.fromJson(JsonCodec.asMap(item)))
            .where((a) => a.id.isNotEmpty)
            .toList();
        setState(() {
          _items = items;
          _loading = false;
        });
      },
      failure: (err) => setState(() {
        _error = err.message;
        _loading = false;
      }),
    );
  }

  int _countFor(_EmergencyStatusFilter filter) {
    switch (filter) {
      case _EmergencyStatusFilter.all:
        return _items.length;
      case _EmergencyStatusFilter.active:
        return _items.where((a) => a.isActive).length;
      case _EmergencyStatusFilter.acknowledged:
        return _items.where((a) => a.isAcknowledged).length;
      case _EmergencyStatusFilter.inProgress:
        return _items.where((a) => a.isInProgress).length;
      case _EmergencyStatusFilter.resolved:
        return _items.where((a) => a.isResolved).length;
      case _EmergencyStatusFilter.cancelled:
        return _items.where((a) => a.isCancelled).length;
    }
  }

  List<StaffEmergencyAlert> get _visibleItems {
    switch (_filter) {
      case _EmergencyStatusFilter.all:
        return _items;
      case _EmergencyStatusFilter.active:
        return _items.where((a) => a.isActive).toList();
      case _EmergencyStatusFilter.acknowledged:
        return _items.where((a) => a.isAcknowledged).toList();
      case _EmergencyStatusFilter.inProgress:
        return _items.where((a) => a.isInProgress).toList();
      case _EmergencyStatusFilter.resolved:
        return _items.where((a) => a.isResolved).toList();
      case _EmergencyStatusFilter.cancelled:
        return _items.where((a) => a.isCancelled).toList();
    }
  }

  Future<void> _raisePanic() async {
    final result = await StaffRaiseEmergencyDialog.show();
    if (result != null) _load();
  }

  Future<void> _openAlert(StaffEmergencyAlert alert) async {
    await StaffEmergencyDetailsSheet.show(alert);
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final canRaise = _session.canRaiseEmergency;
    final visible = _visibleItems;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Emergency'),
        backgroundColor: AppColors.surfaceWhite,
        foregroundColor: AppColors.textHeading,
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondaryTeal),
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
                        TextButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: ResponsiveHelper.getResponsivePadding(
                        context,
                        left: 16,
                        right: 16,
                        top: 16,
                        bottom: 8,
                      ),
                      child: _EmergencyStatusChips(
                        selected: _filter,
                        countFor: _countFor,
                        onSelected: (value) => setState(() => _filter = value),
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        color: AppColors.secondaryTeal,
                        onRefresh: _load,
                        child: _items.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: 120),
                                  Center(
                                    child: Text(
                                      'No emergency alerts yet.',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : visible.isEmpty
                                ? ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    children: [
                                      SizedBox(
                                        height:
                                            ResponsiveHelper.getResponsiveHeight(
                                          context,
                                          120,
                                        ),
                                      ),
                                      Center(
                                        child: Text(
                                          'No ${_filterLabel(_filter).toLowerCase()} alerts.',
                                          style: const TextStyle(
                                            fontFamily: 'Outfit',
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : ListView.separated(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding:
                                        ResponsiveHelper.getResponsivePadding(
                                      context,
                                      horizontal: 16,
                                      top: 8,
                                      bottom: 88,
                                    ),
                                    itemCount: visible.length,
                                    separatorBuilder: (_, _) => SizedBox(
                                      height:
                                          ResponsiveHelper.getResponsiveHeight(
                                        context,
                                        12,
                                      ),
                                    ),
                                    itemBuilder: (context, index) {
                                      final alert = visible[index];
                                      return StaffEmergencyAlertCard(
                                        alert: alert,
                                        onOpen: () => _openAlert(alert),
                                      );
                                    },
                                  ),
                      ),
                    ),
                  ],
                ),
    );
  }

  String _filterLabel(_EmergencyStatusFilter filter) {
    switch (filter) {
      case _EmergencyStatusFilter.all:
        return 'All';
      case _EmergencyStatusFilter.active:
        return 'Active';
      case _EmergencyStatusFilter.acknowledged:
        return 'Acknowledged';
      case _EmergencyStatusFilter.inProgress:
        return 'In Progress';
      case _EmergencyStatusFilter.resolved:
        return 'Resolved';
      case _EmergencyStatusFilter.cancelled:
        return 'Cancelled';
    }
  }
}

class _EmergencyStatusChips extends StatelessWidget {
  final _EmergencyStatusFilter selected;
  final int Function(_EmergencyStatusFilter filter) countFor;
  final ValueChanged<_EmergencyStatusFilter> onSelected;

  static const Color _selectedBg = Color(0xFF0E7C7B);
  static const Color _unselectedInk = Color(0xFF6B7280);
  static const Color _unselectedBorder = Color(0xFFE5E9EF);

  const _EmergencyStatusChips({
    required this.selected,
    required this.countFor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final filter in _EmergencyStatusFilter.values) ...[
            if (filter != _EmergencyStatusFilter.values.first)
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            _StatusChip(
              label: '${_label(filter)} (${countFor(filter)})',
              isSelected: filter == selected,
              onTap: () => onSelected(filter),
            ),
          ],
        ],
      ),
    );
  }

  String _label(_EmergencyStatusFilter filter) {
    switch (filter) {
      case _EmergencyStatusFilter.all:
        return 'All';
      case _EmergencyStatusFilter.active:
        return 'Active';
      case _EmergencyStatusFilter.acknowledged:
        return 'Acknowledged';
      case _EmergencyStatusFilter.inProgress:
        return 'In Progress';
      case _EmergencyStatusFilter.resolved:
        return 'Resolved';
      case _EmergencyStatusFilter.cancelled:
        return 'Cancelled';
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 14,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? _EmergencyStatusChips._selectedBg
              : AppColors.surfaceWhite,
          border: Border.all(
            color: isSelected
                ? _EmergencyStatusChips._selectedBg
                : _EmergencyStatusChips._unselectedBorder,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
            color: isSelected
                ? Colors.white
                : _EmergencyStatusChips._unselectedInk,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}
