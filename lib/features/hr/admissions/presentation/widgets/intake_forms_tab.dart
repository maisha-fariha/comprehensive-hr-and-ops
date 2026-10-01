import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../attendance/presentation/widgets/attendance_pagination.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/referral.dart';
import '../controllers/admissions_controller.dart';
import 'admissions_common.dart';
import 'intake_template_form_sheet.dart';

/// The web "Intake forms" tab: every template, in use or retired.
class IntakeFormsTab extends StatefulWidget {
  final AdmissionsController controller;

  const IntakeFormsTab({super.key, required this.controller});

  @override
  State<IntakeFormsTab> createState() => _IntakeFormsTabState();
}

class _IntakeFormsTabState extends State<IntakeFormsTab> {
  static const List<int> _pageSizes = [10, 25, 50];
  int _page = 1;
  int _limit = _pageSizes.first;

  AdmissionsController get _c => widget.controller;

  Future<void> _retire(IntakeTemplate t) async {
    final confirmed = await confirmAdmissionAction(
      context,
      title: 'Retire this intake form?',
      description:
          '"${t.name}" stops being offered on new referrals. Existing referrals '
          'keep the answers they already gave — retiring does not touch them.',
      confirmLabel: 'Retire',
      tone: AppColors.urgentAmber,
      confirmKey: const ValueKey('template-retire-confirm'),
    );
    if (confirmed) await _c.retireTemplate(t);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final templates = _c.templates.toList();
      final pages = templates.isEmpty ? 1 : (templates.length + _limit - 1) ~/ _limit;
      final page = _page.clamp(1, pages);
      final visible = templates.skip((page - 1) * _limit).take(_limit).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_c.canWrite) ...[
            Align(
              alignment: Alignment.centerRight,
              child: HandoverButton(
                key: const ValueKey('template-new'),
                label: 'New intake form',
                icon: Icons.add_rounded,
                filled: true,
                onPressed: () =>
                    showIntakeTemplateFormSheet(context, controller: _c),
              ),
            ),
            const SizedBox(height: 15),
          ],
          if (_c.templatesLoading.value && templates.isEmpty)
            for (var i = 0; i < 2; i++)
              Container(
                height: 96,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.filterButtonBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
              )
          else if (templates.isEmpty)
            _empty(context)
          else ...[
            for (final t in visible) ...[
              _TemplateCard(
                key: ValueKey('template-${t.id}'),
                template: t,
                canWrite: _c.canWrite,
                busy: _c.busyId.value == t.id,
                onEdit: () => showIntakeTemplateFormSheet(
                  context,
                  controller: _c,
                  template: t,
                ),
                onToggle: () =>
                    t.isRetired ? _c.reinstateTemplate(t) : _retire(t),
              ),
              const SizedBox(height: 12),
            ],
            AttendancePagination(
              page: page,
              limit: _limit,
              total: templates.length,
              totalPages: pages,
              limitOptions: _pageSizes,
              onPage: (p) => setState(() => _page = p),
              onLimit: (l) => setState(() {
                _limit = l;
                _page = 1;
              }),
            ),
          ],
        ],
      );
    });
  }

  Widget _empty(BuildContext context) {
    final failed = _c.templatesError.value != null;
    return HandoverPanel(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.filterButtonBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.description_outlined,
              size: 19,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            failed ? 'Forms could not be loaded' : 'No intake forms',
            textAlign: TextAlign.center,
            style: handoverText(context, 15, weight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            failed
                ? _c.templatesError.value!
                : 'A referral can be taken without one — a form adds the '
                    'questions and the checklist that gate admission.',
            textAlign: TextAlign.center,
            style: handoverText(context, 13.5, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final IntakeTemplate template;
  final bool canWrite;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  const _TemplateCard({
    super.key,
    required this.template,
    required this.canWrite,
    required this.busy,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final t = template;
    final required = t.requiredChecklistCount;
    Widget cell(String label, String value) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: handoverText(
                context,
                10.5,
                weight: FontWeight.w600,
                color: AppColors.textMuted,
              ).copyWith(letterSpacing: 0.5),
            ),
            const SizedBox(height: 2),
            Text(value, style: handoverText(context, 13)),
          ],
        );
    return Opacity(
      opacity: busy ? 0.6 : 1,
      child: HandoverPanel(
        padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.name,
                        style: handoverText(
                          context,
                          14.5,
                          weight: FontWeight.w600,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${t.provinceOrState ?? 'No region'} · v${t.version ?? 1}',
                        style: handoverText(context, 12, color: AppColors.infoBlue),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AdmissionPill(
                  label: t.isRetired ? 'Retired' : 'In use',
                  tone: t.isRetired ? AdmissionTone.neutral : AdmissionTone.success,
                  dot: true,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                cell('Questions', '${t.fields.length}'),
                cell(
                  'Checklist',
                  '${t.checklist.length}${required > 0 ? ' · $required required' : ''}',
                ),
              ],
            ),
            if (canWrite) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  children: [
                    Semantics(
                      label: 'Edit form',
                      child: HandoverButton(
                        key: ValueKey('template-edit-${t.id}'),
                        label: '',
                        icon: Icons.edit_outlined,
                        compact: true,
                        onPressed: busy ? null : onEdit,
                      ),
                    ),
                    HandoverButton(
                      key: ValueKey('template-toggle-${t.id}'),
                      label: t.isRetired ? 'Reinstate' : 'Retire',
                      compact: true,
                      onPressed: busy ? null : onToggle,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
