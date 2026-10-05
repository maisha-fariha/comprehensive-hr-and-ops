import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../../presentation/widgets/hr_directory_widgets.dart';
import '../../domain/entities/residence_form.dart';
import '../../domain/entities/residence_summary.dart';
import '../controllers/residences_controller.dart';
import '../residences_labels.dart';
import '../widgets/residence_form_steps.dart';

/// Web "Add New Residence" / "Edit Residence" five-step wizard.
/// Pops `true` after a successful save.
class ResidenceFormPage extends StatefulWidget {
  final ResidencesController controller;
  final ResidenceSummary? editing;

  /// The detail drawer's edit always replaces the assignments.
  final bool alwaysSendAssignments;

  const ResidenceFormPage({
    super.key,
    required this.controller,
    this.editing,
    this.alwaysSendAssignments = false,
  });

  @override
  State<ResidenceFormPage> createState() => _ResidenceFormPageState();
}

class _ResidenceFormPageState extends State<ResidenceFormPage> {
  static const _missingMessage =
      'Some required fields are missing — fix the highlighted step before creating this residence.';

  late final ResidenceFormValues _values = widget.editing == null
      ? ResidenceFormValues()
      : ResidenceFormValues.fromResidence(widget.editing!);
  final Map<String, String> _errors = {};
  final Map<String, TextEditingController> _text = {};
  final ScrollController _scroll = ScrollController();

  ResidenceFormStep _step = ResidenceFormStep.basic;
  String? _submitError;
  bool _submitting = false;
  bool _staffLoading = true;
  List<ResidenceStaffOption> _staff = const [];

