import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../features/family/messages/presentation/controllers/family_conversation_controller.dart';
import '../../features/family/messages/presentation/pages/family_conversation_page.dart';
import '../../features/family/messages/presentation/pages/family_messages_list_page.dart';
import '../../features/hr/communication/presentation/controllers/communication_controller.dart';
import '../../features/hr/communication/presentation/pages/communication_page.dart';
import '../roles/user_role.dart';
import '../roles/user_session.dart';
import 'firebase_push_bridge.dart';

/// Opens Communication when a message push arrives, and refreshes the open
/// thread so the new message shows without leaving the screen.
class CommunicationPushRouter {
  final PushNotificationService _push;
  StreamSubscription<PushMessage>? _sub;
  Map<String, dynamic>? _pending;

  CommunicationPushRouter(this._push);

  void attach() {
    _sub ??= _push.messages.listen(_onMessage);
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }

  void _onMessage(PushMessage message) {
    final data = normalizePushData(message.data);
    if (message.source == NotificationSource.foreground) {
      unawaited(_onForeground(message.copyWith(data: data)));
      return;
    }
    if (!isCommunicationPush(data)) return;
    _pending = data;
    _flush();
  }

  Future<void> _onForeground(PushMessage message) async {
    try {
      await showMessageNotification(message.data);
      await dismissCollapsedFirebaseNotifications();
    } catch (_) {}
    if (!isCommunicationPush(message.data)) return;
    await _refreshOpenThread(conversationIdOf(message.data));
  }

  /// Local-notification tap, including a launch from a killed app.
  void openFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        _pending = Map<String, dynamic>.from(decoded);
        _flush();
      }
    } catch (_) {}
  }

  void _flush() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pending == null) return;
      if (!_navigatorReady()) {
        _flush();
        return;
      }
      final data = _pending!;
      _pending = null;
      unawaited(_open(data));
    });
  }

  Future<void> _open(Map<String, dynamic> data) async {
    if (!Get.isRegistered<UserSession>() ||
        !Get.find<UserSession>().isSignedIn) {
      return;
    }
    final session = Get.find<UserSession>();
    final id = conversationIdOf(data);
    if (session.role == UserRole.family) {
      await _openFamily(id);
      return;
    }
    if (!session.can('messaging')) return;
    await _openStaffOrManager(id, staff: session.role == UserRole.staff);
  }

  Future<void> _openFamily(String? id) async {
    if (id == null) {
      Get.to(() => const FamilyMessagesListPage());
      return;
    }
    if (Get.isRegistered<FamilyConversationController>(tag: id)) {
      await Get.find<FamilyConversationController>(tag: id).load(silent: true);
      if (_viewingFamily(id)) return;
    }
    Get.to(() => FamilyConversationPage(conversationId: id));
  }

  Future<void> _openStaffOrManager(String? id, {required bool staff}) async {
    if (Get.isRegistered<CommunicationController>()) {
      final controller = Get.find<CommunicationController>();
      await controller.loadConversations();
      if (id != null) {
        if (controller.selectedConversationId.value == id) {
          await controller.loadMessages(id);
        } else {
          await controller.selectConversation(id);
        }
      }
      if (_viewingCommunication()) return;
    }
    Get.to(
      () => CommunicationPage(
        initialConversationId: id,
        showStaffBottomNav: staff,
      ),
    );
  }

  Future<void> _refreshOpenThread(String? id) async {
    if (!Get.isRegistered<UserSession>() ||
        !Get.find<UserSession>().isSignedIn) {
      return;
    }
    final session = Get.find<UserSession>();
    if (session.role == UserRole.family) {
      if (id != null &&
          Get.isRegistered<FamilyConversationController>(tag: id)) {
        await Get.find<FamilyConversationController>(tag: id)
            .load(silent: true);
      }
      return;
    }
    if (!Get.isRegistered<CommunicationController>()) return;
    final controller = Get.find<CommunicationController>();
    await controller.loadConversations();
    if (id != null && controller.selectedConversationId.value == id) {
      await controller.loadMessages(id);
    }
  }

  bool _viewingCommunication() {
    final route = Get.currentRoute.toLowerCase();
    return route.contains('communication');
  }

  bool _viewingFamily(String? id) {
    if (id == null) return false;
    final route = Get.currentRoute.toLowerCase();
    return route.contains('familyconversation') &&
        Get.isRegistered<FamilyConversationController>(tag: id);
  }

  bool _navigatorReady() {
    try {
      return Get.key.currentState != null;
    } catch (_) {
      return false;
    }
  }
}

/// Flattens a nested `meta` object the backend may put on the push.
Map<String, dynamic> normalizePushData(Map<String, dynamic> data) {
  final copy = Map<String, dynamic>.from(data);
  final meta = copy['meta'] ?? copy['metaJson'];
  if (meta is String && meta.trim().startsWith('{')) {
    try {
      final decoded = jsonDecode(meta);
      if (decoded is Map) {
        copy.addAll(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
  } else if (meta is Map) {
    copy.addAll(Map<String, dynamic>.from(meta));
  }
  return copy;
}

/// True when the push is a Communication / family message.
bool isCommunicationPush(Map<String, dynamic> data) {
  final type = _token(data['entityType'] ?? data['type']).replaceAll('-', '_');
  final key = _token(data['eventKey'] ?? data['event']);
  if (type == 'conversation' || type == 'message') return true;
  if (key.startsWith('messaging.') || key.startsWith('messages.')) return true;
  if (_raw(data['conversationId']) != null) return true;
  return false;
}

String? conversationIdOf(Map<String, dynamic> data) {
  final direct = _raw(data['conversationId']) ?? _raw(data['threadId']);
  if (direct != null) return direct;
  final type = _token(data['entityType'] ?? data['type']).replaceAll('-', '_');
  if (type == 'conversation' || type == 'message') return _raw(data['entityId']);
  return null;
}

String? _raw(Object? value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty || text == 'null') return null;
  return text;
}

String _token(Object? value) => _raw(value)?.toLowerCase() ?? '';

/// Reads a local-notification launch that happened before the router attached.
Future<void> deliverLocalNotificationLaunch(CommunicationPushRouter router) async {
  final launch = await messageNotifications.getNotificationAppLaunchDetails();
  if (launch?.didNotificationLaunchApp != true) return;
  router.openFromPayload(launch?.notificationResponse?.payload);
}
