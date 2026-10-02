import 'dart:async';

import 'package:comprehensive_hr_and_ops/core/roles/user_session.dart';
import 'package:comprehensive_hr_and_ops/features/family/dashboard/data/mappers/family_notifications_mapper.dart';
import 'package:comprehensive_hr_and_ops/features/family/dashboard/domain/entities/family_dashboard_overview.dart';
import 'package:comprehensive_hr_and_ops/features/family/dashboard/domain/entities/family_notification.dart';
import 'package:comprehensive_hr_and_ops/features/family/dashboard/domain/entities/family_notification_target.dart';
import 'package:comprehensive_hr_and_ops/features/family/dashboard/domain/entities/family_search_hit.dart';
import 'package:comprehensive_hr_and_ops/features/family/dashboard/domain/repositories/family_dashboard_repository.dart';
import 'package:comprehensive_hr_and_ops/features/family/dashboard/presentation/controllers/family_notifications_controller.dart';
import 'package:comprehensive_hr_and_ops/features/family/dashboard/presentation/navigation/family_notification_navigator.dart';
import 'package:comprehensive_hr_and_ops/features/family/dashboard/presentation/pages/family_notifications_page.dart';
import 'package:comprehensive_hr_and_ops/features/family/documents/presentation/pages/family_documents_page.dart';
import 'package:comprehensive_hr_and_ops/features/family/messages/data/mappers/family_messages_mapper.dart';
import 'package:comprehensive_hr_and_ops/features/family/messages/domain/entities/conversation_preview.dart';
import 'package:comprehensive_hr_and_ops/features/family/messages/domain/entities/family_conversation_thread.dart';
import 'package:comprehensive_hr_and_ops/features/family/messages/domain/entities/message_attachment.dart';
import 'package:comprehensive_hr_and_ops/features/family/messages/domain/repositories/family_messages_repository.dart';
import 'package:comprehensive_hr_and_ops/features/family/messages/presentation/controllers/compose_message_controller.dart';
import 'package:comprehensive_hr_and_ops/features/family/messages/presentation/controllers/family_conversation_controller.dart';
import 'package:comprehensive_hr_and_ops/features/family/messages/presentation/pages/compose_message_page.dart';
import 'package:comprehensive_hr_and_ops/features/family/messages/presentation/pages/family_conversation_page.dart';
import 'package:comprehensive_hr_and_ops/features/family/messages/presentation/widgets/send_message_button.dart';
import 'package:comprehensive_hr_and_ops/features/family/profile_settings/presentation/pages/family_support_ticket_thread_page.dart';
import 'package:comprehensive_hr_and_ops/features/family/profile_settings/presentation/pages/family_support_tickets_page.dart';
import 'package:comprehensive_hr_and_ops/features/family/visit_requests/presentation/pages/visit_request_details_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

const _me = 'c05426f7-1d5f-4f33-a90a-54a5169ee233';
const _conversationId = '3b17ab63-fdba-4a51-97aa-5f894d463b4c';

/// Shape of the live `GET /family/messages/:id` body for this account.
Map<String, dynamic> _liveThreadBody() => {
  'success': true,
  'data': [
    {
      'id': '58e446f1',
      'conversationId': _conversationId,
      'senderId': '99f7eec5',
      'body': 'Ayaan had a settled week.',
      'createdAt': '2026-08-27T09:33:09.190Z',
      'sender': {'id': '99f7eec5', 'name': 'Maya Rahman'},
    },
    {
      'id': '02840694',
      'conversationId': _conversationId,
      'senderId': _me,
      'body': 'hi',
      'createdAt': '2026-09-29T09:29:01.865Z',
      'sender': {'id': _me, 'name': 'Shirin Karim'},
    },
  ],
};

