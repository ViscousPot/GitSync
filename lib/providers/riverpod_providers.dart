import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:GitSync/api/manager/git_manager.dart';
import 'package:GitSync/api/manager/settings_manager.dart';
import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/api/logger.dart';
import 'package:GitSync/constant/strings.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/src/rust/api/git_manager.dart' as GitManagerRs;
import 'package:GitSync/type/git_provider.dart';
import 'package:GitSync/type/showcase_feature.dart';
import 'package:GitSync/api/manager/auth/git_provider_manager.dart';

abstract class SettingNotifier<T> extends AsyncNotifier<T> {
  Future<T> read();
  Future<void> write(T value);

  @override
  Future<T> build() => read();

  void set(T value) {
    state = AsyncData(value);
    write(value);
  }
}

abstract class CachedGitNotifier<T> extends AsyncNotifier<T> {
  Future<T> readCache(SettingsManager manager);
  Future<T> fetchLive();
  Future<void> writeCache(SettingsManager manager, T value);

  SettingsManager? _scopedManager;

  Future<bool> _isCurrentIndex(int buildIndex) async => await repoManager.getInt(StorageKey.repoman_repoIndex) == buildIndex;

  @override
  Future<T> build() async {
    final repoIndex = await repoManager.getInt(StorageKey.repoman_repoIndex);
    final manager = await SettingsManager.scoped(repoIndex);
    _scopedManager = manager;

    var cancelled = false;
    ref.onDispose(() => cancelled = true);

    bool cacheValid = true;
    late T cached;
    try {
      cached = await readCache(manager);
    } catch (e, s) {
      cacheValid = false;
      Logger.logError(LogType.Global, e, s);
    }

    if (cacheValid) {
      () async {
        try {
          final live = await fetchLive();
          if (!cancelled && await _isCurrentIndex(repoIndex)) {
            state = AsyncData(live);
            await writeCache(manager, live);
          }
        } on OperationNotExecuted {
        } catch (e, s) {
          if (!cancelled && await _isCurrentIndex(repoIndex)) {
            state = AsyncData(cached);
          }
          Logger.logError(LogType.Global, e, s);
        }
      }();

      return cached;
    }

    final live = await fetchLive();
    if (!cancelled && await _isCurrentIndex(repoIndex)) {
      await writeCache(manager, live);
    }
    return live;
  }

  void set(T value) {
    state = AsyncData(value);
    writeCache(_scopedManager ?? uiSettingsManager, value);
  }
}

class BranchNameNotifier extends CachedGitNotifier<String?> {
  @override
  Future<String?> readCache(SettingsManager manager) => manager.getStringNullable(StorageKey.setman_branchName);

  @override
  Future<String?> fetchLive() => runGitOperation<String?>(LogType.BranchName, (event) => event?["result"]);

  @override
  Future<void> writeCache(SettingsManager manager, String? value) => manager.setStringNullable(StorageKey.setman_branchName, value);
}

final branchNameProvider = AsyncNotifierProvider<BranchNameNotifier, String?>(BranchNameNotifier.new);

class RemoteUrlLinkNotifier extends CachedGitNotifier<(String, String)?> {
  @override
  Future<(String, String)?> readCache(SettingsManager manager) async {
    final cached = await manager.getStringList(StorageKey.setman_remoteUrlLink);
    if (cached.isEmpty) return null;
    return (cached.first, cached.last);
  }

  @override
  Future<(String, String)?> fetchLive() => runGitOperation<(String, String)?>(
    LogType.GetRemoteUrlLink,
    (event) => event == null || event["result"] == null ? null : (event["result"][0] as String, event["result"][1] as String),
  );

  @override
  Future<void> writeCache(SettingsManager manager, (String, String)? value) =>
      manager.setStringList(StorageKey.setman_remoteUrlLink, value == null ? [] : [value.$1, value.$2]);
}

final remoteUrlLinkProvider = AsyncNotifierProvider<RemoteUrlLinkNotifier, (String, String)?>(RemoteUrlLinkNotifier.new);

class ListRemotesNotifier extends CachedGitNotifier<List<String>> {
  @override
  Future<List<String>> readCache(SettingsManager manager) => manager.getStringList(StorageKey.setman_remotes);

  @override
  Future<List<String>> fetchLive() =>
      runGitOperation<List<String>>(LogType.ListRemotes, (event) => event?["result"].map<String>((r) => "$r").toList() ?? <String>[]);

  @override
  Future<void> writeCache(SettingsManager manager, List<String> value) => manager.setStringList(StorageKey.setman_remotes, value);
}

