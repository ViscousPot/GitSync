import 'package:GitSync/api/manager/storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
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

  const ServiceStrings({
    required this.syncStartPull,
    required this.syncStartPush,
    required this.syncNotRequired,
    required this.syncComplete,
    required this.syncInProgress,
    required this.syncScheduled,
    required this.detectingChanges,
    required this.ongoingMergeConflict,
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
  );
  bool isScheduled = false;
  bool isSyncing = false;

  Future<void> initialise(
    Function(ServiceInstance) onServiceStart,
    Function() callbackDispatcher,
    // Map<String, String> stringMap,
  ) async {
    final service = FlutterBackgroundService();

    Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);

    // final serviceStrings = ServiceStrings.fromMap(stringMap);

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

  Future<void> debouncedSync(int repomanRepoindex, [bool forced = false, bool immediate = false]) async {
    if (!await hasNetworkConnection()) {
      Workmanager().registerOneOffTask(
        "$networkScheduledSyncKey$repomanRepoindex",
        networkScheduledSyncKey,
        inputData: {repoIndex: repomanRepoindex},
        constraints: Constraints(networkType: NetworkType.connected),
      );
      return;
    }
    final settingsManager = SettingsManager();
    await settingsManager.reinit(repoIndex: repomanRepoindex);

    if (isScheduled) {
      _displaySyncMessage(settingsManager, s.syncInProgress);
      return;
    } else {
      if (isSyncing) {
        isScheduled = true;
        Logger.gmLog(type: LogType.Sync, "Sync Scheduled");
        _displaySyncMessage(settingsManager, s.syncScheduled);
        return;
      } else {
        if (immediate) {
          await _sync(repomanRepoindex, forced);
          return;
        }
        debounce(repomanRepoindex.toString(), 500, () => _sync(repomanRepoindex, forced));
      }
    }
  }

  void _displaySyncMessage(SettingsManager settingsManager, String message) async {
    if (await settingsManager.getBool(StorageKey.setman_syncMessageEnabled)) {
      Fluttertoast.showToast(msg: message, toastLength: Toast.LENGTH_LONG, gravity: null);
    }
  }

  Future<void> _sync(int repomanRepoindex, [bool forced = false]) async {
    try {
      isSyncing = true;
      await GitManager.getAndExcludeLfsFilePaths(repomanRepoindex);

      final settingsManager = SettingsManager();
      await settingsManager.reinit(repoIndex: repomanRepoindex);

      final provider = await settingsManager.getGitProvider();

      if (provider == GitProvider.SSH
          ? (await settingsManager.getGitSshAuthCredentials()).$2.isEmpty
          : (await settingsManager.getGitHttpAuthCredentials()).$2.isEmpty) {
        Logger.gmLog(type: LogType.Sync, "Credentials Not Found");
        Fluttertoast.showToast(msg: "Credentials not found", toastLength: Toast.LENGTH_LONG, gravity: null);
        isScheduled = false;
        isSyncing = false;
        return;
      }

      if ((await GitManager.getConflicting(repomanRepoindex)).isNotEmpty) {
        Fluttertoast.showToast(msg: s.ongoingMergeConflict, toastLength: Toast.LENGTH_SHORT, gravity: null);
        isScheduled = false;
        isSyncing = false;
        return;
      }

      if (forced) {
        _displaySyncMessage(settingsManager, s.detectingChanges);
      }
      Logger.gmLog(type: LogType.Sync, "Start Sync");

      await () async {
        final gitDirPath = await settingsManager.getGitDirPath();

        if (gitDirPath == null) {
          Logger.gmLog(type: LogType.Sync, "Repository Not Found");
          Fluttertoast.showToast(msg: repositoryNotFound, toastLength: Toast.LENGTH_LONG, gravity: null);
          return;
        }

        bool synced = false;
        bool? pullResult = null;
        bool? pushResult = null;

        if (!await hasNetworkConnection()) {
          Workmanager().registerOneOffTask(
            "$networkScheduledSyncKey$repomanRepoindex",
            networkScheduledSyncKey,
            inputData: {repoIndex: repomanRepoindex},
            constraints: Constraints(networkType: NetworkType.connected),
          );
          return;
        }

        final optimisedSyncFlag = await settingsManager.getBool(StorageKey.setman_optimisedSyncExperimental);
        final recommendedAction = await GitManager.getRecommendedAction();

        if (optimisedSyncFlag && recommendedAction == null) return;

        if (!optimisedSyncFlag || [0, 1, 2, 3].contains(recommendedAction)) {
          Logger.gmLog(type: LogType.Sync, "Start Pull Repo");
          pullResult = await GitManager.downloadChanges(repomanRepoindex, settingsManager, () {
            synced = true;
            _displaySyncMessage(settingsManager, s.syncStartPull);
          });

          switch (pullResult) {
            case null:
              {
                Logger.gmLog(type: LogType.Sync, "Pull Repo Failed");
                if (!await hasNetworkConnection()) {
                  Workmanager().registerOneOffTask(
                    "$networkScheduledSyncKey$repomanRepoindex",
                    networkScheduledSyncKey,
                    inputData: {repoIndex: repomanRepoindex},
                    constraints: Constraints(networkType: NetworkType.connected),
                  );
                  return;
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

          if (!await hasNetworkConnection()) {
            Workmanager().registerOneOffTask(
              "$networkScheduledSyncKey$repomanRepoindex",
              networkScheduledSyncKey,
              inputData: {repoIndex: repomanRepoindex},
              constraints: Constraints(networkType: NetworkType.connected),
            );
            return;
          }
        }

        if (!optimisedSyncFlag || [2, 3].contains(recommendedAction)) {
          Logger.gmLog(type: LogType.Sync, "Start Push Repo");
          pushResult = await GitManager.uploadChanges(repomanRepoindex, settingsManager, () {
            if (!synced) {
              _displaySyncMessage(settingsManager, s.syncStartPush);
            }
          });

          switch (pushResult) {
            case null:
              {
                Logger.gmLog(type: LogType.Sync, "Push Repo Failed");
                if (!await hasNetworkConnection()) {
                  Workmanager().registerOneOffTask(
                    "$networkScheduledSyncKey$repomanRepoindex",
                    networkScheduledSyncKey,
                    inputData: {repoIndex: repomanRepoindex},
                    constraints: Constraints(networkType: NetworkType.connected),
                  );
                  return;
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

        if (!(pushResult == true || pullResult == true)) {
          if (forced) {
            _displaySyncMessage(settingsManager, s.syncNotRequired);
          }
          return;
        } else {
          _displaySyncMessage(settingsManager, s.syncComplete);
        }

        Logger.dismissError(null);
      }();

      Logger.gmLog(type: LogType.Sync, "Sync Complete!");
      isSyncing = false;

      if (isScheduled) {
        Logger.gmLog(type: LogType.Sync, "Scheduled Sync Starting");
        isScheduled = false;
        debouncedSync(repomanRepoindex);
      }
    } catch (e, st) {
      Logger.logError(LogType.SyncException, e, st);
    }
  }

  void merge(int repomanRepoindex, String commitMessage, List<String> conflictingaths) async {
    final settingsManager = SettingsManager();
    await settingsManager.reinit(repoIndex: repomanRepoindex);

    final pushResult = await GitManager.uploadChanges(
      repomanRepoindex,
      settingsManager,
      () {
        Fluttertoast.showToast(msg: resolvingMerge, toastLength: Toast.LENGTH_SHORT, gravity: null);
      },
      conflictingaths,
      commitMessage,
    );

    switch (pushResult) {
      case null:
        {
          Logger.gmLog(type: LogType.Sync, "Merge Failed");
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
