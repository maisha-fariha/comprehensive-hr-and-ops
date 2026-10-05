import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/hr_training.dart';
import '../../domain/entities/training_form.dart';
import '../../domain/repositories/hr_training_repository.dart';
import '../training_labels.dart';
import '../widgets/training_common.dart';
import '../widgets/training_form_steps.dart';
import '../../../../../core/media/app_file_picker.dart';

typedef TrainingFilePicker = Future<TrainingMaterialFile?> Function();

Future<TrainingMaterialFile?> pickTrainingMaterial() async {
  final result = await AppFilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['mp4', 'mov', 'webm', 'pdf', 'doc', 'docx', 'ppt', 'pptx'],
  );
  final file = result?.files.firstOrNull;
  final path = file?.path;
  if (file == null || path == null) return null;
  return TrainingMaterialFile(path: path, name: file.name, size: file.size);
}

/// Opens the web "Create New Training" / "Edit Training" wizard full screen.
/// Resolves to true once saved.
Future<bool?> openTrainingForm(
  BuildContext context, {
  required bool edit,
  required TrainingFormValues initial,
  required String code,
  required HrTrainingRepository repository,
  required UserSession session,
  required Future<String?> Function(TrainingFormValues values) onSave,
  TrainingFilePicker pickFile = pickTrainingMaterial,
}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => HrTrainingFormPage(
        edit: edit,
        initial: initial,
        code: code,
        repository: repository,
        session: session,
        onSave: onSave,
        pickFile: pickFile,
      ),
    ),
  );
}

class HrTrainingFormPage extends StatefulWidget {
  final bool edit;
  final TrainingFormValues initial;
  final String code;
  final HrTrainingRepository repository;
  final UserSession session;
  final Future<String?> Function(TrainingFormValues values) onSave;
  final TrainingFilePicker pickFile;

  const HrTrainingFormPage({
    super.key,
    required this.edit,
    required this.initial,
    required this.code,
    required this.repository,
    required this.session,
    required this.onSave,
    this.pickFile = pickTrainingMaterial,
  });

  @override
  State<HrTrainingFormPage> createState() => _HrTrainingFormPageState();
}

class _HrTrainingFormPageState extends State<HrTrainingFormPage> {
  static const _steps = TrainingLabels.wizardSteps;
  static const Map<String, List<String>> _stepFields = {
    'trainingInformation': ['title', 'category', 'type', 'expiryPeriod'],
    'contentUpload': [],
    'quizSetup': [],
    'assignmentRules': ['assignTo', 'dueDate'],
    'reviewPublish': [],
  };
  static const Map<String, String> _fieldStep = {
    'title': 'trainingInformation',
    'category': 'trainingInformation',
    'customDurationValue': 'trainingInformation',
    'questions': 'quizSetup',
    'roles': 'assignmentRules',
    'residences': 'assignmentRules',
    'staffIds': 'assignmentRules',
  };

  late final TrainingFormValues _v = widget.initial;
  String _step = 'trainingInformation';
  Map<String, String> _errors = const {};
  String? _saveError;
  bool _saving = false;

  List<TrainingStaffOption> _staff = const [];
  List<TrainingOption> _categories = const [];
  List<TrainingOption> _residences = const [];

