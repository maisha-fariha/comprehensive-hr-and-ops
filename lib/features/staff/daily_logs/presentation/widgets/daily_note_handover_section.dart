import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';

/// "Handover Note" block + teal "Submit Note" CTA. Submitting posts the
/// daily-log entry and a separate shift handover.
class DailyNoteHandoverSection extends StatelessWidget {
  final VoidCallback? onSubmit;
  final TextEditingController controller;

  const DailyNoteHandoverSection({
    super.key,
    required this.controller,
    this.onSubmit,
  });

  static const int _maxChars = 250;
  static const Color _ink = Color(0xFF1A2533);
  static const Color _muted = Color(0xFF94A3B8);
  static const Color _submit = Color(0xFF16807D);

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 18);
    final fieldHeight = ResponsiveHelper.getResponsiveHeight(context, 140);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Handover Note',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                  color: _ink,
                  height: 1.2,
                ),
              ),
            ),
            Text(
              'for next shift',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w400,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                color: _muted,
                height: 1.2,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        Container(
          width: double.infinity,
          height: fieldHeight,
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 16,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowNavy.withValues(alpha: 0.05),
                offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 3)),
                blurRadius: ResponsiveHelper.getResponsiveHeight(context, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLength: _maxChars,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w500,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    color: _ink,
                    height: 1.4,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                    contentPadding: EdgeInsets.zero,
                    counterText: '',
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) {
                    return Text(
                      '${value.text.length}/$_maxChars',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w400,
                        fontSize:
                            ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                        color: _muted,
                        height: 1.2,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
        GestureDetector(
          onTap: onSubmit ?? Get.back,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              minHeight: ResponsiveHelper.getResponsiveHeight(context, 54),
            ),
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              vertical: 15,
              horizontal: 16,
            ),
            decoration: BoxDecoration(
              color: _submit,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 16),
              ),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_rounded,
                  size: ResponsiveHelper.getResponsiveSize(context, 20),
                  color: Colors.white,
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                Flexible(
                  child: Text(
                    'Submit Note',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15.5),
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
