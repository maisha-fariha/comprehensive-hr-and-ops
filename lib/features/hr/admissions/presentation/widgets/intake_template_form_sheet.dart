import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/referral.dart';
import '../admissions_labels.dart';
import '../controllers/admissions_controller.dart';
import 'admissions_common.dart';

Future<void> showIntakeTemplateFormSheet(
  BuildContext context, {
  required AdmissionsController controller,
  IntakeTemplate? template,
}) =>
    showAdmissionSheet<void>(
      context,
      IntakeTemplateFormSheet(controller: controller, template: template),
    );

class _QuestionDraft {
  final String key;
  final TextEditingController label;
  final TextEditingController options;
  String type;
  String target;
  bool required;

  _QuestionDraft({
    this.key = '',
    String label = '',
    String options = '',
    this.type = 'text',
    this.target = 'none',
    this.required = false,
  })  : label = TextEditingController(text: label),
        options = TextEditingController(text: options);

  void dispose() {
    label.dispose();
    options.dispose();
  }
}

class _ItemDraft {
  final String key;
  final TextEditingController label;
  bool required;
  bool requiresDocument;

  _ItemDraft({
    this.key = '',
    String label = '',
    this.required = true,
    this.requiresDocument = false,
  }) : label = TextEditingController(text: label);
}

/// "New intake form" / "Edit intake form": questions and the checklist that
/// gates admission.
class IntakeTemplateFormSheet extends StatefulWidget {
  final AdmissionsController controller;
  final IntakeTemplate? template;

  const IntakeTemplateFormSheet({
    super.key,
    required this.controller,
    this.template,
  });

  @override
  State<IntakeTemplateFormSheet> createState() =>
      _IntakeTemplateFormSheetState();
}

class _IntakeTemplateFormSheetState extends State<IntakeTemplateFormSheet> {
  late final _name = TextEditingController(text: widget.template?.name);
  late final _region =
      TextEditingController(text: widget.template?.provinceOrState);
  late final List<_QuestionDraft> _questions = widget.template == null
      ? [_QuestionDraft()]
      : [
          for (final f in widget.template!.fields)
            _QuestionDraft(
              key: f.key,
              label: f.label,
              type: f.type,
              required: f.required,
              target: f.target ?? 'none',
              options: f.options.join(', '),
            ),
        ];
  late final List<_ItemDraft> _items = [
    for (final c in widget.template?.checklist ?? const <IntakeChecklistItem>[])
      _ItemDraft(
        key: c.key,
        label: c.label,
        required: c.required,
        requiresDocument: c.requiresDocument,
      ),
  ];
  final List<VoidCallback> _pendingDisposals = [];
  bool _saving = false;
  String? _error;

  bool get _editing => widget.template != null;

