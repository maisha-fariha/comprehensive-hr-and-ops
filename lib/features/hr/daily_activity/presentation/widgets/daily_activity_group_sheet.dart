import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/formatting/web_formats.dart';
import '../../../../../core/media/app_file_picker.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/daily_activity.dart';
import '../controllers/daily_activity_controller.dart';
import '../daily_activity_labels.dart';

/// Activity types that default "Share with family" on (web `en` Set).
const _shareByDefault = {
  'personal_activity',
  'family_memory',
  'care_activity',
  'school',
  'program',
  'work',
  'other',
};

Future<bool?> showDailyActivityGroupSheet(
  BuildContext context, {
  required DailyActivityController controller,
}) {
  return showAppBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (_) => DailyActivityGroupSheet(controller: controller),
  );
}

class DailyActivityGroupSheet extends StatefulWidget {
  final DailyActivityController controller;

  const DailyActivityGroupSheet({super.key, required this.controller});

  @override
  State<DailyActivityGroupSheet> createState() => _DailyActivityGroupSheetState();
}

class _DailyActivityGroupSheetState extends State<DailyActivityGroupSheet> {
  final _description = TextEditingController();
  final _selected = <String>{};
  final _notes = <String, TextEditingController>{};
  final _files = <DailyActivityLocalFile>[];
  String _type = 'personal_activity';
  String _status = 'completed';
  late DateTime _date;
  TimeOfDay? _time;
  bool? _shareWithFamily;
  String? _banner;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _description.dispose();
    for (final c in _notes.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _shareChecked => _shareWithFamily ?? _shareByDefault.contains(_type);

  void _toggleClient(DailyActivityOption client) {
    setState(() {
      if (_selected.contains(client.id)) {
        _selected.remove(client.id);
        _notes.remove(client.id)?.dispose();
      } else {
        _selected.add(client.id);
        _notes[client.id] = TextEditingController();
      }
    });
  }

  Future<void> _pickPhotos() async {
    final picked = await AppFilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: true,
    );
    if (picked == null || !mounted) return;
    setState(() {
      for (final file in picked.files) {
        final path = file.path;
        if (path == null) continue;
        if (file.size > 10 * 1024 * 1024) continue;
        _files.add(DailyActivityLocalFile(path: path, name: file.name));
      }
    });
  }

