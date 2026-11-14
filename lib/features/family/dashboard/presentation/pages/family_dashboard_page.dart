import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/offline/offline_image.dart';
import '../../../appointments/presentation/pages/create_appointment_page.dart';
import '../../../documents/presentation/pages/family_documents_page.dart';
import '../../../messages/presentation/pages/compose_message_page.dart';
import '../../../outings/presentation/pages/family_outings_page.dart';
import '../../../presentation/family_portal_nav.dart';
import '../../../profile_settings/presentation/pages/family_profile_settings_page.dart';
import '../../domain/entities/family_dashboard_overview.dart';
import '../../domain/entities/family_shared_activity.dart';
import '../controllers/family_dashboard_controller.dart';
import '../widgets/family_dashboard_header.dart';
import '../widgets/family_needs_attention_card.dart';
import '../widgets/family_quick_actions_section.dart';
import 'family_notifications_page.dart';
import 'family_search_page.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_refresh_indicator.dart';

/// Family Overview — web `/family`.
class FamilyDashboardPage extends StatelessWidget {
  const FamilyDashboardPage({super.key});

  FamilyDashboardController _resolveController() {
    try {
      return Get.find<FamilyDashboardController>();
    } catch (_) {
      return Get.put(
        GetIt.instance<FamilyDashboardController>(),
        permanent: true,
      );
    }
  }

