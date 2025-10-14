import 'dart:convert';
import 'dart:io';

import 'package:GitSync/api/logger.dart';
import 'package:GitSync/api/manager/settings_manager.dart';
import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/ui/component/button_setting.dart';
import 'package:GitSync/ui/component/custom_showcase.dart';
import 'package:GitSync/ui/component/item_setting.dart';
import 'package:GitSync/ui/page/file_explorer.dart';
import 'package:archive/archive_io.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:GitSync/ui/dialog/unlock_premium.dart' as UnlockPremiumDialog;
import 'package:sprintf/sprintf.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../api/helper.dart';
import '../../../constant/colors.dart';
import '../../../constant/dimens.dart';
import '../../../constant/strings.dart';
import '../../../global.dart';

import '../dialog/change_language.dart' as ChangeLanguageDialog;
import '../dialog/confirm_clear_data.dart' as ConfirmClearDataDialog;
import '../dialog/enter_backup_restore_password.dart' as EnterBackupRestorePasswordDialog;

class GlobalSettingsMain extends StatefulWidget {
  const GlobalSettingsMain({super.key, this.onboarding = false});
  final bool onboarding;

  @override
  State<GlobalSettingsMain> createState() => _GlobalSettingsMain();
}

class _GlobalSettingsMain extends State<GlobalSettingsMain> with WidgetsBindingObserver {
  final _controller = ScrollController();
  bool atTop = true;
  final _uiSetupGuideKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      atTop = _controller.offset <= 0;
      setState(() {});
    });

    if (widget.onboarding) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _controller.animateTo(_controller.position.maxScrollExtent / 2, duration: Duration(milliseconds: 500), curve: Curves.easeInOut);
        await Future.delayed(Duration(milliseconds: 200));
        ShowCaseWidget.of(context).startShowCase([_uiSetupGuideKey]);
        while (!ShowCaseWidget.of(context).isShowCaseCompleted) {
          await Future.delayed(Duration(milliseconds: 100));
        }
        Navigator.of(context).popUntil((route) => route.isFirst);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: secondaryDark,
          systemNavigationBarColor: secondaryDark,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        leading: getBackButton(context, () => Navigator.of(context).canPop() ? Navigator.pop(context) : null),
        centerTitle: true,
        title: Text(
          t.globalSettings.toUpperCase(),
          style: TextStyle(color: primaryLight, fontWeight: FontWeight.bold),
        ),
      ),
      body: ShaderMask(
        shaderCallback: (Rect rect) {
          return LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [atTop ? Colors.transparent : Colors.black, Colors.transparent, Colors.transparent, Colors.transparent],
            stops: [0.0, 0.1, 0.9, 1.0],
          ).createShader(rect);
        },
        blendMode: BlendMode.dstOut,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: spaceMD + spaceSM),
          child: SingleChildScrollView(
            controller: _controller,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                ButtonSetting(
                  text: t.language,
                  icon: FontAwesomeIcons.earthOceania,
                  onPressed: () async {
                    await ChangeLanguageDialog.showDialog(context, (locale) async {
                      await repoManager.setStringNullable(StorageKey.repoman_appLocale, locale);
                      Navigator.of(context).canPop() ? Navigator.pop(context) : null;
                      if (mounted) setState(() {});
                      Navigator.of(context).canPop() ? Navigator.pop(context) : null;
                    });
                  },
                ),
                SizedBox(height: spaceMD),
                ButtonSetting(
                  text: t.browseEditDir,
                  icon: FontAwesomeIcons.folderTree,
                  onPressed: () async {
                    String? selectedDirectory;
                    if (await requestStoragePerm()) {
                      selectedDirectory = await pickDirectory();
                    }
                    if (selectedDirectory == null) return;

                    await useDirectory(selectedDirectory, (_) async {}, (path) async {
                      await Navigator.of(context).push(createFileExplorerRoute(path));
                    });
                  },
                ),
                SizedBox(height: spaceLG),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: spaceMD),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          color: tertiaryLight,
                          height: spaceXXXXS,
                          margin: EdgeInsets.only(right: spaceSM),
                        ),
                      ),
                      Text(
                        t.backupRestoreTitle.toUpperCase(),
                        style: TextStyle(fontSize: textSM, color: primaryLight, fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Container(
                          color: tertiaryLight,
                          height: spaceXXXXS,
                          margin: EdgeInsets.only(left: spaceSM),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: spaceSM),
                ButtonSetting(
                  text: t.backup,
                  icon: FontAwesomeIcons.solidFloppyDisk,
                  onPressed: () async {
                    await EnterBackupRestorePasswordDialog.showDialog(context, true, (text) async {
                      final repoManagerSettings = await repoManager.getAll();
                      final repoCount = (await repoManager.getStringList(StorageKey.repoman_repoNames)).length;
                      final settingsManagerSettings = <Map<String, String>>[];

                      for (var i = 0; i < repoCount; i++) {
                        final settingsManager = SettingsManager();
                        settingsManager.reinit(repoIndex: i);
                        settingsManagerSettings.add(await settingsManager.getAll());
                      }

                      final Map<String, dynamic> settingsMap = {"repoManager": repoManagerSettings, "settingsManager": settingsManagerSettings};

                      await FilePicker.platform.saveFile(
                        dialogTitle: t.selectBackupLocation,
                        fileName: sprintf(t.backupFileTemplate, [DateTime.now().toLocal().toString().replaceAll(":", "-")]),
                        bytes: utf8.encode(await encryptMap(settingsMap, text)),
                      );
                    });
                  },
                ),
                SizedBox(height: spaceMD),
                ButtonSetting(
                  text: t.restore,
                  icon: FontAwesomeIcons.arrowRotateLeft,
                  onPressed: () async {
                    FilePickerResult? result = await FilePicker.platform.pickFiles();
                    if (result == null) return;

                    File file = File(result.files.single.path!);

                    await EnterBackupRestorePasswordDialog.showDialog(context, false, (text) async {
                      Map<String, dynamic> settingsMap = {};
                      try {
                        settingsMap = await decryptMap(file.readAsStringSync(), text);
                      } catch (e) {
                        await Fluttertoast.showToast(msg: t.invalidPassword, toastLength: Toast.LENGTH_LONG, gravity: null);
                        return;
                      }

                      await repoManager.setAll(settingsMap["repoManager"]);
                      List<dynamic> settingsManagerSettings = settingsMap["settingsManager"];

                      for (var i = 0; i < settingsManagerSettings.length; i++) {
                        final settingsManager = SettingsManager();
                        settingsManager.reinit(repoIndex: i);
                        await settingsManager.setAll(settingsManagerSettings[i]);
                      }

                      Navigator.of(context).canPop() ? Navigator.pop(context) : null;
                    });
                  },
                ),

                SizedBox(height: spaceLG),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: spaceMD),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          color: tertiaryLight,
                          height: spaceXXXXS,
                          margin: EdgeInsets.only(right: spaceSM),
                        ),
                      ),
                      Text(
                        t.community.toUpperCase(),
                        style: TextStyle(fontSize: textSM, color: primaryLight, fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Container(
                          color: tertiaryLight,
                          height: spaceXXXXS,
                          margin: EdgeInsets.only(left: spaceSM),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: spaceSM),
                ButtonSetting(
                  text: t.reportABug,
                  icon: FontAwesomeIcons.bug,
                  textColor: primaryDark,
                  iconColor: primaryDark,
                  buttonColor: tertiaryNegative,
                  onPressed: () async {
                    await Logger.reportIssue(context);
                  },
                ),
                SizedBox(height: spaceMD),
                ButtonSetting(
                  text: t.shareLogs,
                  icon: FontAwesomeIcons.envelopeOpenText,
                  loads: true,
                  onPressed: () async {
                    final dir = await getTemporaryDirectory();
                    final logsDir = Directory('${dir.path}/logs');
                    final files = !logsDir.existsSync() ? [] : logsDir.listSync().whereType<File>().where((f) => f.path.endsWith('.log')).toList();

                    if (files.isEmpty || !logsDir.existsSync()) {
                      Fluttertoast.showToast(msg: t.noLogFilesFound, toastLength: Toast.LENGTH_SHORT, gravity: null);
                      return;
                    }

                    final zipFile = File('${dir.path}/logs.zip');

                    var encoder = ZipFileEncoder();
                    encoder.create('${dir.path}/logs.zip');

                    for (var file in files) {
                      await encoder.addFile(file);
                    }
                    await encoder.close();

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

                    final Email email = Email(
                      body:
                          """

${await Logger.generateDeviceInfo()}

""",
                      subject: sprintf(t.logsEmailSubjectTemplate, [Platform.isIOS ? t.ios : t.android]),
                      recipients: [t.logsEmailRecipient],
                      attachmentPaths: [zipFile.path],
                      isHTML: false,
                    );

                    try {
                      await FlutterEmailSender.send(email);
                    } catch (e, stackStrace) {
                      Logger.logError(LogType.Global, e, stackStrace);
                    }
                  },
                ),
                SizedBox(height: spaceMD),
                ButtonSetting(
                  text: t.requestAFeature,
                  icon: FontAwesomeIcons.solidHandPointUp,
                  onPressed: () async {
                    if (await canLaunchUrl(Uri.parse(githubFeatureTemplate))) {
                      await launchUrl(Uri.parse(githubFeatureTemplate));
                    }
                  },
                ),
                SizedBox(height: spaceMD),
                ButtonSetting(
                  text: t.improveTranslations,
                  icon: FontAwesomeIcons.language,
                  onPressed: () async {
                    if (await canLaunchUrl(Uri.parse(githubImproveTranslationsDocs))) {
                      await launchUrl(Uri.parse(githubImproveTranslationsDocs));
                    }
                  },
                ),
                SizedBox(height: spaceMD),
                ButtonSetting(
                  text: t.joinTheDiscussion,
                  icon: FontAwesomeIcons.discord,
                  onPressed: () async {
                    if (await canLaunchUrl(Uri.parse(discordLink))) {
                      await launchUrl(Uri.parse(discordLink));
                    }
                  },
                ),

                SizedBox(height: spaceLG),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: spaceMD),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          color: tertiaryLight,
                          height: spaceXXXXS,
                          margin: EdgeInsets.only(right: spaceSM),
                        ),
                      ),
                      Text(
                        t.guides.toUpperCase(),
                        style: TextStyle(fontSize: textSM, color: primaryLight, fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Container(
                          color: tertiaryLight,
                          height: spaceXXXXS,
                          margin: EdgeInsets.only(left: spaceSM),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: spaceSM),
                ButtonSetting(
                  text: t.viewDocumentation,
                  icon: FontAwesomeIcons.solidFileLines,
                  onPressed: () async {
                    launchUrl(Uri.parse(documentationLink));
                  },
                ),
                SizedBox(height: spaceMD),
                CustomShowcase(
                  globalKey: _uiSetupGuideKey,
                  description: t.guidedSetupHint,
                  cornerRadius: cornerRadiusMD,
                  last: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ButtonSetting(
                        text: t.guidedSetup,
                        icon: FontAwesomeIcons.chalkboardUser,
                        onPressed: () async {
                          await repoManager.setInt(StorageKey.repoman_onboardingStep, 0);
                          Navigator.of(context).canPop() ? Navigator.pop(context) : null;
                          await onboardingController?.show();
                          if (mounted) setState(() {});
                        },
                      ),
                      SizedBox(height: spaceMD),
                      ButtonSetting(
                        text: t.uiGuide,
                        icon: FontAwesomeIcons.route,
                        onPressed: () async {
                          await repoManager.setInt(StorageKey.repoman_onboardingStep, 4);
                          Navigator.of(context).canPop() ? Navigator.pop(context) : null;
                          await onboardingController?.show();
                          if (mounted) setState(() {});
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: spaceLG + spaceMD),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: spaceMD),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          color: tertiaryLight,
                          height: spaceXXXXS,
                          margin: EdgeInsets.only(right: spaceSM),
                        ),
                      ),
                      Text(
                        "Repository Defaults".toUpperCase(),
                        style: TextStyle(fontSize: textSM, color: primaryLight, fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Container(
                          color: tertiaryLight,
                          height: spaceXXXXS,
                          margin: EdgeInsets.only(left: spaceSM),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: spaceMD),
                FutureBuilder(
                  future: repoManager.getBool(StorageKey.repoman_defaultClientModeEnabled),
                  builder: (context, clientModeEnabledSnapshot) => Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () async {
                            await repoManager.setBool(StorageKey.repoman_defaultClientModeEnabled, false);
                            setState(() {});
                          },
                          style: ButtonStyle(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: WidgetStatePropertyAll(EdgeInsets.zero),
                            backgroundColor: WidgetStatePropertyAll(clientModeEnabledSnapshot.data != true ? primaryPositive : tertiaryDark),
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  topLeft: cornerRadiusMD,
                                  topRight: Radius.zero,
                                  bottomLeft: cornerRadiusMD,
                                  bottomRight: Radius.zero,
                                ),

                                side: clientModeEnabledSnapshot.data != true ? BorderSide.none : BorderSide(width: 3, color: primaryPositive),
                              ),
                            ),
                            animationDuration: Duration.zero,
                          ),
                          icon: FaIcon(
                            FontAwesomeIcons.arrowsRotate,
                            color: clientModeEnabledSnapshot.data != true ? tertiaryDark : primaryLight,
                            size: textMD,
                          ),
                          label: Text(
                            t.syncMode,
                            style: TextStyle(
                              color: clientModeEnabledSnapshot.data != true ? tertiaryDark : primaryLight,
                              fontSize: textMD,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () async {
                            await repoManager.setBool(StorageKey.repoman_defaultClientModeEnabled, true);
                            setState(() {});
                          },
                          style: ButtonStyle(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: WidgetStatePropertyAll(EdgeInsets.zero),
                            backgroundColor: WidgetStatePropertyAll(clientModeEnabledSnapshot.data == true ? primaryPositive : tertiaryDark),
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.zero,
                                  topRight: cornerRadiusMD,
                                  bottomLeft: Radius.zero,
                                  bottomRight: cornerRadiusMD,
                                ),
                                side: clientModeEnabledSnapshot.data == true ? BorderSide.none : BorderSide(width: 3, color: primaryPositive),
                              ),
                            ),
                            animationDuration: Duration.zero,
                          ),
                          iconAlignment: IconAlignment.end,
                          icon: FaIcon(
                            FontAwesomeIcons.codeCompare,
                            color: clientModeEnabledSnapshot.data == true ? tertiaryDark : primaryLight,
                            size: textMD,
                          ),
                          label: Text(
                            t.clientMode,
                            style: TextStyle(
                              color: clientModeEnabledSnapshot.data == true ? tertiaryDark : primaryLight,
                              fontSize: textMD,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: spaceMD),
                ItemSetting(
                  setFn: (value) => repoManager.setString(StorageKey.repoman_defaultSyncMessage, value),
                  getFn: () => repoManager.getString(StorageKey.repoman_defaultSyncMessage),
                  title: t.syncMessageLabel,
                  description: t.syncMessageDescription,
                  hint: defaultSyncMessage,
                  maxLines: null,
                  minLines: null,
                ),
                SizedBox(height: spaceMD),
                ItemSetting(
                  setFn: (value) => repoManager.setString(StorageKey.repoman_defaultSyncMessageTimeFormat, value),
                  getFn: () => repoManager.getString(StorageKey.repoman_defaultSyncMessageTimeFormat),
                  title: t.syncMessageTimeFormatLabel,
                  description: t.syncMessageTimeFormatDescription,
                  hint: defaultSyncMessageTimeFormat,
                ),
                SizedBox(height: spaceMD),
                ItemSetting(
                  setFn: (value) => repoManager.setString(StorageKey.repoman_defaultAuthorName, value.trim()),
                  getFn: demo ? () async => "" : () => repoManager.getString(StorageKey.repoman_defaultAuthorName),
                  title: t.authorNameLabel,
                  hint: t.authorName,
                ),
                SizedBox(height: spaceMD),
                ItemSetting(
                  setFn: (value) => repoManager.setString(StorageKey.repoman_defaultAuthorEmail, value.trim()),
                  getFn: demo ? () async => "" : () => repoManager.getString(StorageKey.repoman_defaultAuthorEmail),
                  title: t.authorEmailLabel,
                  hint: t.authorEmail,
                ),
                SizedBox(height: spaceMD),
                ItemSetting(
                  setFn: (value) => repoManager.setString(StorageKey.repoman_defaultRemote, value),
                  getFn: () => repoManager.getString(StorageKey.repoman_defaultRemote),
                  title: t.remoteLabel,
                  hint: t.defaultRemote,
                ),

                SizedBox(height: spaceLG + spaceMD),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: spaceMD),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          color: tertiaryLight,
                          height: spaceXXXXS,
                          margin: EdgeInsets.only(right: spaceSM),
                        ),
                      ),
                      Text(
                        "Miscellaneous".toUpperCase(),
                        style: TextStyle(fontSize: textSM, color: primaryLight, fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Container(
                          color: tertiaryLight,
                          height: spaceXXXXS,
                          margin: EdgeInsets.only(left: spaceSM),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: spaceSM),
                ValueListenableBuilder(
                  valueListenable: premiumManager.hasPremiumNotifier,
                  builder: (context, hasPremium, child) => ButtonSetting(
                    text: (hasPremium == true ? t.contributeTitle : t.premiumDialogTitle).toUpperCase(),
                    icon: hasPremium == true ? FontAwesomeIcons.circleDollarToSlot : FontAwesomeIcons.solidGem,
                    iconColor: tertiaryPositive,
                    onPressed: () async {
                      if (hasPremium == true) {
                        await launchUrl(Uri.parse(contributeLink));
                      } else {
                        await UnlockPremiumDialog.showDialog(context, () => mounted ? setState(() {}) : null);
                        if (mounted) setState(() {});
                      }
                    },
                  ),
                ),
                SizedBox(height: spaceMD),
                ButtonSetting(
                  text: t.viewPrivacyPolicy,
                  icon: FontAwesomeIcons.userShield,
                  onPressed: () async {
                    launchUrl(Uri.parse(privacyPolicyLink));
                  },
                ),
                SizedBox(height: spaceMD),
                ButtonSetting(
                  text: t.viewEula,
                  icon: FontAwesomeIcons.fileContract,
                  onPressed: () async {
                    launchUrl(Uri.parse(eulaLink));
                  },
                ),
                SizedBox(height: spaceMD),
                FutureBuilder(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, versionSnapshot) => ButtonSetting(
                    text: versionSnapshot.data?.version ?? "x.x.xx",
                    icon: FontAwesomeIcons.tag,
                    onPressed: () async {
                      launchUrl(Uri.parse(eulaLink));
                    },
                  ),
                ),

                SizedBox(height: spaceLG),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: spaceMD),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          color: tertiaryNegative,
                          height: spaceXXXXS,
                          margin: EdgeInsets.only(right: spaceSM),
                        ),
                      ),
                      Text(
                        "Danger Zone".toUpperCase(),
                        style: TextStyle(fontSize: textSM, color: tertiaryNegative, fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Container(
                          color: tertiaryNegative,
                          height: spaceXXXXS,
                          margin: EdgeInsets.only(left: spaceSM),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: spaceSM),
                ButtonSetting(
                  text: t.iosClearDataAction,
                  icon: FontAwesomeIcons.dumpsterFire,
                  onPressed: () async {
                    await ConfirmClearDataDialog.showDialog(context, () async {
                      await uiSettingsManager.storage.deleteAll();
                      await repoManager.storage.deleteAll();

                      Navigator.of(context).canPop() ? Navigator.pop(context) : null;
                    });
                  },
                  buttonColor: secondaryNegative,
                ),
                SizedBox(height: spaceLG),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Route createGlobalSettingsMainRoute({bool onboarding = false}) {
  return PageRouteBuilder(
    settings: const RouteSettings(name: global_settings_main),
    pageBuilder: (context, animation, secondaryAnimation) => ShowCaseWidget(builder: (context) => GlobalSettingsMain(onboarding: onboarding)),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      const curve = Curves.ease;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}
