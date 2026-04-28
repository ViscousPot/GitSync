import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:GitSync/api/manager/auth/github_app_manager.dart';
import 'package:GitSync/api/manager/settings_manager.dart';
import 'package:GitSync/ui/component/button_setting.dart';
import 'package:GitSync/ui/component/custom_showcase.dart';
import 'package:GitSync/ui/component/group_sync_settings.dart';
import 'package:GitSync/ui/component/branch_selector.dart';
import 'package:GitSync/ui/component/sync_loader.dart';
import 'package:GitSync/ui/dialog/base_alert_dialog.dart';
import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/ui/dialog/add_remote.dart' as AddRemoteDialog;
import 'package:GitSync/ui/dialog/confirm_delete_remote.dart' as ConfirmDeleteRemoteDialog;
import 'package:GitSync/ui/dialog/create_branch.dart' as CreateBranchDialog;
import 'package:GitSync/ui/dialog/info_dialog.dart' as InfoDialog;
import 'package:GitSync/ui/dialog/merge_conflict.dart' as MergeConflictDialog;
import 'package:GitSync/ui/dialog/rename_remote.dart' as RenameRemoteDialog;
import 'package:GitSync/ui/page/file_explorer.dart';
import 'package:GitSync/ui/page/ai_features_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:GitSync/providers/riverpod_providers.dart';
import 'package:GitSync/ui/component/provider_builder.dart';
import 'package:GitSync/ui/page/global_settings_main.dart';
import 'package:GitSync/ui/page/onboarding_setup.dart';
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
import 'package:home_widget/home_widget.dart';
import 'package:mixin_logger/mixin_logger.dart';
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
import '../ui/dialog/add_container.dart' as AddContainerDialog;
import '../ui/dialog/remove_container.dart' as RemoveContainerDialog;
import '../ui/dialog/rename_container.dart' as RenameContainerDialog;
import 'package:GitSync/ui/page/unlock_premium.dart';
import 'ui/dialog/confirm_force_push_pull.dart' as ConfirmForcePushPullDialog;
import '../ui/dialog/force_push_pull.dart' as ForcePushPullDialog;
import '../ui/dialog/manual_sync.dart' as ManualSyncDialog;
import '../constant/dimens.dart';
import '../global.dart';
import '../ui/component/commit_select_action_bar.dart';
import '../ui/component/item_commit.dart';
import '../ui/page/clone_repo_main.dart';
import 'package:GitSync/ui/page/expanded_commits.dart';
import 'package:GitSync/ui/page/issues_page.dart';
import 'package:GitSync/ui/page/pull_requests_page.dart';
import 'package:GitSync/type/showcase_feature.dart';
import 'package:GitSync/ui/component/showcase_feature_button.dart';
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
      DartPluginRegistrant.ensureInitialized();

      if (!RustLib.instance.initialized) await RustLib.init();
      await GitManager.clearLocks();
      initAsync(() async {
        await gitSyncService.initialise(onServiceStart, callbackDispatcher);
        if (await FlutterBackgroundService().isRunning()) {
          FlutterBackgroundService().invoke("clearLocks");
        }
        await Logger.init();
        await requestStoragePerm(false);
      });
      initLogger("${(await getTemporaryDirectory()).path}/logs", maxFileCount: 50, maxFileLength: 1 * 1024 * 1024);
      await uiSettingsManager.reinit();
      // Loads premiumManager initial state
      initAsync(() async => await premiumManager.init());
      runApp(const ProviderScope(child: MyApp()));
    },
    (error, stackTrace) {
      e(LogType.Global.name, error, stackTrace);
    },
  );
}

Future<int> _resolveRepoIndex(Uri? uri, StorageKey<int> fallbackKey) async {
  if (uri == null) return await repoManager.getInt(fallbackKey);

  final indexParam = uri.queryParameters['index'];
  if (indexParam != null) {
    return int.tryParse(indexParam) ?? await repoManager.getInt(fallbackKey);
  }

  return await repoManager.getInt(fallbackKey);
}

@pragma("vm:entry-point")
Future<void> backgroundCallback(Uri? data) async {
  HomeWidget.setAppGroupId('group.ForceSyncWidget');
  if (!RustLib.instance.initialized) await RustLib.init();

  try {
    print(data.toString());

    final scheme = data?.scheme ?? '';
    final hasHomeWidget = data?.queryParameters.containsKey('homeWidget') ?? false;

    if (scheme == 'forcesyncwidget' && hasHomeWidget) {
      final repoIndex = await _resolveRepoIndex(data, StorageKey.repoman_widgetSyncIndex);

      if (Platform.isIOS) {
        await gitSyncService.debouncedSync(repoIndex, true, true);
      } else {
        FlutterBackgroundService().invoke(GitsyncService.FORCE_SYNC, {REPO_INDEX: "$repoIndex"});
      }
      return;
    }

    if (scheme == 'manualsyncwidget' && hasHomeWidget) {
      final repoIndex = await _resolveRepoIndex(data, StorageKey.repoman_widgetManualSyncIndex);
      await repoManager.setInt(StorageKey.repoman_repoIndex, repoIndex);
      return;
    }

    if (scheme == 'gitsync' && data?.host == 'sync-now') {
      final shortcutSyncIndex = await repoManager.getInt(StorageKey.repoman_shortcutSyncIndex);

      if (Platform.isIOS) {
        await gitSyncService.debouncedSync(shortcutSyncIndex, true, true);
      } else {
        FlutterBackgroundService().invoke(GitsyncService.FORCE_SYNC, {REPO_INDEX: "$shortcutSyncIndex"});
      }
      return;
    }
  } catch (e) {
    print('Error in widget callback: $e');
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  if (!RustLib.instance.initialized) await RustLib.init();

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

      return Future.value(false);
    } catch (e) {
      return Future.error(e);
    }
  });
}

