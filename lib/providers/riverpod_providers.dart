import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:GitSync/api/manager/git_manager.dart';
import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/api/logger.dart';
import 'package:GitSync/global.dart';

abstract class CachedGitNotifier<T> extends AsyncNotifier<T> {
  Future<T> readCache();
  Future<T> fetchLive();
  Future<void> writeCache(T value);

  @override
  Future<T> build() async {
    var cancelled = false;
    ref.onDispose(() => cancelled = true);

    final cached = await readCache();

    () async {
      try {
        final live = await fetchLive();
        if (!cancelled) {
          state = AsyncData(live);
          await writeCache(live);
        }
      } catch (_) {}
    }();

    return cached;
  }

  void set(T value) {
    state = AsyncData(value);
    writeCache(value);
  }
}

class BranchNameNotifier extends CachedGitNotifier<String?> {
  @override
  Future<String?> readCache() => uiSettingsManager.getStringNullable(StorageKey.setman_branchName);

  @override
  Future<String?> fetchLive() => runGitOperation<String?>(LogType.BranchName, (event) => event?["result"]);

  @override
  Future<void> writeCache(String? value) => uiSettingsManager.setStringNullable(StorageKey.setman_branchName, value);
}

final branchNameProvider = AsyncNotifierProvider<BranchNameNotifier, String?>(BranchNameNotifier.new);

class RemoteUrlLinkNotifier extends CachedGitNotifier<(String, String)?> {
  @override
  Future<(String, String)?> readCache() async {
    final cached = await uiSettingsManager.getStringList(StorageKey.setman_remoteUrlLink);
    if (cached.isEmpty) return null;
    return (cached.first, cached.last);
  }

  @override
  Future<(String, String)?> fetchLive() => runGitOperation<(String, String)?>(
    LogType.GetRemoteUrlLink,
    (event) => event == null || event["result"] == null ? null : (event["result"][0] as String, event["result"][1] as String),
  );

  @override
  Future<void> writeCache((String, String)? value) =>
      uiSettingsManager.setStringList(StorageKey.setman_remoteUrlLink, value == null ? [] : [value.$1, value.$2]);
}

final remoteUrlLinkProvider = AsyncNotifierProvider<RemoteUrlLinkNotifier, (String, String)?>(RemoteUrlLinkNotifier.new);

class ListRemotesNotifier extends CachedGitNotifier<List<String>> {
  @override
  Future<List<String>> readCache() => uiSettingsManager.getStringList(StorageKey.setman_remotes);

  @override
  Future<List<String>> fetchLive() => runGitOperation<List<String>>(
    LogType.ListRemotes,
    (event) => event?["result"].map<String>((r) => "$r").toList() ?? <String>[],
  );

  @override
  Future<void> writeCache(List<String> value) => uiSettingsManager.setStringList(StorageKey.setman_remotes, value);
}

final listRemotesProvider = AsyncNotifierProvider<ListRemotesNotifier, List<String>>(ListRemotesNotifier.new);
