import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_document.dart';
import '../controllers/staff_documents_controller.dart';

InputDecoration _docFieldDecoration({String? hint, String? helper}) {
  const radius = 12.0;
  return InputDecoration(
    hintText: hint,
    helperText: helper,
    helperStyle: const TextStyle(
      fontFamily: 'Outfit',
      fontWeight: FontWeight.w400,
      fontSize: 11.5,
      color: AppColors.textMuted,
    ),
    hintStyle: const TextStyle(
      fontFamily: 'Outfit',
      fontWeight: FontWeight.w400,
      fontSize: 14,
      color: AppColors.textMuted,
    ),
    filled: true,
    fillColor: AppColors.surfaceWhite,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: const BorderSide(color: AppColors.searchBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: const BorderSide(color: AppColors.searchBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: const BorderSide(color: AppColors.secondaryTeal, width: 1.4),
    ),
  );
}

const _fieldTextStyle = TextStyle(
  fontFamily: 'Outfit',
  fontWeight: FontWeight.w500,
  fontSize: 14,
  color: AppColors.textHeading,
);

Future<void> showStaffUploadDocumentSheet(
  BuildContext context,
  StaffDocumentsController controller,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _UploadSheet(controller: controller),
  );
}

class _UploadSheet extends StatefulWidget {
  final StaffDocumentsController controller;

  const _UploadSheet({required this.controller});

  @override
  State<_UploadSheet> createState() => _UploadSheetState();
}

class _UploadSheetState extends State<_UploadSheet> {
  final _name = TextEditingController();
  final _notes = TextEditingController();
  String _ownerType = 'client';
  String? _ownerId;
  String? _documentTypeId;
  String _visibility = 'staff_only';
  bool _expiryTracking = false;
  DateTime? _expiryDate;
  String? _filePath;
  String? _fileName;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  List<StaffDocumentOwnerOption> get _owners {
    switch (_ownerType) {
      case 'staff':
        return widget.controller.staff.toList();
      case 'residence':
        return widget.controller.residences.toList();
      case 'client':
      default:
        return widget.controller.clients.toList();
    }
  }

  List<StaffDocumentType> get _categories {
    return widget.controller.activeTypes
        .where(
          (t) => t.appliesTo == 'general' || t.appliesTo == _ownerType,
        )
        .toList();
  }

