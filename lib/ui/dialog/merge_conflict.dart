import 'dart:io';
import 'dart:math';

import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/main.dart';
import 'package:animated_reorderable_list/animated_reorderable_list.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/api/helper.dart';
import 'package:GitSync/api/logger.dart';
import 'package:GitSync/api/manager/git_manager.dart';
import 'package:GitSync/constant/strings.dart';
import 'package:GitSync/gitsync_service.dart';
import 'package:open_file/open_file.dart';
import '../../../constant/colors.dart';
import '../../../constant/dimens.dart';
import '../../../global.dart';
import '../../../ui/dialog/base_alert_dialog.dart';
import 'package:anchor_scroll_controller/anchor_scroll_controller.dart';

final demoConflictSections = [
  (
    0,
    """
$conflictStart HEAD.txt
- Flashlight
$conflictSeparator
- Headlamp
$conflictEnd 77976da35a11db4580b80ae27e8d65caf5208086:gear-update.txt
""",
  ),
  (1, "- First aid kit"),
  (2, "- Map & compass"),
  (3, ""),
  (4, "## Clothing"),
  (5, "- Waterproof jacket"),
  (6, "- Extra socks"),
  (7, "- Hat and gloves"),
  (8, ""),
  (9, "## Food"),
  (10, "- Trail mix"),
  (11, "- Instant noodles"),
  (12, "- Granola bars"),
  (13, "- Water bottles"),
  (14, ""),
  (15, "## Misc"),
  (16, "- Matches/lighter"),
  (17, "- Pocket knife"),
  (18, "- Notebook & pen"),
];

