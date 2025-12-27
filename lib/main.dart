import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:GitSync/api/manager/auth/github_app_manager.dart';
import 'package:GitSync/api/manager/auth/github_manager.dart';
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
import 'package:animated_reorderable_list/animated_reorderable_list.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
import '../constant/colors.dart';
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
    e("${LogType.Global.name}: ${"${details.stack.toString()}\nError: ${details.exception.toString()}"}");
  };

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      initAsync(() async {
        await gitSyncService.initialise(onServiceStart, callbackDispatcher);
        await uiSettingsManager.reinit();
        await Logger.init();
        await requestStoragePerm(false);
      });
      initLogger("${(await getTemporaryDirectory()).path}/logs", maxFileCount: 50, maxFileLength: 1 * 1024 * 1024);
      await RustLib.init();
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
  @override
  void initState() {
    HomeWidget.setAppGroupId('group.ForceSyncWidget');
    HomeWidget.registerInteractivityCallback(backgroundCallback);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: repoManager.getStringNullable(StorageKey.repoman_appLocale),
      builder: (context, appLocaleSnapshot) => MaterialApp(
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
          colorScheme: ColorScheme.fromSeed(seedColor: primaryDark),
          useMaterial3: true,
          textSelectionTheme: TextSelectionThemeData(
            selectionHandleColor: tertiaryInfo,
            selectionColor: secondaryInfo.withAlpha(100),
            cursorColor: secondaryInfo.withAlpha(150),
          ),
        ),
        builder: (context, child) {
          return child == null
              ? SizedBox.shrink()
              : Container(
                  color: primaryDark,
                  child: SafeArea(
                    top: false,
                    child: Padding(padding: EdgeInsets.zero, child: child),
                  ),
                );
        },
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
            return MyHomePage(title: appName, setState: setState);
          },
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.setState});

  final String title;
  final void Function(VoidCallback) setState;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  bool repoSettingsExpanded = false;
  bool gitLfsExpanded = false;
  bool demoConflicting = false;

  Timer? autoRefreshTimer;
  StreamSubscription<List<ConnectivityResult>>? networkSubscription;
  ScrollController recentCommitsController = ScrollController();

  final syncMethodsDropdownKey = GlobalKey();
  final syncMethodMainButtonKey = GlobalKey();
  final _globalSettingsKey = GlobalKey();
  final _syncProgressKey = GlobalKey();
  final _addMoreKey = GlobalKey();
  final _controlKey = GlobalKey();
  final _configKey = GlobalKey();
  final _autoSyncOptionsKey = GlobalKey();

  static final List<((String, Widget), Future<void> Function(BuildContext context, (String, String)? remote))> remoteActions = [
    (
      (t.launchInBrowser, FaIcon(FontAwesomeIcons.squareArrowUpRight, color: primaryPositive, size: textMD)),
      (BuildContext context, (String, String)? remote) async => remote == null ? null : await launchUrl(Uri.parse(remote.$2)),
    ),
    (
      (t.modifyRemoteUrl, FaIcon(FontAwesomeIcons.squarePen, color: tertiaryInfo, size: textMD)),
      (BuildContext context, (String, String)? remote) async {
        await SetRemoteUrlDialog.showDialog(context, remote?.$1, (newRemoteUrl) async => await GitManager.setRemoteUrl(newRemoteUrl));
      },
    ),
  ];

  @override
  void initState() {
    AccessibilityServiceHelper.init(context, setState);
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
        setState(() {});
        await ManualSyncDialog.showDialog(context, () async {});
        return;
      }
    });

    quickActions.setShortcutItems(<ShortcutItem>[
      ShortcutItem(type: GitsyncService.FORCE_SYNC, localizedTitle: t.syncNow, icon: "sync_now"),
      ShortcutItem(type: GitsyncService.MANUAL_SYNC, localizedTitle: t.manualSync, icon: "manual_sync"),
    ]);

    initAsync(() async {
      await GitManager.getAndExcludeLfsFilePaths();
    });

    initAsync(() async {
      if (premiumManager.hasPremiumNotifier.value == false) {
        await premiumManager.cullNonPremium();
        setState(() {});
      }
    });

    premiumManager.hasPremiumNotifier.addListener(() async {
      if (premiumManager.hasPremiumNotifier.value == false) {
        await premiumManager.cullNonPremium();
      }
      setState(() {});
    });

    FlutterBackgroundService().on(GitsyncService.MERGE_COMPLETE).listen((event) async {
      Navigator.of(context).canPop() ? Navigator.pop(context) : null;
      setState(() {});
    });

    networkSubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) => setState(() {}));

    initAsync(() async {
      // TODO: Commented for release
      // await repoManager.setInt(StorageKey.repoman_onboardingStep, 0);

      await promptClearKeychainValues();

      if (await repoManager.hasLegacySettings()) {
        if (!mounted) return;
        await LegacyAppUserDialog.showDialog(context, () async {
          await onboardingController?.show();
          setState(() {});
        });
        return;
      }
      final step = await repoManager.getInt(StorageKey.repoman_onboardingStep);
      if (step != -1) {
        await onboardingController?.show();
        setState(() {});
      }

      await updateRecommendedAction();
      autoRefreshTimer = Timer.periodic(Duration(seconds: 5), (_) async => await updateRecommendedAction());
    });

    super.initState();
  }

  Future<void> launchWidgetManualSync() async {
    final widgetManualSyncIndex = await repoManager.getInt(StorageKey.repoman_widgetManualSyncIndex);
    await repoManager.setInt(StorageKey.repoman_repoIndex, widgetManualSyncIndex);
    await uiSettingsManager.reinit();
    setState(() {});
    await ManualSyncDialog.showDialog(context, () async {});
  }

  Future<void> updateRecommendedAction([int? override]) async {
    if (!await uiSettingsManager.getClientModeEnabled()) return;

    updatingRecommendedAction.value = true;
    recommendedAction.value = override ?? await GitManager.getRecommendedAction();
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
    await Navigator.of(context).push(createGlobalSettingsMainRoute(onboarding: true)).then((_) => setState(() {}));
    await repoManager.setOnboardingStep(-1);
    await uiSettingsManager.setBoolNullable(StorageKey.setman_clientModeEnabled, initialClientModeEnabled);
    setState(() {});
  }

  Future<void> addRepo() async {
    repoSettingsExpanded = false;
    setState(() {});

    AddContainerDialog.showDialog(context, (text) async {
      List<String> repomanReponames = List.from(await repoManager.getStringList(StorageKey.repoman_repoNames));

      if (repomanReponames.contains(text)) {
        text = "${text}_alt";
      }

      repomanReponames = [...repomanReponames, text];

      await repoManager.setStringList(StorageKey.repoman_repoNames, repomanReponames);
      await repoManager.setInt(StorageKey.repoman_repoIndex, repomanReponames.indexOf(text));
      await uiSettingsManager.reinit();

      setState(() {});
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

  Future<Map<String, (IconData, Future<void> Function())>> getSyncOptions() async {
    final repomanRepoindex = await repoManager.getInt(StorageKey.repoman_repoIndex);
    final clientModeEnabled = await uiSettingsManager.getClientModeEnabled();
    final dirPath = await uiSettingsManager.getGitDirPath();
    final submodulePaths = dirPath == null ? [] : await GitManager.getSubmodulePaths(dirPath);
    Map<String, (IconData, Future<void> Function())> syncOptions = {};

    if ((await GitManager.getConflicting()).isEmpty) {
      syncOptions.addAll({
        clientModeEnabled ? t.syncAllChanges : t.syncNow: (
          FontAwesomeIcons.solidCircleDown,
          () async {
            if (await GitManager.getBranchName() == null) {
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
                      textColor: primaryDark,
                      iconColor: primaryDark,
                      buttonColor: tertiaryNegative,
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
            FontAwesomeIcons.listCheck,
            () async {
              await ManualSyncDialog.showDialog(context, () async => await updateRecommendedAction(3));
            },
          ),
        if (dirPath != null && clientModeEnabled && submodulePaths.isNotEmpty)
          t.updateSubmodules: (
            FontAwesomeIcons.solidSquareCaretDown,
            () async {
              await GitManager.updateSubmodules();
            },
          ),
        if (clientModeEnabled)
          sprintf(t.fetchRemote, [await uiSettingsManager.getRemote()]): (
            FontAwesomeIcons.caretDown,
            () async {
              await GitManager.fetchRemote();
              await updateRecommendedAction(1);
            },
          ),
        if (!clientModeEnabled)
          t.downloadChanges: (
            FontAwesomeIcons.angleDown,
            () async {
              final result = await GitManager.downloadChanges(repomanRepoindex, uiSettingsManager, () async {
                if (await uiSettingsManager.getBool(StorageKey.setman_syncMessageEnabled)) {
                  Fluttertoast.showToast(msg: t.syncStartPull, toastLength: Toast.LENGTH_LONG, gravity: null);
                }
              });
              if (result == null) return;

              if (result == false && (await GitManager.getUncommittedFilePaths(repomanRepoindex)).isNotEmpty) {
                Fluttertoast.showToast(msg: t.pullFailed, toastLength: Toast.LENGTH_LONG, gravity: null);
                return;
              }

              if (await uiSettingsManager.getBool(StorageKey.setman_syncMessageEnabled)) {
                Fluttertoast.showToast(msg: t.syncComplete, toastLength: Toast.LENGTH_LONG, gravity: null);
              }
            },
          ),
        if (clientModeEnabled)
          t.pullChanges: (
            FontAwesomeIcons.angleDown,
            () async {
              await GitManager.pullChanges();
            },
          ),
        if (clientModeEnabled)
          t.stageAndCommit: (
            FontAwesomeIcons.listCheck,
            () async {
              await ManualSyncDialog.showDialog(context, () async => await updateRecommendedAction(3));
            },
          ),
        if (!clientModeEnabled)
          t.uploadChanges: (
            FontAwesomeIcons.angleUp,
            () async {
              final result = await GitManager.uploadChanges(repomanRepoindex, uiSettingsManager, () async {
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
            },
          ),
        if (clientModeEnabled)
          t.pushChanges: (
            FontAwesomeIcons.angleUp,
            () async {
              await GitManager.pushChanges();
            },
          ),
      });
    }

    syncOptions.addAll({
      if (!clientModeEnabled)
        t.uploadAndOverwrite: (
          FontAwesomeIcons.anglesUp,
          () async {
            ConfirmForcePushPullDialog.showDialog(context, push: true, () async {
              ForcePushPullDialog.showDialog(context, push: true);
              await GitManager.uploadAndOverwrite();
              await GitManager.downloadAndOverwrite();
              Navigator.of(context).canPop() ? Navigator.pop(context) : null;
              setState(() {});
            });
          },
        ),
      if (!clientModeEnabled)
        t.downloadAndOverwrite: (
          FontAwesomeIcons.anglesDown,
          () async {
            ConfirmForcePushPullDialog.showDialog(context, () async {
              ForcePushPullDialog.showDialog(context);
              await GitManager.downloadAndOverwrite();
              Navigator.of(context).canPop() ? Navigator.pop(context) : null;
              setState(() {});
            });
          },
        ),
      if (clientModeEnabled)
        t.forcePush: (
          FontAwesomeIcons.anglesUp,
          () async {
            ConfirmForcePushPullDialog.showDialog(context, push: true, () async {
              ForcePushPullDialog.showDialog(context, push: true);
              await GitManager.forcePush();
              Navigator.of(context).canPop() ? Navigator.pop(context) : null;
              setState(() {});
            });
          },
        ),
      if (clientModeEnabled)
        t.forcePull: (
          FontAwesomeIcons.anglesDown,
          () async {
            ConfirmForcePushPullDialog.showDialog(context, () async {
              ForcePushPullDialog.showDialog(context);
              await GitManager.forcePull();
              Navigator.of(context).canPop() ? Navigator.pop(context) : null;
              setState(() {});
            });
          },
        ),
      clientModeEnabled ? t.switchToSyncMode : t.switchToClientMode: (
        FontAwesomeIcons.rightLeft,
        () async {
          await uiSettingsManager.setBoolNullable(StorageKey.setman_clientModeEnabled, !clientModeEnabled);
          setState(() {});
        },
      ),
    });

    return syncOptions;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

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
      setState(() {});
    }
    if (state == AppLifecycleState.paused) {
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
      setState(() {});
      if ((await uiSettingsManager.getAuthorEmail()).isEmpty || (await uiSettingsManager.getAuthorName()).isEmpty) {
        await AuthorDetailsPromptDialog.showDialog(
          context,
          () async {
            await Navigator.of(context).push(createSettingsMainRoute(showcaseAuthorDetails: true)).then((_) => setState(() {}));
          },
          () async {
            if (await repoManager.getInt(StorageKey.repoman_onboardingStep) == -1) {
              await showCloneRepoPage();
            } else {
              await onboardingController?.show();
              setState(() {});
            }
          },
        );
        return;
      }
      if (await repoManager.getInt(StorageKey.repoman_onboardingStep) == -1) {
        await showCloneRepoPage();
      } else {
        await onboardingController?.show();
        setState(() {});
      }
    });
  }

  Future<void> showCloneRepoPage() async {
    Navigator.of(context).push(createCloneRepoMainRoute()).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    initAsync(() async {
      if (Logger.notifClicked == true) {
        Logger.notifClicked = false;
        Logger.dismissError(context);
      }
    });

    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        actionsPadding: EdgeInsets.only(bottom: spaceXXS),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: primaryDark,
          systemNavigationBarColor: primaryDark,
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
                await Navigator.of(context).push(createGlobalSettingsMainRoute()).then((_) => setState(() {}));
                widget.setState(() {});
              },
              icon: FaIcon(FontAwesomeIcons.gear, color: tertiaryDark, size: spaceMD + 7),
            ),
          ),
          SizedBox(width: spaceSM),
          SyncLoader(syncProgressKey: _syncProgressKey, reload: () => widget.setState(() {})),
          SizedBox(width: spaceSM),
          CustomShowcase(
            globalKey: _addMoreKey,
            description: t.addMoreHint,
            cornerRadius: cornerRadiusMax,
            customTooltipActions: [
              TooltipActionButton(
                backgroundColor: secondaryInfo,
                textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: textSM, color: primaryLight),
                leadIcon: ActionButtonIcon(
                  icon: Icon(FontAwesomeIcons.solidFileLines, color: primaryLight, size: textSM),
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
                decoration: BoxDecoration(color: tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusMax)),
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
                                  await UnlockPremiumDialog.showDialog(context, () {
                                    setState(() {});
                                    addRepo();
                                  });
                                  setState(() {});
                                  return;
                                }

                                if (repoNamesSnapshot.data!.length == 1 || repoSettingsExpanded) {
                                  addRepo();
                                  return;
                                }

                                repoSettingsExpanded = !repoSettingsExpanded;
                                setState(() {});

                                if (repoSettingsExpanded) {
                                  Future.delayed(
                                    Duration(seconds: 5),
                                    () => setState(() {
                                      repoSettingsExpanded = false;
                                    }),
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
                                      color: repoNamesSnapshot.data!.length == 1 || repoSettingsExpanded ? tertiaryPositive : secondaryLight,
                                      size: textLG,
                                    ),
                                  ),
                                  repoNamesSnapshot.data!.length != 1
                                      ? SizedBox.shrink()
                                      : Padding(
                                          padding: EdgeInsets.only(left: spaceSM),
                                          child: Text(
                                            t.addMore.toUpperCase(),
                                            style: TextStyle(color: primaryLight, fontSize: textSM, fontWeight: FontWeight.w900),
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
                                        onPressed: () {
                                          repoSettingsExpanded = false;
                                          setState(() {});

                                          RemoveContainerDialog.showDialog(context, (deleteContents) async {
                                            if (deleteContents) {
                                              await GitManager.deleteDirContents();
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
                                            setState(() {});
                                          });
                                        },
                                        icon: FaIcon(FontAwesomeIcons.solidSquareMinus, color: tertiaryNegative, size: textLG),
                                      ),
                                      IconButton(
                                        style: ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                        constraints: BoxConstraints(),
                                        onPressed: () {
                                          repoSettingsExpanded = false;
                                          setState(() {});

                                          if (repoNamesSnapshot.data == null || repoIndexSnapshot.data == null) return;

                                          RenameContainerDialog.showDialog(context, repoNamesSnapshot.data![repoIndexSnapshot.data!].toLowerCase(), (
                                            text,
                                          ) async {
                                            if (text.isEmpty) return;

                                            final repomanReponames = await repoManager.getStringList(StorageKey.repoman_repoNames);
                                            uiSettingsManager.renameNamespace(text);
                                            repomanReponames[await repoManager.getInt(StorageKey.repoman_repoIndex)] = text;

                                            await repoManager.setStringList(StorageKey.repoman_repoNames, repomanReponames);
                                            setState(() {});
                                          });
                                        },
                                        icon: FaIcon(FontAwesomeIcons.squarePen, color: tertiaryInfo, size: textLG),
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
                                        child: FaIcon(FontAwesomeIcons.caretDown, color: secondaryLight, size: textSM),
                                      ),
                                      value: repoIndexSnapshot.data ?? 0,
                                      style: const TextStyle(color: tertiaryLight, fontWeight: FontWeight.w900, fontSize: textMD),
                                      isDense: true,
                                      underline: const SizedBox.shrink(),
                                      dropdownColor: secondaryDark,
                                      onChanged: (value) async {
                                        if (value == null) return;
                                        await repoManager.setInt(StorageKey.repoman_repoIndex, value);
                                        await uiSettingsManager.reinit();
                                        setState(() {});
                                      },
                                      selectedItemBuilder: (context) => List.generate(
                                        repoNamesSnapshot.data!.length,
                                        (index) => ConstrainedBox(
                                          constraints: BoxConstraints(maxWidth: spaceXXL + spaceLG),
                                          child: Text(
                                            repoNamesSnapshot.data![index].toUpperCase(),
                                            style: TextStyle(fontSize: textXS, color: primaryLight),
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
                                            style: TextStyle(fontSize: textXS, color: primaryLight),
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
            style: TextStyle(color: primaryLight, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: OrientationBuilder(
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
                      child: FutureBuilder(
                        future: GitManager.getRecentCommits(),
                        builder: (context, recentCommitsSnapshot) => FutureBuilder(
                          future: GitManager.getInitialRecentCommits(),
                          builder: (context, fastRecentCommitsSnapshot) => FutureBuilder(
                            future: GitManager.getConflicting(),
                            builder: (context, conflictingSnapshot) {
                              final recentCommits = fastRecentCommitsSnapshot.data;
                              final items = [
                                ...((conflictingSnapshot.data == null || conflictingSnapshot.data!.isEmpty)
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
                                ...recentCommits ?? <GitManagerRs.Commit>[],
                              ];

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
                                        color: secondaryDark,
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
                                                          ((recentCommits ?? []).isEmpty &&
                                                                  fastRecentCommitsSnapshot.connectionState == ConnectionState.waiting) ||
                                                              conflictingSnapshot.data == null
                                                          ? Center(child: CircularProgressIndicator(color: tertiaryLight))
                                                          : (recentCommits!.isEmpty && conflictingSnapshot.data!.isEmpty
                                                                ? Center(
                                                                    child: Text(
                                                                      t.commitsNotFound.toUpperCase(),
                                                                      style: TextStyle(
                                                                        color: secondaryLight,
                                                                        fontWeight: FontWeight.bold,
                                                                        fontSize: textLG,
                                                                      ),
                                                                    ),
                                                                  )
                                                                : Column(
                                                                    children: [
                                                                      Expanded(
                                                                        child: AnimatedListView(
                                                                          controller: recentCommitsController,
                                                                          items: items,
                                                                          reverse: true,
                                                                          isSameItem: (a, b) => a.reference == b.reference,
                                                                          itemBuilder: (BuildContext context, int index) {
                                                                            final reference = items[index].reference;

                                                                            if (reference == mergeConflictReference) {
                                                                              return ItemMergeConflict(
                                                                                key: Key(reference),
                                                                                conflictingSnapshot.data!,
                                                                                () => setState(() {}),
                                                                              );
                                                                            }

                                                                            return ItemCommit(
                                                                              key: Key(reference),
                                                                              items[index],
                                                                              index < items.length - 1 ? items[index + 1] : null,
                                                                            );
                                                                          },
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  )),
                                                    ),
                                                  ),
                                                ),
                                                ...(recentCommits?.isNotEmpty == true &&
                                                        recentCommitsSnapshot.connectionState == ConnectionState.waiting)
                                                    ? [
                                                        Positioned(
                                                          top: orientation == Orientation.portrait ? -(spaceXS / 2) : 0,
                                                          left: 0,
                                                          right: 0,
                                                          child: LinearProgressIndicator(
                                                            value: null,
                                                            backgroundColor: secondaryDark,
                                                            color: tertiaryDark,
                                                            borderRadius: BorderRadius.all(cornerRadiusMD),
                                                          ),
                                                        ),
                                                      ]
                                                    : [],
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: orientation == Orientation.portrait ? spaceXS : 0),

                                          FutureBuilder(
                                            future: GitManager.getBranchName(),
                                            builder: (context, branchNameSnapshot) => FutureBuilder(
                                              future: uiSettingsManager.getStringNullable(StorageKey.setman_branchName),
                                              builder: (context, fastBranchNameSnapshot) => FutureBuilder(
                                                future: GitManager.getBranchNames(),
                                                builder: (context, branchNamesSnapshot) => FutureBuilder(
                                                  future: uiSettingsManager.getStringList(StorageKey.setman_branchNames),
                                                  builder: (context, fastBranchNamesSnapshot) {
                                                    final branchName = fastBranchNameSnapshot.data ?? branchNameSnapshot.data;
                                                    final branchNames = fastBranchNamesSnapshot.data ?? branchNamesSnapshot.data;

                                                    return Row(
                                                      children: [
                                                        Expanded(
                                                          child: DropdownButton(
                                                            isDense: true,
                                                            isExpanded: true,
                                                            hint: Text(
                                                              t.detachedHead.toUpperCase(),
                                                              style: TextStyle(fontSize: textMD, fontWeight: FontWeight.bold, color: secondaryLight),
                                                            ),
                                                            padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceXS),
                                                            value: branchNames?.contains(branchName) == true ? branchName : null,
                                                            menuMaxHeight: 250,
                                                            dropdownColor: secondaryDark,
                                                            borderRadius: BorderRadius.all(cornerRadiusSM),
                                                            selectedItemBuilder: (context) => List.generate(
                                                              (branchNames ?? []).length,
                                                              (index) => Row(
                                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                                children: [
                                                                  Text(
                                                                    (branchNames ?? [])[index].toUpperCase(),
                                                                    style: TextStyle(
                                                                      fontSize: textMD,
                                                                      fontWeight: FontWeight.bold,
                                                                      color: !(conflictingSnapshot.data == null || conflictingSnapshot.data!.isEmpty)
                                                                          ? tertiaryLight
                                                                          : primaryLight,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            underline: const SizedBox.shrink(),
                                                            onChanged: !(conflictingSnapshot.data == null || conflictingSnapshot.data!.isEmpty)
                                                                ? null
                                                                : <String>(value) async {
                                                                    if (value == branchName) return;

                                                                    await ConfirmBranchCheckoutDialog.showDialog(context, value, () async {
                                                                      await GitManager.checkoutBranch(value);
                                                                    });
                                                                    setState(() {});
                                                                  },
                                                            items: (branchNames ?? [])
                                                                .map(
                                                                  (item) => DropdownMenuItem(
                                                                    value: item,
                                                                    child: Text(
                                                                      item.toUpperCase(),
                                                                      style: TextStyle(
                                                                        fontSize: textSM,
                                                                        color: primaryLight,
                                                                        fontWeight: FontWeight.bold,
                                                                        overflow: TextOverflow.ellipsis,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                )
                                                                .toList(),
                                                          ),
                                                        ),
                                                        IconButton(
                                                          onPressed: branchNames?.contains(branchName) == true
                                                              ? () {
                                                                  CreateBranchDialog.showDialog(context, (branchName, basedOn) async {
                                                                    await GitManager.createBranch(branchName, basedOn);
                                                                    setState(() {});
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
                                                            color: branchNames?.contains(branchName) == true ? primaryLight : secondaryLight,
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
                                  IntrinsicHeight(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          child: FutureBuilder(
                                            future: getSyncOptions(),
                                            builder: (context, syncOptionsSnapshot) => ValueListenableBuilder(
                                              valueListenable: recommendedAction,
                                              builder: (context, recommendedActionValue, _) => FutureBuilder(
                                                future: getLastSyncOption(),
                                                builder: (context, lastSyncMethodSnapshot) => Stack(
                                                  children: [
                                                    SizedBox.expand(
                                                      child: TextButton.icon(
                                                        key: syncMethodMainButtonKey,
                                                        onPressed: () async {
                                                          if (syncOptionsSnapshot.data == null || lastSyncMethodSnapshot.data == null) return;

                                                          WidgetsBinding.instance.addPostFrameCallback((_) async {
                                                            setState(() {});
                                                          });

                                                          await GitManager.getAndExcludeLfsFilePaths();

                                                          if (syncOptionsSnapshot.data?.containsKey(lastSyncMethodSnapshot.data) == true) {
                                                            await syncOptionsSnapshot.data![lastSyncMethodSnapshot.data]!.$2();
                                                          } else {
                                                            await syncOptionsSnapshot.data?.values.first.$2();
                                                          }
                                                          WidgetsBinding.instance.addPostFrameCallback((_) async {
                                                            setState(() {});
                                                          });
                                                          await updateRecommendedAction();
                                                        },
                                                        style: ButtonStyle(
                                                          alignment: Alignment.centerLeft,
                                                          backgroundColor: WidgetStatePropertyAll(secondaryDark),
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
                                                                      ? SizedBox(
                                                                          height: spaceXXL,
                                                                          width: spaceXXL,
                                                                          child: CircularProgressIndicator(color: tertiaryDark),
                                                                        )
                                                                      : SizedBox.shrink(),
                                                                ),
                                                              ),
                                                            FaIcon(
                                                              syncOptionsSnapshot.data?[lastSyncMethodSnapshot.data]?.$1 ??
                                                                  syncOptionsSnapshot.data?.values.first.$1 ??
                                                                  FontAwesomeIcons.solidCircleDown,
                                                              color: primaryLight,
                                                              size: textLG,
                                                            ),
                                                          ],
                                                        ),
                                                        label: Padding(
                                                          padding: EdgeInsets.only(left: spaceXS),
                                                          child: Text(
                                                            ((syncOptionsSnapshot.data?.containsKey(lastSyncMethodSnapshot.data) == true
                                                                        ? lastSyncMethodSnapshot.data
                                                                        : syncOptionsSnapshot.data?.keys.first) ??
                                                                    t.syncNow)
                                                                .toUpperCase(),
                                                            style: TextStyle(
                                                              color: clientModeEnabledSnapshot.data == true && recommendedActionValue != null
                                                                  ? tertiaryInfo
                                                                  : primaryLight,
                                                              fontSize: textMD,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Positioned(
                                                      left: 0,
                                                      right: 0,
                                                      top: spaceMD * 4,
                                                      child: Container(
                                                        decoration: BoxDecoration(borderRadius: BorderRadius.all(cornerRadiusSM)),
                                                        margin: EdgeInsets.only(left: spaceMD),
                                                        child: DropdownButton(
                                                          key: syncMethodsDropdownKey,
                                                          borderRadius: BorderRadius.all(cornerRadiusSM),
                                                          selectedItemBuilder: (context) =>
                                                              List.generate(syncOptionsSnapshot.data?.length ?? 0, (_) => SizedBox.shrink()),
                                                          icon: SizedBox.shrink(),
                                                          underline: const SizedBox.shrink(),
                                                          menuWidth: clientModeEnabledSnapshot.data == true
                                                              ? MediaQuery.of(context).size.width - (spaceMD * 2)
                                                              : null,
                                                          dropdownColor: secondaryDark,
                                                          padding: EdgeInsets.zero,
                                                          onChanged: (value) {},
                                                          items: (syncOptionsSnapshot.data ?? {}).entries
                                                              .where(
                                                                (item) =>
                                                                    item.key !=
                                                                    (syncOptionsSnapshot.data?.containsKey(lastSyncMethodSnapshot.data) == true
                                                                        ? lastSyncMethodSnapshot.data
                                                                        : syncOptionsSnapshot.data?.keys.first),
                                                              )
                                                              .map(
                                                                (item) => DropdownMenuItem(
                                                                  onTap: () async {
                                                                    if (![t.switchToClientMode, t.switchToSyncMode].contains(item.key)) {
                                                                      await uiSettingsManager.setString(StorageKey.setman_lastSyncMethod, item.key);
                                                                    }
                                                                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                                                                      setState(() {});
                                                                    });
                                                                    await item.value.$2();
                                                                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                                                                      setState(() {});
                                                                    });
                                                                    await updateRecommendedAction();
                                                                  },
                                                                  value: item.key,
                                                                  child: Row(
                                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                                    children: [
                                                                      FaIcon(
                                                                        item.value.$1,
                                                                        color: [t.switchToClientMode, t.switchToSyncMode].contains(item.key)
                                                                            ? tertiaryInfo
                                                                            : primaryLight,
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
                                                                                ? tertiaryInfo
                                                                                : primaryLight,
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
                                                    ),
                                                    Positioned(
                                                      right: 0,
                                                      top: 0,
                                                      bottom: 0,
                                                      child: IconButton(
                                                        onPressed: () {
                                                          if (demo) {
                                                            demoConflicting = true;
                                                            setState(() {});
                                                            MergeConflictDialog.showDialog(context, ["Readme.md"])
                                                                .then((_) {
                                                                  demoConflicting = false;
                                                                  setState(() {});
                                                                })
                                                                .then((_) => setState(() {}));

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
                                                          backgroundColor: WidgetStatePropertyAll(secondaryDark),
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
                                                          color: primaryLight,
                                                          size: textLG,
                                                          semanticLabel: t.moreSyncOptionsLabel,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        ...clientModeEnabledSnapshot.data != true
                                            ? [
                                                SizedBox(width: spaceSM),
                                                IconButton(
                                                  onPressed: () {
                                                    Navigator.of(context).push(createSettingsMainRoute()).then((_) => setState(() {}));
                                                  },
                                                  style: ButtonStyle(
                                                    backgroundColor: WidgetStatePropertyAll(secondaryDark),
                                                    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceMD)),
                                                    shape: WidgetStatePropertyAll(
                                                      RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM), side: BorderSide.none),
                                                    ),
                                                  ),
                                                  icon: FaIcon(
                                                    FontAwesomeIcons.gear,
                                                    color: primaryLight,
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

                                                      uiSettingsManager.setBool(StorageKey.setman_syncMessageEnabled, !(snapshot.data ?? false));
                                                      setState(() {});
                                                    },
                                                    style: ButtonStyle(
                                                      backgroundColor: WidgetStatePropertyAll(secondaryDark),
                                                      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceMD)),
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
                                                        FaIcon(FontAwesomeIcons.solidBellSlash, color: Colors.transparent, size: textLG - 2),
                                                        FaIcon(
                                                          demo || snapshot.data == true
                                                              ? FontAwesomeIcons.solidBell
                                                              : FontAwesomeIcons.solidBellSlash,
                                                          color: demo || snapshot.data == true ? primaryPositive : primaryLight,
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
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: spaceLG, width: spaceMD),

                  Expanded(
                    flex: orientation == Orientation.portrait ? 0 : 1,
                    child: FutureBuilder(
                      future: uiSettingsManager.getGitDirPath(true),
                      builder: (context, gitDirPathSnapshot) => FutureBuilder(
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
                                          FutureBuilder(
                                            future: GitManager.getRemoteUrlLink(),
                                            builder: (context, snapshot) => Expanded(
                                              child: Stack(
                                                children: [
                                                  Container(
                                                    padding: EdgeInsets.zero,
                                                    // padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceMD),
                                                    decoration: BoxDecoration(color: secondaryDark, borderRadius: BorderRadius.all(cornerRadiusMD)),

                                                    child: DropdownButton(
                                                      borderRadius: BorderRadius.all(cornerRadiusMD),
                                                      // padding: EdgeInsets.zero,
                                                      padding: EdgeInsets.only(left: spaceMD, right: spaceXXS, top: 1, bottom: 1),
                                                      onTap: () {
                                                        if (demo) {
                                                          ManualSyncDialog.showDialog(context, () async {}).then((_) => setState(() {}));
                                                          return;
                                                        }
                                                      },
                                                      //   // icon: FaIcon(
                                                      //   //   snapshot.data != null ? FontAwesomeIcons.caretDown : FontAwesomeIcons.solidCircleXmark,
                                                      //   //   color: snapshot.data != null ? primaryLight : primaryNegative,
                                                      //   //   size: textLG,
                                                      //   // ),
                                                      icon: Padding(
                                                        padding: EdgeInsets.symmetric(horizontal: spaceSM),
                                                        child: FaIcon(
                                                          snapshot.data != null ? FontAwesomeIcons.caretDown : FontAwesomeIcons.solidCircleXmark,
                                                          color: snapshot.data != null ? secondaryLight : primaryNegative,
                                                          size: textLG,
                                                        ),
                                                      ),
                                                      value: 0,
                                                      // style: const TextStyle(color: tertiaryLight, fontWeight: FontWeight.w900, fontSize: textMD),
                                                      // isDense: true,
                                                      isExpanded: true,
                                                      underline: const SizedBox.shrink(),
                                                      dropdownColor: secondaryDark,
                                                      onChanged: (value) async {
                                                        // await repoManager.setInt(StorageKey.repoman_repoIndex, value);
                                                        // await uiSettingsManager.reinit();
                                                        // setState(() {});
                                                      },

                                                      selectedItemBuilder: (context) => List.generate(
                                                        remoteActions.length,
                                                        (index) => Row(
                                                          children: [
                                                            Expanded(
                                                              child: ExtendedText(
                                                                demo
                                                                    ? "https://github.com/ViscousTests/TestObsidianVault.git"
                                                                    : (snapshot.data == null ? t.repoNotFound : snapshot.data!.$1),
                                                                maxLines: 1,
                                                                textAlign: TextAlign.left,
                                                                softWrap: false,
                                                                overflowWidget: TextOverflowWidget(
                                                                  position: TextOverflowPosition.start,
                                                                  child: Text(
                                                                    "…",
                                                                    style: TextStyle(
                                                                      color: tertiaryLight,
                                                                      fontSize: textMD,
                                                                      fontWeight: FontWeight.w400,
                                                                    ),
                                                                  ),
                                                                ),
                                                                style: TextStyle(
                                                                  color: snapshot.data != null ? primaryLight : secondaryLight,
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
                                                          // SetRemoteUrlDialog.showDialog(this.context, snapshot.data?.$1, (newRemoteUrl) async {
                                                          //   await GitManager.setRemoteUrl(newRemoteUrl);
                                                          //   setState(() {});
                                                          // }),
                                                          onTap: () async {
                                                            await remoteActions[index].$2(context, snapshot.data);
                                                            setState(() {});
                                                          },
                                                          child: Row(
                                                            children: [
                                                              remoteActions[index].$1.$2,
                                                              SizedBox(width: spaceSM),
                                                              Text(
                                                                remoteActions[index].$1.$1.toUpperCase(),
                                                                style: TextStyle(fontSize: textXS, color: primaryLight, fontWeight: FontWeight.bold),
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
                                                      style: TextStyle(color: tertiaryLight, fontSize: textXXS, fontWeight: FontWeight.w900),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: gitDirPathSnapshot.data == null ? spaceSM : 0),
                                          Visibility(
                                            visible: gitDirPathSnapshot.data == null,
                                            child: TextButton.icon(
                                              onPressed: isAuthenticatedSnapshot.data == true
                                                  ? () async {
                                                      await showCloneRepoPage();
                                                    }
                                                  : null,
                                              style: ButtonStyle(
                                                backgroundColor: WidgetStatePropertyAll(secondaryDark),
                                                padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceMD)),
                                                shape: WidgetStatePropertyAll(
                                                  RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
                                                ),
                                              ),
                                              icon: FaIcon(
                                                FontAwesomeIcons.cloudArrowDown,
                                                color: isAuthenticatedSnapshot.data == true ? primaryLight : tertiaryLight,
                                                size: textLG - 2,
                                              ),
                                              iconAlignment: IconAlignment.start,
                                              label: Padding(
                                                padding: EdgeInsets.only(left: spaceXS),
                                                child: Text(
                                                  t.clone.toUpperCase(),
                                                  style: TextStyle(color: primaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: spaceSM),
                                          Container(
                                            decoration: BoxDecoration(borderRadius: BorderRadius.all(cornerRadiusMD), color: secondaryDark),
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
                                                    color: isAuthenticatedSnapshot.data == true ? primaryPositive : primaryNegative,
                                                    size: textLG,
                                                  ),
                                                  label: Padding(
                                                    padding: EdgeInsets.only(left: spaceXS),
                                                    child: Text(
                                                      t.auth.toUpperCase(),
                                                      style: TextStyle(color: primaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
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
                                                            backgroundColor: WidgetStatePropertyAll(tertiaryDark),
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

                                                            final githubAppInstallations = await gitProviderManager.getGitHubAppInstallations(token);
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
                                                          icon: FaIcon(FontAwesomeIcons.sliders, size: textLG, color: secondaryLight),
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
                                                    color: secondaryDark,
                                                    borderRadius: BorderRadius.only(
                                                      bottomLeft: cornerRadiusMD,
                                                      bottomRight: cornerRadiusSM,
                                                      topLeft: cornerRadiusMD,
                                                      topRight: cornerRadiusSM,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    crossAxisAlignment: CrossAxisAlignment.center,
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
                                                                : (gitDirPathSnapshot.data == null
                                                                      ? t.repoNotFound
                                                                      : (Platform.isIOS
                                                                                ? gitDirPathSnapshot.data?.split("/").last
                                                                                : gitDirPathSnapshot.data) ??
                                                                            ""),
                                                            maxLines: 1,
                                                            textAlign: TextAlign.left,
                                                            softWrap: false,
                                                            overflowWidget: TextOverflowWidget(
                                                              position: TextOverflowPosition.start,
                                                              child: Text(
                                                                "…",
                                                                style: TextStyle(
                                                                  color: gitDirPathSnapshot.data == null ? secondaryLight : primaryLight,
                                                                  fontSize: textMD,
                                                                ),
                                                              ),
                                                            ),
                                                            style: TextStyle(
                                                              color: gitDirPathSnapshot.data == null ? secondaryLight : primaryLight,
                                                              fontSize: textMD,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      gitDirPathSnapshot.data == null
                                                          ? SizedBox.shrink()
                                                          : IconButton(
                                                              onPressed: () async {
                                                                await uiSettingsManager.setGitDirPath("");
                                                                setState(() {});
                                                              },
                                                              constraints: BoxConstraints(),
                                                              style: ButtonStyle(
                                                                backgroundColor: WidgetStatePropertyAll(secondaryDark),
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
                                                                color: primaryLight,
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
                                                    style: TextStyle(color: tertiaryLight, fontSize: textXXS, fontWeight: FontWeight.w900),
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

                                                    if (mounted) setState(() {});
                                                  }
                                                : null,
                                            style: ButtonStyle(
                                              backgroundColor: WidgetStatePropertyAll(secondaryDark),
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
                                              color: isAuthenticatedSnapshot.data == true ? primaryLight : tertiaryLight,
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
                                        onPressed: gitDirPathSnapshot.data == null
                                            ? null
                                            : () async {
                                                await useDirectory(
                                                  await uiSettingsManager.getString(StorageKey.setman_gitDirPath),
                                                  (bookmarkPath) async => await uiSettingsManager.setGitDirPath(bookmarkPath, true),
                                                  (path) async {
                                                    await Navigator.of(context).push(createFileExplorerRoute(path)).then((_) => setState(() {}));
                                                  },
                                                );
                                              },
                                        style: ButtonStyle(
                                          alignment: Alignment.center,
                                          backgroundColor: WidgetStatePropertyAll(secondaryDark),
                                          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceMD)),
                                          shape: WidgetStatePropertyAll(
                                            RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
                                          ),
                                        ),
                                        icon: FaIcon(
                                          FontAwesomeIcons.filePen,
                                          color: gitDirPathSnapshot.data == null ? secondaryLight : tertiaryInfo,
                                          size: textLG,
                                        ),
                                        label: Padding(
                                          padding: EdgeInsets.only(left: spaceXS),
                                          child: Text(
                                            t.openFileExplorer.toUpperCase(),
                                            style: TextStyle(
                                              color: gitDirPathSnapshot.data == null ? secondaryLight : tertiaryInfo,
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
                                                  decoration: BoxDecoration(color: secondaryDark, borderRadius: BorderRadius.all(cornerRadiusMD)),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      SizedBox(
                                                        width: double.infinity,
                                                        child: TextButton.icon(
                                                          onPressed: () async {
                                                            gitLfsExpanded = !gitLfsExpanded;
                                                            setState(() {});
                                                            await GitManager.getAndExcludeLfsFilePaths();
                                                            setState(() {});
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
                                                            color: primaryLight,
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
                                                                        color: primaryLight,
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
                                                                    color: tertiaryNegative,
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
                                                                                    color: primaryLight,
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
                                                                                          Shadow(offset: Offset(-1, -1), color: tertiaryDark),
                                                                                          Shadow(offset: Offset(1, -1), color: tertiaryDark),
                                                                                          Shadow(offset: Offset(1, 1), color: tertiaryDark),
                                                                                          Shadow(offset: Offset(-1, 1), color: tertiaryDark),
                                                                                        ],
                                                                                        color: primaryLight,
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
                                                                                  color: primaryLight,
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
                                                                                  color: primaryLight,
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
                                                  Navigator.of(context).push(createSettingsMainRoute()).then((_) => setState(() {}));
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
                                                  backgroundColor: WidgetStatePropertyAll(secondaryDark),
                                                ),
                                                icon: IconButton(
                                                  padding: EdgeInsets.zero,
                                                  style: ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                                  constraints: BoxConstraints(),
                                                  onPressed: () async {
                                                    launchUrl(Uri.parse(repositorySettingsDocsLink));
                                                  },
                                                  icon: FaIcon(FontAwesomeIcons.circleQuestion, color: primaryLight, size: textLG),
                                                ),
                                                label: Row(
                                                  children: [
                                                    FaIcon(FontAwesomeIcons.gear, color: primaryLight, size: textLG),
                                                    SizedBox(width: spaceSM),
                                                    Expanded(
                                                      child: Text(
                                                        t.repositorySettings,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          fontFeatures: [FontFeature.enable('smcp')],
                                                          color: primaryLight,
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
                                                  setState(() {});
                                                },
                                                style: ButtonStyle(
                                                  backgroundColor: WidgetStatePropertyAll(secondaryDark),
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
                                                      color: demo || snapshot.data == true ? primaryPositive : primaryLight,
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
                                          Navigator.of(context).push(createSyncSettingsMainRoute()).then((_) => setState(() {}));
                                        },
                                        iconAlignment: IconAlignment.end,
                                        style: ButtonStyle(
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceLG, vertical: spaceMD)),
                                          shape: WidgetStatePropertyAll(
                                            RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
                                          ),
                                          backgroundColor: WidgetStatePropertyAll(secondaryDark),
                                        ),
                                        icon: IconButton(
                                          padding: EdgeInsets.zero,
                                          style: ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                          constraints: BoxConstraints(),
                                          onPressed: () async {
                                            launchUrl(Uri.parse(syncOptionsDocsLink));
                                          },
                                          icon: FaIcon(FontAwesomeIcons.circleQuestion, color: primaryLight, size: textLG),
                                        ),
                                        label: Row(
                                          children: [
                                            FaIcon(FontAwesomeIcons.rightLeft, color: primaryLight, size: textLG),
                                            SizedBox(width: spaceSM),
                                            Expanded(
                                              child: Text(
                                                t.syncSettings,
                                                style: TextStyle(fontFeatures: [FontFeature.enable('smcp')], color: primaryLight, fontSize: textLG),
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
                                            backgroundColor: secondaryInfo,
                                            textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: textSM, color: primaryLight),
                                            leadIcon: ActionButtonIcon(
                                              icon: Icon(FontAwesomeIcons.solidFileLines, color: primaryLight, size: textSM),
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
                decoration: BoxDecoration(color: tertiaryNegative),
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
    );
  }
}
