import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/communication_enums.dart';
import '../../domain/entities/hr_conversation.dart';

class ConversationsPanel extends StatelessWidget {
  final List<HrConversation> conversations;
  final String? selectedId;
  final int activeCount;
  final int unreadCount;
  final ConversationFilter selectedFilter;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<ConversationFilter> onFilterSelected;
  final ValueChanged<String> onConversationTap;
  final VoidCallback? onComposeTap;
  final VoidCallback? onMarkAllRead;

  const ConversationsPanel({
    super.key,
    required this.conversations,
    required this.selectedId,
    required this.activeCount,
    required this.unreadCount,
    required this.selectedFilter,
    required this.searchController,
    required this.onSearchChanged,
    required this.onFilterSelected,
    required this.onConversationTap,
    this.onComposeTap,
    this.onMarkAllRead,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 16),
        ),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: 16,
              top: 16,
              bottom: 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Conversations',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            16,
                          ),
                          color: AppColors.textHeading,
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveHeight(context, 2),
                      ),
                      Text(
                        '$activeCount active · $unreadCount unread',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w400,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            12,
                          ),
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onComposeTap,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'New conversation',
                  icon: Icon(
                    Icons.edit_square,
                    size: ResponsiveHelper.getResponsiveSize(context, 20),
                    color: AppColors.textMuted,
                  ),
                ),
                if (onMarkAllRead != null)
                  IconButton(
                    onPressed: onMarkAllRead,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Mark all read',
                    icon: Icon(
                      Icons.done_all_rounded,
                      size: ResponsiveHelper.getResponsiveSize(context, 20),
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: 16,
            ),
            child: _SearchField(
              controller: searchController,
              onChanged: onSearchChanged,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: 16,
            ),
            child: Row(
              children: [
                for (final filter in ConversationFilter.values) ...[
                  _FilterChip(
                    label: switch (filter) {
                      ConversationFilter.all => 'All',
                      ConversationFilter.direct => 'Direct',
                      ConversationFilter.group => 'Group',
                      ConversationFilter.family => 'Family',
                    },
                    selected: selectedFilter == filter,
                    onTap: () => onFilterSelected(filter),
                  ),
                  if (filter != ConversationFilter.values.last)
                    SizedBox(
                      width: ResponsiveHelper.getResponsiveWidth(context, 8),
                    ),
                ],
              ],
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
          if (conversations.isEmpty)
            Padding(
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                all: 20,
              ),
              child: Text(
                'No conversations match your filters.',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            for (final conversation in conversations)
              _ConversationRow(
                conversation: conversation,
                selected: conversation.id == selectedId,
                onTap: () => onConversationTap(conversation.id),
              ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.filterButtonBackground,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
        border: Border.all(color: AppColors.searchBorder),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
          color: AppColors.textHeading,
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: 'Search conversations',
          hintStyle: TextStyle(
            fontFamily: 'Outfit',
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
            color: AppColors.textPlaceholder,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: ResponsiveHelper.getResponsiveSize(context, 20),
            color: AppColors.textMuted,
          ),
          contentPadding: ResponsiveHelper.getResponsivePadding(
            context,
            vertical: 12,
            right: 12,
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryNavy : AppColors.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 999),
        ),
        side: BorderSide(
          color: selected ? AppColors.primaryNavy : AppColors.searchBorder,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 999),
        ),
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 14,
            vertical: 8,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
              color: selected ? Colors.white : AppColors.textHeading,
            ),
          ),
        ),
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  final HrConversation conversation;
  final bool selected;
  final VoidCallback onTap;

  const _ConversationRow({
    required this.conversation,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFEAF2FB) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 16,
            vertical: 12,
          ),
          child: Row(
            children: [
              Container(
                width: ResponsiveHelper.getResponsiveSize(context, 40),
                height: ResponsiveHelper.getResponsiveSize(context, 40),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFD7E6F7)
                      : const Color(0xFFE8F3F2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  conversation.isGroup
                      ? Icons.groups_rounded
                      : Icons.person_rounded,
                  size: ResponsiveHelper.getResponsiveSize(context, 20),
                  color: selected
                      ? AppColors.infoBlue
                      : AppColors.secondaryTeal,
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          13.5,
                        ),
                        color: AppColors.textHeading,
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 2),
                    ),
                    Text(
                      conversation.preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w400,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          12.5,
                        ),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    conversation.dateLabel,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w400,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        11,
                      ),
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (conversation.unreadCount > 0) ...[
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 6),
                    ),
                    Container(
                      padding: ResponsiveHelper.getResponsivePadding(
                        context,
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryTeal,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${conversation.unreadCount}',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            10.5,
                          ),
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
