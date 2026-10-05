import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'offline_config.dart';

/// Opens the app-owned encrypted Hive boxes.
///
/// The AES key lives in the platform keychain / keystore. If the key cannot
/// be read (keychain locked, plugin failure) boxes are opened in memory only
/// for this run instead of risking an unencrypted or truncated file.
class OfflineStorage {
  static const String _keyName = 'hr_offline_hive_key_v1';

  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    // resetOnError: a backup restored without its keystore entry is wiped
    // (and the boxes with it) instead of failing every launch.
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    // Background sync may run while the device is locked after first unlock.
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static bool _hiveReady = false;

  final HiveCipher? cipher;

  /// False when the key was unavailable and boxes live in memory only.
  final bool persistent;

  const OfflineStorage._(this.cipher, {required this.persistent});

  static const List<String> _ownedBoxes = [
    OfflineConfig.outboxBox,
    OfflineConfig.stagedUploadsBox,
    OfflineConfig.cacheBox,
    '${OfflineConfig.cacheBox}_meta',
  ];

  /// [requireKey] (background isolate) returns null instead of degrading.
  static Future<OfflineStorage?> open({bool requireKey = false}) async {
    if (!_hiveReady) {
      await Hive.initFlutter();
      _hiveReady = true;
    }
    _KeyResult key;
    try {
      key = await _readOrCreateKey(createIfMissing: !requireKey);
    } catch (error) {
      debugPrint('OfflineStorage: secure key unavailable ($error)');
      if (requireKey) return null;
      return const OfflineStorage._(null, persistent: false);
    }
    if (key.created) {
      // A fresh key cannot read boxes written with a lost one.
      for (final name in _ownedBoxes) {
        try {
          await Hive.deleteBoxFromDisk(name);
        } catch (_) {}
      }
    }
    return OfflineStorage._(HiveAesCipher(key.bytes), persistent: true);
  }

  static Future<_KeyResult> _readOrCreateKey({
    required bool createIfMissing,
  }) async {
    var existing = await _secure.read(key: _keyName);
    if ((existing == null || existing.isEmpty) && await _anyOwnedBoxOnDisk()) {
      // Data exists but the key read came back empty: re-check before
      // generating a new key, which would make that data unreadable.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      existing = await _secure.read(key: _keyName);
    }
    if (existing != null && existing.isNotEmpty) {
      final bytes = base64Url.decode(existing);
      if (bytes.length == 32) return _KeyResult(bytes, created: false);
    }
    if (!createIfMissing) {
      throw StateError('Offline storage key missing');
    }
    final generated = Hive.generateSecureKey();
    await _secure.write(key: _keyName, value: base64UrlEncode(generated));
    return _KeyResult(generated, created: true);
  }

  static Future<bool> _anyOwnedBoxOnDisk() async {
    for (final name in _ownedBoxes) {
      try {
        if (await Hive.boxExists(name)) return true;
      } catch (_) {}
    }
    return false;
  }

  Future<Box<String>> openBox(String name) async {
    if (!persistent) {
      return Hive.openBox<String>('${name}_mem', bytes: Uint8List(0));
    }
    try {
      return await Hive.openBox<String>(name, encryptionCipher: cipher);
    } catch (error) {
      debugPrint('OfflineStorage: resetting unreadable box $name ($error)');
      await Hive.deleteBoxFromDisk(name);
      return Hive.openBox<String>(name, encryptionCipher: cipher);
    }
  }

  /// Large values (read cache) use a lazy box so they are not all held in
  /// memory. In degraded mode an in-memory box is used instead.
  Future<BoxBase<String>> openLargeBox(String name) async {
    if (!persistent) {
      return Hive.openBox<String>('${name}_mem', bytes: Uint8List(0));
    }
    try {
      return await Hive.openLazyBox<String>(name, encryptionCipher: cipher);
    } catch (error) {
      debugPrint('OfflineStorage: resetting unreadable box $name ($error)');
      await Hive.deleteBoxFromDisk(name);
      return Hive.openLazyBox<String>(name, encryptionCipher: cipher);
    }
  }
}

class _KeyResult {
  final Uint8List bytes;
  final bool created;

  _KeyResult(List<int> bytes, {required this.created})
      : bytes = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
}
