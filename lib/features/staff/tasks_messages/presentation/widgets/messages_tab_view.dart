import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../domain/entities/conversation_preview.dart';
import 'conversation_row_tile.dart';

/// Body of the "Messages" tab: title + conversation cards.
class MessagesTabView extends StatelessWidget {
  final List<ConversationPreview> conversations;
  final ValueChanged<ConversationPreview>? onConversationTap;

  static const Color _titleColor = Color(0xFF1A2B48);

  const MessagesTabView({
    super.key,
    required this.conversations,
    this.onConversationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Messages',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
            color: _titleColor,
            height: 1.2,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        for (var i = 0; i < conversations.length; i++) ...[
          if (i > 0) SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
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
