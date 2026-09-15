import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/conversation_preview.dart';
import 'conversation_row_tile.dart';

/// Body of the "Messages" tab: title, actions, conversation cards.
class MessagesTabView extends StatelessWidget {
  final List<ConversationPreview> conversations;
  final ValueChanged<ConversationPreview>? onConversationTap;
  final VoidCallback? onNewMessage;
  final VoidCallback? onMarkAllRead;

  static const Color _titleColor = Color(0xFF1A2B48);

  const MessagesTabView({
    super.key,
    required this.conversations,
    this.onConversationTap,
    this.onNewMessage,
    this.onMarkAllRead,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Messages',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 16),
                  color: _titleColor,
                  height: 1.2,
                ),
              ),
            ),
            if (onMarkAllRead != null)
              TextButton(
                onPressed: onMarkAllRead,
                child: const Text('Mark all read'),
              ),
            if (onNewMessage != null)
              TextButton(
                onPressed: onNewMessage,
                child: const Text('New'),
              ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        if (conversations.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveHelper.getResponsiveHeight(context, 24),
            ),
            child: const Text(
              'No conversations yet.',
              style: TextStyle(
                fontFamily: 'Outfit',
                color: AppColors.textMuted,
              ),
            ),
          )
        else
          for (var i = 0; i < conversations.length; i++) ...[
            if (i > 0)
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
            ConversationRowTile(
              conversation: conversations[i],
              onTap: onConversationTap == null
                  ? null
                  : () => onConversationTap!(conversations[i]),
            ),
          ],
      ],
    );
  }
}