final listRemotesProvider = AsyncNotifierProvider<ListRemotesNotifier, List<String>>(ListRemotesNotifier.new);

class BranchNamesNotifier extends CachedGitNotifier<Map<String, String>> {
  @override
  Future<Map<String, String>> readCache(SettingsManager manager) async {
    final cached = await manager.getStringList(StorageKey.setman_branchNames);
    if (cached.isEmpty) return {};
    final map = <String, String>{};
    for (final entry in cached) {
      final parts = entry.split(conflictSeparator);
      map[parts[0]] = parts.length > 1 ? parts[1] : 'both';
    }
    return map;
  }

  @override
  Future<Map<String, String>> fetchLive() => runGitOperation<Map<String, String>>(LogType.BranchNames, (event) {
    final raw = event?["result"]?.map<String>((path) => "$path").toList() ?? <String>[];
    final map = <String, String>{};
    for (final entry in raw) {
      final parts = entry.split(conflictSeparator);
      map[parts[0]] = parts.length > 1 ? parts[1] : 'both';
    }
    return map;
  });

  @override
  Future<void> writeCache(SettingsManager manager, Map<String, String> value) =>
      manager.setStringList(StorageKey.setman_branchNames, value.entries.map((e) => "${e.key}$conflictSeparator${e.value}").toList());
}

final branchNamesProvider = AsyncNotifierProvider<BranchNamesNotifier, Map<String, String>>(BranchNamesNotifier.new);

class HasGitFiltersNotifier extends CachedGitNotifier<bool> {
  @override
  Future<bool> readCache(SettingsManager manager) => manager.getBool(StorageKey.setman_hasGitFilters);

  @override
  Future<bool> fetchLive() => runGitOperation<bool>(LogType.HasGitFilters, (event) => event?["result"] ?? false);

  @override
  Future<void> writeCache(SettingsManager manager, bool value) => manager.setBool(StorageKey.setman_hasGitFilters, value);
}

final hasGitFiltersProvider = AsyncNotifierProvider<HasGitFiltersNotifier, bool>(HasGitFiltersNotifier.new);

class ConflictingFilesNotifier extends CachedGitNotifier<List<(String, GitManagerRs.ConflictType)>> {
  @override
  Future<List<(String, GitManagerRs.ConflictType)>> readCache(SettingsManager manager) async {
    final cached = await manager.getStringList(StorageKey.setman_conflicting);
    try {
      final result = cached.map((item) {
        final parts = item.split(conflictSeparator);
        return (parts[0], GitManagerRs.ConflictType.values.byName(parts[1]));
      }).toList();
      return result;
    } catch (e, s) {
      Logger.logError(LogType.Global, e, s);
      await manager.setStringList(StorageKey.setman_conflicting, []);
      return [];
    }
  }

  @override
  Future<List<(String, GitManagerRs.ConflictType)>> fetchLive() => runGitOperation<List<(String, GitManagerRs.ConflictType)>>(
    LogType.ConflictingFiles,
    (event) => (event?["result"] as List)
        .map<(String, GitManagerRs.ConflictType)>((item) => (item[0] as String, GitManagerRs.ConflictType.values.byName(item[1] as String)))
        .toList(),
  );

  @override
  Future<void> writeCache(SettingsManager manager, List<(String, GitManagerRs.ConflictType)> value) =>
      manager.setStringList(StorageKey.setman_conflicting, value.map((e) => "${e.$1}$conflictSeparator${e.$2.name}").toList());
}

final conflictingFilesProvider = AsyncNotifierProvider<ConflictingFilesNotifier, List<(String, GitManagerRs.ConflictType)>>(
  ConflictingFilesNotifier.new,
);

final isLoadingCommitsProvider = StateProvider<bool>((ref) => false);

class RecentCommitsNotifier extends CachedGitNotifier<List<GitManagerRs.Commit>> {
  bool _hasMoreCommits = true;

  @override
  Future<List<GitManagerRs.Commit>> readCache(SettingsManager manager) async {
    final cached = await manager.getStringList(StorageKey.setman_recentCommits);
    return cached.map((item) => CommitJson.fromJson(jsonDecode(utf8.fuse(base64).decode(item)))).toList();
  }

  @override
  Future<List<GitManagerRs.Commit>> fetchLive() => runGitOperation<List<GitManagerRs.Commit>>(
    LogType.RecentCommits,
    (event) =>
        event?["result"]?.map<GitManagerRs.Commit>((path) => CommitJson.fromJson(jsonDecode(utf8.fuse(base64).decode("$path")))).toList() ??
        <GitManagerRs.Commit>[],
  );

