import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:GitSync/api/helper.dart';
import 'package:GitSync/type/git_provider.dart';
import 'package:path_provider/path_provider.dart';
import '../logger.dart';
import 'package:GitSync/api/manager/storage.dart';
import '../manager/settings_manager.dart';
import '../../constant/strings.dart';
import '../../global.dart';
import '../../src/rust/api/git_manager.dart' as GitManagerRs;
import 'package:intl/intl.dart';
import 'package:sprintf/sprintf.dart';
import 'package:path/path.dart' as path;
import 'package:collection/collection.dart';

extension CommitJson on GitManagerRs.Commit {
  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toInt(),
    'authorUsername': authorUsername,
    'authorEmail': authorEmail,
    'reference': reference,
    'commitMessage': commitMessage,
    'additions': additions,
    'deletions': deletions,
    'unpulled': unpulled,
    'unpushed': unpushed,
  };

  static GitManagerRs.Commit fromJson(Map<String, dynamic> json) {
    try {
      return GitManagerRs.Commit(
        timestamp: _parseTimestamp(json['timestamp']),
        authorUsername: json['authorUsername'] as String? ?? '',
        authorEmail: json['authorEmail'] as String? ?? '',
        reference: json['reference'] as String? ?? '',
        commitMessage: json['commitMessage'] as String? ?? '',
        additions: _parseIntSafely(json['additions']),
        deletions: _parseIntSafely(json['deletions']),
        unpulled: json['unpulled'] as bool? ?? false,
        unpushed: json['unpushed'] as bool? ?? false,
      );
    } catch (e) {
      print('Error parsing commit JSON: $e');
      rethrow;
    }
  }

  static int _parseTimestamp(dynamic timestamp) {
    if (timestamp is int) return timestamp;
    if (timestamp is String) return int.tryParse(timestamp) ?? 0;
    return 0;
  }

  static int _parseIntSafely(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

Future<T> runGitOperation<T>(LogType type, T Function(Map<String, dynamic>? event) transformer, [Map<String, dynamic>? arg]) async {
  if (!await FlutterBackgroundService().isRunning()) await FlutterBackgroundService().startService();
  FlutterBackgroundService().invoke(type.name, arg);
  final event = await FlutterBackgroundService().on(type.name).first;
  return transformer(event);
}

class GitManager {
  static final Map<String, Future<String?> Function()> _errorContentMap = {
    "failed to parse signature - Signature cannot have an empty name or email": () async => missingAuthorDetailsError,
    "authentication required but no callback set": () async =>
        sprintf(authMethodMismatchError, [await uiSettingsManager.getGitProvider() == GitProvider.SSH ? "HTTP/S" : "SSH"]),
    "invalid data in index - incorrect header signature": () async => invalidIndexHeaderError,
    "cannot push because a reference that you are trying to update on the remote contains commits that are not present locally.": () async => null,
    "error reading file for hashing:": () async => null,
    "failed to parse loose object: invalid header": () async => corruptedLooseObjectError,
  };

  static final List<String> resyncStrings = ["uncommitted changes exist in index", "unstaged changes exist in workdir"];

  static bool lastOperationWasNetworkStall = false;
  static final _networkStallPatterns = ["network stall detected", "transfer speed was below", "timed out"];
  static bool _isNetworkStallError(String message) => _networkStallPatterns.any((p) => message.toLowerCase().contains(p.toLowerCase()));

  static Codec<String, String> stringToBase64 = utf8.fuse(base64);

  static FutureOr<T?> _runWithLock<T>(
    FutureOr<T?> Function({
      required String queueDir,
      required int index,
      required int priority,
      required String fnName,
      required FutureOr<T?> Function() function,
    })?
    typedRunWithLock,
    int index,
    LogType type,
    Future<T?> Function(String dirPath) fn, {
    int priority = 3,
    bool expectGitDir = true,
    String? dirPath = null,
    bool uiLock = false,
  }) async {
    final fnName = type.name;

    Future<T?> action() async {
      Future<T?> internalFn(dirPath) async {
        try {
          final result = await fn(dirPath);
          return result;
        } catch (e, stackTrace) {
          Logger.logError(type, e, stackTrace);
        }
        return null;
      }

      final setman = await SettingsManager().reinit(repoIndex: index);

      T? result;

      if (dirPath == null) {
        dirPath = setman.gitDirPath?.$1;
        if (dirPath == null) return null;
      }
      if (dirPath!.isNotEmpty) {
        result = await useDirectory(dirPath!, (bookmarkPath) async => await setman.setGitDirPath(bookmarkPath, true), (dirPath) async {
          if (expectGitDir && !isGitDir(dirPath)) return null;
          Logger.gmLog(type: type, ".git folder found");
          return await internalFn(dirPath);
        });
      } else {
        result = await internalFn(dirPath);
      }

      return result;
    }

    if (typedRunWithLock == null) {
      try {
        return await action();
      } catch (e, stackTrace) {
        Logger.logError(type, e, stackTrace);
      }
    }

    try {
      return await typedRunWithLock!(
        queueDir: (await getApplicationSupportDirectory()).path,
        index: index,
        priority: priority,
        fnName: fnName,
        function: action,
      );
    } catch (e, stackTrace) {
      Logger.logError(type, e, stackTrace);
    }
    return null;
  }

  static Future<bool> isLocked({waitForUnlock = true, bool ui = false}) async {
    Future<bool> internal() async {
      return GitManagerRs.isLocked(
        queueDir: (await getApplicationSupportDirectory()).path,
        index: await repoManager.getInt(StorageKey.repoman_repoIndex),
      );
      // final locks = await repoManager.getStringList(ui ? StorageKey.repoman_uiLocks : StorageKey.repoman_locks);
      // final locked = locks.contains((await repoManager.getInt(StorageKey.repoman_repoIndex)).toString());
      // return locked;
    }

    if (!waitForUnlock) return await internal();

    return await waitFor(internal, maxWaitSeconds: 660);
  }

  static Future<void> clearLocks() async {
    try {
      final dir = Directory('${(await getApplicationSupportDirectory()).path}/queues');
      if (dir.existsSync()) {
        for (final entity in dir.listSync()) {
          if (entity is File) {
            entity.writeAsStringSync('');
          }
        }
      }
    } catch (e) {}
  }

  static FutureOr<void> _logWrapper(GitManagerRs.LogType type, String message) {
    Logger.gmLog(
      type: LogType.values.firstWhereOrNull((logType) => logType.name.toLowerCase() == type.name.toLowerCase()) ?? LogType.Global,
      message,
    );
  }

  static Future<String?> _getErrorContent(String message) async {
    String error = message.split(";").first;
    if (error.contains(" (")) error = message.split(" (").first;

    return _errorContentMap.containsKey(error) ? await _errorContentMap[error]!() : message;
  }

  static Future<(String, String)> _getCredentials([SettingsManager? setman]) async {
    final provider = await (setman ?? uiSettingsManager).getGitProvider();

    return provider == GitProvider.SSH
        ? await (setman ?? uiSettingsManager).getGitSshAuthCredentials()
        : await (setman ?? uiSettingsManager).getGitHttpAuthCredentials();
  }

  static bool isGitDir(String dirPath) =>
      Directory("$dirPath/$gitPath").existsSync() || File("$dirPath/$gitIndexPath").existsSync() || File("$dirPath/$gitPath").existsSync();

  static Future<int> get _repoIndex async => await repoManager.getInt(StorageKey.repoman_repoIndex);
  static Future<String> _gitProvider([SettingsManager? setman]) async => (await (setman ?? uiSettingsManager).getGitProvider()).name;
  static Future<String> _remote([SettingsManager? setman]) async => await (setman ?? uiSettingsManager).getRemote();
  static Future<(String, String)> _author([SettingsManager? setman]) async =>
      (await (setman ?? uiSettingsManager).getAuthorName(), await (setman ?? uiSettingsManager).getAuthorEmail());

  // UI Accessible Only
  static Future<String?> clone(String repoUrl, String repoPath, Function(String) cloneTaskCallback, Function(int) cloneProgressCallback) async {
    if (await isLocked()) return operationInProgressError;

    final repoIndex = await repoManager.getInt(StorageKey.repoman_repoIndex);

    final result = await _runWithLock(
      GitManagerRs.stringRunWithLock,
      dirPath: repoPath,
      uiLock: true,
      expectGitDir: false,
      await repoIndex,
      LogType.Clone,
      (dirPath) async {
        try {
          await GitManagerRs.cloneRepository(
            url: repoUrl,
            pathString: dirPath,
            provider: await _gitProvider(),
            credentials: await _getCredentials(),
            author: await _author(),
            cloneTaskCallback: cloneTaskCallback,
            cloneProgressCallback: cloneProgressCallback,
            log: _logWrapper,
          );
          return "";
        } on AnyhowException catch (e, stackTrace) {
          Logger.logError(LogType.Clone, e.message, stackTrace, causeError: false);
          return await _getErrorContent(e.message) ?? e.message.split(";").first;
        }
      },
    );

    if (result?.isEmpty == true) return null;
    if (result == null) return inaccessibleDirectoryMessage;

    return result;
  }

  static Future<void> updateSubmodules() async {
    return await _runWithLock(
      GitManagerRs.voidRunWithLock,
      await _repoIndex,
      LogType.UpdateSubmodules,
      (dirPath) async => await GitManagerRs.updateSubmodules(
        pathString: dirPath,
        provider: await _gitProvider(),
        credentials: await _getCredentials(),
        log: _logWrapper,
      ),
    );
  }

  static Future<void> fetchRemote() async {
    return await _runWithLock(
      GitManagerRs.voidRunWithLock,
      uiLock: true,
      await _repoIndex,
      LogType.FetchRemote,
      (dirPath) async => await GitManagerRs.fetchRemote(
        pathString: dirPath,
        remote: await _remote(),
        provider: await _gitProvider(),
        credentials: await _getCredentials(),
        log: _logWrapper,
      ),
    );
  }

  static Future<void> pullChanges() async {
    return await _runWithLock(
      GitManagerRs.voidRunWithLock,
      uiLock: true,
      await _repoIndex,
      LogType.PullFromRepo,
      (dirPath) async => await GitManagerRs.pullChanges(
        pathString: dirPath,
        provider: await _gitProvider(),
        credentials: await _getCredentials(),
        log: _logWrapper,
        syncCallback: () {},
      ),
    );
  }

  static Future<void> stageFilePaths(List<String> paths) async {
    return await _runWithLock(
      GitManagerRs.voidRunWithLock,
      uiLock: true,
      await _repoIndex,
      LogType.Stage,
      (dirPath) async => await GitManagerRs.stageFilePaths(pathString: dirPath, paths: paths, log: _logWrapper),
    );
  }

  static Future<void> unstageFilePaths(List<String> paths) async {
    return await _runWithLock(
      GitManagerRs.voidRunWithLock,
      await _repoIndex,
      LogType.Unstage,
      (dirPath) async => await GitManagerRs.unstageFilePaths(pathString: dirPath, paths: paths, log: _logWrapper),
    );
  }

  static Future<int?> getRecommendedAction([int priority = 1]) async {
    final repoIndex = await _repoIndex;
    return await _runWithLock(priority: priority, GitManagerRs.intRunWithLock, repoIndex, LogType.RecommendedAction, (dirPath) async {
      try {
        final result = await GitManagerRs.getRecommendedAction(
          pathString: dirPath,
          remoteName: await _remote(),
          provider: await _gitProvider(),
          credentials: await _getCredentials(),
          log: _logWrapper,
        );
        final settingsManager = SettingsManager();
        await settingsManager.reinit(repoIndex: repoIndex);
        await settingsManager.setIntNullable(StorageKey.setman_recommendedAction, result);
        return result;
      } catch (e, stackTrace) {
        Logger.logError(LogType.RecommendedAction, e, stackTrace, causeError: false);
        return null;
      }
    });
  }

  static Future<void> commitChanges(String? syncMessage) async {
    return await _runWithLock(
      GitManagerRs.voidRunWithLock,
      uiLock: true,
      await _repoIndex,
      LogType.Commit,
      (dirPath) async => await GitManagerRs.commitChanges(
        pathString: dirPath,
        author: await _author(),
        commitSigningCredentials: await uiSettingsManager.getGitCommitSigningCredentials(),
        syncMessage: sprintf(syncMessage ?? await uiSettingsManager.getSyncMessage(), [
          (DateFormat(await uiSettingsManager.getSyncMessageTimeFormat())).format(DateTime.now()),
        ]),
        log: _logWrapper,
      ),
    );
  }

  static Future<void> pushChanges() async {
    return await _runWithLock(GitManagerRs.voidRunWithLock, uiLock: true, await _repoIndex, LogType.PushToRepo, (dirPath) async {
      try {
        await GitManagerRs.pushChanges(
          pathString: dirPath,
          remoteName: await _remote(),
          provider: await _gitProvider(),
          credentials: await _getCredentials(),
          log: _logWrapper,
          mergeConflictCallback: () {},
        );
      } on AnyhowException catch (e, stackTrace) {
        if (resyncStrings.any((resyncString) => e.message.contains(resyncString))) {
          Logger.logError(LogType.PushToRepo, e.message, stackTrace, errorContent: changesDuringRebase);
        }
        Logger.logError(LogType.PushToRepo, e.message, stackTrace);
      }
    });
  }

  static Future<void> forcePull() async {
    return await _runWithLock(
      GitManagerRs.voidRunWithLock,
      uiLock: true,
      await _repoIndex,
      LogType.ForcePull,
      (dirPath) async => await GitManagerRs.forcePull(pathString: dirPath, log: _logWrapper),
    );
  }

  static Future<void> forcePush() async {
    return await _runWithLock(
      GitManagerRs.voidRunWithLock,
      uiLock: true,
      await _repoIndex,
      LogType.ForcePush,
      (dirPath) async => await GitManagerRs.forcePush(
        pathString: dirPath,
        remoteName: await _remote(),
        provider: await _gitProvider(),
        credentials: await _getCredentials(),
        log: _logWrapper,
      ),
    );
  }

  static Future<void> downloadAndOverwrite() async {
    return await _runWithLock(
      GitManagerRs.voidRunWithLock,
      uiLock: true,
      await _repoIndex,
      LogType.DownloadAndOverwrite,
      (dirPath) async => await GitManagerRs.downloadAndOverwrite(
        pathString: dirPath,
        remoteName: await _remote(),
        provider: await _gitProvider(),
        author: await _author(),
        credentials: await _getCredentials(),
        log: _logWrapper,
      ),
    );
  }

  static Future<void> uploadAndOverwrite() async {
    return await _runWithLock(
      GitManagerRs.voidRunWithLock,
      uiLock: true,
      await _repoIndex,
      LogType.UploadAndOverwrite,
      (dirPath) async => await GitManagerRs.uploadAndOverwrite(
        pathString: dirPath,
        remoteName: await _remote(),
        provider: await _gitProvider(),
        credentials: await _getCredentials(),
        commitSigningCredentials: await uiSettingsManager.getGitCommitSigningCredentials(),
        author: await _author(),
        syncMessage: sprintf(await uiSettingsManager.getSyncMessage(), [
          (DateFormat(await uiSettingsManager.getSyncMessageTimeFormat())).format(DateTime.now()),
        ]),
        log: _logWrapper,
      ),
    );
  }

  static Future<void> discardChanges(List<String> filePaths) async {
    return await _runWithLock(
      GitManagerRs.voidRunWithLock,
      await _repoIndex,
      LogType.DiscardChanges,
      (dirPath) async => await GitManagerRs.discardChanges(pathString: dirPath, filePaths: filePaths, log: _logWrapper),
    );
  }

  static Future<void> untrackAll([List<String>? filePaths = null]) async {
    return await _runWithLock(
      GitManagerRs.voidRunWithLock,
      await _repoIndex,
      LogType.UntrackAll,
      (dirPath) async => await GitManagerRs.untrackAll(pathString: dirPath, filePaths: filePaths, log: _logWrapper),
    );
  }

  static Future<GitManagerRs.Diff?> getCommitDiff(String startRef, String? endRef) async {
    return await _runWithLock(null, await _repoIndex, LogType.CommitDiff, (dirPath) async {
      try {
        return (await GitManagerRs.getCommitDiff(pathString: dirPath, startRef: startRef, endRef: endRef, log: _logWrapper));
      } catch (e, stackTrace) {
        Logger.logError(LogType.CommitDiff, e, stackTrace);
        return null;
      }
    });
  }

  static Future<GitManagerRs.Diff?> getFileDiff(String filePath) async {
    return await _runWithLock(null, await _repoIndex, LogType.FileDiff, (dirPath) async {
      try {
        return (await GitManagerRs.getFileDiff(pathString: dirPath, filePath: filePath, log: _logWrapper));
      } catch (e, stackTrace) {
        Logger.logError(LogType.FileDiff, e, stackTrace);
        return null;
      }
    });
  }

  static Future<int?> getInitialRecommendedAction() async {
    return await uiSettingsManager.getIntNullable(StorageKey.setman_recommendedAction);
  }

  static const recentCommitsIndexFailures = ["invalid data in index - invalid entry", "failed to read index"];
  static Future<List<GitManagerRs.Commit>> getInitialRecentCommits() async {
    return (await uiSettingsManager.getStringList(
      StorageKey.setman_recentCommits,
    )).map((item) => CommitJson.fromJson(jsonDecode(stringToBase64.decode(item)))).toList();
  }

  static Future<List<GitManagerRs.Commit>> getRecentCommits([priority = 1]) async {
    final repoIndex = await _repoIndex;
    final cachedCommits = await getInitialRecentCommits();
    final cachedDiffStats = <String, (int, int)>{
      for (final c in cachedCommits) c.reference: (c.additions, c.deletions),
    };
    final result = await _runWithLock(priority: priority, GitManagerRs.commitListRunWithLock, repoIndex, LogType.RecentCommits, (dirPath) async {
      try {
        return await GitManagerRs.getRecentCommits(pathString: dirPath, remoteName: await _remote(), cachedDiffStats: cachedDiffStats, log: _logWrapper);
      } catch (e, stackTrace) {
        if (recentCommitsIndexFailures.any((msg) => e.toString().contains(msg))) {
          await File('$dirPath/$gitIndexPath').delete();
        } else {
          Logger.logError(LogType.RecentCommits, e, stackTrace);
        }
        return <GitManagerRs.Commit>[];
      }
    });

    final settingsManager = SettingsManager();
    await settingsManager.reinit(repoIndex: repoIndex);
    if (result != null)
      await settingsManager.setStringList(
        StorageKey.setman_recentCommits,
        result.map((item) => stringToBase64.encode(jsonEncode(item.toJson()))).toList(),
      );
    return result ?? <GitManagerRs.Commit>[];
  }

  static Future<List<String>> getConflicting([int? repomanRepoindex, int priority = 1]) async {
    final result =
        await _runWithLock(priority: priority, GitManagerRs.stringListRunWithLock, repomanRepoindex ?? await _repoIndex, LogType.ConflictingFiles, (
          dirPath,
        ) async {
          try {
            return (await GitManagerRs.getConflicting(pathString: dirPath, log: _logWrapper)).toSet().toList();
          } catch (e, stackTrace) {
            if (recentCommitsIndexFailures.any((msg) => e.toString().contains(msg))) {
              await File('$dirPath/$gitIndexPath').delete();
            } else {
              Logger.logError(LogType.ConflictingFiles, e, stackTrace);
            }
            return <String>[];
          }
        }) ??
        <String>[];

    final settingsManager = repomanRepoindex == null ? uiSettingsManager : await SettingsManager().reinit(repoIndex: repomanRepoindex);
    await settingsManager.setStringList(StorageKey.setman_conflicting, result);
    return result;
  }

  static Future<List<(String, int)>> getUncommittedFilePaths([int? repomanRepoindex]) async {
    if (demo) {
      return [
        ("storage/external/example/file_changed.md", 1),
        ("storage/external/example/file_added.md", 3),
        ("storage/external/example/file_removed.md", 2),
      ];
    }

    final result =
        await _runWithLock(priority: 2, GitManagerRs.stringIntListRunWithLock, repomanRepoindex ?? await _repoIndex, LogType.UncommittedFiles, (
          dirPath,
        ) async {
          try {
            return (await GitManagerRs.getUncommittedFilePaths(pathString: dirPath, log: _logWrapper)).toSet().toList();
          } catch (e, stackTrace) {
            if (recentCommitsIndexFailures.any((msg) => e.toString().contains(msg))) {
              await File('$dirPath/$gitIndexPath').delete();
            } else {
              Logger.logError(LogType.UncommittedFiles, e, stackTrace);
            }
            return <(String, int)>[];
          }
        }) ??
        <(String, int)>[];

    final settingsManager = repomanRepoindex == null ? uiSettingsManager : await SettingsManager().reinit(repoIndex: repomanRepoindex);
    await settingsManager.setStringList(
      StorageKey.setman_uncommittedFilePaths,
      result.map((item) => "${item.$1}$conflictSeparator${item.$2}").toList(),
    );
    return result;
  }

  static Future<List<(String, int)>> getStagedFilePaths() async {
    if (demo) {
      return [("storage/external/example/file_staged.md", 1)];
    }

    final result =
        await _runWithLock(priority: 2, GitManagerRs.stringIntListRunWithLock, await _repoIndex, LogType.StagedFiles, (dirPath) async {
          try {
            return (await GitManagerRs.getStagedFilePaths(pathString: dirPath, log: _logWrapper)).toSet().toList();
          } catch (e, stackTrace) {
            if (recentCommitsIndexFailures.any((msg) => e.toString().contains(msg))) {
              await File('$dirPath/$gitIndexPath').delete();
            } else {
              Logger.logError(LogType.StagedFiles, e, stackTrace);
            }
            return <(String, int)>[];
          }
        }) ??
        <(String, int)>[];

    await uiSettingsManager.setStringList(StorageKey.setman_stagedFilePaths, result.map((item) => "${item.$1}$conflictSeparator${item.$2}").toList());
    return result;
  }

  static Future<void> abortMerge() async {
    return await _runWithLock(
      GitManagerRs.voidRunWithLock,
      await _repoIndex,
      LogType.AbortMerge,
      (dirPath) async => await GitManagerRs.abortMerge(pathString: dirPath, log: _logWrapper),
    );
  }

  static Future<String?> getBranchName() async {
    final result = await _runWithLock(priority: 1, GitManagerRs.stringRunWithLock, await _repoIndex, LogType.BranchName, (dirPath) async {
      try {
        return (await GitManagerRs.getBranchName(pathString: dirPath, log: _logWrapper));
      } catch (e, stackTrace) {
        Logger.logError(LogType.BranchName, e, stackTrace);
        return repositoryNotFound;
      }
    });

    await uiSettingsManager.setStringNullable(StorageKey.setman_branchName, result);
    return result;
  }

  static Future<List<String>> getBranchNames() async {
    final result =
        await _runWithLock(priority: 1, GitManagerRs.stringListRunWithLock, await _repoIndex, LogType.BranchNames, (dirPath) async {
          try {
            return (await GitManagerRs.getBranchNames(pathString: dirPath, remote: await uiSettingsManager.getRemote(), log: _logWrapper));
          } catch (e, stackTrace) {
            Logger.logError(LogType.BranchNames, e, stackTrace);
          }
          return null;
        }) ??
        <String>[];

    await uiSettingsManager.setStringList(StorageKey.setman_branchNames, result);
    return result;
  }

  static Future<void> setRemoteUrl(String newRemoteUrl) async {
    return await _runWithLock(GitManagerRs.voidRunWithLock, await _repoIndex, LogType.SetRemoteUrl, (dirPath) async {
      final settingsManager = uiSettingsManager;
      await GitManagerRs.setRemoteUrl(
        pathString: dirPath,
        remoteName: await settingsManager.getRemote(),
        newRemoteUrl: newRemoteUrl,
        log: _logWrapper,
      );
    });
  }

  static Future<void> checkoutBranch(String branchName) async {
    return await _runWithLock(GitManagerRs.voidRunWithLock, await _repoIndex, LogType.CheckoutBranch, (dirPath) async {
      final settingsManager = uiSettingsManager;
      await GitManagerRs.checkoutBranch(pathString: dirPath, remote: await settingsManager.getRemote(), branchName: branchName, log: _logWrapper);
    });
  }

  static Future<void> createBranch(String branchName, String basedOn) async {
    return await _runWithLock(GitManagerRs.voidRunWithLock, await _repoIndex, LogType.CreateBranch, (dirPath) async {
      final settingsManager = uiSettingsManager;
      await GitManagerRs.createBranch(
        pathString: dirPath,
        remoteName: await settingsManager.getRemote(),
        newBranchName: branchName,
        sourceBranchName: basedOn,
        provider: (await settingsManager.getGitProvider()).name,
        credentials: await _getCredentials(settingsManager),
        log: _logWrapper,
      );
    });
  }

  static Future<String> readGitignore() async {
    return await _runWithLock(priority: 2, GitManagerRs.stringRunWithLock, await _repoIndex, LogType.ReadGitIgnore, (dirPath) async {
          final gitignorePath = '$dirPath/$gitIgnorePath';
          final file = File(gitignorePath);
          if (!file.existsSync()) return '';
          return file.readAsStringSync();
        }) ??
        "";
  }

  static Future<void> writeGitignore(String gitignoreString) async {
    return await _runWithLock(GitManagerRs.voidRunWithLock, await _repoIndex, LogType.WriteGitIgnore, (dirPath) async {
      final gitignorePath = '$dirPath/$gitIgnorePath';
      final file = File(gitignorePath);
      if (!file.existsSync()) file.createSync();
      file.writeAsStringSync(gitignoreString, mode: FileMode.write);
    });
  }

  static Future<String> readGitInfoExclude() async {
    return await _runWithLock(priority: 2, GitManagerRs.stringRunWithLock, await _repoIndex, LogType.ReadGitInfoExclude, (dirPath) async {
          final gitInfoExcludeFullPath = '$dirPath/$gitInfoExcludePath';
          final file = File(gitInfoExcludeFullPath);
          if (!file.existsSync()) return '';
          return file.readAsStringSync();
        }) ??
        "";
  }

  static Future<void> writeGitInfoExclude(String gitInfoExcludeString) async {
    return await _runWithLock(GitManagerRs.voidRunWithLock, await _repoIndex, LogType.WriteGitInfoExclude, (dirPath) async {
      final gitInfoExcludeFullPath = '$dirPath/$gitInfoExcludePath';
      final file = File(gitInfoExcludeFullPath);
      final parentDir = file.parent;
      if (!parentDir.existsSync()) {
        parentDir.createSync(recursive: true);
      }
      if (!file.existsSync()) file.createSync();
      file.writeAsStringSync(gitInfoExcludeString, mode: FileMode.write);
    });
  }

  static Future<bool> getDisableSsl() async {
    final result =
        await _runWithLock(
          priority: 2,
          GitManagerRs.boolRunWithLock,
          await _repoIndex,
          LogType.GetDisableSsl,
          (dirPath) async => await GitManagerRs.getDisableSsl(gitDir: dirPath),
        ) ??
        false;

    await uiSettingsManager.setBool(StorageKey.setman_disableSsl, result);
    return result;
  }

  static Future<void> setDisableSsl(bool disable) async {
    return await _runWithLock(
      GitManagerRs.voidRunWithLock,
      await _repoIndex,
      LogType.SetDisableSsl,
      (dirPath) async => await GitManagerRs.setDisableSsl(gitDir: dirPath, disable: disable),
    );
  }

  static Future<(String, String)?> generateKeyPair(String passphrase) async {
    return await _runWithLock(
      GitManagerRs.stringPairRunWithLock,
      await _repoIndex,
      LogType.GenerateKeyPair,
      (_) async => await GitManagerRs.generateSshKey(format: "ed25519", passphrase: passphrase, log: _logWrapper),
      dirPath: "",
    );
  }

  static Future<(String, String)?> getRemoteUrlLink() async {
    final result = await _runWithLock(priority: 1, GitManagerRs.stringPairRunWithLock, await _repoIndex, LogType.GetRemoteUrlLink, (dirPath) async {
      final remoteName = await uiSettingsManager.getRemote();

      try {
        String gitConfigPath = path.join(dirPath, '.git', 'config');

        final gitDirFile = File(path.join(dirPath, '.git'));
        if (await gitDirFile.exists()) {
          final gitDirContent = await gitDirFile.readAsString();
          final match = RegExp(r'gitdir:\s*(.+)').firstMatch(gitDirContent);
          if (match != null) {
            final actualGitDirPath = path.normalize(path.join(dirPath, match.group(1)!.trim()));
            gitConfigPath = path.join(actualGitDirPath, 'config');
          }
        }

        final configFile = File(gitConfigPath);

        if (!await configFile.exists()) {
          throw Exception('Not a Git repository: $dirPath');
        }

        final configContent = await configFile.readAsString();

        print(configContent);

        print(remoteName);

        final remoteUrlPattern = RegExp(r'\[remote\s+"' + remoteName + r'"\]\s+url\s*=\s*([^\n]+)');
        final match = remoteUrlPattern.firstMatch(configContent);

        if (match == null || match.groupCount < 1) {
          return null;
        }

        String remoteUrl = match.group(1)!.trim();

        print(remoteUrl);
        print(_convertToWebUrl(remoteUrl));

        return (remoteUrl, _convertToWebUrl(remoteUrl));
      } catch (e) {
        print('Error getting Git remote URL: $e');
        return null;
      }
    });

    print("////?weee $result");

    await uiSettingsManager.setStringList(StorageKey.setman_remoteUrlLink, result == null ? [] : [result.$1, result.$2]);

    return result;
  }

  static String _convertToWebUrl(String remoteUrl) {
    remoteUrl = remoteUrl.trim();

    final sshPattern = RegExp(r'^(?:ssh://)?(?:[^:@]+)@([^:]+):([^/]+)/(.+?)(?:\.git)?$');
    if (sshPattern.hasMatch(remoteUrl)) {
      final match = sshPattern.firstMatch(remoteUrl)!;
      final host = match.group(1)!;
      final usernameOrPort = match.group(2)!;
      final repo = match.group(3)!;

      if (double.tryParse(usernameOrPort) != null) {
        return 'https://$host:$usernameOrPort/$repo';
      }

      return 'https://$host/$usernameOrPort/$repo';
    }

    final httpsPattern = RegExp(r'^https?://([^/]+)/(.+?)(?:\.git)?$');
    if (httpsPattern.hasMatch(remoteUrl)) {
      final match = httpsPattern.firstMatch(remoteUrl)!;
      final host = match.group(1)!;
      final path = match.group(2)!;

      return 'https://$host/$path';
    }

    final gitPattern = RegExp(r'^git://([^/]+)/(.+?)(?:\.git)?$');
    if (gitPattern.hasMatch(remoteUrl)) {
      final match = gitPattern.firstMatch(remoteUrl)!;
      final host = match.group(1)!;
      final path = match.group(2)!;

      return 'https://$host/$path';
    }

    return remoteUrl;
  }

  static Future<void> deleteDirContents([String? dirPath]) async {
    return await _runWithLock(GitManagerRs.voidRunWithLock, await _repoIndex, dirPath: dirPath, LogType.DiscardDir, (dirPath) async {
      final dir = Directory(dirPath);
      try {
        if (Platform.isIOS) {
          final entities = dir.listSync(recursive: false);
          for (var entity in entities) {
            try {
              final type = FileSystemEntity.typeSync(entity.path, followLinks: false);
              if (type == FileSystemEntityType.link) {
                await entity.delete();
                continue;
              }

              if (entity is File) {
                await entity.delete();
              } else if (entity is Directory) {
                final childEntities = entity.listSync(recursive: false);
                for (var child in childEntities) {
                  try {
                    final childType = FileSystemEntity.typeSync(child.path, followLinks: false);
                    if (childType == FileSystemEntityType.link) {
                      await child.delete();
                    }
                  } catch (e) {
                    print('Error while deleting symlink inside subdir: $e');
                  }
                }
                await entity.delete(recursive: true);
              }
            } catch (e) {
              print('Error while processing entity ${entity.path}: $e');
            }
          }
        } else {
          final entities = dir.listSync(recursive: false);
          for (var entity in entities) {
            try {
              final type = FileSystemEntity.typeSync(entity.path, followLinks: false);
              if (type == FileSystemEntityType.link) {
                await entity.delete();
              }
            } catch (e) {
              print('Error while deleting symlink ${entity.path}: $e');
            }
          }

          await dir.delete(recursive: true);
          await dir.create();
        }
      } catch (e) {
        print('Error while deleting folder contents: $e');
      }
    });
  }

  static Future<void> deleteGitIndex() async {
    return await _runWithLock(GitManagerRs.voidRunWithLock, await _repoIndex, LogType.DiscardGitIndex, (dirPath) async {
      final file = File("$dirPath/$gitIndexPath");
      if (await file.exists()) {
        await file.delete();
      }
    });
  }

  static Future<void> deleteFetchHead([int? repomanRepoindex]) async {
    return await _runWithLock(GitManagerRs.voidRunWithLock, repomanRepoindex ?? await _repoIndex, LogType.DiscardFetchHead, (dirPath) async {
      final file = File("$dirPath/$gitFetchHeadPath");
      if (await file.exists()) {
        await file.delete();
      }
    });
  }

  static Future<void> pruneCorruptedObjects() async {
    return await _runWithLock(GitManagerRs.voidRunWithLock, await _repoIndex, LogType.PruneCorruptedObjects, (dirPath) async {
      await GitManagerRs.pruneCorruptedLooseObjects(pathString: dirPath);
    });
  }

  static Future<bool> hasGitFilters([int? repomanRepoindex]) async {
    return await _runWithLock(priority: 2, GitManagerRs.boolRunWithLock, repomanRepoindex ?? await _repoIndex, LogType.HasGitFilters, (dirPath) async {
          final file = File('$dirPath/$gitAttributesPath');
          if (!file.existsSync()) return false;
          final contents = file.readAsStringSync();
          return RegExp(r'(filter|diff|merge)=').hasMatch(contents);
        }) ??
        false;
  }

  static Future<List<String>> getSubmodulePaths(String repoPath) async {
    final repoIndex = await _repoIndex;
    return await _runWithLock(priority: 2, GitManagerRs.stringListRunWithLock, repoIndex, LogType.GetSubmodules, (dirPath) async {
          final submodulePaths = await GitManagerRs.getSubmodulePaths(pathString: dirPath);
          final settingsManager = SettingsManager();
          await settingsManager.reinit(repoIndex: repoIndex);
          await settingsManager.setStringList(StorageKey.setman_submodulePaths, submodulePaths);
          return submodulePaths;
        }) ??
        [];
  }

  static Future<bool?> downloadChanges(int repomanRepoindex, Function() syncCallback) async {
    final settingsManager = await SettingsManager().reinit(repoIndex: repomanRepoindex);
    return await backgroundDownloadChanges(repomanRepoindex, settingsManager, syncCallback);
  }

  static Future<bool?> uploadChanges(
    int repomanRepoindex,
    Function() syncCallback, [
    List<String>? filePaths,
    String? syncMessage,
    VoidCallback? resyncCallback,
  ]) async {
    final settingsManager = await SettingsManager().reinit(repoIndex: repomanRepoindex);
    return await backgroundUploadChanges(repomanRepoindex, settingsManager, syncCallback, filePaths, syncMessage, resyncCallback);
  }

  // Background Accessible
  static Future<bool?> backgroundDownloadChanges(int repomanRepoindex, SettingsManager settingsManager, Function() syncCallback) async {
    return await _runWithLock(GitManagerRs.boolRunWithLock, uiLock: true, repomanRepoindex, LogType.DownloadChanges, (dirPath) async {
      try {
        return await GitManagerRs.downloadChanges(
          pathString: dirPath,
          remote: await settingsManager.getRemote(),
          provider: (await settingsManager.getGitProvider()).name,
          author: (await settingsManager.getAuthorName(), await settingsManager.getAuthorEmail()),
          credentials: await _getCredentials(settingsManager),
          commitSigningCredentials: await settingsManager.getGitCommitSigningCredentials(),
          syncCallback: syncCallback,
          log: _logWrapper,
        );
      } on AnyhowException catch (e, stackTrace) {
        if (_isNetworkStallError(e.message)) {
          Logger.gmLog(type: LogType.DownloadChanges, "Network stall - will retry");
          lastOperationWasNetworkStall = true;
          return null;
        }
        lastOperationWasNetworkStall = false;
        final errorContent = await _getErrorContent(e.message);
        Logger.logError(LogType.DownloadChanges, e.message, stackTrace, errorContent: errorContent);
      }
      return null;
    });
  }

  static Future<bool?> backgroundUploadChanges(
    int repomanRepoindex,
    SettingsManager settingsManager,
    Function() syncCallback, [
    List<String>? filePaths,
    String? syncMessage,
    VoidCallback? resyncCallback,
  ]) async {
    Future<bool?> internalFn(String dirPath) async => await GitManagerRs.uploadChanges(
      pathString: dirPath,
      remoteName: await settingsManager.getRemote(),
      provider: (await settingsManager.getGitProvider()).name,
      author: (await settingsManager.getAuthorName(), await settingsManager.getAuthorEmail()),
      credentials: await _getCredentials(settingsManager),
      commitSigningCredentials: await settingsManager.getGitCommitSigningCredentials(),
      syncCallback: syncCallback,
      mergeConflictCallback: () {
        repoManager.setInt(StorageKey.repoman_repoIndex, repomanRepoindex);
        sendMergeConflictNotification();
      },
      filePaths: filePaths,
      syncMessage: sprintf(syncMessage ?? await settingsManager.getSyncMessage(), [
        (DateFormat(await settingsManager.getSyncMessageTimeFormat())).format(DateTime.now()),
      ]),
      log: _logWrapper,
    );
    return await _runWithLock(GitManagerRs.boolRunWithLock, uiLock: true, repomanRepoindex, LogType.UploadChanges, (dirPath) async {
      try {
        return await internalFn(dirPath);
      } on AnyhowException catch (e, stackTrace) {
        if (_isNetworkStallError(e.message)) {
          Logger.gmLog(type: LogType.UploadChanges, "Network stall - will retry");
          lastOperationWasNetworkStall = true;
          return null;
        }
        lastOperationWasNetworkStall = false;
        if (resyncStrings.any((resyncString) => e.message.contains(resyncString))) {
          if (resyncCallback != null) {
            resyncCallback();
          } else {
            Logger.logError(LogType.UploadChanges, e.message, stackTrace, errorContent: changesDuringRebase);
          }
          return false;
        }
        final errorContent = await _getErrorContent(e.message);
        Logger.logError(LogType.UploadChanges, e.message, stackTrace, errorContent: errorContent);
      }
      return null;
    });
  }
}
