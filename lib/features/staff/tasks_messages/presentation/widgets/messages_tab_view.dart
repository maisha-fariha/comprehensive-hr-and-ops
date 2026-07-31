import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/widgets/section_header_row.dart';
import '../../domain/entities/conversation_preview.dart';
import 'conversation_row_tile.dart';

/// Body content of the "Messages" tab: a "Messages" section header followed
/// by the conversation list. Tapping a row is expected to navigate to the
/// Message Details (conversation thread) screen via [onConversationTap].
class MessagesTabView extends StatelessWidget {
  final List<ConversationPreview> conversations;
  final ValueChanged<ConversationPreview>? onConversationTap;

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
        const SectionHeaderRow(title: 'Messages'),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        for (final conversation in conversations) ...[
          ConversationRowTile(
            conversation: conversation,
            onTap: onConversationTap == null ? null : () => onConversationTap!(conversation),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        ],
      ],
    );
  }
}
