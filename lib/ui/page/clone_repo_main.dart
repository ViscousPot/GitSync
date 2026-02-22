import 'dart:io';

import 'package:GitSync/api/logger.dart';
import 'package:GitSync/api/manager/git_manager.dart';
import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/ui/dialog/prompt_disable_ssl.dart' as PromptDisableSslDialog;
import 'package:animated_reorderable_list/animated_reorderable_list.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../api/helper.dart';
import '../../../api/manager/auth/git_provider_manager.dart';
import '../../../constant/dimens.dart';
import '../../../constant/strings.dart';
import '../../../global.dart';
import '../../../type/git_provider.dart';
import '../../../ui/dialog/select_folder.dart' as SelectFolderDialog;
import '../../../ui/dialog/cloning_repository.dart' as CloningRepositoryDialog;
import '../../../ui/dialog/repo_url_invalid.dart' as RepoUrlInvalid;
import 'package:GitSync/ui/dialog/error_occurred.dart' as ErrorOccurredDialog;
import '../../../ui/dialog/confirm_clone_overwrite.dart' as ConfirmCloneOverwriteDialog;
import '../dialog/info_dialog.dart' as InfoDialog;

class CloneRepoMain extends StatefulWidget {
  const CloneRepoMain({super.key, this.onboarding = false});

  final bool onboarding;

  @override
  State<CloneRepoMain> createState() => _CloneRepoMain();
}

class _CloneRepoMain extends State<CloneRepoMain> with WidgetsBindingObserver, TickerProviderStateMixin {
  final _controller = ScrollController();
  final searchController = TextEditingController();
  final cloneUrlController = TextEditingController();
  final _urlFocusNode = FocusNode();
  bool _urlFocused = false;

  bool atTop = true;
  bool atBottom = false;

  bool hasList = false;
  bool loadingRepos = false;
  Function()? loadNextRepos;
  final Map<String, String> repoMap = {};

  @override
  void initState() {
    super.initState();
    _controller.addListener(scrollListener);
    _urlFocusNode.addListener(() {
      setState(() => _urlFocused = _urlFocusNode.hasFocus);
    });

    initAsync(() async {
      searchRepos("");
    });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.removeListener(scrollListener);
    _urlFocusNode.dispose();
  }

  void scrollListener() {
    if (_controller.position.atEdge) {
      atTop = _controller.offset == 0;
      atBottom = _controller.offset != 0;
      if (atBottom) {
        if (loadNextRepos == null) return;
        setLoadingRepos(true);
        loadNextRepos!();
      }
    } else {
      atTop = false;
      atBottom = false;
    }

    if (!mounted) return;
    setState(() {});
  }

  Future<void> searchRepos(String searchString) async {
    final gitProviderManager = GitProviderManager.getGitProviderManager(
      await uiSettingsManager.getGitProvider(),
      await uiSettingsManager.getBool(StorageKey.setman_githubScopedOauth),
    );
    if (gitProviderManager == null) return;

    setLoadingRepos(true);
    final accessToken = (await uiSettingsManager.getGitHttpAuthCredentials()).$2;

    gitProviderManager.getRepos(accessToken, searchString, addRepos, (callback) => loadNextRepos = callback);
  }

  void addRepos(List<(String, String)> repos) {
    setLoadingRepos(false);
    hasList = true;

    for (final r in repos) {
      repoMap[r.$1] = r.$2;
    }

    if (!mounted) return;
    setState(() {});
  }

  void setLoadingRepos(bool loading) {
    if (loading && loadNextRepos != null) {
      repoMap[t.loadingElipsis] = t.loadingElipsis;
    } else {
      repoMap.removeWhere((key, value) => key == t.loadingElipsis);
    }
    loadingRepos = loading;

    if (!mounted) return;
    setState(() {});
  }

  bool validateGitRepoUrl(bool isSsh, String url) {
    if (url.isEmpty) return false;

    if (isSsh) {
      return sshPattern.hasMatch(url) ? true : false;
    } else {
      return httpsPattern.hasMatch(url) ? true : false;
    }
  }