  @override
  Future<void> writeCache(SettingsManager manager, List<GitManagerRs.Commit> value) =>
      manager.setStringList(StorageKey.setman_recentCommits, value.map((item) => utf8.fuse(base64).encode(jsonEncode(item.toJson()))).toList());

  @override
  Future<List<GitManagerRs.Commit>> build() async {
    _hasMoreCommits = true;

    final repoIndex = await repoManager.getInt(StorageKey.repoman_repoIndex);
    final manager = await SettingsManager.scoped(repoIndex);
    _scopedManager = manager;

    var cancelled = false;
    ref.onDispose(() {
      cancelled = true;
      ref.read(isLoadingCommitsProvider.notifier).state = false;
    });

    final cached = await readCache(manager);

    if (cached.isEmpty) {
      ref.read(isLoadingCommitsProvider.notifier).state = true;
      final live = await fetchLive();
      await writeCache(manager, live);
      ref.read(isLoadingCommitsProvider.notifier).state = false;
      return live;
    }

    () async {
      try {
        ref.read(isLoadingCommitsProvider.notifier).state = true;
        final live = await fetchLive();
        if (!cancelled && await _isCurrentIndex(repoIndex)) {
          state = AsyncData(live);
          await writeCache(manager, live);
        }
      } on OperationNotExecuted {
      } catch (e, s) {
        if (!cancelled && await _isCurrentIndex(repoIndex)) {
          state = AsyncData(cached);
        }
        Logger.logError(LogType.Global, e, s);
      } finally {
        if (!cancelled) ref.read(isLoadingCommitsProvider.notifier).state = false;
      }
    }();

    return cached;
  }

  Future<void> loadMore() async {
    if (!_hasMoreCommits || ref.read(isLoadingCommitsProvider)) return;
    final repoIndex = await repoManager.getInt(StorageKey.repoman_repoIndex);
    final manager = await SettingsManager.scoped(repoIndex);
    final current = state.valueOrNull ?? [];
    ref.read(isLoadingCommitsProvider.notifier).state = true;
    final moreCommits = await GitManager.getMoreRecentCommits(current.length);
    if (moreCommits.isEmpty) {
      _hasMoreCommits = false;
    } else if (await _isCurrentIndex(repoIndex)) {
      final updated = [...current, ...moreCommits];
      state = AsyncData(updated);
      await writeCache(manager, updated);
    }
    ref.read(isLoadingCommitsProvider.notifier).state = false;
  }
}

final recentCommitsProvider = AsyncNotifierProvider<RecentCommitsNotifier, List<GitManagerRs.Commit>>(RecentCommitsNotifier.new);

class RecommendedActionNotifier extends CachedGitNotifier<int?> {
  @override
  Future<int?> readCache(SettingsManager manager) => manager.getIntNullable(StorageKey.setman_recommendedAction);

  @override
  Future<int?> fetchLive() => runGitOperation<int?>(LogType.RecommendedAction, (event) => event?["result"]);

  @override
  Future<void> writeCache(SettingsManager manager, int? value) => manager.setIntNullable(StorageKey.setman_recommendedAction, value);

  Future<int?> refresh() async {
    final repoIndex = await repoManager.getInt(StorageKey.repoman_repoIndex);
    final manager = await SettingsManager.scoped(repoIndex);
    final previous = state.valueOrNull;
    try {
      final live = await fetchLive();
      if (await _isCurrentIndex(repoIndex)) {
        state = AsyncData(live);
        await writeCache(manager, live);
      }
      return live;
    } catch (e, s) {
      if (await _isCurrentIndex(repoIndex)) state = AsyncData(previous);
      rethrow;
    }
  }
}

final recommendedActionProvider = AsyncNotifierProvider<RecommendedActionNotifier, int?>(RecommendedActionNotifier.new);

class SyncMessageEnabledNotifier extends SettingNotifier<bool> {
  @override
  Future<bool> read() => uiSettingsManager.getBool(StorageKey.setman_syncMessageEnabled);

  @override
  Future<void> write(bool value) => uiSettingsManager.setBool(StorageKey.setman_syncMessageEnabled, value);
}

final syncMessageEnabledProvider = AsyncNotifierProvider<SyncMessageEnabledNotifier, bool>(SyncMessageEnabledNotifier.new);

class LastSyncMethodNotifier extends SettingNotifier<String> {
  @override
  Future<String> read() => uiSettingsManager.getString(StorageKey.setman_lastSyncMethod);

  @override
  Future<void> write(String value) => uiSettingsManager.setString(StorageKey.setman_lastSyncMethod, value);
}

