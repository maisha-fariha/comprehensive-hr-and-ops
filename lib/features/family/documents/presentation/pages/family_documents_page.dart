import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../family_shell.dart';
import '../../../presentation/widgets/family_bottom_nav_bar.dart';
import '../controllers/family_documents_controller.dart';
import '../widgets/family_document_row_tile.dart';
import '../widgets/family_documents_caption.dart';
import '../widgets/family_documents_header.dart';

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

        final documents = overview.documents;

        return Column(
          children: [
            ColoredBox(
              color: AppColors.surfaceWhite,
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    FamilyDocumentsHeader(onBackTap: () => Navigator.maybePop(context)),
                    FamilyDocumentsCaption(text: overview.captionText),
                  ],
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.secondaryTeal,
                onRefresh: controller.refresh,
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    ResponsiveHelper.getResponsiveWidth(context, AppDimens.screenPaddingHorizontal),
                    ResponsiveHelper.getResponsiveHeight(context, 16),
                    ResponsiveHelper.getResponsiveWidth(context, AppDimens.screenPaddingHorizontal),
                    ResponsiveHelper.getResponsiveHeight(context, 24),
                  ),
                  itemCount: documents.length,
                  separatorBuilder: (context, index) =>
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
                  itemBuilder: (context, index) {
                    final document = documents[index];
                    return FamilyDocumentRowTile(document: document);
                  },
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
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
