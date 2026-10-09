import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/formatting/web_formats.dart';
import '../../../attendance/presentation/widgets/attendance_record_card.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/emergency_alert.dart';
import '../controllers/emergency_controller.dart';
import '../emergency_labels.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

Future<void> showEmergencyDetailSheet(
  BuildContext context, {
  required EmergencyController controller,
  required String alertId,
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => EmergencyDetailSheet(controller: controller, alertId: alertId),
  );
}

/// The web alarm modal: what was reported, the response timeline,
/// attachments, "Add to the response" and the footer actions.
class EmergencyDetailSheet extends StatefulWidget {
  final EmergencyController controller;
  final String alertId;

  const EmergencyDetailSheet({
    super.key,
    required this.controller,
    required this.alertId,
  });

  @override
  State<EmergencyDetailSheet> createState() => _EmergencyDetailSheetState();
}

class _EmergencyDetailSheetState extends State<EmergencyDetailSheet> {
  final _note = TextEditingController();
  EmergencyAlert? _alert;
  String? _loadError;
  String? _actionError;
  String? _assignee;
  bool _saving = false;

  EmergencyController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await _c.repository.byId(widget.alertId);
    if (!mounted) return;
    result.when(
      success: (a) => setState(() {
        _alert = a;
        _loadError = null;
      }),
      failure: (e) => setState(() => _loadError = e.message),
    );
  }

  Future<void> _act(Future<String?> Function() action, {VoidCallback? onDone}) async {
    setState(() {
      _saving = true;
      _actionError = null;
    });
    final error = await action();
    if (!mounted) return;
    setState(() {
      _saving = false;
      _actionError = error;
    });
    if (error == null) {
      onDone?.call();
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = _alert;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.92,
        decoration: const BoxDecoration(
          color: AppColors.scaffoldBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _Header(
              title: a == null ? 'Emergency' : EmergencyLabels.type(a.type),
              subtitle: a == null
                  ? 'Loading…'
                  : '${a.residenceName ?? ''}'
                      '${a.locationNote == null ? '' : ' · ${a.locationNote}'}'
                      ' · ${WebFormat.dateTime(a.createdAt, empty: '')}',
            ),
            Expanded(
              child: a == null
                  ? Center(
                      child: _loadError == null
                          ? const CircularProgressIndicator(
                              color: AppColors.secondaryTeal,
                            )
                          : Text(_loadError!, style: handoverText(context, 13.5)),
                    )
                  : ListView(
                      padding: ResponsiveHelper.getResponsivePadding(
                        context,
                        horizontal: 16,
                        vertical: 14,
                      ),
                      children: _body(context, a),
                    ),
            ),
            if (a != null) _footer(context, a),
          ],
        ),
      ),
    );
  }

  List<Widget> _body(BuildContext context, EmergencyAlert a) {
    const gap = SizedBox(height: 16);
    return [
      if (_actionError != null) ...[
        Container(
          key: const ValueKey('emergency-detail-error'),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.criticalBackgroundSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            _actionError!,
            style: handoverText(context, 13.5, color: AppColors.criticalRed),
          ),
        ),
        gap,
      ],
      Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          AttendancePill(
            label: EmergencyLabels.status(a.status),
            tone: EmergencyLabels.statusTone(a.status),
            dot: true,
          ),
          if (a.priority != null)
            AttendancePill(
              label: EmergencyLabels.priority(a.priority!),
              tone: EmergencyLabels.priorityTone(a.priority!),
            ),
        ],
      ),
      gap,
      _Section(
        title: 'What was reported',
        children: [
          Text(
            a.note ?? 'No description was given.',
            style: handoverText(context, 13.5),
          ),
          const SizedBox(height: 10),
          _Field('Raised by', a.raiser?.name ?? 'Unknown'),
          _Field('Resident', a.clientName ?? 'Not about a resident'),
          _Field('Where in the building', a.locationNote),
          _Field('Assigned to', a.assignee?.name ?? 'Nobody yet'),
          _Field('House line', a.residenceEmergencyPhone),
          _Field("Reporter's phone", a.raiser?.phone),
        ],
      ),
      gap,
      _Section(
        title: 'Response',
        children: [
          for (final action in a.actions) _ActionRow(action: action),
        ],
      ),
      if (a.attachments.isNotEmpty) ...[
        gap,
        _Section(
          title: 'Attachments',
          children: [
            for (final file in a.attachments)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(9),
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: file.fileUrl));
                    AppSnackbar.show('Link copied', file.fileName);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.description_outlined,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            file.fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: handoverText(context, 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
      if (!a.isClosed) ...[
        gap,
        _Section(
          title: 'Add to the response',
          children: [
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _note,
              builder: (context, value, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HandoverTextArea(
                    key: const ValueKey('emergency-note'),
                    label: 'Note',
                    controller: _note,
                    placeholder: 'What you found, what you did…',
                  ),
                  const SizedBox(height: 8),
                  HandoverButton(
                    key: const ValueKey('emergency-add-note'),
                    label: 'Add note',
                    compact: true,
                    onPressed: _saving || value.text.trim().isEmpty
                        ? null
                        : () => _act(
                              () => _c.addNote(a.id, value.text.trim()),
                              onDone: _note.clear,
                            ),
                  ),
                ],
              ),
            ),
            if (_c.canRespond) ...[
              const SizedBox(height: 14),
              HandoverSelect(
                key: const ValueKey('emergency-hand-to'),
                label: 'Hand it to',
                value: _c.responders
                    .where((r) => r.id == _assignee)
                    .map((r) => r.label)
                    .firstOrNull,
                placeholder: 'Choose who is going',
                helper:
                    'The person who saw the alarm is often not the person who can go',
                onTap: () async {
                  final picked = await pickHandoverOption(
                    context,
                    title: 'Hand it to',
                    options: [for (final r in _c.responders) (r.id, r.label)],
                    selected: _assignee,
                  );
                  if (picked != null) setState(() => _assignee = picked);
                },
              ),
              const SizedBox(height: 8),
              HandoverButton(
                key: const ValueKey('emergency-assign'),
                label: 'Assign',
                icon: Icons.how_to_reg_outlined,
                compact: true,
                onPressed: _saving || _assignee == null
                    ? null
                    : () => _act(
                          () => _c.assign(a.id, _assignee!),
                          onDone: () => _assignee = null,
                        ),
              ),
            ],
          ],
        ),
      ],
    ];
  }

  Widget _footer(BuildContext context, EmergencyAlert a) {
    final canAct = _c.canRespond && !a.isClosed;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: [
          HandoverButton(
            label: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
          if (canAct && a.status != 'in_progress')
            HandoverButton(
              key: const ValueKey('emergency-on-it'),
              label: 'I am on it',
              onPressed: _saving ? null : () => _act(() => _c.markInProgress(a.id)),
            ),
          if (canAct)
            HandoverButton(
              key: const ValueKey('emergency-detail-resolve'),
              label: 'Resolve',
              filled: true,
              onPressed: () {
                Navigator.of(context).pop();
                _c.resolve(a);
              },
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;

  const _Header({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.criticalBackgroundSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.crisis_alert_rounded,
              size: 20,
              color: AppColors.criticalRed,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: handoverText(context, 16, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: handoverText(context, 13, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return HandoverPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: handoverText(context, 14, weight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String? value;

  const _Field(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final v = value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: handoverText(
              context,
              11,
              weight: FontWeight.w600,
              color: AppColors.textMuted,
            ).copyWith(letterSpacing: 0.6),
          ),
          const SizedBox(height: 2),
          Text(
            v == null || v.isEmpty ? '—' : v,
            style: handoverText(context, 13),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final EmergencyAction action;

  const _ActionRow({required this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                EmergencyLabels.action(action.action),
                style: handoverText(
                  context,
                  12.5,
                  weight: FontWeight.w600,
                  color: AppColors.primaryNavy,
                ),
              ),
              Text(
                '${action.actorName ?? 'Unknown'} · '
                '${WebFormat.dateTime(action.createdAt, empty: '')}',
                style: handoverText(context, 11.5, color: AppColors.textMuted),
              ),
              if (action.targetName != null)
                AttendancePill(
                  label: '→ ${action.targetName}',
                  tone: AttendanceTone.info,
                ),
            ],
          ),
          if (action.note != null) ...[
            const SizedBox(height: 4),
            Text(action.note!, style: handoverText(context, 13)),
          ],
        ],
      ),
    );
  }
}
