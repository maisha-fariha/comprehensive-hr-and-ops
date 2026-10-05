import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../../recurring_checks/presentation/widgets/check_common.dart';
import '../../domain/entities/daily_log.dart';
import '../controllers/daily_logs_controller.dart';
import '../daily_logs_labels.dart';
import 'daily_log_common.dart';

/// Header, scrolling body and a custom footer, as the web modals.
class DailyLogSheet extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<Widget> children;
  final List<Widget> footer;
  final Widget? footerLeading;

  const DailyLogSheet({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.children,
    required this.footer,
    this.footerLeading,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.92),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.activeBackground,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, size: 18, color: AppColors.primaryNavy),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: handoverText(context, 17, weight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: handoverText(context, 13, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.cardBorder),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0) const SizedBox(height: 16),
                    children[i],
                  ],
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.cardBorder),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Row(
                  children: [
                    if (footerLeading != null) Expanded(child: footerLeading!) else const Spacer(),
                    for (var i = 0; i < footer.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      footer[i],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bordered, titled block inside a detail sheet ("Entry", "Observations").
class DailyLogBlock extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const DailyLogBlock({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: handoverText(context, 14, weight: FontWeight.w700)),
          const SizedBox(height: 10),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            children[i],
          ],
        ],
      ),
    );
  }
}

// ── Entry detail ─────────────────────────────────────────────────────────

Future<void> showEntryDetailSheet(
  BuildContext context, {
  required DailyLogsController controller,
  required String entryId,
}) =>
    showCheckSheet<void>(
      context,
      (_) => _EntryDetailSheet(controller: controller, entryId: entryId, host: context),
    );

class _EntryDetailSheet extends StatefulWidget {
  final DailyLogsController controller;
  final String entryId;
  final BuildContext host;

  const _EntryDetailSheet({
    required this.controller,
    required this.entryId,
    required this.host,
  });

  @override
  State<_EntryDetailSheet> createState() => _EntryDetailSheetState();
}

class _EntryDetailSheetState extends State<_EntryDetailSheet> {
  DailyLogEntry? _entry;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    widget.controller.entry(widget.entryId).then((result) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        result.when(success: (e) => _entry = e, failure: (e) => _error = e.message);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final e = _entry;
    final c = widget.controller;
    return DailyLogSheet(
      icon: Icons.edit_note_rounded,
      title: 'Log entry',
      description: e == null ? 'Loading…' : DailyLogLabels.dateTime(e.at),
      footer: [
        HandoverButton(
          key: const ValueKey('dl-detail-close'),
          label: 'Close',
          onPressed: () => Navigator.of(context).pop(),
        ),
        if (c.canWrite && e != null && !e.isSuperseded)
          HandoverButton(
            key: const ValueKey('dl-detail-amend'),
            label: 'Amend',
            icon: Icons.edit_outlined,
            filled: true,
            onPressed: () {
              Navigator.of(context).pop();
              if (widget.host.mounted) {
                showAmendEntrySheet(widget.host, controller: c, entry: e);
              }
            },
          ),
      ],
      children: [
        if (_loading)
          for (var i = 0; i < 3; i++)
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.filterButtonBackground,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
        if (_error != null) DailyLogFormError(_error!),
        if (e != null) ..._body(context, e),
      ],
    );
  }

