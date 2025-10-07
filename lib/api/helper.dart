import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:GitSync/api/manager/git_manager.dart';
import 'package:GitSync/api/manager/settings_manager.dart';
import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/ui/dialog/unlock_premium.dart' as UnlockPremiumDialog show showDialog;
import 'package:GitSync/ui/page/code_editor.dart';
import 'package:cryptography/cryptography.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/api/logger.dart';
import 'package:GitSync/constant/strings.dart';
import 'package:GitSync/src/rust/api/git_manager.dart' as GitManagerRs;
import 'package:ios_document_picker/ios_document_picker.dart';
import 'package:ios_document_picker/types.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:GitSync/global.dart';
import '../constant/colors.dart';
import '../constant/dimens.dart';
import '../ui/dialog/submodules_found.dart' as SubmodulesFoundDialog;

const int mergeConflictNotificationId = 1758;
Map<String, Timer> debounceTimers = {};
Map<String, VoidCallback> _callbacks = {};

Future<void> initAsync(Future<void> Function() fn) async {
  await Future.delayed(Duration.zero, fn);
}

Future<bool> requestStoragePerm([bool request = true]) async {
  Future<void> gitManagerInit() async =>
      await GitManagerRs.init(homepath: Platform.isAndroid ? (await getApplicationDocumentsDirectory()).path : null);

  if (Platform.isIOS) {
    await gitManagerInit();
    return true;
  }

  AndroidDeviceInfo androidInfo = await DeviceInfoPlugin().androidInfo;
  if (androidInfo.version.sdkInt <= 29) {
    var storageRequest = Permission.storage;
    if (await (request ? storageRequest.request().isGranted : storageRequest.isGranted)) {
      await gitManagerInit();
      return true;
    }
    return false;
  }

  var storageRequest = Permission.manageExternalStorage;
  if (await (request ? storageRequest.request().isGranted : storageRequest.isGranted)) {
    await gitManagerInit();
    return true;
  }
  return false;
}

Widget? getBackButton(BuildContext context, Function() onPressed) => IconButton(
  onPressed: onPressed,
  icon: FaIcon(FontAwesomeIcons.arrowLeft, color: primaryLight, size: textLG, semanticLabel: t.backLabel),
);

void debounce(String index, int milliseconds, VoidCallback callback) {
  debounceTimers[index]?.cancel();
  _callbacks[index] = callback;
  debounceTimers[index] = Timer(Duration(milliseconds: milliseconds), callback);
}

void cancelDebounce(String index, [bool run = false]) {
  debounceTimers[index]?.cancel();
  if (run) {
    _callbacks[index]!();
  }
}

String formatBytes(int? bytes, [int precision = 2]) {
  if (bytes == null || bytes <= 0) return '0 B';
  final base = (math.log(bytes) / math.log(1024)).floor();
  final size = bytes / [1, 1024, 1048576, 1073741824, 1099511627776][base];
  final formattedSize = size.toStringAsFixed(precision);
  return '$formattedSize ${['B', 'KB', 'MB', 'GB', 'TB'][base]}';
}

Future<void> openLogViewer(BuildContext context) async {
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

  print("Using log file: ${logFile.path}");
  await Navigator.of(context).push(createCodeEditorRoute(logFile.path, logs: true));
}

Future<void> sendMergeConflictNotification() async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    gitSyncNotifyChannelId,
    gitSyncNotifyChannelName,
    icon: gitSyncIconRes,
    importance: Importance.high,
    priority: Priority.high,
  );
  const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

  await Logger.notificationsPlugin.show(
    mergeConflictNotificationId,
    mergeConflictNotificationTitle,
    mergeConflictNotificationBody,
    notificationDetails,
  );
}

Future<bool> hasNetworkConnection() async {
  return (await Connectivity().checkConnectivity())[0] != ConnectivityResult.none;
}

Future<T?> returnWhenOffline<T>(Future<T> Function() callback) async {
  return (await Connectivity().checkConnectivity())[0] == ConnectivityResult.none ? callback() : null;
}

Future<String?> pickDirectory() async {
  try {
    if (Platform.isAndroid) {
      final path = await FilePicker.platform.getDirectoryPath();
      if (path?.startsWith("/storage/home") == true) return path!.replaceFirst("/storage/home", "/storage/emulated/0/Documents");
      if (path == "/") return null;
      return path;
    }

    final iosDocumentPickerPlugin = IosDocumentPicker();
    var result = await iosDocumentPickerPlugin.pick(IosDocumentPickerType.directory, multiple: false);
    if (result == null) {
      return null;
    }

    return result[0].bookmark;
  } catch (e, st) {
    Logger.logError(LogType.SelectDirectory, e, st);
  }
  return null;
}

