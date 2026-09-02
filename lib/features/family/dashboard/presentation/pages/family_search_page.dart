import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../documents/presentation/pages/family_documents_page.dart';
import '../../../family_shell.dart';
import '../../../messages/presentation/pages/family_conversation_page.dart';
import '../../domain/entities/family_search_hit.dart';
import '../controllers/family_search_controller.dart';

class FamilySearchPage extends StatefulWidget {
  const FamilySearchPage({super.key});

  @override
  State<FamilySearchPage> createState() => _FamilySearchPageState();
}

class _FamilySearchPageState extends State<FamilySearchPage> {
  late final FamilySearchController _controller;
  final TextEditingController _query = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<FamilySearchController>()) {
      Get.delete<FamilySearchController>(force: true);
    }
    _controller = Get.put(FamilySearchController());
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _openHit(FamilySearchHit hit) {
    switch (hit.type) {
      case FamilySearchHitType.dailyLog:
        Get.offAll(() => const FamilyShell(initialIndex: 1));
      case FamilySearchHitType.appointment:
        Get.offAll(() => const FamilyShell(initialIndex: 2));
      case FamilySearchHitType.message:
        Get.to(() => FamilyConversationPage(conversationId: hit.id));
      case FamilySearchHitType.document:
        Get.to(() => const FamilyDocumentsPage());
      case FamilySearchHitType.unknown:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        title: TextField(
          controller: _query,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: _controller.search,
          onSubmitted: _controller.search,
          decoration: const InputDecoration(
            hintText: 'Search updates, visits, or messages',
            border: InputBorder.none,
          ),
        ),
      ),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.secondaryTeal),
          );
        }
        if (_controller.errorMessage.value.isNotEmpty &&
            _controller.hits.isEmpty) {
          return Center(child: Text(_controller.errorMessage.value));
        }
        if (_query.text.trim().isEmpty) {
          return const Center(
            child: Text('Search care notes, visits, messages, and documents.'),
          );
        }
        if (_controller.hits.isEmpty) {
          return const Center(child: Text('No family-safe results.'));
        }
        return ListView.separated(
          padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
          itemCount: _controller.hits.length,
          separatorBuilder: (_, _) =>
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
          itemBuilder: (context, index) {
            final hit = _controller.hits[index];
            return ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              title: Text(hit.title),
              subtitle: hit.subtitle.isEmpty ? null : Text(hit.subtitle),
              onTap: () => _openHit(hit),
            );
          },
        );
      }),
    );
  }
}
