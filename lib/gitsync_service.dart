import 'dart:io';

import 'package:GitSync/api/manager/storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:GitSync/api/manager/repo_manager.dart';
import 'package:GitSync/type/git_provider.dart';
import 'package:workmanager/workmanager.dart';
import '../api/helper.dart';
import '../api/logger.dart';
import '../api/manager/git_manager.dart';
import '../api/manager/settings_manager.dart';
import '../constant/strings.dart';

ServiceInstance? serviceInstance;

class ServiceStrings {
  final String syncStartPull;
  final String syncStartPush;
  final String syncNotRequired;
  final String syncComplete;
  final String syncInProgress;
  final String syncScheduled;
  final String detectingChanges;
  final String ongoingMergeConflict;
  final String networkStallRetry;

  const ServiceStrings({
    required this.syncStartPull,
    required this.syncStartPush,
    required this.syncNotRequired,
    required this.syncComplete,
    required this.syncInProgress,
    required this.syncScheduled,
    required this.detectingChanges,
    required this.ongoingMergeConflict,
    required this.networkStallRetry,
  });

  factory ServiceStrings.fromMap(Map<String, dynamic> map) {
    return ServiceStrings(
      syncStartPull: map['syncStartPull'] ?? '',
      syncStartPush: map['syncStartPush'] ?? '',
      syncNotRequired: map['syncNotRequired'] ?? '',
      syncComplete: map['syncComplete'] ?? '',
      syncInProgress: map['syncInProgress'] ?? '',
      syncScheduled: map['syncScheduled'] ?? '',
      detectingChanges: map['detectingChanges'] ?? '',
      ongoingMergeConflict: map['ongoingMergeConflict'] ?? '',
      networkStallRetry: map['networkStallRetry'] ?? '',
    );
  }

  Map<String, String> toMap() {
    return {
      'syncStartPull': syncStartPull,
      'syncStartPush': syncStartPush,
      'syncNotRequired': syncNotRequired,
      'syncComplete': syncComplete,
      'syncInProgress': syncInProgress,
      'syncScheduled': syncScheduled,
      'detectingChanges': detectingChanges,
      'ongoingMergeConflict': ongoingMergeConflict,
      'networkStallRetry': networkStallRetry,
    };
  }
}

class GitsyncService {
  static const ACCESSIBILITY_EVENT = "ACCESSIBILITY_EVENT";
  static const FORCE_SYNC = "FORCE_SYNC";
  static const MANUAL_SYNC = "MANUAL_SYNC";
  static const INTENT_SYNC = "INTENT_SYNC";
  static const TILE_SYNC = "TILE_SYNC";
  static const UPDATE_SERVICE_STRINGS = "UPDATE_SERVICE_STRINGS";
  static const MERGE = "MERGE";
  static const MERGE_COMPLETE = "MERGE_COMPLETE";
  static const repoIndex = "repoIndex";

  static RepoManager repoManager = RepoManager();

  ServiceStrings s = ServiceStrings(
    syncStartPull: "Syncing changes…",
    syncStartPush: "Syncing local changes…",
    syncNotRequired: "Sync not required!",
    syncComplete: "Repository synced!",
    syncInProgress: "Sync In Progress",
    syncScheduled: "Sync Scheduled",
    detectingChanges: "Detecting Changes…",
    ongoingMergeConflict: "Ongoing merge conflict",
    networkStallRetry: "Poor network — will retry shortly",
  );
  bool isScheduled = false;
  bool isSyncing = false;

  Future<void> initialise(Function(ServiceInstance) onServiceStart, Function() callbackDispatcher) async {
    final service = FlutterBackgroundService();

    Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);

