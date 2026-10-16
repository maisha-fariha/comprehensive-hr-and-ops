import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../appointments/presentation/widgets/family_primary_button.dart';
import '../../domain/entities/family_document.dart';
import '../../../family_shell.dart';
import '../../../presentation/widgets/family_bottom_nav_bar.dart';
import '../controllers/family_documents_controller.dart';
import '../widgets/family_document_row_tile.dart';
import '../widgets/family_documents_header.dart';
import '../widgets/family_send_document_sheet.dart';
import '../widgets/family_sign_document_sheet.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_refresh_indicator.dart';

/// "Documents" — the Family portal's screen listing documents shared by the
/// care facility (care plans, appointment summaries, policies, etc.).
///
/// Pushed as a standalone route (e.g. `Get.to(() => const
/// FamilyDocumentsPage())`) from the Family "More" hub, so it owns its own
/// `Scaffold`/`SafeArea` rather than being embedded in a shell.
///
/// Hosts [FamilyBottomNavBar] with "More" selected so the pushed route still
/// matches reference frames that show the family bottom nav.
class FamilyDocumentsPage extends StatelessWidget {
  const FamilyDocumentsPage({super.key});

  /// Index of the "More" slot in [FamilyBottomNavBar.items].
  static const int _moreTabIndex = 4;

  FamilyDocumentsController _resolveController() {
    try {
      return Get.find<FamilyDocumentsController>();
    } catch (_) {
      return Get.put(GetIt.instance<FamilyDocumentsController>(), permanent: true);
    }
  }

  void _onBottomNavTap(int index) {
    Get.offAll(() => FamilyShell(initialIndex: index));
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolveController();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      bottomNavigationBar: FamilyBottomNavBar(
        currentIndex: _moreTabIndex,
        onTap: _onBottomNavTap,
      ),
      body: Obx(() {
        final response = controller.state.value;
        final overview = response.data;

        if (overview == null && controller.isLoading.value) {
          return const SafeArea(
            child: Center(child: CircularProgressIndicator(color: AppColors.secondaryTeal)),
          );
        }

        if (overview == null) {
          return _FamilyDocumentsError(
            message: controller.errorMessage.value.isEmpty
                ? 'Something went wrong while loading documents.'
                : controller.errorMessage.value,
            onRetry: controller.refresh,
          );
        }

        return _FamilyDocumentsBody(
          documents: overview.documents,
          onRefresh: controller.refresh,
          onSend: () async {
            final sent = await showFamilySendDocumentSheet(
              context: context,
              repository: controller.repository,
            );
            if (sent == true) controller.refresh();
          },
          onDownload: controller.openDocument,
          onPreview: (document) => _previewDocument(context, controller, document),
          onSign: (document) => showFamilySignDocumentSheet(
            context: context,
            document: document,
            defaultSignerName: Get.isRegistered<UserSession>()
                ? Get.find<UserSession>().displayName
                : '',
            onConfirm: () => controller.signDocument(document),
          ),
        );
      }),
    );
  }
}

class _FamilyDocumentsBody extends StatefulWidget {
  final List<FamilyDocument> documents;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onSend;
  final ValueChanged<FamilyDocument> onDownload;
  final ValueChanged<FamilyDocument> onPreview;
  final ValueChanged<FamilyDocument> onSign;

  const _FamilyDocumentsBody({
    required this.documents,
    required this.onRefresh,
    required this.onSend,
    required this.onDownload,
    required this.onPreview,
    required this.onSign,
  });

  @override
  State<_FamilyDocumentsBody> createState() => _FamilyDocumentsBodyState();
}

class _FamilyDocumentsBodyState extends State<_FamilyDocumentsBody> {
  static const _filters = [
    ('all', 'All documents'),
    ('care_home', 'From the care home'),
    ('consent_form', 'Consent forms'),
    ('resident_memory', 'Memories & photos'),
    ('mine', 'Sent by me'),
  ];