@pragma('vm:entry-point')
void onServiceStart(ServiceInstance service) async {
  serviceInstance = service;
  if (!RustLib.instance.initialized) await RustLib.init();
  await GitManager.clearLocks();

  service.on("clearLocks").listen((event) async {
    await GitManager.clearLocks();
    service.invoke("clearLocks");
  });

  service.on(LogType.Clone.name).listen((event) async {
    if (event == null) return;
    final result = await GitManager.clone(
      event["repoUrl"],
      event["repoPath"],
      (task) => service.invoke("cloneTaskCallback", {"task": task}),
      (progress) => service.invoke("cloneProgressCallback", {"progress": progress}),
      depth: event["depth"] as int?,
      bare: event["bare"] as bool? ?? false,
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
    final rid = event?['_rid'];
    try {
      final result = await GitManager.getRecommendedAction();
      service.invoke(LogType.RecommendedAction.name, {"result": result, if (rid != null) '_rid': rid});
    } on OperationNotExecuted {
      service.invoke(LogType.RecommendedAction.name, {if (rid != null) '_rid': rid, '_skipped': true});
    } catch (e, s) {
      Logger.logError(LogType.RecommendedAction, e, s);
      service.invoke(LogType.RecommendedAction.name, {if (rid != null) '_rid': rid, '_skipped': true});
    }
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
    await GitManager.untrackAll(
      filePaths: event == null || !event.keys.contains("filePaths") ? null : event["filePaths"].map<String>((filePath) => "$filePath").toList(),
    );
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

  service.on(LogType.WorkdirFileDiff.name).listen((event) async {
    if (event == null) return;
    final result = await GitManager.getWorkdirFileDiff(event["filePath"]);
    service.invoke(
      LogType.WorkdirFileDiff.name,
      result == null
          ? null
          : {
              "filePath": result.filePath,
              "insertions": result.insertions,
              "deletions": result.deletions,
              "isBinary": result.isBinary,
              "lines": result.lines
                  .map(
                    (l) => {
                      "lineIndex": l.lineIndex,
                      "origin": l.origin,
                      "content": l.content,
                      "oldLineno": l.oldLineno,
                      "newLineno": l.newLineno,
                      "isStaged": l.isStaged,
                    },
                  )
                  .toList(),
            },
    );
  });

  service.on(LogType.StageFileLines.name).listen((event) async {
    if (event == null) return;
    await GitManager.stageFileLines(event["filePath"], event["selectedLineIndices"].map<int>((i) => i as int).toList());
    service.invoke(LogType.StageFileLines.name);
  });

  service.on(LogType.RecentCommits.name).listen((event) async {
    final rid = event?['_rid'];
    try {
      final result = await GitManager.getRecentCommits();
      service.invoke(LogType.RecentCommits.name, {
        "result": result.map((item) => utf8.fuse(base64).encode(jsonEncode(item.toJson()))).toList(),
        if (rid != null) '_rid': rid,
      });
    } on OperationNotExecuted {
      service.invoke(LogType.RecentCommits.name, {if (rid != null) '_rid': rid, '_skipped': true});
    } catch (e, s) {
      Logger.logError(LogType.RecentCommits, e, s);
      service.invoke(LogType.RecentCommits.name, {if (rid != null) '_rid': rid, '_skipped': true});
    }
  });

  service.on(LogType.ConflictingFiles.name).listen((event) async {
    final rid = event?['_rid'];
    try {
      final result = await GitManager.getConflicting();
      service.invoke(LogType.ConflictingFiles.name, {
        "result": result.map<List<String>>((item) => [item.$1, item.$2.name]).toList(),
        if (rid != null) '_rid': rid,
      });
    } on OperationNotExecuted {
      service.invoke(LogType.ConflictingFiles.name, {if (rid != null) '_rid': rid, '_skipped': true});
    } catch (e, s) {
      Logger.logError(LogType.ConflictingFiles, e, s);
      service.invoke(LogType.ConflictingFiles.name, {if (rid != null) '_rid': rid, '_skipped': true});
    }
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
    final rid = event?['_rid'];
    try {
      await GitManager.abortMerge();
      service.invoke(LogType.AbortMerge.name, {if (rid != null) '_rid': rid});
    } catch (e, s) {
      Logger.logError(LogType.AbortMerge, e, s);
      service.invoke(LogType.AbortMerge.name, {if (rid != null) '_rid': rid, '_skipped': true});
    }
  });

  service.on(LogType.BranchName.name).listen((event) async {
    final rid = event?['_rid'];
    try {
      final result = await GitManager.getBranchName();
      service.invoke(LogType.BranchName.name, {"result": result, if (rid != null) '_rid': rid});
    } on OperationNotExecuted {
      service.invoke(LogType.BranchName.name, {if (rid != null) '_rid': rid, '_skipped': true});
    } catch (e, s) {
      Logger.logError(LogType.BranchName, e, s);
      service.invoke(LogType.BranchName.name, {if (rid != null) '_rid': rid, '_skipped': true});
    }
  });

  service.on(LogType.BranchNames.name).listen((event) async {
    final rid = event?['_rid'];
    try {
      final result = await GitManager.getBranchNames();
      service.invoke(LogType.BranchNames.name, {
        "result": result.map<String>((branch) => "${branch.$1}$conflictSeparator${branch.$2}").toList(),
        if (rid != null) '_rid': rid,
      });
    } on OperationNotExecuted {
      service.invoke(LogType.BranchNames.name, {if (rid != null) '_rid': rid, '_skipped': true});
    } catch (e, s) {
      Logger.logError(LogType.BranchNames, e, s);
      service.invoke(LogType.BranchNames.name, {if (rid != null) '_rid': rid, '_skipped': true});
    }
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

  service.on(LogType.RenameBranch.name).listen((event) async {
    if (event == null) return;
    await GitManager.renameBranch(event["oldName"], event["newName"]);
    service.invoke(LogType.RenameBranch.name);
  });

  service.on(LogType.DeleteBranch.name).listen((event) async {
    if (event == null) return;
    await GitManager.deleteBranch(event["branchName"]);
    service.invoke(LogType.DeleteBranch.name);
  });

  service.on(LogType.ReadGitIgnore.name).listen((event) async {
    final result = await GitManager.readGitignore();
    service.invoke(LogType.ReadGitIgnore.name, {"result": result});
  });

  service.on(LogType.WriteGitIgnore.name).listen((event) async {
    if (event == null) return;
    await GitManager.writeGitignore(event["gitignoreString"]);
    service.invoke(LogType.WriteGitIgnore.name);
  });

  service.on(LogType.ReadGitInfoExclude.name).listen((event) async {
    final result = await GitManager.readGitInfoExclude();
    service.invoke(LogType.ReadGitInfoExclude.name, {"result": result});
  });

  service.on(LogType.WriteGitInfoExclude.name).listen((event) async {
    if (event == null) return;
    await GitManager.writeGitInfoExclude(event["gitInfoExcludeString"]);
    service.invoke(LogType.WriteGitInfoExclude.name);
  });

  service.on(LogType.GetDisableSsl.name).listen((event) async {
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
    final rid = event?['_rid'];
    try {
      final result = await GitManager.getRemoteUrlLink();
      service.invoke(LogType.GetRemoteUrlLink.name, {
        "result": result == null ? null : [result.$1, result.$2],
        if (rid != null) '_rid': rid,
      });
    } on OperationNotExecuted {
      service.invoke(LogType.GetRemoteUrlLink.name, {if (rid != null) '_rid': rid, '_skipped': true});
    } catch (e, s) {
      Logger.logError(LogType.GetRemoteUrlLink, e, s);
      service.invoke(LogType.GetRemoteUrlLink.name, {if (rid != null) '_rid': rid, '_skipped': true});
    }
  });

  service.on(LogType.ListRemotes.name).listen((event) async {
    final rid = event?['_rid'];
    try {
      final result = await GitManager.listRemotes();
      service.invoke(LogType.ListRemotes.name, {"result": result.map<String>((r) => "$r").toList(), if (rid != null) '_rid': rid});
    } on OperationNotExecuted {
      service.invoke(LogType.ListRemotes.name, {if (rid != null) '_rid': rid, '_skipped': true});
    } catch (e, s) {
      Logger.logError(LogType.ListRemotes, e, s);
      service.invoke(LogType.ListRemotes.name, {if (rid != null) '_rid': rid, '_skipped': true});
    }
  });

  service.on(LogType.AddRemote.name).listen((event) async {
    if (event == null) return;
    await GitManager.addRemote(event["name"], event["url"]);
    service.invoke(LogType.AddRemote.name);
  });

  service.on(LogType.DeleteRemote.name).listen((event) async {
    if (event == null) return;
    await GitManager.deleteRemote(event["name"]);
    service.invoke(LogType.DeleteRemote.name);
  });

  service.on(LogType.RenameRemote.name).listen((event) async {
    if (event == null) return;
    await GitManager.renameRemote(event["oldName"], event["newName"]);
    service.invoke(LogType.RenameRemote.name);
  });

  service.on(LogType.DiscardDir.name).listen((event) async {
    if (event == null) return;

    await GitManager.deleteDirContents(dirPath: event["dirPath"]);
    service.invoke(LogType.DiscardDir.name);
  });

  service.on(LogType.DiscardGitIndex.name).listen((event) async {
    await GitManager.deleteGitIndex();
    service.invoke(LogType.DiscardGitIndex.name);
  });

  service.on(LogType.RecreateGitIndex.name).listen((event) async {
    await GitManager.recreateGitIndex();
    service.invoke(LogType.RecreateGitIndex.name);
  });

  service.on(LogType.DiscardFetchHead.name).listen((event) async {
    await GitManager.deleteFetchHead();
    service.invoke(LogType.DiscardFetchHead.name);
  });

  service.on(LogType.PruneCorruptedObjects.name).listen((event) async {
    await GitManager.pruneCorruptedObjects();
    service.invoke(LogType.PruneCorruptedObjects.name);
  });

  service.on(LogType.GetSubmodules.name).listen((event) async {
    if (event == null) return;
    final result = await GitManager.getSubmodulePaths(event["dir"]);
    service.invoke(LogType.GetSubmodules.name, {"result": result.map<String>((branch) => "$branch").toList()});
  });

  service.on(LogType.HasGitFilters.name).listen((event) async {
    final rid = event?['_rid'];
    try {
      final result = await GitManager.hasGitFilters(event?["repomanRepoindex"]);
      service.invoke(LogType.HasGitFilters.name, {"result": result, if (rid != null) '_rid': rid});
    } on OperationNotExecuted {
      service.invoke(LogType.HasGitFilters.name, {if (rid != null) '_rid': rid, '_skipped': true});
    } catch (e, s) {
      Logger.logError(LogType.HasGitFilters, e, s);
      service.invoke(LogType.HasGitFilters.name, {if (rid != null) '_rid': rid, '_skipped': true});
    }
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
    gitSyncService.debouncedSync(
      int.tryParse(event?[REPO_INDEX] ?? "null") ?? await repoManager.getInt(StorageKey.repoman_repoIndex),
      false,
      false,
      event?[COMMIT_MESSAGE],
    );
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
                networkStallRetry: t.networkStallRetry,
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

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key, required this.title, required this.reloadLocale});

  final String title;
  final VoidCallback reloadLocale;

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> with WidgetsBindingObserver, RestorationMixin, TickerProviderStateMixin {
  bool repoSettingsExpanded = false;
  bool demoConflicting = false;

  bool devTools = false;
  final ValueNotifier<int> _tabIndex = ValueNotifier(1); // Default to Home tab
  final PageController _pageController = PageController(initialPage: 1);
  final GlobalKey<NavigatorState> _homeNavigatorKey = GlobalKey<NavigatorState>();
  final ValueNotifier<bool> _homeCanPop = ValueNotifier(false);
  final GlobalKey<NavigatorState> _filesNavigatorKey = GlobalKey<NavigatorState>();
  final ValueNotifier<bool> _filesCanPop = ValueNotifier(false);
  final GlobalKey<FileExplorerState> _fileExplorerKey = GlobalKey<FileExplorerState>();
  late ValueNotifier<List<String>> queueValue = ValueNotifier([]);
  Timer? queueTimer;

  Timer? autoRefreshTimer;
  StreamSubscription<List<ConnectivityResult>>? networkSubscription;
  late AnchorScrollController recentCommitsController = AnchorScrollController(
    onIndexChanged: (index, userScroll) {
      mergeConflictVisible.value = index == 0;
    },
  )..addListener(_onCommitsScroll);

  late final _restorableGlobalSettings = RestorableRouteFuture<String?>(
    onPresent: (navigator, arguments) {
      return navigator.restorablePush(createGlobalSettingsMainRoute, arguments: arguments);
    },
    onComplete: (result) async {
      if (result == "guided_setup") {
        _restorableOnboardingSetup.present({});
      } else if (result == "ui_guide") {
        _triggerUiGuideShowcase();
      }
      reloadAll();
    },
  );

  Future<void> _openSettingsMain({bool showcaseAuthorDetails = false}) async {
    await _homeNavigatorKey.currentState?.push<String?>(
      createSettingsMainRoute(_homeNavigatorKey.currentContext!, {"showcaseAuthorDetails": showcaseAuthorDetails}),
    );
    reloadAll();
  }

  late final _restorableOnboardingSetup = RestorableRouteFuture<String?>(
    onPresent: (navigator, arguments) {
      return navigator.restorablePush(createOnboardingSetupRoute, arguments: arguments);
    },
    onComplete: (result) async {
      final step = await repoManager.getInt(StorageKey.repoman_onboardingStep);
      if (step == 5) {
        await _triggerUiGuideShowcase();
      }
      reloadAll();
    },
  );

  late final _restorableUnlockPremium = RestorableRouteFuture<bool?>(
    onPresent: (navigator, arguments) {
      return navigator.restorablePush(createUnlockPremiumRoute, arguments: arguments);
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
    registerForRestoration(_restorableOnboardingSetup, onboarding_setup);
    registerForRestoration(_restorableUnlockPremium, unlock_premium);
    registerForRestoration(mergeConflictVisible, 'mergeConflictVisible');
  }

  late final syncMethodsDropdownKey = GlobalKey();
  late final syncMethodMainButtonKey = GlobalKey();
  late final _globalSettingsKey = GlobalKey();
  late final _syncProgressKey = GlobalKey();
  late final _addMoreKey = GlobalKey();
  late final _controlKey = GlobalKey();
  late final _configKey = GlobalKey();
  late final _autoSyncOptionsKey = GlobalKey();

  late final AnimationController _pulseController = AnimationController(vsync: this, duration: Duration(milliseconds: 2000))..repeat(reverse: true);
  late final Animation<double> _pulseAnimation = Tween<double>(
    begin: 30.0,
    end: 120.0,
  ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

  final ValueNotifier<bool> _commitSelectMode = ValueNotifier(false);
  final ValueNotifier<Set<String>> _commitSelectedShas = ValueNotifier({});

  RestorableBool mergeConflictVisible = RestorableBool(true);

  int _reloadToken = 0;

  void _exitCommitSelectMode() {
    _commitSelectMode.value = false;
    _commitSelectedShas.value = {};
  }

  void _onCommitsScroll() {
    final pos = recentCommitsController.position;
    if (pos.pixels >= pos.maxScrollExtent - 50) {
      ref.read(recentCommitsProvider.notifier).loadMore();
    }
  }

  Future<void> _navigateToExpandedCommits({double initialScrollOffset = 0, ShowcaseFeature? pendingFeature}) async {
    final provider = ref.read(gitProviderProvider).valueOrNull ?? GitProvider.GITHUB;
    final authenticated = ref.read(isAuthenticatedProvider).valueOrNull ?? false;
    if (!mounted) return;
    Navigator.of(context)
        .push(
          createExpandedCommitsRoute(
            gitProvider: provider,
            remoteWebUrl: ref.read(remoteUrlLinkProvider).valueOrNull?.$2,
            isAuthenticated: authenticated,
            onBranchChanged: (newBranch) async {
              await runGitOperation(LogType.CheckoutBranch, (event) => event, {"branchName": newBranch});
              await reloadAll();
            },
            onCreateBranch: () {
              CreateBranchDialog.showDialog(
                context,
                ref.read(branchNameProvider).valueOrNull,
                (ref.read(branchNamesProvider).valueOrNull ?? {}).keys.toList(),
                (branchNameValue, basedOn) async {
                  await runGitOperation(LogType.CreateBranch, (event) => event, {"branchName": branchNameValue, "basedOn": basedOn});
                  await syncOptionCompletionCallback();
                },
              );
            },
            onRenameBranch: (oldName, newName) async {
              await runGitOperation(LogType.RenameBranch, (event) => event, {"oldName": oldName, "newName": newName});
              await reloadAll();
            },
            onDeleteBranch: (branchName) async {
              await runGitOperation(LogType.DeleteBranch, (event) => event, {"branchName": branchName});
              await reloadAll();
            },
            isClientMode: ref.read(clientModeEnabledProvider).valueOrNull ?? false,
            onReloadAll: () async => await reloadAll(),
            initialScrollOffset: initialScrollOffset,
            pendingFeature: pendingFeature,
          ),
        )
        .then((popResult) {
          if (popResult != null) {
            double scrollOffset = double.parse("$popResult");
            recentCommitsController = AnchorScrollController(
              onIndexChanged: (index, userScroll) {
                mergeConflictVisible.value = index == 0;
              },
              initialScrollOffset: scrollOffset,
            )..addListener(_onCommitsScroll);
          }
          reloadAll();
        });
  }

  Future<void> reloadAll() async {
    final token = ++_reloadToken;
    aiChatService.switchToRepo();
    await colours.reloadTheme(context);
    if (token != _reloadToken) return;
    if (mounted) setState(() {});
    ref.invalidate(branchNameProvider);
    ref.invalidate(remoteUrlLinkProvider);
    ref.invalidate(listRemotesProvider);
    ref.invalidate(branchNamesProvider);
    ref.invalidate(hasGitFiltersProvider);
    ref.invalidate(conflictingFilesProvider);
    ref.invalidate(recentCommitsProvider);
    ref.invalidate(recommendedActionProvider);
    ref.invalidate(syncMessageEnabledProvider);
    ref.invalidate(lastSyncMethodProvider);
    ref.invalidate(clientModeEnabledProvider);
    ref.invalidate(gitProviderProvider);
    ref.invalidate(postFooterProvider);
    ref.invalidate(authorNameProvider);
    ref.invalidate(authorEmailProvider);
    ref.invalidate(syncMessageProvider);
    ref.invalidate(githubScopedOauthProvider);
    ref.invalidate(isAuthenticatedProvider);
    ref.invalidate(repoNamesProvider);
    ref.invalidate(repoIndexProvider);
    ref.invalidate(featureCountsProvider);
    ref.invalidate(gitDirPathProvider);
    ref.invalidate(remoteNameProvider);
    ref.invalidate(submodulePathsProvider);
    if (token != _reloadToken) return;
    if (mounted) setState(() {});
  }

  static List<((String, Widget), Future<void> Function(BuildContext context, (String, String)? remote), bool enabled)> remoteEllipsisActions(
    int remoteCount,
  ) => [
    (
      (t.launchInBrowser, FaIcon(FontAwesomeIcons.squareArrowUpRight, color: colours.primaryPositive, size: textMD)),
      (BuildContext context, (String, String)? remote) async => remote == null ? null : await launchUrl(Uri.parse(remote.$2)),
      true,
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
      true,
    ),
    (
      (t.renameRemote, FaIcon(FontAwesomeIcons.penToSquare, color: colours.tertiaryInfo, size: textMD)),
      (BuildContext context, (String, String)? remote) async {
        if (remote == null) return;
        final currentRemoteName = await uiSettingsManager.getRemote();
        await RenameRemoteDialog.showDialog(context, currentRemoteName, (newName) async {
          await runGitOperation(LogType.RenameRemote, (event) => event, {"oldName": currentRemoteName, "newName": newName});
          await uiSettingsManager.setStringNullable(StorageKey.setman_remote, newName);
        });
      },
      true,
    ),
    (
      (t.deleteRemote, FaIcon(FontAwesomeIcons.trashCan, color: remoteCount > 1 ? colours.tertiaryNegative : colours.tertiaryLight, size: textMD)),
      (BuildContext context, (String, String)? remote) async {
        if (remote == null) return;
        final currentRemoteName = await uiSettingsManager.getRemote();
        await ConfirmDeleteRemoteDialog.showDialog(context, currentRemoteName, () async {
          await runGitOperation(LogType.DeleteRemote, (event) => event, {"name": currentRemoteName});
          final remainingRemotes = await runGitOperation<List<String>>(
            LogType.ListRemotes,
            (event) => event?["result"].map<String>((r) => "$r").toList() ?? <String>[],
          );
          if (remainingRemotes.isNotEmpty) {
            await uiSettingsManager.setStringNullable(StorageKey.setman_remote, remainingRemotes.first);
          }
        });
      },
      remoteCount > 1,
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
    //     .listen((event) => ref.read(conflictingFilesProvider.notifier).set(event?["result"].map<String>((path) => "$path").toList()));

    // TODO: put behind an on for all the sync option fns?
    //

    initAsync(() async {
      if (kDebugMode) {
        queueTimer?.cancel();
        queueTimer = Timer.periodic(Duration(milliseconds: 500), (_) async {
          try {
            queueValue.value = await File(
              '${(await getApplicationSupportDirectory()).path}/queues/flock_queue_${await repoManager.getInt(StorageKey.repoman_repoIndex)}',
            ).readAsLines();
          } catch (e) {
            queueValue.value = [];
          }
        });
      }
    });

    initAsync(() async {
      await reloadAll();
    });

    initAsync(() async {
      Uri? uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      print("////init $uri");
      if (uri?.scheme == 'manualsyncwidget' && (uri?.queryParameters.containsKey('homeWidget') ?? false)) {
        final repoIndex = await _resolveRepoIndex(uri, StorageKey.repoman_widgetManualSyncIndex);
        await repoManager.setInt(StorageKey.repoman_repoIndex, repoIndex);
        await uiSettingsManager.reinit();
        await reloadAll();
        await ManualSyncDialog.showDialog(context, hasRemotes: (ref.read(listRemotesProvider).valueOrNull ?? []).isNotEmpty);
      }
    });

    HomeWidget.widgetClicked.listen((uri) async {
      if (uri?.scheme == 'manualsyncwidget' && (uri?.queryParameters.containsKey('homeWidget') ?? false)) {
        final repoIndex = await _resolveRepoIndex(uri, StorageKey.repoman_widgetManualSyncIndex);
        await repoManager.setInt(StorageKey.repoman_repoIndex, repoIndex);
        await uiSettingsManager.reinit();
        await reloadAll();
        await ManualSyncDialog.showDialog(context, hasRemotes: (ref.read(listRemotesProvider).valueOrNull ?? []).isNotEmpty);
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
        await ManualSyncDialog.showDialog(context, hasRemotes: (ref.read(listRemotesProvider).valueOrNull ?? []).isNotEmpty);
        return;
      }
    });

    quickActions.setShortcutItems(<ShortcutItem>[
      ShortcutItem(type: GitsyncService.FORCE_SYNC, localizedTitle: t.syncNow, icon: "sync_now"),
      ShortcutItem(type: GitsyncService.MANUAL_SYNC, localizedTitle: t.manualSync, icon: "manual_sync"),
    ]);

    initAsync(() async {
      final provider = await repoManager.getStringNullable(StorageKey.repoman_aiProvider);
      final apiKey = await repoManager.getStringNullable(StorageKey.repoman_aiApiKey);
      aiKeyConfigured.value = provider != null && provider.isNotEmpty && apiKey != null && apiKey.isNotEmpty;
    });

    aiFeaturesEnabled.addListener(_onAiFeaturesEnabledChanged);

    initAsync(() async {
      aiFeaturesEnabled.value = await repoManager.getBool(StorageKey.repoman_aiFeaturesEnabled);
    });

    switchToAiTab = () {
      if (!aiFeaturesEnabled.value) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      _homeNavigatorKey.currentState?.popUntil((route) => route.isFirst);
      _tabIndex.value = 0;
      _pageController.animateToPage(0, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
    };

    initAsync(() async {
      if (premiumManager.hasPremiumNotifier.value == false) {
        await premiumManager.cullNonPremium();
        await reloadAll();
      }
    });

    premiumManager.hasPremiumNotifier.addListener(() async {
      if (premiumManager.hasPremiumNotifier.value == false && await premiumManager.cullNonPremium()) {
        await reloadAll();
      }
    });

    FlutterBackgroundService().on(GitsyncService.MERGE_COMPLETE).listen((event) async {
      Navigator.of(context).canPop() ? Navigator.pop(context) : null;
      await reloadAll();
    });

    networkSubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) => mounted ? setState(() {}) : null);

    initAsync(() async {
      await promptClearKeychainValues();

      if (await repoManager.hasLegacySettings()) {
        if (!mounted) return;

        _restorableOnboardingSetup.present({"legacy": true});
        return;
      }
      final step = await repoManager.getInt(StorageKey.repoman_onboardingStep);
      if (step != -1 && step != 5) {
        final gitDirPath = await uiSettingsManager.getString(StorageKey.setman_gitDirPath);
        if (gitDirPath.isNotEmpty) {
          await repoManager.setOnboardingStep(-1);
          return;
        }
      }

      if (step == 5) {
        _triggerUiGuideShowcase();
      } else if (step != -1) {
        _restorableOnboardingSetup.present({});
      }
    });

    super.initState();
  }

  void _onAiFeaturesEnabledChanged() {
    final oldIndex = _tabIndex.value;
    final int newIndex;
    if (aiFeaturesEnabled.value) {
      // 2 → 3 children. Old: 0=Home, 1=Files. New: 0=AI, 1=Home, 2=Files.
      newIndex = oldIndex + 1;
    } else {
      // 3 → 2 children. Old: 0=AI, 1=Home, 2=Files. New: 0=Home, 1=Files.
      newIndex = oldIndex == 0 ? 0 : oldIndex - 1;
    }
    if (newIndex != oldIndex) {
      _tabIndex.value = newIndex;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      if ((_pageController.page ?? _pageController.initialPage.toDouble()).round() != newIndex) {
        _pageController.jumpToPage(newIndex);
      }
    });
  }

  Future<void> launchWidgetManualSync() async {
    final widgetManualSyncIndex = await repoManager.getInt(StorageKey.repoman_widgetManualSyncIndex);
    await repoManager.setInt(StorageKey.repoman_repoIndex, widgetManualSyncIndex);
    await uiSettingsManager.reinit();
    await reloadAll();
    await ManualSyncDialog.showDialog(context, hasRemotes: (ref.read(listRemotesProvider).valueOrNull ?? []).isNotEmpty);
  }

  Future<void> updateRecommendedAction({int? override}) async {
    if (!(ref.read(clientModeEnabledProvider).valueOrNull ?? false)) return;
    autoRefreshTimer?.cancel();
    final startTime = DateTime.now();
    if (override != null) {
      ref.read(recommendedActionProvider.notifier).set(override);
    } else {
      await ref.read(recommendedActionProvider.notifier).refresh();
    }
    _scheduleNextRecommendedAction(startTime);
  }

  void _scheduleNextRecommendedAction(DateTime startTime) {
    autoRefreshTimer?.cancel();
    const minDelay = Duration(seconds: 10);
    final elapsed = DateTime.now().difference(startTime);
    final remaining = minDelay - elapsed;
    if (remaining <= Duration.zero) {
      autoRefreshTimer = Timer(Duration.zero, () async => await updateRecommendedAction());
    } else {
      autoRefreshTimer = Timer(remaining, () async => await updateRecommendedAction());
    }
  }

  Future<void> promptClearKeychainValues() async {
    final prefs = await SharedPreferences.getInstance();

    if (Platform.isIOS && (prefs.getBool('is_first_app_launch') ?? true)) {
      await ConfirmReinstallClearDataDialog.showDialog(context, () async {
        await uiSettingsManager.storage.deleteAll();
        await repoManager.storage.deleteAll();
      });

      await GitManager.clearLocks();
      await prefs.setBool('is_first_app_launch', false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> completeUiGuideShowcase(bool initialClientModeEnabled) async {
    _restorableGlobalSettings.present({"onboarding": true});
    await repoManager.setOnboardingStep(-1);
    ref.read(clientModeEnabledProvider.notifier).set(initialClientModeEnabled);
    if (mounted) setState(() {});
  }

  Future<void> _triggerUiGuideShowcase() async {
    final initialClientModeEnabled = ref.read(clientModeEnabledProvider).valueOrNull ?? false;
    ref.read(clientModeEnabledProvider.notifier).set(false);
    ShowCaseWidget.of(context).startShowCase([_configKey, _autoSyncOptionsKey, _controlKey, _globalSettingsKey, _syncProgressKey, _addMoreKey]);
    while (!ShowCaseWidget.of(context).isShowCaseCompleted) {
      await Future.delayed(Duration(milliseconds: 100));
    }
    await completeUiGuideShowcase(initialClientModeEnabled);
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

  Future<bool> isGithubOauth() async {
    final provider = ref.read(gitProviderProvider).valueOrNull ?? GitProvider.GITHUB;
    return provider == GitProvider.GITHUB;
  }

  String getLastSyncOption(int? recommendedActionValue) {
    if (ref.read(clientModeEnabledProvider).valueOrNull ?? false) {
      if (recommendedActionValue != null && recommendedActionValue >= 0) {
        return [
          sprintf(t.fetchRemote, [ref.read(remoteNameProvider).valueOrNull ?? "origin"]),
          t.pullChanges,
          t.stageAndCommit,
          t.pushChanges,
        ][recommendedActionValue];
      }
    }
    return ref.read(lastSyncMethodProvider).valueOrNull ?? "";
  }

  Map<String, (FaIconData, Future<void> Function())> _buildSyncOptions({
    required bool clientModeEnabled,
    required bool noRemotes,
    required String? dirPath,
    required List<String> submodulePaths,
    required String remoteName,
    required bool hasConflicts,
    required int repomanRepoindex,
  }) {
    if (hasConflicts) {
      return {
        if (!noRemotes && clientModeEnabled)
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
        if (!noRemotes && clientModeEnabled)
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
        if (!noRemotes && !clientModeEnabled)
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
        if (!noRemotes && !clientModeEnabled)
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
      };
    }

    return {
      if (!noRemotes)
        clientModeEnabled ? t.syncAllChanges : t.syncNow: (
          FontAwesomeIcons.solidCircleDown,
          () async {
            final currentBranch = ref.read(branchNameProvider).valueOrNull;
            if (currentBranch == null || currentBranch.isEmpty) {
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
            await ManualSyncDialog.showDialog(context, hasRemotes: (ref.read(listRemotesProvider).valueOrNull ?? []).isNotEmpty);
            await syncOptionCompletionCallback();
          },
        ),
      if (!noRemotes && dirPath != null && clientModeEnabled && submodulePaths.isNotEmpty)
        t.updateSubmodules: (
          FontAwesomeIcons.solidSquareCaretDown,
          () async {
            await runGitOperation(LogType.UpdateSubmodules, (event) => event);
            await syncOptionCompletionCallback();
          },
        ),
      if (!noRemotes && clientModeEnabled)
        sprintf(t.fetchRemote, [remoteName]): (
          FontAwesomeIcons.caretDown,
          () async {
            await runGitOperation(LogType.FetchRemote, (event) => event);
            if (ref.read(recommendedActionProvider).valueOrNull == 0) {
              await updateRecommendedAction(override: 1);
            }
            await syncOptionCompletionCallback();
          },
        ),
      if (!noRemotes && !clientModeEnabled)
        t.downloadChanges: (
          FontAwesomeIcons.angleDown,
          () async {
            final result = await runGitOperation(LogType.DownloadChanges, (event) => event, {"repomanRepoindex": repomanRepoindex});
            FlutterBackgroundService().on("downloadChanges-syncCallback").first.then((_) async {
              if (ref.read(syncMessageEnabledProvider).valueOrNull ?? false) {
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

            if (ref.read(syncMessageEnabledProvider).valueOrNull ?? false) {
              Fluttertoast.showToast(msg: t.syncComplete, toastLength: Toast.LENGTH_LONG, gravity: null);
            }
            await syncOptionCompletionCallback();
          },
        ),
      if (!noRemotes && clientModeEnabled)
        t.pullChanges: (
          FontAwesomeIcons.angleDown,
          () async {
            await runGitOperation(LogType.PullFromRepo, (event) => event);
            if (ref.read(recommendedActionProvider).valueOrNull == 1) {
              await updateRecommendedAction(override: -1);
            }
            await syncOptionCompletionCallback();
          },
        ),
      if (clientModeEnabled)
        t.stageAndCommit: (
          FontAwesomeIcons.barsStaggered,
          () async {
            final committed = await ManualSyncDialog.showDialog(context, hasRemotes: (ref.read(listRemotesProvider).valueOrNull ?? []).isNotEmpty);
            if (committed && ref.read(recommendedActionProvider).valueOrNull == 2) {
              await updateRecommendedAction(override: 3);
            }
            await syncOptionCompletionCallback();
          },
        ),
      if (!noRemotes && !clientModeEnabled)
        t.uploadChanges: (
          FontAwesomeIcons.angleUp,
          () async {
            final result = await runGitOperation(LogType.UploadChanges, (event) => event, {"repomanRepoindex": repomanRepoindex});
            FlutterBackgroundService().on("uploadChanges-syncCallback").first.then((_) async {
              if (ref.read(syncMessageEnabledProvider).valueOrNull ?? false) {
                Fluttertoast.showToast(msg: t.syncStartPush, toastLength: Toast.LENGTH_LONG, gravity: null);
              }
            });
            if (result == null) return;

            if (result == false) {
              Fluttertoast.showToast(msg: t.syncNotRequired, toastLength: Toast.LENGTH_LONG, gravity: null);
              return;
            }

            if (ref.read(syncMessageEnabledProvider).valueOrNull ?? false) {
              Fluttertoast.showToast(msg: t.syncComplete, toastLength: Toast.LENGTH_LONG, gravity: null);
            }
            await syncOptionCompletionCallback();
          },
        ),
      if (!noRemotes && clientModeEnabled)
        t.pushChanges: (
          FontAwesomeIcons.angleUp,
          () async {
            await runGitOperation(LogType.PushToRepo, (event) => event);
            if (ref.read(recommendedActionProvider).valueOrNull == 3) {
              await updateRecommendedAction(override: -1);
            }
            await syncOptionCompletionCallback();
          },
        ),
      if (!noRemotes && !clientModeEnabled)
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
      if (!noRemotes && !clientModeEnabled)
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
      if (!noRemotes && clientModeEnabled)
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
      if (!noRemotes && clientModeEnabled)
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
    };
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    recentCommitsController.removeListener(_onCommitsScroll);

    mergeConflictVisible.dispose();

    premiumManager.dispose();
    _pulseController.dispose();
    _commitSelectMode.dispose();
    _commitSelectedShas.dispose();

    switchToAiTab = null;
    aiFeaturesEnabled.removeListener(_onAiFeaturesEnabledChanged);
    autoRefreshTimer?.cancel();
    networkSubscription?.cancel();
    _tabIndex.dispose();
    _pageController.dispose();
    _homeCanPop.dispose();
    for (var key in debounceTimers.keys) {
      if (key.startsWith(iosFolderAccessDebounceReference)) {
        cancelDebounce(key, true);
      }
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (Platform.isIOS) {
      if (state == AppLifecycleState.resumed) {
        await _triggerLifecycleSync(true);
      } else if (state == AppLifecycleState.paused) {
        await _triggerLifecycleSync(false);
      }
    }

    if (state == AppLifecycleState.resumed) {
      await GitManager.clearLocks();
      await reloadAll();
    }
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      autoRefreshTimer?.cancel();
    }
  }

  Future<void> _triggerLifecycleSync(bool isOpening) async {
    try {
      final repoNamesLength = (await repoManager.getStringList(StorageKey.repoman_repoNames)).length;

      for (var index = 0; index < repoNamesLength; index++) {
        final settingsManager = await SettingsManager().reinit(repoIndex: index);

        final syncSetting = isOpening
            ? await settingsManager.getBool(StorageKey.setman_syncOnAppOpened)
            : await settingsManager.getBool(StorageKey.setman_syncOnAppClosed);

        if (!syncSetting) continue;

        gitSyncService.debouncedSync(index);
      }
    } catch (e) {}
  }

  Future<void> showAuthDialog([Function(BaseAlertDialog dialog, {bool cancelable})? showDialog]) async {
    if (AuthDialog.authDialogKey.currentContext != null) {
      Navigator.of(context).canPop() ? Navigator.pop(context) : null;
    }

    return AuthDialog.showDialog(context, () async {
      await reloadAll();
      // After auth, offer remote creation if current repo has no remotes
      final gitDirPath = ref.read(gitDirPathProvider).valueOrNull;
      if (gitDirPath?.$1 != null && (ref.read(listRemotesProvider).valueOrNull ?? []).isEmpty) {
        final provider = ref.read(gitProviderProvider).valueOrNull ?? GitProvider.GITHUB;
        if (provider.isOAuthProvider) {
          await offerCreateRemoteForExistingRepo(context, gitDirPath!.$1);
          await reloadAll();
        }
      }
      if ((ref.read(authorEmailProvider).valueOrNull ?? "").isEmpty || (ref.read(authorNameProvider).valueOrNull ?? "").isEmpty) {
        await AuthorDetailsPromptDialog.showDialog(
          context,
          () async {
            await _openSettingsMain(showcaseAuthorDetails: true);
            await showCloneRepoPage();
          },
          () async {
            await showCloneRepoPage();
          },
        );
        return;
      }
      await showCloneRepoPage();
    });
  }

  Future<void> showCloneRepoPage() async {
    await _homeNavigatorKey.currentState?.push(createCloneRepoMainRoute());
    reloadAll();
  }

  Widget _buildFilesTab() {
    return ProviderBuilder<(String, String)?>(
      provider: gitDirPathProvider,
      builder: (context, gitDirPathAsync) {
        final path = gitDirPathAsync.valueOrNull?.$2;
        if (path == null) {
          return Container(
            color: colours.primaryDark,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(FontAwesomeIcons.solidFolderOpen, color: colours.secondaryLight, size: spaceXL),
                  SizedBox(height: spaceMD),
                  Text(
                    t.noRepoSetup,
                    style: TextStyle(color: colours.secondaryLight, fontSize: textLG),
                  ),
                  SizedBox(height: spaceLG),
                  TextButton.icon(
                    onPressed: () async {
                      String? selectedDirectory;
                      if (await requestStoragePerm()) {
                        selectedDirectory = await pickDirectory();
                      }
                      if (selectedDirectory == null) return;
                      if (!mounted) return;
                      final isRepo = await validateOrInitGitDir(context, selectedDirectory);
                      if (!isRepo) return;
                      if (!mounted) return;
                      await setGitDirPathGetSubmodules(context, selectedDirectory, ref);
                      await reloadAll();
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(colours.secondaryDark),
                      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM)),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(cornerRadiusMD),
                          side: BorderSide(color: colours.tertiaryDark),
                        ),
                      ),
                    ),
                    icon: FaIcon(FontAwesomeIcons.folderOpen, color: colours.tertiaryInfo, size: textMD),
                    label: Text(
                      t.selectDirLabel.toUpperCase(),
                      style: TextStyle(color: colours.primaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        void goToHomeTab() {
          final homeIndex = aiFeaturesEnabled.value ? 1 : 0;
          _tabIndex.value = homeIndex;
          _pageController.animateToPage(homeIndex, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        }

        return ValueListenableBuilder(
          valueListenable: _tabIndex,
          builder: (context, currentTab, child) => ValueListenableBuilder(
            valueListenable: _filesCanPop,
            builder: (context, canPop, child) => PopScope(
              canPop: currentTab != (aiFeaturesEnabled.value ? 2 : 1) && !canPop,
              onPopInvokedWithResult: (didPop, _) {
                if (didPop) return;
                if (_filesNavigatorKey.currentState?.canPop() ?? false) {
                  _filesNavigatorKey.currentState!.pop();
                } else if (!(_fileExplorerKey.currentState?.handleBack() ?? false)) {
                  goToHomeTab();
                }
              },
              child: child!,
            ),
            child: child,
          ),
          child: Navigator(
            key: _filesNavigatorKey,
            observers: [_NestedNavigatorObserver(_filesCanPop)],
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (context) => Consumer(
                builder: (context, ref, _) {
                  final currentPath = ref.watch(gitDirPathProvider).valueOrNull?.$2 ?? path;
                  final commits = ref.watch(recentCommitsProvider).valueOrNull ?? [];
                  return FileExplorer(commits, key: _fileExplorerKey, path: currentPath, embedded: true, onBackAtRoot: goToHomeTab);
                },
              ),
            ),
          ),
        );
      },
    );
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
            title: Padding(
              padding: EdgeInsets.only(left: spaceMD, bottom: spaceXXS),
              child: GestureDetector(
                onTap: kDebugMode
                    ? () {
                        devTools = !devTools;
                        if (devTools) {
                          queueTimer?.cancel();
                          queueTimer = Timer.periodic(Duration(milliseconds: 500), (_) async {
                            try {
                              queueValue.value = await File(
                                '${(await getApplicationSupportDirectory()).path}/queues/flock_queue_${await repoManager.getInt(StorageKey.repoman_repoIndex)}',
                              ).readAsLines();
                            } catch (e) {
                              queueValue.value = [];
                            }
                          });
                        } else {
                          queueTimer?.cancel();
                        }
                        setState(() {});
                      }
                    : null,
                child: Text(
                  widget.title,
                  textAlign: TextAlign.right,
                  style: TextStyle(color: colours.primaryLight, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            actions: [
              CustomShowcase(
                globalKey: _globalSettingsKey,
                cornerRadius: cornerRadiusMax,
                richContent: ShowcaseTooltipContent(
                  title: t.showcaseGlobalSettingsTitle,
                  subtitle: t.showcaseGlobalSettingsSubtitle,
                  featureRows: [
                    ShowcaseFeatureRow(icon: FontAwesomeIcons.sliders, text: t.showcaseGlobalSettingsFeatureTheme),
                    ShowcaseFeatureRow(icon: FontAwesomeIcons.solidFloppyDisk, text: t.showcaseGlobalSettingsFeatureBackup),
                    ShowcaseFeatureRow(icon: FontAwesomeIcons.chalkboardUser, text: t.showcaseGlobalSettingsFeatureSetup),
                  ],
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  style: ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  constraints: BoxConstraints(),
                  onPressed: () async {
                    _restorableGlobalSettings.present({});
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
                cornerRadius: cornerRadiusMax,
                richContent: ShowcaseTooltipContent(
                  title: t.showcaseAddMoreTitle,
                  subtitle: t.showcaseAddMoreSubtitle,
                  featureRows: [
                    ShowcaseFeatureRow(icon: FontAwesomeIcons.solidFolderOpen, text: t.showcaseAddMoreFeatureSwitch),
                    ShowcaseFeatureRow(icon: FontAwesomeIcons.squarePen, text: t.showcaseAddMoreFeatureManage),
                    ShowcaseFeatureRow(icon: FontAwesomeIcons.solidGem, text: t.showcaseAddMoreFeaturePremium),
                  ],
                ),
                customTooltipActions: [
                  TooltipActionButton(
                    backgroundColor: colours.secondaryInfo,
                    textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: textSM, color: colours.primaryLight),
                    leadIcon: ActionButtonIcon(
                      icon: FaIcon(FontAwesomeIcons.solidFileLines, color: colours.primaryLight, size: textSM),
                    ),
                    name: t.learnMore.toUpperCase(),
                    onTap: () => launchUrl(Uri.parse(premiumDocsLink)),
                    type: null,
                    borderRadius: BorderRadius.all(cornerRadiusMD),
                    padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceXS),
                  ),
                ],
                child: ProviderBuilder<List<String>>(
                  provider: repoNamesProvider,
                  builder: (context, repoNamesAsync) => Container(
                    padding: EdgeInsets.zero,
                    decoration: BoxDecoration(color: colours.tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusMax)),
                    child: ProviderBuilder<int>(
                      provider: repoIndexProvider,
                      builder: (context, repoIndexAsync) => repoNamesAsync.valueOrNull == null
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
                                    if (demo) {
                                      final result = await Navigator.of(context).push(createUnlockPremiumRoute(context, {}));
                                      if (result == true) {
                                        if (mounted) setState(() {});
                                      }
                                    }

                                    if (premiumManager.hasPremiumNotifier.value != true) {
                                      final result = await Navigator.of(context).push(createUnlockPremiumRoute(context, {}));
                                      if (result == true) {
                                        if (mounted) setState(() {});
                                        await addRepo();
                                      }
                                      if (mounted) setState(() {});
                                      return;
                                    }

                                    if (repoNamesAsync.valueOrNull!.length == 1 || repoSettingsExpanded) {
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
                                              ? (repoNamesAsync.valueOrNull!.length == 1 || repoSettingsExpanded
                                                    ? FontAwesomeIcons.solidSquarePlus
                                                    : FontAwesomeIcons.ellipsis)
                                              : FontAwesomeIcons.solidGem,
                                          color: repoNamesAsync.valueOrNull!.length == 1 || repoSettingsExpanded
                                              ? colours.tertiaryPositive
                                              : colours.secondaryLight,
                                          size: textLG,
                                        ),
                                      ),
                                      repoNamesAsync.valueOrNull!.length != 1
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
                                repoNamesAsync.valueOrNull!.length > 1 && repoSettingsExpanded
                                    ? Row(
                                        children: [
                                          IconButton(
                                            style: ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                            constraints: BoxConstraints(),
                                            onPressed: () async {
                                              repoSettingsExpanded = false;
                                              setState(() {});

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

                                              if (repoNamesAsync.valueOrNull == null || repoIndexAsync.valueOrNull == null) return;

                                              RenameContainerDialog.showDialog(
                                                context,
                                                repoNamesAsync.valueOrNull![repoIndexAsync.valueOrNull!].toLowerCase(),
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
                                ...repoNamesAsync.valueOrNull!.length > 1
                                    ? [
                                        SizedBox(width: spaceXXXS),
                                        DropdownButton(
                                          borderRadius: BorderRadius.all(cornerRadiusMD),
                                          padding: EdgeInsets.zero,
                                          icon: Padding(
                                            padding: EdgeInsets.symmetric(horizontal: spaceSM),
                                            child: FaIcon(FontAwesomeIcons.caretDown, color: colours.secondaryLight, size: textSM),
                                          ),
                                          value: repoIndexAsync.valueOrNull ?? 0,
                                          style: TextStyle(color: colours.tertiaryLight, fontWeight: FontWeight.w900, fontSize: textMD),
                                          isDense: true,
                                          underline: const SizedBox.shrink(),
                                          dropdownColor: colours.secondaryDark,
                                          onChanged: (value) async {
                                            if (value == null) return;
                                            await repoManager.setInt(StorageKey.repoman_repoIndex, value);
                                            await uiSettingsManager.reinit();
                                            await reloadAll();
                                          },
                                          selectedItemBuilder: (context) => List.generate(
                                            repoNamesAsync.valueOrNull!.length,
                                            (index) => ConstrainedBox(
                                              constraints: BoxConstraints(maxWidth: spaceXXL + spaceLG),
                                              child: Text(
                                                repoNamesAsync.valueOrNull![index].toUpperCase(),
                                                style: TextStyle(fontSize: textXS, color: colours.primaryLight),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          items: List.generate(
                                            repoNamesAsync.valueOrNull!.length,
                                            (index) => DropdownMenuItem(
                                              value: index,
                                              child: Text(
                                                repoNamesAsync.valueOrNull![index].toUpperCase(),
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
          ),
          body: ValueListenableBuilder<bool>(
            valueListenable: aiFeaturesEnabled,
            builder: (context, aiEnabled, _) => PageView(
              controller: _pageController,
              onPageChanged: (page) => _tabIndex.value = page,
              children: [
                if (aiEnabled)
                  _KeepAlivePage(
                    child: ValueListenableBuilder(
                      valueListenable: _tabIndex,
                      builder: (context, currentTab, child) => PopScope(
                        canPop: currentTab != 0,
                        onPopInvokedWithResult: (didPop, _) {
                          if (!didPop) {
                            _tabIndex.value = 1;
                            _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                          }
                        },
                        child: child!,
                      ),
                      child: AiFeaturesPage(),
                    ),
                  ),
                _KeepAlivePage(
                  child: ValueListenableBuilder(
                    valueListenable: _homeCanPop,
                    builder: (context, canPop, child) => PopScope(
                      canPop: !canPop,
                      onPopInvokedWithResult: (didPop, _) {
                        if (!didPop && (_homeNavigatorKey.currentState?.canPop() ?? false)) {
                          _homeNavigatorKey.currentState!.pop();
                        }
                      },
                      child: child!,
                    ),
                    child: Navigator(
                      key: _homeNavigatorKey,
                      observers: [_NestedNavigatorObserver(_homeCanPop)],
                      onGenerateRoute: (_) => MaterialPageRoute(
                        builder: (context) => BetterOrientationBuilder(
                          builder: (context, orientation) => SingleChildScrollView(
                            scrollDirection: orientation == Orientation.portrait ? Axis.vertical : Axis.horizontal,
                            child: ProviderBuilder<bool>(
                              provider: clientModeEnabledProvider,
                              builder: (context, clientModeEnabledAsync) {
                                final clientModeEnabledValue = clientModeEnabledAsync.valueOrNull;
                                return Container(
                                  width: orientation == Orientation.portrait
                                      ? null
                                      : MediaQuery.of(context).size.width -
                                            (MediaQuery.of(context).systemGestureInsets.right > 0 ||
                                                    MediaQuery.of(context).systemGestureInsets.left > 0
                                                ? (MediaQuery.of(context).systemGestureInsets.left > MediaQuery.of(context).systemGestureInsets.right
                                                      ? (MediaQuery.of(context).systemGestureInsets.left -
                                                            MediaQuery.of(context).systemGestureInsets.right)
                                                      : (MediaQuery.of(context).systemGestureInsets.right -
                                                            MediaQuery.of(context).systemGestureInsets.left))
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
                                          richContent: ShowcaseTooltipContent(
                                            title: t.showcaseControlTitle,
                                            subtitle: t.showcaseControlSubtitle,
                                            featureRows: [
                                              ShowcaseFeatureRow(icon: FontAwesomeIcons.solidCircleDown, text: t.showcaseControlFeatureSync),
                                              ShowcaseFeatureRow(icon: FontAwesomeIcons.clockRotateLeft, text: t.showcaseControlFeatureHistory),
                                              ShowcaseFeatureRow(icon: FontAwesomeIcons.solidCircleXmark, text: t.showcaseControlFeatureConflicts),
                                              ShowcaseFeatureRow(icon: FontAwesomeIcons.ellipsis, text: t.showcaseControlFeatureMore),
                                            ],
                                          ),
                                          child: ProviderBuilder<List<GitManagerRs.Commit>>(
                                            provider: recentCommitsProvider,
                                            builder: (context, recentCommitsAsync) => ProviderBuilder<List<(String, GitManagerRs.ConflictType)>>(
                                              provider: conflictingFilesProvider,
                                              builder: (context, conflictingAsync) {
                                                final recentCommits = recentCommitsAsync.valueOrNull ?? [];
                                                final conflictingValue = conflictingAsync.valueOrNull ?? [];
                                                final items = [
                                                  ...((conflictingValue.isEmpty)
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
                                                            tags: [],
                                                          ),
                                                        ]),
                                                  ...recentCommits,
                                                ];
                                                if (conflictingValue.isEmpty) mergeConflictVisible.value = true;

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
                                                        tags: [],
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
                                                    tags: [],
                                                  );
                                                }

                                                return Column(
                                                  verticalDirection: orientation == Orientation.portrait
                                                      ? VerticalDirection.down
                                                      : VerticalDirection.up,
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
                                                          verticalDirection: orientation == Orientation.portrait
                                                              ? VerticalDirection.down
                                                              : VerticalDirection.up,
                                                          children: [
                                                            Expanded(
                                                              flex: orientation == Orientation.portrait ? 0 : 1,
                                                              child: Stack(
                                                                clipBehavior: Clip.none,
                                                                children: [
                                                                  Hero(
                                                                    tag: hero_commits_list,
                                                                    child: SizedBox(
                                                                      height: orientation == Orientation.portrait ? 220 : double.infinity,
                                                                      child: AnimatedBuilder(
                                                                        animation: recentCommitsController,
                                                                        builder: (context, _) => ShaderMask(
                                                                          shaderCallback: (Rect rect) {
                                                                            return LinearGradient(
                                                                              begin: Alignment.topCenter,
                                                                              end: Alignment.bottomCenter,
                                                                              colors: [
                                                                                Colors.black,
                                                                                Colors.transparent,
                                                                                Colors.transparent,
                                                                                Colors.transparent,
                                                                              ],
                                                                              stops: [0.0, 0.1, 0.9, 1.0],
                                                                            ).createShader(rect);
                                                                          },
                                                                          blendMode: BlendMode.dstOut,
                                                                          child: recentCommits.isEmpty && recentCommitsAsync.isLoading
                                                                              ? Center(child: CircularProgressIndicator(color: colours.tertiaryLight))
                                                                              : (recentCommits.isEmpty && conflictingValue.isEmpty
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
                                                                                                          conflictingValue,
                                                                                                          () => reloadAll(),
                                                                                                          clientModeEnabledValue ?? false,
                                                                                                        ),
                                                                                                      );
                                                                                                    }

                                                                                                    return AnchorItemWrapper(
                                                                                                      index: index,
                                                                                                      controller: recentCommitsController,
                                                                                                      child: Consumer(
                                                                                                        builder: (context, ref, _) => ItemCommit(
                                                                                                          key: Key(reference),
                                                                                                          items[index],
                                                                                                          index < items.length - 1
                                                                                                              ? items[index + 1]
                                                                                                              : null,
                                                                                                          recentCommits,
                                                                                                          gitProvider: ref
                                                                                                              .watch(gitProviderProvider)
                                                                                                              .valueOrNull,
                                                                                                          remoteWebUrl: ref
                                                                                                              .watch(remoteUrlLinkProvider)
                                                                                                              .valueOrNull
                                                                                                              ?.$2,
                                                                                                          onRefresh: () => reloadAll(),
                                                                                                          selectMode: _commitSelectMode,
                                                                                                          selectedShas: _commitSelectedShas,
                                                                                                          onSelectModeRequested: () {
                                                                                                            _commitSelectMode.value = true;
                                                                                                            _commitSelectedShas.value = {
                                                                                                              items[index].reference,
                                                                                                            };
                                                                                                          },
                                                                                                        ),
                                                                                                      ),
                                                                                                    );
                                                                                                  },
                                                                                                ),
                                                                                                ListenableBuilder(
                                                                                                  listenable: mergeConflictVisible,
                                                                                                  builder: (context, child) => AnimatedPositioned(
                                                                                                    bottom:
                                                                                                        conflictingValue.isEmpty ||
                                                                                                            mergeConflictVisible.value
                                                                                                        ? -spaceXL
                                                                                                        : spaceMD,
                                                                                                    left: 0,
                                                                                                    right: 0,
                                                                                                    width: null,
                                                                                                    duration: animFast,
                                                                                                    child: Center(
                                                                                                      child: AnimatedOpacity(
                                                                                                        duration: animFast,
                                                                                                        opacity:
                                                                                                            conflictingValue.isEmpty ||
                                                                                                                mergeConflictVisible.value
                                                                                                            ? 0
                                                                                                            : 1,
                                                                                                        child: TextButton(
                                                                                                          onPressed: () async {
                                                                                                            await recentCommitsController.animateTo(
                                                                                                              0,
                                                                                                              duration: animFast,
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
                                                                                                                borderRadius: BorderRadius.all(
                                                                                                                  cornerRadiusSM,
                                                                                                                ),
                                                                                                                side: BorderSide.none,
                                                                                                              ),
                                                                                                            ),
                                                                                                          ),
                                                                                                          child: AnimatedContainer(
                                                                                                            duration: animFast,
                                                                                                            child: Column(
                                                                                                              crossAxisAlignment:
                                                                                                                  CrossAxisAlignment.center,
                                                                                                              mainAxisAlignment:
                                                                                                                  MainAxisAlignment.spaceBetween,
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
                                                                  ),
                                                                  ...(recentCommits.isNotEmpty == true && ref.watch(isLoadingCommitsProvider))
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
                                                                  ProviderBuilder<bool>(
                                                                    provider: isAuthenticatedProvider,
                                                                    builder: (context, authAsync) {
                                                                      if (authAsync.valueOrNull != true) return SizedBox.shrink();
                                                                      return Positioned(
                                                                        top: orientation == Orientation.portrait ? -spaceXS : null,
                                                                        bottom: orientation == Orientation.portrait ? null : -spaceXS,
                                                                        left: -spaceSM,
                                                                        child: Stack(
                                                                          children: [
                                                                            Hero(
                                                                              tag: hero_expand_contract,
                                                                              flightShuttleBuilder:
                                                                                  (
                                                                                    flightContext,
                                                                                    animation,
                                                                                    flightDirection,
                                                                                    fromHeroContext,
                                                                                    toHeroContext,
                                                                                  ) {
                                                                                    return AnimatedBuilder(
                                                                                      animation: animation,
                                                                                      builder: (context, _) {
                                                                                        final icon = flightDirection == HeroFlightDirection.push
                                                                                            ? (animation.value < 0.5
                                                                                                  ? FontAwesomeIcons.upRightAndDownLeftFromCenter
                                                                                                  : FontAwesomeIcons.downLeftAndUpRightToCenter)
                                                                                            : (animation.value < 0.5
                                                                                                  ? FontAwesomeIcons.downLeftAndUpRightToCenter
                                                                                                  : FontAwesomeIcons.upRightAndDownLeftFromCenter);
                                                                                        return IconButton(
                                                                                          padding: EdgeInsets.all(spaceSM),
                                                                                          style: ButtonStyle(
                                                                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                                                            shape: WidgetStatePropertyAll(
                                                                                              RoundedRectangleBorder(
                                                                                                borderRadius: BorderRadius.all(
                                                                                                  cornerRadiusSM,
                                                                                                ).copyWith(topLeft: cornerRadiusMD),
                                                                                              ),
                                                                                            ),
                                                                                            backgroundColor: WidgetStatePropertyAll(
                                                                                              colours.secondaryDark.withOpacity(0.5),
                                                                                            ),
                                                                                          ),
                                                                                          constraints: BoxConstraints(),
                                                                                          onPressed: null,
                                                                                          icon: FaIcon(
                                                                                            icon,
                                                                                            size: textMD,
                                                                                            color: colours.primaryLight,
                                                                                          ),
                                                                                        );
                                                                                      },
                                                                                    );
                                                                                  },
                                                                              child: IconButton(
                                                                                padding: EdgeInsets.all(spaceSM),
                                                                                style: ButtonStyle(
                                                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                                                  shape: WidgetStatePropertyAll(
                                                                                    RoundedRectangleBorder(
                                                                                      borderRadius: BorderRadius.all(cornerRadiusSM).copyWith(
                                                                                        topLeft: orientation == Orientation.portrait
                                                                                            ? cornerRadiusMD
                                                                                            : cornerRadiusSM,
                                                                                        bottomLeft: orientation == Orientation.portrait
                                                                                            ? cornerRadiusSM
                                                                                            : cornerRadiusMD,
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                  backgroundColor: WidgetStatePropertyAll(
                                                                                    colours.secondaryDark.withOpacity(0.5),
                                                                                  ),
                                                                                ),
                                                                                constraints: BoxConstraints(),
                                                                                onPressed: () => _navigateToExpandedCommits(
                                                                                  initialScrollOffset: recentCommitsController.offset,
                                                                                ),
                                                                                icon: FaIcon(
                                                                                  FontAwesomeIcons.upRightAndDownLeftFromCenter,
                                                                                  size: textMD,
                                                                                  color: colours.primaryLight,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            CommitSelectActionBar(
                                                                              selectMode: _commitSelectMode,
                                                                              selectedShas: _commitSelectedShas,
                                                                              commits: recentCommits,
                                                                              onReloadAll: () => reloadAll(),
                                                                              onExitSelectMode: _exitCommitSelectMode,
                                                                              borderRadius: BorderRadius.all(cornerRadiusSM).copyWith(
                                                                                topLeft: orientation == Orientation.portrait
                                                                                    ? cornerRadiusMD
                                                                                    : cornerRadiusSM,
                                                                                bottomLeft: orientation == Orientation.portrait
                                                                                    ? cornerRadiusSM
                                                                                    : cornerRadiusMD,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      );
                                                                    },
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            SizedBox(height: orientation == Orientation.portrait ? spaceXS : 0),

                                                            ProviderBuilder<String?>(
                                                              provider: branchNameProvider,
                                                              builder: (context, branchNameAsync) => ProviderBuilder<Map<String, String>>(
                                                                provider: branchNamesProvider,
                                                                builder: (context, branchNamesAsync) => ProviderBuilder<bool>(
                                                                  provider: conflictingFilesProvider.select((v) => v.whenData((d) => d.isNotEmpty)),
                                                                  builder: (context, hasConflictsAsync) {
                                                                    final branchNameValue = branchNameAsync.valueOrNull;
                                                                    final branchNamesMap = branchNamesAsync.valueOrNull ?? {};
                                                                    final hasBranch = branchNamesMap.containsKey(branchNameValue);

                                                                    return BranchSelector(
                                                                      branchName: branchNameValue,
                                                                      branchNames: branchNamesMap,
                                                                      hasConflicts: hasConflictsAsync.valueOrNull ?? false,
                                                                      onCheckoutBranch: (item) async {
                                                                        await runGitOperation(LogType.CheckoutBranch, (event) => event, {
                                                                          "branchName": item,
                                                                        });
                                                                        await reloadAll();
                                                                      },
                                                                      onRenameBranch: (item, newName) async {
                                                                        await runGitOperation(LogType.RenameBranch, (event) => event, {
                                                                          "oldName": item,
                                                                          "newName": newName,
                                                                        });
                                                                        await reloadAll();
                                                                      },
                                                                      onDeleteBranch: (item) async {
                                                                        await runGitOperation(LogType.DeleteBranch, (event) => event, {
                                                                          "branchName": item,
                                                                        });
                                                                        await reloadAll();
                                                                      },
                                                                      onCreateBranch: hasBranch
                                                                          ? () {
                                                                              CreateBranchDialog.showDialog(
                                                                                context,
                                                                                branchNameValue,
                                                                                branchNamesMap.keys.toList(),
                                                                                (branchNameValue, basedOn) async {
                                                                                  await runGitOperation(LogType.CreateBranch, (event) => event, {
                                                                                    "branchName": branchNameValue,
                                                                                    "basedOn": basedOn,
                                                                                  });
                                                                                  await syncOptionCompletionCallback();
                                                                                },
                                                                              );
                                                                            }
                                                                          : null,
                                                                    );
                                                                  },
                                                                ),
                                                              ),
                                                            ),

                                                            AnimatedSize(
                                                              duration: animFast,
                                                              child: ProviderBuilder<Map<ShowcaseFeature, int?>>(
                                                                provider: featureCountsProvider,
                                                                builder: (context, featureCountsAsync) => Consumer(
                                                                  builder: (context, ref, _) {
                                                                    final countsMap = featureCountsAsync.valueOrNull ?? {};
                                                                    final featureCountsLoading = featureCountsAsync.isLoading;
                                                                    final gitProviderValue =
                                                                        ref.watch(gitProviderProvider).valueOrNull ?? GitProvider.GITHUB;
                                                                    final webUrl = ref.watch(remoteUrlLinkProvider).valueOrNull?.$2;
                                                                    final authenticated = ref.watch(isAuthenticatedProvider).valueOrNull ?? false;
                                                                    final gitDirPath = ref.watch(gitDirPathProvider).valueOrNull;
                                                                    return FutureBuilder<List<String>>(
                                                                      future: uiSettingsManager.getStringList(
                                                                        StorageKey.setman_pinnedShowcaseFeatures,
                                                                      ),
                                                                      builder: (context, snapshot) {
                                                                        final data = snapshot.data;
                                                                        if (data == null) return SizedBox(width: double.infinity, height: 0);
                                                                        if (!gitProviderValue.isOAuthProvider ||
                                                                            !authenticated ||
                                                                            gitDirPath == null) {
                                                                          return SizedBox(width: double.infinity, height: 0);
                                                                        }
                                                                        final pinned = ShowcaseFeature.fromStorageKeys(data);
                                                                        if (pinned.isEmpty) return SizedBox(width: double.infinity, height: 0);
                                                                        if (pinned.length == 1) {
                                                                          return Hero(
                                                                            tag: heroShowcaseFeature(pinned[0].storageKey),
                                                                            child: ShowcaseFeatureButton(
                                                                              feature: pinned[0],
                                                                              gitProvider: gitProviderValue,
                                                                              count: countsMap[pinned[0]],
                                                                              countLoading: featureCountsLoading,
                                                                              onAdd: resolveFeatureOnAdd(
                                                                                context: context,
                                                                                feature: pinned[0],
                                                                                gitProvider: gitProviderValue,
                                                                                remoteWebUrl: webUrl,
                                                                              ),
                                                                              onPressed: () => _navigateToExpandedCommits(
                                                                                initialScrollOffset: recentCommitsController.offset,
                                                                                pendingFeature: pinned[0],
                                                                              ),
                                                                            ),
                                                                          );
                                                                        }
                                                                        return Row(
                                                                          children: [
                                                                            Expanded(
                                                                              child: Hero(
                                                                                tag: heroShowcaseFeature(pinned[0].storageKey),
                                                                                child: ShowcaseFeatureButton(
                                                                                  feature: pinned[0],
                                                                                  gitProvider: gitProviderValue,
                                                                                  count: countsMap[pinned[0]],
                                                                                  countLoading: featureCountsLoading,
                                                                                  onAdd: resolveFeatureOnAdd(
                                                                                    context: context,
                                                                                    feature: pinned[0],
                                                                                    gitProvider: gitProviderValue,
                                                                                    remoteWebUrl: webUrl,
                                                                                  ),
                                                                                  onPressed: () => _navigateToExpandedCommits(
                                                                                    initialScrollOffset: recentCommitsController.offset,
                                                                                    pendingFeature: pinned[0],
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            SizedBox(width: spaceXS),
                                                                            Expanded(
                                                                              child: Hero(
                                                                                tag: heroShowcaseFeature(pinned[1].storageKey),
                                                                                child: ShowcaseFeatureButton(
                                                                                  feature: pinned[1],
                                                                                  gitProvider: gitProviderValue,
                                                                                  count: countsMap[pinned[1]],
                                                                                  countLoading: featureCountsLoading,
                                                                                  onAdd: resolveFeatureOnAdd(
                                                                                    context: context,
                                                                                    feature: pinned[1],
                                                                                    gitProvider: gitProviderValue,
                                                                                    remoteWebUrl: webUrl,
                                                                                  ),
                                                                                  onPressed: () => _navigateToExpandedCommits(
                                                                                    initialScrollOffset: recentCommitsController.offset,
                                                                                    pendingFeature: pinned[1],
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        );
                                                                      },
                                                                    );
                                                                  },
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(height: spaceSM),
                                                    ProviderBuilder<(String, String)?>(
                                                      provider: gitDirPathProvider,
                                                      builder: (context, gitDirPathAsync) {
                                                        final gitDirPath = gitDirPathAsync.valueOrNull;
                                                        return ProviderBuilder<List<String>>(
                                                          provider: listRemotesProvider,
                                                          builder: (context, remotesAsync) => ProviderBuilder<List<String>>(
                                                            provider: submodulePathsProvider,
                                                            builder: (context, submodulePathsAsync) => ProviderBuilder<String>(
                                                              provider: remoteNameProvider,
                                                              builder: (context, remoteNameAsync) => ProviderBuilder<int>(
                                                                provider: repoIndexProvider,
                                                                builder: (context, repoIndexAsync) => ProviderBuilder<int?>(
                                                                  provider: recommendedActionProvider,
                                                                  builder: (context, recommendedActionAsync) {
                                                                    final recommendedActionValue = recommendedActionAsync.valueOrNull;
                                                                    final noRemotes = (remotesAsync.valueOrNull ?? []).isEmpty;
                                                                    final remoteName = remoteNameAsync.valueOrNull ?? "origin";
                                                                    final syncOptionsSnapshot = _buildSyncOptions(
                                                                      clientModeEnabled: clientModeEnabledValue ?? false,
                                                                      noRemotes: noRemotes,
                                                                      dirPath: gitDirPath?.$1,
                                                                      submodulePaths: submodulePathsAsync.valueOrNull ?? [],
                                                                      remoteName: remoteName,
                                                                      hasConflicts: (conflictingAsync.valueOrNull ?? []).isNotEmpty,
                                                                      repomanRepoindex: repoIndexAsync.valueOrNull ?? 0,
                                                                    );
                                                                    final lastSyncMethod = getLastSyncOption(recommendedActionValue);
                                                                    return Column(
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
                                                                                    onPressed: gitDirPath?.$2 == null
                                                                                        ? null
                                                                                        : () async {
                                                                                            if (syncOptionsSnapshot.isEmpty) return;

                                                                                            if (syncOptionsSnapshot.containsKey(
                                                                                                  lastSyncMethod,
                                                                                                ) ==
                                                                                                true) {
                                                                                              syncOptionsSnapshot[lastSyncMethod]!.$2();
                                                                                            } else {
                                                                                              await syncOptionsSnapshot.values.first.$2();
                                                                                            }
                                                                                          },
                                                                                    style: ButtonStyle(
                                                                                      alignment: Alignment.centerLeft,
                                                                                      backgroundColor: WidgetStatePropertyAll(colours.secondaryDark),
                                                                                      padding: WidgetStatePropertyAll(
                                                                                        EdgeInsets.symmetric(horizontal: spaceMD),
                                                                                      ),
                                                                                      shape: WidgetStatePropertyAll(
                                                                                        RoundedRectangleBorder(
                                                                                          borderRadius: orientation == Orientation.portrait
                                                                                              ? BorderRadius.only(
                                                                                                  topLeft: cornerRadiusSM,
                                                                                                  topRight: cornerRadiusSM,
                                                                                                  bottomLeft: cornerRadiusMD,
                                                                                                  bottomRight: clientModeEnabledValue == true
                                                                                                      ? cornerRadiusMD
                                                                                                      : cornerRadiusSM,
                                                                                                )
                                                                                              : BorderRadius.only(
                                                                                                  topLeft: cornerRadiusMD,
                                                                                                  bottomRight: cornerRadiusSM,
                                                                                                  bottomLeft: cornerRadiusSM,
                                                                                                  topRight: clientModeEnabledValue == true
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
                                                                                        if (clientModeEnabledValue == true)
                                                                                          Positioned(
                                                                                            top: -spaceXXS,
                                                                                            bottom: -spaceXXS,
                                                                                            left: -spaceXXS,
                                                                                            right: -spaceXXS,
                                                                                            child: ProviderBuilder<int?>(
                                                                                              provider: recommendedActionProvider,
                                                                                              builder: (context, value) => value.isLoading
                                                                                                  ? CircularProgressIndicator(
                                                                                                      color: colours.tertiaryDark,
                                                                                                    )
                                                                                                  : SizedBox.shrink(),
                                                                                            ),
                                                                                          ),
                                                                                        SizedBox(
                                                                                          height: textLG,
                                                                                          width: textLG,
                                                                                          child: Center(
                                                                                            child: FaIcon(
                                                                                              gitDirPath?.$2 == null
                                                                                                  ? FontAwesomeIcons.solidCircleDown
                                                                                                  : syncOptionsSnapshot[lastSyncMethod]
                                                                                                            ?.$1 ??
                                                                                                        (syncOptionsSnapshot.values.isNotEmpty
                                                                                                            ? syncOptionsSnapshot.values.first.$1
                                                                                                            : null) ??
                                                                                                        FontAwesomeIcons.solidCircleDown,
                                                                                              color: gitDirPath?.$2 == null
                                                                                                  ? colours.secondaryLight
                                                                                                  : colours.primaryLight,
                                                                                              size: textLG,
                                                                                            ),
                                                                                          ),
                                                                                        ),
                                                                                      ],
                                                                                    ),
                                                                                    label: Padding(
                                                                                      padding: EdgeInsets.only(left: spaceXS),
                                                                                      child: Text(
                                                                                        (gitDirPath?.$2 == null
                                                                                                ? (clientModeEnabledValue == true
                                                                                                      ? t.syncAllChanges
                                                                                                      : t.syncNow)
                                                                                                : ((syncOptionsSnapshot.containsKey(
                                                                                                                lastSyncMethod,
                                                                                                              ) ==
                                                                                                              true
                                                                                                          ? lastSyncMethod
                                                                                                          : (syncOptionsSnapshot.keys.isNotEmpty
                                                                                                                ? syncOptionsSnapshot.keys.first
                                                                                                                : (clientModeEnabledValue == true
                                                                                                                      ? t.syncAllChanges
                                                                                                                      : t.syncNow))) ??
                                                                                                      t.syncNow))
                                                                                            .toUpperCase(),
                                                                                        style: TextStyle(
                                                                                          color: gitDirPath?.$2 == null
                                                                                              ? colours.secondaryLight
                                                                                              : (clientModeEnabledValue == true &&
                                                                                                        recommendedActionValue != null &&
                                                                                                        recommendedActionValue >= 0
                                                                                                    ? colours.tertiaryInfo
                                                                                                    : colours.primaryLight),
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
                                                                                    onPressed: gitDirPath?.$2 == null
                                                                                        ? null
                                                                                        : () async {
                                                                                            if (demo) {
                                                                                              demoConflicting = true;
                                                                                              await reloadAll();
                                                                                              MergeConflictDialog.showDialog(context, [
                                                                                                ("Readme.md", GitManagerRs.ConflictType.text),
                                                                                              ]).then((_) async {
                                                                                                demoConflicting = false;
                                                                                                await reloadAll();
                                                                                              });

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

                                                                                            searchForGestureDetector(
                                                                                              syncMethodsDropdownKey.currentContext,
                                                                                            );

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
                                                                                                  bottomRight: clientModeEnabledValue == true
                                                                                                      ? cornerRadiusMD
                                                                                                      : cornerRadiusSM,
                                                                                                )
                                                                                              : BorderRadius.only(
                                                                                                  topLeft: cornerRadiusMD,
                                                                                                  bottomRight: cornerRadiusSM,
                                                                                                  bottomLeft: cornerRadiusSM,
                                                                                                  topRight: clientModeEnabledValue == true
                                                                                                      ? cornerRadiusMD
                                                                                                      : cornerRadiusSM,
                                                                                                ),
                                                                                          side: BorderSide.none,
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                    icon: FaIcon(
                                                                                      FontAwesomeIcons.ellipsis,
                                                                                      color: gitDirPath?.$2 == null
                                                                                          ? colours.secondaryLight
                                                                                          : colours.primaryLight,
                                                                                      size: textLG,
                                                                                      semanticLabel: t.moreSyncOptionsLabel,
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                          SizedBox(width: spaceSM),
                                                                          IconButton(
                                                                            onPressed: () {
                                                                              _openSettingsMain();
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
                                                                          ProviderBuilder<bool>(
                                                                            provider: syncMessageEnabledProvider,
                                                                            builder: (context, syncMsgEnabledAsync) {
                                                                              final syncMsgEnabled = syncMsgEnabledAsync.valueOrNull;
                                                                              return IconButton(
                                                                                onPressed: () async {
                                                                                  if (!(syncMsgEnabled ?? false)) {
                                                                                    if (!(await Permission.notification.request().isGranted)) return;
                                                                                  }

                                                                                  ref
                                                                                      .read(syncMessageEnabledProvider.notifier)
                                                                                      .set(!(syncMsgEnabled ?? false));
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
                                                                                      demo || syncMsgEnabled == true
                                                                                          ? FontAwesomeIcons.solidBell
                                                                                          : FontAwesomeIcons.solidBellSlash,
                                                                                      color: demo || syncMsgEnabled == true
                                                                                          ? colours.primaryPositive
                                                                                          : colours.primaryLight,
                                                                                      size: textLG - 2,
                                                                                      semanticLabel: t.syncMessagesLabel,
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              );
                                                                            },
                                                                          ),
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
                                                                                  (syncOptionsSnapshot.containsKey(lastSyncMethod) ==
                                                                                          true
                                                                                      ? lastSyncMethod
                                                                                      : (syncOptionsSnapshot.keys.isNotEmpty
                                                                                            ? syncOptionsSnapshot.keys.first
                                                                                            : "")),
                                                                            )
                                                                            .map(
                                                                              (item) => DropdownMenuItem(
                                                                                onTap: () async {
                                                                                  if (![
                                                                                    t.switchToClientMode,
                                                                                    t.switchToSyncMode,
                                                                                  ].contains(item.key)) {
                                                                                    ref.read(lastSyncMethodProvider.notifier).set(item.key);
                                                                                  }

                                                                                  await item.value.$2();
                                                                                },
                                                                                value: item.key,
                                                                                child: Row(
                                                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                                                  children: [
                                                                                    FaIcon(
                                                                                      item.value.$1,
                                                                                      color:
                                                                                          [
                                                                                            t.switchToClientMode,
                                                                                            t.switchToSyncMode,
                                                                                          ].contains(item.key)
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
                                                                                          color:
                                                                                              [
                                                                                                t.switchToClientMode,
                                                                                                t.switchToSyncMode,
                                                                                              ].contains(item.key)
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
                                                                );
                                                                  },
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: spaceLG, width: spaceMD),

                                      Expanded(
                                        flex: orientation == Orientation.portrait ? 0 : 1,
                                        child: ProviderBuilder<bool>(
                                          provider: isAuthenticatedProvider,
                                          builder: (context, isAuthenticatedAsync) =>
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
                                                  first: true,
                                                  richContent: ShowcaseTooltipContent(
                                                    title: t.showcaseRepoTitle,
                                                    subtitle: t.showcaseRepoSubtitle,
                                                    featureRows: [
                                                      ShowcaseFeatureRow(icon: FontAwesomeIcons.key, text: t.showcaseRepoFeatureAuth),
                                                      ShowcaseFeatureRow(icon: FontAwesomeIcons.folderOpen, text: t.showcaseRepoFeatureDir),
                                                      ShowcaseFeatureRow(icon: FontAwesomeIcons.filePen, text: t.showcaseRepoFeatureBrowse),
                                                      ShowcaseFeatureRow(icon: FontAwesomeIcons.link, text: t.showcaseRepoFeatureRemote),
                                                    ],
                                                  ),
                                                  child: ProviderBuilder<(String, String)?>(
                                                    provider: gitDirPathProvider,
                                                    builder: (context, gitDirPathAsync) {
                                                      final gitDirPath = gitDirPathAsync.valueOrNull;
                                                      return Column(
                                                        children: [
                                                          IntrinsicHeight(
                                                            child: Row(
                                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                                              children: [
                                                                ProviderBuilder<(String, String)?>(
                                                                  provider: remoteUrlLinkProvider,
                                                                  builder: (context, remoteUrlLinkAsync) => ProviderBuilder<List<String>>(
                                                                    provider: listRemotesProvider,
                                                                    builder: (context, remotesAsync) {
                                                                      final remoteUrlLinkValue = remoteUrlLinkAsync.valueOrNull;
                                                                      final remotesList = remotesAsync.valueOrNull ?? [];
                                                                      final actions = remoteEllipsisActions(remotesList.length);
                                                                      return FutureBuilder<String>(
                                                                        future: uiSettingsManager.getRemote(),
                                                                        builder: (context, currentRemoteSnapshot) {
                                                                          final currentRemoteName = currentRemoteSnapshot.data;
                                                                          final hasDir = gitDirPath?.$1 != null;
                                                                          final noRemoteWithDir = remotesList.isEmpty && hasDir;
                                                                          // Build dropdown items: "Add Remote" first, then each remote name
                                                                          final dropdownItems = <DropdownMenuItem<String>>[
                                                                            DropdownMenuItem(
                                                                              value: "__add_remote__",
                                                                              child: Row(
                                                                                children: [
                                                                                  FaIcon(
                                                                                    FontAwesomeIcons.plus,
                                                                                    color: colours.primaryPositive,
                                                                                    size: textMD,
                                                                                  ),
                                                                                  SizedBox(width: spaceSM),
                                                                                  Text(
                                                                                    t.addRemote.toUpperCase(),
                                                                                    style: TextStyle(
                                                                                      fontSize: textXS,
                                                                                      color: colours.primaryLight,
                                                                                      fontWeight: FontWeight.bold,
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                            ...remotesList.map(
                                                                              (name) => DropdownMenuItem(
                                                                                value: name,
                                                                                child: name == currentRemoteName && remoteUrlLinkValue != null
                                                                                    ? Row(
                                                                                        children: [
                                                                                          Text(
                                                                                            name.toUpperCase(),
                                                                                            style: TextStyle(
                                                                                              fontSize: textXS,
                                                                                              color: colours.primaryLight,
                                                                                              fontWeight: FontWeight.bold,
                                                                                            ),
                                                                                          ),
                                                                                          Text(
                                                                                            " · ",
                                                                                            style: TextStyle(
                                                                                              fontSize: textXS,
                                                                                              color: colours.tertiaryLight,
                                                                                            ),
                                                                                          ),
                                                                                          Flexible(
                                                                                            child: Text(
                                                                                              remoteUrlLinkValue.$1,
                                                                                              style: TextStyle(
                                                                                                fontSize: textXS,
                                                                                                color: colours.tertiaryLight,
                                                                                                fontWeight: FontWeight.w400,
                                                                                              ),
                                                                                              overflow: TextOverflow.ellipsis,
                                                                                              maxLines: 1,
                                                                                            ),
                                                                                          ),
                                                                                        ],
                                                                                      )
                                                                                    : Text(
                                                                                        name.toUpperCase(),
                                                                                        style: TextStyle(
                                                                                          fontSize: textXS,
                                                                                          color: colours.primaryLight,
                                                                                          fontWeight: FontWeight.bold,
                                                                                        ),
                                                                                      ),
                                                                              ),
                                                                            ),
                                                                          ];
                                                                          return Expanded(
                                                                            child: Row(
                                                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                                                              children: [
                                                                                Expanded(
                                                                                  child: Stack(
                                                                                    children: [
                                                                                      if (noRemoteWithDir)
                                                                                        GestureDetector(
                                                                                          onTap: () async {
                                                                                            final provider = ref
                                                                                                .read(gitProviderProvider)
                                                                                                .valueOrNull;
                                                                                            final hasOAuth = provider?.isOAuthProvider == true;
                                                                                            await AddRemoteDialog.showDialog(
                                                                                              context,
                                                                                              (name, url) async {
                                                                                                await runGitOperation(
                                                                                                  LogType.AddRemote,
                                                                                                  (event) => event,
                                                                                                  {"name": name, "url": url},
                                                                                                );
                                                                                                await uiSettingsManager.setStringNullable(
                                                                                                  StorageKey.setman_remote,
                                                                                                  name,
                                                                                                );
                                                                                                await reloadAll();
                                                                                              },
                                                                                              oauthProviderName: hasOAuth ? provider!.name : null,
                                                                                              onCreateRemote: hasOAuth
                                                                                                  ? () async {
                                                                                                      final dirPath = ref
                                                                                                          .read(gitDirPathProvider)
                                                                                                          .valueOrNull
                                                                                                          ?.$1;
                                                                                                      if (dirPath != null) {
                                                                                                        await offerCreateRemoteForExistingRepo(
                                                                                                          context,
                                                                                                          dirPath,
                                                                                                        );
                                                                                                        await reloadAll();
                                                                                                      }
                                                                                                    }
                                                                                                  : null,
                                                                                            );
                                                                                          },
                                                                                          child: Container(
                                                                                            padding: EdgeInsets.only(
                                                                                              left: spaceMD,
                                                                                              right: 0,
                                                                                              top: 1,
                                                                                              bottom: 1,
                                                                                            ),
                                                                                            decoration: BoxDecoration(
                                                                                              color: colours.secondaryDark,
                                                                                              borderRadius: BorderRadius.all(cornerRadiusMD),
                                                                                            ),
                                                                                            child: Row(
                                                                                              children: [
                                                                                                Expanded(
                                                                                                  child: Padding(
                                                                                                    padding: EdgeInsets.symmetric(
                                                                                                      vertical: spaceSM + spaceXXXS,
                                                                                                    ),
                                                                                                    child: Text(
                                                                                                      t.addRemote,
                                                                                                      maxLines: 1,
                                                                                                      overflow: TextOverflow.ellipsis,
                                                                                                      style: TextStyle(
                                                                                                        color: colours.primaryLight,
                                                                                                        fontSize: textMD,
                                                                                                        fontWeight: FontWeight.w400,
                                                                                                      ),
                                                                                                    ),
                                                                                                  ),
                                                                                                ),
                                                                                                Padding(
                                                                                                  padding: EdgeInsets.only(
                                                                                                    left: spaceSM,
                                                                                                    right: spaceMD,
                                                                                                  ),
                                                                                                  child: FaIcon(
                                                                                                    FontAwesomeIcons.plus,
                                                                                                    color: colours.primaryLight,
                                                                                                    size: textLG,
                                                                                                  ),
                                                                                                ),
                                                                                              ],
                                                                                            ),
                                                                                          ),
                                                                                        )
                                                                                      else
                                                                                        Container(
                                                                                          padding: EdgeInsets.zero,
                                                                                          decoration: BoxDecoration(
                                                                                            color: colours.secondaryDark,
                                                                                            borderRadius: remotesList.isEmpty
                                                                                                ? BorderRadius.all(cornerRadiusMD)
                                                                                                : BorderRadius.only(
                                                                                                    topLeft: cornerRadiusMD,
                                                                                                    bottomLeft: cornerRadiusMD,
                                                                                                    topRight: Radius.zero,
                                                                                                    bottomRight: Radius.zero,
                                                                                                  ),
                                                                                          ),
                                                                                          child: DropdownButton<String>(
                                                                                            borderRadius: BorderRadius.all(cornerRadiusMD),
                                                                                            padding: EdgeInsets.only(
                                                                                              left: spaceMD,
                                                                                              right: remotesList.isEmpty ? spaceMD : 0,
                                                                                              top: 1,
                                                                                              bottom: 1,
                                                                                            ),

                                                                                            onTap: () {
                                                                                              if (demo) {
                                                                                                ManualSyncDialog.showDialog(
                                                                                                  context,
                                                                                                  hasRemotes:
                                                                                                      (ref.read(listRemotesProvider).valueOrNull ??
                                                                                                              [])
                                                                                                          .isNotEmpty,
                                                                                                ).then((_) => reloadAll());
                                                                                                return;
                                                                                              }
                                                                                            },
                                                                                            icon: Padding(
                                                                                              padding: EdgeInsets.only(left: spaceSM),
                                                                                              child: FaIcon(
                                                                                                remoteUrlLinkValue != null
                                                                                                    ? FontAwesomeIcons.caretDown
                                                                                                    : FontAwesomeIcons.solidCircleXmark,
                                                                                                color: remoteUrlLinkValue != null
                                                                                                    ? colours.secondaryLight
                                                                                                    : colours.tertiaryLight,
                                                                                                size: textLG,
                                                                                              ),
                                                                                            ),
                                                                                            value:
                                                                                                currentRemoteName != null &&
                                                                                                    remotesList.contains(currentRemoteName)
                                                                                                ? currentRemoteName
                                                                                                : null,
                                                                                            isExpanded: true,
                                                                                            underline: const SizedBox.shrink(),
                                                                                            dropdownColor: colours.secondaryDark,
                                                                                            hint: Text(
                                                                                              t.repoNotFound,
                                                                                              maxLines: 1,
                                                                                              overflow: TextOverflow.ellipsis,
                                                                                              style: TextStyle(
                                                                                                color: colours.secondaryLight,
                                                                                                fontSize: textMD,
                                                                                                fontWeight: FontWeight.w400,
                                                                                              ),
                                                                                            ),
                                                                                            onChanged: (gitDirPath?.$2 == null)
                                                                                                ? null
                                                                                                : (value) async {
                                                                                                    if (value == "__add_remote__") {
                                                                                                      await AddRemoteDialog.showDialog(context, (
                                                                                                        name,
                                                                                                        url,
                                                                                                      ) async {
                                                                                                        await runGitOperation(
                                                                                                          LogType.AddRemote,
                                                                                                          (event) => event,
                                                                                                          {"name": name, "url": url},
                                                                                                        );
                                                                                                        await uiSettingsManager.setStringNullable(
                                                                                                          StorageKey.setman_remote,
                                                                                                          name,
                                                                                                        );
                                                                                                        await reloadAll();
                                                                                                      });
                                                                                                      return;
                                                                                                    }
                                                                                                    if (value != null) {
                                                                                                      await uiSettingsManager.setStringNullable(
                                                                                                        StorageKey.setman_remote,
                                                                                                        value,
                                                                                                      );
                                                                                                      await reloadAll();
                                                                                                    }
                                                                                                  },
                                                                                            selectedItemBuilder: (context) => List.generate(
                                                                                              dropdownItems.length,
                                                                                              (index) => Row(
                                                                                                children: [
                                                                                                  Expanded(
                                                                                                    child: ExtendedText(
                                                                                                      demo
                                                                                                          ? "https://github.com/ViscousTests/TestObsidianVault.git"
                                                                                                          : (remoteUrlLinkValue == null
                                                                                                                ? t.repoNotFound
                                                                                                                : remoteUrlLinkValue.$1),
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
                                                                                            items: dropdownItems,
                                                                                          ),
                                                                                        ),
                                                                                      Positioned(
                                                                                        top: spaceXXXXS / 2,
                                                                                        left: spaceSM,
                                                                                        child: Text(
                                                                                          "${t.remote}${currentRemoteName != null ? " · $currentRemoteName" : ""}"
                                                                                              .toUpperCase(),
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
                                                                                if (remotesList.isNotEmpty)
                                                                                  Container(
                                                                                    decoration: BoxDecoration(
                                                                                      color: colours.secondaryDark,
                                                                                      borderRadius: BorderRadius.only(
                                                                                        topRight: cornerRadiusMD,
                                                                                        bottomRight: cornerRadiusMD,
                                                                                        topLeft: Radius.zero,
                                                                                        bottomLeft: Radius.zero,
                                                                                      ),
                                                                                    ),
                                                                                    child: PopupMenuButton<int>(
                                                                                      icon: Padding(
                                                                                        padding: EdgeInsets.symmetric(horizontal: spaceXS),
                                                                                        child: FaIcon(
                                                                                          FontAwesomeIcons.ellipsisVertical,
                                                                                          color: colours.secondaryLight,
                                                                                          size: textLG,
                                                                                        ),
                                                                                      ),
                                                                                      color: colours.secondaryDark,
                                                                                      shape: RoundedRectangleBorder(
                                                                                        borderRadius: BorderRadius.all(cornerRadiusMD),
                                                                                      ),
                                                                                      onSelected: (index) async {
                                                                                        await actions[index].$2(context, remoteUrlLinkValue);
                                                                                        await reloadAll();
                                                                                      },
                                                                                      itemBuilder: (context) => List.generate(
                                                                                        actions.length,
                                                                                        (index) => PopupMenuItem(
                                                                                          value: index,
                                                                                          enabled: actions[index].$3,
                                                                                          child: Row(
                                                                                            children: [
                                                                                              actions[index].$1.$2,
                                                                                              SizedBox(width: spaceSM),
                                                                                              Text(
                                                                                                actions[index].$1.$1.toUpperCase(),
                                                                                                style: TextStyle(
                                                                                                  fontSize: textXS,
                                                                                                  color: actions[index].$3
                                                                                                      ? colours.primaryLight
                                                                                                      : colours.tertiaryLight,
                                                                                                  fontWeight: FontWeight.bold,
                                                                                                ),
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                              ],
                                                                            ),
                                                                          );
                                                                        },
                                                                      );
                                                                    },
                                                                  ),
                                                                ),
                                                                SizedBox(width: gitDirPath?.$2 == null ? spaceSM : 0),
                                                                Visibility(
                                                                  visible: gitDirPath?.$2 == null,
                                                                  child: AnimatedBuilder(
                                                                    animation: _pulseAnimation,
                                                                    builder: (context, child) => TextButton.icon(
                                                                      onPressed: () async {
                                                                        await showCloneRepoPage();
                                                                      },
                                                                      style: ButtonStyle(
                                                                        backgroundColor: WidgetStatePropertyAll(colours.secondaryDark),
                                                                        padding: WidgetStatePropertyAll(
                                                                          EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceMD),
                                                                        ),
                                                                        shape: WidgetStatePropertyAll(
                                                                          RoundedRectangleBorder(
                                                                            borderRadius: BorderRadius.all(cornerRadiusMD),
                                                                            side: gitDirPath?.$2 == null
                                                                                ? BorderSide(
                                                                                    color: colours.tertiaryInfo.withAlpha(
                                                                                      isAuthenticatedAsync.valueOrNull != true
                                                                                          ? _pulseAnimation.value.toInt()
                                                                                          : 120,
                                                                                    ),
                                                                                    width: 2,
                                                                                    strokeAlign: BorderSide.strokeAlignInside,
                                                                                  )
                                                                                : BorderSide.none,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      icon: FaIcon(
                                                                        FontAwesomeIcons.cloudArrowDown,
                                                                        color: colours.primaryLight,
                                                                        size: textLG - 2,
                                                                      ),
                                                                      iconAlignment: IconAlignment.start,
                                                                      label: Padding(
                                                                        padding: EdgeInsets.only(left: spaceXS),
                                                                        child: Text(
                                                                          t.clone.toUpperCase(),
                                                                          style: TextStyle(
                                                                            color: colours.primaryLight,
                                                                            fontSize: textMD,
                                                                            fontWeight: FontWeight.bold,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                SizedBox(width: spaceSM),
                                                                Container(
                                                                  decoration: BoxDecoration(
                                                                    borderRadius: BorderRadius.all(cornerRadiusMD),
                                                                    color: colours.secondaryDark,
                                                                  ),
                                                                  child: Row(
                                                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                                                    children: [
                                                                      AnimatedBuilder(
                                                                        animation: _pulseAnimation,
                                                                        builder: (context, child) => TextButton.icon(
                                                                          onPressed: () async {
                                                                            await showAuthDialog();
                                                                          },
                                                                          style: ButtonStyle(
                                                                            alignment: Alignment.centerLeft,
                                                                            backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                                                                            padding: WidgetStatePropertyAll(
                                                                              EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceMD),
                                                                            ),
                                                                            shape: WidgetStatePropertyAll(
                                                                              RoundedRectangleBorder(
                                                                                borderRadius: BorderRadius.all(cornerRadiusMD),
                                                                                side: isAuthenticatedAsync.valueOrNull != true
                                                                                    ? BorderSide(
                                                                                        color: colours.tertiaryNegative.withAlpha(
                                                                                          gitDirPath?.$2 == null
                                                                                              ? _pulseAnimation.value.toInt()
                                                                                              : 120,
                                                                                        ),
                                                                                        width: 2,
                                                                                        strokeAlign: BorderSide.strokeAlignInside,
                                                                                      )
                                                                                    : BorderSide.none,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          icon: FaIcon(
                                                                            isAuthenticatedAsync.valueOrNull == true
                                                                                ? FontAwesomeIcons.solidCircleCheck
                                                                                : FontAwesomeIcons.solidCircleXmark,
                                                                            color: isAuthenticatedAsync.valueOrNull == true
                                                                                ? colours.primaryPositive
                                                                                : colours.primaryNegative,
                                                                            size: textLG,
                                                                          ),
                                                                          label: Padding(
                                                                            padding: EdgeInsets.only(left: spaceXS),
                                                                            child: Text(
                                                                              t.auth.toUpperCase(),
                                                                              style: TextStyle(
                                                                                color: colours.primaryLight,
                                                                                fontSize: textMD,
                                                                                fontWeight: FontWeight.bold,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),

                                                                      Consumer(
                                                                        builder: (context, ref, _) =>
                                                                            !((ref.watch(gitProviderProvider).valueOrNull ?? GitProvider.GITHUB) ==
                                                                                    GitProvider.GITHUB &&
                                                                                (ref.watch(githubScopedOauthProvider).valueOrNull ?? false))
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

                                                                                  final usernameToken = await uiSettingsManager
                                                                                      .getGitHttpAuthCredentials();

                                                                                  final token = await gitProviderManager.getToken(
                                                                                    usernameToken.$2,
                                                                                    (_, _, _) async {},
                                                                                  );

                                                                                  if (token == null) return;

                                                                                  final githubAppInstallations = await gitProviderManager
                                                                                      .getGitHubAppInstallations(token);
                                                                                  if (githubAppInstallations.isEmpty) {
                                                                                    await launchUrl(
                                                                                      Uri.parse(githubAppsLink),
                                                                                      mode: LaunchMode.inAppBrowserView,
                                                                                    );
                                                                                  } else {
                                                                                    await launchUrl(
                                                                                      Uri.parse(
                                                                                        "https://github.com/settings/installations/${githubAppInstallations[0]["id"]}",
                                                                                      ),
                                                                                      mode: LaunchMode.inAppBrowserView,
                                                                                    );
                                                                                  }
                                                                                },
                                                                                icon: FaIcon(
                                                                                  FontAwesomeIcons.sliders,
                                                                                  size: textLG,
                                                                                  color: colours.secondaryLight,
                                                                                ),
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
                                                                                      : (gitDirPath?.$2 == null
                                                                                            ? t.repoNotFound
                                                                                            : (Platform.isIOS
                                                                                                      ? gitDirPath?.$2.split("/").last
                                                                                                      : gitDirPath?.$2) ??
                                                                                                  ""),
                                                                                  maxLines: 1,
                                                                                  textAlign: TextAlign.left,
                                                                                  softWrap: false,
                                                                                  overflowWidget: TextOverflowWidget(
                                                                                    position: TextOverflowPosition.start,
                                                                                    child: Text(
                                                                                      "…",
                                                                                      style: TextStyle(
                                                                                        color: gitDirPath?.$2 == null
                                                                                            ? colours.secondaryLight
                                                                                            : colours.primaryLight,
                                                                                        fontSize: textMD,
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                  style: TextStyle(
                                                                                    color: gitDirPath?.$2 == null
                                                                                        ? colours.secondaryLight
                                                                                        : colours.primaryLight,
                                                                                    fontSize: textMD,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            gitDirPath?.$2 == null
                                                                                ? SizedBox.shrink()
                                                                                : IconButton(
                                                                                    onPressed: () async {
                                                                                      ref.read(gitDirPathProvider.notifier).set(null);
                                                                                      ref.read(branchNameProvider.notifier).set(null);
                                                                                      ref.read(remoteUrlLinkProvider.notifier).set(null);
                                                                                      ref.read(listRemotesProvider.notifier).set([]);
                                                                                      ref.read(gitProviderProvider.notifier).set(GitProvider.GITHUB);
                                                                                      ref.read(recommendedActionProvider.notifier).set(null);
                                                                                      ref.read(branchNamesProvider.notifier).set({});
                                                                                      ref.read(hasGitFiltersProvider.notifier).set(false);
                                                                                      ref.read(recentCommitsProvider.notifier).set([]);
                                                                                      ref.read(conflictingFilesProvider.notifier).set([]);
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
                                                                SizedBox(width: spaceSM),
                                                                AnimatedBuilder(
                                                                  animation: _pulseAnimation,
                                                                  builder: (context, child) => IconButton(
                                                                    onPressed: () async {
                                                                      String? selectedDirectory;
                                                                      if (await requestStoragePerm()) {
                                                                        selectedDirectory = await pickDirectory();
                                                                      }
                                                                      if (selectedDirectory == null) return;

                                                                      if (!mounted) return;
                                                                      final isRepo = await validateOrInitGitDir(context, selectedDirectory);
                                                                      if (!isRepo) return;

                                                                      if (!mounted) return;
                                                                      await setGitDirPathGetSubmodules(context, selectedDirectory, ref);
                                                                      await reloadAll();
                                                                    },
                                                                    style: ButtonStyle(
                                                                      backgroundColor: WidgetStatePropertyAll(colours.secondaryDark),
                                                                      padding: WidgetStatePropertyAll(
                                                                        EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceMD),
                                                                      ),
                                                                      shape: WidgetStatePropertyAll(
                                                                        RoundedRectangleBorder(
                                                                          borderRadius: BorderRadius.only(
                                                                            bottomLeft: cornerRadiusSM,
                                                                            bottomRight: cornerRadiusMD,
                                                                            topLeft: cornerRadiusSM,
                                                                            topRight: cornerRadiusMD,
                                                                          ),
                                                                          side: gitDirPath?.$2 == null
                                                                              ? BorderSide(
                                                                                  color: colours.tertiaryInfo.withAlpha(
                                                                                    isAuthenticatedAsync.valueOrNull != true
                                                                                        ? _pulseAnimation.value.toInt()
                                                                                        : 120,
                                                                                  ),
                                                                                  width: 2,
                                                                                  strokeAlign: BorderSide.strokeAlignInside,
                                                                                )
                                                                              : BorderSide.none,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    icon: FaIcon(
                                                                      FontAwesomeIcons.solidFolderOpen,
                                                                      color: colours.primaryLight,
                                                                      size: textLG - 2,
                                                                      semanticLabel: t.selectDirLabel,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  ),
                                                ),

                                                SizedBox(height: spaceLG),
                                                ...clientModeEnabledValue == true
                                                    ? [
                                                        TextButton.icon(
                                                          onPressed: () async {
                                                            _homeNavigatorKey.currentState
                                                                ?.push(createSyncSettingsMainRoute())
                                                                .then((_) => reloadAll());
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
                                                          cornerRadius: cornerRadiusMD,
                                                          richContent: ShowcaseTooltipContent(
                                                            title: t.showcaseAutoSyncTitle,
                                                            subtitle: t.showcaseAutoSyncSubtitle,
                                                            featureRows: [
                                                              ShowcaseFeatureRow(
                                                                icon: FontAwesomeIcons.solidBell,
                                                                text: t.showcaseAutoSyncFeatureApp,
                                                              ),
                                                              ShowcaseFeatureRow(
                                                                icon: FontAwesomeIcons.clockRotateLeft,
                                                                text: t.showcaseAutoSyncFeatureSchedule,
                                                              ),
                                                              ShowcaseFeatureRow(
                                                                icon: FontAwesomeIcons.barsStaggered,
                                                                text: t.showcaseAutoSyncFeatureQuick,
                                                              ),
                                                              ShowcaseFeatureRow(
                                                                icon: FontAwesomeIcons.solidGem,
                                                                text: t.showcaseAutoSyncFeaturePremium,
                                                              ),
                                                            ],
                                                          ),
                                                          targetPadding: EdgeInsets.all(spaceSM),
                                                          customTooltipActions: [
                                                            TooltipActionButton(
                                                              backgroundColor: colours.secondaryInfo,
                                                              textStyle: TextStyle(
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: textSM,
                                                                color: colours.primaryLight,
                                                              ),
                                                              leadIcon: ActionButtonIcon(
                                                                icon: FaIcon(
                                                                  FontAwesomeIcons.solidFileLines,
                                                                  color: colours.primaryLight,
                                                                  size: textSM,
                                                                ),
                                                              ),
                                                              name: t.learnMore.toUpperCase(),
                                                              onTap: () => launchUrl(Uri.parse(syncOptionsBGDocsLink)),
                                                              type: null,
                                                              borderRadius: BorderRadius.all(cornerRadiusMD),
                                                              padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceXS),
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
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _KeepAlivePage(child: _buildFilesTab()),
              ],
            ),
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: aiFeaturesEnabled,
                builder: (context, aiEnabled, _) => ValueListenableBuilder(
                  valueListenable: _tabIndex,
                  builder: (context, currentTabIndex, _) => Theme(
                    data: Theme.of(context).copyWith(
                      navigationBarTheme: NavigationBarThemeData(
                        labelTextStyle: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return TextStyle(color: colours.tertiaryInfo, fontSize: textXS, fontWeight: FontWeight.bold);
                          }
                          return TextStyle(color: colours.secondaryLight, fontSize: textXS);
                        }),
                      ),
                    ),
                    child: NavigationBar(
                      selectedIndex: currentTabIndex.clamp(0, aiEnabled ? 2 : 1),
                      onDestinationSelected: (i) {
                        if (aiEnabled) {
                          if (i == 1 && _tabIndex.value == 1) {
                            _homeNavigatorKey.currentState?.popUntil((route) => route.isFirst);
                          } else if (i == 2 && _tabIndex.value == 2) {
                            _filesNavigatorKey.currentState?.popUntil((route) => route.isFirst);
                          } else {
                            _tabIndex.value = i;
                            _pageController.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                          }
                        } else {
                          if (i == 0 && _tabIndex.value == 0) {
                            _homeNavigatorKey.currentState?.popUntil((route) => route.isFirst);
                          } else if (i == 1 && _tabIndex.value == 1) {
                            _filesNavigatorKey.currentState?.popUntil((route) => route.isFirst);
                          } else {
                            _tabIndex.value = i;
                            _pageController.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                          }
                        }
                      },
                      backgroundColor: colours.secondaryDark,
                      indicatorColor: colours.tertiaryDark,
                      surfaceTintColor: Colors.transparent,
                      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                      height: 64,
                      destinations: [
                        if (aiEnabled)
                          NavigationDestination(
                            icon: FaIcon(FontAwesomeIcons.wandMagicSparkles, color: colours.secondaryLight, size: textLG),
                            selectedIcon: FaIcon(FontAwesomeIcons.wandMagicSparkles, color: colours.tertiaryInfo, size: textLG),
                            label: t.tabChat,
                          ),
                        NavigationDestination(
                          icon: FaIcon(FontAwesomeIcons.codeBranch, color: colours.secondaryLight, size: textLG),
                          selectedIcon: FaIcon(FontAwesomeIcons.codeBranch, color: colours.tertiaryInfo, size: textLG),
                          label: t.tabHome,
                        ),
                        NavigationDestination(
                          icon: FaIcon(FontAwesomeIcons.solidFolderOpen, color: colours.secondaryLight, size: textLG),
                          selectedIcon: FaIcon(FontAwesomeIcons.solidFolderOpen, color: colours.tertiaryInfo, size: textLG),
                          label: t.tabFiles,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ProviderBuilder<bool>(
                provider: hasGitFiltersProvider,
                builder: (context, hasFiltersAsync) => !(hasFiltersAsync.valueOrNull ?? false)
                    ? SizedBox.shrink()
                    : GestureDetector(
                        onTap: () => launchUrl(Uri.parse(playStoreLink)),
                        child: Container(
                          decoration: BoxDecoration(color: colours.tertiaryInfo),
                          padding: EdgeInsets.symmetric(vertical: spaceXXS, horizontal: spaceSM),
                          child: Center(
                            child: Text.rich(
                              textAlign: TextAlign.center,
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: t.unsupportedGitAttributes,
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(text: " "),
                                  TextSpan(text: t.tapToOpenPlayStore),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
              FutureBuilder(
                future: hasNetworkConnection(),
                builder: (context, snapshot) => snapshot.data == false
                    ? Container(
                        width: double.infinity,
                        decoration: BoxDecoration(color: colours.tertiaryNegative),
                        padding: EdgeInsets.symmetric(vertical: spaceXXS, horizontal: spaceSM),
                        child: Text.rich(
                          textAlign: TextAlign.center,
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
            ],
          ),
        ),
        devTools
            ? Positioned(
                left: spaceLG,
                bottom: spaceLG,
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colours.tertiaryDark,
                      borderRadius: BorderRadius.all(cornerRadiusSM),
                      border: BoxBorder.all(color: colours.secondaryDark, width: 2),
                    ),
                    child: ValueListenableBuilder(
                      valueListenable: queueValue,
                      builder: (context, queue, child) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: (queue.isEmpty ? ["-:QUEUE EMPTY:EMPTY QUEUE"] : queue).map((item) {
                          final parts = item.split(":");

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: spaceLG,
                                child: Center(
                                  child: Text(
                                    "${parts[0]}".trim(),
                                    textAlign: TextAlign.start,
                                    style: TextStyle(color: colours.tertiaryNegative, fontSize: textMD, decoration: TextDecoration.none),
                                  ),
                                ),
                              ),
                              Text(
                                "${parts[1]}".trim(),
                                style: TextStyle(color: colours.primaryLight, fontSize: textMD, decoration: TextDecoration.none),
                              ),
                              Text(
                                "${parts[2]}".trim(),
                                style: TextStyle(color: colours.secondaryLight, fontSize: textMD, decoration: TextDecoration.none),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              )
            : SizedBox.shrink(),
      ],
    );
  }
}

class _KeepAlivePage extends StatefulWidget {
  final Widget child;
  const _KeepAlivePage({required this.child});
  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _NestedNavigatorObserver extends NavigatorObserver {
  final ValueNotifier<bool> canPop;
  _NestedNavigatorObserver(this.canPop);

  void _update() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      canPop.value = navigator?.canPop() ?? false;
    });
  }

  @override
  void didPush(Route route, Route? previousRoute) => _update();
  @override
  void didPop(Route route, Route? previousRoute) => _update();
  @override
  void didRemove(Route route, Route? previousRoute) => _update();
  @override
  void didReplace({Route? newRoute, Route? oldRoute}) => _update();
}