    await service.configure(
      androidConfiguration: AndroidConfiguration(autoStart: true, isForegroundMode: false, onStart: onServiceStart),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onServiceStart,
        onBackground: (service) {
          onServiceStart(service);
          return true;
        },
      ),
    );
  }

  void initialiseStrings(Map<String, dynamic> stringMap) {
    s = ServiceStrings.fromMap(stringMap);
  }

  Future<void> debouncedSync(int repomanRepoindex, [bool forced = false, bool immediate = false, String? syncMessage]) async {
    final settingsManager = SettingsManager();
    await settingsManager.reinit(repoIndex: repomanRepoindex);

    if (isScheduled) {
      await _displaySyncMessage(settingsManager, s.syncInProgress);
      return;
    } else {
      if (isSyncing) {
        isScheduled = true;
        Logger.gmLog(type: LogType.Sync, "Sync Scheduled");
        await _displaySyncMessage(settingsManager, s.syncScheduled);
        return;
      } else {
        if (immediate) {
          await _sync(repomanRepoindex, forced, syncMessage);
          return;
        }
        debounce(repomanRepoindex.toString(), 500, () => _sync(repomanRepoindex, forced, syncMessage));
      }
    }
  }

  Future<void> _displaySyncMessage(SettingsManager? settingsManager, String message) async {
    if (settingsManager == null || await settingsManager.getBool(StorageKey.setman_syncMessageEnabled)) {
      if (Platform.isIOS) {
        final active = await Logger.notificationsPlugin.getActiveNotifications();
        final alreadyShowing = active.any((n) => n.id == syncStatusNotificationId);

        final darwinDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentList: true,
          presentBadge: false,
          presentSound: !alreadyShowing,
        );
        await Logger.notificationsPlugin.show(syncStatusNotificationId, appName, message, NotificationDetails(iOS: darwinDetails));
      } else {
        await Fluttertoast.showToast(msg: message, toastLength: Toast.LENGTH_LONG, gravity: null);
      }
    }
  }

  void _scheduleStallRetry(int repomanRepoindex) {
    Future.delayed(const Duration(seconds: 30), () {
      debouncedSync(repomanRepoindex);
    });
  }

  Future<void> _sync(int repomanRepoindex, [bool forced = false, String? syncMessage]) async {
    try {
      isSyncing = true;

      final settingsManager = SettingsManager();
      await settingsManager.reinit(repoIndex: repomanRepoindex);

      final provider = await settingsManager.getGitProvider();

      final remotesList = await GitManager.listRemotes(repomanRepoindex, 3);
      if (remotesList.isEmpty) {
        Logger.gmLog(type: LogType.Sync, "No remote configured, skipping sync");
        isScheduled = false;
        return;
      }

      if (provider == GitProvider.SSH
          ? (await settingsManager.getGitSshAuthCredentials()).$2.isEmpty
          : (await settingsManager.getGitHttpAuthCredentials()).$2.isEmpty) {
        Logger.gmLog(type: LogType.Sync, "Credentials Not Found");
        _displaySyncMessage(null, "Credentials not found");
        isScheduled = false;
        return;
      }
      if ((await GitManager.getConflicting(repomanRepoindex, 3)).isNotEmpty) {
        _displaySyncMessage(null, s.ongoingMergeConflict);
        isScheduled = false;
        return;
      }

      if (forced) {
        await _displaySyncMessage(settingsManager, s.detectingChanges);
      }
      Logger.gmLog(type: LogType.Sync, "Start Sync");

      bool? pullResult = false;
      bool? pushResult = false;

      await () async {
        final gitDirPath = settingsManager.gitDirPath?.$1;

        if (gitDirPath == null) {
          Logger.gmLog(type: LogType.Sync, "Repository Not Found");
          _displaySyncMessage(null, repositoryNotFound);
          return;
        }

        bool synced = false;

        final optimisedSyncFlag = await settingsManager.getBool(StorageKey.setman_optimisedSyncExperimental);
        int? recommendedAction = await GitManager.getRecommendedAction(priority: 3);

        if (optimisedSyncFlag && (recommendedAction == null || recommendedAction == -1)) return;

        if (!optimisedSyncFlag || [0, 1, 2, 3].contains(recommendedAction)) {
          Logger.gmLog(type: LogType.Sync, "Start Pull Repo");
          pullResult = await GitManager.backgroundDownloadChanges(repomanRepoindex, settingsManager, () async {
            synced = true;
            await _displaySyncMessage(settingsManager, s.syncStartPull);
          });

          switch (pullResult) {
            case null:
              {
                Logger.gmLog(type: LogType.Sync, "Pull Repo Failed");
                if (GitManager.lastOperationWasNetworkStall) {
                  await _displaySyncMessage(settingsManager, s.networkStallRetry);
                  _scheduleStallRetry(repomanRepoindex);
                }
                return;
              }
            case true:
              {
                Logger.gmLog(type: LogType.Sync, "Pull Complete");
              }
            case false:
              {
                Logger.gmLog(type: LogType.Sync, "Pull Not Required");
              }
          }
        }

        if ((await GitManager.getConflicting(repomanRepoindex, 3)).isNotEmpty) {
          _displaySyncMessage(null, s.ongoingMergeConflict);
          return;
        }

        recommendedAction = await GitManager.getRecommendedAction(priority: 3);
        if (optimisedSyncFlag && (recommendedAction == null || recommendedAction == -1)) return;

        if (!optimisedSyncFlag || [2, 3].contains(recommendedAction)) {
          Logger.gmLog(type: LogType.Sync, "Start Push Repo");
          pushResult = await GitManager.backgroundUploadChanges(
            repomanRepoindex,
            settingsManager,
            () async {
              if (!synced) {
                await _displaySyncMessage(settingsManager, s.syncStartPush);
              }
            },
            null,
            syncMessage,
            () => debouncedSync(repomanRepoindex),
          );

          switch (pushResult) {
            case null:
              {
                Logger.gmLog(type: LogType.Sync, "Push Repo Failed");
                if (GitManager.lastOperationWasNetworkStall) {
                  await _displaySyncMessage(settingsManager, s.networkStallRetry);
                  _scheduleStallRetry(repomanRepoindex);
                }
                return;
              }
            case true:
              {
                Logger.gmLog(type: LogType.Sync, "Push Complete");
              }
            case false:
              {
                Logger.gmLog(type: LogType.Sync, "Push Not Required");
              }
          }
        }
      }();

      if (!(pushResult == true || pullResult == true)) {
        if (forced) {
          await _displaySyncMessage(settingsManager, s.syncNotRequired);
        }
      } else {
        await GitManager.getRecentCommits();
        await _displaySyncMessage(settingsManager, s.syncComplete);
      }

      if (!(pushResult == null || pullResult == null)) {
        Logger.dismissError(null);
        Logger.gmLog(type: LogType.Sync, "Sync Complete!");
      }

      await GitManager.getRecentCommits(priority: 3);
    } catch (e, st) {
      Logger.logError(LogType.SyncException, e, st);
    } finally {
      isSyncing = false;
      if (isScheduled) {
        Logger.gmLog(type: LogType.Sync, "Scheduled Sync Starting");
        isScheduled = false;
        debouncedSync(repomanRepoindex);
      }
    }
  }

  void merge(int repomanRepoindex, String commitMessage, List<String> conflictingPaths) async {
    final settingsManager = SettingsManager();
    await settingsManager.reinit(repoIndex: repomanRepoindex);

    bool? pushResult = false;

    if (await settingsManager.getClientModeEnabled()) {
      pushResult = await GitManager.backgroundStageAndCommit(repomanRepoindex, settingsManager, conflictingPaths, commitMessage);
    } else {
      pushResult = await GitManager.backgroundUploadChanges(
        repomanRepoindex,
        settingsManager,
        () {
          _displaySyncMessage(null, resolvingMerge);
        },
        conflictingPaths,
        commitMessage,
        () => debouncedSync(repomanRepoindex),
      );
    }

    switch (pushResult) {
      case null:
        {
          Logger.gmLog(type: LogType.Sync, "Merge Failed");
          serviceInstance?.invoke(MERGE_COMPLETE);
          return;
        }
      case true:
        Logger.gmLog(type: LogType.Sync, "Merge Complete");
      case false:
        Logger.gmLog(type: LogType.Sync, "Merge Not Required");
    }

    if (!await settingsManager.getClientModeEnabled()) {
      debouncedSync(repomanRepoindex, true);
    }

    serviceInstance?.invoke(MERGE_COMPLETE);
  }

  String lastOpenPackageName = conflictSeparator;
  String lastOpenPackageNameExcludingInputs = conflictSeparator;

  void accessibilityEvent(String packageName, List<String> enabledInputMethods) async {
    enabledInputMethods = [...enabledInputMethods];
    final repoNamesLength = (await repoManager.getStringList(StorageKey.repoman_repoNames)).length;
    for (var index = 0; index < repoNamesLength; index++) {
      final settingsManager = await SettingsManager().reinit(repoIndex: index);

      final syncClosed = await settingsManager.getBool(StorageKey.setman_syncOnAppClosed);
      final syncOpened = await settingsManager.getBool(StorageKey.setman_syncOnAppOpened);

      final packageNames = await settingsManager.getApplicationPackages();

      if ((!syncOpened && !syncClosed) || packageNames.isEmpty) continue;

      if (packageNames.contains(lastOpenPackageNameExcludingInputs) &&
          !packageNames.contains(packageName) &&
          !enabledInputMethods.contains(packageName)) {
        Logger.gmLog(type: LogType.AccessibilityService, "Application Closed $packageName");
        if (syncClosed) {
          debouncedSync(index);
        }
      }

      if (!packageNames.contains(lastOpenPackageNameExcludingInputs) &&
          packageNames.contains(packageName) &&
          !enabledInputMethods.contains(packageName)) {
        Logger.gmLog(type: LogType.AccessibilityService, "Application Opened $packageName");
        if (syncOpened) {
          debouncedSync(index);
        }
      }
    }

    lastOpenPackageName = packageName;
    if (!enabledInputMethods.contains(packageName)) {
      lastOpenPackageNameExcludingInputs = packageName;
    }
  }
}
