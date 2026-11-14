import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/offline/offline_image.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../documents/presentation/pages/family_documents_page.dart';
import '../../../presentation/family_portal_nav.dart';
import '../../domain/entities/family_care_journal_models.dart';
import '../../domain/entities/family_daily_update_entry.dart';
import '../controllers/family_daily_updates_controller.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_refresh_indicator.dart';

/// Family Care Journal — web `/family/updates`.
///
/// Tabs: Journal notes · Health & Care Plan · Activity Moments.
/// Gated per-resident visibility from `/family/clients`.
class FamilyDailyUpdatesPage extends StatelessWidget {
  const FamilyDailyUpdatesPage({super.key});

  FamilyDailyUpdatesController _resolveController() {
    try {
      return Get.find<FamilyDailyUpdatesController>();
    } catch (_) {
      return Get.put(
        GetIt.instance<FamilyDailyUpdatesController>(),
        permanent: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolveController();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Obx(() {
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
                  ? 'Something went wrong while loading Care Journal.'
                  : controller.errorMessage.value,
              onRetry: controller.refresh,
            );
          }

          return Column(
            children: [
              _Header(
                onBack: () {
                  final navigator = Navigator.of(context);
                  if (navigator.canPop()) {
                    navigator.pop();
                    return;
                  }
                  familyGoToTab(0, context: context);
                },
              ),
              Expanded(
                child: AppRefreshIndicator(
                  color: AppColors.secondaryTeal,
                  onRefresh: controller.refresh,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      ResponsiveHelper.getResponsiveWidth(
                        context,
                        AppDimens.screenPaddingHorizontal,
                      ),
                      12,
                      ResponsiveHelper.getResponsiveWidth(
                        context,
                        AppDimens.screenPaddingHorizontal,
                      ),
                      32,
                    ),
                    children: [
                      Text(
                        'Daily Care Journal & Health',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            18,
                          ),
                          color: AppColors.textHeading,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'A transparent view of daily routines, nourishment, physical wellbeing, and moments.',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            13,
                          ),
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (overview.clients.length > 1) ...[
                        const SizedBox(height: 14),
                        _ClientPicker(
                          clients: overview.clients,
                          selectedId: overview.selectedClientId,
                          onChanged: controller.selectClient,
                        ),
                      ],
                      const SizedBox(height: 14),
                      _TabBar(
                        tab: controller.selectedTab.value,
                        onChanged: controller.selectTab,
                      ),
                      const SizedBox(height: 16),
                      switch (controller.selectedTab.value) {
                        CareJournalTab.journal => _JournalTab(
                            overview: overview,
                            controller: controller,
                          ),
                        CareJournalTab.medical => _MedicalTab(
                            overview: overview,
                          ),
                        CareJournalTab.moments => _MomentsTab(
                            overview: overview,
                          ),
                      },
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceWhite,
      padding: const EdgeInsets.fromLTRB(8, 4, 12, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
          Expanded(
            child: Text(
              'Care Journal',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                color: AppColors.textHeading,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Share a photo',
            onPressed: () => Get.to(() => const FamilyDocumentsPage()),
            icon: const Icon(Icons.add_photo_alternate_outlined),
            color: AppColors.secondaryTeal,
          ),
        ],
      ),
    );
  }
}

class _ClientPicker extends StatelessWidget {
  final List<FamilyCareJournalClient> clients;
  final String selectedId;
  final ValueChanged<String> onChanged;

  const _ClientPicker({
    required this.clients,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Client',
        filled: true,
        fillColor: AppColors.surfaceWhite,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: clients.any((c) => c.id == selectedId)
              ? selectedId
              : clients.first.id,
          items: [
            for (final c in clients)
              DropdownMenuItem(value: c.id, child: Text(c.name)),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  final CareJournalTab tab;
  final ValueChanged<CareJournalTab> onChanged;

  const _TabBar({required this.tab, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget chip(CareJournalTab value, IconData icon, String label) {
      final active = tab == value;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onChanged(value),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: active ? AppColors.secondaryTeal : AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active ? AppColors.secondaryTeal : AppColors.cardBorder,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: active ? Colors.white : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                      color: active ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(
          CareJournalTab.journal,
          Icons.menu_book_outlined,
          'Daily Care Notes',
        ),
        const SizedBox(width: 8),
        chip(
          CareJournalTab.medical,
          Icons.monitor_heart_outlined,
          'Health & Care Plan',
        ),
        const SizedBox(width: 8),
        chip(
          CareJournalTab.moments,
          Icons.photo_outlined,
          'Activity Moments',
        ),
      ],
    );
  }
}

class _JournalTab extends StatelessWidget {
  final FamilyCareJournalOverview overview;
  final FamilyDailyUpdatesController controller;

  const _JournalTab({
    required this.overview,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.activeBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.secondaryTeal.withValues(alpha: 0.25),
            ),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome, size: 16, color: AppColors.secondaryTeal),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transparent Care Updates',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Our care team logs notes throughout the day to keep family informed of daily routines, nourishment, wellbeing, and comfort.',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (overview.days.isEmpty)
          _EmptyCard(
            icon: Icons.menu_book_outlined,
            title: 'No care notes recorded for this period',
            body:
                'Care staff enter notes as routines unfold. Notes will appear here as soon as they are logged.',
          )
        else
          for (final day in overview.days) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        day.dateLabel,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${day.careNoteCount} recorded update${day.careNoteCount == 1 ? '' : 's'}'
                        '${day.activityCount > 0 ? ' · ${day.activityCount} activit${day.activityCount == 1 ? 'y' : 'ies'}' : ''}',
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.filterButtonBackground,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${day.careNoteCount} ${day.careNoteCount == 1 ? 'entry' : 'entries'}',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (day.notes.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'No notes were logged for this date.',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else
              for (final entry in day.notes) ...[
                _CareJournalEntryCard(entry: entry),
                const SizedBox(height: 10),
              ],
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 8),
        Text(
          overview.footerNote,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _CareJournalEntryCard extends StatelessWidget {
  final FamilyDailyUpdateEntry entry;

  const _CareJournalEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final memory = entry.isFamilyMemory;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: memory
            ? AppColors.activeBackground.withValues(alpha: 0.45)
            : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: memory
              ? AppColors.secondaryTeal.withValues(alpha: 0.35)
              : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      memory ? Icons.auto_awesome : Icons.menu_book_outlined,
                      size: 13,
                      color: AppColors.secondaryTeal,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      entry.title,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (entry.timeLabel.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      entry.timeLabel,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            entry.description,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13.5,
              color: AppColors.textHeading,
              height: 1.4,
            ),
          ),
          if (entry.authorName != null && entry.authorName!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              entry.authorName!,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                color: AppColors.textHeading,
              ),
            ),
          ],
          if (entry.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 1.4,
                child: Image(
                  image: OfflineImage.provider(
                    entry.mediaUrls.first,
                    withAuth: true,
                  ),
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stackTrace) => const ColoredBox(
                    color: AppColors.filterButtonBackground,
                    child: Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MedicalTab extends StatelessWidget {
  final FamilyCareJournalOverview overview;

  const _MedicalTab({required this.overview});

  @override
  Widget build(BuildContext context) {
    final client = overview.selectedClient;
    final conditions = overview.medicalConditions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionCard(
          title: 'Standing Health Profile & Baselines',
          child: Text(
            client == null
                ? 'Select a resident to view their health profile.'
                : 'Transparent care updates for ${client.name}.',
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (overview.medicalConditionsDisabled)
          _EmptyCard(
            icon: Icons.lock_outline,
            title: 'Health profile not shared',
            body: overview.medicalConditionsError ??
                'Family access to medical conditions is disabled for this resident.',
          )
        else ...[
          _SectionCard(
            title: 'Dietary Plan & Allergies',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kv('Diagnoses', conditions?.diagnoses ?? const []),
                const SizedBox(height: 8),
                _kv('Allergies', conditions?.allergies ?? const []),
                const SizedBox(height: 8),
                Text(
                  'Dietary Texture: ${conditions?.dietaryRequirements?.trim().isNotEmpty == true ? conditions!.dietaryRequirements : 'Not recorded'}',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13.5,
                    color: AppColors.textBody,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (overview.medicationsDisabled)
          _EmptyCard(
            icon: Icons.lock_outline,
            title: 'Medications not shared',
            body: overview.medicationsError ??
                'Family access to medications is disabled for this resident.',
          )
        else
          _SectionCard(
            title: 'Medication Routine Schedule',
            child: overview.medications.isEmpty
                ? const Text(
                    'No current prescriptions.',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      color: AppColors.textSecondary,
                    ),
                  )
                : Column(
                    children: [
                      for (final med in overview.medications) ...[
                        _MedRow(med: med),
                        if (med != overview.medications.last)
                          const Divider(height: 18),
                      ],
                    ],
                  ),
          ),
      ],
    );
  }

  Widget _kv(String label, List<String> values) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        if (values.isEmpty)
          const Text(
            'None recorded.',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final v in values)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.filterButtonBackground,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    v,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _MedRow extends StatelessWidget {
  final FamilyMedicationItem med;

  const _MedRow({required this.med});

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (med.dose.isNotEmpty) med.dose,
      if (med.route.isNotEmpty) med.route,
      if (med.frequency.isNotEmpty) med.frequency,
    ].join(' · ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.medication_outlined, color: AppColors.secondaryTeal),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                med.name,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              if (meta.isNotEmpty)
                Text(
                  meta,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              if (med.times.isNotEmpty)
                Text(
                  'Times: ${med.times.join(', ')}',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MomentsTab extends StatelessWidget {
  final FamilyCareJournalOverview overview;

  const _MomentsTab({required this.overview});

  @override
  Widget build(BuildContext context) {
    final moments = overview.moments;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionCard(
          title: 'Recreational Moments & Memories',
          child: const Text(
            'Photos captured during activities, workshops, garden walks, and family shares.',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (moments.isEmpty)
          _EmptyCard(
            icon: Icons.photo_outlined,
            title: 'No photos yet',
            body:
                'Photos the care team takes during activities and shares with you will appear here.',
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: moments.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.86,
            ),
            itemBuilder: (context, index) {
              final moment = moments[index];
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _openPhoto(context, moment),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Image(
                          image: OfflineImage.provider(
                            moment.url,
                            withAuth: true,
                          ),
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stackTrace) => const ColoredBox(
                            color: AppColors.filterButtonBackground,
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          moment.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  void _openPhoto(BuildContext context, FamilyCareMoment moment) {
    showAppBottomSheet<void>(
      context: context,
      backgroundColor: Colors.black,
      builder: (_) => SafeArea(
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image(
                  image: OfflineImage.provider(moment.url, withAuth: true),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 14.5,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.secondaryTeal, size: 28),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
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
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.criticalRed,
              size: 40,
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Manrope',
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
