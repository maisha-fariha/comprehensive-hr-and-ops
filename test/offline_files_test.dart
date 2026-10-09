import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gems_core/gems_core.dart';

import 'package:comprehensive_hr_and_ops/core/offline/offline_file_cache.dart';
import 'package:comprehensive_hr_and_ops/core/offline/offline_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  var offline = false;
  var downloads = 0;

  Future<Result<List<int>>> Function() serve(List<int>? bytes) => () async {
        downloads++;
        return bytes == null
            ? Result.failure(const NetworkError(message: 'down', code: 'offline'))
            : Result.success(bytes);
      };

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('offline_files');
    offline = false;
    downloads = 0;
    OfflineFileCache.resetForTests();
    OfflineFileCache.enabled = true;
    OfflineFileCache.scope = () => 'acme|u1';
    OfflineFileCache.rootOverride = () async => tmp;
    OfflineFileCache.offlineOverride = () => offline;
  });

  tearDown(() async {
    OfflineFileCache.enabled = false;
    OfflineFileCache.scope = () => '';
    OfflineFileCache.rootOverride = null;
    OfflineFileCache.offlineOverride = null;
    OfflineFileCache.resetForTests();
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  group('OfflineFileCache', () {
    test('a file opened online opens again offline', () async {
      final online = await OfflineFileCache.remember('cir:1', serve([1, 2]));
      expect(online.value, [1, 2]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      offline = true;
      final again = await OfflineFileCache.remember('cir:1', serve([9]));
      expect(again.value, [1, 2]);
      expect(downloads, 1);
    });

    test('online always fetches the latest copy', () async {
      await OfflineFileCache.remember('cir:1', serve([1]));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final fresh = await OfflineFileCache.remember('cir:1', serve([2]));
      expect(fresh.value, [2]);
      expect(downloads, 2);
    });

    test('never-opened files explain they need one online visit', () async {
      offline = true;
      final result = await OfflineFileCache.remember('doc:x', serve([1]));
      expect(result.isFailure, isTrue);
      expect(result.error?.code, 'offline_uncached');
      expect(downloads, 0);
    });

    test('a failed download falls back to the saved copy only when asked',
        () async {
      await OfflineFileCache.remember('img:a', serve([5]));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final strict = await OfflineFileCache.remember('img:a', serve(null));
      expect(strict.isFailure, isTrue);
      final lenient = await OfflineFileCache.remember(
        'img:a',
        serve(null),
        serveCopyOnFailure: true,
      );
      expect(lenient.value, [5]);
    });

    test('copies are private to the signed-in person', () async {
      await OfflineFileCache.remember('doc:1', serve([7]));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      OfflineFileCache.scope = () => 'acme|u2';
      offline = true;
      final other = await OfflineFileCache.remember('doc:1', serve([1]));
      expect(other.isFailure, isTrue);
    });

    test('does nothing until offline mode is on', () async {
      OfflineFileCache.enabled = false;
      await OfflineFileCache.remember('doc:1', serve([7]));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(tmp.listSync(recursive: true).whereType<File>(), isEmpty);
    });
  });

  group('OfflineImage', () {
    test('stored photos use the saving provider with the same auth choice',
        () {
      final plain = OfflineImage.provider('https://cdn.example/a.jpg');
      final authed = OfflineImage.provider('/files/a.jpg', withAuth: true);
      expect(plain, isA<SavedNetworkImage>());
      expect((plain as SavedNetworkImage).withAuth, isFalse);
      expect((authed as SavedNetworkImage).withAuth, isTrue);
      expect(
        OfflineImage.provider('https://cdn.example/a.jpg'),
        equals(plain),
      );
    });

    test('a photo picked offline without an outbox falls back safely', () {
      final provider = OfflineImage.provider('offline-upload://abc/p.jpg');
      expect(provider, isA<ImageProvider>());
    });
  });
}