Future<void> setGitDirPathGetSubmodules(BuildContext context, String dir) async {
  await uiSettingsManager.setGitDirPath(dir);
  final submodulePaths = await GitManager.getSubmodulePaths(dir);

  Future<void> addSubmodules() async {
    List<String> repomanReponames = List.from(await repoManager.getStringList(StorageKey.repoman_repoNames));
    String currentContainerName = await repoManager.getRepoName(await repoManager.getInt(StorageKey.repoman_repoIndex));
    final curentClientModeEnabled = await uiSettingsManager.getClientModeEnabled();
    final currentSyncMessage = await uiSettingsManager.getSyncMessage();
    final currentSyncMessageTimeFormat = await uiSettingsManager.getSyncMessageTimeFormat();
    final currentDirPath = await uiSettingsManager.getString(StorageKey.setman_gitDirPath);
    final currentAuthorName = await uiSettingsManager.getAuthorName();
    final currentAuthorEmail = await uiSettingsManager.getAuthorEmail();
    final currentAuthUsername = await uiSettingsManager.getString(StorageKey.setman_gitAuthUsername);
    final currentAuthToken = await uiSettingsManager.getString(StorageKey.setman_gitAuthToken);
    final currentGitSshKey = await uiSettingsManager.getString(StorageKey.setman_gitSshKey);
    final currentSshPassphrase = await uiSettingsManager.getString(StorageKey.setman_gitSshPassphrase);
    final currentGitCommitSigningPassphrase = await uiSettingsManager.getStringNullable(StorageKey.setman_gitCommitSigningPassphrase);
    final currentGitCommitSigningKey = await uiSettingsManager.getStringNullable(StorageKey.setman_gitCommitSigningKey);
    final currentRemote = await uiSettingsManager.getRemote();
    final currentSyncMessageEnabled = await uiSettingsManager.getBool(StorageKey.setman_syncMessageEnabled);
    final currentGitProvider = await uiSettingsManager.getStringNullable(StorageKey.setman_gitProvider);
    final currentLastSyncMethod = await uiSettingsManager.getString(StorageKey.setman_lastSyncMethod);

    for (var path in submodulePaths) {
      String containerName = "$currentContainerName-${path.split("/").last}";

      if (repomanReponames.contains(containerName)) {
        containerName = "${containerName}_alt";
      }

      repomanReponames = [...repomanReponames, containerName];

      await repoManager.setStringList(StorageKey.repoman_repoNames, repomanReponames);

      final tempSettingsManager = SettingsManager();
      await tempSettingsManager.reinit(repoIndex: repomanReponames.indexOf(containerName));

      await tempSettingsManager.setBoolNullable(StorageKey.setman_clientModeEnabled, curentClientModeEnabled);
      await tempSettingsManager.setStringNullable(StorageKey.setman_authorName, currentAuthorName);
      await tempSettingsManager.setStringNullable(StorageKey.setman_authorEmail, currentAuthorEmail);
      await tempSettingsManager.setStringNullable(StorageKey.setman_syncMessage, currentSyncMessage);
      await tempSettingsManager.setStringNullable(StorageKey.setman_syncMessageTimeFormat, currentSyncMessageTimeFormat);
      await tempSettingsManager.setStringNullable(StorageKey.setman_remote, currentRemote);
      await tempSettingsManager.setBool(StorageKey.setman_syncMessageEnabled, currentSyncMessageEnabled);
      await tempSettingsManager.setStringNullable(StorageKey.setman_gitProvider, currentGitProvider);
      await tempSettingsManager.setString(StorageKey.setman_gitAuthUsername, currentAuthUsername);
      await tempSettingsManager.setString(StorageKey.setman_gitAuthToken, currentAuthToken);
      await tempSettingsManager.setString(StorageKey.setman_gitSshKey, currentGitSshKey);
      await tempSettingsManager.setString(StorageKey.setman_gitSshPassphrase, currentSshPassphrase);
      await tempSettingsManager.setStringNullable(StorageKey.setman_gitCommitSigningPassphrase, currentGitCommitSigningPassphrase);
      await tempSettingsManager.setStringNullable(StorageKey.setman_gitCommitSigningKey, currentGitCommitSigningKey);
      await tempSettingsManager.setString(StorageKey.setman_lastSyncMethod, currentLastSyncMethod);

      if (Platform.isIOS) {
        final bookmarkParts = currentDirPath.split(conflictSeparator);
        final bookmark = bookmarkParts.first;
        final pathSuffix = currentDirPath.contains(conflictSeparator) ? bookmarkParts.last : "";
        await tempSettingsManager.setGitDirPath("$bookmark$conflictSeparator${pathSuffix.isEmpty ? path : "$pathSuffix/$path"}");
      } else {
        await tempSettingsManager.setGitDirPath("$currentDirPath/$path");
      }
    }

    await repoManager.setInt(StorageKey.repoman_repoIndex, min(repomanReponames.length, repomanReponames.indexOf(currentContainerName) + 1));
    await uiSettingsManager.reinit();
  }

  if (submodulePaths.isNotEmpty) {
    await SubmodulesFoundDialog.showDialog(context, () async {
      if (premiumManager.hasPremiumNotifier.value != true) {
        await UnlockPremiumDialog.showDialog(context, () async {
          await addSubmodules();
        });
        return;
      }
      await addSubmodules();
    });
  }
}

