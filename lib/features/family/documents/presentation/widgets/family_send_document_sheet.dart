import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/media/app_file_picker.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../../core/widgets/searchable_option_list.dart';
import '../../../appointments/presentation/widgets/appointment_form_fields.dart';
import '../../domain/repositories/family_documents_repository.dart';

Future<bool?> showFamilySendDocumentSheet({
  required BuildContext context,
  required FamilyDocumentsRepository repository,
}) {
  return showAppBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceWhite,
    builder: (context) => _SendDocumentSheet(repository: repository),
  );
}

class _SendDocumentSheet extends StatefulWidget {
  final FamilyDocumentsRepository repository;

  const _SendDocumentSheet({required this.repository});

  @override
  State<_SendDocumentSheet> createState() => _SendDocumentSheetState();
}

class _SendDocumentSheetState extends State<_SendDocumentSheet> {
  static const _categories = [
    ('consent_form', 'Signed consent form'),
    ('resident_memory', 'Family photo or memory'),
  ];

  final _name = TextEditingController();
  final _notes = TextEditingController();
  List<FamilyDocumentResident> _residents = const [];
  String? _clientId;
  String _category = 'consent_form';
  PlatformFile? _file;
  bool _loadingPeople = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPeople();
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _loadPeople() async {
    final result = await widget.repository.linkedResidents();
    if (!mounted) return;
    result.when(
      success: (people) => setState(() {
        _residents = people;
        _clientId = people.length == 1 ? people.first.id : null;
        _loadingPeople = false;
      }),
      failure: (error) => setState(() {
        _error = error.message;
        _loadingPeople = false;
      }),
    );
  }

  Future<void> _pickCategory() async {
    final picked = await _pickOption(
      title: 'What is it?',
      options: _categories,
      selected: _category,
    );
    if (picked != null) setState(() => _category = picked);
  }

