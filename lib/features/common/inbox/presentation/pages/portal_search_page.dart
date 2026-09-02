import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/portal_search_hit.dart';
import '../controllers/portal_search_controller.dart';

class PortalSearchPage extends StatefulWidget {
  final String hint;
  final String emptyPrompt;
  final ValueChanged<PortalSearchHit> onHit;

  const PortalSearchPage({
    super.key,
    required this.hint,
    required this.emptyPrompt,
    required this.onHit,
  });

  @override
  State<PortalSearchPage> createState() => _PortalSearchPageState();
}

class _PortalSearchPageState extends State<PortalSearchPage> {
  late final PortalSearchController _controller;
  final TextEditingController _query = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<PortalSearchController>()) {
      Get.delete<PortalSearchController>(force: true);
    }
    _controller = Get.put(PortalSearchController());
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
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
          decoration: InputDecoration(
            hintText: widget.hint,
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
          return Center(child: Text(widget.emptyPrompt));
        }
        if (_controller.hits.isEmpty) {
          return const Center(child: Text('No matching results.'));
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
              onTap: () => widget.onHit(hit),
            );
          },
        );
      }),
    );
  }
}