  Future<void> _pickFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'csv',
        'jpg',
        'jpeg',
        'png',
      ],
    );
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    if (file.path == null) return;
    setState(() {
      _filePath = file.path;
      _fileName = file.name;
      _error = null;
    });
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give the document a name');
      return;
    }
    if (_ownerType != 'tenant' && (_ownerId == null || _ownerId!.isEmpty)) {
      setState(() => _error = 'Choose who this document belongs to');
      return;
    }
    if (_filePath == null) {
      setState(() => _error = 'Attach the file being filed');
      return;
    }
    if (_expiryTracking && _expiryDate == null) {
      setState(
        () => _error =
            'Set the date it expires, or turn expiry tracking off',
      );
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final result = await widget.controller.uploadDocument(
      name: name,
      ownerType: _ownerType,
      ownerId: _ownerType == 'tenant' ? null : _ownerId,
      documentTypeId: _documentTypeId,
      localPath: _filePath!,
      fileName: _fileName ?? 'document',
      visibility: _visibility,
      expiresAt: _expiryTracking ? _expiryDate : null,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);
    result.when(
      success: (_) {
        Navigator.pop(context);
        Get.snackbar('Uploaded', 'Document filed successfully.');
      },
      failure: (e) => setState(() => _error = e.message),
    );
  }

  String get _ownerLabel {
    if (_ownerType == 'tenant') return 'Organisation';
    final id = _ownerId;
    if (id == null) return '—';
    for (final o in _owners) {
      if (o.id == id) return o.label;
    }
    return '—';
  }

  String get _categoryLabel {
    final id = _documentTypeId;
    if (id == null || id.isEmpty) return 'Unclassified';
    for (final t in _categories) {
      if (t.id == id) return t.name;
    }
    return 'Unclassified';
  }

  String get _visibilityLabel {
    switch (_visibility) {
      case 'staff_only':
        return 'Staff only';
      case 'management_only':
        return 'Management only';
      case 'family':
        return 'Family';
      default:
        return 'Everyone';
    }
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
          height: MediaQuery.sizeOf(context).height * 0.92,
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
                              color: AppColors.activeBackground,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.upload_file_rounded,
                              color: AppColors.activeGreen,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Add New Document',
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
                                  'Upload a file, file it against its owner, and set who may read it.',
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
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  children: [
                    _Labeled(
                      label: 'Document Name',
                      required: true,
                      child: TextField(
                        controller: _name,
                        style: _fieldTextStyle,
                        decoration: _docFieldDecoration(
                          hint: 'e.g. Care plan review – Q3 2026',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _Labeled(
                      label: 'Owner Type',
                      required: true,
                      child: DropdownButtonFormField<String>(
                        initialValue: _ownerType,
                        isExpanded: true,
                        style: _fieldTextStyle,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textMuted,
                        ),
                        decoration: _docFieldDecoration(),
                        items: const [
                          DropdownMenuItem(
                            value: 'client',
                            child: Text('Resident'),
                          ),
                          DropdownMenuItem(
                            value: 'staff',
                            child: Text('Staff'),
                          ),
                          DropdownMenuItem(
                            value: 'residence',
                            child: Text('Residence'),
                          ),
                          DropdownMenuItem(
                            value: 'tenant',
                            child: Text('Organisation'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() {
                            _ownerType = v;
                            _ownerId = null;
                            _documentTypeId = null;
                          });
                        },
                      ),
                    ),
                    if (_ownerType != 'tenant') ...[
                      const SizedBox(height: 14),
                      _Labeled(
                        label: 'Owner Record',
                        required: true,
                        child: DropdownButtonFormField<String>(
                          initialValue: _ownerId,
                          isExpanded: true,
                          style: _fieldTextStyle,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textMuted,
                          ),
                          decoration: _docFieldDecoration(
                            hint: _owners.isEmpty
                                ? 'None in your access'
                                : 'Select an owner',
                          ),
                          items: [
                            for (final o in _owners)
                              DropdownMenuItem(
                                value: o.id,
                                child: Text(o.label),
                              ),
                          ],
                          onChanged: (v) => setState(() => _ownerId = v),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _Labeled(
                      label: 'Category',
                      hint: 'Document types are managed from the registry',
                      child: DropdownButtonFormField<String>(
                        initialValue: _documentTypeId ?? '',
                        isExpanded: true,
                        style: _fieldTextStyle,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textMuted,
                        ),
                        decoration: _docFieldDecoration(),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('Unclassified'),
                          ),
                          for (final t in _categories)
                            DropdownMenuItem(
                              value: t.id,
                              child: Text(t.name),
                            ),
                        ],
                        onChanged: (v) => setState(
                          () => _documentTypeId =
                              (v == null || v.isEmpty) ? null : v,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _Labeled(
                      label: 'Upload File',
                      required: true,
                      child: _UploadZone(
                        fileName: _fileName,
                        onTap: _pickFile,
                        onClear: () => setState(() {
                          _filePath = null;
                          _fileName = null;
                        }),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Fmt('PDF'),
                        _Fmt('DOCX'),
                        _Fmt('XLSX'),
                        _Fmt('CSV'),
                        _Fmt('JPG'),
                        _Fmt('PNG'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _Labeled(
                      label: 'Visible to',
                      required: true,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.filterButtonBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            for (final opt in const [
                              ('all', 'Everyone'),
                              ('staff_only', 'Staff only'),
                              ('management_only', 'Management only'),
                              ('family', 'Family'),
                            ])
                              _VisibilityChip(
                                label: opt.$2,
                                selected: _visibility == opt.$1,
                                onTap: () =>
                                    setState(() => _visibility = opt.$1),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.searchBorder),
                      ),
                      child: SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Expiry Tracking',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textHeading,
                          ),
                        ),
                        subtitle: const Text(
                          'Counts towards the expiring and expired figures',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        value: _expiryTracking,
                        activeThumbColor: AppColors.secondaryTeal,
                        activeTrackColor: AppColors.quickActionCreateShiftBg,
                        onChanged: (v) => setState(() {
                          _expiryTracking = v;
                          if (!v) _expiryDate = null;
                        }),
                      ),
                    ),
                    if (_expiryTracking) ...[
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _expiryDate ?? now,
                            firstDate: now,
                            lastDate: DateTime(now.year + 20),
                          );
                          if (picked != null) {
                            setState(() => _expiryDate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: _docFieldDecoration(
                            hint: 'Pick expiry date',
                          ).copyWith(
                            prefixIcon: const Icon(
                              Icons.event_outlined,
                              color: AppColors.secondaryTeal,
                            ),
                          ),
                          child: Text(
                            _expiryDate == null
                                ? 'Pick expiry date'
                                : '${_expiryDate!.day.toString().padLeft(2, '0')}/'
                                    '${_expiryDate!.month.toString().padLeft(2, '0')}/'
                                    '${_expiryDate!.year}',
                            style: _expiryDate == null
                                ? const TextStyle(
                                    fontFamily: 'Outfit',
                                    color: AppColors.textMuted,
                                  )
                                : _fieldTextStyle,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _Labeled(
                      label: 'Notes (optional)',
                      child: TextField(
                        controller: _notes,
                        maxLines: 3,
                        style: _fieldTextStyle,
                        decoration: _docFieldDecoration(
                          hint:
                              'Anything a reader should know about this document...',
                        ).copyWith(
                          contentPadding: const EdgeInsets.all(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _LivePreview(
                      name: _name.text.trim(),
                      fileName: _fileName,
                      ownerLabel: _ownerLabel,
                      categoryLabel: _categoryLabel,
                      visibilityLabel: _visibilityLabel,
                      expiryLabel: !_expiryTracking
                          ? 'Not tracked'
                          : (_expiryDate == null
                              ? '—'
                              : '${_expiryDate!.day.toString().padLeft(2, '0')}/'
                                  '${_expiryDate!.month.toString().padLeft(2, '0')}/'
                                  '${_expiryDate!.year}'),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.criticalBackgroundSoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.criticalRed.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: AppColors.criticalRed,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ColoredBox(
                color: AppColors.surfaceWhite,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _submitting
                                ? null
                                : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.secondaryTeal,
                              side: const BorderSide(
                                color: AppColors.secondaryTeal,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: _submitting ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryNavy,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: _submitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.upload_rounded, size: 18),
                            label: Text(
                              _submitting ? 'Saving…' : 'Upload Document',
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
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

class _Labeled extends StatelessWidget {
  final String label;
  final String? hint;
  final bool required;
  final Widget child;

  const _Labeled({
    required this.label,
    required this.child,
    this.hint,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: label,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textHeading,
                ),
              ),
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.criticalRed,
                  ),
                ),
            ],
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 2),
          Text(
            hint!,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11.5,
              color: AppColors.textMuted,
            ),
          ),
        ],
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _UploadZone extends StatelessWidget {
  final String? fileName;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _UploadZone({
    required this.fileName,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.searchBorder,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.quickActionCreateShiftBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.cloud_upload_outlined,
                size: 24,
                color: AppColors.secondaryTeal,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              fileName ?? 'Click to upload or drag & drop',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textHeading,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'PDF, Word, Excel, CSV or an image — up to 15MB',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.5,
                color: AppColors.textMuted,
              ),
            ),
            if (fileName != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onClear,
                child: const Text(
                  'Remove',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTeal,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VisibilityChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _VisibilityChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryNavy : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12.5,
              color: selected ? Colors.white : AppColors.textHeading,
            ),
          ),
        ),
      ),
    );
  }
}

class _Fmt extends StatelessWidget {
  final String label;
  const _Fmt(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.filterButtonBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _LivePreview extends StatelessWidget {
  final String name;
  final String? fileName;
  final String ownerLabel;
  final String categoryLabel;
  final String visibilityLabel;
  final String expiryLabel;

  const _LivePreview({
    required this.name,
    required this.fileName,
    required this.ownerLabel,
    required this.categoryLabel,
    required this.visibilityLabel,
    required this.expiryLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.visibility_outlined,
                size: 16,
                color: AppColors.secondaryTeal,
              ),
              SizedBox(width: 6),
              Text(
                'Live preview',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.textHeading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryNavy,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Document',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name.isEmpty ? 'Not named yet' : name,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PreviewRow('File', fileName ?? '—'),
          _PreviewRow('Owner', ownerLabel),
          _PreviewRow('Category', categoryLabel),
          _PreviewRow('Visible to', visibilityLabel),
          _PreviewRow('Expiry', expiryLabel),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;
  const _PreviewRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 84,
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
                fontSize: 12.5,
                color: AppColors.textHeading,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
