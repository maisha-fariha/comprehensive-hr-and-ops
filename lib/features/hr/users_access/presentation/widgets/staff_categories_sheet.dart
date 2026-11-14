import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../data/users_access_repository.dart';
import '../../domain/users_access_models.dart';

/// Web "Staff categories" / "Job titles" modal.
Future<void> showStaffCategoriesSheet(
  BuildContext context, {
  required UsersAccessRepository repository,
  required bool canWrite,
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _StaffCategoriesSheet(
      repository: repository,
      canWrite: canWrite,
    ),
  );
}

class _StaffCategoriesSheet extends StatefulWidget {
  final UsersAccessRepository repository;
  final bool canWrite;

  const _StaffCategoriesSheet({
    required this.repository,
    required this.canWrite,
  });

  @override
  State<_StaffCategoriesSheet> createState() => _StaffCategoriesSheetState();
}

class _StaffCategoriesSheetState extends State<_StaffCategoriesSheet> {
  final _name = TextEditingController();
  List<StaffCategoryItem> _items = const [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await widget.repository.fetchStaffCategories();
    if (!mounted) return;
    result.when(
      success: (items) => setState(() {
        _items = items;
        _loading = false;
      }),
      failure: (error) => setState(() {
        _loading = false;
        _error = error.message;
      }),
    );
  }

  Future<void> _add() async {
    if (!widget.canWrite || _saving) return;
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a job title name.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await widget.repository.createStaffCategory(name: name);
    if (!mounted) return;
    result.when(
      success: (_) {
        _name.clear();
        setState(() => _saving = false);
        AppSnackbar.show('Job title added', name, force: true);
        _reload();
      },
      failure: (error) => setState(() {
        _saving = false;
        _error = error.message;
      }),
    );
  }

  Future<void> _rename(StaffCategoryItem item) async {
    if (!widget.canWrite) return;
    final controller = TextEditingController(text: item.name);
    final next = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit job title'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (next == null || next.isEmpty || next == item.name || !mounted) return;
    final result = await widget.repository.updateStaffCategory(
      id: item.id,
      name: next,
      residenceType: item.residenceType,
    );
    if (!mounted) return;
    result.when(
      success: (_) {
        AppSnackbar.show('Job title updated', next, force: true);
        _reload();
      },
      failure: (error) =>
          AppSnackbar.show('Could not update', error.message, force: true),
    );
  }

  Future<void> _toggleArchive(StaffCategoryItem item) async {
    if (!widget.canWrite) return;
    final result = item.isActive
        ? await widget.repository.archiveStaffCategory(item.id)
        : await widget.repository.restoreStaffCategory(item.id);
    if (!mounted) return;
    result.when(
      success: (_) {
        AppSnackbar.show(
          item.isActive ? 'Job title retired' : 'Job title restored',
          item.name,
          force: true,
        );
        _reload();
      },
      failure: (error) =>
          AppSnackbar.show('Could not update', error.message, force: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                child: Row(
                  children: [
                    const Icon(Icons.work_outline, color: AppColors.infoBlue),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Job titles',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                          Text(
                            'What your people are called. Retiring one keeps everybody already holding it.',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      color: AppColors.criticalRed,
                    ),
                  ),
                ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              item.name,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w600,
                                decoration: item.isActive
                                    ? null
                                    : TextDecoration.lineThrough,
                              ),
                            ),
                            subtitle: item.residenceType.isEmpty
                                ? null
                                : Text(
                                    item.residenceType,
                                    style: const TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                            trailing: widget.canWrite
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Edit',
                                        onPressed: () => _rename(item),
                                        icon: const Icon(Icons.edit_outlined),
                                      ),
                                      IconButton(
                                        tooltip: item.isActive
                                            ? 'Retire'
                                            : 'Restore',
                                        onPressed: () => _toggleArchive(item),
                                        icon: Icon(
                                          item.isActive
                                              ? Icons.delete_outline
                                              : Icons.restore_outlined,
                                        ),
                                      ),
                                    ],
                                  )
                                : null,
                          );
                        },
                      ),
              ),
              if (widget.canWrite)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Add a job title',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _name,
                              enabled: !_saving,
                              decoration: const InputDecoration(
                                hintText: 'e.g. Registered Nurse',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onSubmitted: (_) => _add(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: _saving ? null : _add,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryNavy,
                            ),
                            child: Text(_saving ? '…' : '+ Add'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
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
