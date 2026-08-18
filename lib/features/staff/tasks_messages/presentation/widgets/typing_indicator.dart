import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

/// Small avatar + animated "..." bubble shown at the bottom of the thread
/// while the other participant is typing.
class TypingIndicator extends StatefulWidget {
  final String contactInitials;

  static const Color _avatarBg = Color(0xFFE3ECF9);
  static const Color _avatarFg = Color(0xFF4775C5);
  static const Color _dotColor = Color(0xFFB0BCC6);

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
    final avatarSize = ResponsiveHelper.getResponsiveSize(context, 28);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 999);

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: const BoxDecoration(
            color: TypingIndicator._avatarBg,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            widget.contactInitials,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
              color: TypingIndicator._avatarFg,
              height: 1,
            ),
          ),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
        Container(
          padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 12,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  final t = (_controller.value - (index * 0.2)) % 1.0;
                  final opacity = 0.35 + 0.65 * (t < 0.5 ? t * 2 : (1 - t) * 2);
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveHelper.getResponsiveWidth(context, 2.5),
                    ),
                    child: Opacity(
                      opacity: opacity.clamp(0.35, 1.0),
                      child: Container(
                        width: ResponsiveHelper.getResponsiveSize(context, 6),
                        height: ResponsiveHelper.getResponsiveSize(context, 6),
                        decoration: const BoxDecoration(
                          color: TypingIndicator._dotColor,
                          shape: BoxShape.circle,
                        ),
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
