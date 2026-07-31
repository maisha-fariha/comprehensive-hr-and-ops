import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../staff_tasks_messages_constants.dart';

/// Small avatar + animated "..." bubble shown at the bottom of the thread
/// while the other participant is typing.
class TypingIndicator extends StatefulWidget {
  final String contactInitials;

  const TypingIndicator({super.key, required this.contactInitials});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatarSize = ResponsiveHelper.getResponsiveSize(context, StaffTasksMessagesDimens.avatarSizeSmall);

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: const BoxDecoration(color: AppColors.infoIconBackground, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            widget.contactInitials,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 9.5),
              color: AppColors.infoBlue,
            ),
          ),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
        Container(
          padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: StaffTasksMessagesColors.incomingBubbleBackground,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(ResponsiveHelper.getResponsiveRadius(context, 16)),
              topRight: Radius.circular(ResponsiveHelper.getResponsiveRadius(context, 16)),
              bottomRight: Radius.circular(ResponsiveHelper.getResponsiveRadius(context, 16)),
              bottomLeft: Radius.circular(ResponsiveHelper.getResponsiveRadius(context, 4)),
            ),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  final t = (_controller.value - (index * 0.2)) % 1.0;
                  final opacity = 0.3 + 0.7 * (t < 0.5 ? t * 2 : (1 - t) * 2);
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveHelper.getResponsiveWidth(context, 2),
                    ),
                    child: Opacity(
                      opacity: opacity.clamp(0.3, 1.0),
                      child: Container(
                        width: ResponsiveHelper.getResponsiveSize(context, 6),
                        height: ResponsiveHelper.getResponsiveSize(context, 6),
                        decoration: const BoxDecoration(color: AppColors.textMuted, shape: BoxShape.circle),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }
}