  List<Widget> _body(BuildContext context, DailyLogEntry e) {
    final observations = e.observations.entries
        .where((o) => o.value != null && o.value != '' && o.value != false)
        .toList();
    final chain = e.amendmentChain;
    Widget grid(List<Widget> cells) => Wrap(
          runSpacing: 10,
          children: [
            for (final cell in cells)
              FractionallySizedBox(widthFactor: 0.5, child: cell),
          ],
        );
    return [
      Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          if (e.shift != null) DailyLogPill(e.shift!),
          if (e.logType != null)
            DailyLogPill(DailyLogLabels.camel(e.logType!), tone: DailyLogTone.info),
          if (e.isSuperseded) const DailyLogPill('Superseded', tone: DailyLogTone.warning),
          if (e.amendsEntryId != null) const DailyLogPill('Correction', tone: DailyLogTone.info),
          if (e.flag case final flag?)
            DailyLogPill(
              '${flag.category}${flag.resolvedAt != null ? ' · resolved' : ' · open'}',
              tone: flag.resolvedAt != null ? DailyLogTone.neutral : DailyLogTone.danger,
            ),
        ],
      ),
      DailyLogBlock(
        title: 'Entry',
        children: [
          Text(e.body, style: handoverText(context, 13.5)),
          grid([
            DailyLogDetail('Author', e.authorName ?? 'Unknown'),
            DailyLogDetail('Occurred at', DailyLogLabels.dateTime(e.occurredAt)),
            DailyLogDetail('Written at', DailyLogLabels.dateTime(e.createdAt)),
            DailyLogDetail('Reminder', DailyLogLabels.dateTime(e.remindAt)),
          ]),
          if (e.amendmentReason != null)
            DailyLogDetail('Reason for correction', e.amendmentReason),
        ],
      ),
      DailyLogBlock(
        title: 'Observations',
        children: [
          if (observations.isEmpty)
            Text(
              'Nothing was graded on this entry.',
              style: handoverText(context, 13, color: AppColors.textMuted),
            )
          else
            grid([
              for (final o in observations)
                DailyLogDetail(
                  DailyLogLabels.camel(o.key),
                  o.value == true ? 'Yes' : DailyLogLabels.camel('${o.value}'),
                ),
            ]),
        ],
      ),
      DailyLogBlock(
        title: 'Checks',
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              DailyLogPill(
                'Wellness check ${e.wellnessCheckCompleted == true ? 'completed' : 'not completed'}',
                tone: e.wellnessCheckCompleted == true ? DailyLogTone.success : DailyLogTone.warning,
              ),
              DailyLogPill(
                'Bed check ${e.bedCheckCompleted == true ? 'completed' : 'not completed'}',
                tone: e.bedCheckCompleted == true ? DailyLogTone.success : DailyLogTone.warning,
              ),
            ],
          ),
        ],
      ),
      if (e.flag case final flag?)
        DailyLogBlock(
          title: 'Flag',
          children: [
            DailyLogDetail('Category', DailyLogLabels.camel(flag.category)),
            DailyLogDetail('Note', flag.note ?? ''),
            DailyLogDetail('Raised', DailyLogLabels.dateTime(flag.raisedAt)),
            DailyLogDetail(
              'Resolved',
              flag.resolvedAt != null ? DailyLogLabels.dateTime(flag.resolvedAt) : 'Still open',
            ),
          ],
        ),
      if (e.attachments.isNotEmpty)
        DailyLogBlock(
          title: 'Attachments',
          children: [
            for (final a in e.attachments)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.description_outlined, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        a.fileName,
                        overflow: TextOverflow.ellipsis,
                        style: handoverText(context, 13),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      if (chain.length > 1)
        DailyLogBlock(
          title: 'Correction history',
          children: [
            for (var i = 0; i < chain.length; i++)
              Container(
                key: ValueKey('dl-chain-${chain[i].id}'),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: chain[i].id == e.id
                      ? AppColors.secondaryTeal.withValues(alpha: 0.05)
                      : null,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: chain[i].id == e.id
                        ? AppColors.secondaryTeal.withValues(alpha: 0.4)
                        : AppColors.cardBorder,
                  ),
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
                          i == 0 ? 'Original' : 'Correction $i',
                          style: handoverText(context, 12, weight: FontWeight.w600, color: AppColors.primaryNavy),
                        ),
                        Text(
                          '${chain[i].authorName ?? 'Unknown'} · '
                          '${DailyLogLabels.dateTime(chain[i].createdAt)}',
                          style: handoverText(context, 11.5, color: AppColors.textMuted),
                        ),
                        if (chain[i].id == e.id)
                          const DailyLogPill('This entry', tone: DailyLogTone.info),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(chain[i].body, style: handoverText(context, 13)),
                    if (chain[i].amendmentReason != null)
                      Text(
                        'Reason: ${chain[i].amendmentReason}',
                        style: handoverText(context, 12, color: AppColors.textMuted),
                      ),
                  ],
                ),
              ),
          ],
        ),
    ];
  }
}

// ── Amend ────────────────────────────────────────────────────────────────

Future<void> showAmendEntrySheet(
  BuildContext context, {
  required DailyLogsController controller,
  required DailyLogEntry entry,
}) =>
    showCheckSheet<void>(context, (_) => _AmendSheet(controller: controller, entry: entry));

class _AmendSheet extends StatefulWidget {
  final DailyLogsController controller;
  final DailyLogEntry entry;

