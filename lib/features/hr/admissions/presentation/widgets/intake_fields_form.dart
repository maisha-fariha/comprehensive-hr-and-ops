import 'package:flutter/material.dart';

import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/referral.dart';
import 'admissions_common.dart';

/// Renders an intake template's questions (the web `IntakeFields`).
/// Numbers are stored as numbers, an emptied number as `''`, checkboxes as
/// booleans and dates as `YYYY-MM-DD`.
class IntakeFieldsForm extends StatefulWidget {
  final List<IntakeField> fields;
  final Map<String, dynamic> values;
  final void Function(String key, dynamic value) onChanged;
  final bool disabled;

  const IntakeFieldsForm({
    super.key,
    required this.fields,
    required this.values,
    required this.onChanged,
    this.disabled = false,
  });

  @override
  State<IntakeFieldsForm> createState() => _IntakeFieldsFormState();
}

class _IntakeFieldsFormState extends State<IntakeFieldsForm> {
  final Map<String, TextEditingController> _controllers = {};

  TextEditingController _controller(String key) =>
      _controllers.putIfAbsent(key, () {
        final v = widget.values[key];
        return TextEditingController(
          text: v is String || v is num ? '$v' : '',
        );
      });

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fields.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final field in widget.fields) ...[
          _field(context, field),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _field(BuildContext context, IntakeField field) {
    final key = ValueKey('intake-field-${field.key}');
    final value = widget.values[field.key];
    switch (field.type) {
      case 'textarea':
        return HandoverTextArea(
          key: key,
          label: field.label,
          required: field.required,
          controller: _controller(field.key),
          minLines: 3,
          onChanged: (v) => widget.onChanged(field.key, v),
        );
      case 'select':
        return HandoverSelect(
          key: key,
          label: field.label,
          required: field.required,
          value: value is String && value.isNotEmpty ? value : null,
          placeholder: 'Choose one',
          helper: 'The API rejects anything outside this list',
          onTap: widget.disabled
              ? null
              : () async {
                  final picked = await pickHandoverOption(
                    context,
                    title: field.label,
                    options: [for (final o in field.options) (o, o)],
                    selected: value is String ? value : null,
                  );
                  if (picked != null) widget.onChanged(field.key, picked);
                },
        );
      case 'checkbox':
        return Align(
          alignment: Alignment.centerLeft,
          child: AdmissionCheckbox(
            key: key,
            label: field.label,
            value: value == true,
            onChanged: widget.disabled
                ? null
                : (v) => widget.onChanged(field.key, v),
          ),
        );
      case 'date':
        return AdmissionDateField(
          key: key,
          label: field.label,
          required: field.required,
          enabled: !widget.disabled,
          value: value is String ? value : '',
          onChanged: (v) => widget.onChanged(field.key, v),
        );
      case 'number':
        return AdmissionInput(
          key: key,
          label: field.label,
          required: field.required,
          enabled: !widget.disabled,
          controller: _controller(field.key),
          keyboardType: TextInputType.number,
          onChanged: (v) => widget.onChanged(
            field.key,
            v.isEmpty ? '' : (num.tryParse(v) ?? ''),
          ),
        );
      default:
        return AdmissionInput(
          key: key,
          label: field.label,
          required: field.required,
          enabled: !widget.disabled,
          controller: _controller(field.key),
          onChanged: (v) => widget.onChanged(field.key, v),
        );
    }
  }
}
