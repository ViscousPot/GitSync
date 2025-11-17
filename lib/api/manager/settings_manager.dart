import 'dart:io';
import 'package:GitSync/api/helper.dart';
import 'package:GitSync/api/manager/auth/gitea_manager.dart';
import 'package:GitSync/api/manager/auth/github_app_manager.dart';
import 'package:GitSync/api/manager/auth/github_manager.dart';
import 'package:GitSync/api/manager/auth/gitlab_manager.dart';

import '../../../constant/strings.dart';
import 'package:GitSync/api/manager/storage.dart';
import '../../../global.dart';
import '../../../type/git_provider.dart';

class SettingsManager extends Storage {
  static const keyPrefix = "git_sync_settings";
  static String keyNamespace = "git_sync_settings---main";

  SettingsManager({super.name, super.keyTransformer = k});

  Future<SettingsManager> reinit({int? repoIndex}) async {
    final repoName = await repoManager.getRepoName(repoIndex ?? await repoManager.getInt(StorageKey.repoman_repoIndex));
    keyNamespace = "$keyPrefix---$repoName";
    return this;
  }

  static String k(String key) => "$keyNamespace::$key";

  Future<T> _getOrDefault<T>(
    StorageKey<T?> key,
    Future<T?> Function(StorageKey<T?> key, [bool defaulting]) getFn,
    Future<T> Function() defaultFn,
  ) async => await getFn(key, true) ?? await defaultFn();

  Future<bool> getClientModeEnabled() async => await _getOrDefault(
    StorageKey.setman_clientModeEnabled,
    getBoolNullable,
    () => repoManager.getBool(StorageKey.repoman_defaultClientModeEnabled),
  );

  Future<String> getSyncMessage() async =>
      await _getOrDefault(StorageKey.setman_syncMessage, getStringNullable, () => repoManager.getString(StorageKey.repoman_defaultSyncMessage));

  Future<String> getSyncMessageTimeFormat() async => await _getOrDefault(
    StorageKey.setman_syncMessageTimeFormat,
    getStringNullable,
    () => repoManager.getString(StorageKey.repoman_defaultSyncMessageTimeFormat),
  );

  Future<String> getAuthorName() async =>
      await _getOrDefault(StorageKey.setman_authorName, getStringNullable, () => repoManager.getString(StorageKey.repoman_defaultAuthorName));

  Future<String> getAuthorEmail() async =>
      await _getOrDefault(StorageKey.setman_authorEmail, getStringNullable, () => repoManager.getString(StorageKey.repoman_defaultAuthorEmail));

  Future<String> getRemote() async =>
      await _getOrDefault(StorageKey.setman_remote, getStringNullable, () => repoManager.getString(StorageKey.repoman_defaultRemote));

  Future<void> clearAll() async {
    final all = await storage.readAll();
    for (var entry in all.entries) {
      if (entry.key.startsWith(keyNamespace)) {
        await storage.delete(key: entry.key);
      }
    }
  }

  Future<void> renameNamespace(String newRepoName) async {
    final newNamespace = "$keyPrefix---$newRepoName";
    final all = await storage.readAll();

    for (var entry in all.entries) {
      if (entry.key.startsWith(keyNamespace)) {
        final suffix = entry.key.substring(keyNamespace.length + 2);
        final newKey = "$newNamespace::$suffix";
        await storage.write(key: newKey, value: entry.value);
        await storage.delete(key: entry.key);
      }
    }

    keyNamespace = newNamespace;
  }

  Future<void> setGitDirPath(String dir, [bookmark = false]) async {
    await setString(StorageKey.setman_gitDirPath, dir);

    if (!bookmark) {
      await setStringNullable(StorageKey.setman_branchName, null);
      await setStringList(StorageKey.setman_branchNames, []);
      await setStringList(StorageKey.setman_recentCommits, []);
      await setStringList(StorageKey.setman_lfsFilePaths, []);
    }
  }

  Future<String?> getGitDirPath([bool iosGetPath = false]) async {
    final bookmarkPath = await getString(StorageKey.setman_gitDirPath);
    if (bookmarkPath.isEmpty) return null;

    return await useDirectory(bookmarkPath, (bookmarkPath) async => await uiSettingsManager.setGitDirPath(bookmarkPath, true), (path) async {
      if (!await requestStoragePerm(false) || (!await Directory('$path/$gitPath').exists() && !await File('$path/$gitPath').exists())) {
        await setString(StorageKey.setman_gitDirPath, "");
        return null;
      }
      if (!await Directory('$path/$gitPath').exists() && await File('$path/$gitIndexPath').length() < 1) {
        await File('$path/$gitIndexPath').delete();
      }
      return path.isEmpty == true ? null : (Platform.isIOS && iosGetPath ? path : bookmarkPath);
    });
  }

  Future<GitProvider> getGitProvider() async {
    final gitProviderName = await getStringNullable(StorageKey.setman_gitProvider);
    return GitProvider.values.firstWhere((p) => p.name == gitProviderName, orElse: () => GitProvider.GITHUB);
  }

  Future<void> setGitHttpAuthCredentials(String username, String email, String accessToken) async {
    await setStringNullable(StorageKey.setman_authorName, username.trim());
    await setStringNullable(StorageKey.setman_authorEmail, email.trim());
    await setString(StorageKey.setman_gitAuthUsername, username.trim());
    await setString(StorageKey.setman_gitAuthToken, accessToken.trim());
  }

  Future<(String, String)> getGitHttpAuthCredentials() async {
    final username = await getString(StorageKey.setman_gitAuthUsername);
    final token = await getString(StorageKey.setman_gitAuthToken);

    Future<void> setAccessRefreshToken(String accessToken, DateTime? expirationDate, String refreshToken) async {
      await setString(StorageKey.setman_gitAuthToken, buildAccessRefreshToken(accessToken, expirationDate, refreshToken));
    }

    String? oauthToken;

    bool githubAppOauth = await getBool(StorageKey.setman_githubScopedOauth);

    switch (await getGitProvider()) {
      case GitProvider.GITHUB:
        oauthToken = githubAppOauth
            ? await GithubAppManager().getToken(token, setAccessRefreshToken)
            : await GithubManager().getToken(token, setAccessRefreshToken);
      case GitProvider.GITEA:
        oauthToken = await GiteaManager().getToken(token, setAccessRefreshToken);
      case GitProvider.GITLAB:
        oauthToken = await GitlabManager().getToken(token, setAccessRefreshToken);
      default:
        oauthToken = null;
    }

    return (username, oauthToken ?? token);
  }

  Future<void> setGitSshAuthCredentials(String passphrase, String sshKey) async {
    await setString(StorageKey.setman_gitSshKey, sshKey.trim());
    await setString(StorageKey.setman_gitSshPassphrase, passphrase);
  }

  Future<(String, String)> getGitSshAuthCredentials() async =>
      (await getString(StorageKey.setman_gitSshPassphrase), await getString(StorageKey.setman_gitSshKey));

  Future<(String, String)?> getGitCommitSigningCredentials() async {
    final passphrase = await getStringNullable(StorageKey.setman_gitCommitSigningPassphrase);
    final key = await getStringNullable(StorageKey.setman_gitCommitSigningKey);

    if (key != null) {
      if (key.isEmpty) {
        return await getGitSshAuthCredentials();
      }
      return (passphrase ?? "", key);
    }
    return null;
  }

  Future<Set<String>> getApplicationPackages() async {
    final packages = await getStringList(StorageKey.setman_packageNames);
    return packages.toSet();
  }
}
