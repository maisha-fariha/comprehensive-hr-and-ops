import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/communication_enums.dart';

class NewConversationResult {
  final ConversationFilter type;
  final String recipientQuery;
  final String firstMessage;

  const NewConversationResult({
    required this.type,
    required this.recipientQuery,
    required this.firstMessage,
  });
}

/// Modal matching the "New Conversation" reference.
Future<NewConversationResult?> showNewConversationDialog(
  BuildContext context,
) {
  return showDialog<NewConversationResult>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (context) => const NewConversationDialog(),
  );
}

class NewConversationDialog extends StatefulWidget {
  const NewConversationDialog({super.key});

  @override
  State<NewConversationDialog> createState() => _NewConversationDialogState();
}

class _NewConversationDialogState extends State<NewConversationDialog> {
  ConversationFilter _type = ConversationFilter.direct;
  late final TextEditingController _recipientController;
  late final TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _recipientController = TextEditingController();
    _messageController = TextEditingController();
    _recipientController.addListener(_onChanged);
    _messageController.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _recipientController
      ..removeListener(_onChanged)
      ..dispose();
    _messageController
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  bool get _canStart => _recipientController.text.trim().isNotEmpty;

  String get _recipientLabel => switch (_type) {
        ConversationFilter.direct => 'Staff member',
        ConversationFilter.group => 'Residence',
        ConversationFilter.family => 'Family contact',
        ConversationFilter.all => 'Recipient',
      };

  String get _recipientHint => switch (_type) {
        ConversationFilter.direct => 'Search by name or role...',
        ConversationFilter.group => 'Search residences...',
        ConversationFilter.family => 'Search family contacts...',
        ConversationFilter.all => 'Search...',
      };