  @override
  void dispose() {
    _name.dispose();
    _region.dispose();
    for (final q in _questions) {
      q.dispose();
    }
    for (final i in _items) {
      i.label.dispose();
    }
    for (final d in _pendingDisposals) {
      d();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give the form a name.');
      return;
    }
    final fields = [
      for (final q in _questions)
        if (q.label.text.trim().isNotEmpty)
          <String, dynamic>{
            'key': q.key.trim().isNotEmpty
                ? q.key.trim()
                : AdmissionsLabels.slug(q.label.text),
            'label': q.label.text.trim(),
            'type': q.type,
            'required': q.required,
            if (q.target != 'none') 'target': q.target,
            if (q.type == 'select')
              'options': [
                for (final o in q.options.text.split(','))
                  if (o.trim().isNotEmpty) o.trim(),
              ],
          },
    ];
    if (fields.isEmpty) {
      setState(() => _error = 'A form needs at least one question.');
      return;
    }
    final keys = fields.map((f) => f['key']).toList();
    if (keys.toSet().length != keys.length) {
      setState(() => _error = 'Two questions share a key — rename one.');
      return;
    }
    final emptyChoice = fields
        .where((f) => f['type'] == 'select' && (f['options'] as List).isEmpty)
        .firstOrNull;
    if (emptyChoice != null) {
      setState(() => _error =
          '"${emptyChoice['label']}" is a choice question with no options.');
      return;
    }
    setState(() => _saving = true);
    final region = _region.text.trim();
    final body = <String, dynamic>{
      'name': name,
      if (region.isNotEmpty) 'provinceOrState': region,
      'fields': fields,
      'checklist': [
        for (final i in _items)
          if (i.label.text.trim().isNotEmpty)
            {
              'key': i.key.trim().isNotEmpty
                  ? i.key.trim()
                  : AdmissionsLabels.slug(i.label.text),
              'label': i.label.text.trim(),
              'required': i.required,
              'requiresDocument': i.requiresDocument,
            },
      ],
    };
    final error = _editing
        ? await widget.controller.updateTemplate(widget.template!.id, body)
        : await widget.controller.createTemplate(body);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = error;
    });
    if (error == null) Navigator.of(context).pop();
  }

  void _removeQuestion(int index) {
    final removed = _questions.removeAt(index);
    setState(() {});
    _pendingDisposals.add(removed.dispose);
  }

  void _removeItem(int index) {
    final removed = _items.removeAt(index);
    setState(() {});
    _pendingDisposals.add(removed.label.dispose);
  }

  Widget _card(BuildContext context, String heading, String removeLabel,
      Key removeKey, VoidCallback onRemove, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  heading,
                  style: handoverText(context, 13, color: AppColors.infoBlue),
                ),
              ),
              IconButton(
                key: removeKey,
                tooltip: removeLabel,
                visualDensity: VisualDensity.compact,
                onPressed: onRemove,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 16,
                  color: AppColors.criticalRed,
                ),
              ),
            ],
          ),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 12);
    return AdmissionSheetFrame(
      icon: Icons.description_outlined,
      title: _editing ? 'Edit intake form' : 'New intake form',
      description: _editing
          ? 'Referrals already taken keep the snapshot of this form as it stood when they were taken — editing only changes what new referrals see.'
          : 'Questions are stored as data, so this form can change without a release.',
      footer: [
        HandoverButton(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        HandoverButton(
          key: const ValueKey('template-form-save'),
          label: _saving
              ? 'Saving…'
              : _editing
                  ? 'Save changes'
                  : 'Create form',
          filled: true,
          onPressed: _saving ? null : _save,
        ),
      ],
      children: [
        if (_error != null) ...[
          AdmissionErrorBanner(_error!, key: const ValueKey('template-form-error')),
          gap,
        ],
        AdmissionInput(
          key: const ValueKey('template-name'),
          label: 'Name',
          required: true,
          controller: _name,
        ),
        gap,
        AdmissionInput(
          key: const ValueKey('template-region'),
          label: 'Region',
          placeholder: 'e.g. Ontario',
          controller: _region,
          helper:
              'Optional — for providers running different forms per province or state',
        ),
        const SizedBox(height: 20),
        const AdmissionSectionTitle('Questions'),
        gap,
        for (var i = 0; i < _questions.length; i++)
          _card(
            context,
            'Question ${i + 1}',
            'Remove question ${i + 1}',
            ValueKey('question-remove-$i'),
            () => _removeQuestion(i),
            [
              AdmissionInput(
                key: ValueKey('question-label-$i'),
                label: 'Label',
                controller: _questions[i].label,
              ),
              gap,
              HandoverSelect(
                key: ValueKey('question-type-$i'),
                label: 'Answer type',
                value: AdmissionsLabels.label(
                  AdmissionsLabels.answerTypes,
                  _questions[i].type,
                ),
                placeholder: 'Text',
                onTap: () async {
                  final picked = await pickHandoverOption(
                    context,
                    title: 'Answer type',
                    options: AdmissionsLabels.answerTypes,
                    selected: _questions[i].type,
                  );
                  if (picked != null) setState(() => _questions[i].type = picked);
                },
              ),
              gap,
              HandoverSelect(
                key: ValueKey('question-target-$i'),
                label: 'Carries over to',
                value: AdmissionsLabels.label(
                  AdmissionsLabels.carryOverTargets,
                  _questions[i].target,
                ),
                placeholder: 'Keep on the referral',
                onTap: () async {
                  final picked = await pickHandoverOption(
                    context,
                    title: 'Carries over to',
                    options: AdmissionsLabels.carryOverTargets,
                    selected: _questions[i].target,
                  );
                  if (picked != null) {
                    setState(() => _questions[i].target = picked);
                  }
                },
              ),
              if (_questions[i].type == 'select') ...[
                gap,
                AdmissionInput(
                  key: ValueKey('question-options-$i'),
                  label: 'Options',
                  placeholder: 'Comma separated',
                  controller: _questions[i].options,
                ),
              ],
              gap,
              AdmissionCheckbox(
                key: ValueKey('question-required-$i'),
                label: 'Required',
                value: _questions[i].required,
                onChanged: (v) => setState(() => _questions[i].required = v),
              ),
            ],
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: HandoverButton(
            key: const ValueKey('question-add'),
            label: 'Add question',
            icon: Icons.add_rounded,
            compact: true,
            onPressed: () => setState(() => _questions.add(_QuestionDraft())),
          ),
        ),
        const SizedBox(height: 20),
        const AdmissionSectionTitle('Checklist'),
        const SizedBox(height: 6),
        Text(
          'What has to be in place before someone is admitted. A required '
          'item blocks admission until it is ticked.',
          style: handoverText(context, 12.5, color: AppColors.textMuted),
        ),
        gap,
        for (var i = 0; i < _items.length; i++)
          _card(
            context,
            'Item ${i + 1}',
            'Remove item ${i + 1}',
            ValueKey('item-remove-$i'),
            () => _removeItem(i),
            [
              AdmissionInput(
                key: ValueKey('item-label-$i'),
                label: 'Label',
                controller: _items[i].label,
              ),
              gap,
              AdmissionCheckbox(
                key: ValueKey('item-required-$i'),
                label: 'Blocks admission until done',
                value: _items[i].required,
                onChanged: (v) => setState(() => _items[i].required = v),
              ),
              const SizedBox(height: 6),
              AdmissionCheckbox(
                key: ValueKey('item-document-$i'),
                label: 'Needs a document attached',
                value: _items[i].requiresDocument,
                onChanged: (v) => setState(() => _items[i].requiresDocument = v),
              ),
            ],
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: HandoverButton(
            key: const ValueKey('item-add'),
            label: 'Add checklist item',
            icon: Icons.add_rounded,
            compact: true,
            onPressed: () => setState(() => _items.add(_ItemDraft())),
          ),
        ),
      ],
    );
  }
}
