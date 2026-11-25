import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show DartPluginRegistrant;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show
        AndroidFlutterLocalNotificationsPlugin,
        AndroidInitializationSettings,
        AndroidNotificationCategory,
        AndroidNotificationChannel,
        AndroidNotificationDetails,
        DarwinInitializationSettings,
        DarwinNotificationDetails,
        FlutterLocalNotificationsPlugin,
        Importance,
        InitializationSettings,
        NotificationDetails,
        NotificationResponse,
        Priority;
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../firebase_options.dart';
import '../config/app_env.dart';

const messageNotificationChannelId = 'messages_high';
const messageNotificationIcon = 'ic_stat_message';

/// High-importance channel used for conversation pushes.
const messageNotificationChannel = AndroidNotificationChannel(
  messageNotificationChannelId,
  'Messages',
  description: 'New messages in Communication',
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin messageNotifications =
    FlutterLocalNotificationsPlugin();

/// Posts one alert per message.
///
/// The server reuses one Android tag (`FCM-Notification:…`, id 0). Android
/// then replaces the alert already in the tray and does not pop the next
/// message. This handler posts a new alert and removes that collapsed one.
/// iOS already presents each system notification.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!Platform.isAndroid && message.notification != null) return;
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}
  try {
    await prepareMessageNotifications();
    await showMessageNotification(message.data, remote: message);
    await dismissCollapsedFirebaseNotifications();
    await acknowledgeMessagePush(message.data);
    // Firebase posts its copy after this handler starts. Remove it once more
    // so the tray keeps the new alert, not the one shared tag.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await dismissCollapsedFirebaseNotifications();
  } catch (_) {}
}

/// Removes the server notification that always uses the same tag.
Future<void> dismissCollapsedFirebaseNotifications() async {
  final active = await messageNotifications.getActiveNotifications();
  for (final notification in active) {
    final tag = notification.tag ?? '';
    if (!tag.startsWith('FCM-Notification')) continue;
    await messageNotifications.cancel(id: notification.id ?? 0, tag: tag);
  }
}

Future<void> prepareMessageNotifications({
  void Function(NotificationResponse response)? onTap,
}) async {
  const settings = InitializationSettings(
    android: AndroidInitializationSettings(messageNotificationIcon),
    iOS: DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    ),
  );
  await messageNotifications.initialize(
    settings: settings,
    onDidReceiveNotificationResponse: onTap,
  );
  await messageNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(messageNotificationChannel);
}

Future<void> showMessageNotification(
  Map<String, dynamic> data, {
  RemoteMessage? remote,
}) async {
  final title = _text(remote?.notification?.title) ??
      _text(data['title']) ??
      'New message';
  final body = _text(remote?.notification?.body) ?? _text(data['body']) ?? '';
  final messageId = _text(data['messageId']) ?? remote?.messageId;
  final id = nextMessageNotificationId(messageId);
  await messageNotifications.show(
    id: id,
    title: title,
    body: body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        messageNotificationChannelId,
        'Messages',
        channelDescription: 'New messages in Communication',
        importance: Importance.high,
        priority: Priority.high,
        icon: messageNotificationIcon,
        ticker: body.isEmpty ? title : body,
        onlyAlertOnce: false,
        autoCancel: true,
        playSound: true,
        enableVibration: true,
        tag: 'msg-$id',
        category: AndroidNotificationCategory.message,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentSound: true,
      ),
    ),
    payload: jsonEncode(data),
  );
}

int _messageNotificationSerial = 0;

/// A new id for every message. Reusing the conversation id makes Android
/// replace the first alert, so later messages never pop up again.
int nextMessageNotificationId([String? messageId]) {
  _messageNotificationSerial = (_messageNotificationSerial + 1) & 0x7fffffff;
  final mixed = Object.hash(
    DateTime.now().microsecondsSinceEpoch,
    _messageNotificationSerial,
    messageId,
  );
  final id = mixed & 0x7fffffff;
  return id == 0 ? 1 : id;
}

String? _text(Object? value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty || text == 'null') return null;
  return text;
}

/// FCM token + message streams for [PushNotificationService].
class FirebasePushBridge {
  final _messages = StreamController<PushMessage>.broadcast();
  final _opened = StreamController<PushMessage>.broadcast();
  final _tokens = StreamController<String>.broadcast();

  PushNotificationProvider build() {
    return CustomPushNotificationProvider(
      initializeHandler: _initialize,
      permissionHandler: _requestPermission,
      tokenHandler: _token,
      // `/devices` stores the FCM registration token, not the installation id.
      // ignore: deprecated_member_use
      deleteTokenHandler: () => FirebaseMessaging.instance.deleteToken(),
      initialMessageHandler: _initialMessage,
      tokenRefreshStream: _tokens.stream,
      messageStream: _messages.stream,
      messageOpenedStream: _opened.stream,
    );
  }

