import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/formatting/web_formats.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/hr_document.dart';
import '../../domain/entities/hr_document_draft.dart';
import '../../domain/entities/hr_document_row.dart';
import '../controllers/hr_documents_controller.dart';
import 'hr_documents_common.dart';

Future<void> showHrDocumentFormSheet(
  BuildContext context, {
  required HrDocumentsController controller,
  HrDocumentRow? editing,
}) =>
    showHrSheet<void>(
      context,
      (_) => HrDocumentFormSheet(controller: controller, editing: editing),
    );

/// The web "Add New Document" / "Edit Document" modal and its saved view.
class HrDocumentFormSheet extends StatefulWidget {
  final HrDocumentsController controller;
  final HrDocumentRow? editing;

  const HrDocumentFormSheet({super.key, required this.controller, this.editing});

  @override
  State<HrDocumentFormSheet> createState() => _HrDocumentFormSheetState();
}

class _HrDocumentFormSheetState extends State<HrDocumentFormSheet> {
  late HrDocumentDraft _draft;
  late final TextEditingController _name;
  late final TextEditingController _notes;
  bool _submitted = false;
  bool _saving = false;
  String? _saveError;
  String? _fileError;
  ({HrDocument document, HrDocumentDraft values})? _saved;

  HrDocumentsController get _c => widget.controller;
  bool get _editing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    _draft = _editing ? HrDocumentDraft.edit(widget.editing!) : const HrDocumentDraft();
    _name = TextEditingController(text: _draft.name);
    _notes = TextEditingController(text: _draft.notes);
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _update(HrDocumentDraft next) => setState(() => _draft = next);

  Map<String, String> get _errors => _submitted ? _draft.validate() : const {};

  String get _visibilityLabel =>
      HrDocumentOptions.label(HrDocumentOptions.visibilities, _draft.visibility, '');

  Future<void> _pickOwnerType() async {
    final picked = await pickHandoverOption(
      context,
      title: 'Owner Type',
      options: HrDocumentOptions.formOwnerTypes,
      selected: _draft.ownerType,
    );
    if (picked != null) {
      _update(_draft.copyWith(ownerType: picked, ownerId: '', documentTypeId: ''));
    }
  }

  Future<void> _pickOwner() async {
    final owners = _c.directoryFor(_draft.ownerType);
    final picked = await pickHandoverOption(
      context,
      title: 'Owner Record',
      options: [for (final o in owners) (o.id, o.name)],
      selected: _draft.ownerId,
    );
    if (picked != null) _update(_draft.copyWith(ownerId: picked));
  }

  Future<void> _pickCategory() async {
    final picked = await pickHandoverOption(
      context,
      title: 'Category',
      options: [for (final t in _c.categoryOptionsFor(_draft.ownerType)) (t.id, t.name)],
      selected: _draft.documentTypeId,
    );
    if (picked != null) _update(_draft.copyWith(documentTypeId: picked));
  }

