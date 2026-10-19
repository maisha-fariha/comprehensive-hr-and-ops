import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../staff/presentation/widgets/staff_bottom_nav_bar.dart';
import '../../../../staff/staff_shell.dart';
import '../../domain/entities/communication_enums.dart';
import '../../domain/entities/hr_conversation.dart';
import '../../domain/entities/hr_message_contact.dart';
import '../../domain/repositories/communication_repository.dart';
import '../controllers/communication_controller.dart';
import '../widgets/chat_panel.dart';
import '../widgets/communication_extra_panels.dart';
import '../widgets/communication_header.dart';
import '../widgets/communication_segment_tabs.dart';
import '../widgets/conversations_panel.dart';
import '../widgets/new_conversation_dialog.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_refresh_indicator.dart';

/// Communication screen — Messages (staff omits Communication Log; not on staff web).
class CommunicationPage extends StatefulWidget {
  final String? initialConversationId;

  /// When true, hosts [StaffBottomNavBar] and keeps Messages-only layout
  /// (staff web has no Communication Log).
  final bool showStaffBottomNav;

  const CommunicationPage({
    super.key,
    this.initialConversationId,
    this.showStaffBottomNav = false,
  });

  @override
  State<CommunicationPage> createState() => _CommunicationPageState();
}

class _CommunicationPageState extends State<CommunicationPage> {
  var _didSeedConversation = false;

  CommunicationController _resolve() {
    if (Get.isRegistered<CommunicationController>()) {
      return Get.find<CommunicationController>();
    }
    return Get.put(
      GetIt.instance<CommunicationController>(),
      permanent: true,
    );
  }

  Future<void> _openNewConversation(
    BuildContext context,
    CommunicationController controller,
  ) async {
    if (controller.contacts.isEmpty && !controller.isLoadingContacts.value) {
      await controller.loadContacts();
    }
    if (controller.residences.isEmpty) await controller.loadResidences();
    if (controller.clients.isEmpty) await controller.loadClients();
    if (!context.mounted) return;

    final result = await showNewConversationDialog(
      context,
      contacts: List<HrMessageContact>.from(controller.contacts),
      residences: List<CommunicationResidenceOption>.from(controller.residences),
      clients: List<CommunicationClientOption>.from(controller.clients),
      initialResidenceId: controller.preferredResidenceId,
      loadFamilyContacts: controller.familyContactsFor,
    );
    if (result == null) return;

    await controller.startConversation(
      type: result.type,
      title: result.title,
      memberUserIds: result.memberUserIds,
      residenceId: result.residenceId,
      clientId: result.clientId,
      firstMessage: result.firstMessage,
    );
  }

