import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/type/git_provider.dart';
import 'package:GitSync/ui/component/button_setting.dart';
import 'package:GitSync/ui/component/sync_client_mode_toggle.dart';
import 'package:GitSync/ui/page/global_settings_main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../../api/helper.dart';
import '../../../api/manager/git_manager.dart';
import '../../../constant/colors.dart';
import '../../../constant/dimens.dart';
import '../../../constant/strings.dart';
import '../../../global.dart';
import '../../../ui/component/item_setting.dart';
import 'package:GitSync/ui/dialog/import_priv_key.dart' as ImportPrivKeyDialog;

class SettingsMain extends StatefulWidget {
  const SettingsMain({super.key, this.showcaseAuthorDetails = false});

  final bool showcaseAuthorDetails;

  @override
  State<SettingsMain> createState() => _SettingsMain();
}

class _SettingsMain extends State<SettingsMain> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _borderVisible = false;
  final _controller = ScrollController();
  final _authorDetailsKey = GlobalKey();
  bool atTop = true;
  bool unstaging = false;
  bool ignoreChanged = false;
  String? gitDirPath;
  final _landscapeScrollControllerLeft = ScrollController();
  final _landscapeScrollControllerRight = ScrollController();

  static const duration = Duration(seconds: 1);

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      atTop = _controller.offset <= 0;
      setState(() {});
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

    _pulseController = AnimationController(duration: duration, vsync: this);
    _pulseController.stop();

    _pulseController.addListener(() {
      setState(() {
        _borderVisible = _pulseController.value > 0.5;
      });
    });

    if (widget.showcaseAuthorDetails) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        ShowCaseWidget.of(context).startShowCase([_authorDetailsKey]);
      });
    }

    initAsync(() async {
      gitDirPath = await uiSettingsManager.getStringNullable(StorageKey.setman_gitDirPath);
      if (gitDirPath == "") gitDirPath = null;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void writeGitignore(String gitignoreString) {
    if (!ignoreChanged) {
      ignoreChanged = true;
      _pulseController.repeat(reverse: true);
      setState(() {});
    }
    GitManager.writeGitignore(gitignoreString);
  }

  void writeGitInfoExclude(String gitInfoExcludeString) {
    if (!ignoreChanged) {
      ignoreChanged = true;
      _pulseController.repeat(reverse: true);
      setState(() {});
    }
    GitManager.writeGitInfoExclude(gitInfoExcludeString);
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
          t.settings.toUpperCase(),
          style: TextStyle(color: primaryLight, fontWeight: FontWeight.bold),
        ),
      ),
      body: OrientationBuilder(
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
                    SizedBox(height: spaceXXS),
                    SyncClientModeToggle(),
                    gitDirPath == null
                        ? SizedBox.shrink()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              SizedBox(height: spaceMD + spaceSM),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: spaceMD),
                                child: Text(
                                  t.signedCommitsLabel.toUpperCase(),
                                  style: TextStyle(color: primaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: spaceMD),
                                child: Text(
                                  t.signedCommitsDescription,
                                  style: TextStyle(color: secondaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                                ),
                              ),
                              SizedBox(height: spaceSM),
                              FutureBuilder(
                                future: uiSettingsManager.getStringNullable(StorageKey.setman_gitCommitSigningKey),
                                builder: (context, gitCommitSigningKeySnapshot) => Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(color: tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusMD)),
                                  child: FutureBuilder(
                                    future: uiSettingsManager.getGitProvider(),
                                    builder: (context, snapshot) => Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        snapshot.data == GitProvider.SSH && gitCommitSigningKeySnapshot.data == ""
                                            ? SizedBox.shrink()
                                            : Row(
                                                children: [
                                                  Expanded(
                                                    child: TextButton.icon(
                                                      onPressed: () async {
                                                        await ImportPrivKeyDialog.showDialog(context, ((String, String) sshCredentials) async {
                                                          await uiSettingsManager.setStringNullable(
                                                            StorageKey.setman_gitCommitSigningKey,
                                                            sshCredentials.$2,
                                                          );
                                                          await uiSettingsManager.setStringNullable(
                                                            StorageKey.setman_gitCommitSigningPassphrase,
                                                            sshCredentials.$1,
                                                          );
                                                          setState(() {});
                                                        });
                                                      },
                                                      style: ButtonStyle(
                                                        alignment: Alignment.centerLeft,
                                                        backgroundColor: WidgetStatePropertyAll(tertiaryDark),
                                                        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM)),
                                                        shape: WidgetStatePropertyAll(
                                                          RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.all(cornerRadiusMD),
                                                            side: BorderSide.none,
                                                          ),
                                                        ),
                                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                        minimumSize: WidgetStatePropertyAll(Size.zero),
                                                      ),
                                                      icon: FaIcon(
                                                        FontAwesomeIcons.key,
                                                        color: gitCommitSigningKeySnapshot.data?.isNotEmpty == true ? primaryPositive : primaryLight,
                                                      ),
                                                      label: Padding(
                                                        padding: EdgeInsets.only(left: spaceXS),
                                                        child: Text(
                                                          (gitCommitSigningKeySnapshot.data?.isNotEmpty == true
                                                                  ? t.commitKeyImported
                                                                  : t.importCommitKey)
                                                              .toUpperCase(),
                                                          style: TextStyle(
                                                            color: gitCommitSigningKeySnapshot.data?.isNotEmpty == true
                                                                ? primaryPositive
                                                                : primaryLight,
                                                            fontSize: textMD,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  gitCommitSigningKeySnapshot.data?.isNotEmpty == true
                                                      ? IconButton(
                                                          padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM),
                                                          style: ButtonStyle(
                                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                            shape: WidgetStatePropertyAll(
                                                              RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.all(cornerRadiusMD),
                                                                side: BorderSide.none,
                                                              ),
                                                            ),
                                                          ),
                                                          constraints: BoxConstraints(),
                                                          onPressed: () async {
                                                            await uiSettingsManager.setStringNullable(
                                                              StorageKey.setman_gitCommitSigningPassphrase,
                                                              null,
                                                            );
                                                            await uiSettingsManager.setStringNullable(StorageKey.setman_gitCommitSigningKey, null);
                                                            setState(() {});
                                                          },
                                                          icon: FaIcon(FontAwesomeIcons.trash, color: tertiaryNegative, size: textMD),
                                                        )
                                                      : SizedBox.shrink(),
                                                ],
                                              ),
                                        snapshot.data == GitProvider.SSH &&
                                                (gitCommitSigningKeySnapshot.data == null || gitCommitSigningKeySnapshot.data == "")
                                            ? TextButton.icon(
                                                onPressed: () async {
                                                  await uiSettingsManager.setStringNullable(
                                                    StorageKey.setman_gitCommitSigningKey,
                                                    gitCommitSigningKeySnapshot.data == null ? "" : null,
                                                  );
                                                  setState(() {});
                                                },
                                                style: ButtonStyle(
                                                  alignment: Alignment.centerLeft,
                                                  backgroundColor: WidgetStatePropertyAll(tertiaryDark),
                                                  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM)),
                                                  shape: WidgetStatePropertyAll(
                                                    RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
                                                  ),
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  minimumSize: WidgetStatePropertyAll(Size.zero),
                                                ),
                                                iconAlignment: IconAlignment.end,
                                                icon: FaIcon(
                                                  gitCommitSigningKeySnapshot.data != null
                                                      ? FontAwesomeIcons.solidSquareCheck
                                                      : FontAwesomeIcons.squareCheck,
                                                  color: primaryPositive,
                                                  size: textLG,
                                                ),
                                                label: SizedBox(
                                                  width: double.infinity,
                                                  child: Text(
                                                    t.useSshKey.toUpperCase(),
                                                    style: TextStyle(color: primaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              )
                                            : SizedBox.shrink(),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                    SizedBox(height: spaceMD),
                    ItemSetting(
                      setFn: (value) => uiSettingsManager.setStringNullable(StorageKey.setman_syncMessage, value),
                      getFn: () => uiSettingsManager.getSyncMessage(),
                      title: t.syncMessageLabel,
                      description: t.syncMessageDescription,
                      hint: defaultSyncMessage,
                      maxLines: null,
                      minLines: null,
                    ),
                    SizedBox(height: spaceMD),
                    ItemSetting(
                      setFn: (value) => uiSettingsManager.setStringNullable(StorageKey.setman_syncMessageTimeFormat, value),
                      getFn: () => uiSettingsManager.getSyncMessageTimeFormat(),
                      title: t.syncMessageTimeFormatLabel,
                      description: t.syncMessageTimeFormatDescription,
                      hint: defaultSyncMessageTimeFormat,
                    ),
                    SizedBox(height: spaceLG),
                    Showcase(
                      key: _authorDetailsKey,
                      description: t.authorDetailsShowcasePrompt,
                      tooltipBackgroundColor: tertiaryInfo,
                      textColor: secondaryDark,
                      targetBorderRadius: BorderRadius.all(cornerRadiusMD),
                      descTextStyle: TextStyle(fontSize: textMD, fontWeight: FontWeight.w500, color: primaryDark),
                      targetPadding: EdgeInsets.all(spaceSM),
                      child: Column(
                        children: [
                          ItemSetting(
                            setFn: (value) => uiSettingsManager.setStringNullable(StorageKey.setman_authorName, value.trim()),
                            getFn: demo ? () async => "" : () => uiSettingsManager.getAuthorName(),
                            title: t.authorNameLabel,
                            hint: t.authorName,
                          ),
                          SizedBox(height: spaceMD),
                          ItemSetting(
                            setFn: (value) => uiSettingsManager.setStringNullable(StorageKey.setman_authorEmail, value.trim()),
                            getFn: demo ? () async => "" : () => uiSettingsManager.getAuthorEmail(),
                            title: t.authorEmailLabel,
                            hint: t.authorEmail,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: spaceLG),
                    ItemSetting(
                      setFn: (value) => uiSettingsManager.setStringNullable(StorageKey.setman_remote, value),
                      getFn: () => uiSettingsManager.getRemote(),
                      title: t.remoteLabel,
                      hint: t.defaultRemote,
                    ),
                    if (orientation == Orientation.landscape) SizedBox(height: spaceLG),
                  ]),

                  SizedBox(height: spaceLG, width: spaceLG),

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
                    ...gitDirPath == null
                        ? []
                        : [
                            TextButton(
                              onPressed: () async {
                                unstaging = true;
                                setState(() {});

                                await GitManager.untrackAll();

                                unstaging = false;
                                ignoreChanged = false;
                                _pulseController.stop();
                                setState(() {});
                              },
                              style: ButtonStyle(
                                alignment: Alignment.center,
                                backgroundColor: WidgetStatePropertyAll(tertiaryDark),
                                padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceMD)),
                                animationDuration: duration,
                                shape: WidgetStatePropertyAll(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(cornerRadiusMD),
                                    side: ignoreChanged || unstaging
                                        ? (_borderVisible
                                              ? BorderSide(color: secondaryLight, width: spaceXXXS)
                                              : BorderSide(color: secondaryLight.withAlpha(150), width: spaceXXXS - 2))
                                        : BorderSide.none,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: textMD,
                                    width: textMD,
                                    child: CircularProgressIndicator(color: !unstaging ? Colors.transparent : primaryLight),
                                  ),
                                  SizedBox(width: spaceSM),
                                  Padding(
                                    padding: EdgeInsets.only(left: spaceXS),
                                    child: Text(
                                      t.untrackAll.toUpperCase(),
                                      style: TextStyle(color: primaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  SizedBox(width: textMD + spaceSM),
                                ],
                              ),
                            ),
                            SizedBox(height: spaceMD),
                            ItemSetting(
                              setFn: writeGitignore,
                              getFn: demo ? () async => "" : GitManager.readGitignore,
                              title: t.gitIgnore,
                              description: t.gitIgnoreDescription,
                              hint: t.gitIgnoreHint,
                              maxLines: -1,
                              minLines: -1,
                              isTextArea: true,
                            ),
                            SizedBox(height: spaceMD),
                            ItemSetting(
                              setFn: writeGitInfoExclude,
                              getFn: demo ? () async => "" : GitManager.readGitInfoExclude,
                              title: t.gitInfoExclude,
                              description: t.gitInfoExcludeDescription,
                              hint: t.gitInfoExcludeHint,
                              maxLines: -1,
                              minLines: -1,
                              isTextArea: true,
                            ),
                            SizedBox(height: spaceSM),
                            FutureBuilder(
                              future: GitManager.getDisableSsl(),
                              builder: (context, snapshot) => TextButton.icon(
                                onPressed: () async {
                                  await GitManager.setDisableSsl(!(snapshot.data ?? false));
                                  setState(() {});
                                },
                                style: ButtonStyle(
                                  shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD))),
                                ),
                                label: SizedBox(
                                  width: double.infinity,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.disableSsl.toUpperCase(),
                                        style: TextStyle(color: primaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        t.disableSslDescription,
                                        style: TextStyle(color: secondaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                iconAlignment: IconAlignment.end,
                                icon: FaIcon(
                                  snapshot.data == true ? FontAwesomeIcons.solidSquareCheck : FontAwesomeIcons.squareCheck,
                                  color: primaryPositive,
                                  size: textLG,
                                ),
                              ),
                            ),
                            SizedBox(height: spaceSM),
                            FutureBuilder(
                              future: uiSettingsManager.getBool(StorageKey.setman_optimisedSyncExperimental),
                              builder: (context, optimisedSyncSnapshot) => TextButton.icon(
                                onPressed: () async {
                                  await uiSettingsManager.setBool(
                                    StorageKey.setman_optimisedSyncExperimental,
                                    !(optimisedSyncSnapshot.data ?? false),
                                  );
                                  setState(() {});
                                },
                                style: ButtonStyle(
                                  shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD))),
                                ),
                                label: SizedBox(
                                  width: double.infinity,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${t.optimisedSync.toUpperCase()} (${t.experimental.toLowerCase()})".toUpperCase(),
                                        style: TextStyle(color: primaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        t.optimisedSyncDescription,
                                        style: TextStyle(color: secondaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                iconAlignment: IconAlignment.end,
                                icon: FaIcon(
                                  optimisedSyncSnapshot.data == true ? FontAwesomeIcons.solidSquareCheck : FontAwesomeIcons.squareCheck,
                                  color: primaryPositive,
                                  size: textLG,
                                ),
                              ),
                            ),
                          ],
                    SizedBox(height: spaceMD),
                    ButtonSetting(
                      text: t.moreOptions,
                      icon: FontAwesomeIcons.ellipsisVertical,
                      onPressed: () async {
                        Navigator.of(context).canPop() ? Navigator.pop(context) : null;
                        await Navigator.of(context).push(createGlobalSettingsMainRoute());
                      },
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

Route createSettingsMainRoute({bool showcaseAuthorDetails = false}) {
  return PageRouteBuilder(
    settings: const RouteSettings(name: settings_main),
    pageBuilder: (context, animation, secondaryAnimation) =>
        ShowCaseWidget(builder: (context) => SettingsMain(showcaseAuthorDetails: showcaseAuthorDetails)),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      const curve = Curves.ease;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}
