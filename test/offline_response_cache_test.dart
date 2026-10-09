import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

import 'package:comprehensive_hr_and_ops/core/network/response_cache.dart';

void main() {
  late Directory tmp;
  var scope = 'acme|u1';

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('cache_test');
    Hive.init(tmp.path);
    scope = 'acme|u1';
  });

  tearDown(() async {
    await Hive.close();
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  Future<ResponseCache> open({int maxEntries = 100, int maxBytes = 1 << 20}) async {
    final cache = ResponseCache(
      values: await Hive.openLazyBox<String>('values'),
      meta: await Hive.openBox<String>('values_meta'),
      scope: () => scope,
      maxEntries: maxEntries,
      maxBytes: maxBytes,
    );
    await cache.ensureReady();
    return cache;
  }

  test('round-trips a body with the time it was saved', () async {
    final cache = await open();
    final before = DateTime.now();
    await cache.put(
      method: 'GET',
      path: '/staff/dashboard',
      query: {'b': 2, 'a': 1},
      body: {'ok': true},
    );

    final hit = await cache.read(
      method: 'GET',
      path: '/staff/dashboard',
      query: {'a': 1, 'b': 2},
    );
    expect(hit?.body, {'ok': true});
    expect(hit!.savedAt.isBefore(before.subtract(const Duration(seconds: 1))),
        isFalse);
  });

  test('another user or tenant never sees cached data', () async {
    final cache = await open();
    await cache.put(method: 'GET', path: '/clients', body: ['secret']);

    scope = 'acme|u2';
    expect(await cache.read(method: 'GET', path: '/clients'), isNull);
    scope = 'other|u1';
    expect(await cache.read(method: 'GET', path: '/clients'), isNull);
    scope = 'acme|u1';
    expect((await cache.read(method: 'GET', path: '/clients'))?.body, ['secret']);
  });

  test('survives a restart', () async {
    var cache = await open();
    await cache.put(method: 'GET', path: '/a', body: {'v': 1});
    await Hive.close();

    cache = await open();
    expect((await cache.read(method: 'GET', path: '/a'))?.body, {'v': 1});
    expect(cache.entryCount, 1);
  });

  test('evicts least recently used entries beyond the cap', () async {
    final cache = await open(maxEntries: 10);
    for (var i = 0; i < 10; i++) {
      await cache.put(method: 'GET', path: '/item/$i', body: {'i': i});
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }
    // Touch the oldest so it is kept.
    await cache.read(method: 'GET', path: '/item/0');
    await cache.put(method: 'GET', path: '/item/10', body: {'i': 10});

    expect(cache.entryCount, lessThanOrEqualTo(10));
    expect(await cache.read(method: 'GET', path: '/item/0'), isNotNull);
    expect(await cache.read(method: 'GET', path: '/item/1'), isNull);
    expect(await cache.read(method: 'GET', path: '/item/10'), isNotNull);
  });

  group('date/time window fallback', () {
    final day1 = DateTime.utc(2026, 10, 5, 8, 14, 3);

    Map<String, dynamic> q(DateTime from, {String residence = 'r1'}) => {
          'residenceId': residence,
          'from': from.toIso8601String(),
          'to': from.add(const Duration(days: 7)).toIso8601String(),
          'page': 1,
        };

    test('a request built from "now" later finds the earlier copy', () async {
      final cache = await open();
      await cache.put(method: 'GET', path: '/shifts', query: q(day1), body: 'A');

      final later = day1.add(const Duration(hours: 5, minutes: 3));
      final hit = await cache.read(method: 'GET', path: '/shifts', query: q(later));
      expect(hit?.body, 'A');
    });

    test('picks the newest close copy', () async {
      final cache = await open();
      await cache.put(method: 'GET', path: '/shifts', query: q(day1), body: 'old');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await cache.put(
        method: 'GET',
        path: '/shifts',
        query: q(day1.add(const Duration(hours: 2))),
        body: 'new',
      );
      final hit = await cache.read(
        method: 'GET',
        path: '/shifts',
        query: q(day1.add(const Duration(hours: 3))),
      );
      expect(hit?.body, 'new');
    });

    test('never serves a different week', () async {
      final cache = await open();
      await cache.put(method: 'GET', path: '/shifts', query: q(day1), body: 'A');
      final nextWeek = day1.add(const Duration(days: 7));
      expect(
        await cache.read(method: 'GET', path: '/shifts', query: q(nextWeek)),
        isNull,
      );
    });

    test('never serves another residence or page', () async {
      final cache = await open();
      await cache.put(method: 'GET', path: '/shifts', query: q(day1), body: 'A');
      expect(
        await cache.read(
          method: 'GET',
          path: '/shifts',
          query: q(day1, residence: 'r2'),
        ),
        isNull,
      );
      expect(
        await cache.read(
          method: 'GET',
          path: '/shifts',
          query: {...q(day1), 'page': 2},
        ),
        isNull,
      );
    });

    test('requests without dates still need an exact match', () async {
      final cache = await open();
      await cache.put(
        method: 'GET',
        path: '/clients',
        query: const {'residenceId': 'r1'},
        body: 'A',
      );
      expect(
        await cache.read(
          method: 'GET',
          path: '/clients',
          query: const {'residenceId': 'r2'},
        ),
        isNull,
      );
    });

    test('fallback survives a restart', () async {
      var cache = await open();
      await cache.put(method: 'GET', path: '/shifts', query: q(day1), body: 'A');
      await Hive.close();
      cache = await open();
      final hit = await cache.read(
        method: 'GET',
        path: '/shifts',
        query: q(day1.add(const Duration(hours: 1))),
      );
      expect(hit?.body, 'A');
    });
  });

  test('clear removes everything', () async {
    final cache = await open();
    await cache.put(method: 'GET', path: '/a', body: 1);
    await cache.clear();
    expect(cache.entryCount, 0);
    expect(await cache.read(method: 'GET', path: '/a'), isNull);
  });
}
