import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:GitSync/providers/riverpod_providers.dart';
import 'package:GitSync/api/accessibility_service_helper.dart';
import 'package:GitSync/api/logger.dart';
import 'package:GitSync/api/manager/git_manager.dart';
import 'package:GitSync/api/manager/settings_manager.dart';
import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/ui/component/button_setting.dart';
import 'package:GitSync/ui/component/custom_showcase.dart';
import 'package:GitSync/ui/component/item_setting.dart';
import 'package:GitSync/ui/component/sync_client_mode_toggle.dart';
import 'package:GitSync/ui/page/file_explorer.dart';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:GitSync/ui/page/unlock_premium.dart';
import 'package:sprintf/sprintf.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../api/helper.dart';
import '../../../constant/dimens.dart';
import '../../../constant/strings.dart';
import '../../../global.dart';

import '../dialog/change_language.dart' as ChangeLanguageDialog;
import '../dialog/confirm_clear_data.dart' as ConfirmClearDataDialog;
import '../dialog/enter_backup_restore_password.dart' as EnterBackupRestorePasswordDialog;

class GlobalSettingsMain extends ConsumerStatefulWidget {
  const GlobalSettingsMain({super.key, this.onboarding = false});

  final bool onboarding;

  @override
  ConsumerState<GlobalSettingsMain> createState() => _GlobalSettingsMain();
}

