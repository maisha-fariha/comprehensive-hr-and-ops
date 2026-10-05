import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:uuid/uuid.dart';

import 'offline_config.dart';
import 'outbox_item.dart';

/// Files captured while offline, copied out of the picker's temp directory so
/// the OS cannot purge them before the owning write is replayed.
class StagedUploadStore {
  final Box<String> _box;
  final Future<Directory> Function() _rootDir;
  final Uuid _uuid;

  StagedUploadStore(
    this._box, {
    required Future<Directory> Function() rootDir,
    Uuid? uuid,
  })  : _rootDir = rootDir,
        _uuid = uuid ?? const Uuid();

  static final RegExp _tokenPattern = RegExp(
    '${RegExp.escape(OfflineConfig.stagedUploadScheme)}([A-Za-z0-9-]+)(/[^\\s"\']*)?',
  );

  static String tokenFor(String id, String filename) =>
      '${OfflineConfig.stagedUploadScheme}$id/${Uri.encodeComponent(filename)}';

  static bool isToken(Object? value) =>
      value is String && value.startsWith(OfflineConfig.stagedUploadScheme);

  /// Ids of staged uploads referenced anywhere inside a JSON body.
  static Set<String> referencedIds(dynamic body) {
    final ids = <String>{};
    void walk(dynamic node) {
      if (node is String) {
        for (final match in _tokenPattern.allMatches(node)) {
          ids.add(match.group(1)!);
        }
      } else if (node is Map) {
        node.values.forEach(walk);
      } else if (node is List) {
        node.forEach(walk);
      }
    }

    walk(body);
    return ids;
  }

  /// Copy of [body] with every staged token swapped for its uploaded URL.
  static dynamic replaceTokens(dynamic body, Map<String, String> urlsById) {
    if (body is String) {
      return body.replaceAllMapped(_tokenPattern, (m) {
        return urlsById[m.group(1)!] ?? m.group(0)!;
      });
    }
    if (body is Map) {
      return body.map((k, v) => MapEntry(k, replaceTokens(v, urlsById)));
    }
    if (body is List) {
      return [for (final v in body) replaceTokens(v, urlsById)];
    }
    return body;
  }

  /// Persists the single file in [form]. Returns an upload-shaped response
  /// whose URL is a placeholder token, or null when the form is unsupported.
  Future<Map<String, dynamic>?> stage({
    required FormData form,
    required String uploadPath,
    Map<String, dynamic>? uploadQuery,
  }) async {
    if (form.files.length != 1) return null;
    final entry = form.files.single;
    final file = entry.value;
    final id = _uuid.v4();
    final filename = (file.filename == null || file.filename!.trim().isEmpty)
        ? 'attachment'
        : file.filename!.trim();
    final dir = Directory('${(await _rootDir()).path}/$id');
    await dir.create(recursive: true);
    final target = File('${dir.path}/${_safeName(filename)}');
    final sink = target.openWrite();
    try {
      await sink.addStream(file.finalize());
    } finally {
      await sink.close();
    }

    final mime = file.contentType?.mimeType ?? _mimeFromName(filename);
    final attachment = OutboxAttachment(
      id: id,
      localPath: target.path,
      field: entry.key,
      filename: filename,
      mime: mime,
      uploadPath: uploadPath,
      uploadQuery: uploadQuery,
      fields: {for (final f in form.fields) f.key: f.value},
    );
    await _box.put(
      id,
      jsonEncode({
        'attachment': attachment.toJson(),
        'stagedAt': DateTime.now().toUtc().toIso8601String(),
      }),
    );

    final token = tokenFor(id, filename);
    final size = await target.length();
    return {
      'fileUrl': token,
      'url': token,
      'publicUrl': token,
      'fileType': mime,
      'mimeType': mime,
      'contentType': mime,
      'fileName': filename,
      'originalName': filename,
      'size': size,
      'offlineStaged': true,
    };
  }

  /// Moves staged uploads referenced by [body] out of the staging area so the
  /// owning outbox item carries them.
  Future<List<OutboxAttachment>> claim(dynamic body) async {
    final claimed = <OutboxAttachment>[];
    for (final id in referencedIds(body)) {
      final raw = _box.get(id);
      if (raw == null) continue;
      try {
        final map = (jsonDecode(raw) as Map).cast<String, dynamic>();
        claimed.add(
          OutboxAttachment.fromJson(
            (map['attachment'] as Map).cast<String, dynamic>(),
          ),
        );
        await _box.delete(id);
      } catch (_) {}
    }
    return claimed;
  }

  static FormData rebuildForm(OutboxAttachment attachment) {
    return FormData.fromMap({
      ...attachment.fields,
      attachment.field: MultipartFile.fromFileSync(
        attachment.localPath,
        filename: attachment.filename,
      ),
    });
  }

  Future<void> deleteFiles(Iterable<OutboxAttachment> attachments) async {
    for (final attachment in attachments) {
      try {
        final dir = File(attachment.localPath).parent;
        if (await dir.exists()) await dir.delete(recursive: true);
      } catch (_) {}
    }
  }

  /// Removes staged files never claimed by a queued write (form abandoned).
  Future<void> purgeOrphans({Duration ttl = OfflineConfig.orphanUploadTtl}) async {
    final cutoff = DateTime.now().subtract(ttl);
    for (final key in _box.keys.toList()) {
      final raw = _box.get(key);
      if (raw == null) continue;
      try {
        final map = (jsonDecode(raw) as Map).cast<String, dynamic>();
        final stagedAt = DateTime.tryParse('${map['stagedAt']}');
        if (stagedAt != null && stagedAt.isAfter(cutoff)) continue;
        final attachment = OutboxAttachment.fromJson(
          (map['attachment'] as Map).cast<String, dynamic>(),
        );
        await deleteFiles([attachment]);
      } catch (_) {}
      await _box.delete(key);
    }
  }

  Future<void> close() => _box.close();

  static String _safeName(String name) =>
      name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');

  static String _mimeFromName(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'heic':
        return 'image/heic';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      default:
        return 'application/octet-stream';
    }
  }
}
