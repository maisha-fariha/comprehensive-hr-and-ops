import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/formatting/web_formats.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/referral.dart';
import '../admissions_labels.dart';
import '../controllers/admissions_controller.dart';
import 'admissions_common.dart';
import 'referral_contacts_editor.dart';

Future<void> showReferralDetailSheet(
  BuildContext context, {
  required AdmissionsController controller,
  required String referralId,
}) =>
    showAdmissionSheet<void>(
      context,
      ReferralDetailSheet(controller: controller, referralId: referralId),
    );

/// The web referral modal: contact, intake answers, checklist, family and
/// guardians, history, assessments and "Move it on".
class ReferralDetailSheet extends StatefulWidget {
  final AdmissionsController controller;
  final String referralId;

  const ReferralDetailSheet({
    super.key,
    required this.controller,
    required this.referralId,
  });

  @override
  State<ReferralDetailSheet> createState() => _ReferralDetailSheetState();
}

class _ReferralDetailSheetState extends State<ReferralDetailSheet> {
  final _summary = TextEditingController();
  final _outcome = TextEditingController();
  Referral? _referral;
  String? _loadError;
  String? _error;
  bool _saving = false;
  bool _checklistSaving = false;

  AdmissionsController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _summary.dispose();
    _outcome.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await _c.repository.referral(widget.referralId);
    if (!mounted) return;
    result.when(
      success: (r) => setState(() {
        _referral = r;
        _loadError = null;
      }),
      failure: (e) => setState(() => _loadError = AdmissionsLabels.error(e)),
    );
  }

  Future<bool> _act(Future<String?> Function() action) async {
    setState(() {
      _error = null;
      _saving = true;
    });
    final error = await action();
    if (!mounted) return false;
    setState(() {
      _saving = false;
      _error = error;
    });
    if (error == null) await _load();
    return error == null;
  }

  Future<void> _toggle(Referral r, String key) async {
    final next = {...r.completedChecklist};
    if (!next.remove(key)) next.add(key);
    setState(() => _checklistSaving = true);
    final error = await _c.setChecklist(r.id, next.toList());
    if (!mounted) return;
    setState(() => _checklistSaving = false);
    if (error == null) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final r = _referral;
    return AdmissionSheetFrame(
      icon: Icons.person_add_alt_1_outlined,
      title: r != null
          ? r.fullName
          : _loadError == null
              ? 'Loading…'
              : 'Referral',
      description: r == null
          ? null
          : '${WebFormat.humanise(r.status)}'
              '${r.source == null ? '' : ' · referred by ${r.source}'}',
      footer: [
        HandoverButton(
          key: const ValueKey('referral-detail-close'),
          label: 'Close',
          filled: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      children: r == null
          ? [
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: _loadError == null
                      ? const CircularProgressIndicator(
                          color: AppColors.secondaryTeal,
                        )
                      : Text(_loadError!, style: handoverText(context, 13.5)),
                ),
              ),
            ]
          : _body(context, r),
    );
  }

  List<Widget> _body(BuildContext context, Referral r) {
    const gap = SizedBox(height: 20);
    const small = SizedBox(height: 8);
    final editable = _c.canWrite && !r.isClosed;
    final snapshot = r.snapshot;
    final fields = snapshot?.fields ?? const <IntakeField>[];
    final checklist = r.checklist;
    final outstanding = r.outstanding;
    return [
      if (_error != null) ...[
        AdmissionErrorBanner(_error!, key: const ValueKey('referral-detail-error')),
        gap,
      ],
      if (r.isClosed) ...[
        AdmissionNotice(
          'This referral is ${WebFormat.humanise(r.status).toLowerCase()} and '
          'can no longer be changed.'
          '${r.closedReason == null ? '' : ' Reason: ${r.closedReason}'}',
        ),
        gap,
      ],
      const AdmissionSectionTitle('Contact'),
      small,
      AdmissionField('Date of birth', WebFormat.date(r.dateOfBirth)),
      AdmissionField('Contact', r.contactName ?? '—'),
      AdmissionField('Phone', r.contactPhone ?? '—'),
      AdmissionField('Email', r.contactEmail ?? '—'),
      AdmissionField(
        'Preferred residence',
        _c.residenceName(r.preferredResidenceId) ?? 'Not stated',
      ),
      AdmissionField('Waiting since', WebFormat.date(r.waitlistedAt)),
      if (r.notes != null) Text(r.notes!, style: handoverText(context, 13.5)),
      if (fields.isNotEmpty) ...[
        gap,
        AdmissionSectionTitle(
          'Intake — ${snapshot?.name ?? 'form'}'
          '${snapshot?.version == null ? '' : ' v${snapshot!.version}'}',
        ),
        small,
        Text(
          'The form as it stood when this referral was taken. Editing the '
          'template later does not change what was answered here.',
          style: handoverText(context, 12.5, color: AppColors.textMuted),
        ),
        small,
        for (final f in fields) AdmissionField(f.label, _answer(r.payload[f.key])),
      ],
      if (checklist.isNotEmpty) ...[
        gap,
        const AdmissionSectionTitle('Intake checklist'),
        small,
        if (outstanding.isNotEmpty) ...[
          Text(
            'Admission is blocked until these are done: '
            '${outstanding.map((o) => o.label).join(', ')}',
            key: const ValueKey('referral-detail-blocked'),
            style: handoverText(context, 12.5, color: AppColors.urgentAmber),
          ),
          small,
        ],
        for (final item in checklist) _checklistRow(context, r, item, editable),
      ],
      gap,
      const AdmissionSectionTitle('Family and guardians'),
      small,
      if (editable)
        ReferralContactsEditor(
          key: ValueKey('contacts-${r.contacts.map((c) => c.id).join(',')}'),
          initial: r.contacts,
          onSave: (contacts) async {
            final error = await _c.setContacts(r.id, contacts);
            if (error == null && mounted) await _load();
            return error;
          },
        )
      else if (r.contacts.isEmpty)
        Text(
          'None collected yet.',
          style: handoverText(context, 13, color: AppColors.textMuted),
        )
      else
        for (final c in r.contacts) _contactRow(context, c),
      if (r.events.isNotEmpty) ...[
        gap,
        const AdmissionSectionTitle('History'),
        small,
        for (final e in r.events) _eventRow(context, e),
      ],
      gap,
      const AdmissionSectionTitle('Assessments'),
      small,
      if (r.assessments.isEmpty)
        Text(
          'None recorded.',
          style: handoverText(context, 13, color: AppColors.textMuted),
        )
      else
        for (final a in r.assessments) _assessmentRow(context, a),
      if (editable) ...[
        small,
        _box(
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _summary,
            builder: (context, value, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HandoverTextArea(
                  key: const ValueKey('assessment-summary'),
                  label: 'New assessment',
                  controller: _summary,
                  minLines: 3,
                ),
                small,
                AdmissionInput(
                  key: const ValueKey('assessment-outcome'),
                  label: 'Outcome',
                  placeholder: 'e.g. suitable, needs review',
                  controller: _outcome,
                ),
                small,
                Align(
                  alignment: Alignment.centerLeft,
                  child: HandoverButton(
                    key: const ValueKey('assessment-record'),
                    label: 'Record assessment',
                    compact: true,
                    onPressed: _saving || value.text.trim().isEmpty
                        ? null
                        : () async {
                            final outcome = _outcome.text.trim();
                            final ok = await _act(
                              () => _c.addAssessment(
                                r.id,
                                summary: _summary.text.trim(),
                                outcome: outcome.isEmpty ? null : outcome,
                              ),
                            );
                            if (ok) {
                              _summary.clear();
                              _outcome.clear();
                            }
                          },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      if (editable) ...[
        gap,
        const AdmissionSectionTitle('Move it on'),
        small,
        HandoverSelect(
          key: const ValueKey('referral-stage'),
          label: 'Stage',
          value: AdmissionsLabels.label(AdmissionsLabels.stages, r.status),
          placeholder: 'New',
          helper:
              'Waitlisting starts the clock that orders the queue; leaving the waitlist clears it',
          onTap: _saving
              ? null
              : () async {
                  final picked = await pickHandoverOption(
                    context,
                    title: 'Stage',
                    options: AdmissionsLabels.openStages,
                    selected: r.status,
                  );
                  if (picked != null && picked != r.status) {
                    await _act(() => _c.moveStage(r.id, picked));
                  }
                },
        ),
      ],
    ];
  }

  static String _answer(dynamic value) {
    if (value == null || value == '') return '—';
    if (value is bool) return value ? 'Yes' : 'No';
    return '$value';
  }

  Widget _box(Widget child) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: child,
      );

  Widget _checklistRow(
    BuildContext context,
    Referral r,
    IntakeChecklistItem item,
    bool editable,
  ) {
    final doc = item.requiresDocument ? r.documentFor(item.key) : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 10,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          AdmissionCheckbox(
            key: ValueKey('checklist-${item.key}'),
            label: item.label,
            value: r.completedChecklist.contains(item.key),
            onChanged: !editable || _checklistSaving
                ? null
                : (_) => _toggle(r, item.key),
          ),
          if (item.required)
            const AdmissionPill(label: 'Required', tone: AdmissionTone.danger),
          if (item.requiresDocument)
            if (doc != null)
              InkWell(
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: doc.fileUrl));
                  AppSnackbar.show('Link copied', doc.name);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.attach_file_rounded,
                      size: 12,
                      color: AppColors.secondaryTeal,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      doc.name,
                      style: handoverText(
                        context,
                        12,
                        color: AppColors.secondaryTeal,
                      ),
                    ),
                  ],
                ),
              )
            else
              const AdmissionPill(
                label: 'Needs a file',
                tone: AdmissionTone.warning,
              ),
        ],
      ),
    );
  }

  Widget _contactRow(BuildContext context, ReferralContact c) => _box(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  c.name,
                  style: handoverText(
                    context,
                    13,
                    weight: FontWeight.w600,
                    color: AppColors.primaryNavy,
                  ),
                ),
                if (c.relationship != null)
                  Text(
                    c.relationship!,
                    style: handoverText(context, 12, color: AppColors.textMuted),
                  ),
                if (c.isPrimaryGuardian)
                  const AdmissionPill(label: 'Decides', tone: AdmissionTone.info),
                if (c.isEmergencyContact)
                  const AdmissionPill(
                    label: 'Called first',
                    tone: AdmissionTone.warning,
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              [c.phone, c.email, c.address].whereType<String>().join(' · '),
              style: handoverText(context, 12.5, color: AppColors.textMuted),
            ),
          ],
        ),
      );

  Widget _eventRow(BuildContext context, ReferralEvent e) => _box(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  AdmissionsLabels.event(e.event),
                  style: handoverText(
                    context,
                    12.5,
                    weight: FontWeight.w600,
                    color: AppColors.primaryNavy,
                  ),
                ),
                if (e.fromStatus != null && e.toStatus != null)
                  Text(
                    '${WebFormat.humanise(e.fromStatus)} → '
                    '${WebFormat.humanise(e.toStatus)}',
                    style: handoverText(context, 11.5, color: AppColors.textMuted),
                  ),
                Text(
                  '${e.actorName ?? 'System'} · ${WebFormat.dateTime(e.createdAt)}',
                  style: handoverText(context, 11.5, color: AppColors.textMuted),
                ),
              ],
            ),
            if (e.note != null) ...[
              const SizedBox(height: 4),
              Text(e.note!, style: handoverText(context, 13)),
            ],
          ],
        ),
      );

  Widget _assessmentRow(BuildContext context, ReferralAssessment a) => _box(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    WebFormat.date(a.assessedAt),
                    style: handoverText(
                      context,
                      13,
                      weight: FontWeight.w600,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                ),
                if (a.outcome != null)
                  AdmissionPill(
                    label: WebFormat.humanise(a.outcome),
                    tone: AdmissionTone.info,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(a.summary, style: handoverText(context, 13.5)),
          ],
        ),
      );
}
