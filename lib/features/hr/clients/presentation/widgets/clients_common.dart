import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/offline/offline_image.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../clients_labels.dart';

class ClientPill extends StatelessWidget {
  final String label;
  final ClientTone tone;
  final IconData? icon;

  const ClientPill({super.key, required this.label, required this.tone, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: tone.foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: handoverText(context, 11, weight: FontWeight.w600, color: tone.foreground),
          ),
        ],
      ),
    );
  }
}

Widget clientFieldLabel(BuildContext context, String label, {bool required = false}) =>
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

Widget clientFieldHelper(BuildContext context, {String? helper, String? error}) {
  final text = error ?? helper;
  if (text == null) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(top: 5),
    child: Text(
      text,
      style: handoverText(
        context,
        12,
        color: error != null ? AppColors.criticalRed : AppColors.textMuted,
      ),
    ),
  );
}

OutlineInputBorder _border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide(color: color),
    );

/// Labelled text input / textarea (the web `TextInput` / `Textarea`).
class ClientInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? placeholder;
  final String? helper;
  final String? error;
  final bool required;
  final bool enabled;
  final int lines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const ClientInput({
    super.key,
    required this.label,
    required this.controller,
    this.placeholder,
    this.helper,
    this.error,
    this.required = false,
    this.enabled = true,
    this.lines = 1,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        clientFieldLabel(context, label, required: required),
        TextField(
          controller: controller,
          enabled: enabled,
          minLines: lines,
          maxLines: lines == 1 ? 1 : lines + 3,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: handoverText(context, 13.5),
          decoration: InputDecoration(
            isDense: true,
            hintText: placeholder,
            hintStyle: handoverText(context, 13.5, color: AppColors.textMuted),
            filled: true,
            fillColor: enabled ? AppColors.surfaceWhite : AppColors.filterButtonBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            border: _border(AppColors.searchBorder),
            enabledBorder: _border(error == null ? AppColors.searchBorder : AppColors.criticalRed),
            disabledBorder: _border(AppColors.searchBorder),
            focusedBorder: _border(AppColors.secondaryTeal),
          ),
        ),
        clientFieldHelper(context, helper: helper, error: error),
      ],
    );
  }
}

/// Labelled select opening a bottom-sheet list of `(value, label)`.
class ClientSelect extends StatelessWidget {
  final String label;
  final String value;
  final List<(String, String)> options;
  final String placeholder;
  final String? helper;
  final String? error;
  final bool required;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  const ClientSelect({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.placeholder,
    this.helper,
    this.error,
    this.required = false,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    String? shown;
    for (final (id, text) in options) {
      if (id == value) shown = text;
    }
    if (shown == null && value.isNotEmpty) shown = value;
    final active = enabled && onChanged != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        clientFieldLabel(context, label, required: required),
        Opacity(
          opacity: active ? 1 : 0.6,
          child: InkWell(
            borderRadius: BorderRadius.circular(9),
            onTap: !active
                ? null
                : () async {
                    final picked = await pickHandoverOption(
                      context,
                      title: label,
                      options: options,
                      selected: value,
                    );
                    if (picked != null) onChanged!(picked);
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: active ? AppColors.surfaceWhite : AppColors.filterButtonBackground,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: error == null ? AppColors.searchBorder : AppColors.criticalRed,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      shown ?? placeholder,
                      style: handoverText(
                        context,
                        13.5,
                        color: shown == null ? AppColors.textMuted : AppColors.textHeading,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        clientFieldHelper(context, helper: helper, error: error),
      ],
    );
  }
}

/// Date-only field (`YYYY-MM-DD`) opening the platform picker.
class ClientDateField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String>? onChanged;
  final String? error;
  final bool required;
  final bool enabled;
  final DateTime? lastDate;

  const ClientDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.error,
    this.required = false,
    this.enabled = true,
    this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    final current = ClientsLabels.parseDateInput(value);
    final active = enabled && onChanged != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        clientFieldLabel(context, label, required: required),
        Opacity(
          opacity: active ? 1 : 0.6,
          child: InkWell(
            borderRadius: BorderRadius.circular(9),
            onTap: !active
                ? null
                : () async {
                    final last = lastDate ?? DateTime(2100);
                    final initial = current ?? (lastDate ?? DateTime.now());
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: initial.isAfter(last) ? last : initial,
                      firstDate: DateTime(1900),
                      lastDate: last,
                    );
                    if (picked != null) onChanged!(ClientsLabels.dateInput(picked));
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: active ? AppColors.surfaceWhite : AppColors.filterButtonBackground,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: error == null ? AppColors.searchBorder : AppColors.criticalRed,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      current == null ? 'Pick a date' : ClientsLabels.date(current),
                      style: handoverText(
                        context,
                        13.5,
                        color: current == null ? AppColors.textMuted : AppColors.textHeading,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        clientFieldHelper(context, error: error),
      ],
    );
  }
}

/// The web `SwitchField`: label, description and a switch.
class ClientSwitchTile extends StatelessWidget {
  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool bordered;

  const ClientSwitchTile({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
    this.bordered = false,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: handoverText(context, 13.5, weight: FontWeight.w600)),
              if (description != null) ...[
                const SizedBox(height: 2),
                Text(
                  description!,
                  style: handoverText(context, 12, color: AppColors.textMuted),
                ),
              ],
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: AppColors.surfaceWhite,
          activeTrackColor: AppColors.secondaryTeal,
          onChanged: onChanged,
        ),
      ],
    );
    if (!bordered) return row;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: row,
    );
  }
}