class _FakeMessagesRepository implements FamilyMessagesRepository {
  FamilyConversationThread thread = FamilyMessagesMapper.threadFrom(
    _liveThreadBody(),
    currentUserId: _me,
  );
  Completer<Result<FamilyChatMessage?>>? pendingSend;
  Completer<Result<String?>>? pendingStart;
  final List<String> sentBodies = [];
  int conversationLoads = 0;
  List<String> linkedClientIds = const ['client-1'];

  @override
  Future<Result<List<String>>> getLinkedClientIds() async =>
      Result.success(linkedClientIds);

  @override
  Future<Result<FamilyConversationThread>> getConversation(String id) async {
    conversationLoads++;
    return Result.success(thread);
  }

  @override
  Future<Result<List<ConversationPreview>>> getConversations() async =>
      Result.success(const []);

  @override
  Future<Result<FamilyChatMessage?>> sendInConversation({
    required String conversationId,
    required String body,
    bool highPriority = false,
    List<MessageAttachment> attachments = const [],
  }) {
    sentBodies.add(body);
    pendingSend = Completer();
    return pendingSend!.future;
  }

  @override
  Future<Result<String?>> startConversation({
    required String clientId,
    required String body,
    bool highPriority = false,
    List<MessageAttachment> attachments = const [],
  }) {
    sentBodies.add(body);
    pendingStart = Completer();
    return pendingStart!.future;
  }

  @override
  Future<Result<MessageAttachment>> uploadAttachment({
    required String localPath,
    required String fileName,
    required String fileType,
  }) async => Result.failure(const ApiError(message: 'unused'));
}

class _FakeDashboardRepository implements FamilyDashboardRepository {
  _FakeDashboardRepository(this.notifications);

  List<FamilyNotification> notifications;
  final List<String> markedRead = [];

  @override
  Future<Result<List<FamilyNotification>>> getNotifications() async =>
      Result.success(notifications);

  @override
  Future<Result<void>> markNotificationRead(String id) async {
    markedRead.add(id);
    notifications = [
      for (final item in notifications)
        item.id == id ? item.copyWith(isRead: true) : item,
    ];
    return Result.success(null);
  }

  @override
  Future<Result<void>> markAllNotificationsRead() async => Result.success(null);

  @override
  Future<Result<FamilyDashboardOverview>> getOverview() =>
      throw UnimplementedError();

  @override
  Future<Result<List<FamilySearchHit>>> search(String query) =>
      throw UnimplementedError();
}