  void _submit() {
    if (!_canStart) return;
    Navigator.of(context).pop(
      NewConversationResult(
        type: _type,
        recipientQuery: _recipientController.text.trim(),
        firstMessage: _messageController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return Dialog(
      insetPadding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 20,
        vertical: 24,
      ),
      backgroundColor: AppColors.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 24),
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(onClose: () => Navigator.of(context).pop()),
            const Divider(height: 1, color: AppColors.cardBorder),
            Flexible(
              child: SingleChildScrollView(
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 20,
                  vertical: 18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Conversation Type',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          13,
                        ),
                        color: AppColors.textHeading,
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 10),
                    ),
                    _TypeCard(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Direct',
                      subtitle: 'One person, staff to staff',
                      selected: _type == ConversationFilter.direct,
                      onTap: () => setState(() {
                        _type = ConversationFilter.direct;
                        _recipientController.clear();
                      }),
                    ),
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 10),
                    ),
                    _TypeCard(
                      icon: Icons.groups_outlined,
                      title: 'Group',
                      subtitle: 'Everyone posted to a home',
                      selected: _type == ConversationFilter.group,
                      onTap: () => setState(() {
                        _type = ConversationFilter.group;
                        _recipientController.clear();
                      }),
                    ),
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 10),
                    ),
                    _TypeCard(
                      icon: Icons.favorite_border_rounded,
                      title: 'Family',
                      subtitle: 'A relative and the office',
                      selected: _type == ConversationFilter.family,
                      onTap: () => setState(() {
                        _type = ConversationFilter.family;
                        _recipientController.clear();
                      }),
                    ),
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 18),
                    ),
                    Text(
                      _recipientLabel,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          13,
                        ),
                        color: AppColors.textHeading,
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 8),
                    ),
                    _OutlinedField(
                      controller: _recipientController,
                      hint: _recipientHint,
                      prefixIcon: Icons.search_rounded,
                    ),
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 16),
                    ),
                    Text(
                      'First message (optional)',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          13,
                        ),
                        color: AppColors.textHeading,
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 8),
                    ),
                    _OutlinedField(
                      controller: _messageController,
                      hint:
                          'Type a message to send right away, or leave blank to start an empty conversation...',
                      minLines: 4,
                      maxLines: 6,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.cardBorder),
            Padding(
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                horizontal: 20,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _FooterButton(
                      label: 'Cancel',
                      filled: false,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                  SizedBox(
                    width: ResponsiveHelper.getResponsiveWidth(context, 10),
                  ),
                  Expanded(
                    flex: 2,
                    child: _FooterButton(
                      label: 'Start Conversation',
                      filled: true,
                      enabled: _canStart,
                      icon: Icons.add_comment_outlined,
                      onTap: _canStart ? _submit : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onClose;

  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 20,
        top: 18,
        bottom: 16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: ResponsiveHelper.getResponsiveSize(context, 44),
            height: ResponsiveHelper.getResponsiveSize(context, 44),
            decoration: BoxDecoration(
              color: AppColors.secondaryTeal,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 12),
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.add_comment_outlined,
              size: ResponsiveHelper.getResponsiveSize(context, 22),
              color: Colors.white,
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Conversation',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 18),
                    color: AppColors.textHeading,
                  ),
                ),
                SizedBox(
                  height: ResponsiveHelper.getResponsiveHeight(context, 4),
                ),
                Text(
                  'Start a direct message, a residence group, or a family thread.',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          Material(
            color: AppColors.filterButtonBackground,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onClose,
              child: SizedBox(
                width: ResponsiveHelper.getResponsiveSize(context, 34),
                height: ResponsiveHelper.getResponsiveSize(context, 34),
                child: Icon(
                  Icons.close_rounded,
                  size: ResponsiveHelper.getResponsiveSize(context, 18),
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFE8F4F3) : AppColors.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
        side: BorderSide(
          color: selected ? AppColors.secondaryTeal : AppColors.searchBorder,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
        child: Stack(
          children: [
            Padding(
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                horizontal: 14,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: ResponsiveHelper.getResponsiveSize(context, 22),
                    color: selected
                        ? AppColors.secondaryTeal
                        : AppColors.textMuted,
                  ),
                  SizedBox(
                    width: ResponsiveHelper.getResponsiveWidth(context, 12),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              14,
                            ),
                            color: AppColors.textHeading,
                          ),
                        ),
                        SizedBox(
                          height: ResponsiveHelper.getResponsiveHeight(
                            context,
                            2,
                          ),
                        ),
                        Text(
                          subtitle,
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
                ],
              ),
            ),
            if (selected)
              Positioned(
                top: ResponsiveHelper.getResponsiveHeight(context, 10),
                right: ResponsiveHelper.getResponsiveWidth(context, 10),
                child: Container(
                  width: ResponsiveHelper.getResponsiveSize(context, 22),
                  height: ResponsiveHelper.getResponsiveSize(context, 22),
                  decoration: const BoxDecoration(
                    color: AppColors.secondaryTeal,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: ResponsiveHelper.getResponsiveSize(context, 14),
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OutlinedField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? prefixIcon;
  final int minLines;
  final int maxLines;

  const _OutlinedField({
    required this.controller,
    required this.hint,
    this.prefixIcon,
    this.minLines = 1,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
        border: Border.all(color: AppColors.searchBorder),
      ),
      child: TextField(
        controller: controller,
        minLines: minLines,
        maxLines: maxLines,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
          color: AppColors.textHeading,
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: 'Outfit',
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
            color: AppColors.textPlaceholder,
            height: 1.35,
          ),
          prefixIcon: prefixIcon == null
              ? null
              : Icon(
                  prefixIcon,
                  size: ResponsiveHelper.getResponsiveSize(context, 20),
                  color: AppColors.textMuted,
                ),
          contentPadding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  final String label;
  final bool filled;
  final bool enabled;
  final IconData? icon;
  final VoidCallback? onTap;

  const _FooterButton({
    required this.label,
    required this.filled,
    this.enabled = true,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background = !filled
        ? AppColors.surfaceWhite
        : (enabled ? AppColors.primaryNavy : const Color(0xFF90A4AE));
    final foreground = filled ? Colors.white : AppColors.textHeading;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(
        ResponsiveHelper.getResponsiveRadius(context, 12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
        child: Container(
          alignment: Alignment.center,
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 12,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveRadius(context, 12),
            ),
            border: filled ? null : Border.all(color: AppColors.searchBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: ResponsiveHelper.getResponsiveSize(context, 16),
                  color: foreground,
                ),
                SizedBox(
                  width: ResponsiveHelper.getResponsiveWidth(context, 6),
                ),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 13),
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
