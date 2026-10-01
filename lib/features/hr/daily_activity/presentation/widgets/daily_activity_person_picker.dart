import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/daily_activity.dart';
import '../daily_activity_labels.dart';
import 'daily_activity_common.dart';

/// Web searchable picker: type to filter, the choice shows as "Selected"
/// with an X to change it.
class DailyActivityPersonPicker extends StatefulWidget {
  final String label;
  final bool required;
  final List<DailyActivityOption> options;
  final String? value;
  final String? error;
  final ValueChanged<DailyActivityOption?> onSelect;

  const DailyActivityPersonPicker({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onSelect,
    this.required = false,
    this.error,
  });

  @override
  State<DailyActivityPersonPicker> createState() => _DailyActivityPersonPickerState();
}

class _DailyActivityPersonPickerState extends State<DailyActivityPersonPicker> {
  final _query = TextEditingController();
  final _focus = FocusNode();
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (_focus.hasFocus && !_open) setState(() => _open = true);
    });
  }

  @override
  void dispose() {
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  Widget _label(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text.rich(
          TextSpan(
            text: widget.label,
            children: [
              if (widget.required)
                const TextSpan(text: ' *', style: TextStyle(color: AppColors.criticalRed)),
            ],
          ),
          style: handoverText(context, 13, weight: FontWeight.w500),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final selected = widget.options.where((o) => o.id == widget.value).firstOrNull;
    final lower = widget.label.toLowerCase();
    if (selected != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _label(context),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                DailyActivityInitials(
                  text: DailyActivityLabels.initials(selected.name),
                  size: 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selected.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: handoverText(
                          context,
                          13.5,
                          weight: FontWeight.w600,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      if (selected.subtitle.isNotEmpty)
                        Text(
                          selected.subtitle,
                          style: handoverText(context, 11.5, color: AppColors.textMuted),
                        ),
                    ],
                  ),
                ),
                const DailyActivityPill(label: 'Selected', tone: DailyActivityTone.success),
                IconButton(
                  tooltip: 'Change ${widget.label}',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    _query.clear();
                    setState(() => _open = false);
                    widget.onSelect(null);
                  },
                  icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final q = _query.text.trim().toLowerCase();
    final matches = widget.options.where((o) => o.name.toLowerCase().contains(q)).toList();
    final error = widget.error;
    final border = error == null ? AppColors.searchBorder : AppColors.criticalRed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label(context),
        TextField(
          controller: _query,
          focusNode: _focus,
          onTap: () => setState(() => _open = true),
          onChanged: (_) => setState(() => _open = true),
          style: handoverText(context, 13.5),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Search $lower...',
            hintStyle: handoverText(context, 13.5, color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surfaceWhite,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: BorderSide(color: border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: BorderSide(color: border),
            ),
          ),
        ),
        if (_open)
          Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 260),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: matches.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'No matches found',
                      textAlign: TextAlign.center,
                      style: handoverText(context, 12.5, color: AppColors.textMuted),
                    ),
                  )
                : ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(6),
                    children: [
                      for (final o in matches)
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            _query.clear();
                            _focus.unfocus();
                            setState(() => _open = false);
                            widget.onSelect(o);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: Row(
                              children: [
                                DailyActivityInitials(
                                  text: DailyActivityLabels.initials(o.name),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        o.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: handoverText(context, 13, weight: FontWeight.w500),
                                      ),
                                      if (o.subtitle.isNotEmpty)
                                        Text(
                                          o.subtitle,
                                          style: handoverText(
                                            context,
                                            11.5,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        const SizedBox(height: 5),
        Text(
          error ?? 'Type to search $lower',
          style: handoverText(
            context,
            12,
            color: error == null ? AppColors.textMuted : AppColors.criticalRed,
          ),
        ),
      ],
    );
  }
}
