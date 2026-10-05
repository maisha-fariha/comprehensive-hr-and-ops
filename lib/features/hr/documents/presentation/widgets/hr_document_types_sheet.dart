import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/hr_document.dart';
import '../../domain/entities/hr_document_row.dart';
import '../controllers/hr_documents_controller.dart';
import 'hr_documents_common.dart';

/// The web "Document types" modal: add a type, archive or restore one.
class HrDocumentTypesSheet extends StatefulWidget {
  final HrDocumentsController controller;

  const HrDocumentTypesSheet({super.key, required this.controller});

  @override
  State<HrDocumentTypesSheet> createState() => _HrDocumentTypesSheetState();
}

class _HrDocumentTypesSheetState extends State<HrDocumentTypesSheet> {
  final TextEditingController _name = TextEditingController();
  String _appliesTo = 'general';
  bool _adding = false;
  String? _error;
  List<HrDocumentType> _types = const [];
  String? _busyId;

  HrDocumentsController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await _c.repository.types(includeArchived: true);
    if (!mounted) return;
    result.when(success: (types) => setState(() => _types = types), failure: (_) {});
  }

  Future<void> _changed() async {
    await _load();
    _c.typesChanged();
  }

  Future<void> _add() async {
    setState(() => _error = null);
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give the type a name.');
      return;
    }
    setState(() => _adding = true);
    final result = await _c.repository.createType(name: name, appliesTo: _appliesTo);
    if (!mounted) return;
    setState(() => _adding = false);
    result.when(
      success: (_) {
        AppSnackbar.show('Document type added', '');
        _name.clear();
        _changed();
      },
      failure: (error) => setState(() => _error = error.message),
    );
  }

  Future<void> _toggle(HrDocumentType type) async {
    setState(() => _busyId = type.id);
    final result = type.isActive
        ? await _c.repository.archiveType(type.id)
        : await _c.repository.restoreType(type.id);
    if (!mounted) return;
    setState(() => _busyId = null);
    result.when(
      success: (_) {
        AppSnackbar.show(type.isActive ? 'Type archived' : 'Type restored', '');
        _changed();
      },
      failure: (error) => AppSnackbar.show(error.message, ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HrSheetFrame(
      key: const ValueKey('document-types'),
      icon: Icons.sell_outlined,
      title: 'Document types',
      description: 'What a document can be filed as. Retired types are archived, never deleted.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.criticalBackgroundSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _error!,
                style: handoverText(context, 13.5, color: AppColors.criticalRed),
              ),
            ),
            const SizedBox(height: 14),
          ],
          HandoverPanel(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KeyedSubtree(
                  key: const ValueKey('document-type-name'),
                  child: HandoverTextArea(
                    label: 'New type',
                    minLines: 1,
                    controller: _name,
                    placeholder: 'e.g. DBS certificate',
                  ),
                ),
                const SizedBox(height: 12),
                HandoverSelect(
                  key: const ValueKey('document-type-applies-to'),
                  label: 'Applies to',
                  value: HrDocumentOptions.appliesToLabel(_appliesTo),
                  placeholder: 'Anything',
                  onTap: () async {
                    final picked = await pickHandoverOption(
                      context,
                      title: 'Applies to',
                      options: HrDocumentOptions.typeAppliesTo,
                      selected: _appliesTo,
                    );
                    if (picked != null) setState(() => _appliesTo = picked);
                  },
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: HandoverButton(
                    key: const ValueKey('document-type-add'),
                    label: _adding ? 'Adding…' : 'Add type',
                    filled: true,
                    compact: true,
                    onPressed: _adding ? null : _add,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final type in _types) ...[
            Container(
              key: ValueKey('document-type-${type.id}'),
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(type.name, style: handoverText(context, 14, weight: FontWeight.w600)),
                        Text(
                          '${HrDocumentOptions.appliesToLabel(type.appliesTo)}'
                          '${type.isMandatory ? ' · Required' : ''}'
                          '${type.isActive ? '' : ' · Archived'}',
                          style: handoverText(context, 12.5, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  HandoverButton(
                    key: ValueKey('document-type-toggle-${type.id}'),
                    label: type.isActive ? 'Archive' : 'Restore',
                    compact: true,
                    foreground: type.isActive ? AppColors.criticalRed : null,
                    onPressed: _busyId == type.id ? null : () => _toggle(type),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (_types.isEmpty)
            Text(
              'No document types yet. Documents can still be filed without one.',
              style: handoverText(context, 13, color: AppColors.textMuted),
            ),
        ],
      ),
      footer: [
        HandoverButton(
          key: const ValueKey('document-types-done'),
          label: 'Done',
          filled: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

/// The web "Missing required documents" modal.
class HrMissingDocumentsSheet extends StatelessWidget {
  final List<HrMissingGap> rows;

  const HrMissingDocumentsSheet({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    return HrSheetFrame(
      key: const ValueKey('documents-missing'),
      icon: Icons.report_problem_outlined,
      iconBackground: AppColors.urgentAmber,
      title: 'Missing required documents',
      description: 'Mandatory document types, and how many people have yet to file one.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final gap in rows) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
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
                          gap.name,
                          overflow: TextOverflow.ellipsis,
                          style: handoverText(context, 13.5, weight: FontWeight.w600),
                        ),
                        Text(
                          '${gap.filed} of ${gap.owners} '
                          '${gap.appliesTo == 'client' ? 'residents' : 'staff'} have filed one',
                          style: handoverText(context, 12.5, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  HrDocPill(
                    label: '${gap.missing} missing',
                    foreground: AppColors.urgentAmber,
                    background: AppColors.urgentBackground,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (rows.isEmpty)
            Text(
              'Every mandatory document type has been filed by everyone it applies to.',
              style: handoverText(context, 13, color: AppColors.textMuted),
            ),
        ],
      ),
      footer: [
        HandoverButton(
          key: const ValueKey('documents-missing-done'),
          label: 'Done',
          filled: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