  Future<String?> _pickOption({
    required String title,
    required List<(String, String)> options,
    required String selected,
  }) {
    return showAppBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.surfaceWhite,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textHeading,
                  ),
                ),
              ),
            ),
            for (final option in options)
              ListTile(
                title: Text(
                  option.$2,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textHeading,
                  ),
                ),
                trailing: option.$1 == selected
                    ? const Icon(Icons.check_rounded, color: AppColors.secondaryTeal)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(option.$1),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickResident() async {
    final picked = await showAppBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: AppColors.surfaceWhite,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
          child: SearchableOptionList<FamilyDocumentResident>(
            title: 'Resident',
            searchHint: 'Search resident',
            options: _residents,
            labelOf: (person) => person.name,
            idOf: (person) => person.id,
            selectedId: _clientId,
            onSelected: (person) => Navigator.of(context).pop(person.id),
          ),
        ),
      ),
    );
    if (picked != null) setState(() => _clientId = picked);
  }

  Future<void> _pickFile() async {
    final images = _category == 'resident_memory';
    final picked = await AppFilePicker.pickFiles(
      context: context,
      type: images ? FileType.image : FileType.custom,
      allowedExtensions: images ? null : const ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
    );
    final file = picked?.files.where((item) => item.path != null).firstOrNull;
    if (file == null || !mounted) return;
    setState(() {
      _file = file;
      if (_name.text.trim().isEmpty) {
        final dot = file.name.lastIndexOf('.');
        _name.text = dot > 0 ? file.name.substring(0, dot) : file.name;
      }
    });
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please provide a name for this document.');
      return;
    }
    final path = _file?.path;
    if (path == null) {
      setState(() => _error = 'Please select a file to upload.');
      return;
    }
    final clientId = _clientId;
    if (clientId == null || clientId.isEmpty) {
      setState(() => _error = 'Choose the resident this is for.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await widget.repository.sendDocument(
      clientId: clientId,
      name: name,
      category: _category,
      localPath: path,
      fileName: _file!.name,
      notes: _notes.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      success: (_) {
        AppSnackbar.show(
          _category == 'resident_memory'
              ? 'Shared with the care team. It will appear in your relative\'s activities.'
              : 'Sent to the care home and filed on your relative\'s record.',
          '',
          force: true,
        );
        Navigator.of(context).pop(true);
      },
      failure: (error) => setState(() => _error = error.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final residentName = _residents
        .where((person) => person.id == _clientId)
        .map((person) => person.name)
        .firstOrNull;
    final categoryLabel = _categories
        .where((option) => option.$1 == _category)
        .map((option) => option.$2)
        .firstOrNull;
    final noteLabel = _category == 'resident_memory'
        ? 'Caption (Optional)'
        : 'Note for the care home (Optional)';
    final gap = SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16));
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
          child: SingleChildScrollView(
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: 20,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: ResponsiveHelper.getResponsiveSize(context, 44),
                      height: ResponsiveHelper.getResponsiveSize(context, 44),
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy,
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getResponsiveRadius(context, 12),
                        ),
                      ),
                      child: Icon(
                        Icons.upload_file_rounded,
                        color: Colors.white,
                        size: ResponsiveHelper.getResponsiveSize(context, 22),
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Send a Document or Photo',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w800,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                              color: AppColors.primaryNavy,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
                          Text(
                            'A signed consent form, or a family photo or memory for your relative.',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w500,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                              color: AppColors.textMuted,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                gap,
                if (_error != null) ...[
                  AppointmentFormErrorBanner(message: _error!),
                  gap,
                ],
                if (_loadingPeople)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator(color: AppColors.secondaryTeal)),
                  )
                else
                  AbsorbPointer(
                    absorbing: _busy,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_residents.length > 1) ...[
                          const AppointmentFieldLabel('Resident', required: true),
                          AppointmentDropdownField(
                            value: residentName ?? 'Choose a resident',
                            isPlaceholder: residentName == null,
                            onTap: _pickResident,
                          ),
                          gap,
                        ],
                        const AppointmentFieldLabel('Document Title', required: true),
                        AppointmentTextField(
                          controller: _name,
                          hint: 'e.g. Signed Medical Power of Attorney',
                        ),
                        gap,
                        const AppointmentFieldLabel('What is it?'),
                        AppointmentDropdownField(
                          value: categoryLabel ?? 'Signed consent form',
                          onTap: _pickCategory,
                        ),
                        gap,
                        const AppointmentFieldLabel('Attached File', required: true),
                        AppointmentDropdownField(
                          value: _file?.name ??
                              (_category == 'resident_memory'
                                  ? 'A photo: PNG, JPEG or WebP'
                                  : 'PDF, Word, PNG or JPEG'),
                          isPlaceholder: _file == null,
                          trailingIcon: Icons.attach_file_rounded,
                          onTap: _pickFile,
                        ),
                        gap,
                        AppointmentFieldLabel(noteLabel),
                        AppointmentNoteField(
                          controller: _notes,
                          hint: _category == 'resident_memory'
                              ? 'e.g. Mum at the seaside, summer 1982'
                              : 'Anything the care home should know about this form',
                        ),
                        gap,
                        _SheetActions(
                          busy: _busy,
                          busyLabel: 'Sending...',
                          actionLabel: 'Send to the care home',
                          onCancel: () => Navigator.of(context).pop(false),
                          onConfirm: _submit,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetActions extends StatelessWidget {
  final bool busy;
  final String busyLabel;
  final String actionLabel;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _SheetActions({
    required this.busy,
    required this.busyLabel,
    required this.actionLabel,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 12);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: busy ? null : onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textHeading,
              side: const BorderSide(color: AppColors.searchBorder),
              backgroundColor: AppColors.surfaceWhite,
              padding: EdgeInsets.symmetric(
                vertical: ResponsiveHelper.getResponsiveHeight(context, 14),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
              ),
            ),
          ),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
        Expanded(
          child: FilledButton(
            onPressed: busy ? null : onConfirm,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              disabledBackgroundColor: AppColors.primaryNavy.withValues(alpha: 0.5),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                vertical: ResponsiveHelper.getResponsiveHeight(context, 14),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
            ),
            child: Text(
              busy ? busyLabel : actionLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
