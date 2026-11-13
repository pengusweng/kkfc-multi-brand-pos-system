import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const appUpdateRepository = String.fromEnvironment(
  'APP_UPDATE_REPOSITORY',
  defaultValue: 'pengusweng/kkfc-multi-brand-pos-system',
);

class AppUpdate {
  const AppUpdate({required this.buildNumber, required this.downloadUrl});

  final int buildNumber;
  final Uri downloadUrl;

  static AppUpdate? fromRelease(
    Map<String, dynamic> release,
    String repository,
  ) {
    if (release['draft'] == true || release['prerelease'] == true) return null;
    final tag = release['tag_name'];
    if (tag is! String) return null;
    final match = RegExp(r'^android-build-(\d+)$').firstMatch(tag);
    final build = int.tryParse(match?.group(1) ?? '');
    final assets = release['assets'];
    if (build == null || build < 1 || assets is! List) return null;
    for (final asset in assets) {
      if (asset is! Map<String, dynamic> || asset['name'] != 'kkfc-pos.apk') {
        continue;
      }
      final url = Uri.tryParse(asset['browser_download_url']?.toString() ?? '');
      if (url == null ||
          url.scheme != 'https' ||
          url.host != 'github.com' ||
          url.port != 443 ||
          url.userInfo.isNotEmpty ||
          url.hasQuery ||
          url.hasFragment ||
          url.path != '/$repository/releases/download/$tag/kkfc-pos.apk') {
        continue;
      }
      return AppUpdate(buildNumber: build, downloadUrl: url);
    }
    return null;
  }
}

/// This client is intentionally separate from the authenticated POS API client.
class AppUpdateService {
  AppUpdateService(this._dio, {this.repository = appUpdateRepository});

  final Dio _dio;
  final String repository;
  static const _channel = MethodChannel('com.kkfc.pos/app_updates');
  static const _dismissedKey = 'dismissed_android_update_build';
  final _storage = const FlutterSecureStorage();

  Future<AppUpdate?> check() async {
    try {
      if (!RegExp(r'^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$').hasMatch(repository)) {
        return null;
      }
      final installed = await _channel.invokeMethod<int>(
        'installedBuildNumber',
      );
      if (installed == null) return null;
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.github.com/repos/$repository/releases/latest',
      );
      final release = response.data;
      if (release == null) return null;
      final update = AppUpdate.fromRelease(release, repository);
      if (update == null || update.buildNumber <= installed) return null;
      String? dismissed;
      try {
        dismissed = await _storage.read(key: _dismissedKey);
      } catch (_) {
        // Storage failures must never affect ordering or the update check.
      }
      if (dismissed == update.buildNumber.toString()) return null;
      return update;
    } catch (_) {
      // No release, offline, rate limits, or platform failures are all silent.
      return null;
    }
  }

  Future<void> dismiss(AppUpdate update) async {
    try {
      await _storage.write(
        key: _dismissedKey,
        value: update.buildNumber.toString(),
      );
    } catch (_) {}
  }

  Future<bool> download(AppUpdate update) async {
    try {
      return await _channel.invokeMethod<bool>('openUpdateDownload', {
            'url': update.downloadUrl.toString(),
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }
}

final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 3),
      sendTimeout: const Duration(seconds: 3),
      receiveTimeout: const Duration(seconds: 5),
      headers: const {
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'KKFC-POS',
      },
    ),
  );
  ref.onDispose(() => dio.close(force: true));
  return AppUpdateService(dio);
});

/// Checked at most once per app session, without blocking app launch or login.
final availableAppUpdateProvider = FutureProvider<AppUpdate?>((ref) async {
  const enabled = bool.fromEnvironment('APP_UPDATES_ENABLED');
  if (!enabled || kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return null;
  }
  return ref.watch(appUpdateServiceProvider).check();
});

class DismissedAppUpdateNotifier extends Notifier<int?> {
  @override
  int? build() => null;
  void dismiss(int buildNumber) => state = buildNumber;
}

final dismissedAppUpdateProvider =
    NotifierProvider<DismissedAppUpdateNotifier, int?>(
      DismissedAppUpdateNotifier.new,
    );
