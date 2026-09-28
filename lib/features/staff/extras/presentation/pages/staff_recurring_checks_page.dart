import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../tasks_messages/domain/entities/recurring_check_instance.dart';
import '../../../tasks_messages/domain/repositories/staff_tasks_messages_repository.dart';

/// Dedicated Recurring Checks module (BUG_Report008).
class StaffRecurringChecksPage extends StatefulWidget {
  const StaffRecurringChecksPage({super.key});

  @override
  State<StaffRecurringChecksPage> createState() =>
      _StaffRecurringChecksPageState();
}

class _StaffRecurringChecksPageState extends State<StaffRecurringChecksPage> {
  late final StaffTasksMessagesRepository _repository;
  bool _loading = true;
  String? _error;
  List<RecurringCheckInstance> _items = const [];

  @override
  void initState() {
    super.initState();
    _repository = GetIt.instance<StaffTasksMessagesRepository>();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repository.getMyRecurringChecks();
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

  Future<void> _complete(RecurringCheckInstance check) async {
    final result = await _repository.updateRecurringCheck(
      instanceId: check.id,
      status: 'requires_review',
      statusNote: 'Completed from Recurring Checks',
    );
    result.when(
      success: (_) {
        AppSnackbar.show('Check updated', check.title);
        _load();
      },
      failure: (error) => AppErrorDialog.showResultError(
        error,
        fallbackTitle: 'Could not update check',
      ),
    );
  }

  Future<void> _skip(RecurringCheckInstance check) async {
    final result = await _repository.updateRecurringCheck(
      instanceId: check.id,
      status: 'skipped',
      statusNote: 'Skipped from Recurring Checks',
    );
    result.when(
      success: (_) {
        AppSnackbar.show('Check skipped', check.title);
        _load();
      },
      failure: (error) => AppErrorDialog.showResultError(
        error,
        fallbackTitle: 'Could not skip check',
      ),
    );
  }

  Color _statusColor(String status) {
    return switch (status.toLowerCase()) {
      'pending' => AppColors.urgentAmber,
      'in_progress' || 'in progress' => AppColors.infoBlue,
      'requires_review' || 'requires review' => AppColors.secondaryTeal,
      'skipped' => AppColors.textMuted,
      _ => AppColors.textSecondary,
    };
  }

  String _statusLabel(String status) {
    final normalized = status.trim().toLowerCase();
    return switch (normalized) {
      '' => 'Pending',
      'in_progress' => 'In progress',
      'requires_review' => 'Requires review',
      _ => '${normalized[0].toUpperCase()}${normalized.substring(1)}',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('staff-recurring-checks-page'),
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Recurring Checks'),
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
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'No pending recurring checks. Pull to refresh.',
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
                        final check = _items[index];
                        final statusColor = _statusColor(check.statusRaw);
                        return Material(
                          color: AppColors.surfaceWhite,
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        check.title,
                                        style: const TextStyle(
                                          fontFamily: 'Outfit',
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textHeading,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        _statusLabel(check.statusRaw),
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 6,
                                  children: [
                                    if (check.dueLabel.isNotEmpty)
                                      _MetaText(
                                        icon: Icons.schedule_outlined,
                                        text: 'Due ${check.dueLabel}',
                                      ),
                                    if (check.location.isNotEmpty)
                                      _MetaText(
                                        icon: Icons.home_outlined,
                                        text: check.location,
                                      ),
                                  ],
                                ),
                                if (check.isOpen) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _skip(check),
                                          child: const Text('Skip'),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: FilledButton(
                                          onPressed: () => _complete(check),
                                          child: const Text('Complete'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

class _MetaText extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaText({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Outfit',
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
