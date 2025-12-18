import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:GitSync/api/accessibility_service_helper.dart';
import 'package:GitSync/api/helper.dart';
import 'package:GitSync/api/manager/auth/github_manager.dart';
import 'package:GitSync/api/manager/git_manager.dart';
import 'package:GitSync/api/manager/settings_manager.dart';
import 'package:GitSync/main.dart';
import 'package:GitSync/type/git_provider.dart';
import 'package:GitSync/ui/dialog/github_issue_oauth.dart' as GithubIssueOauthDialog;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:GitSync/constant/strings.dart';
import 'package:GitSync/api/manager/storage.dart';
import 'package:http/http.dart' as http;
import 'package:mixin_logger/mixin_logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../global.dart';
import 'package:path_provider/path_provider.dart';
import 'package:GitSync/ui/dialog/error_occurred.dart' as ErrorOccurredDialog;

import '../ui/dialog/github_issue_report.dart' as GithubIssueReportDialog;
import '../ui/dialog/issue_reported_successfully.dart' as IssueReportedSuccessfullyDialog;

// Also add to rust/src/api/git_manager.rs:21
enum LogType {
  TEST,

  Global,
  AccessibilityService,
  Sync,
  GitStatus,
  AbortMerge,
  Commit,
  GetRepos,
  CloneRepo,
  SelectDirectory,
  PullFromRepo,
  PushToRepo,
  ForcePull,
  ForcePush,
  RecentCommits,
  Stage,
  SyncException,
}

enum From { GLOBAL_SETTINGS, ERROR_DIALOG, CODE_EDITOR, SYNC_DURING_DETACHED_HEAD }

void notificationClicked(NotificationResponse _) {
  Logger.notifClicked = true;
  runApp(const MyApp());
}

class Logger {
  static const int _errorNotificationId = 1757;
  static final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();
  static bool notifClicked = false;

