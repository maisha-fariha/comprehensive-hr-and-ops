import 'package:flutter/material.dart';
import 'package:gems_core/gems_core.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';

class AiSelectOption {
  final String value;
  final String label;

  const AiSelectOption(this.value, this.label);
}

class AiDraftPayload {
  final String draft;
  final String? note;

  const AiDraftPayload({required this.draft, this.note});
}

/// Shared web-parity AI draft dialog (Draft it → editable note).
Future<void> showAiDraftSheet(
  BuildContext context, {
  required String title,
  required String sends,
  required Future<Result<AiDraftPayload>> Function() generate,
  List<Widget> options = const [],
  String draftLabel = 'Draft',
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AiDraftSheet(
      title: title,
      sends: sends,
      generate: generate,
      options: options,
      draftLabel: draftLabel,
    ),
  );
}

class _AiDraftSheet extends StatefulWidget {
  final String title;
  final String sends;
  final Future<Result<AiDraftPayload>> Function() generate;
  final List<Widget> options;
  final String draftLabel;

  const _AiDraftSheet({
    required this.title,
    required this.sends,
    required this.generate,
    required this.options,
    required this.draftLabel,
  });

  @override
  State<_AiDraftSheet> createState() => _AiDraftSheetState();
}

class _AiDraftSheetState extends State<_AiDraftSheet> {
  final _draft = TextEditingController();
  String? _note;
  bool _loading = false;
  bool _hasDraft = false;

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    if (_loading) return;
    setState(() => _loading = true);
    final result = await widget.generate();
    if (!mounted) return;
    setState(() => _loading = false);
    result.when(
      success: (payload) {
        setState(() {
          _draft.text = payload.draft;
          _note = payload.note;
          _hasDraft = true;
        });
      },
      failure: (error) {
        AppErrorDialog.showResultError(
          error,
          fallbackTitle: 'Could not draft',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 20),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                horizontal: 20,
                top: 10,
                bottom: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.dividerLight,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primaryNavy,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: handoverText(
                                context,
                                16,
                                weight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'An AI first draft — read every line and correct it before you use it.',
                              style: handoverText(
                                context,
                                12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.sends,
                    style: handoverText(
                      context,
                      12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ...widget.options,
                          if (widget.options.isNotEmpty)
                            const SizedBox(height: 14),
                          if (!_hasDraft)
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.searchBorder,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Center(
                                child: HandoverButton(
                                  label: _loading ? 'Drafting…' : 'Draft it',
                                  icon: Icons.auto_awesome,
                                  filled: true,
                                  onPressed: _loading ? null : _run,
                                ),
                              ),
                            )
                          else ...[
                            if ((_note ?? '').isNotEmpty) ...[
                              Text(
                                _note!,
                                style: handoverText(
                                  context,
                                  12.5,
                                  color: AppColors.urgentAmber,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            Text(
                              widget.draftLabel,
                              style: handoverText(
                                context,
                                13,
                                weight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 7),
                            TextField(
                              controller: _draft,
                              maxLines: 12,
                              style: handoverText(context, 13.5),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.scaffoldBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (_hasDraft)
                        HandoverButton(
                          label: _loading ? 'Drafting…' : 'Draft again',
                          icon: Icons.auto_awesome,
                          onPressed: _loading ? null : _run,
                        ),
                      const Spacer(),
                      HandoverButton(
                        label: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact outline AI action button matching web sparkles controls.
class AiAssistButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Key? buttonKey;

  const AiAssistButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.buttonKey,
  });

  @override
  Widget build(BuildContext context) {
    return HandoverButton(
      key: buttonKey,
      label: label,
      icon: Icons.auto_awesome,
      compact: true,
      onPressed: onPressed,
    );
  }
}

class AiDropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<AiSelectOption> options;
  final ValueChanged<String> onChanged;

  const AiDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: handoverText(context, 12.5, weight: FontWeight.w600)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: options.any((o) => o.value == value) ? value : null,
          items: [
            for (final option in options)
              DropdownMenuItem(value: option.value, child: Text(option.label)),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.searchBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.searchBorder),
            ),
          ),
        ),
      ],
    );
  }
}