  Future<void> _addParticipant(
    BuildContext context,
    CommunicationController controller,
  ) async {
    if (controller.contacts.isEmpty && !controller.isLoadingContacts.value) {
      await controller.loadContacts();
    }
    if (!context.mounted) return;
    final ids = await showAppBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _AddParticipantSheet(
          contacts: List<HrMessageContact>.from(controller.contacts),
        );
      },
    );
    if (ids == null || ids.isEmpty) return;
    await controller.addParticipants(ids);
  }

  Future<void> _showParticipants(
    BuildContext context,
    CommunicationController controller,
  ) async {
    final conversation = controller.selectedConversation;
    if (conversation == null) return;
    final canAdd = controller.canWriteMessages &&
        !controller.monitoring.value &&
        !conversation.isArchived;
    await showAppBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _ParticipantsSheet(
          people: conversation.participants,
          roleFor: (userId) {
            for (final contact in controller.contacts) {
              if (contact.id == userId) return contact.roleLabel;
            }
            return null;
          },
          onAdd: canAdd
              ? () async {
                  Navigator.of(sheetContext).pop();
                  if (!context.mounted) return;
                  await _addParticipant(context, controller);
                }
              : null,
        );
      },
    );
  }

  Future<void> _seedIfNeeded(CommunicationController controller) async {
    if (_didSeedConversation) return;
    final seedId = widget.initialConversationId?.trim();
    if (seedId == null || seedId.isEmpty) return;
    _didSeedConversation = true;
    if (controller.conversations.isEmpty) {
      await controller.loadConversations();
    }
    await controller.selectConversation(seedId);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolve();
    final staffNav = widget.showStaffBottomNav;
    final tabs = <CommunicationTab>[
      CommunicationTab.messages,
      CommunicationTab.announcements,
      if (Get.isRegistered<UserSession>() &&
          Get.find<UserSession>().canMonitorMessaging) ...[
        CommunicationTab.monitoring,
        CommunicationTab.communicationLog,
      ],
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _seedIfNeeded(controller);
      if (!tabs.contains(controller.selectedTab.value)) {
        controller.selectTab(CommunicationTab.messages);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      bottomNavigationBar: staffNav
          ? StaffBottomNavBar(
              currentIndex: 4,
              onTap: (i) => Get.offAll(() => StaffShell(initialIndex: i)),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            CommunicationHeader(
              onBack: () {
                FocusManager.instance.primaryFocus?.unfocus();
                Navigator.of(context).pop();
              },
              onNewConversation: () =>
                  _openNewConversation(context, controller),
            ),
            Obx(
              () => CommunicationSegmentTabs(
                tabs: tabs,
                selected: tabs.contains(controller.selectedTab.value)
                    ? controller.selectedTab.value
                    : CommunicationTab.messages,
                onSelected: controller.selectTab,
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.selectedTab.value ==
                    CommunicationTab.announcements) {
                  return AnnouncementsPanel(repository: controller.repository);
                }
                if (controller.selectedTab.value ==
                    CommunicationTab.communicationLog) {
                  return CommunicationLogPanel(
                    repository: controller.repository,
                    onOpenConversation: (id) {
                      controller.selectConversation(id);
                      controller.selectTab(CommunicationTab.monitoring);
                    },
                  );
                }

                if (controller.isLoading.value &&
                    controller.conversations.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.errorMessage.value.isNotEmpty &&
                    controller.conversations.isEmpty) {
                  return _ErrorState(
                    message: controller.errorMessage.value,
                    onRetry: controller.loadConversations,
                  );
                }

                final wide = MediaQuery.sizeOf(context).width >= 900;
                final conversations = ConversationsPanel(
                  conversations: controller.filteredConversations,
                  selectedId: controller.selectedConversationId.value,
                  activeCount: controller.activeCount,
                  unreadCount: controller.unreadCount,
                  selectedFilter: controller.selectedFilter.value,
                  searchController: controller.searchController,
                  onSearchChanged: controller.onSearchChanged,
                  onFilterSelected: controller.selectFilter,
                  onConversationTap: controller.selectConversation,
                  onComposeTap: controller.monitoring.value ||
                          !controller.canWriteMessages
                      ? null
                      : () => _openNewConversation(context, controller),
                  onMarkAllRead:
                      controller.unreadCount > 0 ? controller.markAllRead : null,
                  showingArchived: controller.showingArchived.value,
                  onToggleArchived: controller.toggleArchived,
                );
                final selected = controller.selectedConversation;
                final archived = selected?.isArchived ?? false;
                final readOnly = controller.monitoring.value ||
                    !controller.canWriteMessages ||
                    archived;
                final chat = ChatPanel(
                  conversation: selected,
                  messages: controller.activeMessages.toList(),
                  messageController: controller.messageController,
                  onSend: controller.sendMessage,
                  isLoading: controller.isLoadingMessages.value,
                  isSending: controller.isSending.value,
                  readOnly: readOnly,
                  onHide: readOnly ? null : controller.hideConversation,
                  onShowParticipants: selected == null
                      ? null
                      : () => _showParticipants(context, controller),
                  onUnarchive: archived &&
                          controller.canWriteMessages &&
                          !controller.monitoring.value
                      ? controller.unarchiveConversation
                      : null,
                );

                if (wide) {
                  return Padding(
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      horizontal: 20,
                      top: 8,
                      bottom: 16,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: ResponsiveHelper.getResponsiveWidth(
                            context,
                            340,
                          ),
                          child: conversations,
                        ),
                        SizedBox(
                          width: ResponsiveHelper.getResponsiveWidth(
                            context,
                            16,
                          ),
                        ),
                        Expanded(child: chat),
                      ],
                    ),
                  );
                }

                return AppRefreshIndicator(
                  onRefresh: controller.refreshConversations,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      horizontal: 16,
                      top: 8,
                      bottom: 20,
                    ),
                    children: [
                      conversations,
                      SizedBox(
                        height:
                            ResponsiveHelper.getResponsiveHeight(context, 16),
                      ),
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.58,
                        child: chat,
                      ),
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

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context, all: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _ParticipantsSheet extends StatelessWidget {
  final List<HrConversationParticipant> people;
  final String? Function(String userId) roleFor;
  final VoidCallback? onAdd;

  const _ParticipantsSheet({
    required this.people,
    required this.roleFor,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.7;
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Participants',
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.textHeading,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${people.length} ${people.length == 1 ? 'person' : 'people'}',
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: people.isEmpty
                  ? const Text(
                      'No participants.',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: AppColors.textMuted,
                      ),
                    )
                  : ListView.separated(
                      itemCount: people.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final person = people[index];
                        final role = roleFor(person.userId);
                        return Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFFE8F3F2),
                              child: Text(
                                _initials(person.name),
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: AppColors.secondaryTeal,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    person.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: AppColors.textHeading,
                                    ),
                                  ),
                                  if (role != null && role.isNotEmpty)
                                    Text(
                                      role,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            if (onAdd != null) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: onAdd,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                ),
                icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                label: const Text('Add participant'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final word = parts.first;
    return word.substring(0, word.length >= 2 ? 2 : 1).toUpperCase();
  }
  return (parts.first[0] + parts[1][0]).toUpperCase();
}

class _AddParticipantSheet extends StatefulWidget {
  final List<HrMessageContact> contacts;

  const _AddParticipantSheet({required this.contacts});

  @override
  State<_AddParticipantSheet> createState() => _AddParticipantSheetState();
}

class _AddParticipantSheetState extends State<_AddParticipantSheet> {
  final TextEditingController _search = TextEditingController();
  final Set<String> _selected = <String>{};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final matches = widget.contacts.where((contact) {
      if (query.isEmpty) return true;
      return contact.name.toLowerCase().contains(query) ||
          contact.roleLabel.toLowerCase().contains(query);
    }).toList();
    final height = MediaQuery.sizeOf(context).height * 0.7;
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add participant',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.textHeading,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: Icon(Icons.search_rounded),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: matches.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No contacts match.',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: AppColors.textMuted,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final contact = matches[index];
                        final checked = _selected.contains(contact.id);
                        return CheckboxListTile(
                          value: checked,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            contact.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(contact.roleLabel),
                          onChanged: (_) {
                            setState(() {
                              if (checked) {
                                _selected.remove(contact.id);
                              } else {
                                _selected.add(contact.id);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _selected.isEmpty
                  ? null
                  : () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      Navigator.of(context).pop(_selected.toList());
                    },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