  static Future<void> init() async {
    await notificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/launcher_icon'),
        iOS: DarwinInitializationSettings(requestSoundPermission: false, requestBadgePermission: false, requestAlertPermission: false),
      ),
      onDidReceiveNotificationResponse: notificationClicked,
      onDidReceiveBackgroundNotificationResponse: notificationClicked,
    );
  }

  static void log(dynamic message, {LogType type = LogType.TEST}) {
    i("${type.name}: ${message?.toString() ?? "null"}");
  }

  static void gmLog(dynamic message, {LogType type = LogType.TEST}) {
    w("${type.name}: ${message?.toString() ?? "null"}");
  }

  static void logError(LogType type, dynamic error, StackTrace stackTrace, {String? errorContent, bool causeError = true}) async {
    e("${type.name}: ${"${stackTrace.toString()}\nError: ${error.toString()}"}");
    if (!causeError) return;

    await repoManager.setStringNullable(StorageKey.repoman_erroring, errorContent ?? error.toString());
    await sendBugReportNotification(errorContent);
  }

  static Future<void> dismissError(BuildContext? context) async {
    debounce(dismissErrorDebounceReference, 500, () async {
      final error = await repoManager.getStringNullable(StorageKey.repoman_erroring);
      if (error == null) return;

      await repoManager.setStringNullable(StorageKey.repoman_erroring, null);
      try {
        await notificationsPlugin.cancel(_errorNotificationId);
      } catch (e) {}

      print(ErrorOccurredDialog.errorDialogKey.currentContext);

      if (ErrorOccurredDialog.errorDialogKey.currentContext != null) {
        Navigator.of(context ?? ErrorOccurredDialog.errorDialogKey.currentContext!).canPop()
            ? Navigator.pop(context ?? ErrorOccurredDialog.errorDialogKey.currentContext!)
            : null;
      }
      if (context == null) return;

      await ErrorOccurredDialog.showDialog(context, error, () => Logger.reportIssue(context, From.ERROR_DIALOG));
    });
  }

  static Future<void> sendBugReportNotification(String? contentText) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      gitSyncBugChannelId,
      gitSyncBugChannelName,
      icon: gitSyncIconRes,
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    await notificationsPlugin.show(_errorNotificationId, reportBug, contentText ?? reportABug, notificationDetails);
  }

  static Future<void> reportIssue(BuildContext context, From from) async {
    String? reportIssueToken = await repoManager.getStringNullable(StorageKey.repoman_reportIssueToken);
    if (reportIssueToken == "" || reportIssueToken == null) {
      SettingsManager tempSettingsManager = SettingsManager();
      await tempSettingsManager.reinit(repoIndex: 0);
      final provider = await tempSettingsManager.getGitProvider();
      if (provider == GitProvider.GITHUB) {
        reportIssueToken = (await tempSettingsManager.getGitHttpAuthCredentials()).$2;
      }
      uiSettingsManager.reinit();
    }

    if (reportIssueToken == "" || reportIssueToken == null) {
      await GithubIssueOauthDialog.showDialog(context, () async {
        final oauthManager = GithubManager();
        final result = (await oauthManager.launchOAuthFlow(["public_repo"]));
        await repoManager.setStringNullable(StorageKey.repoman_reportIssueToken, result?.$3 ?? null);
        reportIssueToken = await repoManager.getStringNullable(StorageKey.repoman_reportIssueToken);
      });
    }

    if (reportIssueToken == "" || reportIssueToken == null) return;

    await GithubIssueReportDialog.showDialog(context, (title, description, minimalRepro, includeLogFiles) async {
      final logs = !includeLogFiles
          ? ""
          : utf8.decode(utf8.encode((await _generateLogs()).split("\n").reversed.join("\n")).take(62 * 1024).toList(), allowMalformed: true);
      final deviceInfo = await generateDeviceInfo();

      final url = Uri.parse('https://api.github.com/repos/ViscousPot/GitSync/issues');

      final issueTitle = '[Bug]: (${Platform.isIOS ? "iOS" : "Android"}) $title';
      final issueBody =
          '''
### Description
$description

### Minimal Reproduction
$minimalRepro

### Exception or Error

<details>
<summary>Expand Logs (origin: ${from.name.toLowerCase()})</summary>

$deviceInfo

```
$logs
```

</details>
''';

      final response = await http.post(
        url,
        headers: {'Authorization': 'token $reportIssueToken', 'Accept': 'application/vnd.github+json'},
        body: jsonEncode({
          'title': issueTitle,
          'body': issueBody,
          'labels': ['bug'],
        }),
      );

      if (response.statusCode == 201) {
        print('Issue created successfully: ${response.statusCode} ${response.body}');
      } else {
        await repoManager.setStringNullable(StorageKey.repoman_reportIssueToken, null);
        print('Failed to create issue: ${response.statusCode} ${response.body}');
      }

      IssueReportedSuccessfullyDialog.showDialog(context, jsonDecode(response.body)["html_url"]);
    });
  }

  static Future<String> generateDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();

    String osVersion = '';
    String deviceModel = '';

    if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      osVersion = iosInfo.systemVersion;
      deviceModel = iosInfo.utsname.machine;
    } else {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      osVersion = '${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})';
      deviceModel = androidInfo.model;
    }

    String appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

    return """
**Platform:** ${Platform.isIOS ? "iOS" : "Android"}
**Device Model:** $deviceModel
**OS Version:** $osVersion
**App Version:** $appVersion

**Git Provider:** ${await uiSettingsManager.getStringNullable(StorageKey.setman_gitProvider)}
**Repo URL:** ${(await GitManager.getRemoteUrlLink())?.$1}

${await AccessibilityServiceHelper.isAccessibilityServiceEnabled() ? """
**App Sync**
**Package Names:** [${(await uiSettingsManager.getApplicationPackages()).join(", ")}]
**Sync on app opened:** ${(await uiSettingsManager.getBool(StorageKey.setman_syncOnAppOpened)) ? "🟢" : "⭕"}
**Sync on app closed&nbsp;&nbsp;:** ${(await uiSettingsManager.getBool(StorageKey.setman_syncOnAppClosed)) ? "🟢" : "⭕"}

""".trim() : ""}
${(await uiSettingsManager.getString(StorageKey.setman_schedule)).isNotEmpty ? """
**Scheduled Sync:** ${await uiSettingsManager.getString(StorageKey.setman_schedule)}

""".trim() : ""}

"""
        .trim();
  }

  static Future<String> _generateLogs() async {
    final Directory dir = await getTemporaryDirectory();
    final logsDir = Directory("${dir.path}/logs");

    final logFiles = <File>[];
    if (logsDir.existsSync()) {
      logFiles.addAll(logsDir.listSync().whereType<File>().where((f) => RegExp(r'log_(\d+)\.log$').hasMatch(f.path)));
    }

    File logFile;
    if (logFiles.isEmpty) {
      logFile = File("${logsDir.path}/log_0.log");
    } else {
      // pick file with largest numeric suffix
      final fileWithMax = logFiles.reduce((a, b) {
        final ma = RegExp(r'log_(\d+)\.log$').firstMatch(a.path)!.group(1)!;
        final mb = RegExp(r'log_(\d+)\.log$').firstMatch(b.path)!.group(1)!;
        final ia = int.parse(ma);
        final ib = int.parse(mb);
        return ia >= ib ? a : b;
      });
      logFile = File(fileWithMax.path);
    }
    final logsString = (await logFile.exists()) ? (await logFile.readAsLines()).join("\n") : "";
    return logsString;
  }
}
