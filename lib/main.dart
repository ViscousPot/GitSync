import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:GitSync/api/manager/auth/github_app_manager.dart';
import 'package:GitSync/ui/component/button_setting.dart';
import 'package:GitSync/ui/component/custom_showcase.dart';
import 'package:GitSync/ui/component/group_sync_settings.dart';
import 'package:GitSync/ui/component/sync_loader.dart';
import 'package:GitSync/ui/dialog/base_alert_dialog.dart';
import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/ui/dialog/create_branch.dart' as CreateBranchDialog;
import 'package:GitSync/ui/dialog/info_dialog.dart' as InfoDialog;
import 'package:GitSync/ui/dialog/merge_conflict.dart' as MergeConflictDialog;
import 'package:GitSync/ui/page/file_explorer.dart';
import 'package:GitSync/ui/page/global_settings_main.dart';
import 'package:GitSync/ui/page/sync_settings_main.dart';
import 'package:anchor_scroll_controller/anchor_scroll_controller.dart';
import 'package:animated_reorderable_list/animated_reorderable_list.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/api/accessibility_service_helper.dart';
import 'package:GitSync/ui/component/item_merge_conflict.dart';
import 'package:GitSync/ui/dialog/onboarding_controller.dart';
import 'package:home_widget/home_widget.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:sprintf/sprintf.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workmanager/workmanager.dart';
import '../api/helper.dart';
import '../api/logger.dart';
import '../api/manager/git_manager.dart';
import '../constant/strings.dart';
import '../gitsync_service.dart';
import '../src/rust/api/git_manager.dart' as GitManagerRs;
import '../src/rust/frb_generated.dart';
import '../type/git_provider.dart';
import '../ui/dialog/auth.dart' as AuthDialog;
import '../ui/dialog/author_details_prompt.dart' as AuthorDetailsPromptDialog;
import '../ui/dialog/legacy_app_user.dart' as LegacyAppUserDialog;
import '../ui/dialog/add_container.dart' as AddContainerDialog;
import '../ui/dialog/remove_container.dart' as RemoveContainerDialog;
import '../ui/dialog/rename_container.dart' as RenameContainerDialog;
import '../ui/dialog/unlock_premium.dart' as UnlockPremiumDialog;
import 'ui/dialog/confirm_force_push_pull.dart' as ConfirmForcePushPullDialog;
import '../ui/dialog/force_push_pull.dart' as ForcePushPullDialog;
import '../ui/dialog/manual_sync.dart' as ManualSyncDialog;
import '../ui/dialog/confirm_branch_checkout.dart' as ConfirmBranchCheckoutDialog;
import '../constant/dimens.dart';
import '../global.dart';
import '../ui/component/item_commit.dart';
import '../ui/page/clone_repo_main.dart';
import '../ui/page/settings_main.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ui/dialog/confirm_reinstall_clear_data.dart' as ConfirmReinstallClearDataDialog;
import 'ui/dialog/set_remote_url.dart' as SetRemoteUrlDialog;
import 'package:GitSync/l10n/app_localizations.dart';

const SET_AS_FOREGROUND = "setAsForeground";
const SET_AS_BACKGROUND = "setAsBackground";

const REPO_INDEX = "repoman_repoIndex";
const PACKAGE_NAME = "packageName";
const ENABLED_INPUT_METHODS = "enabledInputMethods";
const COMMIT_MESSAGE = "commitMessage";
const CONFLICTING_PATHS = "conflictingPaths";

Future<void> main() async {
  FlutterError.onError = (details) {
    if (kDebugMode) {
      print("//////---------------//////");
      for (String line in details.stack.toString().split("\n")) {
        print(line);
      }
      print("//////---------------//////");
      print(details.exception.toString());
      print("//////---------------//////");
    }
    e("${LogType.Global.name}: ${"${details.stack.toString()}\nError: ${details.exception.toString()}"}");
  };

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await RustLib.init();
      initAsync(() async {
        await repoManager.setStringList(StorageKey.repoman_locks, []);
        await gitSyncService.initialise(onServiceStart, callbackDispatcher);
        await Logger.init();
        await requestStoragePerm(false);
      });
      initLogger("${(await getTemporaryDirectory()).path}/logs", maxFileCount: 50, maxFileLength: 1 * 1024 * 1024);
      await uiSettingsManager.reinit();
      // Loads premiumManager initial state
      initAsync(() async => await premiumManager.init());
      runApp(const MyApp());
    },
    (error, stackTrace) {
      e(LogType.Global.name, error, stackTrace);
    },
  );
}

