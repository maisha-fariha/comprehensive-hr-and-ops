import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';

class CommunicationHeader extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onNewConversation;

  const CommunicationHeader({
    super.key,
    this.onBack,
    this.onNewConversation,
  });

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 400;

    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 16,
        top: 12,
        bottom: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.arrow_back_rounded,
                  size: ResponsiveHelper.getResponsiveSize(context, 22),
                  color: AppColors.textHeading,
                ),
              ),
              Expanded(
                child: Text(
                  'Communication',
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 22),
                    color: AppColors.textHeading,
                    height: 1.2,
                  ),
                ),
              ),
              if (!narrow) ...[
                const SizedBox(width: 8),
                _NewConversationButton(
                  onTap: onNewConversation,
                  compact: false,
                ),
              ],
            ],
          ),
          if (narrow) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
            Align(
              alignment: Alignment.centerRight,
              child: _NewConversationButton(
                onTap: onNewConversation,
                compact: false,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NewConversationButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool compact;

  const _NewConversationButton({
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryNavy,
      borderRadius: BorderRadius.circular(
        ResponsiveHelper.getResponsiveRadius(context, 10),
      ),
      child: InkWell(
        key: const Key('communication-new-conversation'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 10),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: 10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                size: ResponsiveHelper.getResponsiveSize(context, 18),
                color: Colors.white,
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
              Text(
                compact ? 'New' : 'New conversation',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