  void cloneRepository(String repoUrl) {
    SelectFolderDialog.showDialog(context, (directClone) async {
      String? selectedDirectory;
      if (await requestStoragePerm()) {
        selectedDirectory = await pickDirectory();
      }
      if (selectedDirectory == null) return;

      final nestedDirName = getDirectoryNameFromCloneUrl(repoUrl);

      if (!directClone) {
        if (Platform.isIOS) {
          final bookmarkParts = selectedDirectory.split(conflictSeparator);
          final bookmark = bookmarkParts.first;
          final pathSuffix = selectedDirectory.contains(conflictSeparator) ? bookmarkParts.last : "";
          selectedDirectory = "$bookmark$conflictSeparator${pathSuffix.isEmpty ? nestedDirName : "$pathSuffix/$nestedDirName"}";
        } else {
          selectedDirectory = "$selectedDirectory/$nestedDirName";
        }
        await useDirectory(selectedDirectory, (_) async {}, (selectedDirectory) async {
          final dir = Directory(selectedDirectory);
          print(await dir.exists());
          if (!await dir.exists()) await dir.create();
        }, true);
      }

      final isEmpty = await useDirectory(selectedDirectory, (_) async {}, (selectedDirectory) async {
        final dir = Directory(selectedDirectory);
        return await dir.exists() && (await dir.list().isEmpty);
      });

      Future<void> startClone() async {
        await CloningRepositoryDialog.showDialog(context, repoUrl, selectedDirectory!, (result) async {
          if (result == null) {
            if (!mounted) return;
            await setGitDirPathGetSubmodules(context, selectedDirectory!);
            if (repoUrl.startsWith("http") && !repoUrl.startsWith("https")) {
              await PromptDisableSslDialog.showDialog(context, () async {
                await runGitOperation(LogType.SetDisableSsl, (event) => event, {"disable": true});
              });
            }
            await repoManager.setOnboardingStep(4);
            if (context.mounted) {
              Navigator.of(context).canPop() ? Navigator.pop(context) : null;
            }
          } else {
            await ErrorOccurredDialog.showDialog(context, result, null);
          }
        });
      }

      if (isEmpty == true) {
        await startClone();
      } else {
        await ConfirmCloneOverwriteDialog.showDialog(
          context,
          () async {
            print("////wee $selectedDirectory");
            await runGitOperation(LogType.DiscardDir, (event) => event, {"dirPath": selectedDirectory});
            print("////oui");
          },
          () async {
            await startClone();
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colours.primaryDark,
      resizeToAvoidBottomInset: false,
      appBar: widget.onboarding
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              centerTitle: true,
              leading: getBackButton(context, () => Navigator.of(context).canPop() ? Navigator.pop(context) : null),
              title: Text(
                t.cloneRepo,
                style: TextStyle(color: colours.primaryLight, fontWeight: FontWeight.bold),
              ),
            ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Padding(
        padding: EdgeInsets.symmetric(horizontal: spaceLG),
        child: Column(
          children: [
            if (widget.onboarding) SizedBox(height: spaceSM * 2 + spaceLG),
            if (widget.onboarding)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: animSlow,
                    curve: Curves.easeInOut,
                    width: spaceXXL,
                    height: spaceXXL,
                    child: Image.asset('assets/app_icon.png', fit: BoxFit.cover, color: colours.darkMode ? null : colours.primaryLight),
                  ),
                  SizedBox(height: spaceMD),
                  Text(
                    t.cloneRepo,
                    style: TextStyle(
                      color: colours.primaryLight,
                      fontSize: textMD * 2,
                      fontFamily: "AtkinsonHyperlegible",
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: spaceXS),
                  Text(
                    "Initialise your workspace",
                    style: TextStyle(
                      color: colours.secondaryLight,
                      fontSize: textSM,
                      fontFamily: "AtkinsonHyperlegible",
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            SizedBox(height: spaceLG),
            Expanded(
              child: Builder(
                builder: (context) {
                  final contentColumn = Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      if (hasList)
                        Expanded(
                          flex: _urlFocused ? 0 : 1,
                          child: Container(
                            height: 0,
                            margin: EdgeInsets.only(bottom: spaceLG),
                            decoration: BoxDecoration(
                              color: colours.secondaryDark,
                              borderRadius: BorderRadius.only(
                                topLeft: cornerRadiusMD,
                                bottomLeft: cornerRadiusSM,
                                topRight: cornerRadiusMD,
                                bottomRight: cornerRadiusSM,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  contextMenuBuilder: globalContextMenuBuilder,
                                  controller: searchController,
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: colours.primaryLight,
                                    decoration: TextDecoration.none,
                                    decorationThickness: 0,
                                    fontSize: textMD,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: t.searchEllipsis,
                                    hintStyle: TextStyle(color: colours.secondaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
                                    fillColor: colours.tertiaryDark,
                                    filled: true,
                                    prefixIcon: Padding(
                                      padding: EdgeInsets.only(left: spaceSM, right: spaceXS),
                                      child: FaIcon(FontAwesomeIcons.magnifyingGlass, size: textMD, color: colours.secondaryLight),
                                    ),
                                    prefixIconConstraints: BoxConstraints(minWidth: textMD, minHeight: textMD),
                                    border: const OutlineInputBorder(
                                      borderRadius: BorderRadius.only(
                                        topLeft: cornerRadiusMD,
                                        topRight: cornerRadiusMD,
                                        bottomLeft: cornerRadiusXS,
                                        bottomRight: cornerRadiusXS,
                                      ),
                                      borderSide: BorderSide.none,
                                    ),
                                    suffixIcon: IconButton(
                                      padding: EdgeInsets.symmetric(horizontal: spaceSM),
                                      style: ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                      constraints: BoxConstraints(),
                                      onPressed: () async {
                                        await InfoDialog.showDialog(context, t.repoSearchLimits, t.repoSearchLimitsDescription);
                                      },
                                      visualDensity: VisualDensity.compact,
                                      icon: FaIcon(FontAwesomeIcons.circleInfo, color: colours.secondaryLight, size: textMD),
                                    ),
                                    suffixIconConstraints: BoxConstraints(minWidth: textMD, minHeight: textMD),
                                    isCollapsed: true,
                                    floatingLabelBehavior: FloatingLabelBehavior.always,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceXS),
                                    isDense: true,
                                  ),
                                  onChanged: (text) async {
                                    repoMap.clear();
                                    setState(() {});
                                    debounce("clone_repo_search_string", 500, () async {
                                      await searchRepos(text);
                                    });
                                  },
                                ),
                                SizedBox(height: spaceMD),
                                Expanded(
                                  child: ShaderMask(
                                    shaderCallback: (Rect rect) {
                                      return LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          atTop ? Colors.transparent : Colors.black,
                                          Colors.transparent,
                                          Colors.transparent,
                                          atBottom ? Colors.transparent : Colors.black,
                                        ],
                                        stops: [0.0, 0.1, 0.9, 1.0],
                                      ).createShader(rect);
                                    },
                                    blendMode: BlendMode.dstOut,
                                    child: AnimatedListView(
                                      items: repoMap.entries.toList(),
                                      padding: EdgeInsets.only(bottom: spaceMD, left: spaceMD, right: spaceMD),
                                      controller: _controller,
                                      isSameItem: (a, b) => a.value == b.value,
                                      itemBuilder: (BuildContext context, int index) {
                                        final repo = repoMap.entries.toList()[index];
                                        return Container(
                                          key: Key("${searchController.text} ${repo.key}"),
                                          width: double.infinity,
                                          margin: EdgeInsets.only(bottom: spaceMD),
                                          child: TextButton.icon(
                                            onPressed: () => cloneRepository(repo.value),
                                            style: ButtonStyle(
                                              alignment: Alignment.centerLeft,
                                              backgroundColor: WidgetStatePropertyAll(colours.tertiaryDark),
                                              padding: WidgetStatePropertyAll(
                                                EdgeInsets.only(right: spaceMD, top: spaceSM, bottom: spaceSM, left: spaceXS),
                                              ),
                                              shape: WidgetStatePropertyAll(
                                                RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
                                              ),
                                            ),
                                            iconAlignment: IconAlignment.end,
                                            icon: FaIcon(FontAwesomeIcons.solidCircleDown, color: colours.primaryPositive, size: textXL),
                                            label: Container(
                                              width: double.infinity,
                                              padding: EdgeInsets.only(left: spaceXS),
                                              child: Text(
                                                repo.key,
                                                maxLines: 1,
                                                style: TextStyle(
                                                  overflow: TextOverflow.ellipsis,
                                                  color: colours.primaryLight,
                                                  fontSize: textLG,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Column(
                        children: [
                          SizedBox(height: spaceLG),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: TextField(
                                    contextMenuBuilder: globalContextMenuBuilder,
                                    controller: cloneUrlController,
                                    focusNode: _urlFocusNode,
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: colours.primaryLight,
                                      decoration: TextDecoration.none,
                                      decorationThickness: 0,
                                      fontSize: textLG,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: t.gitRepoUrlHint,
                                      hintStyle: TextStyle(color: colours.secondaryLight, fontSize: textLG),
                                      fillColor: colours.secondaryDark,
                                      filled: true,
                                      border: const OutlineInputBorder(borderRadius: BorderRadius.all(cornerRadiusMD), borderSide: BorderSide.none),
                                      isCollapsed: true,
                                      floatingLabelBehavior: FloatingLabelBehavior.always,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM),
                                      isDense: true,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                SizedBox(width: spaceMD),
                                TextButton.icon(
                                  onPressed: cloneUrlController.text.isEmpty
                                      ? null
                                      : () async {
                                          final isValid = validateGitRepoUrl(
                                            await uiSettingsManager.getGitProvider() == GitProvider.SSH,
                                            cloneUrlController.text,
                                          );
                                          if (isValid) {
                                            cloneRepository(cloneUrlController.text);
                                          } else {
                                            RepoUrlInvalid.showDialog(context, () => cloneRepository(cloneUrlController.text));
                                          }
                                        },
                                  style: ButtonStyle(
                                    alignment: Alignment.center,
                                    backgroundColor: WidgetStatePropertyAll(colours.secondaryDark),
                                    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: 0)),
                                    shape: WidgetStatePropertyAll(
                                      RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
                                    ),
                                  ),
                                  icon: FaIcon(
                                    FontAwesomeIcons.solidCircleDown,
                                    color: cloneUrlController.text.isEmpty ? colours.secondaryPositive : colours.primaryPositive,
                                    size: textLG,
                                  ),
                                  label: Padding(
                                    padding: EdgeInsets.only(left: spaceXS),
                                    child: Text(
                                      t.clone.toUpperCase(),
                                      style: TextStyle(
                                        color: cloneUrlController.text.isEmpty ? colours.tertiaryLight : colours.primaryLight,
                                        fontSize: textMD,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: spaceXXL),
                        ],
                      ),
                      Column(
                        children: [
                          Container(height: 2, color: colours.secondaryDark),
                          SizedBox(height: spaceXXL),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: TextButton.icon(
                                    iconAlignment: IconAlignment.end,
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
                                      await setGitDirPathGetSubmodules(context, selectedDirectory);
                                      await repoManager.setOnboardingStep(4);
                                      setState(() {});

                                      Navigator.of(context).canPop() ? Navigator.pop(context) : null;
                                      if (mounted) setState(() {});
                                    },
                                    style: ButtonStyle(
                                      alignment: Alignment.center,
                                      backgroundColor: WidgetStatePropertyAll(colours.secondaryDark),
                                      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD)),
                                      shape: WidgetStatePropertyAll(
                                        RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
                                      ),
                                    ),
                                    icon: FaIcon(FontAwesomeIcons.solidFolderOpen, color: colours.primaryLight, size: textMD),
                                    label: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.only(left: spaceXS),
                                      child: Text(
                                        t.iHaveALocalRepository.toUpperCase(),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: colours.primaryLight, fontSize: textMD),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: spaceXXL),
                        ],
                      ),
                    ],
                  );
                  if (!widget.onboarding) return contentColumn;
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: SizedBox(
                          height: constraints.maxHeight < spaceXXL * 2 * 5.5 ? spaceXXL * 2 * 5.5 : constraints.maxHeight,
                          child: contentColumn,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

@pragma('vm:entry-point')
Route createCloneRepoMainRoute() {
  return PageRouteBuilder(
    settings: const RouteSettings(name: clone_repo_main),
    pageBuilder: (context, animation, secondaryAnimation) => const CloneRepoMain(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      const curve = Curves.ease;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}

@pragma('vm:entry-point')
Route<String?> createOnboardingCloneRepoMainRoute(BuildContext context, Object? args) {
  return PageRouteBuilder(
    settings: const RouteSettings(name: clone_repo_main),
    pageBuilder: (context, animation, secondaryAnimation) => const CloneRepoMain(onboarding: true),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      const curve = Curves.ease;
      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}