  Future<void> _initialize() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: false,
    );
    FirebaseMessaging.onMessage.listen((message) {
      _messages.add(_toPush(message, NotificationSource.foreground));
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _opened.add(_toPush(message, NotificationSource.openedApp));
    });
    // ignore: deprecated_member_use
    messaging.onTokenRefresh.listen((token) {
      if (token.isNotEmpty) _tokens.add(token);
    });
  }

  Future<NotificationPermissionStatus> _requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission();
    await messageNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    return switch (settings.authorizationStatus) {
      AuthorizationStatus.authorized => NotificationPermissionStatus.granted,
      AuthorizationStatus.provisional =>
        NotificationPermissionStatus.provisional,
      AuthorizationStatus.notDetermined =>
        NotificationPermissionStatus.notDetermined,
      AuthorizationStatus.denied ||
      AuthorizationStatus.deniedPermanently =>
        NotificationPermissionStatus.denied,
    };
  }

  Future<String?> _token() async {
    try {
      // ignore: deprecated_member_use
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return null;
      return token;
    } catch (_) {
      return null;
    }
  }

  Future<PushMessage?> _initialMessage() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message == null) return null;
    return _toPush(message, NotificationSource.initialMessage);
  }

  PushMessage _toPush(RemoteMessage message, NotificationSource source) {
    final data = Map<String, dynamic>.from(message.data);
    final title = message.notification?.title;
    final body = message.notification?.body;
    if (title != null && title.isNotEmpty) data['title'] = title;
    if (body != null && body.isNotEmpty) data['body'] = body;
    final messageId = message.messageId;
    if (messageId != null && messageId.isNotEmpty) {
      data['messageId'] = messageId;
    }
    return PushMessage(
      id: message.messageId,
      title: _text(data['title']),
      body: _text(data['body']),
      data: data,
      source: source,
    );
  }
}

/// The server sends another message push only after the previous
/// `messaging.received` row is read. Clear that row when the alert is shown
/// so the next message can notify. The chat itself stays unread.
Future<void> acknowledgeMessagePush(Map<String, dynamic> data) async {
  final event = (data['eventKey'] ?? '').toString().toLowerCase();
  final conversationId = (data['conversationId'] ?? '').toString().trim();
  if (!event.startsWith('messaging.') && conversationId.isEmpty) return;
  try {
    final prefs = await SharedPreferences.getInstance();
    final access = prefs.getString('mobile_access_token');
    final tenant = prefs.getString('tenant_subdomain');
    if (access == null || access.isEmpty || tenant == null || tenant.isEmpty) {
      return;
    }
    final client = HttpClient();
    try {
      final body = await _pushGet(
        client,
        access,
        tenant,
        '/notifications?page=1&limit=20',
      );
      final rows = _notificationRows(body);
      final ids = <String>[];
      for (final row in rows) {
        if ((row['eventKey'] ?? '').toString() != 'messaging.received') {
          continue;
        }
        if (row['isRead'] == true) continue;
        final meta = row['metaJson'];
        final rowConversation = meta is Map
            ? (meta['conversationId'] ?? '').toString()
            : '';
        if (conversationId.isNotEmpty &&
            rowConversation.isNotEmpty &&
            rowConversation != conversationId) {
          continue;
        }
        final id = (row['id'] ?? '').toString();
        if (id.isNotEmpty) ids.add(id);
      }
      for (final id in ids) {
        await _pushPost(client, access, tenant, '/notifications/$id/read');
      }
    } finally {
      client.close(force: true);
    }
  } catch (_) {}
}

Future<dynamic> _pushGet(
  HttpClient client,
  String access,
  String tenant,
  String path,
) async {
  final request = await client.getUrl(Uri.parse('${AppEnv.apiBaseUrl}$path'));
  request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $access');
  request.headers.set('X-Tenant-Subdomain', tenant);
  request.headers.set(HttpHeaders.acceptHeader, 'application/json');
  final response = await request.close();
  final text = await response.transform(utf8.decoder).join();
  if (response.statusCode < 200 || response.statusCode >= 300) return null;
  return jsonDecode(text);
}

Future<void> _pushPost(
  HttpClient client,
  String access,
  String tenant,
  String path,
) async {
  final request = await client.postUrl(Uri.parse('${AppEnv.apiBaseUrl}$path'));
  request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $access');
  request.headers.set('X-Tenant-Subdomain', tenant);
  request.headers.set(HttpHeaders.acceptHeader, 'application/json');
  request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
  request.add(utf8.encode('{}'));
  final response = await request.close();
  await response.drain<void>();
}

List<Map<String, dynamic>> _notificationRows(dynamic body) {
  if (body is! Map) return const [];
  final data = body['data'];
  if (data is! List) return const [];
  return data.whereType<Map>().map(Map<String, dynamic>.from).toList();
}

bool get firebasePushSupported =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);