  Future<void> _pickFile() async {
    final file = await _c.pickFile();
    if (file == null) return;
    if (file.size > HrDocumentOptions.maxUploadMb * 1024 * 1024) {
      setState(() => _fileError = '"${file.name}" exceeds the ${HrDocumentOptions.maxUploadMb}MB limit');
      return;
    }
    setState(() => _fileError = null);
    _update(_draft.copyWith(file: file));
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final current = DateTime.tryParse(_draft.expiryDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 20),
      lastDate: DateTime(now.year + 30),
    );
    if (picked == null) return;
    String two(int v) => v.toString().padLeft(2, '0');
    _update(_draft.copyWith(expiryDate: '${picked.year}-${two(picked.month)}-${two(picked.day)}'));
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _saveError = null;
    });
    if (_draft.validate().isNotEmpty) return;
    setState(() => _saving = true);
    final result = await _c.save(_draft, documentId: widget.editing?.id);
    if (!mounted) return;
    setState(() {
      _saving = false;
      result.when(
        success: (document) => _saved = (document: document, values: _draft),
        failure: (error) => _saveError = error.message,
      );
    });
  }

  void _fileAnother() {
    final ownerType = _draft.ownerType;
    _name.clear();
    _notes.clear();
    setState(() {
      _saved = null;
      _submitted = false;
      _saveError = null;
      _fileError = null;
      _draft = HrDocumentDraft(ownerType: ownerType);
    });
  }

  @override
  Widget build(BuildContext context) {
    final saved = _saved;
    return saved == null ? _form(context) : _success(context, saved);
  }

  Widget _success(BuildContext context, ({HrDocument document, HrDocumentDraft values}) saved) {
    final values = saved.values;
    final owner = _c.ownerLabelOf(values);
    final visibility =
        HrDocumentOptions.label(HrDocumentOptions.visibilities, values.visibility, values.visibility);
    final category = _c.categoryLabelOf(values);
    final fileUrl = saved.document.fileUrl;
    return HrSheetFrame(
      key: const ValueKey('document-form-saved'),
      icon: Icons.check_circle_outline_rounded,
      iconBackground: AppColors.successGreen,
      title: _editing ? 'Document Updated' : 'Document Filed',
      badges: const [
        HrDocPill(
          label: 'Saved',
          foreground: AppColors.activeGreen,
          background: AppColors.activeBackground,
        ),
      ],
      description: '"${saved.document.name}" is on file'
          '${owner.isEmpty ? '' : ' against $owner'} and readable by ${visibility.toLowerCase()}.',
      body: HandoverPanel(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          children: [
            HrFactRow(label: 'Document', value: saved.document.name),
            HrFactRow(label: 'Owner', value: owner.isEmpty ? '—' : owner),
            HrFactRow(label: 'Category', value: category.isEmpty ? 'Unclassified' : category),
            HrFactRow(label: 'Visible to', value: visibility),
            HrFactRow(
              label: 'Expiry Date',
              value: values.expiryTrackingEnabled
                  ? (values.expiryDate.isEmpty ? '—' : values.expiryDate)
                  : 'Not tracked',
            ),
          ],
        ),
      ),
      footer: [
        if (fileUrl != null)
          HandoverButton(
            key: const ValueKey('document-saved-download'),
            label: 'Download',
            icon: Icons.download_rounded,
            onPressed: () => _c.download(fileUrl, saved.document.name),
          ),
        if (!_editing)
          HandoverButton(
            key: const ValueKey('document-file-another'),
            label: 'File Another',
            onPressed: _fileAnother,
          ),
        HandoverButton(
          key: const ValueKey('document-saved-done'),
          label: 'Done',
          filled: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _form(BuildContext context) {
    final errors = _errors;
    final ownerLabel = _c.ownerLabelOf(_draft);
    final owners = _c.directoryFor(_draft.ownerType);
    final category = _c.categoryLabelOf(_draft);
    final count = errors.length;

    Widget error(String key) => errors[key] == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              errors[key]!,
              style: handoverText(context, 12, color: AppColors.criticalRed),
            ),
          );

    Widget box(List<Widget> children) => HandoverPanel(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        );

    return HrSheetFrame(
      key: const ValueKey('document-form'),
      icon: Icons.upload_rounded,
      title: _editing ? 'Edit Document' : 'Add New Document',
      description: _editing
          ? 'The owner is fixed once filed — file it again to move it.'
          : 'Upload a file, file it against its owner, and set who may read it.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if ((_submitted && count > 0) || _saveError != null) ...[
            Container(
              key: const ValueKey('document-form-alert'),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.criticalBackgroundSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.criticalRed.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.criticalRed),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _saveError != null
                              ? 'This document could not be filed'
                              : '$count field${count == 1 ? '' : 's'} need attention',
                          style: handoverText(context, 13, weight: FontWeight.w700, color: AppColors.criticalRed),
                        ),
                        Text(
                          _saveError ?? 'Complete the required fields below before filing this document.',
                          style: handoverText(context, 12, color: AppColors.criticalRed),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          box([
            KeyedSubtree(
              key: const ValueKey('document-form-name'),
              child: HandoverTextArea(
                label: 'Document Name',
                required: true,
                minLines: 1,
                controller: _name,
                placeholder: 'e.g. Care plan review — Q3 2026',
                onChanged: (v) => _update(_draft.copyWith(name: v)),
              ),
            ),
            error('name'),
            const SizedBox(height: 14),
            HandoverSelect(
              key: const ValueKey('document-form-owner-type'),
              label: 'Owner Type',
              required: true,
              value: HrDocumentOptions.label(HrDocumentOptions.ownerTypes, _draft.ownerType, ''),
              placeholder: 'Select owner type',
              helper: _editing ? 'Fixed once the document is filed' : null,
              onTap: _editing ? null : _pickOwnerType,
            ),
            const SizedBox(height: 14),
            if (_editing)
              HandoverSelect(
                key: const ValueKey('document-form-owner'),
                label: 'Owner Record',
                value: ownerLabel.isEmpty ? '—' : ownerLabel,
                placeholder: '—',
              )
            else if (_draft.isTenant)
              Column(
                key: const ValueKey('document-form-owner'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Owner Record', style: handoverText(context, 13, weight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.searchBorder),
                    ),
                    child: Text(
                      'Held by the organisation itself — no record to choose.',
                      style: handoverText(context, 13.5, color: AppColors.textMuted),
                    ),
                  ),
                ],
              )
            else ...[
              HandoverSelect(
                key: const ValueKey('document-form-owner'),
                label: 'Owner Record',
                required: true,
                value: ownerLabel,
                placeholder: owners.isEmpty ? 'None in your access' : 'Select an owner',
                onTap: _pickOwner,
              ),
              error('ownerId'),
            ],
            const SizedBox(height: 14),
            HandoverSelect(
              key: const ValueKey('document-form-category'),
              label: 'Category',
              value: category,
              placeholder: 'Unclassified',
              helper: 'Document types are managed from the registry',
              onTap: _pickCategory,
            ),
          ]),
          if (!_editing) ...[
            const SizedBox(height: 14),
            _uploadField(context),
            error('files'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final format in HrDocumentOptions.fileFormats)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.filterButtonBackground,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.description_outlined, size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          format,
                          style: handoverText(context, 11, weight: FontWeight.w600, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          box([
            Text.rich(
              const TextSpan(
                text: 'Visible to',
                children: [TextSpan(text: ' *', style: TextStyle(color: AppColors.criticalRed))],
              ),
              style: handoverText(context, 13, weight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.filterButtonBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.searchBorder),
              ),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final (value, label) in HrDocumentOptions.visibilities)
                    Material(
                      color: _draft.visibility == value ? AppColors.primaryNavy : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        key: ValueKey('document-form-visibility-$value'),
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _update(_draft.copyWith(visibility: value)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          child: Text(
                            label,
                            style: handoverText(
                              context,
                              13,
                              weight: FontWeight.w500,
                              color: _draft.visibility == value
                                  ? AppColors.surfaceWhite
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.searchBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Expiry Tracking', style: handoverText(context, 13.5, weight: FontWeight.w600)),
                        Text(
                          'Counts towards the expiring and expired figures',
                          style: handoverText(context, 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    key: const ValueKey('document-form-expiry-toggle'),
                    value: _draft.expiryTrackingEnabled,
                    activeThumbColor: AppColors.surfaceWhite,
                    activeTrackColor: AppColors.secondaryTeal,
                    onChanged: (v) => _update(_draft.copyWith(expiryTrackingEnabled: v)),
                  ),
                ],
              ),
            ),
            if (_draft.expiryTrackingEnabled) ...[
              const SizedBox(height: 14),
              HandoverSelect(
                key: const ValueKey('document-form-expiry-date'),
                label: 'Expiry Date',
                required: true,
                value: _draft.expiryDate.isEmpty
                    ? null
                    : WebFormat.date(DateTime.tryParse(_draft.expiryDate)),
                placeholder: 'Pick a date',
                onTap: _pickExpiry,
              ),
              error('expiryDate'),
            ],
          ]),
          const SizedBox(height: 14),
          KeyedSubtree(
            key: const ValueKey('document-form-notes'),
            child: HandoverTextArea(
              label: 'Notes (optional)',
              controller: _notes,
              minLines: 3,
              placeholder: 'Anything a reader should know about this document...',
              onChanged: (v) => _update(_draft.copyWith(notes: v)),
            ),
          ),
          const SizedBox(height: 18),
          _preview(context, ownerLabel, category),
        ],
      ),
      footer: [
        HandoverButton(
          key: const ValueKey('document-form-cancel'),
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        HandoverButton(
          key: const ValueKey('document-form-submit'),
          label: _saving ? 'Saving…' : (_editing ? 'Save Changes' : 'Upload Document'),
          icon: Icons.upload_rounded,
          filled: true,
          onPressed: _saving ? null : _submit,
        ),
      ],
    );
  }

  Widget _uploadField(BuildContext context) {
    final file = _draft.file;
    final error = _fileError;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          const TextSpan(
            text: 'Upload File',
            children: [TextSpan(text: ' *', style: TextStyle(color: AppColors.criticalRed))],
          ),
          style: handoverText(context, 13, weight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        InkWell(
          key: const ValueKey('document-form-file'),
          onTap: _pickFile,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: error != null ? AppColors.criticalRed : AppColors.searchBorder,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.quickActionCreateShiftBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.cloud_upload_outlined, color: AppColors.secondaryTeal),
                ),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    text: 'Click to upload ',
                    children: [
                      TextSpan(
                        text: 'or drag & drop',
                        style: handoverText(context, 14, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  style: handoverText(context, 14, weight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'PDF, Word, Excel, CSV or an image · up to ${HrDocumentOptions.maxUploadMb}MB',
                  textAlign: TextAlign.center,
                  style: handoverText(context, 11.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(error, style: handoverText(context, 12, color: AppColors.criticalRed)),
          ),
        if (file != null)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.searchBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.description_outlined, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(file.name, overflow: TextOverflow.ellipsis, style: handoverText(context, 13)),
                ),
                IconButton(
                  key: const ValueKey('document-form-file-remove'),
                  tooltip: 'Remove ${file.name}',
                  icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                  onPressed: () => _update(_draft.copyWith(clearFile: true)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _preview(BuildContext context, String ownerLabel, String category) {
    final fileName = _draft.file?.name;
    final name = _draft.name.trim();
    return Column(
      key: const ValueKey('document-form-preview'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const HrIconTile(
              icon: Icons.insert_drive_file_outlined,
              foreground: AppColors.secondaryTeal,
              background: AppColors.quickActionCreateShiftBg,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Document Preview', style: handoverText(context, 14, weight: FontWeight.w700)),
                Text('Live preview', style: handoverText(context, 11.5, color: AppColors.navInactive)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: AppColors.primaryNavy,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Document', style: handoverText(context, 13, color: AppColors.whiteOpacity70)),
                    Text(
                      name.isNotEmpty ? name : (fileName ?? 'Not named yet'),
                      overflow: TextOverflow.ellipsis,
                      style: handoverText(context, 14, weight: FontWeight.w600, color: AppColors.surfaceWhite),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: [
                    HrFactRow(label: 'File', value: fileName ?? (_editing ? 'Already filed' : '')),
                    HrFactRow(label: 'Owner', value: ownerLabel),
                    HrFactRow(label: 'Category', value: category.isEmpty ? 'Unclassified' : category),
                    HrFactRow(label: 'Visible to', value: _visibilityLabel),
                    HrFactRow(
                      label: 'Expiry',
                      value: _draft.expiryTrackingEnabled ? _draft.expiryDate : 'Not tracked',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, size: 13, color: AppColors.urgentAmber),
                  const SizedBox(width: 6),
                  Text('Upload Tips', style: handoverText(context, 12, weight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 8),
              for (final tip in HrDocumentOptions.uploadTips)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.check_circle_outline_rounded, size: 12, color: AppColors.activeGreen),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(tip, style: handoverText(context, 11.5, color: AppColors.textMuted)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
