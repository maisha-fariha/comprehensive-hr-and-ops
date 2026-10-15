import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/media/app_file_picker.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../../core/widgets/searchable_option_list.dart';
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
    final noteLabel = _category == 'resident_memory'
        ? 'Caption (Optional)'
        : 'Note for the care home (Optional)';
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Send a Document or Photo',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: AppColors.textHeading,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'A signed consent form, or a family photo or memory for your relative.',
                  style: TextStyle(fontFamily: 'Manrope', fontSize: 12.5, color: AppColors.textSecondary),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.criticalRed, fontSize: 13)),
                ],
                if (_loadingPeople)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  if (_residents.length > 1) ...[
                    const SizedBox(height: 16),
                    const Text('Resident', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    OutlinedButton(
                      onPressed: _busy ? null : _pickResident,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(residentName ?? 'Choose a resident'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Text('Document Title *', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _name,
                    enabled: !_busy,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Signed Medical Power of Attorney',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('What is it?', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    items: [
                      for (final option in _categories)
                        DropdownMenuItem(value: option.$1, child: Text(option.$2)),
                    ],
                    onChanged: _busy
                        ? null
                        : (value) => setState(() => _category = value ?? 'consent_form'),
                  ),
                  const SizedBox(height: 12),
                  const Text('Attached File *', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  OutlinedButton(
                    onPressed: _busy ? null : _pickFile,
                    child: Text(
                      _file?.name ??
                          (_category == 'resident_memory'
                              ? 'A photo: PNG, JPEG or WebP'
                              : 'PDF, Word, PNG or JPEG'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(noteLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _notes,
                    enabled: !_busy,
                    decoration: InputDecoration(
                      hintText: _category == 'resident_memory'
                          ? 'e.g. Mum at the seaside, summer 1982'
                          : 'Anything the care home should know about this form',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _busy ? null : () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: Text(_busy ? 'Sending...' : 'Send to the care home'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