Future<_FakeMessagesRepository> _pumpConversation(WidgetTester tester) async {
  final repo = _FakeMessagesRepository();
  Get.put(
    FamilyConversationController(
      conversationId: _conversationId,
      repository: repo,
    ),
    tag: _conversationId,
  );
  await tester.pumpWidget(
    const GetMaterialApp(
      home: FamilyConversationPage(conversationId: _conversationId),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

String _inputText(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!.text;

void main() {
  tearDown(Get.reset);

  group('F04 family conversation send', () {
    test(
      'own messages are outgoing by sender id (live payload has no role)',
      () {
        final thread = FamilyMessagesMapper.threadFrom(
          _liveThreadBody(),
          currentUserId: _me,
        );
        expect(
          thread.messages.first.direction,
          FamilyMessageDirection.incoming,
        );
        expect(thread.messages.first.senderName, 'Maya Rahman');
        expect(thread.messages.last.direction, FamilyMessageDirection.outgoing);
        expect(thread.messages.last.senderName, 'You');
      },
    );

    testWidgets(
      'input clears and the message shows immediately while sending',
      (tester) async {
        final repo = await _pumpConversation(tester);

        await tester.enterText(find.byType(TextField), 'See you Saturday');
        await tester.tap(find.byIcon(Icons.send_rounded));
        await tester.pump();

        expect(repo.sentBodies, ['See you Saturday']);
        expect(_inputText(tester), isEmpty);
        expect(find.text('See you Saturday'), findsOneWidget);
        expect(find.text('Sending…'), findsOneWidget);

        repo.thread = repo.thread.copyWith(
          messages: [
            ...repo.thread.messages,
            const FamilyChatMessage(
              id: 'server-1',
              text: 'See you Saturday',
              direction: FamilyMessageDirection.outgoing,
              timeLabel: '10:00 AM',
              senderName: 'You',
            ),
          ],
        );
        repo.pendingSend!.complete(
          Result.success(
            FamilyMessagesMapper.messageFrom({
              'id': 'server-1',
              'body': 'See you Saturday',
              'senderId': _me,
              'sender': {'id': _me, 'name': 'Shirin Karim'},
              'createdAt': DateTime.now().toIso8601String(),
            }, currentUserId: _me),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Sending…'), findsNothing);
        expect(find.text('See you Saturday'), findsOneWidget);
        expect(find.byIcon(Icons.done_all_rounded), findsNWidgets(2));
        expect(repo.conversationLoads, 2);
      },
    );

    testWidgets('a failed send removes the bubble and restores the text', (
      tester,
    ) async {
      final repo = await _pumpConversation(tester);

      await tester.enterText(find.byType(TextField), 'Can I visit Sunday?');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      expect(_inputText(tester), isEmpty);
      expect(find.text('Can I visit Sunday?'), findsOneWidget);

      repo.pendingSend!.complete(
        Result.failure(const ApiError(message: 'Conversation not found')),
      );
      await tester.pump();

      expect(_inputText(tester), 'Can I visit Sunday?');
      expect(find.text('Sending…'), findsNothing);
      final controller = Get.find<FamilyConversationController>(
        tag: _conversationId,
      );
      expect(
        controller.thread!.messages.map((m) => m.text),
        isNot(contains('Can I visit Sunday?')),
      );
    });
  });

  group('F04 compose new message', () {
    Future<_FakeMessagesRepository> openCompose(
      WidgetTester tester, {
      required List<String> linked,
      String? selected,
    }) async {
      final repo = _FakeMessagesRepository()..linkedClientIds = linked;
      final session = UserSession();
      if (selected != null) session.selectClient(selected);
      Get.put(session);
      if (GetIt.I.isRegistered<FamilyMessagesRepository>()) {
        GetIt.I.unregister<FamilyMessagesRepository>();
      }
      GetIt.I.registerSingleton<FamilyMessagesRepository>(repo);
      addTearDown(() => GetIt.I.unregister<FamilyMessagesRepository>());
      await tester.pumpWidget(
        const GetMaterialApp(home: ComposeMessagePage()),
      );
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('no linked resident: explains why and disables Send', (
      tester,
    ) async {
      final repo = await openCompose(tester, linked: const []);

      expect(
        find.byKey(const Key('compose-not-linked-notice')),
        findsOneWidget,
      );
      expect(find.text(ComposeMessageController.notLinkedMessage), findsOneWidget);
      expect(find.textContaining('Open Home first'), findsNothing);
      expect(
        tester.widget<SendMessageButton>(find.byType(SendMessageButton)).onTap,
        isNull,
      );

      await tester.enterText(find.byType(TextField).first, 'Hello');
      await tester.tap(find.text('Send Message'));
      await tester.pumpAndSettle();
      expect(repo.sentBodies, isEmpty);
    });

    testWidgets('linked resident is picked even when Home was never opened', (
      tester,
    ) async {
      await openCompose(tester, linked: const ['client-9']);

      expect(find.byKey(const Key('compose-not-linked-notice')), findsNothing);
      expect(Get.find<UserSession>().selectedClientId, 'client-9');
      expect(
        tester.widget<SendMessageButton>(find.byType(SendMessageButton)).onTap,
        isNotNull,
      );
    });

    testWidgets('clears the draft, shows the web toast and opens the thread', (
      tester,
    ) async {
      final repo = _FakeMessagesRepository();
      final session = UserSession()..selectClient('client-1');
      Get.put(session);
      Get.put(
        FamilyConversationController(
          conversationId: 'new-thread',
          repository: repo,
        ),
        tag: 'new-thread',
      );
      final compose = ComposeMessageController(
        repository: repo,
        session: session,
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Get.to(
                  () => Scaffold(
                    body: Column(
                      children: [
                        TextField(controller: compose.messageController),
                        Obx(
                          () => SendMessageButton(
                            isSending: compose.isSending.value,
                            onTap: compose.sendMessage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Hello care team');
      await tester.tap(find.text('Send Message'));
      await tester.pump();
      expect(find.text('Sending...'), findsOneWidget);
      expect(repo.sentBodies, ['Hello care team']);

      repo.pendingStart!.complete(Result.success('new-thread'));
      await tester.pumpAndSettle();

      expect(compose.messageController.text, isEmpty);
      expect(find.text('Message sent!'), findsWidgets);
      expect(
        find.text('A member of the care team will respond shortly.'),
        findsWidgets,
      );
      expect(find.byType(FamilyConversationPage), findsOneWidget);
    });
  });

  group('F10 notification tap navigation', () {
    FamilyNotification notification(Map<String, dynamic> json) =>
        FamilyNotificationsMapper.fromJson({
          'id': 'n-${json.hashCode}',
          'title': 'Title',
          'isRead': false,
          'createdAt': '2026-09-29T08:07:06.979Z',
          ...json,
        });

    test('resolves live payloads and the web notificationHref types', () {
      const appointmentId = '921c17fb-a2be-42f4-9398-ac36d9b1d847';
      final cases = <Map<String, dynamic>, FamilyNotificationTarget?>{
        {
          'entityType': 'appointment',
          'entityId': appointmentId,
          'eventKey': 'appointments.decided',
          'metaJson': {
            'eventKey': 'appointments.decided',
            'appointmentId': appointmentId,
          },
        }: const FamilyNotificationTarget(
          FamilyNotificationDestination.appointmentDetail,
          appointmentId,
        ),
        {
          'entityType': 'appointment',
          'metaJson': {'appointmentId': appointmentId},
        }: const FamilyNotificationTarget(
          FamilyNotificationDestination.appointmentDetail,
          appointmentId,
        ),
        {'eventKey': 'appointments.changed'}: const FamilyNotificationTarget(
          FamilyNotificationDestination.appointments,
        ),
        {
          'entityType': 'conversation',
          'entityId': 'conv-1',
        }: const FamilyNotificationTarget(
          FamilyNotificationDestination.conversation,
          'conv-1',
        ),
        {
          'eventKey': 'messaging.mentioned',
          'metaJson': {'conversationId': 'conv-2'},
        }: const FamilyNotificationTarget(
          FamilyNotificationDestination.conversation,
          'conv-2',
        ),
        {'entityType': 'family_update'}: const FamilyNotificationTarget(
          FamilyNotificationDestination.dailyUpdates,
        ),
        {
          'eventKey': 'family.daily_update_posted',
        }: const FamilyNotificationTarget(
          FamilyNotificationDestination.dailyUpdates,
        ),
        {
          'entityType': 'document',
          'entityId': 'doc-1',
        }: const FamilyNotificationTarget(
          FamilyNotificationDestination.documents,
        ),
        {
          'entityType': 'support_ticket',
          'entityId': 't-1',
        }: const FamilyNotificationTarget(
          FamilyNotificationDestination.supportTicket,
          't-1',
        ),
        {'eventKey': 'tickets.replied'}: const FamilyNotificationTarget(
          FamilyNotificationDestination.supportTickets,
        ),
        {'entityType': 'client', 'entityId': 'c-1'}:
            const FamilyNotificationTarget(FamilyNotificationDestination.home),
        {'entityType': 'shift', 'entityId': 's-1'}: null,
        {'entityType': 'invoice'}: null,
        {'eventKey': 'scheduling.shift_changed'}: null,
        <String, dynamic>{}: null,
      };
      cases.forEach((json, expected) {
        expect(
          FamilyNotificationTarget.resolve(notification(json)),
          expected,
          reason: '$json',
        );
      });
    });

    test('each destination maps to the existing Family screen', () {
      Type? pageType(FamilyNotificationDestination destination) =>
          FamilyNotificationNavigator.pageFor(
            FamilyNotificationTarget(destination, 'x'),
          )?.runtimeType;
      int? tab(FamilyNotificationDestination destination) =>
          FamilyNotificationNavigator.shellTabFor(
            FamilyNotificationTarget(destination),
          );

      expect(
        pageType(FamilyNotificationDestination.appointmentDetail),
        VisitRequestDetailsPage,
      );
      expect(
        pageType(FamilyNotificationDestination.conversation),
        FamilyConversationPage,
      );
      expect(
        pageType(FamilyNotificationDestination.documents),
        FamilyDocumentsPage,
      );
      expect(
        pageType(FamilyNotificationDestination.supportTicket),
        FamilySupportTicketThreadPage,
      );
      expect(
        pageType(FamilyNotificationDestination.supportTickets),
        FamilySupportTicketsPage,
      );
      expect(tab(FamilyNotificationDestination.home), 0);
      expect(tab(FamilyNotificationDestination.dailyUpdates), 1);
      expect(tab(FamilyNotificationDestination.appointments), 2);
      expect(tab(FamilyNotificationDestination.messages), 3);
    });

    testWidgets('tapping each notification navigates and marks it read', (
      tester,
    ) async {
      final items = [
        notification({
          'id': 'appt',
          'title': 'Family visit approved',
          'entityType': 'appointment',
          'entityId': 'a-1',
          'eventKey': 'appointments.decided',
        }),
        notification({
          'id': 'msg',
          'title': 'Mentioned in a conversation',
          'entityType': 'conversation',
          'entityId': 'conv-1',
        }),
        notification({
          'id': 'update',
          'title': 'Daily update shared',
          'eventKey': 'family.daily_update_posted',
        }),
        notification({
          'id': 'doc',
          'title': 'Document expiring',
          'entityType': 'document',
        }),
        notification({
          'id': 'ticket',
          'title': 'Support replied',
          'entityType': 'support_ticket',
          'entityId': 't-1',
        }),
        notification({
          'id': 'shift',
          'title': 'Shift changed',
          'entityType': 'shift',
          'entityId': 's-1',
        }),
      ];
      final repo = _FakeDashboardRepository(items);
      final opened = <FamilyNotificationTarget>[];
      Get.put(
        FamilyNotificationsController(repository: repo, navigate: opened.add),
      );

      await tester.pumpWidget(
        const GetMaterialApp(home: FamilyNotificationsPage()),
      );
      await tester.pumpAndSettle();

      for (final item in items) {
        await tester.tap(find.text(item.title));
        await tester.pumpAndSettle();
      }

      expect(opened, const [
        FamilyNotificationTarget(
          FamilyNotificationDestination.appointmentDetail,
          'a-1',
        ),
        FamilyNotificationTarget(
          FamilyNotificationDestination.conversation,
          'conv-1',
        ),
        FamilyNotificationTarget(FamilyNotificationDestination.dailyUpdates),
        FamilyNotificationTarget(FamilyNotificationDestination.documents),
        FamilyNotificationTarget(
          FamilyNotificationDestination.supportTicket,
          't-1',
        ),
      ]);
      expect(repo.markedRead, [
        'appt',
        'msg',
        'update',
        'doc',
        'ticket',
        'shift',
      ]);
      final controller = Get.find<FamilyNotificationsController>();
      expect(controller.items.every((item) => item.isRead), isTrue);

      await tester.tap(find.text('Family visit approved'));
      await tester.pumpAndSettle();
      expect(repo.markedRead.length, 6);
      expect(opened.length, 6);
    });
  });
}
