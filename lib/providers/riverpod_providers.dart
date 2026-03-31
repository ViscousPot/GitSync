import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:GitSync/api/manager/git_manager.dart';
import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/api/logger.dart';
import 'package:GitSync/global.dart';

abstract class CachedGitNotifier<T> extends AsyncNotifier<T> {
  Future<T> readCache();
  Future<T> fetchLive();

  @override
  Future<T> build() async {
    var cancelled = false;
    ref.onDispose(() => cancelled = true);

    final cached = await readCache();

    () async {
      try {
        final live = await fetchLive();
        if (!cancelled) state = AsyncData(live);
      } catch (_) {}
    }();

    return cached;
  }

  void set(T value) {
    state = AsyncData(value);
  }
}

class BranchNameNotifier extends CachedGitNotifier<String?> {
  @override
  Future<String?> readCache() => uiSettingsManager.getStringNullable(StorageKey.setman_branchName);

  @override
  Future<String?> fetchLive() => runGitOperation<String?>(LogType.BranchName, (event) => event?["result"]);
}

final branchNameProvider = AsyncNotifierProvider<BranchNameNotifier, String?>(
  BranchNameNotifier.new,
);