  String _filter = 'all';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<FamilyDocument> get _visible {
    final query = _search.text.trim().toLowerCase();
    return widget.documents.where((document) {
      final categoryOk = switch (_filter) {
        'care_home' => document.category.isEmpty,
        'mine' => document.uploadedByMe,
        'consent_form' || 'resident_memory' => document.category == _filter,
        _ => true,
      };
      if (!categoryOk) return false;
      if (query.isEmpty) return true;
      return document.title.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final searching = _search.text.trim().isNotEmpty || _filter != 'all';
    return Column(
      children: [
        ColoredBox(
          color: AppColors.surfaceWhite,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                FamilyDocumentsHeader(onBackTap: () => Navigator.maybePop(context)),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        Expanded(
          child: AppRefreshIndicator(
            color: AppColors.secondaryTeal,
            onRefresh: widget.onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                ResponsiveHelper.getResponsiveWidth(context, AppDimens.screenPaddingHorizontal),
                12,
                ResponsiveHelper.getResponsiveWidth(context, AppDimens.screenPaddingHorizontal),
                24,
              ),
              children: [
                const _CareRecordsBanner(),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final filter in _filters)
                      _DocumentFilterChip(
                        label: filter.$2,
                        selected: _filter == filter.$1,
                        onTap: () => setState(() => _filter = filter.$1),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _DocumentSearchField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                if (visible.isEmpty)
                  _EmptyDocuments(
                    filtered: searching || widget.documents.isNotEmpty,
                  )
                else
                  for (final document in visible) ...[
                    FamilyDocumentRowTile(
                      document: document,
                      onDownloadTap: () => widget.onDownload(document),
                      onPreviewTap: () => widget.onPreview(document),
                      onSignTap: document.signatureRequired &&
                              document.signatureAcknowledgedAt == null
                          ? () => widget.onSign(document)
                          : null,
                    ),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          ),
        ),
        if (!Get.isRegistered<UserSession>() ||
            Get.find<UserSession>().can('family:write'))
        ColoredBox(
          color: AppColors.surfaceWhite,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              ResponsiveHelper.getResponsiveWidth(context, 20),
              ResponsiveHelper.getResponsiveHeight(context, 12),
              ResponsiveHelper.getResponsiveWidth(context, 20),
              ResponsiveHelper.getResponsiveHeight(context, 12),
            ),
            child: FamilyPrimaryButton(
              label: 'Send Document or Photo',
              icon: Icons.add_rounded,
              onTap: () => widget.onSend(),
            ),
          ),
        ),
      ],
    );
  }
}

class _DocumentFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DocumentFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.secondaryTeal : const Color(0xFFF4F7F9),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 10),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
            color: selected ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _DocumentSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _DocumentSearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FB),
        border: Border.all(color: const Color(0xFFE2E8EE)),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 16),
        ),
      ),
      child: Row(
        children: [
          const AppSvgIcon(AppAssets.search, size: 18, color: Color(0xFF9AA8B8)),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                color: const Color(0xFF1A2B48),
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: ResponsiveHelper.getResponsivePadding(context, vertical: 14),
                hintText: 'Search documents...',
                hintStyle: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w400,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  color: const Color(0xFF9AA8B8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CareRecordsBanner extends StatelessWidget {
  const _CareRecordsBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.secondaryTeal),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Care Records & Legal Documentation',
                  style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textHeading),
                ),
                SizedBox(height: 2),
                Text(
                  'Papers the care home shares with you, and anything you send in: a signed consent form, or a family photo for your relative\'s memory board. Photos also appear in your relative\'s activities for the carers.',
                  style: TextStyle(fontFamily: 'Manrope', fontSize: 13, color: AppColors.textSecondary, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDocuments extends StatelessWidget {
  final bool filtered;

  const _EmptyDocuments({required this.filtered});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 8),
      child: Column(
        children: [
          const Icon(Icons.folder_open_outlined, size: 28, color: AppColors.textMuted),
          const SizedBox(height: 8),
          Text(
            filtered ? 'No matching documents found' : 'No documents on file yet',
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textHeading),
          ),
          const SizedBox(height: 4),
          Text(
            filtered
                ? 'Try adjusting your search terms or category filter.'
                : 'When the care team shares agreements or you upload consent files, they will appear here.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Manrope', fontSize: 13, color: AppColors.textSecondary),
          ),
          if (!filtered) ...[
            const SizedBox(height: 8),
            Text(
              'Use Send Document or Photo below to share the first file.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _previewDocument(
  BuildContext context,
  FamilyDocumentsController controller,
  FamilyDocument document,
) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceWhite,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              document.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This document is securely encrypted on the care home server. Click below to download or view the full file.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Manrope', fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            FamilyPrimaryButton(
              label: 'Download File to Device',
              icon: Icons.download_rounded,
              onTap: () {
                Navigator.of(sheetContext).pop();
                controller.openDocument(document);
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: Text(
                'Close Preview',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(sheetContext, 14),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _FamilyDocumentsError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _FamilyDocumentsError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(context, all: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.criticalRed, size: 40),
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
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondaryTeal),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
