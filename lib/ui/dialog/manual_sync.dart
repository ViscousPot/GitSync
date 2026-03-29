import 'package:GitSync/api/helper.dart';
import 'package:GitSync/api/logger.dart';
import 'package:animated_reorderable_list/animated_reorderable_list.dart';
import 'package:collection/collection.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/ui/component/ai_wand_field.dart';
import 'package:GitSync/api/ai_completion_service.dart';
import 'package:GitSync/api/manager/git_manager.dart';
import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/constant/strings.dart';
import 'package:GitSync/global.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';
import 'package:GitSync/ui/dialog/confirm_discard_changes.dart' as ConfirmDiscardChangesDialog;

Widget outlineCircleMinus({required double size, required Color color}) => Stack(
  alignment: Alignment.center,
  children: [
    FaIcon(FontAwesomeIcons.circle, size: size, color: color),
    FaIcon(FontAwesomeIcons.minus, size: size * 0.5, color: color),
  ],
);

Future<bool> showDialog(BuildContext context, {bool? hasRemotes}) async {
  final syncMessageController = TextEditingController();
  final selectedFiles = <String>[];
  final lineSelections = <String, Set<int>>{};
  final pageController = PageController();
  final diffCache = <String, Future<Map<String, dynamic>?>>{};

  final clientModeEnabled = await uiSettingsManager.getClientModeEnabled();
  final editorLineWrap = await repoManager.getBool(StorageKey.repoman_editorLineWrap);
  final bool resolvedHasRemotes =
      hasRemotes ??
      (await runGitOperation<List<String>>(LogType.ListRemotes, (event) => event?["result"].map<String>((r) => "$r").toList()))?.isNotEmpty == true;

  if (demo) {
    selectedFiles.add("storage/external/example/file_changed.md");
  }

  bool uploading = false;
  bool staging = false;
  bool unstaging = false;
  bool onLinesPage = false;
  bool committed = false;
  String? currentDiffFile;
  StateSetter? setStater;

  Future<List<(String, int)>> uncommitedFilePaths = runGitOperation<List<(String, int)>>(
    LogType.UncommittedFiles,
    (event) => event?["result"].map<(String, int)>((item) => ("${item[0]}", int.parse("${item[1]}"))).toList() ?? [],
  );
  Future<List<(String, int)>> stagedFilePaths = runGitOperation<List<(String, int)>>(
    LogType.StagedFiles,
    (event) => event?["result"].map<(String, int)>((item) => ("${item[0]}", int.parse("${item[1]}"))).toList() ?? [],
  );

  Future<void> reload() async {
    uncommitedFilePaths = runGitOperation<List<(String, int)>>(
      LogType.UncommittedFiles,
      (event) => event?["result"].map<(String, int)>((item) => ("${item[0]}", int.parse("${item[1]}"))).toList() ?? [],
    );

    stagedFilePaths = runGitOperation<List<(String, int)>>(
      LogType.StagedFiles,
      (event) => event?["result"].map<(String, int)>((item) => ("${item[0]}", int.parse("${item[1]}"))).toList(),
    );

    diffCache.clear();

    if (context.mounted) setStater?.call(() {});
  }

  void flushLineStage(String filePath, Set<int> selections, {bool isUnstaging = false}) {
    if (isUnstaging) {
      unstaging = true;
    } else {
      staging = true;
    }
    if (context.mounted) setStater?.call(() {});

    final Future<void> op;
    if (selections.isEmpty) {
      lineSelections.remove(filePath);
      op = runGitOperation(LogType.Unstage, (event) => event, {"paths": [filePath]});
    } else {
      op = runGitOperation(LogType.StageFileLines, (event) => event, {
        "filePath": filePath,
        "selectedLineIndices": selections.toList(),
      });
    }

    op.then((_) {
      diffCache.remove(filePath);
      diffCache[filePath] = runGitOperation(
        LogType.WorkdirFileDiff,
        (event) => event,
        {"filePath": filePath},
      );
      staging = false;
      unstaging = false;
      reload();
    });
  }

  await mat.showDialog(
    context: context,
    barrierColor: Colors.transparent,
    builder: (BuildContext context) => PopScope(
      canPop: !uploading,
      child: StatefulBuilder(
        builder: (context, setState) {
          setStater = setState;
          SystemChannels.lifecycle.setMessageHandler((msg) async {
            if (msg == appLifecycleStateResumed) {
              try {
                setState(() {});
              } catch (e) {
                /**/
              }

              return null;
            }
            return msg;
          });
          return FutureBuilder(
            future: uncommitedFilePaths,
            builder: (context, uncommittedFilePathsSnapshot) => FutureBuilder(
              future: stagedFilePaths,
              builder: (context, stagedFilePathsSnapshot) {
                final List<(String, int)> filePaths = clientModeEnabled
                    ? [
                        ...(uncommittedFilePathsSnapshot.data ?? <(String, int)>[]),
                        ...(stagedFilePathsSnapshot.data ?? <(String, int)>[]),
                      ]
                        .fold<List<(String, int)>>([], (list, item) {
                          if (!list.any((e) => e.$1 == item.$1)) list.add(item);
                          return list;
                        })
                        .sorted((a, b) => a.$1.toLowerCase().compareTo(b.$1.toLowerCase()))
                    : uncommittedFilePathsSnapshot.data ?? <(String, int)>[];
                return BaseAlertDialog(
                  expandable: true,
                  title: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Text(
                      (clientModeEnabled ? t.stageAndCommit : t.manualSync).toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
                    ),
                  ),
                  contentBuilder: (expanded) =>
                      (expanded
                      ? (List<Widget> children) => Column(children: children)
                      : (List<Widget> children) => SingleChildScrollView(child: ListBody(children: children)))(<Widget>[
                        Text(
                          t.manualSyncMsg,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colours.primaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
                        ),
                        SizedBox(height: spaceMD + spaceSM),
                        IntrinsicHeight(
                          child: Row(
                            // crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: AiWandField(
                                  multiline: true,
                                  enabled: (stagedFilePathsSnapshot.data ?? []).isNotEmpty || (uncommittedFilePathsSnapshot.data ?? []).isNotEmpty,
                                  onPressed: () async {
                                    final staged = await stagedFilePaths;
                                    final files = staged.isNotEmpty
                                        ? staged
                                        : (await uncommitedFilePaths);
                                    const statusLabels = {0: 'added', 1: 'modified', 2: 'deleted', 3: 'added'};
                                    final buffer = StringBuffer();
                                    for (final (filePath, fileType) in files) {
                                      final status = statusLabels[fileType] ?? 'changed';
                                      buffer.writeln('File ($status): $filePath');
                                      final diff = await GitManager.getWorkdirFileDiff(filePath);
                                      if (diff != null) {
                                        buffer.writeln('+${diff.insertions}/-${diff.deletions}');
                                        for (final line in diff.lines) {
                                          if (buffer.length > 4000) break;
                                          if (line.origin == 'H') {
                                            buffer.writeln(line.content);
                                          } else {
                                            buffer.writeln('${line.origin}${line.content}');
                                          }
                                        }
                                      }
                                      buffer.writeln();
                                      if (buffer.length > 4000) break;
                                    }
                                    final result = await aiComplete(
                                      systemPrompt: "Generate a concise git commit message for these changes. Use conventional commit format (type: description). Output only the commit message, nothing else.",
                                      userPrompt: buffer.toString(),
                                    );
                                    if (result != null) syncMessageController.text = result.trim();
                                  },
                                  child: TextField(
                                    contextMenuBuilder: globalContextMenuBuilder,
                                    controller: syncMessageController,
                                    maxLines: null,
                                    style: TextStyle(
                                      color: colours.primaryLight,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.none,
                                      decorationThickness: 0,
                                      fontSize: textMD,
                                    ),
                                    decoration: InputDecoration(
                                      fillColor: colours.secondaryDark,
                                      filled: true,
                                      border: const OutlineInputBorder(borderRadius: BorderRadius.all(cornerRadiusSM), borderSide: BorderSide.none),
                                      hintText: defaultSyncMessage,
                                      isCollapsed: true,
                                      label: Text(
                                        t.commitMessage.toUpperCase(),
                                        style: TextStyle(color: colours.secondaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                                      ),
                                      floatingLabelBehavior: FloatingLabelBehavior.always,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM),
                                      isDense: true,
                                    ),
                                    onChanged: (_) {
                                      if (context.mounted) setState(() {});
                                    },
                                  ),
                                ),
                              ),
                              if (clientModeEnabled) SizedBox(width: spaceSM),
                              if (clientModeEnabled)
                                TextButton.icon(
                                  onPressed: !uploading && (stagedFilePathsSnapshot.data ?? []).isNotEmpty
                                      ? () async {
                                          uploading = true;
                                          if (context.mounted) setState(() {});

                                          await runGitOperation(LogType.Commit, (event) => event, {
                                            "syncMessage": syncMessageController.text.isEmpty ? null : syncMessageController.text,
                                          });
                                          committed = true;
                                          uploading = false;
                                          await reload();
                                          if (context.mounted) setStater?.call(() {});
                                        }
                                      : null,
                                  style: ButtonStyle(
                                    alignment: Alignment.center,
                                    backgroundColor: WidgetStatePropertyAll(
                                      (stagedFilePathsSnapshot.data ?? []).isNotEmpty ? colours.primaryPositive : colours.tertiaryDark,
                                    ),
                                    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM * 1.15)),
                                    shape: WidgetStatePropertyAll(
                                      RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM), side: BorderSide.none),
                                    ),
                                  ),
                                  icon: uploading
                                      ? Container(
                                          height: textSM,
                                          width: textSM,
                                          margin: EdgeInsets.only(right: spaceXXXS),
                                          child: CircularProgressIndicator(color: colours.tertiaryDark),
                                        )
                                      : null,
                                  label: Text(
                                    t.commit.toUpperCase(),
                                    style: TextStyle(
                                      color: (stagedFilePathsSnapshot.data ?? []).isNotEmpty ? colours.tertiaryDark : colours.tertiaryLight,
                                      fontSize: textSM,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: spaceMD),
                        (expanded ? (Widget child) => Expanded(child: child) : (child) => child)(
                          Container(
                            decoration: BoxDecoration(borderRadius: BorderRadius.all(cornerRadiusSM), color: colours.secondaryDark),
                            padding: EdgeInsets.only(left: spaceXXS, right: spaceXXS, bottom: spaceXXS, top: spaceXXXS),
                            child: SizedBox(
                              height: expanded ? null : MediaQuery.sizeOf(context).height / 3,
                              width: double.maxFinite,
                              child:
                                  (clientModeEnabled
                                      ? uncommittedFilePathsSnapshot.data == null &&
                                            (stagedFilePathsSnapshot.data == null || stagedFilePathsSnapshot.data?.isEmpty == true)
                                      : uncommittedFilePathsSnapshot.data == null)
                                  ? Center(child: CircularProgressIndicator(color: colours.tertiaryLight))
                                  : filePaths.isEmpty
                                  ? Center(
                                      child: Text(
                                        t.noUncommittedChanges.toUpperCase(),
                                        style: TextStyle(fontWeight: FontWeight.bold, color: colours.primaryLight, fontSize: textMD),
                                      ),
                                    )
                                  : PageView(
                                      controller: pageController,
                                      physics: NeverScrollableScrollPhysics(),
                                      children: [
                                        Builder(builder: (context) {
                                          final hasExplicitSelection = selectedFiles.isNotEmpty || lineSelections.isNotEmpty;

                                          return Column(
                                          children: [
                                            Container(
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  TextButton.icon(
                                                    onPressed: () {
                                                      if (selectedFiles.isNotEmpty || lineSelections.isNotEmpty) {
                                                        selectedFiles.clear();
                                                        lineSelections.clear();
                                                      } else {
                                                        selectedFiles.clear();
                                                        lineSelections.clear();
                                                        selectedFiles.addAll(filePaths.map((item) => item.$1).toList());
                                                      }

                                                      if (context.mounted) setState(() {});
                                                    },
                                                    style: ButtonStyle(
                                                      alignment: Alignment.center,
                                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                      padding: WidgetStatePropertyAll(
                                                        EdgeInsets.symmetric(vertical: spaceXS, horizontal: spaceXS + spaceXXXS),
                                                      ),
                                                      shape: WidgetStatePropertyAll(
                                                        RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM)),
                                                      ),
                                                    ),
                                                    icon: uncommittedFilePathsSnapshot.data?.isEmpty != true &&
                                                            selectedFiles.length == uncommittedFilePathsSnapshot.data?.length &&
                                                            lineSelections.isEmpty
                                                        ? FaIcon(
                                                            FontAwesomeIcons.solidCircleCheck,
                                                            color: hasExplicitSelection ? colours.secondaryInfo : colours.tertiaryInfo,
                                                            size: textMD,
                                                          )
                                                        : FaIcon(
                                                            hasExplicitSelection ? FontAwesomeIcons.solidCircleCheck : FontAwesomeIcons.circleCheck,
                                                            color: hasExplicitSelection ? colours.secondaryInfo : colours.tertiaryInfo,
                                                            size: textMD,
                                                          ),
                                                    label: Text(
                                                      (hasExplicitSelection ? t.deselectAll : t.selectAll).toUpperCase(),
                                                      style: TextStyle(fontWeight: FontWeight.bold, color: colours.primaryLight),
                                                    ),
                                                  ),
                                                  uncommittedFilePathsSnapshot.connectionState == ConnectionState.waiting ||
                                                          stagedFilePathsSnapshot.connectionState == ConnectionState.waiting
                                                      ? Padding(
                                                          padding: EdgeInsetsGeometry.only(right: spaceSM),
                                                          child: SizedBox.square(
                                                            dimension: spaceMD,
                                                            child: CircularProgressIndicator(color: colours.primaryLight),
                                                          ),
                                                        )
                                                      : SizedBox.shrink(),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              child: AnimatedListView(
                                                items: filePaths,
                                                itemBuilder: (context, index) {
                                                  final fileName = filePaths[index].$1;
                                                  final fileType = filePaths[index].$2;

                                                  bool isStagedFile() =>
                                                      stagedFilePathsSnapshot.data?.map((file) => file.$1).contains(fileName) == true;

                                                  final bool isPartiallyStagedFile = clientModeEnabled &&
                                                      isStagedFile() &&
                                                      (uncommittedFilePathsSnapshot.data ?? []).any((f) => f.$1 == fileName);
                                                  final bool isWholeFileSelected = selectedFiles.contains(fileName);
                                                  final bool hasLineSelections =
                                                      !isWholeFileSelected && (lineSelections.containsKey(fileName) || isPartiallyStagedFile);

                                                  (FaIconData, (Color, Color)) infoIcon = (
                                                    FontAwesomeIcons.solidSquarePlus,
                                                    (colours.tertiaryPositive, colours.primaryPositive),
                                                  );
                                                  switch (fileType) {
                                                    case 1:
                                                      {
                                                        infoIcon = (FontAwesomeIcons.squarePen, (colours.tertiaryWarning, colours.primaryWarning));
                                                        break;
                                                      }
                                                    case 2:
                                                      {
                                                        infoIcon = (
                                                          FontAwesomeIcons.solidSquareMinus,
                                                          (colours.tertiaryNegative, colours.tertiaryNegative),
                                                        );
                                                        break;
                                                      }
                                                    case 3:
                                                      {
                                                        infoIcon = (
                                                          FontAwesomeIcons.solidSquarePlus,
                                                          (colours.tertiaryPositive, colours.primaryPositive),
                                                        );
                                                        break;
                                                      }
                                                  }

                                                  return TextButton(
                                                    key: Key(fileName),
                                                    style: ButtonStyle(
                                                      backgroundColor: WidgetStatePropertyAll(
                                                        clientModeEnabled && isStagedFile() ? colours.secondaryPositive : colours.primaryDark,
                                                      ),
                                                      padding: WidgetStatePropertyAll(EdgeInsets.zero),
                                                      shape: WidgetStatePropertyAll(
                                                        RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM)),
                                                      ),
                                                    ),
                                                    onPressed: () {
                                                      if (selectedFiles.contains(fileName)) {
                                                        selectedFiles.remove(fileName);
                                                      } else {
                                                        selectedFiles.add(fileName);
                                                        lineSelections.remove(fileName);
                                                      }
                                                      if (context.mounted) setState(() {});
                                                    },
                                                    child: Row(
                                                      children: [
                                                        Expanded(
                                                          child: Padding(
                                                            padding: EdgeInsets.symmetric(vertical: spaceXS, horizontal: spaceXS + spaceXXXS),
                                                            child: Row(
                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                              children: [
                                                                hasLineSelections
                                                                    ? outlineCircleMinus(
                                                                        size: textMD,
                                                                        color: colours.tertiaryInfo,
                                                                      )
                                                                    : Stack(
                                                                        children: [
                                                                          Positioned.fill(
                                                                            child: FaIcon(
                                                                              FontAwesomeIcons.circleCheck,
                                                                              color: isWholeFileSelected && !isPartiallyStagedFile
                                                                                  ? colours.tertiaryInfo
                                                                                  : Colors.transparent,
                                                                              size: textMD,
                                                                            ),
                                                                          ),
                                                                          FaIcon(
                                                                            isWholeFileSelected
                                                                                ? (isPartiallyStagedFile
                                                                                      ? FontAwesomeIcons.circleMinus
                                                                                      : FontAwesomeIcons.solidCircleCheck)
                                                                                : FontAwesomeIcons.circleCheck,
                                                                            color: isWholeFileSelected
                                                                                ? (clientModeEnabled && isStagedFile()
                                                                                      ? colours.primaryInfo
                                                                                      : colours.secondaryInfo)
                                                                                : colours.tertiaryInfo,
                                                                            size: textMD,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                SizedBox(width: spaceXS),
                                                                Expanded(
                                                                  child: Row(
                                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                                    children:
                                                                        (clientModeEnabled && isStagedFile()
                                                                        ? (List<Widget> l) => l.reversed.toList()
                                                                        : (List<Widget> l) => l)([
                                                                          Expanded(
                                                                            child: ExtendedText(
                                                                              fileName,
                                                                              maxLines: 1,
                                                                              textAlign: clientModeEnabled && isStagedFile()
                                                                                  ? TextAlign.right
                                                                                  : TextAlign.left,
                                                                              overflowWidget: TextOverflowWidget(
                                                                                position: TextOverflowPosition.start,
                                                                                child: Text(
                                                                                  "…",
                                                                                  style: TextStyle(color: colours.tertiaryLight, fontSize: textMD),
                                                                                ),
                                                                              ),
                                                                              style: TextStyle(color: colours.primaryLight, fontSize: textMD),
                                                                            ),
                                                                          ),
                                                                          SizedBox(width: spaceLG),
                                                                          FaIcon(
                                                                            infoIcon.$1,
                                                                            color: clientModeEnabled && isStagedFile()
                                                                                ? infoIcon.$2.$2
                                                                                : infoIcon.$2.$1,
                                                                            size: textMD,
                                                                          ),
                                                                        ]),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                        if (fileType != 2)
                                                          IconButton(
                                                            icon: FaIcon(FontAwesomeIcons.listCheck, color: colours.secondaryLight, size: textMD),
                                                            style: ButtonStyle(
                                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                              backgroundColor: WidgetStatePropertyAll(colours.tertiaryDark.withAlpha(128)),
                                                              padding: WidgetStatePropertyAll(
                                                                EdgeInsets.symmetric(horizontal: spaceXS, vertical: spaceXXXS),
                                                              ),
                                                              shape: WidgetStatePropertyAll(
                                                                RoundedRectangleBorder(
                                                                  borderRadius: BorderRadius.horizontal(left: cornerRadiusXS, right: cornerRadiusSM),
                                                                ),
                                                              ),
                                                            ),
                                                            onPressed: () {
                                                              currentDiffFile = fileName;
                                                              onLinesPage = true;
                                                              final future = diffCache.putIfAbsent(
                                                                fileName,
                                                                () => runGitOperation(
                                                                  LogType.WorkdirFileDiff,
                                                                  (event) => event,
                                                                  {"filePath": fileName},
                                                                ),
                                                              );
                                                              future.then((data) {
                                                                if (data == null || (lineSelections[fileName]?.isNotEmpty ?? false)) return;
                                                                final lines = data["lines"] as List? ?? [];

                                                                final isFullyStaged = clientModeEnabled &&
                                                                    (stagedFilePathsSnapshot.data ?? []).any((f) => f.$1 == fileName) &&
                                                                    !(uncommittedFilePathsSnapshot.data ?? []).any((f) => f.$1 == fileName);

                                                                final Set<int> preSelected;
                                                                if (isFullyStaged) {
                                                                  preSelected = lines
                                                                      .where((l) => l["origin"] != " ")
                                                                      .map<int>((l) => l["lineIndex"] as int)
                                                                      .toSet();
                                                                } else {
                                                                  preSelected = lines
                                                                      .where((l) => l["isStaged"] == true)
                                                                      .map<int>((l) => l["lineIndex"] as int)
                                                                      .toSet();
                                                                }

                                                                if (preSelected.isNotEmpty) {
                                                                  lineSelections[fileName] = preSelected;
                                                                  selectedFiles.remove(fileName);
                                                                  if (context.mounted) setState(() {});
                                                                }
                                                              });
                                                              if (context.mounted) setState(() {});
                                                              pageController.animateToPage(1, duration: animMedium, curve: Curves.easeInOut);
                                                            },
                                                          ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                                isSameItem: (a, b) => a == b,
                                              ),
                                            ),
                                          ],
                                        );
                                        }),

                                        Builder(
                                          builder: (context) {
                                            if (currentDiffFile == null) return SizedBox.shrink();
                                            final selections = lineSelections.putIfAbsent(currentDiffFile!, () => <int>{});

                                            return FutureBuilder<Map<String, dynamic>?>(
                                              future: diffCache[currentDiffFile],
                                              builder: (context, diffSnapshot) {
                                                final diffLines =
                                                    (diffSnapshot.data?["lines"] as List?)
                                                        ?.map(
                                                          (l) => (
                                                            lineIndex: l["lineIndex"] as int,
                                                            origin: "${l["origin"]}",
                                                            content: "${l["content"]}",
                                                            oldLineno: l["oldLineno"] as int,
                                                            newLineno: l["newLineno"] as int,
                                                            isStaged: l["isStaged"] == true,
                                                          ),
                                                        )
                                                        .toList() ??
                                                    [];
                                                final insertions = diffLines.where((l) => l.origin == "+").length;
                                                final deletions = diffLines.where((l) => l.origin == "-").length;
                                                final isBinary = diffSnapshot.data?["isBinary"] == true;

                                                return Column(
                                                  children: [
                                                    Padding(
                                                      padding: EdgeInsets.symmetric(horizontal: spaceXXXS, vertical: spaceXXXS),
                                                      child: Row(
                                                        children: [
                                                          IconButton(
                                                            icon: FaIcon(FontAwesomeIcons.arrowLeft, color: colours.primaryLight, size: textMD),
                                                            style: ButtonStyle(
                                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                              padding: WidgetStatePropertyAll(EdgeInsets.all(spaceXS)),
                                                            ),
                                                            constraints: BoxConstraints(),
                                                            onPressed: () {
                                                              if (selections.isEmpty) {
                                                                lineSelections.remove(currentDiffFile);
                                                              }
                                                              onLinesPage = false;
                                                              pageController.animateToPage(0, duration: animMedium, curve: Curves.easeInOut);
                                                            },
                                                          ),
                                                          SizedBox(width: spaceXS),
                                                          Expanded(
                                                            child: Text(
                                                              currentDiffFile!.split("/").last,
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                              style: TextStyle(
                                                                color: colours.primaryLight,
                                                                fontSize: textMD,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(width: spaceXS),
                                                          Text(
                                                            "+$insertions",
                                                            style: TextStyle(
                                                              color: colours.tertiaryPositive,
                                                              fontSize: textSM,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                          SizedBox(width: spaceXS),
                                                          Text(
                                                            "-$deletions",
                                                            style: TextStyle(
                                                              color: colours.tertiaryNegative,
                                                              fontSize: textSM,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding: EdgeInsets.symmetric(horizontal: spaceXXXS),
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          TextButton.icon(
                                                            onPressed: () {
                                                              final changedIndices = diffLines
                                                                  .where((l) => l.origin == "+" || l.origin == "-")
                                                                  .map((l) => l.lineIndex)
                                                                  .toSet();
                                                              if (selections.containsAll(changedIndices)) {
                                                                selections.clear();
                                                              } else {
                                                                selections.addAll(changedIndices);
                                                              }
                                                              selectedFiles.remove(currentDiffFile);
                                                              if (context.mounted) setState(() {});

                                                              cancelDebounce("lineStage_$currentDiffFile");
                                                              flushLineStage(currentDiffFile!, Set<int>.from(selections),
                                                                  isUnstaging: selections.isEmpty);
                                                            },
                                                            style: ButtonStyle(
                                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                              padding: WidgetStatePropertyAll(
                                                                EdgeInsets.symmetric(vertical: spaceXXXS, horizontal: spaceXS),
                                                              ),
                                                              shape: WidgetStatePropertyAll(
                                                                RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM)),
                                                              ),
                                                            ),
                                                            icon: selections.length ==
                                                                        diffLines.where((l) => l.origin == "+" || l.origin == "-").length &&
                                                                    selections.isNotEmpty
                                                                ? FaIcon(
                                                                    FontAwesomeIcons.solidCircleCheck,
                                                                    color: colours.secondaryInfo,
                                                                    size: textSM,
                                                                  )
                                                                : selections.isEmpty
                                                                    ? FaIcon(
                                                                        FontAwesomeIcons.circleCheck,
                                                                        color: colours.tertiaryInfo,
                                                                        size: textSM,
                                                                      )
                                                                    : outlineCircleMinus(
                                                                        size: textSM,
                                                                        color: colours.secondaryInfo,
                                                                      ),
                                                            label: Text(
                                                              (selections.isNotEmpty ? t.deselectAll : t.selectAll).toUpperCase(),
                                                              style: TextStyle(
                                                                fontWeight: FontWeight.bold,
                                                                color: colours.primaryLight,
                                                                fontSize: textSM,
                                                              ),
                                                            ),
                                                          ),
                                                          if (selections.isNotEmpty)
                                                            Padding(
                                                              padding: EdgeInsets.only(right: spaceXS),
                                                              child: Text(
                                                                "${selections.length} LINES",
                                                                style: TextStyle(
                                                                  color: colours.secondaryLight,
                                                                  fontSize: textXS,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(height: spaceXXXS),
                                                    Expanded(
                                                      child: diffSnapshot.connectionState == ConnectionState.waiting
                                                          ? Center(child: CircularProgressIndicator(color: colours.tertiaryLight))
                                                          : isBinary
                                                          ? Center(
                                                              child: Text(
                                                                "BINARY FILE",
                                                                style: TextStyle(
                                                                  color: colours.tertiaryLight,
                                                                  fontSize: textMD,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                            )
                                                          : diffLines.isEmpty
                                                          ? Center(
                                                              child: Text(
                                                                t.noUncommittedChanges.toUpperCase(),
                                                                style: TextStyle(
                                                                  color: colours.tertiaryLight,
                                                                  fontSize: textMD,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                            )
                                                          : ListView.builder(
                                                              itemCount: diffLines.length,
                                                              itemBuilder: (context, index) {
                                                                final line = diffLines[index];

                                                                if (line.origin == "H") {
                                                                  return Container(
                                                                    color: colours.tertiaryDark,
                                                                    padding: EdgeInsets.symmetric(horizontal: spaceXS, vertical: spaceXXXS),
                                                                    child: Text(
                                                                      line.content,
                                                                      style: TextStyle(
                                                                        color: colours.tertiaryLight,
                                                                        fontSize: textSM,
                                                                        fontFamily: "monospace",
                                                                        fontWeight: FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                  );
                                                                }

                                                                final isChangedLine = line.origin == "+" || line.origin == "-";
                                                                final isSelected = selections.contains(line.lineIndex);

                                                                Color lineBackground() {
                                                                  if (line.origin == "+") {
                                                                    return isSelected
                                                                        ? colours.tertiaryPositive.withAlpha(60)
                                                                        : colours.tertiaryPositive.withAlpha(20);
                                                                  }
                                                                  if (line.origin == "-") {
                                                                    return isSelected
                                                                        ? colours.tertiaryNegative.withAlpha(60)
                                                                        : colours.tertiaryNegative.withAlpha(20);
                                                                  }
                                                                  return Colors.transparent;
                                                                }

                                                                return GestureDetector(
                                                                  onTap: isChangedLine
                                                                      ? () {
                                                                          if (isSelected) {
                                                                            selections.remove(line.lineIndex);
                                                                          } else {
                                                                            selections.add(line.lineIndex);
                                                                          }
                                                                          selectedFiles.remove(currentDiffFile);
                                                                          if (context.mounted) setState(() {});

                                                                          debounce("lineStage_$currentDiffFile", 1000, () {
                                                                            flushLineStage(currentDiffFile!, Set<int>.from(selections),
                                                                                isUnstaging: isSelected);
                                                                          });
                                                                        }
                                                                      : null,
                                                                  child: Container(
                                                                    color: lineBackground(),
                                                                    padding: EdgeInsets.symmetric(horizontal: spaceXXS, vertical: spaceXXXXS),
                                                                    child: Row(
                                                                      children: [
                                                                        SizedBox(
                                                                          width: textMD + spaceXXXS,
                                                                          child: isChangedLine && isSelected
                                                                              ? FaIcon(
                                                                                  FontAwesomeIcons.check,
                                                                                  size: textSM,
                                                                                  color: colours.primaryInfo,
                                                                                )
                                                                              : SizedBox.shrink(),
                                                                        ),
                                                                        SizedBox(
                                                                          width: spaceLG,
                                                                          child: Text(
                                                                            line.oldLineno > 0 ? "${line.oldLineno}" : "",
                                                                            textAlign: TextAlign.right,
                                                                            style: TextStyle(
                                                                              color: colours.tertiaryLight,
                                                                              fontSize: textXS,
                                                                              fontFamily: "monospace",
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        SizedBox(width: spaceXXXS),
                                                                        SizedBox(
                                                                          width: spaceLG,
                                                                          child: Text(
                                                                            line.newLineno > 0 ? "${line.newLineno}" : "",
                                                                            textAlign: TextAlign.right,
                                                                            style: TextStyle(
                                                                              color: colours.tertiaryLight,
                                                                              fontSize: textXS,
                                                                              fontFamily: "monospace",
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        SizedBox(width: spaceXXS),
                                                                        SizedBox(
                                                                          width: textSM,
                                                                          child: Text(
                                                                            line.origin,
                                                                            style: TextStyle(
                                                                              color: line.origin == "+"
                                                                                  ? colours.tertiaryPositive
                                                                                  : line.origin == "-"
                                                                                  ? colours.tertiaryNegative
                                                                                  : colours.tertiaryLight,
                                                                              fontFamily: "monospace",
                                                                              fontSize: textSM,
                                                                              fontWeight: FontWeight.bold,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        SizedBox(width: spaceXXXS),
                                                                        Expanded(
                                                                          child: Text(
                                                                            line.content,
                                                                            style: TextStyle(
                                                                              color: colours.primaryLight,
                                                                              fontFamily: "monospace",
                                                                              fontSize: textSM,
                                                                            ),
                                                                            maxLines: editorLineWrap ? null : 1,
                                                                            overflow: editorLineWrap ? null : TextOverflow.ellipsis,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ]),
                  actionsAlignment: MainAxisAlignment.center,
                  actions: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        uploading
                            ? SizedBox.shrink()
                            : IconButton(
                                onPressed: selectedFiles.isNotEmpty || selectedFiles.isNotEmpty
                                    ? () async {
                                        ConfirmDiscardChangesDialog.showDialog(context, selectedFiles, () async {
                                          await runGitOperation(LogType.Unstage, (event) => event, {
                                            "paths": selectedFiles
                                                .where((file) => (stagedFilePathsSnapshot.data ?? []).map((file) => file.$1).contains(file))
                                                .toList(),
                                          });

                                          await runGitOperation(LogType.DiscardChanges, (event) => event, {"paths": selectedFiles});
                                          selectedFiles.clear();
                                          lineSelections.clear();
                                          await reload();
                                          if (context.mounted) setState(() {});
                                        });
                                      }
                                    : null,
                                style: ButtonStyle(
                                  alignment: Alignment.center,
                                  backgroundColor: WidgetStatePropertyAll(
                                    selectedFiles.isNotEmpty || selectedFiles.isNotEmpty ? colours.secondaryNegative : colours.tertiaryDark,
                                  ),
                                  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM)),
                                  shape: WidgetStatePropertyAll(
                                    RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM), side: BorderSide.none),
                                  ),
                                ),
                                icon: FaIcon(
                                  FontAwesomeIcons.eraser,
                                  color: selectedFiles.isNotEmpty || selectedFiles.isNotEmpty ? colours.primaryLight : colours.tertiaryLight,
                                  size: textMD,
                                ),
                              ),
                        clientModeEnabled
                            ? Row(
                                children: [
                                  TextButton.icon(
                                    onPressed:
                                        !onLinesPage &&
                                            selectedFiles
                                                .where((file) => (stagedFilePathsSnapshot.data ?? []).map((file) => file.$1).contains(file))
                                                .isNotEmpty
                                        ? () async {
                                            unstaging = true;
                                            if (context.mounted) setState(() {});

                                            await runGitOperation<Map<String, dynamic>?>(LogType.Unstage, (event) => event, {
                                              "paths": selectedFiles
                                                  .where((file) => (stagedFilePathsSnapshot.data ?? []).map((file) => file.$1).contains(file))
                                                  .toList(),
                                            });
                                            selectedFiles.removeWhere(
                                              (file) => ((stagedFilePathsSnapshot.data ?? []).map((file) => file.$1).contains(file) == true),
                                            );
                                            unstaging = false;
                                            await reload();
                                            if (context.mounted) setStater?.call(() {});
                                          }
                                        : null,
                                    style: ButtonStyle(
                                      alignment: Alignment.center,
                                      backgroundColor: WidgetStatePropertyAll(
                                        !onLinesPage &&
                                                selectedFiles
                                                    .where((file) => (stagedFilePathsSnapshot.data ?? []).map((file) => file.$1).contains(file))
                                                    .isNotEmpty
                                            ? colours.tertiaryInfo
                                            : colours.tertiaryDark,
                                      ),
                                      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM)),
                                      shape: WidgetStatePropertyAll(
                                        RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM), side: BorderSide.none),
                                      ),
                                    ),
                                    icon: unstaging
                                        ? Container(
                                            height: textSM,
                                            width: textSM,
                                            margin: EdgeInsets.only(right: spaceXXXS),
                                            child: CircularProgressIndicator(color: onLinesPage ? colours.tertiaryLight : colours.tertiaryDark),
                                          )
                                        : null,
                                    label: Text(
                                      t.unstage.toUpperCase(),
                                      style: TextStyle(
                                        color:
                                            !onLinesPage &&
                                                selectedFiles
                                                    .where((file) => (stagedFilePathsSnapshot.data ?? []).map((file) => file.$1).contains(file))
                                                    .isNotEmpty
                                            ? colours.tertiaryDark
                                            : colours.tertiaryLight,
                                        fontSize: textSM,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: spaceSM),
                                  TextButton.icon(
                                    onPressed:
                                        !onLinesPage &&
                                            (selectedFiles
                                                    .where((file) => !(stagedFilePathsSnapshot.data ?? []).map((file) => file.$1).contains(file))
                                                    .isNotEmpty ||
                                                lineSelections.isNotEmpty)
                                        ? () async {
                                            staging = true;
                                            if (context.mounted) setState(() {});

                                            final wholeFilePaths = selectedFiles
                                                .where((file) => !(stagedFilePathsSnapshot.data ?? []).map((file) => file.$1).contains(file))
                                                .where((file) => !lineSelections.containsKey(file))
                                                .toList();
                                            if (wholeFilePaths.isNotEmpty) {
                                              await runGitOperation<Map<String, dynamic>?>(LogType.Stage, (event) => event, {
                                                "paths": wholeFilePaths,
                                              });
                                            }

                                            for (final entry in lineSelections.entries) {
                                              await runGitOperation(LogType.StageFileLines, (event) => event, {
                                                "filePath": entry.key,
                                                "selectedLineIndices": entry.value.toList(),
                                              });
                                            }

                                            selectedFiles.removeWhere(
                                              (file) => !((stagedFilePathsSnapshot.data ?? []).map((file) => file.$1).contains(file) == true),
                                            );
                                            lineSelections.clear();
                                            staging = false;
                                            await reload();
                                            if (context.mounted) setState(() {});
                                          }
                                        : null,
                                    style: ButtonStyle(
                                      alignment: Alignment.center,
                                      backgroundColor: WidgetStatePropertyAll(
                                        !onLinesPage &&
                                                (selectedFiles
                                                        .where((file) =>
                                                            !(stagedFilePathsSnapshot.data ?? []).map((file) => file.$1).contains(file))
                                                        .isNotEmpty ||
                                                    lineSelections.isNotEmpty)
                                            ? colours.tertiaryInfo
                                            : colours.tertiaryDark,
                                      ),
                                      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM)),
                                      shape: WidgetStatePropertyAll(
                                        RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM), side: BorderSide.none),
                                      ),
                                    ),
                                    icon: staging
                                        ? Container(
                                            height: textSM,
                                            width: textSM,
                                            margin: EdgeInsets.only(right: spaceXXXS),
                                            child: CircularProgressIndicator(color: onLinesPage ? colours.tertiaryLight : colours.tertiaryDark),
                                          )
                                        : null,
                                    label: Text(
                                      t.stage.toUpperCase(),
                                      style: TextStyle(
                                        color:
                                            !onLinesPage &&
                                                (selectedFiles
                                                        .where((file) =>
                                                            !(stagedFilePathsSnapshot.data ?? []).map((file) => file.$1).contains(file))
                                                        .isNotEmpty ||
                                                    lineSelections.isNotEmpty)
                                            ? colours.tertiaryDark
                                            : colours.tertiaryLight,
                                        fontSize: textSM,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : TextButton.icon(
                                onPressed: !onLinesPage && (selectedFiles.isNotEmpty || lineSelections.isNotEmpty)
                                    ? () async {
                                        uploading = true;
                                        if (context.mounted) setState(() {});

                                        for (final entry in lineSelections.entries) {
                                          await runGitOperation(LogType.StageFileLines, (event) => event, {
                                            "filePath": entry.key,
                                            "selectedLineIndices": entry.value.toList(),
                                          });
                                        }

                                        final wholeFiles = selectedFiles.where((f) => !lineSelections.containsKey(f)).toList();

                                        if (resolvedHasRemotes) {
                                          await runGitOperation(LogType.UploadChanges, (event) => event, {
                                            "repomanRepoindex": await repoManager.getInt(StorageKey.repoman_repoIndex),
                                            "filePaths": wholeFiles,
                                            "syncMessage": syncMessageController.text.isEmpty ? null : syncMessageController.text,
                                          });
                                          FlutterBackgroundService().on("uploadChanges-syncCallback").first.then((_) async {});
                                        } else {
                                          if (wholeFiles.isNotEmpty) {
                                            await runGitOperation(LogType.Stage, (event) => event, {"paths": wholeFiles});
                                          }
                                          await runGitOperation(LogType.Commit, (event) => event, {
                                            "syncMessage": syncMessageController.text.isEmpty ? null : syncMessageController.text,
                                          });
                                        }

                                        selectedFiles.clear();
                                        lineSelections.clear();
                                        uploading = false;
                                        await reload();
                                        if (context.mounted) setState(() {});
                                      }
                                    : null,
                                style: ButtonStyle(
                                  alignment: Alignment.center,
                                  backgroundColor: WidgetStatePropertyAll(
                                    selectedFiles.isNotEmpty || lineSelections.isNotEmpty ? colours.primaryPositive : colours.tertiaryDark,
                                  ),
                                  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM)),
                                  shape: WidgetStatePropertyAll(
                                    RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM), side: BorderSide.none),
                                  ),
                                ),
                                icon: uploading
                                    ? Container(
                                        height: textSM,
                                        width: textSM,
                                        margin: EdgeInsets.only(right: spaceXXXS),
                                        child: CircularProgressIndicator(color: colours.tertiaryDark),
                                      )
                                    : null,
                                label: Text(
                                  (uploading ? t.syncStartPull : t.syncNow).toUpperCase(),
                                  style: TextStyle(
                                    color: selectedFiles.isNotEmpty || lineSelections.isNotEmpty ? colours.tertiaryDark : colours.tertiaryLight,
                                    fontSize: textSM,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ],
                    ),
                    SizedBox(height: spaceXS),
                  ],
                );
              },
            ),
          );
        },
      ),
    ),
  );
  pageController.dispose();
  return committed;
}
