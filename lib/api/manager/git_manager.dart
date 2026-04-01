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
    'tags': tags,
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
        tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
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
    "PEM preamble contains invalid data": () async => pemPreambleError,
    "cannot push non-fastforwardable reference": () async => cannotPushNonFastforwardableError,
    "error loading known_hosts": () async => errorLoadingKnownHostsError,
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
  }) async {
    final fnName = type.name;

    Future<T?> action() async {
      Future<T?> internalFn(dirPath) async {
        try {
          final result = await fn(dirPath);
          return result;
        } catch (e, stackTrace) {
          final errorMsg = e is AnyhowException ? e.message : e.toString();
          if (await _tryAutoFixCorruption(dirPath, errorMsg)) {
            Logger.gmLog(type: type, "Corruption detected and auto-fixed, retrying");
            try {
              return await fn(dirPath);
            } catch (retryError, retryStackTrace) {
              final retryMsg = retryError is AnyhowException ? retryError.message : retryError.toString();
              final errorContent = await _getErrorContent(retryMsg);
              Logger.logError(type, retryError, retryStackTrace, errorContent: errorContent);
            }
          } else {
            final errorContent = await _getErrorContent(errorMsg);
            Logger.logError(type, e, stackTrace, errorContent: errorContent);
          }
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
          if (expectGitDir && !isGitDir(dirPath)) {
            Logger.gmLog(type: type, "Skipped: not a git directory");
            return null;
          }
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

  static Future<String?> isLocked({waitForUnlock = true}) async {
    Future<String?> internal() async {
      return GitManagerRs.isLocked(
        queueDir: (await getApplicationSupportDirectory()).path,
        index: await repoManager.getInt(StorageKey.repoman_repoIndex),
      );
    }

    if (!waitForUnlock) return await internal();

    return await waitFor(internal, maxWaitSeconds: 660);
  }

  static Future<void> clearLocks() async {
    try {
      await GitManagerRs.clearStaleLocks(queueDir: (await getApplicationSupportDirectory()).path, force: kDebugMode);
    } catch (e, stackTrace) {
      Logger.logError(LogType.Global, e, stackTrace);
    }
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

    if (_errorContentMap.containsKey(error)) return await _errorContentMap[error]!();
    if (error.contains(sslErrorPrefix)) return sslErrorMessage;
    if (error.contains(uncommittedChangeOverwrittenByMerge) || error.contains(uncommittedChangesOverwrittenByMerge)) {
      return uncommittedChangeOverwrittenError;
    }
    if (error.contains(failedToReadIndex)) return failedToReadIndexError;
    return message;
  }

  static Future<(String, String)> _getCredentials([SettingsManager? setman]) async {
    final provider = await (setman ?? uiSettingsManager).getGitProvider();

    return provider == GitProvider.SSH
        ? await (setman ?? uiSettingsManager).getGitSshAuthCredentials()
        : await (setman ?? uiSettingsManager).getGitHttpAuthCredentials();
  }

  static bool isGitDir(String dirPath) =>
      Directory("$dirPath/$gitPath").existsSync() || File("$dirPath/$gitIndexPath").existsSync() || File("$dirPath/$gitPath").existsSync();

  static Future<int> _resolveRepoIndex(int? repoIndex) async =>
      repoIndex ?? await repoManager.getInt(StorageKey.repoman_repoIndex);

  static Future<SettingsManager> _resolveSettingsManager(int? repoIndex) async {
    if (repoIndex == null) return uiSettingsManager;
    return SettingsManager().reinit(repoIndex: repoIndex);
  }

  static Future<String> _gitProvider([SettingsManager? setman]) async => (await (setman ?? uiSettingsManager).getGitProvider()).name;
  static Future<String> _remote([SettingsManager? setman]) async => await (setman ?? uiSettingsManager).getRemote();
  static Future<(String, String)> _author([SettingsManager? setman]) async =>
      (await (setman ?? uiSettingsManager).getAuthorName(), await (setman ?? uiSettingsManager).getAuthorEmail());

  // UI Accessible Only
  static Future<String?> clone(String repoUrl, String repoPath, Function(String) cloneTaskCallback, Function(int) cloneProgressCallback, {int? depth, bool bare = false}) async {
    if (await isLocked() != null) return operationInProgressError;

    final repoIndex = await repoManager.getInt(StorageKey.repoman_repoIndex);

    final result = await _runWithLock(GitManagerRs.stringRunWithLock, dirPath: repoPath, expectGitDir: false, await repoIndex, LogType.Clone, (
      dirPath,
    ) async {
      try {
        await GitManagerRs.cloneRepository(
          url: repoUrl,
          pathString: dirPath,
          provider: await _gitProvider(),
          credentials: await _getCredentials(),
          author: await _author(),
          depth: depth,
          bare: bare,
          cloneTaskCallback: cloneTaskCallback,
          cloneProgressCallback: cloneProgressCallback,
          log: _logWrapper,
        );
        return "";
      } on AnyhowException catch (e, stackTrace) {
        Logger.logError(LogType.Clone, e.message, stackTrace, causeError: false);
        return await _getErrorContent(e.message) ?? e.message.split(";").first;
      }
    });

    if (result?.isEmpty == true) return null;
    if (result == null) return inaccessibleDirectoryMessage;

    return result;
  }

  static Future<void> updateSubmodules({int? repoIndex}) async {
    final setman = await _resolveSettingsManager(repoIndex);
    return await _runWithLock(
      GitManagerRs.voidRunWithLock,
      await _resolveRepoIndex(repoIndex),
      LogType.UpdateSubmodules,
      (dirPath) async => await GitManagerRs.updateSubmodules(
        pathString: dirPath,
        provider: await _gitProvider(setman),
        credentials: await _getCredentials(setman),
        log: _logWrapper,
      ),
    );
  }

  static Future<void> fetchRemote({int? repoIndex}) async {
    final setman = await _resolveSettingsManager(repoIndex);
    return await _runWithLock(
      GitManagerRs.voidRunWithLock,
      await _resolveRepoIndex(repoIndex),
      LogType.FetchRemote,
      (dirPath) async => await GitManagerRs.fetchRemote(
        pathString: dirPath,
        remote: await _remote(setman),
        provider: await _gitProvider(setman),
        credentials: await _getCredentials(setman),
        log: _logWrapper,
      ),
    );
  }

  static Future<void> pullChanges({int? repoIndex}) async {
    final setman = await _resolveSettingsManager(repoIndex);
    return await _runWithLock(
      GitManagerRs.voidRunWithLock,
      await _resolveRepoIndex(repoIndex),
      LogType.PullFromRepo,
      (dirPath) async => await GitManagerRs.pullChanges(
        pathString: dirPath,
        provider: await _gitProvider(setman),
        credentials: await _getCredentials(setman),
        log: _logWrapper,
        syncCallback: () {},
      ),
    );
  }

  static Future<void> stageFilePaths(List<String> paths, {int? repoIndex}) async {
    return await _runWithLock(
      GitManagerRs.voidRunWithLock,
      await _resolveRepoIndex(repoIndex),
      LogType.Stage,
      (dirPath) async => await GitManagerRs.stageFilePaths(pathString: dirPath, paths: paths, log: _logWrapper),
    );
  }

  static Future<void> unstageFilePaths(List<String> paths, {int? repoIndex}) async {
    return await _runWithLock(
      GitManagerRs.voidRunWithLock,
      await _resolveRepoIndex(repoIndex),
      LogType.Unstage,
      (dirPath) async => await GitManagerRs.unstageFilePaths(pathString: dirPath, paths: paths, log: _logWrapper),
    );
  }

  static Future<int?> getRecommendedAction({int priority = 1, int? repoIndex}) async {
    final resolvedIndex = await _resolveRepoIndex(repoIndex);
    final setman = await _resolveSettingsManager(repoIndex);
    final result = await _runWithLock(priority: priority, GitManagerRs.intRunWithLock, resolvedIndex, LogType.RecommendedAction, (dirPath) async {
      try {
        final result = await GitManagerRs.getRecommendedAction(
          pathString: dirPath,
          remoteName: await _remote(setman),
          provider: await _gitProvider(setman),
          credentials: await _getCredentials(setman),
          log: _logWrapper,
        );
        return result;
      } catch (e, stackTrace) {
        Logger.logError(LogType.RecommendedAction, e, stackTrace, causeError: false);
        return null;
      }
    });
    if (result != null) {
      await setman.setIntNullable(StorageKey.setman_recommendedAction, result);
    }
    return result;
  }

  static Future<void> commitChanges(String? syncMessage, {int? repoIndex}) async {
    final setman = await _resolveSettingsManager(repoIndex);
    return await _runWithLock(
      GitManagerRs.voidRunWithLock,
      await _resolveRepoIndex(repoIndex),
      LogType.Commit,
      (dirPath) async => await GitManagerRs.commitChanges(
        pathString: dirPath,
        author: await _author(setman),
        commitSigningCredentials: await setman.getGitCommitSigningCredentials(),
        syncMessage: sprintf(syncMessage ?? await setman.getSyncMessage(), [
          (DateFormat(await setman.getSyncMessageTimeFormat())).format(DateTime.now()),
        ]),
        log: _logWrapper,
      ),
    );
  }

  static Future<void> pushChanges({int? repoIndex}) async {
    final setman = await _resolveSettingsManager(repoIndex);
    return await _runWithLock(GitManagerRs.voidRunWithLock, await _resolveRepoIndex(repoIndex), LogType.PushToRepo, (dirPath) async {
      try {
        await GitManagerRs.pushChanges(
          pathString: dirPath,
          remoteName: await _remote(setman),
          provider: await _gitProvider(setman),
          credentials: await _getCredentials(setman),
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

  static Future<void> forcePull({int? repoIndex}) async {
    return await _runWithLock(
      GitManagerRs.voidRunWithLock,
      await _resolveRepoIndex(repoIndex),
      LogType.ForcePull,
      (dirPath) async => await GitManagerRs.forcePull(pathString: dirPath, log: _logWrapper),
    );
  }

  static Future<void> forcePush({int? repoIndex}) async {
    final setman = await _resolveSettingsManager(repoIndex);
    return await _runWithLock(
      GitManagerRs.voidRunWithLock,
      await _resolveRepoIndex(repoIndex),
      LogType.ForcePush,
      (dirPath) async => await GitManagerRs.forcePush(
        pathString: dirPath,
        remoteName: await _remote(setman),
        provider: await _gitProvider(setman),
        credentials: await _getCredentials(setman),
        log: _logWrapper,
      ),
    );
  }

  static Future<void> downloadAndOverwrite({int? repoIndex}) async {
    final setman = await _resolveSettingsManager(repoIndex);
    return await _runWithLock(
      GitManagerRs.voidRunWithLock,
      await _resolveRepoIndex(repoIndex),
      LogType.DownloadAndOverwrite,
      (dirPath) async => await GitManagerRs.downloadAndOverwrite(
        pathString: dirPath,
        remoteName: await _remote(setman),
        provider: await _gitProvider(setman),
        author: await _author(setman),
        credentials: await _getCredentials(setman),
        log: _logWrapper,
      ),
    );
  }

  static Future<void> uploadAndOverwrite({int? repoIndex}) async {
    final setman = await _resolveSettingsManager(repoIndex);
    return await _runWithLock(
      GitManagerRs.voidRunWithLock,
      await _resolveRepoIndex(repoIndex),
      LogType.UploadAndOverwrite,
      (dirPath) async => await GitManagerRs.uploadAndOverwrite(
        pathString: dirPath,
        remoteName: await _remote(setman),
        provider: await _gitProvider(setman),
        credentials: await _getCredentials(setman),
        commitSigningCredentials: await setman.getGitCommitSigningCredentials(),
        author: await _author(setman),
        syncMessage: sprintf(await setman.getSyncMessage(), [
          (DateFormat(await setman.getSyncMessageTimeFormat())).format(DateTime.now()),
        ]),
        log: _logWrapper,
      ),
    );
  }

  static Future<void> discardChanges(List<String> filePaths, {int? repoIndex}) async {
    return await _runWithLock(
      GitManagerRs.voidRunWithLock,
      await _resolveRepoIndex(repoIndex),
      LogType.DiscardChanges,
      (dirPath) async => await GitManagerRs.discardChanges(pathString: dirPath, filePaths: filePaths, log: _logWrapper),
    );
  }

  static Future<void> untrackAll({List<String>? filePaths, int? repoIndex}) async {
    return await _runWithLock(
      GitManagerRs.voidRunWithLock,
      await _resolveRepoIndex(repoIndex),
      LogType.UntrackAll,
      (dirPath) async => await GitManagerRs.untrackAll(pathString: dirPath, filePaths: filePaths, log: _logWrapper),
    );
  }

  static Future<GitManagerRs.Diff?> getCommitDiff(String startRef, String? endRef, {int? repoIndex}) async {
    return await _runWithLock(null, await _resolveRepoIndex(repoIndex), LogType.CommitDiff, (dirPath) async {
      try {
        return (await GitManagerRs.getCommitDiff(pathString: dirPath, startRef: startRef, endRef: endRef, log: _logWrapper));
      } catch (e, stackTrace) {
        Logger.logError(LogType.CommitDiff, e, stackTrace);
        return null;
      }
    });
  }

  static Future<GitManagerRs.Diff?> getFileDiff(String filePath, {int? repoIndex}) async {
    return await _runWithLock(null, await _resolveRepoIndex(repoIndex), LogType.FileDiff, (dirPath) async {
      try {
        return (await GitManagerRs.getFileDiff(pathString: dirPath, filePath: filePath, log: _logWrapper));
      } catch (e, stackTrace) {
        Logger.logError(LogType.FileDiff, e, stackTrace);
        return null;
      }
    });
  }

  static Future<GitManagerRs.WorkdirFileDiff?> getWorkdirFileDiff(String filePath, {int? repoIndex}) async {
    return await _runWithLock(null, await _resolveRepoIndex(repoIndex), LogType.WorkdirFileDiff, (dirPath) async {
      try {
        return (await GitManagerRs.getWorkdirFileDiff(pathString: dirPath, filePath: filePath, log: _logWrapper));
      } catch (e, stackTrace) {
        Logger.logError(LogType.WorkdirFileDiff, e, stackTrace);
        return null;
      }
    });
  }

  static Future<void> stageFileLines(String filePath, List<int> selectedLineIndices, {int? repoIndex}) async {
    return await _runWithLock(
      GitManagerRs.voidRunWithLock,
      await _resolveRepoIndex(repoIndex),
      LogType.StageFileLines,
      (dirPath) async => await GitManagerRs.stageFileLines(
        pathString: dirPath,
        filePath: filePath,
        selectedLineIndices: selectedLineIndices,
        log: _logWrapper,
      ),
    );
  }

  static Future<int?> getInitialRecommendedAction() async {
    return await uiSettingsManager.getIntNullable(StorageKey.setman_recommendedAction);
  }

  static const _indexCorruptionPatterns = [
    "invalid data in index - invalid entry",
    "invalid data in index - incorrect header signature",
    "invalid data in index - extension is truncated",
    "failed to read index",
  ];

  static Future<bool> _tryAutoFixCorruption(String dirPath, dynamic error) async {
    final errorStr = error.toString();

    if (_indexCorruptionPatterns.any((p) => errorStr.contains(p))) {
      final indexFile = File('$dirPath/$gitIndexPath');
      if (await indexFile.exists()) await indexFile.delete();
      try {
        await GitManagerRs.recreateDeletedIndex(pathString: dirPath);
      } catch (e, stackTrace) {
        Logger.logError(LogType.DiscardGitIndex, e, stackTrace);
      }
      return true;
    }

    if (errorStr.contains(corruptedLooseFetchHead)) {
      final file = File('$dirPath/$gitFetchHeadPath');
      if (await file.exists()) await file.delete();
      return true;
    }

    if (errorStr.contains(corruptedLooseObject)) {
      await GitManagerRs.pruneCorruptedLooseObjects(pathString: dirPath);
      return true;
    }

    return false;
  }

  static Future<List<GitManagerRs.Commit>> getInitialRecentCommits() async {
    return (await uiSettingsManager.getStringList(
      StorageKey.setman_recentCommits,
    )).map((item) => CommitJson.fromJson(jsonDecode(stringToBase64.decode(item)))).toList();
  }

  static Future<List<GitManagerRs.Commit>> getRecentCommits({int priority = 1, int? repoIndex}) async {
    final resolvedIndex = await _resolveRepoIndex(repoIndex);
    final setman = await _resolveSettingsManager(repoIndex);
    final cachedCommits = await getInitialRecentCommits();
    final cachedDiffStats = <String, (int, int)>{for (final c in cachedCommits) c.reference: (c.additions, c.deletions)};
    final result = await _runWithLock(priority: priority, GitManagerRs.commitListRunWithLock, resolvedIndex, LogType.RecentCommits, (dirPath) async {
      try {
        return await GitManagerRs.getRecentCommits(
          pathString: dirPath,
          remoteName: await _remote(setman),
          cachedDiffStats: cachedDiffStats,
          skip: BigInt.zero,
          log: _logWrapper,
        );
      } catch (e, stackTrace) {
        Logger.logError(LogType.RecentCommits, e, stackTrace);
        return <GitManagerRs.Commit>[];
      }
    });

    if (result != null)
      await setman.setStringList(
        StorageKey.setman_recentCommits,
        result.map((item) => stringToBase64.encode(jsonEncode(item.toJson()))).toList(),
      );
    return result ?? <GitManagerRs.Commit>[];
  }

  static Future<List<GitManagerRs.Commit>> getMoreRecentCommits(int skip, {int priority = 1, int? repoIndex}) async {
    final setman = await _resolveSettingsManager(repoIndex);
    final cachedCommits = await getInitialRecentCommits();
    final cachedDiffStats = <String, (int, int)>{for (final c in cachedCommits) c.reference: (c.additions, c.deletions)};
    final result = await _runWithLock(priority: priority, GitManagerRs.commitListRunWithLock, await _resolveRepoIndex(repoIndex), LogType.RecentCommits, (dirPath) async {
      try {
        return await GitManagerRs.getRecentCommits(
          pathString: dirPath,
          remoteName: await _remote(setman),
          cachedDiffStats: cachedDiffStats,
          skip: BigInt.from(skip),
          log: _logWrapper,
        );
      } catch (e, stackTrace) {
        Logger.logError(LogType.RecentCommits, e, stackTrace);
        return <GitManagerRs.Commit>[];
      }
    });
    return result ?? <GitManagerRs.Commit>[];
  }

  static Future<List<(String, GitManagerRs.ConflictType)>> getInitialConflicting() async {
    return (await uiSettingsManager.getStringList(StorageKey.setman_conflicting)).map((item) {
      final decoded = jsonDecode(item) as List;
      return (decoded[0] as String, GitManagerRs.ConflictType.values.byName(decoded[1] as String));
    }).toList();
  }

  static Future<List<(String, GitManagerRs.ConflictType)>> getConflicting([int? repomanRepoindex, int priority = 1]) async {
    final result =
        await _runWithLock(
          priority: priority,
          GitManagerRs.stringConflicttypeListRunWithLock,
          await _resolveRepoIndex(repomanRepoindex),
          LogType.ConflictingFiles,
          (dirPath) async {
            return (await GitManagerRs.getConflicting(pathString: dirPath, log: _logWrapper)).toSet().toList();
          },
        ) ??
        <(String, GitManagerRs.ConflictType)>[];

    final settingsManager = await _resolveSettingsManager(repomanRepoindex);
    await settingsManager.setStringList(StorageKey.setman_conflicting, result.map((e) => jsonEncode([e.$1, e.$2.name])).toList());
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
        await _runWithLock(priority: 2, GitManagerRs.stringIntListRunWithLock, await _resolveRepoIndex(repomanRepoindex), LogType.UncommittedFiles, (
          dirPath,
        ) async {
          return (await GitManagerRs.getUncommittedFilePaths(pathString: dirPath, log: _logWrapper)).toSet().toList();
        }) ??
        <(String, int)>[];

    final settingsManager = await _resolveSettingsManager(repomanRepoindex);
    await settingsManager.setStringList(
      StorageKey.setman_uncommittedFilePaths,
      result.map((item) => "${item.$1}$conflictSeparator${item.$2}").toList(),
    );
    return result;
  }

  static Future<List<(String, int)>> getStagedFilePaths({int? repoIndex}) async {
    if (demo) {
      return [("storage/external/example/file_staged.md", 1)];
    }

    final result =
        await _runWithLock(priority: 2, GitManagerRs.stringIntListRunWithLock, await _resolveRepoIndex(repoIndex), LogType.StagedFiles, (dirPath) async {
          return (await GitManagerRs.getStagedFilePaths(pathString: dirPath, log: _logWrapper)).toSet().toList();
        }) ??
        <(String, int)>[];

    final setman = await _resolveSettingsManager(repoIndex);
    await setman.setStringList(StorageKey.setman_stagedFilePaths, result.map((item) => "${item.$1}$conflictSeparator${item.$2}").toList());
    return result;
  }

  static Future<void> abortMerge({int? repoIndex}) async {
    return await _runWithLock(
      GitManagerRs.voidRunWithLock,
      await _resolveRepoIndex(repoIndex),
      LogType.AbortMerge,
      (dirPath) async => await GitManagerRs.abortMerge(pathString: dirPath, log: _logWrapper),
    );
  }

  static Future<String?> getBranchName({int? repoIndex}) async {
    final result = await _runWithLock(priority: 1, GitManagerRs.stringRunWithLock, await _resolveRepoIndex(repoIndex), LogType.BranchName, (dirPath) async {
      try {
        return (await GitManagerRs.getBranchName(pathString: dirPath, log: _logWrapper));
      } catch (e, stackTrace) {
        Logger.logError(LogType.BranchName, e, stackTrace);
        return repositoryNotFound;
      }
    });

    final setman = await _resolveSettingsManager(repoIndex);
    await setman.setStringNullable(StorageKey.setman_branchName, result);
    return result;
  }

  static Future<List<(String, String)>> getBranchNames({int? repoIndex}) async {
    final setman = await _resolveSettingsManager(repoIndex);
    final result =
        await _runWithLock(priority: 1, GitManagerRs.stringListRunWithLock, await _resolveRepoIndex(repoIndex), LogType.BranchNames, (dirPath) async {
          try {
            return (await GitManagerRs.getBranchNames(pathString: dirPath, remote: await setman.getRemote(), log: _logWrapper));
          } catch (e, stackTrace) {
            Logger.logError(LogType.BranchNames, e, stackTrace);
          }
          return null;
        }) ??
        <String>[];

    final parsed = result.map((entry) {
      final parts = entry.split(conflictSeparator);
      return (parts[0], parts.length > 1 ? parts[1] : 'both');
    }).toList();

    await setman.setStringList(StorageKey.setman_branchNames, parsed.map((e) => e.$1).toList());
    return parsed;
  }

  static Future<void> setRemoteUrl(String newRemoteUrl, {int? repoIndex}) async {
    final setman = await _resolveSettingsManager(repoIndex);
    return await _runWithLock(GitManagerRs.voidRunWithLock, await _resolveRepoIndex(repoIndex), LogType.SetRemoteUrl, (dirPath) async {
      await GitManagerRs.setRemoteUrl(
        pathString: dirPath,
        remoteName: await setman.getRemote(),
        newRemoteUrl: newRemoteUrl,
        log: _logWrapper,
      );
    });
  }

  static Future<List<String>> listRemotes([int? repomanRepoindex, int priority = 1]) async {
    return await _runWithLock(priority: priority, GitManagerRs.stringListRunWithLock, await _resolveRepoIndex(repomanRepoindex), LogType.ListRemotes, (
          dirPath,
        ) async {
          try {
            return (await GitManagerRs.listRemotes(pathString: dirPath, log: _logWrapper));
          } catch (e, stackTrace) {
            Logger.logError(LogType.ListRemotes, e, stackTrace);
          }
          return null;
        }) ??
        <String>[];
  }

  static Future<void> addRemote(String name, String url, {String? dirPathOverride, int? repoIndex}) async {
    if (dirPathOverride != null) {
      await GitManagerRs.addRemote(pathString: dirPathOverride, remoteName: name, remoteUrl: url, log: _logWrapper);
      return;
    }
    return await _runWithLock(GitManagerRs.voidRunWithLock, await _resolveRepoIndex(repoIndex), LogType.AddRemote, (dirPath) async {
      await GitManagerRs.addRemote(pathString: dirPath, remoteName: name, remoteUrl: url, log: _logWrapper);
    });
  }

  static Future<void> initialCommit(String dirPath, (String, String) author, String message) async {
    await GitManagerRs.commitChanges(pathString: dirPath, author: author, syncMessage: message, log: _logWrapper);
  }

  static Future<void> initialPush(String dirPath, String remoteName, String provider, (String, String) credentials) async {
    await GitManagerRs.pushChanges(
      pathString: dirPath,
      remoteName: remoteName,
      provider: provider,
      credentials: credentials,
      mergeConflictCallback: () async {},
      log: _logWrapper,
    );
  }

  static Future<void> deleteRemote(String name, {int? repoIndex}) async {
    return await _runWithLock(GitManagerRs.voidRunWithLock, await _resolveRepoIndex(repoIndex), LogType.DeleteRemote, (dirPath) async {
      await GitManagerRs.deleteRemote(pathString: dirPath, remoteName: name, log: _logWrapper);
    });
  }

  static Future<void> renameRemote(String oldName, String newName, {int? repoIndex}) async {
    return await _runWithLock(GitManagerRs.voidRunWithLock, await _resolveRepoIndex(repoIndex), LogType.RenameRemote, (dirPath) async {
      await GitManagerRs.renameRemote(pathString: dirPath, oldName: oldName, newName: newName, log: _logWrapper);
    });
  }

  static Future<bool> initRepository(String dirPath) async {
    try {
      await GitManagerRs.initRepository(pathString: dirPath, log: _logWrapper);
      return true;
    } catch (e, st) {
      Logger.logError(LogType.InitRepo, e, st);
      return false;
    }
  }

  static Future<void> checkoutBranch(String branchName, {int? repoIndex}) async {
    final setman = await _resolveSettingsManager(repoIndex);
    return await _runWithLock(GitManagerRs.voidRunWithLock, await _resolveRepoIndex(repoIndex), LogType.CheckoutBranch, (dirPath) async {
      await GitManagerRs.checkoutBranch(pathString: dirPath, remote: await setman.getRemote(), branchName: branchName, log: _logWrapper);
    });
  }

  static Future<void> createBranch(String branchName, String basedOn, {int? repoIndex}) async {
    final setman = await _resolveSettingsManager(repoIndex);
    return await _runWithLock(GitManagerRs.voidRunWithLock, await _resolveRepoIndex(repoIndex), LogType.CreateBranch, (dirPath) async {
      await GitManagerRs.createBranch(
        pathString: dirPath,
        remoteName: await setman.getRemote(),
        newBranchName: branchName,
        sourceBranchName: basedOn,
        log: _logWrapper,
      );
    });
  }

  static Future<void> renameBranch(String oldName, String newName, {int? repoIndex}) async {
    return await _runWithLock(GitManagerRs.voidRunWithLock, await _resolveRepoIndex(repoIndex), LogType.RenameBranch, (dirPath) async {
      await GitManagerRs.renameBranch(pathString: dirPath, oldName: oldName, newName: newName, log: _logWrapper);
    });
  }

  static Future<void> deleteBranch(String branchName, {int? repoIndex}) async {
    return await _runWithLock(GitManagerRs.voidRunWithLock, await _resolveRepoIndex(repoIndex), LogType.DeleteBranch, (dirPath) async {
      await GitManagerRs.deleteBranch(pathString: dirPath, branchName: branchName, log: _logWrapper);
    });
  }

  static Future<void> createBranchFromCommit(String branchName, String commitSha, {int? repoIndex}) async {
    return await _runWithLock(GitManagerRs.voidRunWithLock, await _resolveRepoIndex(repoIndex), LogType.CreateBranchFromCommit, (dirPath) async {
      await GitManagerRs.createBranchFromCommit(pathString: dirPath, newBranchName: branchName, commitSha: commitSha, log: _logWrapper);
    });
  }

  static Future<void> checkoutCommit(String commitSha, {int? repoIndex}) async {
    return await _runWithLock(GitManagerRs.voidRunWithLock, await _resolveRepoIndex(repoIndex), LogType.CheckoutCommit, (dirPath) async {
      await GitManagerRs.checkoutCommit(pathString: dirPath, commitSha: commitSha, log: _logWrapper);
    });
  }

  static Future<void> createTag(String tagName, String commitSha, {int? repoIndex}) async {
    return await _runWithLock(GitManagerRs.voidRunWithLock, await _resolveRepoIndex(repoIndex), LogType.CreateTag, (dirPath) async {
      await GitManagerRs.createTag(pathString: dirPath, tagName: tagName, commitSha: commitSha, log: _logWrapper);
    });
  }

  static Future<void> revertCommit(String commitSha, {int? repoIndex}) async {
    return await _runWithLock(GitManagerRs.voidRunWithLock, await _resolveRepoIndex(repoIndex), LogType.RevertCommit, (dirPath) async {
      await GitManagerRs.revertCommit(pathString: dirPath, commitSha: commitSha, log: _logWrapper);
    });
  }

  static Future<void> amendCommit(String newMessage, {int? repoIndex}) async {
    final setman = await _resolveSettingsManager(repoIndex);
    return await _runWithLock(GitManagerRs.voidRunWithLock, await _resolveRepoIndex(repoIndex), LogType.AmendCommit, (dirPath) async {
      await GitManagerRs.amendCommit(
        pathString: dirPath,
        newMessage: newMessage,
        commitSigningCredentials: await setman.getGitCommitSigningCredentials(),
        log: _logWrapper,
      );
    });
  }

  static Future<void> undoCommit({int? repoIndex}) async {
    return await _runWithLock(GitManagerRs.voidRunWithLock, await _resolveRepoIndex(repoIndex), LogType.UndoCommit, (dirPath) async {
      await GitManagerRs.undoCommit(pathString: dirPath, log: _logWrapper);
    });
  }

  static Future<void> resetToCommit(String commitSha, {int? repoIndex}) async {
    return await _runWithLock(GitManagerRs.voidRunWithLock, await _resolveRepoIndex(repoIndex), LogType.ResetToCommit, (dirPath) async {
      await GitManagerRs.resetToCommit(pathString: dirPath, commitSha: commitSha, log: _logWrapper);
    });
  }

  static Future<void> cherryPickCommit(String commitSha, String targetBranch, {int? repoIndex}) async {
    return await _runWithLock(GitManagerRs.voidRunWithLock, await _resolveRepoIndex(repoIndex), LogType.CherryPickCommit, (dirPath) async {
      await GitManagerRs.cherryPickCommit(pathString: dirPath, commitSha: commitSha, targetBranch: targetBranch, log: _logWrapper);
    });
  }

  static Future<void> squashCommits(String oldestCommitSha, String squashMessage, {int? repoIndex}) async {
    final setman = await _resolveSettingsManager(repoIndex);
    return await _runWithLock(GitManagerRs.voidRunWithLock, await _resolveRepoIndex(repoIndex), LogType.SquashCommits, (dirPath) async {
      await GitManagerRs.squashCommits(
        pathString: dirPath,
        oldestCommitSha: oldestCommitSha,
        squashMessage: squashMessage,
        commitSigningCredentials: await setman.getGitCommitSigningCredentials(),
        log: _logWrapper,
      );
    });
  }

  static Future<String> readGitignore({int? repoIndex}) async {
    return await _runWithLock(priority: 2, GitManagerRs.stringRunWithLock, await _resolveRepoIndex(repoIndex), LogType.ReadGitIgnore, (dirPath) async {
          final gitignorePath = '$dirPath/$gitIgnorePath';
          final file = File(gitignorePath);
          if (!file.existsSync()) return '';
          return file.readAsStringSync();
        }) ??
        "";
  }

  static Future<void> writeGitignore(String gitignoreString, {int? repoIndex}) async {
    return await _runWithLock(GitManagerRs.voidRunWithLock, await _resolveRepoIndex(repoIndex), LogType.WriteGitIgnore, (dirPath) async {
      final gitignorePath = '$dirPath/$gitIgnorePath';
      final file = File(gitignorePath);
      if (!file.existsSync()) file.createSync();
      file.writeAsStringSync(gitignoreString, mode: FileMode.write);
    });
  }

  static Future<String> readGitInfoExclude({int? repoIndex}) async {
    return await _runWithLock(priority: 2, GitManagerRs.stringRunWithLock, await _resolveRepoIndex(repoIndex), LogType.ReadGitInfoExclude, (dirPath) async {
          final gitInfoExcludeFullPath = '$dirPath/$gitInfoExcludePath';
          final file = File(gitInfoExcludeFullPath);
          if (!file.existsSync()) return '';
          return file.readAsStringSync();
        }) ??
        "";
  }

  static Future<void> writeGitInfoExclude(String gitInfoExcludeString, {int? repoIndex}) async {
    return await _runWithLock(GitManagerRs.voidRunWithLock, await _resolveRepoIndex(repoIndex), LogType.WriteGitInfoExclude, (dirPath) async {
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

  static Future<bool> getDisableSsl({int? repoIndex}) async {
    final result =
        await _runWithLock(
          priority: 2,
          GitManagerRs.boolRunWithLock,
          await _resolveRepoIndex(repoIndex),
          LogType.GetDisableSsl,
          (dirPath) async => await GitManagerRs.getDisableSsl(gitDir: dirPath),
        ) ??
        false;

    final setman = await _resolveSettingsManager(repoIndex);
    await setman.setBool(StorageKey.setman_disableSsl, result);
    return result;
  }

  static Future<void> setDisableSsl(bool disable, {int? repoIndex}) async {
    return await _runWithLock(
      GitManagerRs.voidRunWithLock,
      await _resolveRepoIndex(repoIndex),
      LogType.SetDisableSsl,
      (dirPath) async => await GitManagerRs.setDisableSsl(gitDir: dirPath, disable: disable),
    );
  }

  static Future<(String, String)?> generateKeyPair(String passphrase, {int? repoIndex}) async {
    return await _runWithLock(
      GitManagerRs.stringPairRunWithLock,
      await _resolveRepoIndex(repoIndex),
      LogType.GenerateKeyPair,
      (_) async => await GitManagerRs.generateSshKey(format: "ed25519", passphrase: passphrase, log: _logWrapper),
      dirPath: "",
    );
  }

  static Future<(String, String)?> getRemoteUrlLink({int? repoIndex}) async {
    final setman = await _resolveSettingsManager(repoIndex);
    final result = await _runWithLock(priority: 1, GitManagerRs.stringPairRunWithLock, await _resolveRepoIndex(repoIndex), LogType.GetRemoteUrlLink, (dirPath) async {
      final remoteName = await setman.getRemote();

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

    await setman.setStringList(StorageKey.setman_remoteUrlLink, result == null ? [] : [result.$1, result.$2]);

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

  static Future<void> deleteDirContents({String? dirPath, int? repoIndex}) async {
    return await _runWithLock(GitManagerRs.voidRunWithLock, await _resolveRepoIndex(repoIndex), dirPath: dirPath, expectGitDir: false, LogType.DiscardDir, (dirPath) async {
      final dir = Directory(dirPath);
      try {
        if (Platform.isIOS) {
          final entities = dir.listSync(recursive: false);
          for (var entity in entities) {
            try {
              final type = FileSystemEntity.typeSync(entity.path, followLinks: false);
              if (type == FileSystemEntityType.link) {
                await entity.delete();
              } else {
                await entity.delete(recursive: true);
              }
            } catch (e) {
              print('Error while processing entity ${entity.path}: $e');
            }
          }
          print('iOS directory cleanup complete for: ${dir.path}');
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

  static Future<void> deleteGitIndex({int? repoIndex}) async {
    return await _runWithLock(GitManagerRs.voidRunWithLock, await _resolveRepoIndex(repoIndex), LogType.DiscardGitIndex, (dirPath) async {
      final file = File("$dirPath/$gitIndexPath");
      if (await file.exists()) {
        await file.delete();
      }
    });
  }

  static Future<void> recreateGitIndex({int? repoIndex}) async {
    return await _runWithLock(GitManagerRs.voidRunWithLock, await _resolveRepoIndex(repoIndex), LogType.RecreateGitIndex, (dirPath) async {
      final file = File("$dirPath/$gitIndexPath");
      if (await file.exists()) await file.delete();
      await GitManagerRs.recreateDeletedIndex(pathString: dirPath);
    });
  }

  static Future<void> deleteFetchHead([int? repomanRepoindex]) async {
    return await _runWithLock(GitManagerRs.voidRunWithLock, await _resolveRepoIndex(repomanRepoindex), LogType.DiscardFetchHead, (dirPath) async {
      final file = File("$dirPath/$gitFetchHeadPath");
      if (await file.exists()) {
        await file.delete();
      }
    });
  }

  static Future<void> pruneCorruptedObjects({int? repoIndex}) async {
    return await _runWithLock(GitManagerRs.voidRunWithLock, await _resolveRepoIndex(repoIndex), LogType.PruneCorruptedObjects, (dirPath) async {
      await GitManagerRs.pruneCorruptedLooseObjects(pathString: dirPath);
    });
  }

  static Future<bool> hasGitFilters([int? repomanRepoindex]) async {
    return await _runWithLock(priority: 2, GitManagerRs.boolRunWithLock, await _resolveRepoIndex(repomanRepoindex), LogType.HasGitFilters, (
          dirPath,
        ) async {
          final file = File('$dirPath/$gitAttributesPath');
          if (!file.existsSync()) return false;
          final contents = file.readAsStringSync();
          return RegExp(r'(filter|diff|merge)=').hasMatch(contents);
        }) ??
        false;
  }

  static Future<List<String>> getSubmodulePaths(String repoPath, {int? repoIndex}) async {
    final resolvedIndex = await _resolveRepoIndex(repoIndex);
    final setman = await _resolveSettingsManager(repoIndex);
    return await _runWithLock(priority: 2, GitManagerRs.stringListRunWithLock, resolvedIndex, LogType.GetSubmodules, (dirPath) async {
          final submodulePaths = await GitManagerRs.getSubmodulePaths(pathString: dirPath);
          await setman.setStringList(StorageKey.setman_submodulePaths, submodulePaths);
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
    return await _runWithLock(GitManagerRs.boolRunWithLock, repomanRepoindex, LogType.DownloadChanges, (dirPath) async {
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
      } on AnyhowException catch (e) {
        if (_isNetworkStallError(e.message)) {
          Logger.gmLog(type: LogType.DownloadChanges, "Network stall - will retry");
          lastOperationWasNetworkStall = true;
          return null;
        }
        lastOperationWasNetworkStall = false;
        rethrow;
      }
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
      mergeConflictCallback: () async {
        await repoManager.setInt(StorageKey.repoman_repoIndex, repomanRepoindex);
        await getConflicting(null, 3);
        sendMergeConflictNotification();
      },
      filePaths: filePaths,
      syncMessage: sprintf(syncMessage ?? await settingsManager.getSyncMessage(), [
        (DateFormat(await settingsManager.getSyncMessageTimeFormat())).format(DateTime.now()),
      ]),
      log: _logWrapper,
    );
    return await _runWithLock(GitManagerRs.boolRunWithLock, repomanRepoindex, LogType.UploadChanges, (dirPath) async {
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
        rethrow;
      }
    });
  }

  static Future<bool?> backgroundStageAndCommit(
    int repomanRepoindex,
    SettingsManager settingsManager, [
    List<String>? filePaths,
    String? syncMessage,
  ]) async {
    return await _runWithLock(GitManagerRs.boolRunWithLock, repomanRepoindex, LogType.Commit, (dirPath) async {
      try {
        await GitManagerRs.stageFilePaths(pathString: dirPath, paths: filePaths ?? ["."], log: _logWrapper);
        await GitManagerRs.commitChanges(
          pathString: dirPath,
          author: await _author(settingsManager),
          commitSigningCredentials: await settingsManager.getGitCommitSigningCredentials(),
          syncMessage: sprintf(syncMessage ?? await settingsManager.getSyncMessage(), [
            (DateFormat(await settingsManager.getSyncMessageTimeFormat())).format(DateTime.now()),
          ]),
          log: _logWrapper,
        );
        return true;
      } on AnyhowException catch (e, stackTrace) {
        Logger.logError(LogType.Commit, e.message, stackTrace);
        return null;
      }
    });
  }
}