Future<T?> useDirectory<T>(String bookmarkPath, Future<void> Function(String) setBookmarkPath, Future<T?> Function(String path) useAccess) async {
  Future<T?> preUseAccess(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      return null;
    }

    return await useAccess(path);
  }

  if (Platform.isAndroid) return await preUseAccess(bookmarkPath);

  if (bookmarkPath.isEmpty) return null;

  final iosDocumentPickerPlugin = IosDocumentPicker();
  String? path;

  final bookmarkParts = bookmarkPath.split(conflictSeparator);
  final bookmark = bookmarkParts.first;
  final pathSuffix = bookmarkPath.contains(conflictSeparator) ? bookmarkParts.last : "";

  try {
    final bookmarkAndPath = await iosDocumentPickerPlugin.resolveBookmark(bookmark, isDirectory: true);
    if (bookmarkAndPath == null) return null;
    await setBookmarkPath(bookmarkAndPath.$1);
    path = pathSuffix.isEmpty ? bookmarkAndPath.$2 : "${bookmarkAndPath.$2}/$pathSuffix";
  } catch (e) {
    print(e);
    return null;
  }

  if (path.isEmpty) {
    return null;
  }

  final hasAccess = await iosDocumentPickerPlugin.startAccessing(path);
  if (!hasAccess) {
    Logger.logError(LogType.SelectDirectory, "No folder access", StackTrace.fromString(""));
    return null;
  }

  final result = await preUseAccess(path);

  debounce("$iosFolderAccessDebounceReference-$path", 60000, () async => await iosDocumentPickerPlugin.stopAccessing(path!));

  return result;
}

Future<String> encryptMap(Map<String, dynamic> data, String password) async {
  final salt = _randomBytes(16);
  final key = await _deriveKey(password, salt);
  final nonce = _randomBytes(12);
  final encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key(key), mode: encrypt.AESMode.gcm));
  final json = jsonEncode(data);
  final encrypted = encrypter.encrypt(json, iv: encrypt.IV(Uint8List.fromList(nonce)));

  final result = <int>[...salt, ...nonce, ...encrypted.bytes];
  return base64Encode(result);
}

Future<Map<String, dynamic>> decryptMap(String encryptedBase64, String password) async {
  final data = base64Decode(encryptedBase64);
  final salt = data.sublist(0, 16);
  final nonce = data.sublist(16, 28);
  final ciphertext = data.sublist(28);
  final key = await _deriveKey(password, salt);
  final encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key(key), mode: encrypt.AESMode.gcm));
  final decrypted = encrypter.decrypt(encrypt.Encrypted(ciphertext), iv: encrypt.IV(nonce));
  return jsonDecode(decrypted);
}

Future<Uint8List> _deriveKey(String password, List<int> salt, {int iterations = 100000, int keyLength = 32}) async {
  final pbkdf2 = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: iterations, bits: keyLength * 8);
  final secretKey = await pbkdf2.deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);
  final keyBytes = await secretKey.extractBytes();
  return Uint8List.fromList(keyBytes);
}

List<int> _randomBytes(int length) {
  final rand = Random.secure();
  return List<int>.generate(length, (_) => rand.nextInt(256));
}
