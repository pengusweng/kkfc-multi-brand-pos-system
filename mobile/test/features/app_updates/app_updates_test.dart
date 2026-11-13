import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/app_updates/app_update_service.dart';
import 'package:mobile/features/app_updates/optional_update_notice.dart';

Map<String, dynamic> _release(int build, {String? url}) => {
  'tag_name': 'android-build-$build',
  'draft': false,
  'prerelease': false,
  'assets': [
    {
      'name': 'kkfc-pos.apk',
      'browser_download_url':
          url ??
          'https://github.com/$appUpdateRepository/releases/download/android-build-$build/kkfc-pos.apk',
    },
  ],
};

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);
  final Map<String, dynamic> Function(RequestOptions) handler;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(handler(options)),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.kkfc.pos/app_updates');
  late Dio dio;
  late AppUpdateService service;
  var downloads = 0;
  setUp(() {
    downloads = 0;
    FlutterSecureStorage.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'installedBuildNumber') return 100;
          if (call.method == 'openUpdateDownload') {
            downloads++;
            return true;
          }
          return null;
        });
    dio = Dio();
    dio.httpClientAdapter = _Adapter((options) {
      expect(options.uri.host, 'api.github.com');
      expect(
        options.headers.keys.map((key) => key.toLowerCase()),
        isNot(contains('authorization')),
      );
      return _release(101);
    });
    service = AppUpdateService(dio);
  });
  tearDown(() {
    dio.close(force: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('Only published Android releases from the expected repository are accepted', () {
    expect(
      AppUpdate.fromRelease(_release(101), appUpdateRepository)?.buildNumber,
      101,
    );
    for (final release in [
      {..._release(101), 'draft': true},
      {..._release(101), 'prerelease': true},
      {..._release(101), 'tag_name': 'v1.0'},
      {..._release(101), 'assets': []},
      _release(101, url: 'https://example.com/kkfc-pos.apk'),
      _release(
        101,
        url:
            'http://github.com/$appUpdateRepository/releases/download/android-build-101/kkfc-pos.apk',
      ),
      _release(
        101,
        url: 'https://github.com/other/repo/releases/download/android-build-101/kkfc-pos.apk',
      ),
    ]) {
      expect(AppUpdate.fromRelease(release, appUpdateRepository), isNull);
    }
  });

  test(
    'Checking never downloads; dismissal survives a fresh service instance',
    () async {
      final update = await service.check();
      expect(update?.buildNumber, 101);
      expect(downloads, 0);
      await service.dismiss(update!);
      expect(await AppUpdateService(dio).check(), isNull);
      dio.httpClientAdapter = _Adapter((_) => _release(102));
      expect((await service.check())?.buildNumber, 102);
    },
  );

  test('Current or older builds and failed checks stay silent', () async {
    for (final build in [99, 100]) {
      dio.httpClientAdapter = _Adapter((_) => _release(build));
      expect(await service.check(), isNull);
    }
    dio.httpClientAdapter = _Adapter(
      (options) => throw DioException(requestOptions: options),
    );
    expect(await service.check(), isNull);
    expect(downloads, 0);
  });

  testWidgets(
    'Notice never blocks ordering and dismissal survives navigation',
    (tester) async {
      final update = AppUpdate.fromRelease(_release(101), appUpdateRepository)!;
      final container = ProviderContainer(
        overrides: [
          availableAppUpdateProvider.overrideWith((_) async => update),
          appUpdateServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);
      var orders = 0;
      Widget subject() => UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const OptionalUpdateNotice(),
                TextButton(
                  onPressed: () => orders++,
                  child: const Text('Continue ordering'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpWidget(subject());
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(downloads, 0);
      await tester.tap(find.text('Continue ordering'));
      expect(orders, 1);
      await tester.tap(find.byTooltip('Dismiss update'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(subject());
      await tester.pumpAndSettle();
      expect(find.text('Download update'), findsNothing);
      expect(container.read(dismissedAppUpdateProvider), 101);
    },
  );

  testWidgets('Only an explicit tap opens the download', (tester) async {
    final container = ProviderContainer(
      overrides: [
        availableAppUpdateProvider.overrideWith(
          (_) async =>
              AppUpdate.fromRelease(_release(101), appUpdateRepository),
        ),
        appUpdateServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: OptionalUpdateNotice())),
      ),
    );
    await tester.pumpAndSettle();
    expect(downloads, 0);
    await tester.tap(find.text('Download update'));
    await tester.pumpAndSettle();
    expect(downloads, 1);
  });
}
