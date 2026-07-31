import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../domain/entities/family_messages_enums.dart';
import 'attachment_option_tile.dart';

/// Row of 3 equal-width [AttachmentOptionTile]s: Photo, PDF and Document.
class AttachmentOptionsRow extends StatelessWidget {
  final Set<MessageAttachmentType> selected;
  final ValueChanged<MessageAttachmentType> onToggle;

  const AttachmentOptionsRow({super.key, required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10));

    return Row(
      children: [
        for (final type in MessageAttachmentType.values) ...[
          if (type != MessageAttachmentType.values.first) gap,
          Expanded(
            child: AttachmentOptionTile(
              type: type,
              selected: selected.contains(type),
              onTap: () => onToggle(type),
            ),
          ),
        ],
      ],
    );
  }
}
