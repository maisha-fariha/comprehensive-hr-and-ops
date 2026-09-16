import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/roles/user_session.dart';
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

  @override
  void initState() {
    super.initState();
    _repository = GetIt.instance<StaffExtrasRepository>();
    _session = Get.find<UserSession>();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repository.getHandovers();
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

  @override
  Widget build(BuildContext context) {
    final canWrite = _session.canAccessHandovers;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Shift handovers'),
        backgroundColor: AppColors.surfaceWhite,
        foregroundColor: AppColors.textHeading,
        elevation: 0,
      ),
      floatingActionButton: canWrite
          ? FloatingActionButton(
              backgroundColor: AppColors.secondaryTeal,
              onPressed: _createHandover,
              child: const Icon(Icons.add),
            )
          : null,
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
              : RefreshIndicator(
                  color: AppColors.secondaryTeal,
                  onRefresh: _load,
                  child: _items.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            Center(
                              child: Text(
                                'No shift handovers yet.',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: ResponsiveHelper.getResponsivePadding(
                            context,
                            horizontal: 16,
                            top: 16,
                            bottom: 88,
                          ),
                          itemCount: _items.length,
                          separatorBuilder: (_, _) => SizedBox(
                            height: ResponsiveHelper.getResponsiveHeight(
                              context,
                              12,
                            ),
                          ),
                          itemBuilder: (context, index) {
                            final handover = _items[index];
                            return StaffShiftHandoverCard(
                              handover: handover,
                              residenceFallback: _session.residenceName,
                              onAcknowledge: canWrite
                                  ? () => _acknowledge(handover)
                                  : null,
                              onDelete:
                                  canWrite ? () => _delete(handover) : null,
                            );
                          },
                        ),
                ),
    );
  }
}