class _GlobalSettingsMain extends ConsumerState<GlobalSettingsMain> with WidgetsBindingObserver, TickerProviderStateMixin {
  final _controller = ScrollController();
  final _landscapeScrollControllerLeft = ScrollController();
  final _landscapeScrollControllerRight = ScrollController();
  bool atTop = true;
  bool _blockTouches = false;
  late final _uiSetupGuideKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      atTop = _controller.offset <= 0;
      if (mounted) setState(() {});
    });

    _landscapeScrollControllerLeft.addListener(() {
      if (_landscapeScrollControllerLeft.offset != _landscapeScrollControllerRight.offset &&
          _landscapeScrollControllerLeft.offset <= _landscapeScrollControllerRight.position.maxScrollExtent) {
        _landscapeScrollControllerRight.jumpTo(_landscapeScrollControllerLeft.offset);
      }
    });
    _landscapeScrollControllerRight.addListener(() {
      if (_landscapeScrollControllerLeft.offset != _landscapeScrollControllerRight.offset &&
          _landscapeScrollControllerRight.offset <= _landscapeScrollControllerLeft.position.maxScrollExtent) {
        _landscapeScrollControllerLeft.jumpTo(_landscapeScrollControllerRight.offset);
      }
    });

    if (widget.onboarding) {
      _blockTouches = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _controller.animateTo(_controller.position.maxScrollExtent / 2, duration: animSlow, curve: Curves.easeInOut);
        if (!mounted) return;
        await Future.delayed(Duration(milliseconds: 200));
        if (!mounted) return;
        setState(() => _blockTouches = false);
        ShowCaseWidget.of(context).startShowCase([_uiSetupGuideKey]);
        while (mounted && !ShowCaseWidget.of(context).isShowCaseCompleted) {
          await Future.delayed(Duration(milliseconds: 100));
        }
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      });
    }
  }

  @override
  Widget build(BuildContext context) => AbsorbPointer(absorbing: _blockTouches, child: _buildContent(context));

  Widget _buildContent(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colours.primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: context.colours.primaryDark,
          systemNavigationBarColor: context.colours.primaryDark,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        leading: getBackButton(context, () => Navigator.of(context).canPop() ? Navigator.pop(context) : null),
        centerTitle: true,
        title: Text(
          context.t.globalSettings.toUpperCase(),
          style: TextStyle(color: context.colours.primaryLight, fontWeight: FontWeight.bold),
        ),
      ),
      body: BetterOrientationBuilder(
        builder: (context, orientation) => ShaderMask(
          shaderCallback: (Rect rect) {
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [atTop ? Colors.transparent : Colors.black, Colors.transparent, Colors.transparent, Colors.transparent],
              stops: [0.0, 0.1, 0.9, 1.0],
            ).createShader(rect);
          },
          blendMode: BlendMode.dstOut,
          child: SingleChildScrollView(
            scrollDirection: orientation == Orientation.portrait ? Axis.vertical : Axis.horizontal,
            controller: _controller,
            child: Container(
              width: orientation == Orientation.portrait
                  ? null
                  : MediaQuery.of(context).size.width -
                        (MediaQuery.of(context).systemGestureInsets.right == 48 || MediaQuery.of(context).systemGestureInsets.left == 48
                            ? MediaQuery.of(context).systemGestureInsets.right + MediaQuery.of(context).systemGestureInsets.left
                            : 0),
              padding: EdgeInsets.only(left: spaceMD + spaceSM, right: spaceMD + spaceSM),
              child: Flex(
                direction: orientation == Orientation.portrait ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  (orientation == Orientation.portrait
                      ? (List<Widget> children) =>
                            Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisAlignment: MainAxisAlignment.start, children: children)
                      : (List<Widget> children) => Expanded(
                          child: ShaderMask(
                            shaderCallback: (Rect rect) {
                              return LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.transparent, Colors.transparent, Colors.black],
                                stops: [0, 0.05, 0.95, 1.0],
                              ).createShader(rect);
                            },
                            blendMode: BlendMode.dstOut,
                            child: SingleChildScrollView(
                              controller: _landscapeScrollControllerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: children,
                              ),
                            ),
                          ),
                        ))([
                    IntrinsicHeight(
                      child: FutureBuilder(
                        future: repoManager.getBoolNullable(StorageKey.repoman_themeMode),
                        builder: (context, themeModeSnapshot) => Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: AnimatedContainer(
                                duration: animFast,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topLeft: cornerRadiusMD,
                                    topRight: Radius.zero,
                                    bottomLeft: cornerRadiusMD,
                                    bottomRight: Radius.zero,
                                  ),
                                  color: themeModeSnapshot.data == false ? context.colours.tertiaryLight : context.colours.tertiaryDark,
                                ),
                                child: TextButton.icon(
                                  onPressed: () async {
                                    await repoManager.setBoolNullable(StorageKey.repoman_themeMode, false);
                                    reloadTheme(context);
                                    setState(() {});
                                  },
                                  style: ButtonStyle(
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: spaceSM, horizontal: spaceMD)),
                                    backgroundColor: WidgetStatePropertyAll(
                                      themeModeSnapshot.data == false ? context.colours.tertiaryLight : context.colours.tertiaryDark,
                                    ),
                                    shape: WidgetStatePropertyAll(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.only(
                                          topLeft: cornerRadiusMD,
                                          topRight: Radius.zero,
                                          bottomLeft: cornerRadiusMD,
                                          bottomRight: Radius.zero,
                                        ),

                                        side: themeModeSnapshot.data == false
                                            ? BorderSide.none
                                            : BorderSide(width: 3, color: context.colours.tertiaryLight),
                                      ),
                                    ),
                                  ),
                                  icon: FaIcon(
                                    FontAwesomeIcons.solidSun,
                                    color: themeModeSnapshot.data == false ? context.colours.primaryDark : context.colours.primaryLight,
                                    size: textMD,
                                  ),
                                  label: SizedBox(
                                    width: double.infinity,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        AnimatedDefaultTextStyle(
                                          child: Text(
                                            context.t.lightMode,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: textMD, fontWeight: FontWeight.bold),
                                          ),
                                          style: TextStyle(
                                            color: themeModeSnapshot.data == false ? context.colours.primaryDark : context.colours.primaryLight,
                                            fontSize: textMD,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          duration: animFast,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: AnimatedContainer(
                                duration: animFast,
                                decoration: BoxDecoration(borderRadius: BorderRadius.zero, color: context.colours.tertiaryLight),
                                padding: EdgeInsets.symmetric(vertical: 3),
                                child: Container(
                                  child: TextButton.icon(
                                    onPressed: () async {
                                      await repoManager.setBoolNullable(StorageKey.repoman_themeMode, null);
                                      reloadTheme(context);
                                      setState(() {});
                                    },
                                    style: ButtonStyle(
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: spaceSM - 3, horizontal: spaceMD)),
                                      backgroundColor: WidgetStatePropertyAll(
                                        themeModeSnapshot.data == null ? context.colours.tertiaryLight : context.colours.tertiaryDark,
                                      ),
                                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide.none)),
                                    ),
                                    label: SizedBox(
                                      width: double.infinity,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          AnimatedDefaultTextStyle(
                                            child: Text(
                                              context.t.system,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(fontSize: textMD, fontWeight: FontWeight.bold),
                                            ),
                                            style: TextStyle(
                                              color: themeModeSnapshot.data == null ? context.colours.primaryDark : context.colours.primaryLight,
                                              fontSize: textMD,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            duration: animFast,
                                          ),
                                          SizedBox(height: spaceXXXS),
                                          Transform.flip(
                                            flipX: true,
                                            child: FaIcon(
                                              FontAwesomeIcons.circleHalfStroke,
                                              color: themeModeSnapshot.data == null ? context.colours.primaryDark : context.colours.primaryLight,
                                              size: textMD,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: AnimatedContainer(
                                duration: animFast,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.zero,
                                    topRight: cornerRadiusMD,
                                    bottomLeft: Radius.zero,
                                    bottomRight: cornerRadiusMD,
                                  ),
                                  color: themeModeSnapshot.data == true ? context.colours.tertiaryLight : context.colours.tertiaryDark,
                                ),
                                child: TextButton.icon(
                                  onPressed: () async {
                                    await repoManager.setBoolNullable(StorageKey.repoman_themeMode, true);
                                    reloadTheme(context);
                                    setState(() {});
                                  },
                                  style: ButtonStyle(
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: spaceSM, horizontal: spaceMD)),
                                    backgroundColor: WidgetStatePropertyAll(
                                      themeModeSnapshot.data == true ? context.colours.tertiaryLight : context.colours.tertiaryDark,
                                    ),
                                    shape: WidgetStatePropertyAll(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.zero,
                                          topRight: cornerRadiusMD,
                                          bottomLeft: Radius.zero,
                                          bottomRight: cornerRadiusMD,
                                        ),
                                        side: themeModeSnapshot.data == true
                                            ? BorderSide.none
                                            : BorderSide(width: 3, color: context.colours.tertiaryLight),
                                      ),
                                    ),
                                  ),
                                  iconAlignment: IconAlignment.end,
                                  icon: FaIcon(
                                    FontAwesomeIcons.solidMoon,
                                    color: themeModeSnapshot.data == true ? context.colours.primaryDark : context.colours.primaryLight,
                                    size: textMD,
                                  ),
                                  label: SizedBox(
                                    width: double.infinity,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        AnimatedDefaultTextStyle(
                                          child: Text(
                                            context.t.darkMode,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: textMD, fontWeight: FontWeight.bold),
                                          ),
                                          style: TextStyle(
                                            color: themeModeSnapshot.data == true ? context.colours.primaryDark : context.colours.primaryLight,
                                            fontSize: textMD,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          duration: animFast,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: spaceMD),
                    ButtonSetting(
                      text: context.t.language,
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
                      text: context.t.browseEditDir,
                      icon: FontAwesomeIcons.folderTree,
                      onPressed: () async {
                        String? selectedDirectory;
                        if (await requestStoragePerm()) {
                          selectedDirectory = await pickDirectory();
                        }
                        if (selectedDirectory == null) return;

                        await useDirectory(selectedDirectory, (_) async {}, (path) async {
                          await Navigator.of(context).push(createFileExplorerRoute(ref.read(recentCommitsProvider).valueOrNull ?? [], path));
                        });
                      },
                    ),
                    SizedBox(height: spaceMD),
                    FutureBuilder(
                      future: repoManager.getBool(StorageKey.repoman_editorLineWrap),
                      builder: (context, editorLineWrapSnapshot) => TextButton.icon(
                        onPressed: () async {
                          await repoManager.setBool(StorageKey.repoman_editorLineWrap, !(editorLineWrapSnapshot.data ?? false));
                          if (mounted) setState(() {});
                        },
                        style: ButtonStyle(
                          alignment: Alignment.centerLeft,
                          backgroundColor: WidgetStatePropertyAll(context.colours.tertiaryDark),
                          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceMD)),
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          minimumSize: WidgetStatePropertyAll(Size.zero),
                        ),
                        iconAlignment: IconAlignment.end,
                        icon: FaIcon(
                          editorLineWrapSnapshot.data == true ? FontAwesomeIcons.solidSquareCheck : FontAwesomeIcons.squareCheck,
                          color: context.colours.primaryPositive,
                          size: textLG,
                        ),
                        label: SizedBox(
                          width: double.infinity,
                          child: Text(
                            context.t.enableLineWrap.toUpperCase(),
                            style: TextStyle(color: context.colours.primaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: spaceMD),
                    Builder(
                      builder: (context) {
                        final aiEnabled = ref.watch(aiFeaturesEnabledProvider).valueOrNull ?? true;
                        return TextButton.icon(
                          onPressed: () {
                            ref.read(aiFeaturesEnabledProvider.notifier).set(!aiEnabled);
                          },
                          style: ButtonStyle(
                            alignment: Alignment.centerLeft,
                            backgroundColor: WidgetStatePropertyAll(context.colours.tertiaryDark),
                            padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceMD)),
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            minimumSize: WidgetStatePropertyAll(Size.zero),
                          ),
                          iconAlignment: IconAlignment.end,
                          icon: FaIcon(
                            aiEnabled ? FontAwesomeIcons.solidSquareCheck : FontAwesomeIcons.squareCheck,
                            color: context.colours.primaryPositive,
                            size: textLG,
                          ),
                          label: SizedBox(
                            width: double.infinity,
                            child: Text(
                              context.t.enableAiFeatures.toUpperCase(),
                              style: TextStyle(color: context.colours.primaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                    ),
                    if (Platform.isAndroid) ...[
                      SizedBox(height: spaceMD),
                      FutureBuilder(
                        future: AccessibilityServiceHelper.isExcludedFromRecents(),
                        builder: (context, excludedFromRecentsSnapshot) => TextButton.icon(
                          onPressed: () async {
                            await AccessibilityServiceHelper.excludeFromRecents(!(excludedFromRecentsSnapshot.data ?? false));
                            if (mounted) setState(() {});
                          },
                          style: ButtonStyle(
                            alignment: Alignment.centerLeft,
                            backgroundColor: WidgetStatePropertyAll(context.colours.tertiaryDark),
                            padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceMD)),
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            minimumSize: WidgetStatePropertyAll(Size.zero),
                          ),
                          iconAlignment: IconAlignment.end,
                          icon: FaIcon(
                            excludedFromRecentsSnapshot.data == true ? FontAwesomeIcons.solidSquareCheck : FontAwesomeIcons.squareCheck,
                            color: context.colours.primaryPositive,
                            size: textLG,
                          ),
                          label: SizedBox(
                            width: double.infinity,
                            child: Text(
                              context.t.excludeFromRecents.toUpperCase(),
                              style: TextStyle(color: context.colours.primaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: spaceLG),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: spaceMD),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              color: context.colours.tertiaryLight,
                              height: spaceXXXXS,
                              margin: EdgeInsets.only(right: spaceSM),
                            ),
                          ),
                          Text(
                            context.t.backupRestoreTitle.toUpperCase(),
                            style: TextStyle(fontSize: textSM, color: context.colours.primaryLight, fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                            child: Container(
                              color: context.colours.tertiaryLight,
                              height: spaceXXXXS,
                              margin: EdgeInsets.only(left: spaceSM),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: spaceSM),
                    ButtonSetting(
                      text: context.t.encryptedBackup,
                      icon: FontAwesomeIcons.solidFloppyDisk,
                      onPressed: () async {
                        await EnterBackupRestorePasswordDialog.showDialog(context, true, (text) async {
                          final t = context.t;
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
                      text: context.t.encryptedRestore,
                      icon: FontAwesomeIcons.arrowRotateLeft,
                      onPressed: () async {
                        if (!await requestStoragePerm(false) && !await requestStoragePerm()) return;
                        FilePickerResult? result = await FilePicker.platform.pickFiles();
                        if (result == null) return;

                        File file = File(result.files.single.path!);

                        await EnterBackupRestorePasswordDialog.showDialog(context, false, (text) async {
                          final t = context.t;
                          Map<String, dynamic> settingsMap = {};
                          try {
                            settingsMap = await decryptMap(file.readAsStringSync(), text);
                          } catch (e) {
                            await Fluttertoast.showToast(msg: t.invalidPassword, toastLength: Toast.LENGTH_LONG, gravity: null);
                            return;
                          }

                          List<dynamic> settingsManagerSettings = settingsMap["settingsManager"];

                          Future<void> importSettings() async {
                            await repoManager.setAll(settingsMap["repoManager"]);

                            for (var i = 0; i < settingsManagerSettings.length; i++) {
                              final settingsManager = SettingsManager();
                              settingsManager.reinit(repoIndex: i);
                              await settingsManager.setAll(settingsManagerSettings[i]);
                            }

                            for (var i = 0; i < settingsManagerSettings.length; i++) {
                              final settingsManager = SettingsManager();
                              settingsManager.reinit(repoIndex: i);
                              await GitManager.clearLocks();

                              if (!await Permission.notification.isGranted && await settingsManager.getBool(StorageKey.setman_syncMessageEnabled)) {
                                await settingsManager.setBool(StorageKey.setman_syncMessageEnabled, false);
                                if (await Permission.notification.request().isGranted) {
                                  await settingsManager.setBool(StorageKey.setman_syncMessageEnabled, true);
                                }
                              }
                            }

                            await uiSettingsManager.reinit();

                            Navigator.of(context).canPop() ? Navigator.pop(context) : null;
                          }

                          if (settingsManagerSettings.length > 1) {
                            if (ref.read(premiumStatusProvider) != true) {
                              final result = await Navigator.of(context).push(createUnlockPremiumRoute(context, {}));
                              if (result == true) {
                                await importSettings();
                              }
                              return;
                            }
                          }

                          await importSettings();
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
                              color: context.colours.tertiaryLight,
                              height: spaceXXXXS,
                              margin: EdgeInsets.only(right: spaceSM),
                            ),
                          ),
                          Text(
                            context.t.community.toUpperCase(),
                            style: TextStyle(fontSize: textSM, color: context.colours.primaryLight, fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                            child: Container(
                              color: context.colours.tertiaryLight,
                              height: spaceXXXXS,
                              margin: EdgeInsets.only(left: spaceSM),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: spaceSM),
                    ButtonSetting(
                      text: context.t.reportABug,
                      icon: FontAwesomeIcons.bug,
                      textColor: context.colours.primaryDark,
                      iconColor: context.colours.primaryDark,
                      buttonColor: context.colours.tertiaryNegative,
                      onPressed: () async {
                        await Logger.reportIssue(context, From.GLOBAL_SETTINGS);
                      },
                    ),
                    if (kDebugMode) ...[
                      SizedBox(height: spaceSM),
                      ButtonSetting(
                        text: 'FAKE ERROR',
                        icon: FontAwesomeIcons.explosion,
                        textColor: context.colours.primaryDark,
                        iconColor: context.colours.primaryDark,
                        buttonColor: context.colours.tertiaryWarning,
                        onPressed: () async {
                          Logger.logError(
                            LogType.Sync,
                            '$maestroE2eErrorMarker uncommitted changes exist in index (at line 1291)',
                            StackTrace.current,
                          );
                          await Logger.dismissError(context);
                        },
                      ),
                    ],
                    SizedBox(height: spaceMD),
                    ButtonSetting(
                      text: context.t.shareLogs,
                      icon: FontAwesomeIcons.envelopeOpenText,
                      loads: true,
                      onPressed: () async {
                        final t = context.t;
                        final dir = await getTemporaryDirectory();
                        final logsDir = Directory('${dir.path}/logs');
                        final files = !logsDir.existsSync()
                            ? []
                            : logsDir.listSync().whereType<File>().where((f) => f.path.endsWith('.log')).toList();

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
                          if (e.toString().contains("No email clients found!")) {
                            Fluttertoast.showToast(
                              msg: "No compatible email app found!\n(Gmail incompatible)",
                              toastLength: Toast.LENGTH_LONG,
                              gravity: null,
                            );
                            return;
                          }
                          Logger.logError(LogType.Global, e, stackStrace);
                        }
                      },
                    ),
                    SizedBox(height: spaceMD),
                    ButtonSetting(
                      text: context.t.requestAFeature,
                      icon: FontAwesomeIcons.solidHandPointUp,
                      onPressed: () async {
                        if (await canLaunchUrl(Uri.parse(githubFeatureTemplate))) {
                          await launchUrl(Uri.parse(githubFeatureTemplate));
                        }
                      },
                    ),
                    SizedBox(height: spaceMD),
                    ButtonSetting(
                      text: context.t.improveTranslations,
                      icon: FontAwesomeIcons.language,
                      onPressed: () async {
                        if (await canLaunchUrl(Uri.parse(githubImproveTranslationsDocs))) {
                          await launchUrl(Uri.parse(githubImproveTranslationsDocs));
                        }
                      },
                    ),
                    SizedBox(height: spaceMD),
                    ButtonSetting(
                      text: context.t.joinTheDiscussion,
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
                              color: context.colours.tertiaryLight,
                              height: spaceXXXXS,
                              margin: EdgeInsets.only(right: spaceSM),
                            ),
                          ),
                          Text(
                            context.t.guides.toUpperCase(),
                            style: TextStyle(fontSize: textSM, color: context.colours.primaryLight, fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                            child: Container(
                              color: context.colours.tertiaryLight,
                              height: spaceXXXXS,
                              margin: EdgeInsets.only(left: spaceSM),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: spaceSM),
                    ButtonSetting(
                      text: context.t.viewDocumentation,
                      icon: FontAwesomeIcons.solidFileLines,
                      onPressed: () async {
                        launchUrl(Uri.parse(documentationLink));
                      },
                    ),
                    SizedBox(height: spaceMD),
                    CustomShowcase(
                      globalKey: _uiSetupGuideKey,
                      cornerRadius: cornerRadiusMD,
                      first: true,
                      last: true,
                      richContent: ShowcaseTooltipContent(
                        title: context.t.showcaseSetupGuideTitle,
                        subtitle: context.t.showcaseSetupGuideSubtitle,
                        featureRows: [
                          ShowcaseFeatureRow(icon: FontAwesomeIcons.chalkboardUser, text: context.t.showcaseSetupGuideFeatureSetup),
                          ShowcaseFeatureRow(icon: FontAwesomeIcons.route, text: context.t.showcaseSetupGuideFeatureTour),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ButtonSetting(
                            text: context.t.guidedSetup,
                            icon: FontAwesomeIcons.chalkboardUser,
                            onPressed: () async {
                              await repoManager.setInt(StorageKey.repoman_onboardingStep, 0);
                              Navigator.of(context).canPop() ? Navigator.pop(context, "guided_setup") : null;
                            },
                          ),
                          SizedBox(height: spaceMD),
                          ButtonSetting(
                            text: context.t.uiGuide,
                            icon: FontAwesomeIcons.route,
                            onPressed: () async {
                              await repoManager.setInt(StorageKey.repoman_onboardingStep, 4);
                              Navigator.of(context).canPop() ? Navigator.pop(context, "ui_guide") : null;
                            },
                          ),
                        ],
                      ),
                    ),
                    if (orientation == Orientation.landscape) SizedBox(height: spaceLG),
                  ]),

                  SizedBox(height: spaceLG + spaceMD, width: spaceLG),

                  (orientation == Orientation.portrait
                      ? (List<Widget> children) =>
                            Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisAlignment: MainAxisAlignment.start, children: children)
                      : (List<Widget> children) => Expanded(
                          child: ShaderMask(
                            shaderCallback: (Rect rect) {
                              return LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.transparent, Colors.transparent, Colors.black],
                                stops: [0, 0.05, 0.95, 1.0],
                              ).createShader(rect);
                            },
                            blendMode: BlendMode.dstOut,
                            child: SingleChildScrollView(
                              controller: _landscapeScrollControllerRight,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: children,
                              ),
                            ),
                          ),
                        ))([
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: spaceMD),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              color: context.colours.tertiaryLight,
                              height: spaceXXXXS,
                              margin: EdgeInsets.only(right: spaceSM),
                            ),
                          ),
                          Text(
                            context.t.repositoryDefaults.toUpperCase(),
                            style: TextStyle(fontSize: textSM, color: context.colours.primaryLight, fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                            child: Container(
                              color: context.colours.tertiaryLight,
                              height: spaceXXXXS,
                              margin: EdgeInsets.only(left: spaceSM),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: spaceMD),
                    SyncClientModeToggle(global: true),
                    SizedBox(height: spaceMD),
                    ItemSetting(
                      setFn: (value) => repoManager.setString(StorageKey.repoman_defaultSyncMessage, value),
                      getFn: () => repoManager.getString(StorageKey.repoman_defaultSyncMessage),
                      title: context.t.defaultSyncMessageLabel,
                      description: context.t.syncMessageDescription,
                      hint: defaultSyncMessage,
                      maxLines: null,
                      minLines: null,
                    ),
                    SizedBox(height: spaceMD),
                    ItemSetting(
                      setFn: (value) => repoManager.setString(StorageKey.repoman_defaultSyncMessageTimeFormat, value),
                      getFn: () => repoManager.getString(StorageKey.repoman_defaultSyncMessageTimeFormat),
                      title: context.t.defaultSyncMessageTimeFormatLabel,
                      description: context.t.syncMessageTimeFormatDescription,
                      hint: defaultSyncMessageTimeFormat,
                    ),
                    SizedBox(height: spaceMD),
                    ItemSetting(
                      setFn: (value) => repoManager.setString(StorageKey.repoman_defaultAuthorName, value.trim()),
                      getFn: demo ? () async => "" : () => repoManager.getString(StorageKey.repoman_defaultAuthorName),
                      title: context.t.defaultAuthorNameLabel,
                      description: context.t.authorNameDescription,
                      hint: context.t.authorName,
                    ),
                    SizedBox(height: spaceMD),
                    ItemSetting(
                      setFn: (value) => repoManager.setString(StorageKey.repoman_defaultAuthorEmail, value.trim()),
                      getFn: demo ? () async => "" : () => repoManager.getString(StorageKey.repoman_defaultAuthorEmail),
                      title: context.t.defaultAuthorEmailLabel,
                      description: context.t.authorEmailDescription,
                      hint: context.t.authorEmail,
                    ),
                    SizedBox(height: spaceMD),
                    ItemSetting(
                      setFn: (value) => repoManager.setString(StorageKey.repoman_defaultPostFooter, value),
                      getFn: () => repoManager.getString(StorageKey.repoman_defaultPostFooter),
                      title: context.t.postFooterLabel,
                      description: context.t.postFooterDescription,
                      hint: defaultPostFooter,
                      maxLines: null,
                      minLines: null,
                    ),

                    SizedBox(height: spaceLG + spaceMD),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: spaceMD),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              color: context.colours.tertiaryLight,
                              height: spaceXXXXS,
                              margin: EdgeInsets.only(right: spaceSM),
                            ),
                          ),
                          Text(
                            context.t.miscellaneous.toUpperCase(),
                            style: TextStyle(fontSize: textSM, color: context.colours.primaryLight, fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                            child: Container(
                              color: context.colours.tertiaryLight,
                              height: spaceXXXXS,
                              margin: EdgeInsets.only(left: spaceSM),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: spaceSM),
                    Builder(
                      builder: (context) {
                        final hasPremium = ref.watch(premiumStatusProvider);
                        return ButtonSetting(
                          text: (hasPremium == true ? context.t.contributeTitle : context.t.premiumDialogTitle).toUpperCase(),
                          icon: hasPremium == true ? FontAwesomeIcons.circleDollarToSlot : FontAwesomeIcons.solidGem,
                          iconColor: context.colours.tertiaryPositive,
                          onPressed: () async {
                            if (hasPremium == true) {
                              await launchUrl(Uri.parse(contributeLink));
                            } else {
                              final result = await Navigator.of(context).push(createUnlockPremiumRoute(context, {}));
                              if (result == true && mounted) setState(() {});
                            }
                          },
                        );
                      },
                    ),
                    SizedBox(height: spaceMD),
                    ButtonSetting(
                      text: context.t.viewPrivacyPolicy,
                      icon: FontAwesomeIcons.userShield,
                      onPressed: () async {
                        launchUrl(Uri.parse(privacyPolicyLink));
                      },
                    ),
                    SizedBox(height: spaceMD),
                    ButtonSetting(
                      text: context.t.viewEula,
                      icon: FontAwesomeIcons.fileContract,
                      onPressed: () async {
                        launchUrl(Uri.parse(eulaLink));
                      },
                    ),
                    SizedBox(height: spaceMD),
                    FutureBuilder(
                      future: PackageInfo.fromPlatform(),
                      builder: (context, versionSnapshot) =>
                          ButtonSetting(text: versionSnapshot.data?.version ?? "x.x.xx", icon: FontAwesomeIcons.tag, onPressed: null),
                    ),

                    SizedBox(height: spaceLG),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: spaceMD),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              color: context.colours.tertiaryNegative,
                              height: spaceXXXXS,
                              margin: EdgeInsets.only(right: spaceSM),
                            ),
                          ),
                          Text(
                            context.t.dangerZone.toUpperCase(),
                            style: TextStyle(fontSize: textSM, color: context.colours.tertiaryNegative, fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                            child: Container(
                              color: context.colours.tertiaryNegative,
                              height: spaceXXXXS,
                              margin: EdgeInsets.only(left: spaceSM),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: spaceSM),
                    ButtonSetting(
                      text: context.t.iosClearDataAction,
                      icon: FontAwesomeIcons.dumpsterFire,
                      onPressed: () async {
                        await ConfirmClearDataDialog.showDialog(context, () async {
                          await uiSettingsManager.storage.deleteAll();
                          await repoManager.storage.deleteAll();
                          await uiSettingsManager.reinit();
                          ref.read(premiumStatusProvider.notifier).set(false);

                          Navigator.of(context).canPop() ? Navigator.pop(context) : null;
                        });
                      },
                      buttonColor: context.colours.secondaryNegative,
                    ),
                    SizedBox(height: spaceLG),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

@pragma('vm:entry-point')
Route<String?> createGlobalSettingsMainRoute(BuildContext context, Object? args) {
  final args_ = Map<String, dynamic>.from(args as Map);

  return PageRouteBuilder(
    settings: const RouteSettings(name: global_settings_main),
    pageBuilder: (context, animation, secondaryAnimation) =>
        ShowCaseWidget(builder: (context) => GlobalSettingsMain(onboarding: args_["onboarding"] == true)),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      const curve = Curves.ease;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}
