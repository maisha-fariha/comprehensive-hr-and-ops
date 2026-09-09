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
    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 16,
        top: 12,
        bottom: 8,
      ),
      child: Column(
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
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 24),
                    color: AppColors.textHeading,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: AppColors.primaryNavy,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 10),
              ),
              child: InkWell(
                onTap: onNewConversation,
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveRadius(context, 10),
                ),
                child: Padding(
                  padding: ResponsiveHelper.getResponsivePadding(
                    context,
                    horizontal: 12,
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
                      SizedBox(
                        width: ResponsiveHelper.getResponsiveWidth(context, 4),
                      ),
                      Text(
                        'New conversation',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            12.5,
                          ),
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