@pragma("vm:entry-point")
Future<void> backgroundCallback(Uri? data) async {
  HomeWidget.setAppGroupId('group.ForceSyncWidget');
  if (!RustLib.instance.initialized) await RustLib.init();

  try {
    print(data.toString());
    switch (data.toString()) {
      case "forcesyncwidget://click?homeWidget":
        {
          final widgetSyncIndex = await repoManager.getInt(StorageKey.repoman_widgetSyncIndex);

          if (Platform.isIOS) {
            await gitSyncService.debouncedSync(widgetSyncIndex, true, true);
          } else {
            FlutterBackgroundService().invoke(GitsyncService.FORCE_SYNC, {REPO_INDEX: "$widgetSyncIndex"});
          }
          break;
        }
    }
  } catch (e) {
    print('Error in widget callback: $e');
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  await RustLib.init();

  Workmanager().executeTask((task, inputData) async {
    try {
      if (task.contains(scheduledSyncKey)) {
        final int repoIndex =
            inputData?["repoIndex"] ?? int.tryParse(task.replaceAll(scheduledSyncKey, "")) ?? await repoManager.getInt(StorageKey.repoman_repoIndex);

        if (Platform.isIOS) {
          await gitSyncService.debouncedSync(repoIndex, true, true);
        } else {
          FlutterBackgroundService().invoke(GitsyncService.FORCE_SYNC, {REPO_INDEX: "$repoIndex"});
        }

        return Future.value(true);
      }

      if (task.contains(networkScheduledSyncKey)) {
        final int repoIndex =
            inputData?["repoIndex"] ?? int.tryParse(task.replaceAll(scheduledSyncKey, "")) ?? await repoManager.getInt(StorageKey.repoman_repoIndex);

        if (Platform.isIOS) {
          await gitSyncService.debouncedSync(repoIndex, true, true);
        } else {
          FlutterBackgroundService().invoke(GitsyncService.FORCE_SYNC, {REPO_INDEX: "$repoIndex"});
        }

        return Future.value(true);
      }
      return Future.value(false);
    } catch (e) {
      return Future.error(e);
    }
  });
}

@pragma('vm:entry-point')
void onServiceStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  serviceInstance = service;
  await RustLib.init();

  service.on(LogType.Clone.name).listen((event) async {
    if (event == null) return;
    final result = await GitManager.clone(
      event["repoUrl"],
      event["repoPath"],
      (task) => service.invoke("cloneTaskCallback", {"task": task}),
      (progress) => service.invoke("cloneProgressCallback", {"progress": progress}),
    );

    service.invoke(LogType.Clone.name, {"result": result});
  });

  service.on(LogType.UpdateSubmodules.name).listen((event) async {
    await GitManager.updateSubmodules();
    service.invoke(LogType.UpdateSubmodules.name);
  });

  service.on(LogType.FetchRemote.name).listen((event) async {
    await GitManager.fetchRemote();
    service.invoke(LogType.FetchRemote.name);
  });

  service.on(LogType.PullFromRepo.name).listen((event) async {
    await GitManager.pullChanges();
    service.invoke(LogType.PullFromRepo.name);
  });

  service.on(LogType.Stage.name).listen((event) async {
    if (event == null) return;
    await GitManager.stageFilePaths(event["paths"].map<String>((path) => "$path").toList());
    service.invoke(LogType.Stage.name);
  });

  service.on(LogType.Unstage.name).listen((event) async {
    if (event == null) return;
    await GitManager.unstageFilePaths(event["paths"].map<String>((path) => "$path").toList());
    service.invoke(LogType.Unstage.name);
  });

  service.on(LogType.RecommendedAction.name).listen((event) async {
    final result = await GitManager.getRecommendedAction();
    service.invoke(LogType.RecommendedAction.name, {"result": result});
  });

  service.on(LogType.Commit.name).listen((event) async {
    if (event == null) return;
    await GitManager.commitChanges(event["syncMessage"]);
    service.invoke(LogType.Commit.name);
  });

  service.on(LogType.PushToRepo.name).listen((event) async {
    await GitManager.pushChanges();
    service.invoke(LogType.PushToRepo.name);
  });

  service.on(LogType.ForcePull.name).listen((event) async {
    await GitManager.forcePull();
    service.invoke(LogType.ForcePull.name);
  });

  service.on(LogType.ForcePush.name).listen((event) async {
    await GitManager.forcePush();
    service.invoke(LogType.ForcePush.name);
  });

  service.on(LogType.DownloadAndOverwrite.name).listen((event) async {
    await GitManager.downloadAndOverwrite();
    service.invoke(LogType.DownloadAndOverwrite.name);
  });

  service.on(LogType.UploadAndOverwrite.name).listen((event) async {
    await GitManager.uploadAndOverwrite();
    service.invoke(LogType.UploadAndOverwrite.name);
  });

  service.on(LogType.DiscardChanges.name).listen((event) async {
    if (event == null) return;
    await GitManager.discardChanges(event["paths"].map<String>((path) => "$path").toList());
    service.invoke(LogType.DiscardChanges.name);
  });

  service.on(LogType.UntrackAll.name).listen((event) async {
    await GitManager.untrackAll(event == null || !event.keys.contains("filePaths") ? null : event["filePaths"]);
    service.invoke(LogType.UntrackAll.name);
  });

  service.on(LogType.CommitDiff.name).listen((event) async {
    if (event == null) return;
    final result = await GitManager.getCommitDiff(event["startRef"], event["endRef"]);
    service.invoke(
      LogType.CommitDiff.name,
      result == null ? null : {"insertions": result.insertions, "deletions": result.deletions, "diffParts": result.diffParts},
    );
  });

  service.on(LogType.FileDiff.name).listen((event) async {
    if (event == null) return;
    final result = await GitManager.getFileDiff(event["filePath"]);
    service.invoke(
      LogType.FileDiff.name,
      result == null ? null : {"insertions": result.insertions, "deletions": result.deletions, "diffParts": result.diffParts},
    );
  });

  service.on(LogType.RecentCommits.name).listen((event) async {
    final result = await GitManager.getRecentCommits();
    print(result);
    service.invoke(LogType.RecentCommits.name, {"result": result.map((item) => utf8.fuse(base64).encode(jsonEncode(item.toJson()))).toList()});
  });

  service.on(LogType.ConflictingFiles.name).listen((event) async {
    final result = await GitManager.getConflicting();
    service.invoke(LogType.ConflictingFiles.name, {"result": result.map<String>((path) => "$path").toList()});
  });

  service.on(LogType.UncommittedFiles.name).listen((event) async {
    final result = await GitManager.getUncommittedFilePaths(event?["repomanRepoindex"]);
    service.invoke(LogType.UncommittedFiles.name, {
      "result": result.map<List<String>>((path) => [path.$1, "${path.$2}"]).toList(),
    });
  });

  service.on(LogType.StagedFiles.name).listen((event) async {
    final result = await GitManager.getStagedFilePaths();
    service.invoke(LogType.StagedFiles.name, {
      "result": result.map((item) => [item.$1, "${item.$2}"]).toList(),
    });
  });

  service.on(LogType.AbortMerge.name).listen((event) async {
    await GitManager.abortMerge();
    service.invoke(LogType.AbortMerge.name);
  });

  service.on(LogType.BranchName.name).listen((event) async {
    final result = await GitManager.getBranchName();
    service.invoke(LogType.BranchName.name, {"result": result});
  });

  service.on(LogType.BranchNames.name).listen((event) async {
    final result = await GitManager.getBranchNames();
    service.invoke(LogType.BranchNames.name, {"result": result.map<String>((branch) => "$branch").toList()});
  });

  service.on(LogType.SetRemoteUrl.name).listen((event) async {
    if (event == null) return;
    await GitManager.setRemoteUrl(event["newRemoteUrl"]);
    service.invoke(LogType.SetRemoteUrl.name);
  });

  service.on(LogType.CheckoutBranch.name).listen((event) async {
    if (event == null) return;
    await GitManager.checkoutBranch(event["branchName"]);
    service.invoke(LogType.CheckoutBranch.name);
  });

  service.on(LogType.CreateBranch.name).listen((event) async {
    if (event == null) return;
    await GitManager.createBranch(event["branchName"], event["basedOn"]);
    service.invoke(LogType.CreateBranch.name);
  });

  service.on(LogType.ReadGitIgnore.name).listen((event) async {
    if (event == null) return;
    final result = await GitManager.readGitignore();
    service.invoke(LogType.ReadGitIgnore.name, {"result": result});
  });

  service.on(LogType.WriteGitIgnore.name).listen((event) async {
    if (event == null) return;
    await GitManager.writeGitignore(event["gitignoreString"]);
    service.invoke(LogType.WriteGitIgnore.name);
  });

  service.on(LogType.ReadGitInfoExclude.name).listen((event) async {
    if (event == null) return;
    final result = await GitManager.readGitInfoExclude();
    service.invoke(LogType.ReadGitInfoExclude.name, {"result": result});
  });

  service.on(LogType.WriteGitInfoExclude.name).listen((event) async {
    if (event == null) return;
    await GitManager.writeGitInfoExclude(event["gitInfoExcludeString"]);
    service.invoke(LogType.WriteGitInfoExclude.name);
  });

  service.on(LogType.GetDisableSsl.name).listen((event) async {
    if (event == null) return;
    final result = await GitManager.getDisableSsl();
    service.invoke(LogType.GetDisableSsl.name, {"result": result});
  });

  service.on(LogType.SetDisableSsl.name).listen((event) async {
    if (event == null) return;
    await GitManager.setDisableSsl(event["disable"]);
    service.invoke(LogType.SetDisableSsl.name);
  });

  service.on(LogType.GenerateKeyPair.name).listen((event) async {
    if (event == null) return;
    final result = await GitManager.generateKeyPair(event["passphrase"]);
    service.invoke(LogType.GenerateKeyPair.name, {
      "result": result == null ? null : [result.$1, result.$2],
    });
  });

  service.on(LogType.GetRemoteUrlLink.name).listen((event) async {
    final result = await GitManager.getRemoteUrlLink();
    service.invoke(LogType.GetRemoteUrlLink.name, {
      "result": result == null ? null : [result.$1, result.$2],
    });
  });

  service.on(LogType.DiscardDir.name).listen((event) async {
    if (event == null) return;

    await GitManager.deleteDirContents(event["dirPath"]);
    service.invoke(LogType.DiscardDir.name);
  });

  service.on(LogType.DiscardGitIndex.name).listen((event) async {
    await GitManager.deleteGitIndex();
    service.invoke(LogType.DiscardGitIndex.name);
  });

  service.on(LogType.DiscardFetchHead.name).listen((event) async {
    await GitManager.deleteFetchHead();
    service.invoke(LogType.DiscardFetchHead.name);
  });

  service.on(LogType.GetSubmodules.name).listen((event) async {
    if (event == null || event["dir"] == null) return;
    final result = await GitManager.getSubmodulePaths(event["dir"]);
    service.invoke(LogType.GetSubmodules.name, {"result": result.map<String>((branch) => "$branch").toList()});
  });

  service.on(LogType.GetAndExcludeLfs.name).listen((event) async {
    final result = await GitManager.getAndExcludeLfsFilePaths(event?["repomanRepoindex"]);
    service.invoke(LogType.GetAndExcludeLfs.name, {"result": result.map<String>((path) => "$path").toList()});
  });

  service.on(LogType.DownloadChanges.name).listen((event) async {
    if (event == null) return;
    final result = await GitManager.downloadChanges(event["repomanRepoindex"], () => service.invoke("downloadChanges-syncCallback"));
    service.invoke(LogType.DownloadChanges.name, {"result": result});
  });

  service.on(LogType.UploadChanges.name).listen((event) async {
    if (event == null) return;
    final result = await GitManager.uploadChanges(
      event["repomanRepoindex"],
      () => service.invoke("uploadChanges-syncCallback"),
      event["filePaths"]?.map<String>((path) => "$path").toList(),
      event["syncMessage"],
      () => service.invoke("uploadChanges-resyncCallback"),
    );
    service.invoke(LogType.UploadChanges.name, {"result": result});
  });

  // --------------------------------------------------------- //

  service.on(GitsyncService.ACCESSIBILITY_EVENT).listen((event) {
    print(GitsyncService.ACCESSIBILITY_EVENT);
    if (event == null) return;
    gitSyncService.accessibilityEvent(event[PACKAGE_NAME], event[ENABLED_INPUT_METHODS].toString().split(","));
  });

  service.on(GitsyncService.FORCE_SYNC).listen((event) async {
    print(GitsyncService.FORCE_SYNC);
    gitSyncService.debouncedSync(int.tryParse(event?[REPO_INDEX] ?? "null") ?? await repoManager.getInt(StorageKey.repoman_repoIndex), true);
  });

  service.on(GitsyncService.INTENT_SYNC).listen((event) async {
    print(GitsyncService.INTENT_SYNC);
    gitSyncService.debouncedSync(int.tryParse(event?[REPO_INDEX] ?? "null") ?? await repoManager.getInt(StorageKey.repoman_repoIndex));
  });

  service.on(GitsyncService.TILE_SYNC).listen((event) async {
    print(GitsyncService.TILE_SYNC);
    gitSyncService.debouncedSync(await repoManager.getInt(StorageKey.repoman_tileSyncIndex), true);
  });

  service.on(GitsyncService.MERGE).listen((event) async {
    print(GitsyncService.MERGE);
    gitSyncService.merge(
      int.tryParse(event?[REPO_INDEX] ?? "null") ?? await repoManager.getInt(StorageKey.repoman_repoIndex),
      event?[COMMIT_MESSAGE],
      (event?[CONFLICTING_PATHS]).toString().split(conflictSeparator),
    );
  });

  service.on(GitsyncService.UPDATE_SERVICE_STRINGS).listen((event) {
    if (event == null) return;
    gitSyncService.initialiseStrings(event);
  });

  service.on("stop").listen((event) async {
    await repoManager.setStringList(StorageKey.repoman_locks, []);
    service.stopSelf();
  });

  if (service is AndroidServiceInstance) {
    service.on(SET_AS_FOREGROUND).listen((event) {
      service.setAsForegroundService();
    });

    service.on(SET_AS_BACKGROUND).listen((event) {
      service.setAsBackgroundService();
    });
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<String?> appLocale = repoManager.getStringNullable(StorageKey.repoman_appLocale);

  @override
  void initState() {
    HomeWidget.setAppGroupId('group.ForceSyncWidget');
    HomeWidget.registerInteractivityCallback(backgroundCallback);
    initAsync(() async {
      colours.reloadTheme(context);
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: appLocale,
      builder: (context, appLocaleSnapshot) => MaterialApp(
        restorationScopeId: "root",
        title: appName,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: [LocaleNamesLocalizationsDelegate(), ...AppLocalizations.localizationsDelegates],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: appLocaleSnapshot.data == null ? null : Locale(appLocaleSnapshot.data!),
        initialRoute: "/",
        localeResolutionCallback: (locale, supportedLocales) {
          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale?.languageCode) {
              return supportedLocale;
            }
          }
          return const Locale('en');
        },
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: colours.primaryDark),
          useMaterial3: true,
          textSelectionTheme: TextSelectionThemeData(
            selectionHandleColor: colours.tertiaryInfo,
            selectionColor: colours.secondaryInfo.withAlpha(100),
            cursorColor: colours.secondaryInfo.withAlpha(150),
          ),
        ),
        builder: (context, child) => Container(
          color: colours.primaryDark,
          child: SafeArea(
            top: false,
            child: Padding(padding: EdgeInsets.zero, child: child ?? SizedBox.shrink()),
          ),
        ),
        home: ShowCaseWidget(
          blurValue: 3,
          builder: (context) {
            t = AppLocalizations.of(context);
            FlutterBackgroundService().invoke(
              GitsyncService.UPDATE_SERVICE_STRINGS,
              ServiceStrings(
                syncStartPull: t.syncStartPull,
                syncStartPush: t.syncStartPush,
                syncNotRequired: t.syncNotRequired,
                syncComplete: t.syncComplete,
                syncInProgress: t.syncInProgress,
                syncScheduled: t.syncScheduled,
                detectingChanges: t.detectingChanges,
                ongoingMergeConflict: t.ongoingMergeConflict,
              ).toMap(),
            );
            return MyHomePage(
              title: appName,
              reloadLocale: () async {
                appLocale = repoManager.getStringNullable(StorageKey.repoman_appLocale);
                if (mounted) setState(() {});
              },
            );
          },
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.reloadLocale});

  final String title;
  final VoidCallback reloadLocale;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver, RestorationMixin {
  bool repoSettingsExpanded = false;
  bool gitLfsExpanded = false;
  bool demoConflicting = false;

  Timer? autoRefreshTimer;
  StreamSubscription<List<ConnectivityResult>>? networkSubscription;
  late AnchorScrollController recentCommitsController = AnchorScrollController(
    onIndexChanged: (index, userScroll) {
      mergeConflictVisible.value = index == 0;
    },
  );

  late final _restorableGlobalSettings = RestorableRouteFuture<String?>(
    onPresent: (navigator, arguments) {
      return navigator.restorablePush(createGlobalSettingsMainRoute, arguments: arguments);
    },
    onComplete: (result) {
      reloadAll();
    },
  );

  late final _restorableSettingsMain = RestorableRouteFuture<String?>(
    onPresent: (navigator, arguments) {
      return navigator.restorablePush(createSettingsMainRoute, arguments: arguments);
    },
    onComplete: (result) {
      reloadAll();
    },
  );

  @override
  String get restorationId => 'homepage';
  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_restorableGlobalSettings, global_settings_main);
    registerForRestoration(_restorableSettingsMain, settings_main);
    registerForRestoration(loadingRecentCommits, 'loadingRecentCommits');
    registerForRestoration(mergeConflictVisible, 'mergeConflictVisible');
    registerForRestoration(branchName, 'branchName');
  }

  late final syncMethodsDropdownKey = GlobalKey();
  late final syncMethodMainButtonKey = GlobalKey();
  late final _globalSettingsKey = GlobalKey();
  late final _syncProgressKey = GlobalKey();
  late final _addMoreKey = GlobalKey();
  late final _controlKey = GlobalKey();
  late final _configKey = GlobalKey();
  late final _autoSyncOptionsKey = GlobalKey();

  RestorableBool loadingRecentCommits = RestorableBool(false);
  ValueNotifier<List<GitManagerRs.Commit>> recentCommits = ValueNotifier([]);
  ValueNotifier<List<String>> conflicting = ValueNotifier([]);
  RestorableStringN branchName = RestorableStringN(null);
  ValueNotifier<List<String>> branchNames = ValueNotifier([]);
  ValueNotifier<Map<String, (IconData, Future<void> Function())>> syncOptions = ValueNotifier({});
  ValueNotifier<(String, String)?> remoteUrlLink = ValueNotifier(null);
  RestorableBool mergeConflictVisible = RestorableBool(true);

  ValueNotifier<bool> fsLoader = ValueNotifier(false);

  int _reloadToken = 0;

  Future<void> reloadAll() async {
    final token = ++_reloadToken;
    await colours.reloadTheme(context);
    if (token != _reloadToken) return;
    if (mounted) setState(() {});
    await updateSyncOptions();
    final newConflicting = await runGitOperation<List<String>>(
      LogType.ConflictingFiles,
      (event) => conflicting.value = event?["result"].map<String>((path) => "$path").toList(),
    );
    if (token != _reloadToken) return;
    conflicting.value = newConflicting;
    final newBranchName = await runGitOperation<String?>(LogType.BranchName, (event) => event?["result"]);
    if (token != _reloadToken) return;
    branchName.value = newBranchName;
    final newRemoteUrlLink = await runGitOperation<(String, String)?>(
      LogType.GetRemoteUrlLink,
      (event) => event == null || event["result"] == null ? null : (event["result"][0], event["result"][1]),
    );
    if (token != _reloadToken) return;
    remoteUrlLink.value = newRemoteUrlLink;
    final newBranchNames = await runGitOperation<List<String>>(
      LogType.BranchNames,
      (event) => event?["result"].map<String>((path) => "$path").toList(),
    );
    if (token != _reloadToken) return;
    branchNames.value = newBranchNames;
    await updateRecommendedAction();
    if (token != _reloadToken) return;
    loadingRecentCommits.value = true;
    final newRecentCommits = await runGitOperation<List<GitManagerRs.Commit>>(
      LogType.RecentCommits,
      (event) => event?["result"].map<GitManagerRs.Commit>((path) => CommitJson.fromJson(jsonDecode(utf8.fuse(base64).decode("$path")))).toList(),
    );
    if (token != _reloadToken) return;
    recentCommits.value = newRecentCommits;
    loadingRecentCommits.value = false;
    if (mounted) setState(() {});
  }

  static final List<((String, Widget), Future<void> Function(BuildContext context, (String, String)? remote))> remoteActions = [
    (
      (t.launchInBrowser, FaIcon(FontAwesomeIcons.squareArrowUpRight, color: colours.primaryPositive, size: textMD)),
      (BuildContext context, (String, String)? remote) async => remote == null ? null : await launchUrl(Uri.parse(remote.$2)),
    ),
    (
      (t.modifyRemoteUrl, FaIcon(FontAwesomeIcons.squarePen, color: colours.tertiaryInfo, size: textMD)),
      (BuildContext context, (String, String)? remote) async {
        await SetRemoteUrlDialog.showDialog(
          context,
          remote?.$1,
          (newRemoteUrl) async => await runGitOperation(LogType.SetRemoteUrl, (event) => event, {"newRemoteUrl": newRemoteUrl}),
        );
      },
    ),
  ];

  Future<void> syncOptionCompletionCallback([event]) async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await reloadAll();
    });
  }

  @override
  void initState() {
    AccessibilityServiceHelper.init(context, (fn) => mounted ? setState(fn) : null);
    WidgetsBinding.instance.addObserver(this);

    // TODO: Make sure this is commented for release
    // if (demo) {
    //   repoManager.storage.deleteAll();
    //   uiSettingsManager.storage.deleteAll();
    // }

    // TODO: Make sure this is commented for release
    // repoManager.set(StorageKey.repoman_hasStorePremium, false);
    // repoManager.set(StorageKey.repoman_hasGHSponsorPremium, false);
    // repoManager.set(StorageKey.repoman_hasEnhancedScheduledSync, false);
    // uiSettingsManager.set(StorageKey.setman_schedule, "never|");

    // TODO: Make sure this is commented for release
    // Logger.logError(LogType.TEST, "test", StackTrace.fromString("test stack"));
    // Future.delayed(Duration(seconds: 5), () => Logger.logError(LogType.TEST, "test", StackTrace.fromString("test stack")));

    // FlutterBackgroundService().on(LogType.FetchRemote.name).listen(syncOptionCompletionCallback);
    // FlutterBackgroundService().on(LogType.PullFromRepo.name).listen(syncOptionCompletionCallback);
    // FlutterBackgroundService().on(LogType.Stage.name).listen(syncOptionCompletionCallback);
    // FlutterBackgroundService().on(LogType.Commit.name).listen(syncOptionCompletionCallback);

    // FlutterBackgroundService()
    //     .on(LogType.ConflictingFiles.name)
    //     .listen((event) => conflicting.value = event?["result"].map<String>((path) => "$path").toList());

    // TODO: put behind an on for all the sync option fns?

    initAsync(() async {
      reloadAll();
    });

    initAsync(() async {
      String uri = (await HomeWidget.initiallyLaunchedFromHomeWidget()).toString();
      print("////init $uri");
      if (uri == "manualsyncwidget://click?homeWidget") {
        await launchWidgetManualSync();
      }
    });

    HomeWidget.widgetClicked.listen((uri) async {
      if (uri.toString() == "manualsyncwidget://click?homeWidget") {
        await launchWidgetManualSync();
      }
    });

    final QuickActions quickActions = const QuickActions();
    quickActions.initialize((shortcutType) async {
      if (shortcutType == GitsyncService.FORCE_SYNC) {
        final shortcutSyncIndex = await repoManager.getInt(StorageKey.repoman_shortcutSyncIndex);
        await repoManager.setInt(StorageKey.repoman_repoIndex, shortcutSyncIndex);
        await uiSettingsManager.reinit();
        FlutterBackgroundService().invoke(GitsyncService.FORCE_SYNC, {REPO_INDEX: shortcutSyncIndex.toString()});
        return;
      }
      if (shortcutType == GitsyncService.MANUAL_SYNC) {
        final shortcutSyncIndex = await repoManager.getInt(StorageKey.repoman_shortcutManualSyncIndex);
        await repoManager.setInt(StorageKey.repoman_repoIndex, shortcutSyncIndex);
        await uiSettingsManager.reinit();
        await reloadAll();
        await ManualSyncDialog.showDialog(context);
        return;
      }
    });

    quickActions.setShortcutItems(<ShortcutItem>[
      ShortcutItem(type: GitsyncService.FORCE_SYNC, localizedTitle: t.syncNow, icon: "sync_now"),
      ShortcutItem(type: GitsyncService.MANUAL_SYNC, localizedTitle: t.manualSync, icon: "manual_sync"),
    ]);

    initAsync(() async {
      if (premiumManager.hasPremiumNotifier.value == false) {
        await premiumManager.cullNonPremium();
        await reloadAll();
      }
    });

    premiumManager.hasPremiumNotifier.addListener(() async {
      if (premiumManager.hasPremiumNotifier.value == false) {
        await premiumManager.cullNonPremium();
        await reloadAll();
      }
    });

    FlutterBackgroundService().on(GitsyncService.MERGE_COMPLETE).listen((event) async {
      Navigator.of(context).canPop() ? Navigator.pop(context) : null;
      await reloadAll();
    });

    networkSubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) => mounted ? setState(() {}) : null);

    initAsync(() async {
      // TODO: Commented for release
      // await repoManager.setInt(StorageKey.repoman_onboardingStep, 0);

      await promptClearKeychainValues();

      if (await repoManager.hasLegacySettings()) {
        if (!mounted) return;
        await LegacyAppUserDialog.showDialog(context, () async {
          await onboardingController?.show();
          await reloadAll();
        });
        return;
      }
      final step = await repoManager.getInt(StorageKey.repoman_onboardingStep);
      if (step != -1) {
        await onboardingController?.show();
        await reloadAll();
      }
    });

    super.initState();
  }

  Future<void> syncWrapper(Future<void> Function() callback, bool isForceSync) async {
    fsLoader.value = true;
    if (!isForceSync) {
      await runGitOperation(LogType.GetAndExcludeLfs, (event) => event?["result"].map<String>((path) => "$path").toList(), null);
    }
    fsLoader.value = false;

    await callback();
  }

  Future<void> launchWidgetManualSync() async {
    final widgetManualSyncIndex = await repoManager.getInt(StorageKey.repoman_widgetManualSyncIndex);
    await repoManager.setInt(StorageKey.repoman_repoIndex, widgetManualSyncIndex);
    await uiSettingsManager.reinit();
    await reloadAll();
    await ManualSyncDialog.showDialog(context);
  }

  Future<void> updateRecommendedAction([int? override]) async {
    if (!await uiSettingsManager.getClientModeEnabled()) return;
    autoRefreshTimer?.cancel();
    autoRefreshTimer = Timer(Duration(seconds: 10), () async => await updateRecommendedAction());
    updatingRecommendedAction.value = true;
    if (override != null) {
      recommendedAction.value = override;
      updatingRecommendedAction.value = false;
      return;
    }

    recommendedAction.value = await runGitOperation<int?>(LogType.RecommendedAction, (event) {
      return event?["result"];
    });
    updatingRecommendedAction.value = false;
  }

  Future<void> promptClearKeychainValues() async {
    final prefs = await SharedPreferences.getInstance();

    if (Platform.isIOS && (prefs.getBool('is_first_app_launch') ?? true)) {
      await ConfirmReinstallClearDataDialog.showDialog(context, () async {
        await uiSettingsManager.storage.deleteAll();
        await repoManager.storage.deleteAll();
      });

      await repoManager.setStringList(StorageKey.repoman_locks, []);
      await prefs.setBool('is_first_app_launch', false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    onboardingController = OnboardingController(context, showAuthDialog, showCloneRepoPage, completeUiGuideShowcase, [
      _globalSettingsKey,
      _syncProgressKey,
      _addMoreKey,
      _controlKey,
      _configKey,
      _autoSyncOptionsKey,
    ]);
  }

  Future<void> completeUiGuideShowcase(bool initialClientModeEnabled) async {
    _restorableGlobalSettings.present({"recentCommits": recentCommits.value, "onboarding": true});
    await repoManager.setOnboardingStep(-1);
    await uiSettingsManager.setBoolNullable(StorageKey.setman_clientModeEnabled, initialClientModeEnabled);
    if (mounted) setState(() {});
  }

  Future<void> addRepo() async {
    repoSettingsExpanded = false;
    if (mounted) setState(() {});

    AddContainerDialog.showDialog(context, (text) async {
      List<String> repomanReponames = List.from(await repoManager.getStringList(StorageKey.repoman_repoNames));

      if (repomanReponames.contains(text)) {
        text = "${text}_alt";
      }

      repomanReponames = [...repomanReponames, text];

      await repoManager.setStringList(StorageKey.repoman_repoNames, repomanReponames);
      await repoManager.setInt(StorageKey.repoman_repoIndex, repomanReponames.indexOf(text));
      await uiSettingsManager.reinit();

      await reloadAll();
    });
  }

  Future<bool> isAuthenticated() async {
    final provider = await uiSettingsManager.getGitProvider();
    return provider == GitProvider.SSH
        ? (await uiSettingsManager.getGitSshAuthCredentials()).$2.isNotEmpty
        : (await uiSettingsManager.getGitHttpAuthCredentials()).$2.isNotEmpty;
    // if (authenticated) {
    //   await uiSettingsManager.setOnboardingStep(3);
    //   await onboardingController?.dismissAll();
    // }
  }

  Future<bool> isGithubOauth() async {
    final provider = await uiSettingsManager.getGitProvider();
    return provider == GitProvider.GITHUB;
  }

  ValueNotifier<int?> recommendedAction = ValueNotifier(null);
  ValueNotifier<bool> updatingRecommendedAction = ValueNotifier(false);
  Future<String> getLastSyncOption() async {
    if (await uiSettingsManager.getClientModeEnabled() == true) {
      if (recommendedAction.value != null) {
        return [
          sprintf(t.fetchRemote, [await uiSettingsManager.getRemote()]),
          t.pullChanges,
          t.stageAndCommit,
          t.pushChanges,
        ][recommendedAction.value!];
      }
    }
    return await uiSettingsManager.getString(StorageKey.setman_lastSyncMethod);
  }

  Future<void> updateSyncOptions() async {
    final repomanRepoindex = await repoManager.getInt(StorageKey.repoman_repoIndex);
    final clientModeEnabled = await uiSettingsManager.getClientModeEnabled();
    final dirPath = uiSettingsManager.gitDirPath?.$1;

    final submodulePaths = dirPath == null
        ? []
        : await runGitOperation<List<String>>(LogType.GetSubmodules, (event) => event?["result"].map<String>((path) => "$path").toList() ?? [], {
            "dir": dirPath,
          });
    ;
    syncOptions.value = {};

    syncOptions.value.addAll({
      clientModeEnabled ? t.syncAllChanges : t.syncNow: (
        FontAwesomeIcons.solidCircleDown,
        () async {
          if (branchName.value == null) {
            await InfoDialog.showDialog(
              context,
              "Sync Unavailable on DETACHED HEAD",
              "You can't sync while on a detached HEAD. That means your repository isn't on a branch right now, so changes can't be pushed. To fix this, click the \"DETACHED HEAD\" label, choose either \"main\" or \"master\" from the dropdown to switch back onto a branch, then press sync again.\n\nIf you're unsure which to pick, choose the branch your project normally uses (often main).\n\nIf you find you're often kicked off the branch you expect to be on, please use the \"Report a bug\" button below to describe the issue and the circumstances (what you were doing, branch names, screenshots if possible) so I can investigate and improve the app.",
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: spaceMD),
                  ButtonSetting(
                    text: t.reportABug,
                    icon: FontAwesomeIcons.bug,
                    textColor: colours.primaryDark,
                    iconColor: colours.primaryDark,
                    buttonColor: colours.tertiaryNegative,
                    onPressed: () async {
                      await Logger.reportIssue(context, From.SYNC_DURING_DETACHED_HEAD);
                    },
                  ),
                ],
              ),
            );
            return;
          }
          FlutterBackgroundService().invoke(GitsyncService.FORCE_SYNC);
        },
      ),
      if (!clientModeEnabled)
        t.manualSync: (
          FontAwesomeIcons.barsStaggered,
          () async {
            await ManualSyncDialog.showDialog(context);
            await syncOptionCompletionCallback();
          },
        ),
      if (dirPath != null && clientModeEnabled && submodulePaths.isNotEmpty)
        t.updateSubmodules: (
          FontAwesomeIcons.solidSquareCaretDown,
          () async {
            await runGitOperation(LogType.UpdateSubmodules, (event) => event);
            await syncOptionCompletionCallback();
          },
        ),
      if (clientModeEnabled)
        sprintf(t.fetchRemote, [await uiSettingsManager.getRemote()]): (
          FontAwesomeIcons.caretDown,
          () async {
            await runGitOperation(LogType.FetchRemote, (event) => event);
            await syncOptionCompletionCallback();
          },
        ),
      if (!clientModeEnabled)
        t.downloadChanges: (
          FontAwesomeIcons.angleDown,
          () async {
            final result = await runGitOperation(LogType.DownloadChanges, (event) => event, {"repomanRepoindex": repomanRepoindex});
            FlutterBackgroundService().on("downloadChanges-syncCallback").first.then((_) async {
              if (await uiSettingsManager.getBool(StorageKey.setman_syncMessageEnabled)) {
                Fluttertoast.showToast(msg: t.syncStartPull, toastLength: Toast.LENGTH_LONG, gravity: null);
              }
            });
            if (result == null) return;

            if (result == false &&
                (await runGitOperation<List<(String, int)>>(
                  LogType.UncommittedFiles,
                  (event) => event?["result"].map<(String, int)>((item) => ("${item[0]}", int.parse("${item[1]}"))).toList() ?? [],
                  {"repomanRepoindex": repomanRepoindex},
                )).isNotEmpty) {
              Fluttertoast.showToast(msg: t.pullFailed, toastLength: Toast.LENGTH_LONG, gravity: null);
              return;
            }

            if (await uiSettingsManager.getBool(StorageKey.setman_syncMessageEnabled)) {
              Fluttertoast.showToast(msg: t.syncComplete, toastLength: Toast.LENGTH_LONG, gravity: null);
            }
            await syncOptionCompletionCallback();
          },
        ),
      if (clientModeEnabled)
        t.pullChanges: (
          FontAwesomeIcons.angleDown,
          () async {
            await runGitOperation(LogType.PullFromRepo, (event) => event);
            await syncOptionCompletionCallback();
          },
        ),
      if (clientModeEnabled)
        t.stageAndCommit: (
          FontAwesomeIcons.barsStaggered,
          () async {
            await ManualSyncDialog.showDialog(context);
            await syncOptionCompletionCallback();
          },
        ),
      if (!clientModeEnabled)
        t.uploadChanges: (
          FontAwesomeIcons.angleUp,
          () async {
            final result = await runGitOperation(LogType.UploadChanges, (event) => event, {"repomanRepoindex": repomanRepoindex});
            FlutterBackgroundService().on("uploadChanges-syncCallback").first.then((_) async {
              if (await uiSettingsManager.getBool(StorageKey.setman_syncMessageEnabled)) {
                Fluttertoast.showToast(msg: t.syncStartPush, toastLength: Toast.LENGTH_LONG, gravity: null);
              }
            });
            if (result == null) return;

            if (result == false) {
              Fluttertoast.showToast(msg: t.syncNotRequired, toastLength: Toast.LENGTH_LONG, gravity: null);
              return;
            }

            if (await uiSettingsManager.getBool(StorageKey.setman_syncMessageEnabled)) {
              Fluttertoast.showToast(msg: t.syncComplete, toastLength: Toast.LENGTH_LONG, gravity: null);
            }
            await syncOptionCompletionCallback();
          },
        ),
      if (clientModeEnabled)
        t.pushChanges: (
          FontAwesomeIcons.angleUp,
          () async {
            await runGitOperation(LogType.PushToRepo, (event) => event);
            await syncOptionCompletionCallback();
          },
        ),
      if (!clientModeEnabled)
        t.uploadAndOverwrite: (
          FontAwesomeIcons.anglesUp,
          () async {
            ConfirmForcePushPullDialog.showDialog(context, push: true, () async {
              ForcePushPullDialog.showDialog(context, push: true);
              await runGitOperation(LogType.UploadAndOverwrite, (event) => event);
              Navigator.of(context).canPop() ? Navigator.pop(context) : null;
              syncOptionCompletionCallback();
            });
          },
        ),
      if (!clientModeEnabled)
        t.downloadAndOverwrite: (
          FontAwesomeIcons.anglesDown,
          () async {
            ConfirmForcePushPullDialog.showDialog(context, () async {
              ForcePushPullDialog.showDialog(context);
              await runGitOperation(LogType.DownloadAndOverwrite, (event) => event);
              Navigator.of(context).canPop() ? Navigator.pop(context) : null;
              syncOptionCompletionCallback();
            });
          },
        ),
      if (clientModeEnabled)
        t.forcePush: (
          FontAwesomeIcons.anglesUp,
          () async {
            ConfirmForcePushPullDialog.showDialog(context, push: true, () async {
              ForcePushPullDialog.showDialog(context, push: true);
              await runGitOperation(LogType.ForcePush, (event) => event);
              Navigator.of(context).canPop() ? Navigator.pop(context) : null;
              await syncOptionCompletionCallback();
            });
          },
        ),
      if (clientModeEnabled)
        t.forcePull: (
          FontAwesomeIcons.anglesDown,
          () async {
            ConfirmForcePushPullDialog.showDialog(context, () async {
              ForcePushPullDialog.showDialog(context);
              await runGitOperation(LogType.ForcePull, (event) => event);
              Navigator.of(context).canPop() ? Navigator.pop(context) : null;
              await syncOptionCompletionCallback();
            });
          },
        ),
      clientModeEnabled ? t.switchToSyncMode : t.switchToClientMode: (
        FontAwesomeIcons.rightLeft,
        () async {
          await uiSettingsManager.setBoolNullable(StorageKey.setman_clientModeEnabled, !clientModeEnabled);
          await reloadAll();
        },
      ),
    });

    Future.delayed(Duration.zero, () async {
      if (conflicting.value.isNotEmpty) {
        syncOptions.value.remove(t.syncAllChanges);
        syncOptions.value.remove(t.syncNow);
        syncOptions.value.remove(t.manualSync);
        syncOptions.value.remove(t.updateSubmodules);
        syncOptions.value.remove(sprintf(t.fetchRemote, [await uiSettingsManager.getRemote()]));
        syncOptions.value.remove(t.downloadChanges);
        syncOptions.value.remove(t.pullChanges);
        syncOptions.value.remove(t.stageAndCommit);
        syncOptions.value.remove(t.uploadChanges);
        syncOptions.value.remove(t.pushChanges);
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    loadingRecentCommits.dispose();
    branchName.dispose();
    branchNames.dispose();
    mergeConflictVisible.dispose();

    premiumManager.dispose();

    autoRefreshTimer?.cancel();
    networkSubscription?.cancel();
    for (var key in debounceTimers.keys) {
      if (key.startsWith(iosFolderAccessDebounceReference)) {
        cancelDebounce(key, true);
      }
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      gitLfsExpanded = false;
      await updateRecommendedAction();
      await reloadAll();
    }
    if (state == AppLifecycleState.paused) {
      autoRefreshTimer?.cancel();
      // if (uiSettingsManager.getOnboardingStep() != 0 && onboardingController?.hasSkipped == false) {
      //   onboardingController?.dismissAll();
      // }
    }
  }

  Future<void> showAuthDialog([Function(BaseAlertDialog dialog, {bool cancelable})? showDialog]) async {
    if (AuthDialog.authDialogKey.currentContext != null) {
      Navigator.of(context).canPop() ? Navigator.pop(context) : null;
    }

    return AuthDialog.showDialog(context, () async {
      await reloadAll();
      if ((await uiSettingsManager.getAuthorEmail()).isEmpty || (await uiSettingsManager.getAuthorName()).isEmpty) {
        await AuthorDetailsPromptDialog.showDialog(
          context,
          () async {
            _restorableSettingsMain.present({"recentCommits": recentCommits, "showcaseAuthorDetails": true});
          },
          () async {
            if (await repoManager.getInt(StorageKey.repoman_onboardingStep) == -1) {
              await showCloneRepoPage();
            } else {
              await onboardingController?.show();
              await reloadAll();
            }
          },
        );
        return;
      }
      if (await repoManager.getInt(StorageKey.repoman_onboardingStep) == -1) {
        await showCloneRepoPage();
      } else {
        await onboardingController?.show();
        await reloadAll();
      }
    });
  }

  Future<void> showCloneRepoPage() async {
    Navigator.of(context).push(createCloneRepoMainRoute()).then((_) => reloadAll());
  }

  @override
  Widget build(BuildContext context) {
    initAsync(() async {
      if (Logger.notifClicked == true) {
        Logger.notifClicked = false;
        Logger.dismissError(context);
      }
    });

    return Stack(
      children: [
        Scaffold(
          backgroundColor: colours.primaryDark,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            centerTitle: false,
            actionsPadding: EdgeInsets.only(bottom: spaceXXS),
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: colours.primaryDark,
              systemNavigationBarColor: colours.primaryDark,
              statusBarIconBrightness: Brightness.light,
              systemNavigationBarIconBrightness: Brightness.light,
            ),
            actions: [
              CustomShowcase(
                globalKey: _globalSettingsKey,
                description: t.globalSettingsHint,
                cornerRadius: cornerRadiusMax,
                first: true,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  style: ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  constraints: BoxConstraints(),
                  onPressed: () async {
                    _restorableGlobalSettings.present({"recentCommits": recentCommits.value});
                    widget.reloadLocale();
                  },
                  icon: FaIcon(FontAwesomeIcons.gear, color: colours.tertiaryDark, size: spaceMD + 7),
                ),
              ),
              SizedBox(width: spaceSM),
              SyncLoader(syncProgressKey: _syncProgressKey, reload: () => reloadAll()),
              SizedBox(width: spaceSM),
              CustomShowcase(
                globalKey: _addMoreKey,
                description: t.addMoreHint,
                cornerRadius: cornerRadiusMax,
                customTooltipActions: [
                  TooltipActionButton(
                    backgroundColor: colours.secondaryInfo,
                    textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: textSM, color: colours.primaryLight),
                    leadIcon: ActionButtonIcon(
                      icon: Icon(FontAwesomeIcons.solidFileLines, color: colours.primaryLight, size: textSM),
                    ),
                    name: t.learnMore.toUpperCase(),
                    onTap: () => launchUrl(Uri.parse(multiRepoDocsLink)),
                    type: null,
                  ),
                ],
                child: FutureBuilder(
                  future: repoManager.getStringList(StorageKey.repoman_repoNames),
                  builder: (context, repoNamesSnapshot) => Container(
                    padding: EdgeInsets.zero,
                    decoration: BoxDecoration(color: colours.tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusMax)),
                    child: FutureBuilder(
                      future: repoManager.getInt(StorageKey.repoman_repoIndex),
                      builder: (context, repoIndexSnapshot) => repoNamesSnapshot.data == null
                          ? SizedBox.shrink()
                          : Row(
                              children: [
                                SizedBox(width: spaceXXXS),
                                TextButton(
                                  style: ButtonStyle(
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    minimumSize: WidgetStatePropertyAll(Size.zero),
                                    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceXS, vertical: spaceXS)),
                                  ),
                                  onPressed: () async {
                                    if (premiumManager.hasPremiumNotifier.value != true) {
                                      await UnlockPremiumDialog.showDialog(context, () async {
                                        if (mounted) setState(() {});
                                        await addRepo();
                                      });
                                      if (mounted) setState(() {});
                                      return;
                                    }

                                    if (repoNamesSnapshot.data!.length == 1 || repoSettingsExpanded) {
                                      addRepo();
                                      return;
                                    }

                                    repoSettingsExpanded = !repoSettingsExpanded;
                                    if (mounted) setState(() {});

                                    if (repoSettingsExpanded) {
                                      Future.delayed(
                                        Duration(seconds: 5),
                                        () => mounted
                                            ? setState(() {
                                                repoSettingsExpanded = false;
                                              })
                                            : null,
                                      );
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      ValueListenableBuilder(
                                        valueListenable: premiumManager.hasPremiumNotifier,
                                        builder: (context, hasPremium, child) => FaIcon(
                                          hasPremium == true
                                              ? (repoNamesSnapshot.data!.length == 1 || repoSettingsExpanded
                                                    ? FontAwesomeIcons.solidSquarePlus
                                                    : FontAwesomeIcons.ellipsis)
                                              : FontAwesomeIcons.solidGem,
                                          color: repoNamesSnapshot.data!.length == 1 || repoSettingsExpanded
                                              ? colours.tertiaryPositive
                                              : colours.secondaryLight,
                                          size: textLG,
                                        ),
                                      ),
                                      repoNamesSnapshot.data!.length != 1
                                          ? SizedBox.shrink()
                                          : Padding(
                                              padding: EdgeInsets.only(left: spaceSM),
                                              child: Text(
                                                t.addMore.toUpperCase(),
                                                style: TextStyle(color: colours.primaryLight, fontSize: textSM, fontWeight: FontWeight.w900),
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                                repoNamesSnapshot.data!.length > 1 && repoSettingsExpanded
                                    ? Row(
                                        children: [
                                          IconButton(
                                            style: ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                            constraints: BoxConstraints(),
                                            onPressed: () async {
                                              repoSettingsExpanded = false;
                                              await reloadAll();

                                              RemoveContainerDialog.showDialog(context, (deleteContents) async {
                                                if (deleteContents) {
                                                  await runGitOperation(LogType.DiscardDir, (event) => event, {"dirPath": null});
                                                }

                                                await uiSettingsManager.clearAll();

                                                final repomanReponames = await repoManager.getStringList(StorageKey.repoman_repoNames);
                                                repomanReponames.removeAt(await repoManager.getInt(StorageKey.repoman_repoIndex));

                                                repoManager.setStringList(StorageKey.repoman_repoNames, repomanReponames);

                                                if (await repoManager.getInt(StorageKey.repoman_repoIndex) >= repomanReponames.length) {
                                                  await repoManager.setInt(StorageKey.repoman_repoIndex, repomanReponames.length - 1);
                                                }

                                                if (await repoManager.getInt(StorageKey.repoman_tileSyncIndex) >= repomanReponames.length) {
                                                  await repoManager.setInt(StorageKey.repoman_tileSyncIndex, repomanReponames.length - 1);
                                                }

                                                if (await repoManager.getInt(StorageKey.repoman_tileManualSyncIndex) >= repomanReponames.length) {
                                                  await repoManager.setInt(StorageKey.repoman_tileManualSyncIndex, repomanReponames.length - 1);
                                                }

                                                await uiSettingsManager.reinit();
                                                await reloadAll();
                                              });
                                            },
                                            icon: FaIcon(FontAwesomeIcons.solidSquareMinus, color: colours.tertiaryNegative, size: textLG),
                                          ),
                                          IconButton(
                                            style: ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                            constraints: BoxConstraints(),
                                            onPressed: () async {
                                              repoSettingsExpanded = false;
                                              if (mounted) setState(() {});

                                              if (repoNamesSnapshot.data == null || repoIndexSnapshot.data == null) return;

                                              RenameContainerDialog.showDialog(
                                                context,
                                                repoNamesSnapshot.data![repoIndexSnapshot.data!].toLowerCase(),
                                                (text) async {
                                                  if (text.isEmpty) return;

                                                  final repomanReponames = await repoManager.getStringList(StorageKey.repoman_repoNames);
                                                  uiSettingsManager.renameNamespace(text);
                                                  repomanReponames[await repoManager.getInt(StorageKey.repoman_repoIndex)] = text;

                                                  await repoManager.setStringList(StorageKey.repoman_repoNames, repomanReponames);

                                                  await reloadAll();
                                                },
                                              );
                                            },
                                            icon: FaIcon(FontAwesomeIcons.squarePen, color: colours.tertiaryInfo, size: textLG),
                                          ),
                                        ],
                                      )
                                    : SizedBox.shrink(),
                                SizedBox(width: spaceXXXS),
                                ...repoNamesSnapshot.data!.length > 1
                                    ? [
                                        SizedBox(width: spaceXXXS),
                                        DropdownButton(
                                          borderRadius: BorderRadius.all(cornerRadiusMD),
                                          padding: EdgeInsets.zero,
                                          icon: Padding(
                                            padding: EdgeInsets.symmetric(horizontal: spaceSM),
                                            child: FaIcon(FontAwesomeIcons.caretDown, color: colours.secondaryLight, size: textSM),
                                          ),
                                          value: repoIndexSnapshot.data ?? 0,
                                          style: TextStyle(color: colours.tertiaryLight, fontWeight: FontWeight.w900, fontSize: textMD),
                                          isDense: true,
                                          underline: const SizedBox.shrink(),
                                          dropdownColor: colours.secondaryDark,
                                          onChanged: (value) async {
                                            if (value == null) return;
                                            await repoManager.setInt(StorageKey.repoman_repoIndex, value);
                                            await uiSettingsManager.reinit();
                                            recentCommits.value.clear();
                                            await reloadAll();
                                          },
                                          selectedItemBuilder: (context) => List.generate(
                                            repoNamesSnapshot.data!.length,
                                            (index) => ConstrainedBox(
                                              constraints: BoxConstraints(maxWidth: spaceXXL + spaceLG),
                                              child: Text(
                                                repoNamesSnapshot.data![index].toUpperCase(),
                                                style: TextStyle(fontSize: textXS, color: colours.primaryLight),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          items: List.generate(
                                            repoNamesSnapshot.data!.length,
                                            (index) => DropdownMenuItem(
                                              value: index,
                                              child: Text(
                                                repoNamesSnapshot.data![index].toUpperCase(),
                                                style: TextStyle(fontSize: textXS, color: colours.primaryLight),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ]
                                    : [SizedBox.shrink()],
                              ],
                            ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: spaceMD),
            ],
            title: Padding(
              padding: EdgeInsets.only(left: spaceMD, bottom: spaceXXS),
              child: Text(
                widget.title,
                textAlign: TextAlign.right,
                style: TextStyle(color: colours.primaryLight, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          body: BetterOrientationBuilder(
            builder: (context, orientation) => SingleChildScrollView(
              scrollDirection: orientation == Orientation.portrait ? Axis.vertical : Axis.horizontal,
              child: FutureBuilder(
                future: uiSettingsManager.getClientModeEnabled(),
                builder: (context, clientModeEnabledSnapshot) => Container(
                  width: orientation == Orientation.portrait
                      ? null
                      : MediaQuery.of(context).size.width -
                            (MediaQuery.of(context).systemGestureInsets.right == 48 || MediaQuery.of(context).systemGestureInsets.left == 48
                                ? MediaQuery.of(context).systemGestureInsets.right + MediaQuery.of(context).systemGestureInsets.left
                                : 0),
                  padding: EdgeInsets.only(left: spaceMD, right: spaceMD, bottom: orientation == Orientation.portrait ? 0 : spaceSM),
                  child: Flex(
                    direction: orientation == Orientation.portrait ? Axis.vertical : Axis.horizontal,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Expanded(
                        flex: orientation == Orientation.portrait ? 0 : 1,
                        child: CustomShowcase(
                          globalKey: _controlKey,
                          cornerRadius: cornerRadiusMD,
                          description: t.controlHint,
                          child: ValueListenableBuilder(
                            valueListenable: recentCommits,
                            builder: (context, recentCommitsSnapshot, child) => FutureBuilder(
                              future: GitManager.getInitialRecentCommits(),
                              builder: (context, fastRecentCommitsSnapshot) => ValueListenableBuilder(
                                valueListenable: conflicting,
                                builder: (context, conflictingSnapshot, child) => ListenableBuilder(
                                  listenable: loadingRecentCommits,
                                  builder: (context, child) {
                                    final recentCommits = loadingRecentCommits.value || recentCommitsSnapshot.isEmpty
                                        ? fastRecentCommitsSnapshot.data ?? recentCommitsSnapshot
                                        : recentCommitsSnapshot;
                                    final items = [
                                      ...((conflictingSnapshot.isEmpty)
                                          ? <GitManagerRs.Commit>[]
                                          : [
                                              GitManagerRs.Commit(
                                                timestamp: 0,
                                                authorUsername: "",
                                                authorEmail: "",
                                                reference: mergeConflictReference,
                                                commitMessage: "",
                                                additions: 0,
                                                deletions: 0,
                                                unpulled: false,
                                                unpushed: false,
                                              ),
                                            ]),
                                      ...recentCommits,
                                    ];
                                    if (conflictingSnapshot.isEmpty) mergeConflictVisible.value = true;

                                    if (demoConflicting) {
                                      while (items.length < 3) {
                                        items.add(
                                          GitManagerRs.Commit(
                                            timestamp: 0,
                                            authorUsername: "",
                                            authorEmail: "",
                                            reference: "REFERENCE${Random().nextInt(100)}",
                                            commitMessage: "",
                                            additions: 0,
                                            deletions: 0,
                                            unpulled: false,
                                            unpushed: false,
                                          ),
                                        );
                                      }
                                      items[2] = GitManagerRs.Commit(
                                        timestamp: 0,
                                        authorUsername: "",
                                        authorEmail: "",
                                        reference: mergeConflictReference,
                                        commitMessage: "",
                                        additions: 0,
                                        deletions: 0,
                                        unpulled: false,
                                        unpushed: false,
                                      );
                                    }

                                    return Column(
                                      verticalDirection: orientation == Orientation.portrait ? VerticalDirection.down : VerticalDirection.up,
                                      children: [
                                        Expanded(
                                          flex: orientation == Orientation.portrait ? 0 : 1,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: colours.secondaryDark,
                                              borderRadius: orientation == Orientation.portrait
                                                  ? BorderRadius.only(
                                                      topLeft: cornerRadiusMD,
                                                      bottomLeft: cornerRadiusSM,
                                                      topRight: cornerRadiusMD,
                                                      bottomRight: cornerRadiusSM,
                                                    )
                                                  : BorderRadius.only(
                                                      topLeft: cornerRadiusSM,
                                                      bottomLeft: cornerRadiusMD,
                                                      topRight: cornerRadiusSM,
                                                      bottomRight: cornerRadiusMD,
                                                    ),
                                            ),
                                            padding: EdgeInsets.only(left: spaceSM, bottom: spaceXS, right: spaceSM, top: spaceXS),
                                            child: Column(
                                              verticalDirection: orientation == Orientation.portrait ? VerticalDirection.down : VerticalDirection.up,
                                              children: [
                                                Expanded(
                                                  flex: orientation == Orientation.portrait ? 0 : 1,
                                                  child: Stack(
                                                    clipBehavior: Clip.none,
                                                    children: [
                                                      SizedBox(
                                                        height: orientation == Orientation.portrait ? 220 : double.infinity,
                                                        child: AnimatedBuilder(
                                                          animation: recentCommitsController,
                                                          builder: (context, _) => ShaderMask(
                                                            shaderCallback: (Rect rect) {
                                                              return LinearGradient(
                                                                begin: Alignment.topCenter,
                                                                end: Alignment.bottomCenter,
                                                                colors: [Colors.black, Colors.transparent, Colors.transparent, Colors.transparent],
                                                                stops: [0.0, 0.1, 0.9, 1.0],
                                                              ).createShader(rect);
                                                            },
                                                            blendMode: BlendMode.dstOut,
                                                            child:
                                                                recentCommits.isEmpty &&
                                                                    (fastRecentCommitsSnapshot.connectionState == ConnectionState.waiting ||
                                                                        loadingRecentCommits.value)
                                                                ? Center(child: CircularProgressIndicator(color: colours.tertiaryLight))
                                                                : (recentCommits.isEmpty && conflictingSnapshot.isEmpty
                                                                      ? Center(
                                                                          child: Text(
                                                                            t.commitsNotFound.toUpperCase(),
                                                                            style: TextStyle(
                                                                              color: colours.secondaryLight,
                                                                              fontWeight: FontWeight.bold,
                                                                              fontSize: textLG,
                                                                            ),
                                                                          ),
                                                                        )
                                                                      : Column(
                                                                          children: [
                                                                            Expanded(
                                                                              child: Stack(
                                                                                children: [
                                                                                  AnimatedListView(
                                                                                    controller: recentCommitsController,
                                                                                    reverse: true,
                                                                                    items: items,
                                                                                    isSameItem: (a, b) => a.reference == b.reference,
                                                                                    removeDuration: Duration.zero,
                                                                                    removeItemBuilder: (_, _) => SizedBox.shrink(),
                                                                                    itemBuilder: (BuildContext context, int index) {
                                                                                      final reference = items[index].reference;

                                                                                      if (reference == mergeConflictReference) {
                                                                                        return AnchorItemWrapper(
                                                                                          index: index,
                                                                                          controller: recentCommitsController,
                                                                                          child: ItemMergeConflict(
                                                                                            key: Key(reference),
                                                                                            conflictingSnapshot,
                                                                                            () => reloadAll(),
                                                                                          ),
                                                                                        );
                                                                                      }

                                                                                      return AnchorItemWrapper(
                                                                                        index: index,
                                                                                        controller: recentCommitsController,
                                                                                        child: ItemCommit(
                                                                                          key: Key(reference),
                                                                                          items[index],
                                                                                          index < items.length - 1 ? items[index + 1] : null,
                                                                                          recentCommits,
                                                                                        ),
                                                                                      );
                                                                                    },
                                                                                  ),
                                                                                  ListenableBuilder(
                                                                                    listenable: mergeConflictVisible,
                                                                                    builder: (context, child) => AnimatedPositioned(
                                                                                      bottom:
                                                                                          conflictingSnapshot.isEmpty || mergeConflictVisible.value
                                                                                          ? -spaceXL
                                                                                          : spaceMD,
                                                                                      left: 0,
                                                                                      right: 0,
                                                                                      width: null,
                                                                                      duration: Duration(milliseconds: 200),
                                                                                      child: Center(
                                                                                        child: AnimatedOpacity(
                                                                                          duration: Duration(milliseconds: 200),
                                                                                          opacity:
                                                                                              conflictingSnapshot.isEmpty ||
                                                                                                  mergeConflictVisible.value
                                                                                              ? 0
                                                                                              : 1,
                                                                                          child: TextButton(
                                                                                            onPressed: () async {
                                                                                              await recentCommitsController.animateTo(
                                                                                                0,
                                                                                                duration: Duration(milliseconds: 200),
                                                                                                curve: Curves.easeInOut,
                                                                                              );
                                                                                              mergeConflictVisible.value = true;
                                                                                            },
                                                                                            style: ButtonStyle(
                                                                                              alignment: Alignment.centerLeft,
                                                                                              backgroundColor: WidgetStatePropertyAll(
                                                                                                colours.tertiaryNegative,
                                                                                              ),
                                                                                              padding: WidgetStatePropertyAll(
                                                                                                EdgeInsets.only(
                                                                                                  top: spaceSM,
                                                                                                  left: spaceSM,
                                                                                                  right: spaceSM,
                                                                                                  bottom: spaceXXXS,
                                                                                                ),
                                                                                              ),
                                                                                              shape: WidgetStatePropertyAll(
                                                                                                RoundedRectangleBorder(
                                                                                                  borderRadius: BorderRadius.all(cornerRadiusSM),
                                                                                                  side: BorderSide.none,
                                                                                                ),
                                                                                              ),
                                                                                            ),
                                                                                            child: AnimatedContainer(
                                                                                              duration: Duration(milliseconds: 200),
                                                                                              child: Column(
                                                                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                mainAxisSize: MainAxisSize.max,
                                                                                                children: [
                                                                                                  Text(
                                                                                                    t.mergeConflict.toUpperCase(),
                                                                                                    style: TextStyle(
                                                                                                      color: colours.primaryDark,
                                                                                                      fontSize: textMD,
                                                                                                      overflow: TextOverflow.ellipsis,
                                                                                                      fontWeight: FontWeight.bold,
                                                                                                      height: 1,
                                                                                                    ),
                                                                                                  ),
                                                                                                  FaIcon(
                                                                                                    FontAwesomeIcons.caretDown,
                                                                                                    color: colours.primaryDark,
                                                                                                    size: textMD,
                                                                                                  ),
                                                                                                ],
                                                                                              ),
                                                                                            ),
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        )),
                                                          ),
                                                        ),
                                                      ),
                                                      ...(recentCommits.isNotEmpty == true && loadingRecentCommits.value)
                                                          ? [
                                                              Positioned(
                                                                top: orientation == Orientation.portrait ? -(spaceXS / 2) : 0,
                                                                left: 0,
                                                                right: 0,
                                                                child: LinearProgressIndicator(
                                                                  value: null,
                                                                  backgroundColor: colours.secondaryDark,
                                                                  color: colours.tertiaryDark,
                                                                  borderRadius: BorderRadius.all(cornerRadiusMD),
                                                                ),
                                                              ),
                                                            ]
                                                          : [],
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(height: orientation == Orientation.portrait ? spaceXS : 0),

                                                ListenableBuilder(
                                                  listenable: branchName,
                                                  builder: (context, child) => FutureBuilder(
                                                    future: uiSettingsManager.getStringNullable(StorageKey.setman_branchName),
                                                    builder: (context, fastBranchNameSnapshot) => ListenableBuilder(
                                                      listenable: branchNames,
                                                      builder: (context, child) => FutureBuilder(
                                                        future: uiSettingsManager.getStringList(StorageKey.setman_branchNames),
                                                        builder: (context, fastBranchNamesSnapshot) {
                                                          final branchNameValue = fastBranchNameSnapshot.data ?? branchName.value;
                                                          final branchNamesValue =
                                                              fastBranchNamesSnapshot.data == null || fastBranchNamesSnapshot.data!.isEmpty
                                                              ? branchNames.value
                                                              : fastBranchNamesSnapshot.data;

                                                          return Row(
                                                            children: [
                                                              Expanded(
                                                                child: Stack(
                                                                  children: [
                                                                    DropdownButton(
                                                                      isDense: true,
                                                                      isExpanded: true,
                                                                      hint: Text(
                                                                        t.detachedHead.toUpperCase(),
                                                                        style: TextStyle(
                                                                          fontSize: textMD,
                                                                          fontWeight: FontWeight.bold,
                                                                          color: colours.secondaryLight,
                                                                        ),
                                                                      ),
                                                                      padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceXS),
                                                                      value: branchNamesValue?.contains(branchNameValue) == true
                                                                          ? branchNameValue
                                                                          : null,
                                                                      menuMaxHeight: 250,
                                                                      dropdownColor: colours.secondaryDark,
                                                                      borderRadius: BorderRadius.all(cornerRadiusSM),
                                                                      selectedItemBuilder: (context) => List.generate(
                                                                        (branchNamesValue ?? []).length,
                                                                        (index) => Row(
                                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                                          children: [
                                                                            Flexible(
                                                                              child: Text(
                                                                                (branchNamesValue ?? [])[index].toUpperCase(),
                                                                                overflow: TextOverflow.ellipsis,
                                                                                style: TextStyle(
                                                                                  fontSize: textMD,
                                                                                  fontWeight: FontWeight.bold,
                                                                                  color: !(conflictingSnapshot.isEmpty)
                                                                                      ? colours.tertiaryLight
                                                                                      : colours.primaryLight,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                      underline: const SizedBox.shrink(),
                                                                      onChanged: !(conflictingSnapshot.isEmpty)
                                                                          ? null
                                                                          : <String>(value) async {
                                                                              if (value == branchNameValue) return;

                                                                              await ConfirmBranchCheckoutDialog.showDialog(context, value, () async {
                                                                                await runGitOperation(LogType.CheckoutBranch, (event) => event, {
                                                                                  "branchName": value,
                                                                                });
                                                                              });
                                                                              await reloadAll();
                                                                            },
                                                                      items: (branchNamesValue ?? [])
                                                                          .map(
                                                                            (item) => DropdownMenuItem(
                                                                              value: item,
                                                                              child: Text(
                                                                                item.toUpperCase(),
                                                                                style: TextStyle(
                                                                                  fontSize: textSM,
                                                                                  color: colours.primaryLight,
                                                                                  fontWeight: FontWeight.bold,
                                                                                  overflow: TextOverflow.ellipsis,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          )
                                                                          .toList(),
                                                                    ),
                                                                    Positioned(
                                                                      top: -spaceXXXXS,
                                                                      left: spaceXS,
                                                                      child: Text(
                                                                        t.currentBranch.toUpperCase(),
                                                                        style: TextStyle(
                                                                          color: colours.tertiaryLight,
                                                                          fontSize: textXXS,
                                                                          fontWeight: FontWeight.w900,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              IconButton(
                                                                onPressed: branchNamesValue?.contains(branchNameValue) == true
                                                                    ? () {
                                                                        CreateBranchDialog.showDialog(context, branchNameValue, branchNamesValue, (
                                                                          branchNameValue,

                                                                          basedOn,
                                                                        ) async {
                                                                          await runGitOperation(LogType.CreateBranch, (event) => event, {
                                                                            "branchName": branchNameValue,
                                                                            "basedOn": basedOn,
                                                                          });
                                                                          await syncOptionCompletionCallback();
                                                                        });
                                                                      }
                                                                    : null,
                                                                style: ButtonStyle(
                                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                                  backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                                                                  padding: WidgetStatePropertyAll(
                                                                    EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceXS),
                                                                  ),
                                                                  shape: WidgetStatePropertyAll(
                                                                    RoundedRectangleBorder(
                                                                      borderRadius: BorderRadius.all(cornerRadiusSM),
                                                                      side: BorderSide.none,
                                                                    ),
                                                                  ),
                                                                ),
                                                                constraints: BoxConstraints(),
                                                                icon: FaIcon(
                                                                  FontAwesomeIcons.solidSquarePlus,
                                                                  color: branchNamesValue?.contains(branchNameValue) == true
                                                                      ? colours.primaryLight
                                                                      : colours.secondaryLight,
                                                                  size: textXL,
                                                                  semanticLabel: t.addBranchLabel,
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: spaceSM),
                                        ValueListenableBuilder(
                                          valueListenable: syncOptions,
                                          builder: (context, syncOptionsSnapshot, child) => ValueListenableBuilder(
                                            valueListenable: recommendedAction,
                                            builder: (context, recommendedActionValue, _) => FutureBuilder(
                                              future: getLastSyncOption(),
                                              builder: (context, lastSyncMethodSnapshot) => Column(
                                                children: [
                                                  IntrinsicHeight(
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.max,
                                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                                      children: [
                                                        Expanded(
                                                          child: Stack(
                                                            children: [
                                                              SizedBox.expand(
                                                                child: TextButton.icon(
                                                                  key: syncMethodMainButtonKey,
                                                                  onPressed: () async {
                                                                    if (lastSyncMethodSnapshot.data == null) return;

                                                                    await syncWrapper(
                                                                      () async {
                                                                        if (syncOptionsSnapshot.containsKey(lastSyncMethodSnapshot.data) == true) {
                                                                          syncOptionsSnapshot[lastSyncMethodSnapshot.data]!.$2();
                                                                        } else {
                                                                          await syncOptionsSnapshot.values.first.$2();
                                                                        }
                                                                      },
                                                                      [
                                                                        t.syncAllChanges,
                                                                        t.syncNow,
                                                                        t.switchToClientMode,
                                                                        t.switchToSyncMode,
                                                                      ].contains(
                                                                        syncOptionsSnapshot.containsKey(lastSyncMethodSnapshot.data) == true
                                                                            ? lastSyncMethodSnapshot.data
                                                                            : syncOptionsSnapshot.keys.first,
                                                                      ),
                                                                    );
                                                                  },
                                                                  style: ButtonStyle(
                                                                    alignment: Alignment.centerLeft,
                                                                    backgroundColor: WidgetStatePropertyAll(colours.secondaryDark),
                                                                    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD)),
                                                                    shape: WidgetStatePropertyAll(
                                                                      RoundedRectangleBorder(
                                                                        borderRadius: orientation == Orientation.portrait
                                                                            ? BorderRadius.only(
                                                                                topLeft: cornerRadiusSM,
                                                                                topRight: cornerRadiusSM,
                                                                                bottomLeft: cornerRadiusMD,
                                                                                bottomRight: clientModeEnabledSnapshot.data == true
                                                                                    ? cornerRadiusMD
                                                                                    : cornerRadiusSM,
                                                                              )
                                                                            : BorderRadius.only(
                                                                                topLeft: cornerRadiusMD,
                                                                                bottomRight: cornerRadiusSM,
                                                                                bottomLeft: cornerRadiusSM,
                                                                                topRight: clientModeEnabledSnapshot.data == true
                                                                                    ? cornerRadiusMD
                                                                                    : cornerRadiusSM,
                                                                              ),
                                                                        side: BorderSide.none,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  icon: Stack(
                                                                    clipBehavior: Clip.none,
                                                                    children: [
                                                                      if (clientModeEnabledSnapshot.data == true)
                                                                        Positioned(
                                                                          top: -spaceXXS,
                                                                          bottom: -spaceXXS,
                                                                          left: -spaceXXS,
                                                                          right: -spaceXXS,
                                                                          child: ValueListenableBuilder(
                                                                            valueListenable: updatingRecommendedAction,
                                                                            builder: (context, value, child) => value
                                                                                ? CircularProgressIndicator(color: colours.tertiaryDark)
                                                                                : SizedBox.shrink(),
                                                                          ),
                                                                        ),
                                                                      SizedBox(
                                                                        height: textLG,
                                                                        width: textLG,
                                                                        child: Center(
                                                                          child: FaIcon(
                                                                            syncOptionsSnapshot[lastSyncMethodSnapshot.data]?.$1 ??
                                                                                (syncOptionsSnapshot.values.isNotEmpty
                                                                                    ? syncOptionsSnapshot.values.first.$1
                                                                                    : null) ??
                                                                                FontAwesomeIcons.solidCircleDown,
                                                                            color: colours.primaryLight,
                                                                            size: textLG,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  label: Padding(
                                                                    padding: EdgeInsets.only(left: spaceXS),
                                                                    child: Text(
                                                                      ((syncOptionsSnapshot.containsKey(lastSyncMethodSnapshot.data) == true
                                                                                  ? lastSyncMethodSnapshot.data
                                                                                  : (syncOptionsSnapshot.keys.isNotEmpty
                                                                                        ? syncOptionsSnapshot.keys.first
                                                                                        : (clientModeEnabledSnapshot.data == true
                                                                                              ? t.syncAllChanges
                                                                                              : t.syncNow))) ??
                                                                              t.syncNow)
                                                                          .toUpperCase(),
                                                                      style: TextStyle(
                                                                        color:
                                                                            clientModeEnabledSnapshot.data == true && recommendedActionValue != null
                                                                            ? colours.tertiaryInfo
                                                                            : colours.primaryLight,
                                                                        fontSize: textMD,
                                                                        fontWeight: FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              Positioned(
                                                                right: 0,
                                                                top: 0,
                                                                bottom: 0,
                                                                child: IconButton(
                                                                  onPressed: () async {
                                                                    if (demo) {
                                                                      demoConflicting = true;
                                                                      await reloadAll();
                                                                      MergeConflictDialog.showDialog(context, ["Readme.md"])
                                                                          .then((_) async {
                                                                            demoConflicting = false;
                                                                            await reloadAll();
                                                                          })
                                                                          .then((_) => reloadAll());

                                                                      return;
                                                                    }

                                                                    GestureDetector? detector;

                                                                    void searchForGestureDetector(BuildContext? element) {
                                                                      element?.visitChildElements((element) {
                                                                        if (element.widget is GestureDetector) {
                                                                          detector = element.widget as GestureDetector;
                                                                          return;
                                                                        } else {
                                                                          searchForGestureDetector(element);
                                                                        }

                                                                        return;
                                                                      });
                                                                    }

                                                                    searchForGestureDetector(syncMethodsDropdownKey.currentContext);

                                                                    if (detector?.onTap != null) detector?.onTap!();
                                                                  },
                                                                  style: ButtonStyle(
                                                                    backgroundColor: WidgetStatePropertyAll(colours.secondaryDark),
                                                                    padding: WidgetStatePropertyAll(
                                                                      EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceMD),
                                                                    ),
                                                                    shape: WidgetStatePropertyAll(
                                                                      RoundedRectangleBorder(
                                                                        borderRadius: orientation == Orientation.portrait
                                                                            ? BorderRadius.only(
                                                                                topLeft: cornerRadiusSM,
                                                                                topRight: cornerRadiusSM,
                                                                                bottomLeft: cornerRadiusMD,
                                                                                bottomRight: clientModeEnabledSnapshot.data == true
                                                                                    ? cornerRadiusMD
                                                                                    : cornerRadiusSM,
                                                                              )
                                                                            : BorderRadius.only(
                                                                                topLeft: cornerRadiusMD,
                                                                                bottomRight: cornerRadiusSM,
                                                                                bottomLeft: cornerRadiusSM,
                                                                                topRight: clientModeEnabledSnapshot.data == true
                                                                                    ? cornerRadiusMD
                                                                                    : cornerRadiusSM,
                                                                              ),
                                                                        side: BorderSide.none,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  icon: FaIcon(
                                                                    FontAwesomeIcons.ellipsis,
                                                                    color: colours.primaryLight,
                                                                    size: textLG,
                                                                    semanticLabel: t.moreSyncOptionsLabel,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        ...clientModeEnabledSnapshot.data != true
                                                            ? [
                                                                SizedBox(width: spaceSM),
                                                                IconButton(
                                                                  onPressed: () {
                                                                    _restorableSettingsMain.present({"recentCommits": recentCommits});
                                                                  },
                                                                  style: ButtonStyle(
                                                                    backgroundColor: WidgetStatePropertyAll(colours.secondaryDark),
                                                                    padding: WidgetStatePropertyAll(
                                                                      EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceMD),
                                                                    ),
                                                                    shape: WidgetStatePropertyAll(
                                                                      RoundedRectangleBorder(
                                                                        borderRadius: BorderRadius.all(cornerRadiusSM),
                                                                        side: BorderSide.none,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  icon: FaIcon(
                                                                    FontAwesomeIcons.gear,
                                                                    color: colours.primaryLight,
                                                                    size: textLG,
                                                                    semanticLabel: t.repositorySettingsLabel,
                                                                  ),
                                                                ),
                                                                SizedBox(width: spaceSM),
                                                                FutureBuilder(
                                                                  future: uiSettingsManager.getBool(StorageKey.setman_syncMessageEnabled),
                                                                  builder: (context, snapshot) => IconButton(
                                                                    onPressed: () async {
                                                                      if (!(snapshot.data ?? false)) {
                                                                        if (!(await Permission.notification.request().isGranted)) return;
                                                                      }

                                                                      uiSettingsManager.setBool(
                                                                        StorageKey.setman_syncMessageEnabled,
                                                                        !(snapshot.data ?? false),
                                                                      );
                                                                      await reloadAll();
                                                                    },
                                                                    style: ButtonStyle(
                                                                      backgroundColor: WidgetStatePropertyAll(colours.secondaryDark),
                                                                      padding: WidgetStatePropertyAll(
                                                                        EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceMD),
                                                                      ),
                                                                      shape: WidgetStatePropertyAll(
                                                                        RoundedRectangleBorder(
                                                                          borderRadius: orientation == Orientation.portrait
                                                                              ? BorderRadius.only(
                                                                                  topLeft: cornerRadiusSM,
                                                                                  topRight: cornerRadiusSM,
                                                                                  bottomLeft: cornerRadiusSM,
                                                                                  bottomRight: cornerRadiusMD,
                                                                                )
                                                                              : BorderRadius.only(
                                                                                  topLeft: cornerRadiusSM,
                                                                                  topRight: cornerRadiusMD,
                                                                                  bottomLeft: cornerRadiusSM,
                                                                                  bottomRight: cornerRadiusSM,
                                                                                ),
                                                                          side: BorderSide.none,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    icon: Stack(
                                                                      alignment: Alignment.center,
                                                                      children: [
                                                                        FaIcon(
                                                                          FontAwesomeIcons.solidBellSlash,
                                                                          color: Colors.transparent,
                                                                          size: textLG - 2,
                                                                        ),
                                                                        FaIcon(
                                                                          demo || snapshot.data == true
                                                                              ? FontAwesomeIcons.solidBell
                                                                              : FontAwesomeIcons.solidBellSlash,
                                                                          color: demo || snapshot.data == true
                                                                              ? colours.primaryPositive
                                                                              : colours.primaryLight,
                                                                          size: textLG - 2,
                                                                          semanticLabel: t.syncMessagesLabel,
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              ]
                                                            : [],
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    height: 0,
                                                    width: double.infinity,
                                                    decoration: BoxDecoration(borderRadius: BorderRadius.all(cornerRadiusSM)),
                                                    margin: EdgeInsets.symmetric(horizontal: spaceMD),
                                                    padding: EdgeInsets.only(top: spaceLG + spaceXS),
                                                    child: DropdownButton(
                                                      key: syncMethodsDropdownKey,
                                                      borderRadius: BorderRadius.all(cornerRadiusSM),
                                                      selectedItemBuilder: (context) =>
                                                          List.generate(syncOptionsSnapshot.length, (_) => SizedBox.shrink()),
                                                      icon: SizedBox.shrink(),
                                                      underline: const SizedBox.shrink(),
                                                      menuWidth: MediaQuery.of(context).size.width - (spaceMD * 2),
                                                      // menuWidth: null,
                                                      dropdownColor: colours.secondaryDark,
                                                      padding: EdgeInsets.zero,
                                                      alignment: Alignment.bottomCenter,
                                                      onChanged: (value) {},
                                                      items: (syncOptionsSnapshot).entries
                                                          .where(
                                                            (item) =>
                                                                item.key !=
                                                                (syncOptionsSnapshot.containsKey(lastSyncMethodSnapshot.data) == true
                                                                    ? lastSyncMethodSnapshot.data
                                                                    : (syncOptionsSnapshot.keys.isNotEmpty ? syncOptionsSnapshot.keys.first : "")),
                                                          )
                                                          .map(
                                                            (item) => DropdownMenuItem(
                                                              onTap: () async {
                                                                if (![t.switchToClientMode, t.switchToSyncMode].contains(item.key)) {
                                                                  await uiSettingsManager.setString(StorageKey.setman_lastSyncMethod, item.key);
                                                                }

                                                                await syncWrapper(
                                                                  () async => await item.value.$2(),
                                                                  [
                                                                    t.syncAllChanges,
                                                                    t.syncNow,
                                                                    t.switchToClientMode,
                                                                    t.switchToSyncMode,
                                                                  ].contains(item.key),
                                                                );
                                                              },
                                                              value: item.key,
                                                              child: Row(
                                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                                children: [
                                                                  FaIcon(
                                                                    item.value.$1,
                                                                    color: [t.switchToClientMode, t.switchToSyncMode].contains(item.key)
                                                                        ? colours.tertiaryInfo
                                                                        : colours.primaryLight,
                                                                    size: textLG,
                                                                  ),
                                                                  SizedBox(width: spaceMD),
                                                                  Flexible(
                                                                    child: Text(
                                                                      item.key.toUpperCase(),
                                                                      maxLines: 1,
                                                                      overflow: TextOverflow.ellipsis,
                                                                      style: TextStyle(
                                                                        fontSize: textMD,
                                                                        color: [t.switchToClientMode, t.switchToSyncMode].contains(item.key)
                                                                            ? colours.tertiaryInfo
                                                                            : colours.primaryLight,
                                                                        fontWeight: FontWeight.bold,
                                                                        overflow: TextOverflow.ellipsis,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          )
                                                          .toList(),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: spaceLG, width: spaceMD),

                      Expanded(
                        flex: orientation == Orientation.portrait ? 0 : 1,
                        child: FutureBuilder(
                          future: isAuthenticated(),
                          builder: (context, isAuthenticatedSnapshot) =>
                              (orientation == Orientation.portrait
                              ? (List<Widget> children) => Column(children: children)
                              : (List<Widget> children) => ShaderMask(
                                  shaderCallback: (Rect rect) {
                                    return LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [Colors.transparent, Colors.transparent, Colors.transparent, Colors.black],
                                      stops: [0, 0.05, 0.95, 1.0],
                                    ).createShader(rect);
                                  },
                                  blendMode: BlendMode.dstOut,
                                  child: SingleChildScrollView(child: ListBody(children: children)),
                                ))([
                                CustomShowcase(
                                  cornerRadius: cornerRadiusMD,
                                  globalKey: _configKey,
                                  description: t.configHint,
                                  child: Column(
                                    children: [
                                      IntrinsicHeight(
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            ValueListenableBuilder(
                                              valueListenable: remoteUrlLink,
                                              builder: (context, snapshot, child) => FutureBuilder(
                                                future: uiSettingsManager.getStringList(StorageKey.setman_remoteUrlLink),
                                                builder: (context, fastRemoteUrlLinkSnapshot) {
                                                  final remoteUrlLinkValue =
                                                      fastRemoteUrlLinkSnapshot.data == null || fastRemoteUrlLinkSnapshot.data!.isEmpty == true
                                                      ? snapshot
                                                      : (fastRemoteUrlLinkSnapshot.data!.first, fastRemoteUrlLinkSnapshot.data!.last);
                                                  return Expanded(
                                                    child: Stack(
                                                      children: [
                                                        Container(
                                                          padding: EdgeInsets.zero,
                                                          decoration: BoxDecoration(
                                                            color: colours.secondaryDark,
                                                            borderRadius: BorderRadius.all(cornerRadiusMD),
                                                          ),
                                                          child: DropdownButton(
                                                            borderRadius: BorderRadius.all(cornerRadiusMD),
                                                            padding: EdgeInsets.only(left: spaceMD, right: spaceXXS, top: 1, bottom: 1),
                                                            onTap: () {
                                                              if (demo) {
                                                                ManualSyncDialog.showDialog(context).then((_) => reloadAll());
                                                                return;
                                                              }
                                                            },
                                                            icon: Padding(
                                                              padding: EdgeInsets.symmetric(horizontal: spaceSM),
                                                              child: FaIcon(
                                                                remoteUrlLinkValue != null
                                                                    ? FontAwesomeIcons.caretDown
                                                                    : FontAwesomeIcons.solidCircleXmark,
                                                                color: remoteUrlLinkValue != null ? colours.secondaryLight : colours.primaryNegative,
                                                                size: textLG,
                                                              ),
                                                            ),
                                                            value: 0,
                                                            isExpanded: true,
                                                            underline: const SizedBox.shrink(),
                                                            dropdownColor: colours.secondaryDark,
                                                            onChanged: (value) async {},
                                                            selectedItemBuilder: (context) => List.generate(
                                                              remoteActions.length,
                                                              (index) => Row(
                                                                children: [
                                                                  Expanded(
                                                                    child: ExtendedText(
                                                                      demo
                                                                          ? "https://github.com/ViscousTests/TestObsidianVault.git"
                                                                          : (remoteUrlLinkValue == null ? t.repoNotFound : remoteUrlLinkValue.$1),
                                                                      maxLines: 1,
                                                                      textAlign: TextAlign.left,
                                                                      softWrap: false,
                                                                      overflowWidget: TextOverflowWidget(
                                                                        position: TextOverflowPosition.start,
                                                                        child: Text(
                                                                          "…",
                                                                          style: TextStyle(
                                                                            color: colours.tertiaryLight,
                                                                            fontSize: textMD,
                                                                            fontWeight: FontWeight.w400,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      style: TextStyle(
                                                                        color: remoteUrlLinkValue != null
                                                                            ? colours.primaryLight
                                                                            : colours.secondaryLight,
                                                                        fontSize: textMD,
                                                                        fontWeight: FontWeight.w400,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            items: List.generate(
                                                              remoteActions.length,
                                                              (index) => DropdownMenuItem(
                                                                value: index,
                                                                onTap: () async {
                                                                  await remoteActions[index].$2(context, remoteUrlLinkValue);
                                                                  await reloadAll();
                                                                },
                                                                child: Row(
                                                                  children: [
                                                                    remoteActions[index].$1.$2,
                                                                    SizedBox(width: spaceSM),
                                                                    Text(
                                                                      remoteActions[index].$1.$1.toUpperCase(),
                                                                      style: TextStyle(
                                                                        fontSize: textXS,
                                                                        color: colours.primaryLight,
                                                                        fontWeight: FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        Positioned(
                                                          top: spaceXXXXS / 2,
                                                          left: spaceSM,
                                                          child: Text(
                                                            t.remote.toUpperCase(),
                                                            style: TextStyle(
                                                              color: colours.tertiaryLight,
                                                              fontSize: textXXS,
                                                              fontWeight: FontWeight.w900,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            SizedBox(width: uiSettingsManager.gitDirPath?.$2 == null ? spaceSM : 0),
                                            Visibility(
                                              visible: uiSettingsManager.gitDirPath?.$2 == null,
                                              child: TextButton.icon(
                                                onPressed: isAuthenticatedSnapshot.data == true
                                                    ? () async {
                                                        await showCloneRepoPage();
                                                      }
                                                    : null,
                                                style: ButtonStyle(
                                                  backgroundColor: WidgetStatePropertyAll(colours.secondaryDark),
                                                  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceMD)),
                                                  shape: WidgetStatePropertyAll(
                                                    RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
                                                  ),
                                                ),
                                                icon: FaIcon(
                                                  FontAwesomeIcons.cloudArrowDown,
                                                  color: isAuthenticatedSnapshot.data == true ? colours.primaryLight : colours.tertiaryLight,
                                                  size: textLG - 2,
                                                ),
                                                iconAlignment: IconAlignment.start,
                                                label: Padding(
                                                  padding: EdgeInsets.only(left: spaceXS),
                                                  child: Text(
                                                    t.clone.toUpperCase(),
                                                    style: TextStyle(color: colours.primaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: spaceSM),
                                            Container(
                                              decoration: BoxDecoration(borderRadius: BorderRadius.all(cornerRadiusMD), color: colours.secondaryDark),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                children: [
                                                  TextButton.icon(
                                                    onPressed: () async {
                                                      await showAuthDialog();
                                                    },
                                                    style: ButtonStyle(
                                                      alignment: Alignment.centerLeft,
                                                      backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                                                      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceMD)),
                                                      shape: WidgetStatePropertyAll(
                                                        RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
                                                      ),
                                                    ),
                                                    icon: FaIcon(
                                                      isAuthenticatedSnapshot.data == true
                                                          ? FontAwesomeIcons.solidCircleCheck
                                                          : FontAwesomeIcons.solidCircleXmark,
                                                      color: isAuthenticatedSnapshot.data == true ? colours.primaryPositive : colours.primaryNegative,
                                                      size: textLG,
                                                    ),
                                                    label: Padding(
                                                      padding: EdgeInsets.only(left: spaceXS),
                                                      child: Text(
                                                        t.auth.toUpperCase(),
                                                        style: TextStyle(color: colours.primaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
                                                      ),
                                                    ),
                                                  ),

                                                  FutureBuilder(
                                                    future: (() async =>
                                                        await uiSettingsManager.getGitProvider() == GitProvider.GITHUB &&
                                                        await uiSettingsManager.getBool(StorageKey.setman_githubScopedOauth) == true)(),
                                                    builder: (context, gitProviderSnapshot) => !(gitProviderSnapshot.data == true)
                                                        ? SizedBox.shrink()
                                                        : IconButton(
                                                            padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceMD),
                                                            style: ButtonStyle(
                                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                              backgroundColor: WidgetStatePropertyAll(colours.tertiaryDark),
                                                              shape: WidgetStatePropertyAll(
                                                                RoundedRectangleBorder(
                                                                  borderRadius: BorderRadiusGeometry.only(
                                                                    topRight: cornerRadiusMD,
                                                                    bottomRight: cornerRadiusMD,
                                                                    bottomLeft: Radius.zero,
                                                                    topLeft: Radius.zero,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            constraints: BoxConstraints(),
                                                            onPressed: () async {
                                                              final gitProviderManager = GithubAppManager();

                                                              final usernameToken = await uiSettingsManager.getGitHttpAuthCredentials();

                                                              final token = await gitProviderManager.getToken(usernameToken.$2, (_, _, _) async {});

                                                              if (token == null) return;

                                                              final githubAppInstallations = await gitProviderManager.getGitHubAppInstallations(
                                                                token,
                                                              );
                                                              if (githubAppInstallations.isEmpty) {
                                                                await launchUrl(Uri.parse("https://github.com/apps/gitsync-viscouspotential"));
                                                              } else {
                                                                await launchUrl(
                                                                  Uri.parse(
                                                                    "https://github.com/settings/installations/${githubAppInstallations[0]["id"]}",
                                                                  ),
                                                                );
                                                              }
                                                            },
                                                            icon: FaIcon(FontAwesomeIcons.sliders, size: textLG, color: colours.secondaryLight),
                                                          ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: spaceMD),

                                      IntrinsicHeight(
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Expanded(
                                              child: Stack(
                                                children: [
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: colours.secondaryDark,
                                                      borderRadius: BorderRadius.only(
                                                        bottomLeft: cornerRadiusMD,
                                                        bottomRight: cornerRadiusSM,
                                                        topLeft: cornerRadiusMD,
                                                        topRight: cornerRadiusSM,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Flexible(
                                                          child: Padding(
                                                            padding: EdgeInsets.all(spaceMD),
                                                            child: ExtendedText(
                                                              demo
                                                                  ? (Platform.isIOS
                                                                        ? "TestObsidianVault"
                                                                        : "/storage/emulated/0/github/ViscousTests/TestObsidianVault")
                                                                  : (uiSettingsManager.gitDirPath?.$2 == null
                                                                        ? t.repoNotFound
                                                                        : (Platform.isIOS
                                                                                  ? uiSettingsManager.gitDirPath?.$2.split("/").last
                                                                                  : uiSettingsManager.gitDirPath?.$2) ??
                                                                              ""),
                                                              maxLines: 1,
                                                              textAlign: TextAlign.left,
                                                              softWrap: false,
                                                              overflowWidget: TextOverflowWidget(
                                                                position: TextOverflowPosition.start,
                                                                child: Text(
                                                                  "…",
                                                                  style: TextStyle(
                                                                    color: uiSettingsManager.gitDirPath?.$2 == null
                                                                        ? colours.secondaryLight
                                                                        : colours.primaryLight,
                                                                    fontSize: textMD,
                                                                  ),
                                                                ),
                                                              ),
                                                              style: TextStyle(
                                                                color: uiSettingsManager.gitDirPath?.$2 == null
                                                                    ? colours.secondaryLight
                                                                    : colours.primaryLight,
                                                                fontSize: textMD,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        uiSettingsManager.gitDirPath?.$2 == null
                                                            ? SizedBox.shrink()
                                                            : IconButton(
                                                                onPressed: () async {
                                                                  await uiSettingsManager.setGitDirPath("");
                                                                  branchName.value = null;
                                                                  remoteUrlLink.value = null;
                                                                  recommendedAction.value = null;
                                                                  branchNames.value = [];
                                                                  recentCommits.value = [];
                                                                  conflicting.value = [];
                                                                  await updateSyncOptions();
                                                                  if (mounted) setState(() {});
                                                                },
                                                                constraints: BoxConstraints(),
                                                                style: ButtonStyle(
                                                                  backgroundColor: WidgetStatePropertyAll(colours.secondaryDark),
                                                                  padding: WidgetStatePropertyAll(EdgeInsets.all(spaceMD)),
                                                                  visualDensity: VisualDensity.compact,
                                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                                  shape: WidgetStatePropertyAll(
                                                                    RoundedRectangleBorder(
                                                                      borderRadius: BorderRadius.all(cornerRadiusSM),
                                                                      side: BorderSide.none,
                                                                    ),
                                                                  ),
                                                                ),
                                                                icon: FaIcon(
                                                                  FontAwesomeIcons.solidCircleXmark,
                                                                  size: textLG,
                                                                  color: colours.primaryLight,
                                                                  semanticLabel: t.deselectDirLabel,
                                                                ),
                                                              ),
                                                      ],
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: spaceXXXXS / 2,
                                                    left: spaceSM,
                                                    child: Text(
                                                      t.directory.toUpperCase(),
                                                      style: TextStyle(color: colours.tertiaryLight, fontSize: textXXS, fontWeight: FontWeight.w900),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(width: spaceSM),
                                            IconButton(
                                              onPressed: isAuthenticatedSnapshot.data == true
                                                  ? () async {
                                                      String? selectedDirectory;
                                                      if (await requestStoragePerm()) {
                                                        selectedDirectory = await pickDirectory();
                                                      }
                                                      if (selectedDirectory == null) return;

                                                      if (!mounted) return;
                                                      await setGitDirPathGetSubmodules(context, selectedDirectory);
                                                      await repoManager.setOnboardingStep(4);

                                                      await onboardingController?.show();

                                                      await reloadAll();
                                                    }
                                                  : null,
                                              style: ButtonStyle(
                                                backgroundColor: WidgetStatePropertyAll(colours.secondaryDark),
                                                padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceMD)),
                                                shape: WidgetStatePropertyAll(
                                                  RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.only(
                                                      bottomLeft: cornerRadiusSM,
                                                      bottomRight: cornerRadiusMD,
                                                      topLeft: cornerRadiusSM,
                                                      topRight: cornerRadiusMD,
                                                    ),
                                                    side: BorderSide.none,
                                                  ),
                                                ),
                                              ),
                                              icon: FaIcon(
                                                FontAwesomeIcons.solidFolderOpen,
                                                color: isAuthenticatedSnapshot.data == true ? colours.primaryLight : colours.tertiaryLight,
                                                size: textLG - 2,
                                                semanticLabel: t.selectDirLabel,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: spaceMD),
                                      SizedBox(
                                        width: double.infinity,
                                        child: TextButton.icon(
                                          onPressed: uiSettingsManager.gitDirPath?.$2 == null
                                              ? null
                                              : () async {
                                                  await useDirectory(
                                                    await uiSettingsManager.getString(StorageKey.setman_gitDirPath),
                                                    (bookmarkPath) async => await uiSettingsManager.setGitDirPath(bookmarkPath, true),
                                                    (path) async {
                                                      await Navigator.of(
                                                        context,
                                                      ).push(createFileExplorerRoute(recentCommits.value, path)).then((_) => reloadAll());
                                                    },
                                                  );
                                                },
                                          style: ButtonStyle(
                                            alignment: Alignment.center,
                                            backgroundColor: WidgetStatePropertyAll(colours.secondaryDark),
                                            padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceMD)),
                                            shape: WidgetStatePropertyAll(
                                              RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
                                            ),
                                          ),
                                          icon: FaIcon(
                                            FontAwesomeIcons.filePen,
                                            color: uiSettingsManager.gitDirPath?.$2 == null ? colours.secondaryLight : colours.tertiaryInfo,
                                            size: textLG,
                                          ),
                                          label: Padding(
                                            padding: EdgeInsets.only(left: spaceXS),
                                            child: Text(
                                              t.openFileExplorer.toUpperCase(),
                                              style: TextStyle(
                                                color: uiSettingsManager.gitDirPath?.$2 == null ? colours.secondaryLight : colours.tertiaryInfo,
                                                fontSize: textMD,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      FutureBuilder(
                                        future: uiSettingsManager.getStringList(StorageKey.setman_lfsFilePaths),
                                        builder: (context, lfsFilePathsSnapshot) => lfsFilePathsSnapshot.data?.isEmpty ?? true
                                            ? SizedBox.shrink()
                                            : Column(
                                                children: [
                                                  SizedBox(height: spaceMD),
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: colours.secondaryDark,
                                                      borderRadius: BorderRadius.all(cornerRadiusMD),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        SizedBox(
                                                          width: double.infinity,
                                                          child: TextButton.icon(
                                                            onPressed: () async {
                                                              gitLfsExpanded = !gitLfsExpanded;
                                                              if (mounted) setState(() {});
                                                              await runGitOperation(
                                                                LogType.GetAndExcludeLfs,
                                                                (event) => event?["result"].map<String>((path) => "$path").toList(),
                                                                null,
                                                              );
                                                              if (mounted) setState(() {});
                                                            },
                                                            iconAlignment: IconAlignment.end,
                                                            style: ButtonStyle(
                                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                              padding: WidgetStatePropertyAll(
                                                                EdgeInsets.symmetric(horizontal: spaceLG, vertical: spaceMD),
                                                              ),
                                                              shape: WidgetStatePropertyAll(
                                                                RoundedRectangleBorder(
                                                                  borderRadius: BorderRadius.all(cornerRadiusMD),
                                                                  side: BorderSide.none,
                                                                ),
                                                              ),
                                                            ),
                                                            icon: FaIcon(
                                                              gitLfsExpanded ? FontAwesomeIcons.chevronUp : FontAwesomeIcons.chevronDown,
                                                              color: colours.primaryLight,
                                                              size: textXL,
                                                            ),
                                                            label: SizedBox(
                                                              width: double.infinity,
                                                              child: Row(
                                                                children: [
                                                                  AnimatedSize(
                                                                    duration: Duration(milliseconds: 200),
                                                                    child: Container(
                                                                      width: gitLfsExpanded ? null : 0,
                                                                      decoration: BoxDecoration(),
                                                                      clipBehavior: Clip.hardEdge,
                                                                      child: IconButton(
                                                                        padding: EdgeInsets.zero,
                                                                        style: ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                                                        constraints: BoxConstraints(),
                                                                        onPressed: () async {
                                                                          await InfoDialog.showDialog(
                                                                            context,
                                                                            "Large Files Management",
                                                                            "Large files over 100 MB cannot be synced because GitSync does not currently support Git Large File Storage (LFS). \n\nThese files have been automatically excluded from synchronization and added to the \".git/info/exclude\" file to prevent sync issues. If you need to manage these large files, you'll need to use Git LFS through the command line or update to a future version of the app that supports LFS functionality. You can modify the excluded files list in the repository settings if needed.",
                                                                          );
                                                                          // launchUrl(Uri.parse(autoSyncDocsLink));
                                                                        },
                                                                        icon: FaIcon(
                                                                          FontAwesomeIcons.circleQuestion,
                                                                          color: colours.primaryLight,
                                                                          size: textLG,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  SizedBox(width: gitLfsExpanded ? spaceSM : 0),
                                                                  Text(
                                                                    sprintf(
                                                                      clientModeEnabledSnapshot.data == true ? "%sLFS Files" : "%sUnsynced Files",
                                                                      [
                                                                        (lfsFilePathsSnapshot.data?.length ?? 0) == 0
                                                                            ? ""
                                                                            : "(${lfsFilePathsSnapshot.data?.length}) ",
                                                                      ],
                                                                    ).toUpperCase(),
                                                                    style: TextStyle(
                                                                      color: colours.tertiaryNegative,
                                                                      fontSize: textMD,
                                                                      fontWeight: FontWeight.bold,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        AnimatedSize(
                                                          duration: Duration(milliseconds: 200),
                                                          child: SizedBox(
                                                            height: gitLfsExpanded ? null : 0,
                                                            child: gitLfsExpanded
                                                                ? Container(
                                                                    padding: EdgeInsets.only(left: spaceSM, right: spaceSM, bottom: spaceSM),
                                                                    height: spaceXL * 4,
                                                                    child: ShaderMask(
                                                                      shaderCallback: (Rect rect) {
                                                                        return LinearGradient(
                                                                          begin: Alignment.topCenter,
                                                                          end: Alignment.bottomCenter,
                                                                          colors: [
                                                                            Colors.transparent,
                                                                            Colors.transparent,
                                                                            Colors.transparent,
                                                                            Colors.black,
                                                                          ],
                                                                          stops: [0.0, 0.1, 0.9, 1.0],
                                                                        ).createShader(rect);
                                                                      },
                                                                      blendMode: BlendMode.dstOut,
                                                                      child: GridView.builder(
                                                                        shrinkWrap: true,
                                                                        itemCount: lfsFilePathsSnapshot.data?.length,
                                                                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                                          crossAxisCount: 4,
                                                                          crossAxisSpacing: spaceSM,
                                                                          mainAxisSpacing: spaceSM,
                                                                        ),
                                                                        itemBuilder: (BuildContext context, int index) {
                                                                          final filePath = (lfsFilePathsSnapshot.data ?? [])[index];

                                                                          return Container(
                                                                            child: Column(
                                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                                              children: [
                                                                                Stack(
                                                                                  clipBehavior: Clip.none,
                                                                                  children: [
                                                                                    FaIcon(
                                                                                      FontAwesomeIcons.solidFile,
                                                                                      color: colours.primaryLight,
                                                                                      size: textXL,
                                                                                    ),
                                                                                    Positioned(
                                                                                      bottom: -spaceXS,
                                                                                      left: -spaceXS,
                                                                                      child: Text(
                                                                                        "${formatBytes(File(filePath).statSync().size, 0)}",
                                                                                        maxLines: 1,
                                                                                        style: TextStyle(
                                                                                          fontSize: textXS,

                                                                                          shadows: [
                                                                                            Shadow(
                                                                                              offset: Offset(-1, -1),
                                                                                              color: colours.tertiaryDark,
                                                                                            ),
                                                                                            Shadow(
                                                                                              offset: Offset(1, -1),
                                                                                              color: colours.tertiaryDark,
                                                                                            ),
                                                                                            Shadow(offset: Offset(1, 1), color: colours.tertiaryDark),
                                                                                            Shadow(
                                                                                              offset: Offset(-1, 1),
                                                                                              color: colours.tertiaryDark,
                                                                                            ),
                                                                                          ],
                                                                                          color: colours.primaryLight,
                                                                                          overflow: TextOverflow.ellipsis,
                                                                                          fontWeight: FontWeight.bold,
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                                SizedBox(height: spaceXS),
                                                                                Text(
                                                                                  p.basename(filePath),
                                                                                  maxLines: 1,
                                                                                  style: TextStyle(
                                                                                    fontSize: textSM,
                                                                                    color: colours.primaryLight,
                                                                                    overflow: TextOverflow.ellipsis,
                                                                                    fontWeight: FontWeight.bold,
                                                                                  ),
                                                                                ),
                                                                                SizedBox(height: spaceXXXXS),
                                                                                Text(
                                                                                  "${File(filePath).statSync().modified}".substring(0, 10),
                                                                                  maxLines: 1,
                                                                                  style: TextStyle(
                                                                                    fontSize: textXS,
                                                                                    color: colours.primaryLight,
                                                                                    overflow: TextOverflow.ellipsis,
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          );
                                                                        },
                                                                      ),
                                                                    ),
                                                                  )
                                                                : SizedBox.shrink(),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: spaceLG),
                                ...clientModeEnabledSnapshot.data == true
                                    ? [
                                        IntrinsicHeight(
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              Expanded(
                                                child: TextButton.icon(
                                                  onPressed: () async {
                                                    _restorableSettingsMain.present({"recentCommits": recentCommits});
                                                  },
                                                  iconAlignment: IconAlignment.end,
                                                  style: ButtonStyle(
                                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceLG, vertical: spaceMD)),
                                                    shape: WidgetStatePropertyAll(
                                                      RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.only(
                                                          topLeft: cornerRadiusMD,
                                                          topRight: cornerRadiusSM,
                                                          bottomLeft: cornerRadiusMD,
                                                          bottomRight: cornerRadiusSM,
                                                        ),
                                                        side: BorderSide.none,
                                                      ),
                                                    ),
                                                    backgroundColor: WidgetStatePropertyAll(colours.secondaryDark),
                                                  ),
                                                  icon: IconButton(
                                                    padding: EdgeInsets.zero,
                                                    style: ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                                    constraints: BoxConstraints(),
                                                    onPressed: () async {
                                                      launchUrl(Uri.parse(repositorySettingsDocsLink));
                                                    },
                                                    icon: FaIcon(FontAwesomeIcons.circleQuestion, color: colours.primaryLight, size: textLG),
                                                  ),
                                                  label: Row(
                                                    children: [
                                                      FaIcon(FontAwesomeIcons.gear, color: colours.primaryLight, size: textLG),
                                                      SizedBox(width: spaceSM),
                                                      Expanded(
                                                        child: Text(
                                                          t.repositorySettings,
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(
                                                            fontFeatures: [FontFeature.enable('smcp')],
                                                            color: colours.primaryLight,
                                                            fontSize: textLG,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: spaceSM),
                                              FutureBuilder(
                                                future: uiSettingsManager.getBool(StorageKey.setman_syncMessageEnabled),
                                                builder: (context, snapshot) => IconButton(
                                                  onPressed: () async {
                                                    if (!(snapshot.data ?? false)) {
                                                      if (!(await Permission.notification.request().isGranted)) return;
                                                    }

                                                    uiSettingsManager.setBool(StorageKey.setman_syncMessageEnabled, !(snapshot.data ?? false));
                                                    await reloadAll();
                                                  },
                                                  style: ButtonStyle(
                                                    backgroundColor: WidgetStatePropertyAll(colours.secondaryDark),
                                                    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceMD)),
                                                    shape: WidgetStatePropertyAll(
                                                      RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.only(
                                                          topLeft: cornerRadiusSM,
                                                          topRight: cornerRadiusMD,
                                                          bottomLeft: cornerRadiusSM,
                                                          bottomRight: cornerRadiusMD,
                                                        ),
                                                        side: BorderSide.none,
                                                      ),
                                                    ),
                                                  ),
                                                  icon: Stack(
                                                    alignment: Alignment.center,
                                                    children: [
                                                      FaIcon(FontAwesomeIcons.solidBellSlash, color: Colors.transparent, size: textLG - 2),
                                                      FaIcon(
                                                        demo || snapshot.data == true ? FontAwesomeIcons.solidBell : FontAwesomeIcons.solidBellSlash,
                                                        color: demo || snapshot.data == true ? colours.primaryPositive : colours.primaryLight,
                                                        size: textLG - 2,
                                                        semanticLabel: t.syncMessagesLabel,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: spaceMD),
                                      ]
                                    : [],
                                ...clientModeEnabledSnapshot.data == true
                                    ? [
                                        TextButton.icon(
                                          onPressed: () async {
                                            Navigator.of(context).push(createSyncSettingsMainRoute()).then((_) => reloadAll());
                                          },
                                          iconAlignment: IconAlignment.end,
                                          style: ButtonStyle(
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceLG, vertical: spaceMD)),
                                            shape: WidgetStatePropertyAll(
                                              RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
                                            ),
                                            backgroundColor: WidgetStatePropertyAll(colours.secondaryDark),
                                          ),
                                          icon: IconButton(
                                            padding: EdgeInsets.zero,
                                            style: ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                            constraints: BoxConstraints(),
                                            onPressed: () async {
                                              launchUrl(Uri.parse(syncOptionsDocsLink));
                                            },
                                            icon: FaIcon(FontAwesomeIcons.circleQuestion, color: colours.primaryLight, size: textLG),
                                          ),
                                          label: Row(
                                            children: [
                                              FaIcon(FontAwesomeIcons.rightLeft, color: colours.primaryLight, size: textLG),
                                              SizedBox(width: spaceSM),
                                              Expanded(
                                                child: Text(
                                                  t.syncSettings,
                                                  style: TextStyle(
                                                    fontFeatures: [FontFeature.enable('smcp')],
                                                    color: colours.primaryLight,
                                                    fontSize: textLG,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: spaceMD),
                                      ]
                                    : [
                                        CustomShowcase(
                                          globalKey: _autoSyncOptionsKey,
                                          description: t.autoSyncOptionsHint,
                                          cornerRadius: cornerRadiusMD,
                                          targetPadding: EdgeInsets.all(spaceSM),
                                          customTooltipActions: [
                                            TooltipActionButton(
                                              backgroundColor: colours.secondaryInfo,
                                              textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: textSM, color: colours.primaryLight),
                                              leadIcon: ActionButtonIcon(
                                                icon: Icon(FontAwesomeIcons.solidFileLines, color: colours.primaryLight, size: textSM),
                                              ),
                                              name: t.learnMore.toUpperCase(),
                                              onTap: () => launchUrl(Uri.parse(syncOptionsBGDocsLink)),
                                              type: null,
                                            ),
                                          ],
                                          child: GroupSyncSettings(),
                                        ),
                                      ],
                                SizedBox(height: spaceMD),
                              ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: FutureBuilder(
            future: hasNetworkConnection(),
            builder: (context, snapshot) => snapshot.data == false
                ? Container(
                    decoration: BoxDecoration(color: colours.tertiaryNegative),
                    padding: EdgeInsets.symmetric(vertical: spaceXXS, horizontal: spaceSM),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: t.youreOffline,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: " "),
                          TextSpan(text: t.someFeaturesMayNotWork),
                        ],
                      ),
                    ),
                  )
                : SizedBox.shrink(),
          ),
        ),
        Positioned.fill(
          child: ValueListenableBuilder(
            valueListenable: fsLoader,
            builder: (context, snapshot, child) => !snapshot
                ? SizedBox.shrink()
                : AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    color: colours.primaryDark.withAlpha(150),
                    height: double.infinity,
                    width: double.infinity,
                    child: Center(
                      child: SizedBox(
                        height: spaceXXL,
                        width: spaceXXL,
                        child: CircularProgressIndicator(color: colours.tertiaryLight, strokeWidth: spaceXS),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
