import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../controllers/family_messages_controller.dart';
import '../widgets/conversation_row_tile.dart';
import '../widgets/family_messages_header.dart';
import '../widgets/family_messages_search_bar.dart';
import '../widgets/new_message_fab.dart';
import 'compose_message_page.dart';

/// The Family "Messages" screen: a search bar over a list of conversations
/// with care team members and family/group chats.
///
/// This page is designed to be embedded as one tab of a shared
/// `FamilyShell` (bottom navigation is supplied there, not by this page -
/// see how `lib/features/staff/tasks_messages/presentation/pages/staff_tasks_messages_page.dart`
/// handles the same embedding for the analogous Staff screen).
class FamilyMessagesListPage extends StatefulWidget {
  const FamilyMessagesListPage({super.key});

  @override
  State<FamilyMessagesListPage> createState() => _FamilyMessagesListPageState();
}

class _FamilyMessagesListPageState extends State<FamilyMessagesListPage> {
  late final FamilyMessagesController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = _resolveController();
  }

  FamilyMessagesController _resolveController() {
    try {
      return Get.find<FamilyMessagesController>();
    } catch (_) {
      return Get.put(GetIt.instance<FamilyMessagesController>(), permanent: true);
    }
  }

  void _openComposeMessage() {
    Get.to(() => const ComposeMessagePage());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      floatingActionButton: NewMessageFab(onTap: _openComposeMessage),
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          final response = _controller.state.value;
          final hasData = response.data != null;

          if (!hasData && _controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator(color: AppColors.secondaryTeal));
          }

          if (!hasData) {
            return _MessagesError(
              message: _controller.errorMessage.value.isEmpty
                  ? 'Something went wrong while loading Messages.'
                  : _controller.errorMessage.value,
              onRetry: _controller.refresh,
            );
          }

          final conversations = _controller.visibleConversations;

          return Column(
            children: [
              ColoredBox(
                color: AppColors.surfaceWhite,
                child: Column(
                  children: [
                    const FamilyMessagesHeader(title: 'Messages'),
                    Padding(
                      padding: ResponsiveHelper.getResponsivePadding(
                        context,
                        horizontal: 16,
                        bottom: 14,
                      ),
                      child: FamilyMessagesSearchBar(
                        controller: _searchController,
                        onChanged: _controller.updateSearchQuery,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.secondaryTeal,
                  onRefresh: _controller.refresh,
                  child: conversations.isEmpty
                      ? ListView(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveHelper.getResponsiveWidth(context, 20),
                            vertical: ResponsiveHelper.getResponsiveHeight(context, 40),
                          ),
                          children: const [_NoResults()],
                        )
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                            ResponsiveHelper.getResponsiveWidth(context, 20),
                            ResponsiveHelper.getResponsiveHeight(context, 14),
                            ResponsiveHelper.getResponsiveWidth(context, 20),
                            ResponsiveHelper.getResponsiveHeight(context, 90),
                          ),
                          itemCount: conversations.length,
                          separatorBuilder: (_, _) => SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
                          itemBuilder: (context, index) => ConversationRowTile(conversation: conversations[index]),
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

class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No conversations match your search.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w500,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _MessagesError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _MessagesError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
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
                fontFamily: 'Outfit',
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
    );
  }
}