Future<void> showDialog(BuildContext parentContext, List<String> originalConflictingPaths) async {
  bool initialised = false;
  bool isMerging = false;
  int currentIndex = 0;
  final GlobalKey dialogKey = GlobalKey();
  List<String> conflictingPaths = [...originalConflictingPaths];

  try {
    await Logger.notificationsPlugin.cancel(mergeConflictNotificationId);
  } catch (e) {
    print(e);
  }

  final syncMessage = await uiSettingsManager.getSyncMessage();
  final scrollController = AnchorScrollController();
  final commitMessageController = TextEditingController();

  indexListener(int index, bool userScroll, void Function(void Function()) setState) {
    currentIndex = index;
    debounce(mergeConflictDebounceReference, 50, () {
      if (dialogKey.currentContext != null) setState(() {});
    });
  }

  int conflictIndex = 0;
  List<(int, String)> conflictSections = [];
  bool updating = false;

  print(conflictingPaths);

  Future<void> updateConflictSections(void Function(void Function())? setState) async {
    try {
      if (demo) {
        conflictSections = demoConflictSections;
        return;
      }

      if (setState != null && updating) return;

      updating = true;
      if (setState != null) setState(() {});

      final bookmarkPath = await uiSettingsManager.getString(StorageKey.setman_gitDirPath);
      if (bookmarkPath.isEmpty) return;

      await useDirectory(bookmarkPath, (bookmarkPath) async => await uiSettingsManager.setGitDirPath(bookmarkPath, true), (path) async {
        final file = File("$path/${conflictingPaths[conflictIndex]}");

        List<String> conflictStringSections = [];
        List<String> lines = await file.readAsLines();
        StringBuffer conflictBuffer = StringBuffer();
        bool inConflict = false;

        for (var line in lines) {
          if (line.trim().startsWith(conflictStart)) {
            inConflict = true;
            conflictBuffer.writeln(line);
          } else if (line.trim().startsWith(conflictEnd)) {
            conflictBuffer.writeln(line);
            conflictStringSections.add(conflictBuffer.toString());
            conflictBuffer.clear();
            inConflict = false;
          } else if (inConflict) {
            conflictBuffer.writeln(line);
          } else {
            conflictStringSections.add(line);
          }
        }
        if (conflictBuffer.isNotEmpty) {
          conflictStringSections.add(conflictBuffer.toString());
        }

        conflictSections = conflictStringSections.indexed.toList();
        if (setState != null) setState(() {});

        await Future.delayed(Duration(milliseconds: 500), () {
          updating = false;
          if (setState != null) setState(() {});
        });
      });
    } catch (e) {
      print(e);
    }
  }

  await updateConflictSections(null);

  print(conflictingPaths);
  String padNumber(int num1) {
    String num1Str = num1.toString();
    int targetLength = conflictSections.length.toString().length;
    return num1Str.padLeft(targetLength, '0');
  }

  Future<void> refreshConflictSectionIndices() async {
    final bookmarkPath = await uiSettingsManager.getString(StorageKey.setman_gitDirPath);
    if (bookmarkPath.isEmpty) return;

    await useDirectory(bookmarkPath, (bookmarkPath) async => await uiSettingsManager.setGitDirPath(bookmarkPath, true), (path) async {
      final file = File("$path/${conflictingPaths[conflictIndex]}");
      await file.writeAsString(conflictSections.map((section) => section.$2).join('\n'));

      for (var indexedSection in conflictSections.indexed) {
        conflictSections[indexedSection.$1] = (indexedSection.$1, indexedSection.$2.$2);
      }
    });
  }

  return await mat.showDialog(
    context: parentContext,
    barrierColor: Colors.transparent,
    builder: (BuildContext context) => PopScope(
      canPop: !isMerging,
      child: StatefulBuilder(
        key: dialogKey,
        builder: (context, setState) {
          if (!initialised && conflictSections.isNotEmpty) {
            Future.delayed(Duration(seconds: 0), () async {
              final scrollIndex = max(0, conflictSections.indexWhere((section) => section.$2.contains(conflictStart)));
              await scrollController.scrollToIndex(index: scrollIndex, scrollSpeed: 10);
              await scrollController.scrollToIndex(index: scrollIndex, scrollSpeed: 5);
              initialised = true;
            });
          }
          final int firstConflictIndex = conflictSections.indexWhere((section) => section.$2.contains(conflictStart));
          final int lastConflictIndex = conflictSections.lastIndexWhere((section) => section.$2.contains(conflictStart));
          final prevEnabled = !updating && ((firstConflictIndex != -1 && currentIndex > firstConflictIndex) || conflictIndex > 0);
          final nextEnabled =
              !updating && ((lastConflictIndex != -1 && currentIndex < lastConflictIndex) || conflictIndex < conflictingPaths.length - 1);

          scrollController.removeIndexListener((index, userScroll) => indexListener(index, userScroll, setState));
          scrollController.addIndexListener((index, userScroll) => indexListener(index, userScroll, setState));

          return BaseAlertDialog(
            expandable: true,
            title: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Text(
                t.mergeConflict.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(color: primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
              ),
            ),
            contentBuilder: (expanded) =>
                (expanded
                ? (List<Widget> children) => Column(children: children)
                : (List<Widget> children) => SingleChildScrollView(child: ListBody(children: children)))(<Widget>[
                  Text(
                    t.mergeDialogMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: secondaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
                  ),
                  SizedBox(height: spaceMD + spaceSM),
                  TextField(
                    contextMenuBuilder: globalContextMenuBuilder,
                    controller: commitMessageController,
                    maxLines: null,
                    style: TextStyle(
                      color: primaryLight,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                      decorationThickness: 0,
                      fontSize: textMD,
                    ),
                    decoration: InputDecoration(
                      fillColor: secondaryDark,
                      filled: true,
                      border: const OutlineInputBorder(borderRadius: BorderRadius.all(cornerRadiusSM), borderSide: BorderSide.none),
                      hintText: syncMessage,
                      isCollapsed: true,
                      label: Text(
                        t.commitMessage.toUpperCase(),
                        style: TextStyle(color: secondaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      contentPadding: const EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM),
                      isDense: true,
                    ),
                    onChanged: (_) {
                      setState(() {});
                    },
                  ),
                  SizedBox(height: spaceMD),
                  (expanded ? (Widget child) => Expanded(child: child) : (child) => child)(
                    Container(
                      decoration: BoxDecoration(borderRadius: BorderRadius.all(cornerRadiusSM), color: secondaryDark),
                      padding: EdgeInsets.only(left: spaceXXS, right: spaceXXS, bottom: spaceXXS, top: spaceXXXS),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: () async =>
                                      OpenFile.open("${await uiSettingsManager.getGitDirPath(true)}/${conflictingPaths[conflictIndex]}"),
                                  style: ButtonStyle(
                                    alignment: Alignment.centerLeft,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: WidgetStatePropertyAll(
                                      RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM), side: BorderSide.none),
                                    ),
                                  ),
                                  icon: FaIcon(FontAwesomeIcons.squareArrowUpRight, color: primaryLight, size: textMD),
                                  label: Text(
                                    conflictingPaths.isEmpty ? "-" : conflictingPaths[conflictIndex].split("/").last.toUpperCase(),
                                    maxLines: 1,
                                    textAlign: TextAlign.start,
                                    style: TextStyle(color: primaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              SizedBox(width: spaceXXS),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: prevEnabled
                                        ? () async {
                                            if (conflictSections.isEmpty) return;

                                            if (currentIndex <= firstConflictIndex || firstConflictIndex == -1) {
                                              conflictIndex = (conflictIndex - 1).clamp(0, conflictingPaths.length - 1);
                                              await updateConflictSections(setState);
                                            } else {
                                              int startIndex = currentIndex < 0 ? 0 : currentIndex;
                                              int prevConflictIndex = conflictSections
                                                  .sublist(0, startIndex)
                                                  .lastIndexWhere((section) => section.$2.contains(conflictStart));

                                              scrollController.scrollToIndex(index: prevConflictIndex < 0 ? 0 : prevConflictIndex);
                                            }
                                          }
                                        : null,
                                    icon: FaIcon(FontAwesomeIcons.caretLeft),
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStatePropertyAll(tertiaryDark),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                      shape: WidgetStatePropertyAll(
                                        RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM), side: BorderSide.none),
                                      ),
                                    ),
                                    color: primaryLight,
                                    disabledColor: tertiaryLight,
                                    iconSize: textSM,
                                  ),
                                  SizedBox(width: spaceXS),
                                  IconButton(
                                    onPressed: nextEnabled
                                        ? () async {
                                            if (conflictSections.isEmpty) return;

                                            if (currentIndex + (expanded ? 30 : 15) >= lastConflictIndex ||
                                                conflictSections.isEmpty ||
                                                !conflictSections.any((section) => section.$2.contains(conflictStart))) {
                                              currentIndex = 0;
                                              conflictIndex = (conflictIndex + 1).clamp(0, conflictingPaths.length - 1);
                                              await updateConflictSections(setState);
                                            } else {
                                              int startIndex = currentIndex < 0 ? 0 : currentIndex;
                                              int nextConflictIndex = conflictSections
                                                  .sublist(startIndex)
                                                  .indexWhere((section) => section.$2.contains(conflictStart));

                                              scrollController.scrollToIndex(
                                                index: nextConflictIndex < 0 ? conflictSections.length : nextConflictIndex + startIndex,
                                              );
                                            }
                                          }
                                        : null,
                                    icon: FaIcon(FontAwesomeIcons.caretRight),
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStatePropertyAll(tertiaryDark),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                      shape: WidgetStatePropertyAll(
                                        RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM), side: BorderSide.none),
                                      ),
                                    ),
                                    color: primaryLight,
                                    disabledColor: tertiaryLight,
                                    iconSize: textSM,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          (expanded ? (Widget child) => Expanded(child: child) : (child) => child)(
                            Padding(
                              padding: EdgeInsets.all(spaceXS),
                              child: conflictSections.isEmpty
                                  ? Center(
                                      child: CircularProgressIndicator(color: primaryLight, padding: EdgeInsets.all(spaceXS)),
                                    )
                                  : SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: SizedBox(
                                        height: expanded ? double.infinity : MediaQuery.sizeOf(context).height / 3,
                                        width: double.maxFinite,
                                        child: AnimatedListView(
                                          controller: scrollController,
                                          items: conflictSections,
                                          isSameItem: (a, b) => a.$1 == b.$1 && a.$2 == b.$2,
                                          itemBuilder: (BuildContext context, int index) {
                                            final item = conflictSections[index];

                                            if (item.$2.contains(conflictStart)) {
                                              final lines = item.$2.split("\n");
                                              final startIndex = lines.indexWhere((line) => line.contains(conflictStart));
                                              final midIndex = lines.indexWhere((line) => line.contains(conflictSeparator));
                                              final endIndex = lines.indexWhere((line) => line.contains(conflictEnd));

                                              final remoteLines = lines.sublist(startIndex + 1, midIndex).indexed;
                                              final localLines = lines.sublist(midIndex + 1, endIndex).indexed;

                                              return AnchorItemWrapper(
                                                key: Key("${item.$1}//${item.$2}"),
                                                controller: scrollController,
                                                index: item.$1,
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Padding(
                                                      padding: EdgeInsets.only(left: spaceSM, top: spaceSM),
                                                      child: Text(
                                                        t.keepChanges.toUpperCase(),
                                                        style: TextStyle(color: primaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                                                      ),
                                                    ),
                                                    SizedBox(height: spaceXXS),
                                                    SizedBox(
                                                      width:
                                                          MediaQuery.of(context).size.width -
                                                          ((spaceLG * 2) + (spaceSM * 2 * 2) + (spaceXS * 2) + (spaceXXS * 2)),
                                                      child: Row(
                                                        children: [
                                                          Expanded(
                                                            child: TextButton(
                                                              onPressed: () async {
                                                                conflictSections.removeAt(index);
                                                                conflictSections.insertAll(index, localLines);
                                                                await refreshConflictSectionIndices();
                                                                setState(() {});
                                                              },
                                                              style: ButtonStyle(
                                                                backgroundColor: WidgetStatePropertyAll(tertiaryInfo),
                                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                                visualDensity: VisualDensity.compact,
                                                                padding: WidgetStatePropertyAll(EdgeInsets.zero),
                                                                shape: WidgetStatePropertyAll(
                                                                  RoundedRectangleBorder(
                                                                    borderRadius: BorderRadius.only(
                                                                      topLeft: cornerRadiusSM,
                                                                      topRight: cornerRadiusSM,
                                                                      bottomLeft: cornerRadiusSM,
                                                                      bottomRight: cornerRadiusSM,
                                                                    ),
                                                                    side: BorderSide.none,
                                                                  ),
                                                                ),
                                                              ),
                                                              child: Text(
                                                                t.local.toUpperCase(),
                                                                style: TextStyle(color: secondaryDark, fontWeight: FontWeight.bold),
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(width: spaceXXS),
                                                          Expanded(
                                                            child: TextButton(
                                                              onPressed: () async {
                                                                conflictSections.removeAt(index);
                                                                conflictSections.insertAll(index, remoteLines);
                                                                conflictSections.insertAll(index, localLines);
                                                                await refreshConflictSectionIndices();
                                                                setState(() {});
                                                              },
                                                              style: ButtonStyle(
                                                                backgroundColor: WidgetStatePropertyAll(tertiaryLight),
                                                                visualDensity: VisualDensity.compact,
                                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                                padding: WidgetStatePropertyAll(EdgeInsets.zero),
                                                                shape: WidgetStatePropertyAll(
                                                                  RoundedRectangleBorder(
                                                                    borderRadius: BorderRadius.only(
                                                                      topLeft: cornerRadiusSM,
                                                                      topRight: cornerRadiusSM,
                                                                      bottomLeft: cornerRadiusSM,
                                                                      bottomRight: cornerRadiusSM,
                                                                    ),
                                                                    side: BorderSide.none,
                                                                  ),
                                                                ),
                                                              ),
                                                              child: Text(
                                                                t.both.toUpperCase(),
                                                                style: TextStyle(color: secondaryDark, fontWeight: FontWeight.bold),
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(width: spaceXXS),
                                                          Expanded(
                                                            child: TextButton(
                                                              onPressed: () async {
                                                                conflictSections.removeAt(index);
                                                                conflictSections.insertAll(index, remoteLines);
                                                                await refreshConflictSectionIndices();
                                                                setState(() {});
                                                              },
                                                              style: ButtonStyle(
                                                                backgroundColor: WidgetStatePropertyAll(tertiaryWarning),
                                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                                visualDensity: VisualDensity.compact,
                                                                padding: WidgetStatePropertyAll(EdgeInsets.zero),
                                                                shape: WidgetStatePropertyAll(
                                                                  RoundedRectangleBorder(
                                                                    borderRadius: BorderRadius.only(
                                                                      topLeft: cornerRadiusSM,
                                                                      topRight: cornerRadiusSM,
                                                                      bottomLeft: cornerRadiusSM,
                                                                      bottomRight: cornerRadiusSM,
                                                                    ),
                                                                    side: BorderSide.none,
                                                                  ),
                                                                ),
                                                              ),
                                                              child: Text(
                                                                t.remote.toUpperCase(),
                                                                style: TextStyle(color: secondaryDark, fontWeight: FontWeight.bold),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(height: spaceXS),
                                                    ...localLines.map(
                                                      (line) => Row(
                                                        crossAxisAlignment: CrossAxisAlignment.center,
                                                        children: [
                                                          Text(
                                                            padNumber(item.$1 + line.$1 + 1),
                                                            style: TextStyle(
                                                              color: tertiaryInfo,
                                                              fontSize: textMD,
                                                              fontWeight: FontWeight.bold,
                                                              fontFamily: "Roboto",
                                                            ),
                                                          ),
                                                          SizedBox(width: spaceSM),
                                                          Text(
                                                            line.$2.trim(),
                                                            style: TextStyle(
                                                              color: tertiaryInfo,
                                                              fontSize: textMD,
                                                              fontWeight: FontWeight.bold,
                                                              fontFamily: "RobotoMono",
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    ...remoteLines.map(
                                                      (line) => Row(
                                                        crossAxisAlignment: CrossAxisAlignment.center,
                                                        children: [
                                                          Text(
                                                            padNumber(item.$1 + line.$1 + 1),
                                                            style: TextStyle(
                                                              color: tertiaryWarning,
                                                              fontSize: textMD,
                                                              fontWeight: FontWeight.bold,
                                                              fontFamily: "Roboto",
                                                            ),
                                                          ),
                                                          SizedBox(width: spaceSM),
                                                          Text(
                                                            line.$2.trim(),
                                                            style: TextStyle(
                                                              color: tertiaryWarning,
                                                              fontSize: textMD,
                                                              fontWeight: FontWeight.bold,
                                                              fontFamily: "RobotoMono",
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(height: spaceSM),
                                                  ],
                                                ),
                                              );
                                            }
                                            return AnchorItemWrapper(
                                              key: Key("${item.$1}//${item.$2}"),
                                              controller: scrollController,
                                              index: item.$1,
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    padNumber(item.$1 + 1),
                                                    style: TextStyle(
                                                      color: tertiaryLight,
                                                      fontSize: textMD,
                                                      fontWeight: FontWeight.bold,
                                                      fontFamily: "Roboto",
                                                    ),
                                                  ),
                                                  SizedBox(width: spaceSM),
                                                  Text(
                                                    item.$2.trim(),
                                                    style: TextStyle(
                                                      color: secondaryLight,
                                                      fontSize: textMD,
                                                      fontWeight: FontWeight.bold,
                                                      fontFamily: "RobotoMono",
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
                        ],
                      ),
                    ),
                  ),
                ]),
            actionsAlignment: MainAxisAlignment.center,
            actions: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () async {
                      if (isMerging) return;

                      await GitManager.abortMerge();
                      Navigator.of(context).canPop() ? Navigator.pop(context) : null;
                    },
                    style: ButtonStyle(
                      alignment: Alignment.center,
                      backgroundColor: WidgetStatePropertyAll(secondaryNegative),
                      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM)),
                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM), side: BorderSide.none)),
                    ),
                    child: Text(
                      t.abortMerge.toUpperCase(),
                      style: TextStyle(color: primaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: conflictSections.indexWhere((section) => section.$2.contains("\n")) == -1
                        ? () async {
                            if (isMerging) return;

                            if (conflictingPaths.length > 1) {
                              conflictingPaths.removeAt(conflictIndex);
                              conflictIndex = conflictIndex.clamp(0, conflictingPaths.length - 1);
                              await updateConflictSections(setState);

                              return;
                            }

                            isMerging = true;

                            FlutterBackgroundService().invoke(GitsyncService.MERGE, {
                              COMMIT_MESSAGE: commitMessageController.text.isEmpty ? syncMessage : commitMessageController.text,
                              CONFLICTING_PATHS: originalConflictingPaths.join(conflictSeparator),
                            });
                            setState(() {});
                          }
                        : null,
                    style: ButtonStyle(
                      alignment: Alignment.center,
                      backgroundColor: WidgetStatePropertyAll(
                        !demo && conflictSections.indexWhere((section) => section.$2.contains("\n")) == -1 ? primaryPositive : tertiaryDark,
                      ),
                      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM)),
                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM), side: BorderSide.none)),
                    ),
                    icon: isMerging
                        ? Container(
                            height: textSM,
                            width: textSM,
                            margin: EdgeInsets.only(right: spaceXXXS),
                            child: CircularProgressIndicator(color: tertiaryDark),
                          )
                        : null,
                    label: Text(
                      (isMerging
                              ? t.merging
                              // 0 1
                              // 0 1
                              : (conflictIndex == conflictingPaths.length - 1 || conflictingPaths.length <= 1 ? t.merge : "next"))
                          .toUpperCase(),
                      style: TextStyle(
                        color: !demo && conflictSections.indexWhere((section) => section.$2.contains("\n")) == -1 ? tertiaryDark : tertiaryLight,
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
    ),
  );
}
