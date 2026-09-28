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
      status: 'completed',
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
                              child: Text(
                                'No recurring checks due.',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  color: AppColors.textMuted,
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
                            return Material(
                              color: AppColors.surfaceWhite,
                              borderRadius: BorderRadius.circular(14),
                              child: ListTile(
                                title: Text(
                                  check.title,
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  [
                                    if (check.dueLabel.isNotEmpty)
                                      'Due: ${check.dueLabel}',
                                    if (check.location.isNotEmpty)
                                      check.location,
                                    if (check.statusRaw.isNotEmpty)
                                      check.statusRaw,
                                  ].join(' · '),
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                trailing: check.isOpen
                                    ? TextButton(
                                        onPressed: () => _complete(check),
                                        child: const Text('Complete'),
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