final lastSyncMethodProvider = AsyncNotifierProvider<LastSyncMethodNotifier, String>(LastSyncMethodNotifier.new);

class ClientModeEnabledNotifier extends SettingNotifier<bool> {
  @override
  Future<bool> read() => uiSettingsManager.getClientModeEnabled();

  @override
  Future<void> write(bool value) => uiSettingsManager.setBoolNullable(StorageKey.setman_clientModeEnabled, value);
}

final clientModeEnabledProvider = AsyncNotifierProvider<ClientModeEnabledNotifier, bool>(ClientModeEnabledNotifier.new);

class GitProviderNotifier extends SettingNotifier<GitProvider> {
  @override
  Future<GitProvider> read() => uiSettingsManager.getGitProvider();

  @override
  Future<void> write(GitProvider value) => uiSettingsManager.setStringNullable(StorageKey.setman_gitProvider, value.name);
}

final gitProviderProvider = AsyncNotifierProvider<GitProviderNotifier, GitProvider>(GitProviderNotifier.new);

class PostFooterNotifier extends SettingNotifier<String> {
  @override
  Future<String> read() => uiSettingsManager.getPostFooter();

  @override
  Future<void> write(String value) => uiSettingsManager.setStringNullable(StorageKey.setman_postFooter, value);

  void clear() {
    uiSettingsManager.setStringNullable(StorageKey.setman_postFooter, null);
    ref.invalidateSelf();
  }
}

final postFooterProvider = AsyncNotifierProvider<PostFooterNotifier, String>(PostFooterNotifier.new);

class AuthorNameNotifier extends SettingNotifier<String> {
  @override
  Future<String> read() => uiSettingsManager.getAuthorName();

  @override
  Future<void> write(String value) => uiSettingsManager.setStringNullable(StorageKey.setman_authorName, value);

  void clear() {
    uiSettingsManager.setStringNullable(StorageKey.setman_authorName, null);
    ref.invalidateSelf();
  }
}

final authorNameProvider = AsyncNotifierProvider<AuthorNameNotifier, String>(AuthorNameNotifier.new);

class AuthorEmailNotifier extends SettingNotifier<String> {
  @override
  Future<String> read() => uiSettingsManager.getAuthorEmail();

  @override
  Future<void> write(String value) => uiSettingsManager.setStringNullable(StorageKey.setman_authorEmail, value);

  void clear() {
    uiSettingsManager.setStringNullable(StorageKey.setman_authorEmail, null);
    ref.invalidateSelf();
  }
}

final authorEmailProvider = AsyncNotifierProvider<AuthorEmailNotifier, String>(AuthorEmailNotifier.new);

class SyncMessageNotifier extends SettingNotifier<String> {
  @override
  Future<String> read() => uiSettingsManager.getSyncMessage();

  @override
  Future<void> write(String value) => uiSettingsManager.setStringNullable(StorageKey.setman_syncMessage, value);

  void clear() {
    uiSettingsManager.setStringNullable(StorageKey.setman_syncMessage, null);
    ref.invalidateSelf();
  }
}

final syncMessageProvider = AsyncNotifierProvider<SyncMessageNotifier, String>(SyncMessageNotifier.new);

class GithubScopedOauthNotifier extends SettingNotifier<bool> {
  @override
  Future<bool> read() => uiSettingsManager.getBool(StorageKey.setman_githubScopedOauth);

  @override
  Future<void> write(bool value) => uiSettingsManager.setBool(StorageKey.setman_githubScopedOauth, value);
}

final githubScopedOauthProvider = AsyncNotifierProvider<GithubScopedOauthNotifier, bool>(GithubScopedOauthNotifier.new);

class IsAuthenticatedNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final provider = await ref.watch(gitProviderProvider.future);
    return provider == GitProvider.SSH
        ? (await uiSettingsManager.getGitSshAuthCredentials()).$2.isNotEmpty
        : (await uiSettingsManager.getGitHttpAuthCredentials()).$2.isNotEmpty;
  }
}

final isAuthenticatedProvider = AsyncNotifierProvider<IsAuthenticatedNotifier, bool>(IsAuthenticatedNotifier.new);

class RepoNamesNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() => repoManager.getStringList(StorageKey.repoman_repoNames);

  void set(List<String> value) {
    state = AsyncData(value);
    repoManager.setStringList(StorageKey.repoman_repoNames, value);
  }
}

final repoNamesProvider = AsyncNotifierProvider<RepoNamesNotifier, List<String>>(RepoNamesNotifier.new);

class RepoIndexNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() => repoManager.getInt(StorageKey.repoman_repoIndex);

  void set(int value) {
    state = AsyncData(value);
    repoManager.setInt(StorageKey.repoman_repoIndex, value);
  }
}