/// The web `TagInput`: type a value, press Enter to add; chips remove.
class ClientTagInput extends StatefulWidget {
  final String label;
  final String placeholder;
  final String? helper;
  final List<String> values;
  final ValueChanged<List<String>>? onChanged;

  const ClientTagInput({
    super.key,
    required this.label,
    required this.placeholder,
    required this.values,
    required this.onChanged,
    this.helper,
  });

  @override
  State<ClientTagInput> createState() => _ClientTagInputState();
}

class _ClientTagInputState extends State<ClientTagInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.values.contains(text)) {
      _controller.clear();
      return;
    }
    widget.onChanged?.call([...widget.values, text]);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onChanged != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        clientFieldLabel(context, widget.label),
        if (widget.values.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final v in widget.values)
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 4, 6, 4),
                  decoration: BoxDecoration(
                    color: AppColors.filterButtonBackground,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(v, style: handoverText(context, 12.5, weight: FontWeight.w500)),
                      if (enabled) ...[
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => widget.onChanged!(
                            widget.values.where((e) => e != v).toList(),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        if (enabled)
          TextField(
            controller: _controller,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _add(),
            style: handoverText(context, 13.5),
            decoration: InputDecoration(
              isDense: true,
              hintText: widget.placeholder,
              hintStyle: handoverText(context, 13.5, color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surfaceWhite,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              border: _border(AppColors.searchBorder),
              enabledBorder: _border(AppColors.searchBorder),
              focusedBorder: _border(AppColors.secondaryTeal),
              suffixIcon: IconButton(
                onPressed: _add,
                icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.secondaryTeal),
              ),
            ),
          )
        else if (widget.values.isEmpty)
          Text('—', style: handoverText(context, 13.5, color: AppColors.textMuted)),
        clientFieldHelper(context, helper: widget.helper),
      ],
    );
  }
}

/// The web numbered list editor ("Add Goal" / "Add Outcome").
class ClientListEditor extends StatelessWidget {
  final String label;
  final String addLabel;
  final List<TextEditingController> items;
  final VoidCallback? onChanged;

  const ClientListEditor({
    super.key,
    required this.label,
    required this.addLabel,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        clientFieldLabel(context, label),
        for (var i = 0; i < items.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.filterButtonBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Text('${i + 1}', style: handoverText(context, 11, weight: FontWeight.w600)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: items[i],
                    enabled: enabled,
                    style: handoverText(context, 13),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (enabled)
                  IconButton(
                    tooltip: 'Remove item ${i + 1}',
                    onPressed: () {
                      items.removeAt(i).dispose();
                      onChanged!();
                    },
                    icon: const Icon(Icons.close_rounded, size: 14, color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
        if (enabled)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                items.add(TextEditingController());
                onChanged!();
              },
              icon: const Icon(Icons.add_rounded, size: 14, color: AppColors.secondaryTeal),
              label: Text(
                addLabel,
                style: handoverText(
                  context,
                  12.5,
                  weight: FontWeight.w600,
                  color: AppColors.secondaryTeal,
                ),
              ),
            ),
          )
        else if (items.isEmpty)
          Text('—', style: handoverText(context, 13.5, color: AppColors.textMuted)),
      ],
    );
  }
}

