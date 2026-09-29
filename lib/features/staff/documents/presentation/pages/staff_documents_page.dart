import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../presentation/widgets/staff_bottom_nav_bar.dart';
import '../../../staff_shell.dart';
import '../controllers/staff_documents_controller.dart';
import '../widgets/staff_document_types_sheet.dart';
import '../widgets/staff_documents_bottom_panels.dart';
import '../widgets/staff_documents_filters_bar.dart';
import '../widgets/staff_documents_metrics_strip.dart';
import '../widgets/staff_documents_registry.dart';
import '../widgets/staff_missing_documents_sheet.dart';
import '../widgets/staff_upload_document_sheet.dart';

/// Staff Documents Management — web `/dashboard/documents` parity.
class StaffDocumentsPage extends StatefulWidget {
  const StaffDocumentsPage({super.key});

  @override
  State<StaffDocumentsPage> createState() => _StaffDocumentsPageState();
}

class _StaffDocumentsPageState extends State<StaffDocumentsPage> {
  late final StaffDocumentsController _controller;
  late final TextEditingController _searchController;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    try {
      _controller = Get.find<StaffDocumentsController>();
    } catch (_) {
      _controller = Get.put(
        GetIt.instance<StaffDocumentsController>(),
        permanent: true,
      );
    }
    _searchController = TextEditingController(
      text: _controller.searchQuery.value,
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _controller.setSearch(value);
    });
  }

  Future<void> _openMissing() async {
    await showStaffMissingDocumentsSheet(
      context,
      gaps: _controller.summary.value.missingByType,
    );
  }

  Future<void> _handleResult(
    Future<dynamic> Function() action, {
    required String successTitle,
  }) async {
    final result = await action();
    result.when(
      success: (_) => Get.snackbar(successTitle, ''),
      failure: (e) => Get.snackbar('Something went wrong', e.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = Get.find<UserSession>();
    final canWrite = session.canWriteDocuments;

    return Scaffold(
      key: const Key('staff-documents-page'),
      backgroundColor: AppColors.scaffoldBackground,
      bottomNavigationBar: StaffBottomNavBar(
        currentIndex: 4,
        onTap: (i) => Get.offAll(() => StaffShell(initialIndex: i)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Obx(
              () => _Header(
                canWrite: canWrite,
                showWithdrawn: _controller.includeDeleted.value,
                onBack: () => Navigator.maybePop(context),
                onToggleWithdrawn: _controller.toggleWithdrawn,
                onDocumentTypes: () =>
                    showStaffDocumentTypesSheet(context, _controller),
                onUpload: canWrite
                    ? () => showStaffUploadDocumentSheet(context, _controller)
                    : null,
              ),
            ),
            Expanded(
              child: Obx(() {
                final loading = _controller.isLoading.value;
                final summary = _controller.summary.value;
                final docs = _controller.documents.toList();

                if (loading && docs.isEmpty && summary.documents == 0) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.secondaryTeal,
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.secondaryTeal,
                  onRefresh: _controller.reload,
                  child: ListView(
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      horizontal: 16,
                      vertical: 12,
                    ),
                    children: [
                      Text(
                        'Documents',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w800,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            26,
                          ),
                          color: AppColors.textHeading,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Every certificate, care plan and policy on file, and what is missing.',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            13,
                          ),
                          color: AppColors.textMuted,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 16),
                      StaffDocumentsMetricsStrip(
                        summary: summary,
                        onMissingTap: _openMissing,
                      ),
                      const SizedBox(height: 16),
                      StaffDocumentsFiltersBar(
                        searchController: _searchController,
                        ownerType: _controller.ownerTypeFilter.value,
                        documentTypeId: _controller.documentTypeFilter.value,
                        status: _controller.statusFilter.value,
                        visibility: _controller.visibilityFilter.value,
                        types: _controller.types.toList(),
                        hasActiveFilters: _controller.hasActiveFilters,
                        onSearchChanged: _onSearchChanged,
                        onFilterChanged: ({
                          ownerType,
                          documentTypeId,
                          status,
                          visibility,
                        }) =>
                            _controller.setFilter(
                              ownerType: ownerType,
                              documentTypeId: documentTypeId,
                              status: status,
                              visibility: visibility,
                            ),
                        onClear: () {
                          _searchController.clear();
                          _controller.clearFilters();
                        },
                      ),
                      const SizedBox(height: 16),
                      StaffDocumentsRegistry(
                        documents: docs,
                        totalCount: _controller.total.value,
                        canWrite: canWrite,
                        page: _controller.page.value,
                        totalPages: _controller.totalPages.value,
                        onPageChanged: _controller.goToPage,
                        onWithdraw: (doc) => _handleResult(
                          () => _controller.withdraw(doc.id),
                          successTitle: 'Document withdrawn',
                        ),
                        onRestore: (doc) => _handleResult(
                          () => _controller.restore(doc.id),
                          successTitle: 'Document restored',
                        ),
                      ),
                      const SizedBox(height: 16),
                      StaffDocumentsBottomPanels(
                        summary: summary,
                        onSeeGaps: _openMissing,
                        onViewRestricted: () {
                          _controller.setFilter(visibility: 'staff_only');
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool canWrite;
  final bool showWithdrawn;
  final VoidCallback onBack;
  final VoidCallback onToggleWithdrawn;
  final VoidCallback onDocumentTypes;
  final VoidCallback? onUpload;

  const _Header({
    required this.canWrite,
    required this.showWithdrawn,
    required this.onBack,
    required this.onToggleWithdrawn,
    required this.onDocumentTypes,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceWhite,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 12, 10),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: AppColors.textHeading,
                ),
                const Expanded(
                  child: Text(
                    'Documents Management',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: AppColors.textHeading,
                    ),
                  ),
                ),
              ],
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 8),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: onToggleWithdrawn,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: showWithdrawn
                          ? AppColors.primaryNavy
                          : Colors.transparent,
                      foregroundColor: showWithdrawn
                          ? Colors.white
                          : AppColors.textHeading,
                    ),
                    child: Text(
                      showWithdrawn ? 'Withdrawn shown' : 'Show withdrawn',
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onDocumentTypes,
                    icon: const Icon(Icons.sell_outlined, size: 16),
                    label: const Text('Document types'),
                  ),
                  if (canWrite && onUpload != null) ...[
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: onUpload,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Upload Document'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
