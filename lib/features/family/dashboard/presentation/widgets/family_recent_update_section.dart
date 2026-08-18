import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/family_recent_update.dart';

/// "Recent Update" heading + card for the Family Dashboard.
class FamilyRecentUpdateSection extends StatelessWidget {
  final FamilyRecentUpdate update;
  final VoidCallback? onTap;

  static const Color _titleColor = Color(0xFF1A2B48);
  static const Color _bodyColor = Color(0xFF3A4B60);
  static const Color _metaColor = Color(0xFF8A97A8);
  static const Color _headerStatusColor = Color(0xFF98A2B3);
  static const Color _mintBg = Color(0xFFE6F5F2);
  static const Color _mintFg = Color(0xFF0E7C7B);
  static const Color _approvedBg = Color(0xFFE6F3EC);
  static const Color _approvedFg = Color(0xFF027A48);
  static const Color _border = Color(0xFFEEF1F4);
  static const Color _shadow = Color(0xFF142846);

  static const String _checkAsset = 'assets/icons/family_core/check.svg';
  static const String _imageAsset = 'assets/icons/family_core/image.svg';

  const FamilyRecentUpdateSection({
    super.key,
    required this.update,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = ResponsiveHelper.getResponsiveSize(context, 42);
    final thumbSize = ResponsiveHelper.getResponsiveSize(context, 64);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 20);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Update',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                color: _titleColor,
                height: 1.2,
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            Text(
              update.statusLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                color: _headerStatusColor,
                height: 1.2,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: double.infinity,
            padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: _border),
              boxShadow: [
                BoxShadow(
                  color: _shadow.withValues(alpha: 0.04),
                  offset: Offset(
                    0,
                    ResponsiveHelper.getResponsiveHeight(context, 1),
                  ),
                  blurRadius: ResponsiveHelper.getResponsiveHeight(context, 1),
                ),
                BoxShadow(
                  color: _shadow.withValues(alpha: 0.05),
                  offset: Offset(
                    0,
                    ResponsiveHelper.getResponsiveHeight(context, 8),
                  ),
                  blurRadius: ResponsiveHelper.getResponsiveHeight(context, 16),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: const BoxDecoration(
                        color: _mintBg,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        update.authorInitials,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            13,
                          ),
                          color: _mintFg,
                          height: 1,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: ResponsiveHelper.getResponsiveWidth(context, 10),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            update.authorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w700,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                14.5,
                              ),
                              color: _titleColor,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(
                            height: ResponsiveHelper.getResponsiveHeight(
                              context,
                              2,
                            ),
                          ),
                          Text(
                            update.dateTimeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w400,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                12,
                              ),
                              color: _metaColor,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: ResponsiveHelper.getResponsiveWidth(context, 8),
                    ),
                    Container(
                      padding: ResponsiveHelper.getResponsivePadding(
                        context,
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _approvedBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppSvgIcon(
                            _checkAsset,
                            size: 12,
                          ),
                          SizedBox(
                            width: ResponsiveHelper.getResponsiveWidth(
                              context,
                              4,
                            ),
                          ),
                          Text(
                            update.statusLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w700,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                11,
                              ),
                              color: _approvedFg,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: ResponsiveHelper.getResponsiveHeight(context, 14),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        update.body,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w400,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            13.5,
                          ),
                          color: _bodyColor,
                          height: 1.45,
                        ),
                      ),
                    ),
                    if (update.hasImage) ...[
                      SizedBox(
                        width: ResponsiveHelper.getResponsiveWidth(context, 12),
                      ),
                      Container(
                        width: thumbSize,
                        height: thumbSize,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            stops: [0.0, 1.0],
                            colors: [Color(0xFFDCE9E3), Color(0xFFC6DED4)],
                          ),
                          borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getResponsiveRadius(context, 14),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const AppSvgIcon(_imageAsset, size: 24),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
