import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show
        AndroidFlutterLocalNotificationsPlugin,
        AndroidInitializationSettings,
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

import '../../firebase_options.dart';

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
/// On Android, Firebase also displays a notification payload. That copy uses
/// a silent channel because a repeated tag replaces the first alert instead
/// of showing the next one. iOS already presents each system notification.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!Platform.isAndroid && message.notification != null) return;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}
  await prepareMessageNotifications();
  await showMessageNotification(message.data, remote: message);
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
  final id = nextMessageNotificationId();
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
int nextMessageNotificationId() {
  _messageNotificationSerial = (_messageNotificationSerial + 1) & 0x7fffffff;
  final mixed = Object.hash(
    DateTime.now().microsecondsSinceEpoch,
    _messageNotificationSerial,
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
    return PushMessage(
      id: message.messageId,
      title: _text(data['title']),
      body: _text(data['body']),
      data: data,
      source: source,
    );
  }
}

bool get firebasePushSupported =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);
