import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../common/inbox/domain/entities/portal_search_hit.dart';
import '../../../../common/inbox/presentation/pages/portal_notifications_page.dart';
import '../../../../common/inbox/presentation/pages/portal_search_page.dart';
import '../../../daily_logs/presentation/pages/daily_logs_page.dart';
import '../../../hr_shell.dart';
import '../../../medication/presentation/pages/medication_page.dart';
import '../../../profile_settings/presentation/pages/hr_profile_settings_page.dart';
import '../../../tasks_compliance/presentation/pages/tasks_compliance_page.dart';
import '../../../team_reports/presentation/pages/team_reports_page.dart';
import '../../domain/entities/attention_alert.dart';
import '../../domain/entities/dashboard_enums.dart';
import '../../domain/entities/dashboard_overview.dart';
import '../../domain/entities/overview_stat.dart';
import '../controllers/dashboard_controller.dart';

/// The Manager/HR Dashboard - "Home" tab of the HR portal.
///
/// Pixel-accurate reproduction of the reference Dashboard screen.
class ManagerDashboardPage extends StatelessWidget {
  const ManagerDashboardPage({super.key});

  DashboardController _resolveController() {
    try {
      return Get.find<DashboardController>();
    } catch (_) {
      return Get.put(GetIt.instance<DashboardController>(), permanent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolveController();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Obx(() {
        final response = controller.state.value;
        final overview = response.data;

        if (overview == null && controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.secondaryTeal),
          );
        }

        if (overview == null) {
          return _DashboardError(
            message: controller.errorMessage.value.isEmpty
                ? 'Something went wrong while loading the dashboard.'
                : controller.errorMessage.value,
            onRetry: controller.refresh,
          );
        }

        final horizontalPad = ResponsiveHelper.getResponsiveWidth(
          context,
          AppDimens.screenPaddingHorizontal,
        );
        final searchOverlap = ResponsiveHelper.getResponsiveHeight(
          context,
          AppDimens.searchBarOverlap,
        );

        return RefreshIndicator(
          color: AppColors.secondaryTeal,
          onRefresh: controller.refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _DashboardHeader(
                      overview: overview,
                      onNotificationsTap: () =>
                          Get.to(() => const PortalNotificationsPage()),
                      onAvatarTap: () =>
                          Get.to(() => const HrProfileSettingsPage()),
                    ),
                    Positioned(
                      left: horizontalPad,
                      right: horizontalPad,
                      bottom: -searchOverlap,
                      child: _DashboardSearchBar(
                        onTap: () => _openManagerSearch(),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPad,
                    searchOverlap + ResponsiveHelper.getResponsiveHeight(context, 18),
                    horizontalPad,
                    ResponsiveHelper.getResponsiveHeight(context, 24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (overview.attentionAlerts.isNotEmpty) ...[
                        _NeedsAttentionSection(alerts: overview.attentionAlerts),
                        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
                      ],
                      _TodaysOverviewSection(
                        stats: overview.overviewStats.take(4).toList(),
                        lastUpdatedLabel: overview.lastUpdatedLabel,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

void _openManagerSearch() {
  Get.to(
    () => PortalSearchPage(
      hint: 'Search staff, shifts, or incidents',
      emptyPrompt: 'Search the residence directory and records.',
      onHit: (hit) {
        Get.back();
        switch (hit.type) {
          case PortalSearchHitType.shift:
            Get.offAll(() => const HrShell(initialIndex: 1));
          case PortalSearchHitType.attendance:
          case PortalSearchHitType.staff:
            Get.offAll(() => const HrShell(initialIndex: 2));
          case PortalSearchHitType.incident:
            Get.offAll(() => const HrShell(initialIndex: 3));
          case PortalSearchHitType.task:
            Get.to(() => const TasksCompliancePage());
          case PortalSearchHitType.medication:
            Get.to(() => const MedicationPage());
          case PortalSearchHitType.client:
            Get.to(() => const DailyLogsPage());
          case PortalSearchHitType.message:
          case PortalSearchHitType.document:
            Get.to(() => const TeamReportsPage());
          case PortalSearchHitType.unknown:
            break;
        }
      },
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  final DashboardOverview overview;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onAvatarTap;

  const _DashboardHeader({
    required this.overview,
    this.onNotificationsTap,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.37, -0.93),
          end: Alignment(0.37, 0.93),
          stops: [0, 0.58, 1],
          colors: [
            AppColors.secondaryTeal,
            AppColors.secondaryTealDark,
            AppColors.secondaryTealDeep,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -ResponsiveHelper.getResponsiveHeight(context, 100),
            right: -ResponsiveHelper.getResponsiveWidth(context, 70),
            child: Container(
              width: ResponsiveHelper.getResponsiveSize(context, 230),
              height: ResponsiveHelper.getResponsiveSize(context, 230),
              decoration: const BoxDecoration(
                color: AppColors.whiteOpacity04,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                horizontal: 20,
                top: 8,
                bottom: 36,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _OrganizationSwitcher(name: overview.organizationName),
                      Spacer(),
                      _NotificationButton(
                        count: overview.unreadNotificationCount,
                        onTap: onNotificationsTap,
                      ),
                      SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
                      _AvatarButton(
                        initials: overview.avatarInitials,
                        onTap: onAvatarTap,
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
                  Text(
                    overview.dateLabel.toUpperCase().replaceAll('·', '•'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                      color: AppColors.whiteOpacity62,
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
                  Text(
                    overview.greetingLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 26),
                      color: Colors.white,
                      letterSpacing: -0.4,
                      height: 1.15,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
                  Text(
                    overview.greetingSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w400,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                      color: AppColors.whiteOpacity80,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrganizationSwitcher extends StatelessWidget {
  final String name;

  const _OrganizationSwitcher({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        left: 8,
        right: 12,
        top: 7,
        bottom: 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.whiteOpacity13,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 999),
        ),
        border: Border.all(color: AppColors.whiteOpacity16, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 2)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: ResponsiveHelper.getResponsiveSize(context, 28),
            height: ResponsiveHelper.getResponsiveSize(context, 28),
            decoration: BoxDecoration(
              color: AppColors.activeBackground,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 8),
              ),
            ),
            alignment: Alignment.center,
            child: const AppSvgIcon(
              AppAssets.homeSmall,
              size: 17,
              color: AppColors.secondaryTeal,
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                color: AppColors.surfaceWhite,
              ),
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
          const AppSvgIcon(
            AppAssets.chevronDown,
            size: 17,
            color: AppColors.whiteOpacity70,
          ),
        ],
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const _NotificationButton({required this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveHelper.getResponsiveSize(context, 42);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.whiteOpacity13,
              border: Border.all(color: AppColors.whiteOpacity16),
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 13),
              ),
            ),
            alignment: Alignment.center,
            child: const AppSvgIcon(AppAssets.bell, size: 20, color: Colors.white),
          ),
          if (count > 0)
            Positioned(
              top: -ResponsiveHelper.getResponsiveHeight(context, 4),
              right: -ResponsiveHelper.getResponsiveWidth(context, 5),
              child: Container(
                constraints: BoxConstraints(
                  minWidth: ResponsiveHelper.getResponsiveSize(context, 18),
                  minHeight: ResponsiveHelper.getResponsiveSize(context, 18),
                ),
                padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 4),
                decoration: BoxDecoration(
                  color: AppColors.criticalRed,
                  border: Border.all(
                    color: AppColors.secondaryTealDark,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  final String initials;
  final VoidCallback? onTap;

  const _AvatarButton({required this.initials, this.onTap});

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveHelper.getResponsiveSize(context, 42);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 2)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
          color: AppColors.secondaryTeal,
        ),
      ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search bar
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardSearchBar extends StatelessWidget {
  final VoidCallback? onTap;

  const _DashboardSearchBar({this.onTap});

  @override
  Widget build(BuildContext context) {
    final height = ResponsiveHelper.getResponsiveHeight(context, AppDimens.searchBarHeight);
    final filterSize = ResponsiveHelper.getResponsiveSize(context, 34);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(height / 4),
        border: Border.all(color: AppColors.searchBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowTeal.withValues(alpha: 0.14),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 12)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 28),
          ),
        ],
      ),
      padding: ResponsiveHelper.getResponsivePadding(context, left: 16, right: 10),
      child: Row(
        children: [
          const AppSvgIcon(AppAssets.search, size: 18, color: AppColors.textFaint),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
          Expanded(
            child: Text(
              'Search clients, documents, or medical records',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w400,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                color: AppColors.textPlaceholder,
              ),
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          Container(
            width: 1,
            height: ResponsiveHelper.getResponsiveHeight(context, 22),
            color: AppColors.dividerLight,
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          Container(
            width: filterSize,
            height: filterSize,
            decoration: BoxDecoration(
              color: AppColors.filterButtonBackground,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 10),
              ),
              border: Border.all(
                color: AppColors.secondaryTeal.withValues(alpha: 0.18),
              ),
            ),
            alignment: Alignment.center,
            child: const AppSvgIcon(
              AppAssets.filter,
              size: 16,
              color: AppColors.secondaryTeal,
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Needs Attention
// ─────────────────────────────────────────────────────────────────────────────

class _NeedsAttentionSection extends StatelessWidget {
  final List<AttentionAlert> alerts;

  const _NeedsAttentionSection({required this.alerts});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 20),
        ),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.04),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 1)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 1),
          ),
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.05),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 8)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 16),
          ),
        ],
      ),
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        left: 17,
        right: 17,
        top: 16,
        bottom: 6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: ResponsiveHelper.getResponsiveSize(context, 7),
                height: ResponsiveHelper.getResponsiveSize(context, 7),
                decoration: const BoxDecoration(
                  color: AppColors.criticalRed,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              Text(
                'Needs Attention',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              Container(
                constraints: BoxConstraints(
                  minWidth: ResponsiveHelper.getResponsiveSize(context, 19),
                  minHeight: ResponsiveHelper.getResponsiveSize(context, 19),
                ),
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.criticalBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${alerts.length}',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                    color: AppColors.criticalRed,
                    height: 1,
                  ),
                ),
              ),
              Spacer(),
              Text(
                'View all',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                  color: AppColors.secondaryTeal,
                ),
              ),
            ],
          ),
          for (var i = 0; i < alerts.length; i++)
            _AttentionAlertTile(
              alert: alerts[i],
              showDivider: i != alerts.length - 1,
            ),
        ],
      ),
    );
  }
}