  const _AmendSheet({required this.controller, required this.entry});

  @override
  State<_AmendSheet> createState() => _AmendSheetState();
}

class _AmendSheetState extends State<_AmendSheet> {
  final _body = TextEditingController();
  final _reason = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _body.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (_body.text.trim().isEmpty || _reason.text.trim().isEmpty) {
      setState(() => _error = 'Both the corrected entry and a reason are required.');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.controller.amendEntry(widget.entry, _body.text.trim(), _reason.text.trim());
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DailyLogSheet(
      icon: Icons.edit_outlined,
      title: 'Amend entry',
      description: 'The original stays on the record; this correction is added beside it.',
      footer: [
        HandoverButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
        HandoverButton(
          key: const ValueKey('dl-amend-save'),
          label: _saving ? 'Saving…' : 'Save correction',
          filled: true,
          onPressed: _saving ? null : _save,
        ),
      ],
      children: [
        if (_error != null) DailyLogFormError(_error!),
        DailyLogQuote(caption: 'Original entry', text: widget.entry.body),
        HandoverTextArea(
          key: const ValueKey('dl-amend-body'),
          label: 'Corrected entry',
          required: true,
          controller: _body,
          placeholder: 'What should the record say?',
        ),
        HandoverTextArea(
          key: const ValueKey('dl-amend-reason'),
          label: 'Reason for the correction',
          required: true,
          controller: _reason,
          placeholder: 'Why is this being amended?',
        ),
      ],
    );
  }
}

// ── Delete ───────────────────────────────────────────────────────────────

Future<void> confirmDeleteEntry(
  BuildContext context, {
  required DailyLogsController controller,
  required DailyLogEntry entry,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surfaceWhite,
      title: Text(
        'Delete this entry?',
        style: handoverText(dialogContext, 17, weight: FontWeight.w700),
      ),
      content: Text(
        "It leaves the day's log. A correction to a note is an amendment, not this — "
        'what was written is kept either way, so it can be restored.',
        style: handoverText(dialogContext, 13.5, color: AppColors.textSecondary),
      ),
      actions: [
        HandoverButton(label: 'Cancel', onPressed: () => Navigator.of(dialogContext).pop(false)),
        Material(
          color: AppColors.criticalRed,
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
            key: const ValueKey('dl-delete-confirm'),
            borderRadius: BorderRadius.circular(9),
            onTap: () => Navigator.of(dialogContext).pop(true),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                'Delete',
                style: handoverText(
                  dialogContext,
                  13.5,
                  weight: FontWeight.w600,
                  color: AppColors.surfaceWhite,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
  if (confirmed == true) await controller.deleteEntry(entry);
}

// ── Resolve flag ─────────────────────────────────────────────────────────

Future<void> showResolveFlagSheet(
  BuildContext context, {
  required DailyLogsController controller,
  required CareFlag flag,
}) =>
    showCheckSheet<void>(context, (_) => _ResolveFlagSheet(controller: controller, flag: flag));

class _ResolveFlagSheet extends StatefulWidget {
  final DailyLogsController controller;
  final CareFlag flag;

  const _ResolveFlagSheet({required this.controller, required this.flag});

  @override
  State<_ResolveFlagSheet> createState() => _ResolveFlagSheetState();
}

class _ResolveFlagSheetState extends State<_ResolveFlagSheet> {
  final _note = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _resolve() async {
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await widget.controller.resolveFlag(widget.flag, _note.text);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.flag;
    return DailyLogSheet(
      icon: Icons.done_all_rounded,
      title: 'Resolve flag',
      description: 'Say what was done about it — the flag stays on the record with your note.',
      footer: [
        HandoverButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
        HandoverButton(
          key: const ValueKey('dl-resolve-save'),
          label: _saving ? 'Resolving…' : 'Resolve',
          filled: true,
          onPressed: _saving ? null : _resolve,
        ),
      ],
      children: [
        if (_error != null) DailyLogFormError(_error!),
        DailyLogQuote(
          caption: f.category,
          text: f.note ?? f.source?.excerpt ?? 'No note was left.',
        ),
        HandoverTextArea(
          key: const ValueKey('dl-resolve-note'),
          label: 'What was done',
          controller: _note,
          placeholder: 'e.g. GP called, review booked for Thursday',
        ),
      ],
    );
  }
}
