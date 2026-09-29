import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_document.dart';
import '../controllers/staff_documents_controller.dart';

Future<void> showStaffDocumentTypesSheet(
  BuildContext context,
  StaffDocumentsController controller,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DocumentTypesSheet(controller: controller),
  );
}

class _DocumentTypesSheet extends StatefulWidget {
  final StaffDocumentsController controller;

  const _DocumentTypesSheet({required this.controller});

  @override
  State<_DocumentTypesSheet> createState() => _DocumentTypesSheetState();
}

class _DocumentTypesSheetState extends State<_DocumentTypesSheet> {
  final _name = TextEditingController();
  String _appliesTo = 'general';
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give the type a name.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await widget.controller.createType(
      name: name,
      appliesTo: _appliesTo,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      success: (_) {
        _name.clear();
        Get.snackbar('Document type added', name);
      },
      failure: (e) => setState(() => _error = e.message),
    );
  }

  Future<void> _archive(StaffDocumentType type) async {
    final result = await widget.controller.archiveType(type.id);
    result.when(
      success: (_) => Get.snackbar('Archived', type.name),
      failure: (e) => Get.snackbar('Could not archive', e.message),
    );
  }

  Future<void> _restore(StaffDocumentType type) async {
    final result = await widget.controller.restoreType(type.id);
    result.when(
      success: (_) => Get.snackbar('Restored', type.name),
      failure: (e) => Get.snackbar('Could not restore', e.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Material(
      color: AppColors.scaffoldBackground,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.85,
          child: Column(
            children: [
              ColoredBox(
                color: AppColors.surfaceWhite,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.infoBackground,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.sell_outlined,
                              color: AppColors.infoBlue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Document types',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.w700,
                                    fontSize:
                                        ResponsiveHelper.getResponsiveFontSize(
                                      context,
                                      18,
                                    ),
                                    color: AppColors.textHeading,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'What a document can be filed as. Retired types are archived, never deleted.',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12.5,
                                    color: AppColors.textMuted,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _name,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: AppColors.textHeading,
                            ),
                            decoration: InputDecoration(
                              hintText: 'e.g. DBS certificate',
                              hintStyle: const TextStyle(
                                fontFamily: 'Outfit',
                                color: AppColors.textMuted,
                              ),
                              filled: true,
                              fillColor: AppColors.surfaceWhite,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.searchBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.searchBorder,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.secondaryTeal,
                                  width: 1.4,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 130,
                          child: DropdownButtonFormField<String>(
                            initialValue: _appliesTo,
                            isExpanded: true,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                              color: AppColors.textHeading,
                            ),
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.textMuted,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.surfaceWhite,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.searchBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.searchBorder,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.secondaryTeal,
                                  width: 1.4,
                                ),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'general',
                                child: Text('Anything'),
                              ),
                              DropdownMenuItem(
                                value: 'staff',
                                child: Text('Staff'),
                              ),
                              DropdownMenuItem(
                                value: 'client',
                                child: Text('Residents'),
                              ),
                              DropdownMenuItem(
                                value: 'residence',
                                child: Text('Residences'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _appliesTo = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: _busy ? null : _add,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryNavy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _busy ? 'Adding…' : 'Add type',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _error!,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          color: AppColors.criticalRed,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.cardBorder),
              Expanded(
                child: Obx(() {
                  final types = widget.controller.types.toList();
                  if (types.isEmpty) {
                    return const Center(
                      child: Text(
                        'No document types yet.',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: AppColors.textMuted,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: types.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: AppColors.cardBorder),
                    itemBuilder: (context, index) {
                      final type = types[index];
                      return ListTile(
                        title: Text(
                          type.name,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                            color: type.isActive
                                ? AppColors.textHeading
                                : AppColors.textMuted,
                          ),
                        ),
                        subtitle: Text(
                          type.subtitle,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                        trailing: TextButton(
                          onPressed: () => type.isActive
                              ? _archive(type)
                              : _restore(type),
                          child: Text(
                            type.isActive ? 'Archive' : 'Restore',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w700,
                              color: type.isActive
                                  ? AppColors.criticalRed
                                  : AppColors.secondaryTeal,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
              ColoredBox(
                color: AppColors.surfaceWhite,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryNavy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
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