class _AttentionAlertTile extends StatelessWidget {
  final AttentionAlert alert;
  final bool showDivider;

  const _AttentionAlertTile({
    required this.alert,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final isCritical = alert.severity == AlertSeverity.critical;
    final iconColor = isCritical ? AppColors.criticalRed : AppColors.urgentAmber;
    final iconBg =
        isCritical ? AppColors.criticalBackground : AppColors.urgentBackground;
    final badgeBg =
        isCritical ? AppColors.criticalBackgroundSoft : AppColors.urgentBackgroundSoft;
    final badgeLabel = isCritical ? 'Critical' : 'Urgent';
    final iconAsset = isCritical ? AppAssets.alertTriangle : AppAssets.clock;
    final iconBox = ResponsiveHelper.getResponsiveSize(context, 38);

    return Container(
      decoration: showDivider
          ? const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.dividerLight),
              ),
            )
          : null,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        top: 16,
        bottom: 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: iconBox,
            height: iconBox,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 11),
              ),
            ),
            alignment: Alignment.center,
            child: AppSvgIcon(iconAsset, size: 18, color: iconColor),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 11)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  alert.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                    color: AppColors.textPrimary,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                Text(
                  alert.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: AppColors.textMuted,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
          _StatusPill(
            label: badgeLabel,
            background: badgeBg,
            foreground: iconColor,
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          const AppSvgIcon(
            AppAssets.chevronRight,
            size: 18,
            color: AppColors.iconChevron,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Today's Overview
// ─────────────────────────────────────────────────────────────────────────────

class _TodaysOverviewSection extends StatelessWidget {
  final List<OverviewStat> stats;
  final String lastUpdatedLabel;

  const _TodaysOverviewSection({
    required this.stats,
    required this.lastUpdatedLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              "Today's Overview",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15.5),
                color: AppColors.textPrimary,
              ),
            ),
            Spacer(),
            Flexible(
              child: Text(
                lastUpdatedLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w500,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                  color: AppColors.textFaint,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        LayoutBuilder(
          builder: (context, constraints) {
            final spacing = ResponsiveHelper.getResponsiveWidth(context, 12);
            final cardWidth = (constraints.maxWidth - spacing) / 2;
            final cardHeight = ResponsiveHelper.getResponsiveHeight(context, 175);

            return Wrap(
              spacing: spacing,
              runSpacing: ResponsiveHelper.getResponsiveHeight(context, 12),
              children: [
                for (final stat in stats)
                  SizedBox(
                    width: cardWidth,
                    height: cardHeight,
                    child: _OverviewStatCard(stat: stat),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StatVisual {
  final String asset;
  final Color iconColor;
  final Color iconBackground;
  final Color badgeBackground;
  final String badgeLabel;

  const _StatVisual({
    required this.asset,
    required this.iconColor,
    required this.iconBackground,
    required this.badgeBackground,
    required this.badgeLabel,
  });
}

_StatVisual _visualForTag(StatTag tag) {
  switch (tag) {
    case StatTag.active:
      return const _StatVisual(
        asset: AppAssets.users,
        iconColor: AppColors.activeGreen,
        iconBackground: AppColors.activeIconBackground,
        badgeBackground: AppColors.activeBackground,
        badgeLabel: 'ACTIVE',
      );
    case StatTag.urgent:
      return const _StatVisual(
        asset: AppAssets.alertCircle,
        iconColor: AppColors.criticalRed,
        iconBackground: AppColors.criticalIconBackground,
        badgeBackground: AppColors.criticalBackground,
        badgeLabel: 'URGENT',
      );
    case StatTag.due:
      return const _StatVisual(
        asset: AppAssets.pill,
        iconColor: AppColors.urgentAmber,
        iconBackground: AppColors.urgentIconBackground,
        badgeBackground: AppColors.urgentBackground,
        badgeLabel: 'DUE',
      );
    case StatTag.review:
      return const _StatVisual(
        asset: AppAssets.clipboardCheck,
        iconColor: AppColors.urgentAmber,
        iconBackground: AppColors.urgentIconBackground,
        badgeBackground: AppColors.urgentBackground,
        badgeLabel: 'REVIEW',
      );
    case StatTag.today:
      return const _StatVisual(
        asset: AppAssets.calendarCheck,
        iconColor: AppColors.infoBlue,
        iconBackground: AppColors.infoIconBackground,
        badgeBackground: AppColors.infoBackground,
        badgeLabel: 'TODAY',
      );
    case StatTag.flagged:
      return const _StatVisual(
        asset: AppAssets.flag,
        iconColor: AppColors.criticalRed,
        iconBackground: AppColors.criticalIconBackground,
        badgeBackground: AppColors.criticalBackground,
        badgeLabel: 'FLAGGED',
      );
  }
}

class _OverviewStatCard extends StatelessWidget {
  final OverviewStat stat;

  const _OverviewStatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final visual = _visualForTag(stat.tag);
    final iconBox = ResponsiveHelper.getResponsiveSize(context, 40);

    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, AppDimens.radiusCard),
        ),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.04),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 1)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 1),
          ),
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.04),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 6)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: iconBox,
                height: iconBox,
                decoration: BoxDecoration(
                  color: visual.iconBackground,
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveRadius(context, 12),
                  ),
                ),
                alignment: Alignment.center,
                child: AppSvgIcon(visual.asset, size: 20, color: visual.iconColor),
              ),
              const Spacer(),
              _StatusPill(
                label: visual.badgeLabel,
                background: visual.badgeBackground,
                foreground: visual.iconColor,
                isUppercase: true,
              ),
            ],
          ),
          const Spacer(),
          Text(
            stat.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 30),
              color: AppColors.textHeading,
              letterSpacing: -0.6,
              height: 1,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
          Text(
            stat.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
              color: AppColors.textSecondary,
              height: 1.2,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
          Text(
            stat.helperText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
              color: stat.isHelperTextPositive
                  ? AppColors.activeGreen
                  : AppColors.textMuted,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared pill badge
// ─────────────────────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final bool isUppercase;

  const _StatusPill({
    required this.label,
    required this.background,
    required this.foreground,
    this.isUppercase = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: isUppercase ? 9 : 8,
        vertical: isUppercase ? 4 : 3,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, isUppercase ? 999 : 6),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(
            context,
            isUppercase ? 10.5 : 10,
          ),
          color: foreground,
          letterSpacing: 0.2,
          height: 1,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error state
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _DashboardError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context, all: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: AppColors.criticalRed,
              size: ResponsiveHelper.getResponsiveSize(context, 40),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryTeal,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