  bool get _isEdit => widget.editing != null;
  ResidencesController get _controller => widget.controller;
  bool get _limitReached => !_isEdit && _controller.limitReached;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    final repo = _controller.admin;
    if (repo == null) {
      setState(() => _staffLoading = false);
      return;
    }
    final result = await repo.getStaffOptions();
    if (!mounted) return;
    setState(() {
      _staffLoading = false;
      _staff = result.when(success: (s) => s, failure: (_) => const []);
    });
  }

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  TextEditingController _textFor(String field, String initial) =>
      _text.putIfAbsent(field, () => TextEditingController(text: initial));

  void _goTo(ResidenceFormStep step) {
    setState(() => _step = step);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _next() {
    final errors = _values.validateStep(_step);
    if (errors.isNotEmpty) {
      setState(() => _errors.addAll(errors));
      return;
    }
    _goTo(ResidenceFormStep.values[_step.index + 1]);
  }

  void _back() {
    if (_step.index == 0) {
      Get.back();
      return;
    }
    _goTo(ResidenceFormStep.values[_step.index - 1]);
  }

  ResidenceFormStep _stepOf(String field) {
    for (final entry in ResidenceFormValues.stepFields.entries) {
      if (entry.value.contains(field)) return entry.key;
    }
    return switch (field) {
      'phone' || 'emergencyContact' || 'email' => ResidenceFormStep.basic,
      _ => ResidenceFormStep.management,
    };
  }

  Future<void> _create() async {
    final errors = _values.validate();
    if (errors.isNotEmpty) {
      setState(() {
        _errors
          ..clear()
          ..addAll(errors);
        _submitError = _missingMessage;
      });
      _goTo(_stepOf(errors.keys.first));
      return;
    }
    await _submit(_values);
  }

  /// Web "Save as Draft" skips validation and forces Pending.
  Future<void> _saveDraft() => _submit(_values.copy()..lifecycleStatus = 'Pending');

  Future<void> _submit(ResidenceFormValues values) async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    final error = await _controller.submitResidence(
      values,
      editing: widget.editing,
      alwaysSendAssignments: widget.alwaysSendAssignments,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error == null) {
      Get.back(result: true);
      return;
    }
    setState(() => _submitError = error);
    AppSnackbar.show(error.isEmpty ? 'Failed to save residence' : error, '');
  }

  @override
  Widget build(BuildContext context) {
    final binding = ResidenceFormBinding(
      values: _values,
      errors: _errors,
      staff: _staff,
      staffLoading: _staffLoading,
      enabledTypes: _controller.tenant.value.enabledResidenceTypes,
      text: _textFor,
      update: setState,
    );
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: hrSubPageAppBar(context, _isEdit ? 'Edit Residence' : 'Add New Residence'),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _header(context),
                const SizedBox(height: 12),
                _stepper(context),
                const SizedBox(height: 12),
                _progress(context),
                if (_submitError != null) ...[
                  const SizedBox(height: 12),
                  _banner(context, _submitError!, key: const ValueKey('residence-form-error')),
                ],
                if (_limitReached) ...[
                  const SizedBox(height: 12),
                  _banner(
                    context,
                    'Plan limit reached (${_controller.residenceCount}/${_controller.residenceLimit} '
                    'residences). You cannot create additional residences on your current plan.',
                    key: const ValueKey('residence-form-limit'),
                  ),
                ],
                const SizedBox(height: 12),
                switch (_step) {
                  ResidenceFormStep.basic => ResidenceBasicStep(b: binding),
                  ResidenceFormStep.address => ResidenceAddressStep(b: binding),
                  ResidenceFormStep.capacity => ResidenceCapacityStep(b: binding),
                  ResidenceFormStep.management => ResidenceManagementStep(b: binding),
                  ResidenceFormStep.review => ResidenceReviewStep(b: binding, onEditStep: _goTo),
                },
                const SizedBox(height: 16),
                ResidencePreviewCard(values: _values),
                const SizedBox(height: 12),
                ResidenceSetupProgress(currentIndex: _step.index),
              ],
            ),
          ),
          _footer(context),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isEdit)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondaryTeal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Residence Setup · #${widget.editing!.id.toUpperCase()}',
                style: handoverText(context, 11, weight: FontWeight.w600, color: AppColors.secondaryTeal),
              ),
            ),
          ),
        Text(
          'Register a new residence, set its address, capacity and leadership.',
          style: handoverText(context, 13, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _stepper(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final step in ResidenceFormStep.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                key: ValueKey('residence-step-${step.name}'),
                borderRadius: BorderRadius.circular(12),
                onTap: () => _goTo(step),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: step == _step ? AppColors.surfaceWhite : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: step == _step ? AppColors.secondaryTeal : AppColors.cardBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: step.index < _step.index
                            ? AppColors.secondaryTeal
                            : (step == _step ? AppColors.secondaryTeal : AppColors.dividerLight),
                        child: step.index < _step.index
                            ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                            : Text(
                                '${step.index + 1}',
                                style: handoverText(
                                  context,
                                  11,
                                  weight: FontWeight.w700,
                                  color: step == _step ? Colors.white : AppColors.textSecondary,
                                ),
                              ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ResidencesLabels.stepLabel(step),
                              style: handoverText(context, 12, weight: FontWeight.w600)),
                          Text(ResidencesLabels.stepDescription(step),
                              style: handoverText(context, 10.5, color: AppColors.textMuted)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _progress(BuildContext context) {
    final total = ResidenceFormStep.values.length;
    final done = _step.index + 1;
    return HandoverPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('FORM COMPLETION',
                    style: handoverText(context, 11, weight: FontWeight.w700, color: AppColors.textMuted)),
              ),
              Text('Step $done of $total',
                  style: handoverText(context, 12, weight: FontWeight.w600, color: AppColors.secondaryTeal)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: done / total,
              minHeight: 6,
              backgroundColor: AppColors.dividerLight,
              color: AppColors.secondaryTeal,
            ),
          ),
          const SizedBox(height: 8),
          Text('${(done / total * 100).round()}% complete',
              style: handoverText(context, 11.5, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(ResidencesLabels.stepTip(_step), style: handoverText(context, 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _banner(BuildContext context, String message, {Key? key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.criticalRed.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.criticalRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.criticalRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: handoverText(context, 12.5, color: AppColors.criticalRed)),
          ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context) {
    final review = _step == ResidenceFormStep.review;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Step ${_step.index + 1} of ${ResidenceFormStep.values.length}',
              style: handoverText(context, 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                HandoverButton(
                  key: const ValueKey('residence-form-back'),
                  label: _step.index == 0 ? 'Cancel' : 'Back',
                  icon: _step.index == 0 ? null : Icons.chevron_left_rounded,
                  onPressed: _submitting ? null : _back,
                ),
                if (!review)
                  HandoverButton(
                    key: const ValueKey('residence-form-save'),
                    label: _isEdit ? 'Save Changes' : 'Save as Draft',
                    icon: Icons.save_outlined,
                    onPressed: _submitting || _limitReached
                        ? null
                        : (_isEdit ? _create : _saveDraft),
                  ),
                if (!review)
                  HandoverButton(
                    key: const ValueKey('residence-form-next'),
                    label: 'Next',
                    filled: true,
                    onPressed: _submitting ? null : _next,
                  )
                else
                  HandoverButton(
                    key: const ValueKey('residence-form-submit'),
                    label: _limitReached
                        ? 'Limit Exceeded'
                        : (_submitting
                            ? 'Saving…'
                            : (_isEdit ? 'Save Changes' : 'Create Residence')),
                    icon: Icons.check_rounded,
                    filled: true,
                    onPressed: _submitting || _limitReached ? null : _create,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