final repoIndexProvider = AsyncNotifierProvider<RepoIndexNotifier, int>(RepoIndexNotifier.new);

class FeatureCountsNotifier extends AsyncNotifier<Map<ShowcaseFeature, int?>> {
  @override
  Future<Map<ShowcaseFeature, int?>> build() async {
    final provider = await ref.watch(gitProviderProvider.future);
    if (!provider.isOAuthProvider) return {};
    final authenticated = await ref.watch(isAuthenticatedProvider.future);
    if (!authenticated) return {};
    final remoteUrlLink = await ref.watch(remoteUrlLinkProvider.future);
    final webUrl = remoteUrlLink?.$2;
    if (webUrl == null) return {};
    final githubAppOauth = await ref.watch(githubScopedOauthProvider.future);
    final accessToken = (await uiSettingsManager.getGitHttpAuthCredentials()).$2;
    if (accessToken.isEmpty) return {};
    final manager = GitProviderManager.getGitProviderManager(provider, githubAppOauth);
    if (manager == null) return {};
    final segments = Uri.parse(webUrl).pathSegments;
    final owner = segments[0];
    final repo = segments[1].replaceAll(".git", "");
    final pinnedKeys = await uiSettingsManager.getStringList(StorageKey.setman_pinnedShowcaseFeatures);
    final pinned = ShowcaseFeature.fromStorageKeys(pinnedKeys);
    return await manager.getFeatureCounts(accessToken, owner, repo, pinned);
  }
}

final featureCountsProvider = AsyncNotifierProvider<FeatureCountsNotifier, Map<ShowcaseFeature, int?>>(FeatureCountsNotifier.new);

class GitDirPathNotifier extends AsyncNotifier<(String, String)?> {
  @override
  Future<(String, String)?> build() => uiSettingsManager.getGitDirPath();

  void set((String, String)? value) {
    state = AsyncData(value);
    uiSettingsManager.setGitDirPath(value?.$1 ?? "");
  }
}

final gitDirPathProvider = AsyncNotifierProvider<GitDirPathNotifier, (String, String)?>(GitDirPathNotifier.new);

class AiFeaturesEnabledNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => repoManager.getBool(StorageKey.repoman_aiFeaturesEnabled);

  void set(bool value) {
    state = AsyncData(value);
    repoManager.setBool(StorageKey.repoman_aiFeaturesEnabled, value);
  }
}

final aiFeaturesEnabledProvider = AsyncNotifierProvider<AiFeaturesEnabledNotifier, bool>(AiFeaturesEnabledNotifier.new);

final aiKeyConfiguredProvider = StateProvider<bool>((ref) => false);

class PremiumStatusNotifier extends Notifier<bool?> {
  @override
  bool? build() {
    void listener() {
      state = premiumManager.hasPremiumNotifier.value;
    }

    premiumManager.hasPremiumNotifier.addListener(listener);
    ref.onDispose(() => premiumManager.hasPremiumNotifier.removeListener(listener));
    return premiumManager.hasPremiumNotifier.value;
  }

  void set(bool? value) {
    premiumManager.hasPremiumNotifier.value = value;
  }
}

final premiumStatusProvider = NotifierProvider<PremiumStatusNotifier, bool?>(PremiumStatusNotifier.new);

class RemoteNameNotifier extends SettingNotifier<String> {
  @override
  Future<String> read() => uiSettingsManager.getRemote();

  @override
  Future<void> write(String value) => uiSettingsManager.setStringNullable(StorageKey.setman_remote, value);
}

final remoteNameProvider = AsyncNotifierProvider<RemoteNameNotifier, String>(RemoteNameNotifier.new);

class SubmodulePathsNotifier extends CachedGitNotifier<List<String>> {
  @override
  Future<List<String>> readCache(SettingsManager manager) => manager.getStringList(StorageKey.setman_submodulePaths);

  @override
  Future<List<String>> fetchLive() async {
    final dirPath = (await ref.read(gitDirPathProvider.future))?.$1;
    if (dirPath == null) return [];
    return runGitOperation<List<String>>(
      LogType.GetSubmodules,
      (event) => event?["result"].map<String>((path) => "$path").toList() ?? <String>[],
      {"dir": dirPath},
    );
  }

  @override
  Future<void> writeCache(SettingsManager manager, List<String> value) => manager.setStringList(StorageKey.setman_submodulePaths, value);
}

final submodulePathsProvider = AsyncNotifierProvider<SubmodulePathsNotifier, List<String>>(SubmodulePathsNotifier.new);