/// The web `FileUpload` (one file).
class ClientFileField extends StatelessWidget {
  final String label;
  final String hint;
  final String? fileName;
  final String? existingUrl;
  final VoidCallback? onPick;
  final VoidCallback? onClear;
  final IconData icon;

  const ClientFileField({
    super.key,
    required this.label,
    required this.hint,
    required this.onPick,
    this.fileName,
    this.existingUrl,
    this.onClear,
    this.icon = Icons.cloud_upload_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final hasExisting = existingUrl != null && existingUrl!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        clientFieldLabel(context, label),
        InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.searchBorder),
            ),
            child: Row(
              children: [
                if (hasExisting && fileName == null)
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.filterButtonBackground,
                    backgroundImage: OfflineImage.provider(existingUrl!),
                    onBackgroundImageError: (_, _) {},
                  )
                else
                  Icon(icon, size: 22, color: AppColors.secondaryTeal),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName ?? (onPick == null ? 'No file' : 'Tap to choose a file'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: handoverText(context, 13.5, weight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(hint, style: handoverText(context, 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                if (fileName != null && onClear != null)
                  IconButton(
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The web `FormSectionHeader`.
class ClientSectionHeader extends StatelessWidget {
  final String title;
  final String description;
  final Widget? trailing;

  const ClientSectionHeader({
    super.key,
    required this.title,
    required this.description,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: handoverText(context, 16, weight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(description, style: handoverText(context, 13, color: AppColors.textMuted)),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class ClientBanner extends StatelessWidget {
  final String message;
  final bool warning;

  const ClientBanner(this.message, {super.key, this.warning = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: warning ? AppColors.urgentBackground : AppColors.criticalBackgroundSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message,
        style: handoverText(
          context,
          13,
          color: warning ? AppColors.urgentAmber : AppColors.criticalRed,
        ),
      ),
    );
  }
}

/// Bottom-sheet shell matching the web modal: icon header, optional status
/// bar, scrolling body and a right-aligned footer.
class ClientSheetFrame extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final Widget? statusBar;
  final Widget? top;
  final List<Widget> children;
  final Widget? footerLeft;
  final List<Widget> footer;
  final bool tall;
  final ScrollController? scrollController;

  const ClientSheetFrame({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
    required this.footer,
    this.description,
    this.statusBar,
    this.top,
    this.footerLeft,
    this.tall = true,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final body = ListView(
      controller: scrollController,
      shrinkWrap: !tall,
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 16, vertical: 14),
      children: children,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: tall ? media.size.height * 0.94 : null,
          constraints: BoxConstraints(maxHeight: media.size.height * 0.94),
          decoration: const BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: tall ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Container(
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
                      decoration: const BoxDecoration(
                        color: AppColors.quickActionCreateShiftBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 19, color: AppColors.secondaryTeal),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: handoverText(context, 16, weight: FontWeight.w600)),
                          if (description != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              description!,
                              style: handoverText(context, 13, color: AppColors.textMuted),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              ?statusBar,
              ?top,
              if (tall) Expanded(child: body) else Flexible(child: body),
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + media.padding.bottom),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.cardBorder)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (footerLeft != null) ...[footerLeft!, const SizedBox(height: 8)],
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: footer,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grey info strip under a modal header.
class ClientStatusBar extends StatelessWidget {
  final InlineSpan text;

  const ClientStatusBar(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: const BoxDecoration(
        color: AppColors.scaffoldBackground,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textMuted),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              text,
              style: handoverText(context, 12, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

Future<T?> showClientSheet<T>(BuildContext context, Widget sheet) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => sheet,
    );

/// After the next frame, scrolls the first of [fieldKeys] found under
/// [context] into view (the web `scrollToFirstError`).
void scrollToFirstField(BuildContext context, Iterable<Key> fieldKeys) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    for (final key in fieldKeys) {
      Element? found;
      void visit(Element element) {
        if (found != null) return;
        if (element.widget.key == key) {
          found = element;
          return;
        }
        element.visitChildElements(visit);
      }

      context.visitChildElements(visit);
      final target = found;
      if (target != null) {
        Scrollable.ensureVisible(
          target,
          alignment: 0.1,
          duration: const Duration(milliseconds: 250),
        );
        return;
      }
    }
  });
}

/// Filled red / teal confirm button.
class ClientToneButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final IconData? icon;

  const ClientToneButton({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.55 : 1,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 15, color: AppColors.surfaceWhite),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: handoverText(
                    context,
                    13.5,
                    weight: FontWeight.w600,
                    color: AppColors.surfaceWhite,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The web `ConfirmDialog` (danger tone). Resolves to true when confirmed.
Future<bool> confirmClientAction(
  BuildContext context, {
  required String title,
  required String description,
  required String confirmLabel,
  required Key confirmKey,
  Widget? extra,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surfaceWhite,
      title: Text(title, style: handoverText(dialogContext, 17, weight: FontWeight.w700)),
      content: extra == null
          ? Text(
              description,
              style: handoverText(dialogContext, 13.5, color: AppColors.textSecondary),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    description,
                    style: handoverText(dialogContext, 13.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  extra,
                ],
              ),
            ),
      actions: [
        HandoverButton(
          label: 'Cancel',
          onPressed: () => Navigator.of(dialogContext).pop(false),
        ),
        ClientToneButton(
          key: confirmKey,
          label: confirmLabel,
          color: AppColors.criticalRed,
          onPressed: () => Navigator.of(dialogContext).pop(true),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// Horizontal step navigator (the web vertical `Stepper`).
class ClientStepChips extends StatelessWidget {
  final List<(String id, String label, String description, bool completed)> steps;
  final String current;
  final ValueChanged<String> onTap;

  const ClientStepChips({
    super.key,
    required this.steps,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          for (final (id, label, description, completed) in steps)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                key: ValueKey('client-step-$id'),
                borderRadius: BorderRadius.circular(10),
                onTap: () => onTap(id),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 7, 12, 7),
                  decoration: BoxDecoration(
                    color: id == current ? AppColors.filterButtonBackground : AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: id == current ? AppColors.textHeading : AppColors.cardBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: id == current
                              ? const Color(0xFF1E3A5F)
                              : completed
                                  ? const Color(0xFFE9F5EE)
                                  : const Color(0xFFEEF1F5),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Icon(
                          completed && id != current ? Icons.check_rounded : Icons.circle,
                          size: completed && id != current ? 15 : 7,
                          color: id == current
                              ? AppColors.surfaceWhite
                              : completed
                                  ? const Color(0xFF2E8C58)
                                  : const Color(0xFF6B7C93),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: handoverText(context, 12.5, weight: FontWeight.w600)),
                          Text(
                            description,
                            style: handoverText(context, 11, color: AppColors.textMuted),
                          ),
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
}

/// The web completion card: an uppercase caption, a progress bar and a line.
class ClientProgressCard extends StatelessWidget {
  final String caption;
  final String? trailing;
  final double fraction;
  final String line;
  final bool lineAccent;

  const ClientProgressCard({
    super.key,
    required this.caption,
    required this.fraction,
    required this.line,
    this.trailing,
    this.lineAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    final captionStyle = handoverText(
      context,
      11,
      weight: FontWeight.w600,
      color: AppColors.textMuted,
    ).copyWith(letterSpacing: 0.5);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(caption.toUpperCase(), style: captionStyle)),
              if (trailing != null) Text(trailing!.toUpperCase(), style: captionStyle),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: fraction.clamp(0, 1),
              minHeight: 6,
              backgroundColor: AppColors.filterButtonBackground,
              color: AppColors.secondaryTeal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            line,
            style: handoverText(
              context,
              11,
              weight: lineAccent ? FontWeight.w600 : FontWeight.w500,
              color: lineAccent ? AppColors.secondaryTeal : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
