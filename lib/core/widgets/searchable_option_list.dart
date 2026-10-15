import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Shared dropdown list: a search field filters [options] by label and subtitle.
///
/// Every option sheet in the app should use this so a long list can be searched
/// the same way.
class SearchableOptionList<T> extends StatefulWidget {
  final String title;
  final List<T> options;
  final String Function(T option) labelOf;
  final String Function(T option)? subtitleOf;
  final String Function(T option)? idOf;
  final String? selectedId;
  final bool Function(T option)? isSelected;
  final ValueChanged<T> onSelected;
  final bool showInitials;
  final String searchHint;

  const SearchableOptionList({
    super.key,
    required this.title,
    required this.options,
    required this.labelOf,
    required this.onSelected,
    this.subtitleOf,
    this.idOf,
    this.selectedId,
    this.isSelected,
    this.showInitials = false,
    this.searchHint = 'Search',
  });

  @override
  State<SearchableOptionList<T>> createState() => _SearchableOptionListState<T>();
}

class _SearchableOptionListState<T> extends State<SearchableOptionList<T>> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final visible = widget.options.where((option) {
      if (query.isEmpty) return true;
      final label = widget.labelOf(option).toLowerCase();
      final subtitle = widget.subtitleOf?.call(option).toLowerCase() ?? '';
      return label.contains(query) || subtitle.contains(query);
    }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.title,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.textHeading,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              color: AppColors.textHeading,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: widget.searchHint,
              hintStyle: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                color: AppColors.textMuted,
              ),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.filterButtonBackground,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.searchBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.searchBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.secondaryTeal),
              ),
            ),
          ),
        ),
        Flexible(
          child: visible.isEmpty
              ? const Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Text(
                    'No matches found',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final option = visible[index];
                    final label = widget.labelOf(option);
                    final subtitle = widget.subtitleOf?.call(option).trim() ?? '';
                    final selected = widget.isSelected?.call(option) ??
                        (widget.selectedId != null &&
                            widget.idOf != null &&
                            widget.idOf!(option) == widget.selectedId);
                    return ListTile(
                      leading: widget.showInitials
                          ? CircleAvatar(
                              radius: 16,
                              backgroundColor:
                                  AppColors.secondaryTeal.withValues(alpha: 0.12),
                              child: Text(
                                _initials(label),
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  color: AppColors.secondaryTeal,
                                ),
                              ),
                            )
                          : null,
                      title: Text(
                        label,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textHeading,
                        ),
                      ),
                      subtitle: subtitle.isEmpty
                          ? null
                          : Text(
                              subtitle,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                      trailing: selected
                          ? const Icon(
                              Icons.check_rounded,
                              color: AppColors.secondaryTeal,
                            )
                          : null,
                      onTap: () => widget.onSelected(option),
                    );
                  },
                ),
        ),
      ],
    );
  }

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final word = parts.first;
      return (word.length >= 2 ? word.substring(0, 2) : word).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