  int get _index => _steps.indexWhere((s) => s.$1 == _step);

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final session = widget.session;
    if (session.can('staff:read')) {
      final staff = await widget.repository.staff();
      if (!mounted) return;
      staff.when(success: (s) => setState(() => _staff = s), failure: (_) {});
    }
    if (session.can('staff-categories:read')) {
      final categories = await widget.repository.staffCategories();
      if (!mounted) return;
      categories.when(success: (c) => setState(() => _categories = c), failure: (_) {});
    }
    if (session.can('residences:read')) {
      final residences = await widget.repository.residences();
      if (!mounted) return;
      residences.when(success: (r) => setState(() => _residences = r), failure: (_) {});
    }
  }

  void _changed() => setState(() {
        if (_errors.isNotEmpty) {
          final now = _v.validate();
          _errors = {
            for (final e in _errors.entries)
              if (now.containsKey(e.key)) e.key: now[e.key]!,
          };
        }
      });

  bool _stepComplete(String id) {
    final fields = _stepFields[id]!;
    if (fields.isEmpty) return false;
    return fields.every((f) => switch (f) {
          'title' => _v.title.isNotEmpty,
          'category' => _v.category.isNotEmpty,
          'type' => _v.type.isNotEmpty,
          'expiryPeriod' => _v.expiryPeriod.isNotEmpty,
          'assignTo' => _v.assignTo.isNotEmpty,
          'dueDate' => _v.dueDate != null,
          _ => false,
        });
  }

  void _next() {
    final fields = _stepFields[_step]!;
    final all = _v.validate();
    final stepErrors = {
      for (final e in all.entries)
        if (fields.contains(e.key)) e.key: e.value,
    };
    setState(() => _errors = stepErrors);
    if (stepErrors.isNotEmpty) return;
    if (_index < _steps.length - 1) setState(() => _step = _steps[_index + 1].$1);
  }

  Future<void> _publish() async {
    final errors = _v.validate();
    if (errors.isNotEmpty) {
      setState(() {
        _errors = errors;
        _step = _fieldStep[errors.keys.first] ?? _step;
      });
      return;
    }
    setState(() {
      _saveError = null;
      _saving = true;
    });
    final error = await widget.onSave(_v);
    if (!mounted) return;
    setState(() => _saving = false);
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _saveError = error);
    }
  }

  int get _reach {
    final values = TrainingFormValues(
      assignTo: _v.assignTo,
      roles: _v.roles,
      residences: _v.residences,
      staffIds: _v.staffIds.where((s) => s.isNotEmpty).toList(),
    );
    return values.resolveStaffIds(_staff).length;
  }

  @override
  Widget build(BuildContext context) {
    final last = _step == 'reviewPublish';
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Column(
        children: [
          _header(context),
          _stepStrip(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                _tip(context),
                const SizedBox(height: 14),
                if (_saveError != null) ...[
                  TrainingInlineError(_saveError!),
                  const SizedBox(height: 14),
                ],
                HandoverPanel(
                  padding: const EdgeInsets.all(16),
                  child: TrainingFormStep(
                    key: ValueKey('training-step-$_step'),
                    step: _step,
                    values: _v,
                    errors: _errors,
                    staff: _staff,
                    categories: _categories,
                    residences: _residences,
                    reach: _reach,
                    pickFile: widget.pickFile,
                    onChanged: _changed,
                  ),
                ),
                const SizedBox(height: 14),
                _summary(context),
                const SizedBox(height: 14),
                _setupProgress(context),
              ],
            ),
          ),
          _footer(context, last),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceWhite,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondaryTeal,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.school_outlined, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.edit ? 'Edit Training' : 'Create New Training',
                      style: handoverText(context, 16, weight: FontWeight.w700),
                    ),
                    Text(
                      'Build training content, add materials, configure quiz and assign to staff.',
                      style: handoverText(context, 12.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(false),
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepStrip(BuildContext context) {
    const icons = [
      Icons.assignment_outlined,
      Icons.upload_file_outlined,
      Icons.checklist_rounded,
      Icons.groups_outlined,
      Icons.school_outlined,
    ];
    return Container(
      color: AppColors.surfaceWhite,
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        itemCount: _steps.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (id, label, description) = _steps[i];
          final active = id == _step;
          final done = _stepComplete(id);
          return InkWell(
            key: ValueKey('training-step-tab-$id'),
            onTap: () => setState(() => _step = id),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: active ? AppColors.quickActionCreateShiftBg : AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: active ? AppColors.secondaryTeal : AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    done ? Icons.check_circle_rounded : icons[i],
                    size: 16,
                    color: active || done ? AppColors.secondaryTeal : AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: handoverText(context, 12.5, weight: FontWeight.w600)),
                      Text(description, style: handoverText(context, 11, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _tip(BuildContext context) {
    return HandoverPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.school_outlined, size: 16, color: AppColors.infoBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Setup Progress \u00b7 Step ${_index + 1} of ${_steps.length}',
                  style: handoverText(context, 12.5, weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  TrainingLabels.wizardTips[_step]!,
                  style: handoverText(context, 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summary(BuildContext context) {
    Widget row(String label, Widget value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: handoverText(context, 11.5, color: AppColors.textMuted)),
              value,
            ],
          ),
        );
    return Container(
      key: const ValueKey('training-form-summary'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1C2E4A), Color(0xFF24406B)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.school_outlined, size: 18, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  _v.title.isEmpty ? 'New Training' : _v.title,
                  style: handoverText(context, 16, weight: FontWeight.w700, color: Colors.white),
                ),
                Text(
                  '${widget.edit ? 'EDITING' : 'NEW'} \u00b7 ${widget.code}',
                  style: handoverText(context, 11.5, color: Colors.white70),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                row(
                  'Category',
                  _v.category.isEmpty
                      ? Text('Not set', style: handoverText(context, 12, color: AppColors.textMuted))
                      : TrainingPill(label: _v.category, tone: TrainingTone.cyan),
                ),
                row('Type', Text(_v.type, style: handoverText(context, 12, weight: FontWeight.w600))),
                row(
                  'Status',
                  TrainingPill(
                    label: widget.edit ? 'Active' : 'Not saved yet',
                    tone: widget.edit ? TrainingTone.success : TrainingTone.neutral,
                  ),
                ),
                row(
                  'Est. Reach',
                  Text('$_reach staff', style: handoverText(context, 12, weight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _setupProgress(BuildContext context) {
    return HandoverPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SETUP PROGRESS',
            style: handoverText(context, 11, weight: FontWeight.w600, color: AppColors.textMuted)
                .copyWith(letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          for (final (i, step) in _steps.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: i < _index ? AppColors.secondaryTeal : null,
                      shape: BoxShape.circle,
                      border: i < _index ? null : Border.all(color: AppColors.cardBorder),
                    ),
                    child: i < _index
                        ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    step.$3,
                    style: handoverText(
                      context,
                      12.5,
                      color: i < _index ? AppColors.textHeading : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context, bool last) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '* Required fields',
                  style: handoverText(context, 12, color: AppColors.textMuted),
                ),
              ),
              HandoverButton(
                label: 'Cancel',
                onPressed: () => Navigator.of(context).pop(false),
              ),
              const SizedBox(width: 8),
              last
                  ? HandoverButton(
                      key: const ValueKey('training-form-publish'),
                      label: _saving
                          ? 'Saving…'
                          : widget.edit
                              ? 'Save Changes'
                              : 'Publish Training',
                      icon: Icons.school_outlined,
                      filled: true,
                      onPressed: _saving ? null : _publish,
                    )
                  : HandoverButton(
                      key: const ValueKey('training-form-next'),
                      label: 'Next Step',
                      icon: Icons.arrow_forward_rounded,
                      filled: true,
                      onPressed: _next,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