  Future<void> _submit() async {
    setState(() => _banner = null);
    if (_selected.length < 2) {
      setState(() => _banner =
          'Choose at least two residents — one resident is an ordinary activity.');
      return;
    }
    if (_description.text.trim().isEmpty) {
      setState(() => _banner = 'Say what the group did.');
      return;
    }
    setState(() => _saving = true);
    DateTime? occurredAt;
    if (_time != null) {
      occurredAt = DateTime(
        _date.year,
        _date.month,
        _date.day,
        _time!.hour,
        _time!.minute,
      );
    }
    final draft = DailyActivityBatchDraft(
      clientIds: _selected.toList(),
      activityDate: DailyActivityLabels.ymd(_date),
      activityType: _type,
      status: _status,
      description: _description.text.trim(),
      occurredAt: occurredAt,
      shareWithFamily: _shareChecked,
      individualNotes: {
        for (final id in _selected)
          if ((_notes[id]?.text ?? '').trim().isNotEmpty)
            id: _notes[id]!.text.trim(),
      },
    );
    final error = await widget.controller.saveBatch(draft, files: _files);
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      setState(() => _banner = error);
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final clients = widget.controller.clients.toList();
    const gap = SizedBox(height: 18);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_saving) Navigator.of(context).pop(false);
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: MediaQuery.sizeOf(context).height * 0.94,
            decoration: const BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                _header(context),
                Expanded(
                  child: ListView(
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      horizontal: 16,
                      vertical: 14,
                    ),
                    children: [
                      if (_banner != null) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.criticalBackgroundSoft,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.criticalRed.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                size: 16,
                                color: AppColors.criticalRed,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _banner!,
                                  style: handoverText(
                                    context,
                                    12.5,
                                    color: AppColors.criticalRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        gap,
                      ],
                      _fieldLabel(context, 'Residents', required: true),
                      if (clients.isEmpty)
                        Text(
                          'No residents available for this filter.',
                          style: handoverText(context, 13, color: AppColors.textMuted),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final c in clients)
                              _ResidentChip(
                                label: c.name,
                                selected: _selected.contains(c.id),
                                onTap: _saving ? null : () => _toggleClient(c),
                              ),
                          ],
                        ),
                      if (_selected.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${_selected.length} selected',
                          style: handoverText(context, 12, color: AppColors.textMuted),
                        ),
                      ],
                      gap,
                      _select(
                        context: context,
                        label: 'Activity Type',
                        options: DailyActivityLabels.types,
                        value: _type,
                        onChanged: (v) => setState(() => _type = v),
                      ),
                      gap,
                      _select(
                        context: context,
                        label: 'How it went',
                        options: DailyActivityLabels.statuses,
                        value: _status,
                        onChanged: (v) => setState(() => _status = v),
                      ),
                      gap,
                      _area(
                        context: context,
                        label: 'What the group did',
                        required: true,
                        controller: _description,
                        placeholder: 'e.g. Morning trip to the botanical gardens',
                      ),
                      gap,
                      _dateField(context),
                      gap,
                      _timeField(context),
                      gap,
                      _shareTile(context),
                      gap,
                      _photos(context),
                      if (_selected.isNotEmpty) ...[
                        gap,
                        Text(
                          'A note for one resident (optional)',
                          style: handoverText(context, 13, weight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        for (final id in _selected) ...[
                          _area(
                            context: context,
                            label: _clientName(clients, id),
                            controller: _notes[id]!,
                            placeholder: "Only on this resident's record",
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                _footer(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _clientName(List<DailyActivityOption> clients, String id) {
    for (final c in clients) {
      if (c.id == id) return c.name;
    }
    return id;
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondaryTeal,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.groups_rounded,
              size: 20,
              color: AppColors.surfaceWhite,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Record a group activity',
                  style: handoverText(context, 16, weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  'One activity for several residents, saved together.',
                  style: handoverText(context, 12.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        children: [
          HandoverButton(
            label: 'Cancel',
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          ),
          HandoverButton(
            label: _saving
                ? 'Saving…'
                : 'Save for ${_selected.isEmpty ? 'the' : _selected.length} residents',
            filled: true,
            onPressed: _saving ? null : _submit,
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(BuildContext context, String label, {bool required = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text.rich(
          TextSpan(
            text: label,
            children: [
              if (required)
                const TextSpan(text: ' *', style: TextStyle(color: AppColors.criticalRed)),
            ],
          ),
          style: handoverText(context, 13, weight: FontWeight.w500),
        ),
      );

  Widget _hint(BuildContext context, String? helper) {
    if (helper == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Text(helper, style: handoverText(context, 12, color: AppColors.textMuted)),
    );
  }

  Widget _box({
    required Key key,
    required String text,
    required bool empty,
    required IconData icon,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      key: key,
      onTap: _saving ? null : onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.searchBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: handoverText(
                  context,
                  13.5,
                  color: empty ? AppColors.textMuted : AppColors.textHeading,
                ),
              ),
            ),
            if (trailing != null) trailing,
            Icon(icon, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _select({
    required BuildContext context,
    required String label,
    required List<(String, String)> options,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    final current = options.where((o) => o.$1 == value).map((o) => o.$2).firstOrNull ??
        DailyActivityLabels.humanise(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel(context, label, required: true),
        _box(
          key: ValueKey('group-$label'),
          text: current,
          empty: false,
          icon: Icons.keyboard_arrow_down_rounded,
          onTap: () async {
            final picked = await pickHandoverOption(
              context,
              title: label,
              options: options,
              selected: value,
            );
            if (picked != null) onChanged(picked);
          },
        ),
      ],
    );
  }

  Widget _area({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required String placeholder,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel(context, label, required: required),
        TextField(
          controller: controller,
          minLines: 3,
          maxLines: 6,
          enabled: !_saving,
          style: handoverText(context, 13.5),
          decoration: InputDecoration(
            isDense: true,
            hintText: placeholder,
            hintStyle: handoverText(context, 13.5, color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surfaceWhite,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: AppColors.searchBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: AppColors.searchBorder),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: AppColors.searchBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: AppColors.secondaryTeal),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dateField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel(context, 'Date', required: true),
        _box(
          key: const ValueKey('group-date'),
          text: WebFormat.date(_date),
          empty: false,
          icon: Icons.calendar_today_outlined,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _date,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) setState(() => _date = picked);
          },
        ),
      ],
    );
  }

  Widget _timeField(BuildContext context) {
    final t = _time;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel(context, 'Time'),
        _box(
          key: const ValueKey('group-time'),
          text: t == null
              ? '--:--'
              : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
          empty: t == null,
          icon: Icons.access_time_rounded,
          trailing: t == null
              ? null
              : IconButton(
                  tooltip: 'Clear time',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 20),
                  onPressed: () => setState(() => _time = null),
                  icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                ),
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: _time ?? TimeOfDay.now(),
            );
            if (picked != null) setState(() => _time = picked);
          },
        ),
        _hint(context, 'Optional — without it the record is placed to the day'),
      ],
    );
  }

  Widget _shareTile(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.searchBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share with family',
                  style: handoverText(context, 13.5, weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  "Appears in each resident's family daily updates, with the photos.",
                  style: handoverText(context, 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _shareChecked,
            activeThumbColor: AppColors.secondaryTeal,
            onChanged: _saving
                ? null
                : (v) => setState(() => _shareWithFamily = v),
          ),
        ],
      ),
    );
  }

  Widget _photos(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel(context, 'Photos (Optional)'),
        Text(
          'Shared by everybody in the group',
          style: handoverText(context, 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _saving ? null : _pickPhotos,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.searchBorder, width: 1.5),
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.quickActionCreateShiftBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 20,
                    color: AppColors.secondaryTeal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add photos',
                  style: handoverText(context, 14, weight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'JPG, PNG or WEBP · up to 10MB each',
                  style: handoverText(context, 11.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
        for (final file in _files)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.image_outlined, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: handoverText(context, 13),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove',
                  visualDensity: VisualDensity.compact,
                  onPressed: _saving
                      ? null
                      : () => setState(() => _files.remove(file)),
                  icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ResidentChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _ResidentChip({
    required this.label,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.secondaryTeal.withValues(alpha: 0.12)
          : AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.secondaryTeal : AppColors.searchBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check_rounded, size: 14, color: AppColors.secondaryTeal),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: handoverText(
                  context,
                  12.5,
                  weight: FontWeight.w600,
                  color: selected ? AppColors.secondaryTeal : AppColors.textHeading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