  void _goTab(int index) => familyGoToTab(index);

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
          return _ErrorPane(
            message: controller.errorMessage.value.isEmpty
                ? 'Something went wrong while loading Overview.'
                : controller.errorMessage.value,
            onRetry: controller.refresh,
          );
        }

        final pad = ResponsiveHelper.getResponsiveWidth(
          context,
          AppDimens.screenPaddingHorizontal,
        );

        return AppRefreshIndicator(
          color: AppColors.secondaryTeal,
          onRefresh: controller.refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FamilyDashboardHeader(
                  overview: overview,
                  onNotificationsTap: () =>
                      Get.to(() => const FamilyNotificationsPage()),
                  onAvatarTap: () =>
                      Get.to(() => const FamilyProfileSettingsPage()),
                  onSearchTap: () => Get.to(() => const FamilySearchPage()),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    pad,
                    16,
                    pad,
                    ResponsiveHelper.getResponsiveHeight(context, 42),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _RelativeSelector(
                        overview: overview,
                        selectedId: overview.selectedClientId,
                        onSelect: controller.selectClient,
                        onBookVisit: () =>
                            Get.to(() => const CreateAppointmentPage()),
                        onCareTeamChat: () => _goTab(3),
                      ),
                      if (overview.attentionAlerts.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        FamilyNeedsAttentionCard(
                          alerts: overview.attentionAlerts,
                        ),
                      ],
                      const SizedBox(height: 14),
                      _SummaryGrid(
                        overview: overview,
                      ),
                      const SizedBox(height: 14),
                      if (overview.selectedClient != null)
                        _ResidentCard(
                          overview: overview,
                          onJournal: () => _goTab(1),
                          onOuting: () =>
                              Get.to(() => const FamilyOutingsPage()),
                        ),
                      const SizedBox(height: 14),
                      _LatestJournalNote(
                        overview: overview,
                        onFullJournal: () => _goTab(1),
                      ),
                      if (overview.sharedActivities.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _SharedActivities(
                          activities: overview.sharedActivities,
                        ),
                      ],
                      if (overview.nextAppointment != null) ...[
                        const SizedBox(height: 14),
                        _NextVisitCard(
                          overview: overview,
                          onTap: () => _goTab(2),
                        ),
                      ],
                      if (overview.quickActions.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        FamilyQuickActionsSection(
                          actions: overview.quickActions,
                          onActionTap: (action) {
                            switch (action.id) {
                              case 'request-visit':
                                Get.to(() => const CreateAppointmentPage());
                              case 'send-message':
                                Get.to(() => const ComposeMessagePage());
                              case 'care-journal':
                                _goTab(1);
                              case 'plan-outing':
                                Get.to(() => const FamilyOutingsPage());
                              case 'view-documents':
                                Get.to(() => const FamilyDocumentsPage());
                            }
                          },
                        ),
                      ],
                      const SizedBox(height: 14),
                      _DutyDesk(
                        onMessage: () => Get.to(
                          () => const ComposeMessagePage(),
                        ),
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

class _RelativeSelector extends StatelessWidget {
  final FamilyDashboardOverview overview;
  final String selectedId;
  final ValueChanged<String> onSelect;
  final VoidCallback onBookVisit;
  final VoidCallback onCareTeamChat;

  const _RelativeSelector({
    required this.overview,
    required this.selectedId,
    required this.onSelect,
    required this.onBookVisit,
    required this.onCareTeamChat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Family Portal',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
            color: AppColors.textHeading,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              'Relative:',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            for (final client in overview.linkedClients)
              GestureDetector(
                onTap: () => onSelect(client.id),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: client.id == selectedId
                        ? AppColors.secondaryTeal
                        : AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: client.id == selectedId
                          ? AppColors.secondaryTeal
                          : AppColors.cardBorder,
                    ),
                  ),
                  child: Text(
                    client.name,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      color: client.id == selectedId
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: onCareTeamChat,
              icon: const Icon(Icons.chat_bubble_outline, size: 14),
              label: const Text('Care Team Chat'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textHeading,
                side: const BorderSide(color: AppColors.cardBorder),
                visualDensity: VisualDensity.compact,
              ),
            ),
            FilledButton.icon(
              onPressed: onBookVisit,
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Book a Visit'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondaryTeal,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final FamilyDashboardOverview overview;

  const _SummaryGrid({required this.overview});

  @override
  Widget build(BuildContext context) {
    final client = overview.selectedClient;
    final visit = overview.nextAppointment;
    final cards = [
      (
        'RELATIVE IN CARE',
        client?.name ?? '—',
        'Room ${client?.room ?? 'Assigned'} · ${client?.residenceName.isNotEmpty == true ? client!.residenceName : 'Main Home'}',
        AppColors.textHeading,
      ),
      (
        'UPCOMING VISIT',
        visit?.dateTimeLabel.isNotEmpty == true
            ? visit!.dateTimeLabel
            : 'None booked',
        visit?.statusLabel ?? 'Flexible schedule',
        AppColors.secondaryTeal,
      ),
      (
        'CARE JOURNAL',
        overview.careJournalActiveToday ? 'Active Today' : 'Awaiting Shift',
        overview.careJournalLastNoted == null
            ? 'Daily log pending'
            : 'Last noted on ${overview.careJournalLastNoted}',
        AppColors.textHeading,
      ),
      (
        'CARE FACILITY',
        overview.careFacilityName,
        '24/7 Duty Lead on shift',
        AppColors.textHeading,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 520;
        final children = [
          for (final c in cards)
            _StatTile(
              label: c.$1,
              value: c.$2,
              bottom: c.$3,
              valueColor: c.$4,
            ),
        ];
        if (wide) {
          return Row(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                Expanded(child: children[i]),
                if (i != children.length - 1) const SizedBox(width: 10),
              ],
            ],
          );
        }
        return Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1) const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String bottom;
  final Color valueColor;

  const _StatTile({
    required this.label,
    required this.value,
    required this.bottom,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: AppColors.textMuted,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            bottom,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResidentCard extends StatelessWidget {
  final FamilyDashboardOverview overview;
  final VoidCallback onJournal;
  final VoidCallback onOuting;

  const _ResidentCard({
    required this.overview,
    required this.onJournal,
    required this.onOuting,
  });

  @override
  Widget build(BuildContext context) {
    final client = overview.selectedClient!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.activeBackground,
                child: Text(
                  client.name.isEmpty ? '?' : client.name[0].toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: AppColors.secondaryTeal,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            client.name,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.successGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Active Resident',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              color: AppColors.successGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        client.residenceName.isEmpty
                            ? 'Main Residence Wing'
                            : client.residenceName,
                        'Room: ${client.room ?? '—'}',
                      ].join(' · '),
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: onJournal,
                icon: const Icon(Icons.menu_book_outlined, size: 14),
                label: const Text('Care Journal'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondaryTeal,
                ),
              ),
              OutlinedButton.icon(
                onPressed: onOuting,
                icon: const Icon(Icons.explore_outlined, size: 14),
                label: const Text('Plan Outing'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LatestJournalNote extends StatelessWidget {
  final FamilyDashboardOverview overview;
  final VoidCallback onFullJournal;

  const _LatestJournalNote({
    required this.overview,
    required this.onFullJournal,
  });

  @override
  Widget build(BuildContext context) {
    final note = overview.recentUpdate;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.menu_book_outlined,
                size: 18,
                color: AppColors.secondaryTeal,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Latest Care Journal Note',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              TextButton(
                onPressed: onFullJournal,
                child: const Text(
                  'Full journal →',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: AppColors.secondaryTeal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (note == null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    color: AppColors.secondaryTeal,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Today's care journal is updating. Care notes are written throughout shifts by nursing and support staff.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: onFullJournal,
                    child: const Text('Browse Past Notes'),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.statusLabel.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    note.body,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13.5,
                      color: AppColors.textHeading,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${note.authorName} · ${note.dateTimeLabel}',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(Icons.verified_user_outlined,
                  size: 15, color: AppColors.successGreen),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Care notes are verified by the registered duty manager each morning.',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SharedActivities extends StatelessWidget {
  final List<FamilySharedActivity> activities;

  const _SharedActivities({required this.activities});

  @override
  Widget build(BuildContext context) {
    final items = activities.take(5).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, size: 18, color: AppColors.secondaryTeal),
              SizedBox(width: 8),
              Text(
                'Shared Activities',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final a in items) ...[
            _SharedActivityRow(activity: a),
            if (a != items.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _SharedActivityRow extends StatelessWidget {
  final FamilySharedActivity activity;

  const _SharedActivityRow({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.activeBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          clipBehavior: Clip.antiAlias,
          child: activity.mediaUrls.isEmpty
              ? const Icon(Icons.photo_outlined, color: AppColors.secondaryTeal)
              : Image(
                  image: OfflineImage.provider(
                    activity.mediaUrls.first,
                    withAuth: true,
                  ),
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stackTrace) => const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.textMuted,
                  ),
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.title,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
              Text(
                activity.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
              if (activity.dateLabel.isNotEmpty)
                Text(
                  activity.dateLabel,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ),
        if (activity.mediaUrls.isNotEmpty)
          const Icon(Icons.photo_camera_outlined,
              size: 16, color: AppColors.textMuted),
      ],
    );
  }
}

class _NextVisitCard extends StatelessWidget {
  final FamilyDashboardOverview overview;
  final VoidCallback onTap;

  const _NextVisitCard({required this.overview, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final visit = overview.nextAppointment!;
    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Next Scheduled Visit',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                visit.dateTimeLabel,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.secondaryTeal,
                ),
              ),
              if (visit.location.isNotEmpty)
                Text(
                  visit.location,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  visit.statusLabel,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                    color: AppColors.successGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DutyDesk extends StatelessWidget {
  final VoidCallback onMessage;

  const _DutyDesk({required this.onMessage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.activeBackground,
                child: Icon(Icons.phone_in_talk_outlined,
                    size: 16, color: AppColors.secondaryTeal),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Care Team Duty Desk',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    Text(
                      'Duty nurse & coordinators available 24/7',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onMessage,
            child: const Text('Message Lead'),
          ),
        ],
      ),
    );
  }
}

class _ErrorPane extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorPane({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context, all: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.criticalRed, size: 40),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
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
