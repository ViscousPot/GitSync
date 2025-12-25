import 'package:GitSync/api/helper.dart';
import 'package:GitSync/api/manager/git_manager.dart';
import 'package:GitSync/constant/colors.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/constant/strings.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/ui/page/code_editor.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sprintf/sprintf.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../dialog/diff_view.dart' as DiffViewDialog;

final insertionRegex = RegExp(r'\+{5}insertion\+{5}');
final deletionRegex = RegExp(r'-{5}deletion-{5}');

class DiffFile extends StatefulWidget {
  DiffFile(this.entry, this.filePath, this.expandedDefault, {required this.orientation, required this.openedFromFile, super.key});

  final MapEntry<String, String> entry;
  final String filePath;
  final bool expandedDefault;
  final Orientation orientation;
  final String? openedFromFile;

  @override
  State<DiffFile> createState() => _DiffFileState();
}

class _DiffFileState extends State<DiffFile> {
  bool expanded = false;
  int insertions = 0;
  int deletions = 0;
  double _maxContentHeight = spaceXXL;
  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    expanded = widget.expandedDefault;
    insertions = insertionRegex.allMatches(widget.entry.value).length;
    deletions = deletionRegex.allMatches(widget.entry.value).length;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateMaxScrollExtent();
    });

    scrollController.addListener(_calculateMaxScrollExtent);
  }

  void _calculateMaxScrollExtent() async {
    final result = await waitFor(() async => !scrollController.hasClients, maxWaitSeconds: 1);
    if (result) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _maxContentHeight = scrollController.position.maxScrollExtent + scrollController.position.viewportDimension + spaceSM;
    });
  }

  List<(String, int)> splitTextWithMarkers(String text) {
    if (!text.contains(insertionRegex) && !text.contains(deletionRegex)) {
      return [(text, 0)];
    }

    List<(String, int)> segments = [];

    for (var match in deletionRegex.allMatches(text)) {
      int nextMarkerIndex = text.indexOf(insertionRegex, match.end);
      if (nextMarkerIndex == -1) {
        nextMarkerIndex = text.length;
      }

      segments.add((text.substring(match.end, nextMarkerIndex), -1));
      break;
    }

    for (var match in insertionRegex.allMatches(text)) {
      int nextMarkerIndex = text.indexOf(deletionRegex, match.end);
      if (nextMarkerIndex == -1) {
        nextMarkerIndex = text.length;
      }

      segments.add((text.substring(match.end, nextMarkerIndex), 1));
      break;
    }

    if (segments.isEmpty) {
      return [(text, 0)];
    }

    setState(() {});
    return segments;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: spaceSM * 2, right: spaceSM * 2, bottom: spaceSM),
      decoration: BoxDecoration(color: secondaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: expanded ? tertiaryDark : Colors.transparent)),
            ),
            child: TextButton.icon(
              onPressed: () async {
                expanded = !expanded;
                setState(() {});
                _calculateMaxScrollExtent();
              },
              style: ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: WidgetStatePropertyAll(EdgeInsets.zero),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: cornerRadiusSM,
                      topRight: cornerRadiusSM,
                      bottomLeft: expanded ? Radius.zero : cornerRadiusSM,
                      bottomRight: expanded ? Radius.zero : cornerRadiusSM,
                    ),
                    side: BorderSide.none,
                  ),
                ),
              ),
              iconAlignment: IconAlignment.start,
              icon: Padding(
                padding: EdgeInsets.only(left: spaceSM),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    FaIcon(FontAwesomeIcons.chevronRight, color: expanded ? Colors.transparent : primaryLight, size: textSM),
                    FaIcon(FontAwesomeIcons.chevronDown, color: expanded ? secondaryLight : Colors.transparent, size: textSM),
                  ],
                ),
              ),
              label: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: spaceXXS),
                      child: Flex(
                        direction: widget.orientation == Orientation.portrait ? Axis.vertical : Axis.horizontal,
                        crossAxisAlignment: widget.orientation == Orientation.portrait ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
                        mainAxisAlignment: widget.orientation == Orientation.portrait ? MainAxisAlignment.start : MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            flex: widget.orientation == Orientation.portrait ? 0 : 1,
                            child: Row(
                              children: [
                                if (widget.orientation == Orientation.portrait && widget.entry.key.contains(conflictSeparator) && !expanded) ...[
                                  Container(
                                    decoration: BoxDecoration(color: secondaryLight, borderRadius: BorderRadius.all(cornerRadiusXS)),
                                    padding: EdgeInsets.symmetric(horizontal: spaceXXXS, vertical: spaceXXXXS),
                                    child: Text(
                                      widget.entry.key.split(conflictSeparator)[1].substring(0, 7).toUpperCase(),
                                      style: TextStyle(color: tertiaryDark, fontSize: textXXS, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  SizedBox(width: spaceXS),
                                ],
                                Flexible(
                                  child: ExtendedText(
                                    widget.entry.key.contains(conflictSeparator)
                                        ? widget.entry.key.split(conflictSeparator).last.split("\n").first
                                        : widget.entry.key,
                                    maxLines: 1,
                                    textAlign: TextAlign.start,
                                    overflowWidget: TextOverflowWidget(
                                      position: TextOverflowPosition.middle,
                                      child: Text(
                                        "…",
                                        style: TextStyle(color: primaryLight, fontSize: textMD),
                                      ),
                                    ),
                                    style: TextStyle(color: primaryLight, fontSize: textMD),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: spaceXXXXS),
                          if (widget.entry.key.contains(conflictSeparator) && (widget.orientation == Orientation.landscape || expanded)) ...[
                            SizedBox(height: spaceXXXXS),
                            Flexible(
                              flex: widget.orientation == Orientation.portrait ? 0 : 1,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment: widget.orientation == Orientation.portrait
                                          ? MainAxisAlignment.spaceBetween
                                          : MainAxisAlignment.end,
                                      children:
                                          (widget.orientation == Orientation.portrait
                                          ? (List<Widget> i) => i
                                          : (List<Widget> i) => i.reversed.toList())([
                                            Container(
                                              decoration: BoxDecoration(color: secondaryLight, borderRadius: BorderRadius.all(cornerRadiusXS)),
                                              padding: EdgeInsets.symmetric(horizontal: spaceXXXS, vertical: spaceXXXXS),
                                              child: Text(
                                                widget.entry.key.split(conflictSeparator)[1].substring(0, 7).toUpperCase(),
                                                style: TextStyle(color: tertiaryDark, fontSize: textXS, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            SizedBox(width: spaceMD),
                                            Flexible(
                                              child: ExtendedText(
                                                timeago
                                                    .format(
                                                      DateTime.fromMillisecondsSinceEpoch(
                                                        int.tryParse(widget.entry.key.split(conflictSeparator).first) ?? 0 * 1000,
                                                      ),
                                                      locale: 'en',
                                                    )
                                                    .replaceFirstMapped(RegExp(r'^[A-Z]'), (match) => match.group(0)!.toLowerCase()),
                                                maxLines: 1,
                                                textAlign: TextAlign.end,
                                                overflowWidget: TextOverflowWidget(
                                                  position: TextOverflowPosition.start,
                                                  child: Text(
                                                    "…",
                                                    style: TextStyle(color: secondaryLight, fontSize: textSM, overflow: TextOverflow.ellipsis),
                                                  ),
                                                ),
                                                style: TextStyle(color: secondaryLight, fontSize: textSM, overflow: TextOverflow.ellipsis),
                                              ),
                                            ),
                                          ]),
                                    ),
                                  ),
                                  if (widget.entry.key.contains(conflictSeparator) && expanded)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        SizedBox(width: spaceMD),
                                        Text(
                                          sprintf(t.additions, [insertions]),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(color: tertiaryPositive, fontSize: textSM, fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(width: spaceMD, height: spaceXXS),
                                        Text(
                                          sprintf(t.deletions, [deletions]),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(color: tertiaryNegative, fontSize: textSM, fontWeight: FontWeight.bold),
                                        ),
                                        // SizedBox(width: spaceSM),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (widget.entry.key.contains(conflictSeparator) && expanded) SizedBox(width: spaceSM),
                  if (!(widget.entry.key.contains(conflictSeparator) && expanded))
                    Row(
                      children: [
                        SizedBox(width: spaceMD),
                        Text(
                          sprintf(t.additions, [insertions]),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: tertiaryPositive, fontSize: textSM, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: spaceMD, height: spaceXXS),
                        Text(
                          sprintf(t.deletions, [deletions]),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: tertiaryNegative, fontSize: textSM, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: spaceSM),
                      ],
                    ),
                ],
              ),
            ),
          ),
          SizedBox(width: MediaQuery.sizeOf(context).width, height: expanded ? spaceXXS : 0),
          if (expanded) ...[
            SizedBox(height: spaceXXXS),
            Row(
              children: [
                SizedBox(width: spaceSM),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      print(widget.entry.key);
                      print(widget.openedFromFile);
                      if (widget.entry.key.contains(conflictSeparator)) {
                        if (widget.openedFromFile != null && widget.entry.key.split(conflictSeparator)[1].substring(0, 7) == widget.openedFromFile) {
                          await Navigator.of(context).canPop() ? Navigator.pop(context) : null;
                        } else {
                          final reference = widget.entry.key.split(conflictSeparator)[1];
                          print(reference);
                          final recentCommits = await GitManager.getRecentCommits();
                          final commitIndex = recentCommits.indexWhere((commit) => commit.reference == reference);
                          final commit = recentCommits[commitIndex];
                          final prevCommit = commitIndex + 1 >= recentCommits.length ? null : recentCommits[commitIndex + 1];
                          print(recentCommits);
                          print(commitIndex);

                          final diff = await GitManager.getCommitDiff(commit.reference, prevCommit?.reference);

                          await DiffViewDialog.showDialog(context, diff, commit.reference.substring(0, 7), (commit, prevCommit), widget.filePath);
                        }
                      } else {
                        if (widget.openedFromFile != null && widget.entry.key == widget.openedFromFile) {
                          await Navigator.of(context).canPop() ? Navigator.pop(context) : null;
                        } else {
                          final diff = await GitManager.getFileDiff(widget.entry.key);
                          if (diff == null) return;
                          await DiffViewDialog.showDialog(context, diff, widget.entry.key, null, widget.filePath);
                        }
                      }
                    },

                    style: ButtonStyle(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: WidgetStatePropertyAll(EdgeInsets.zero),
                      backgroundColor: WidgetStatePropertyAll(tertiaryDark),
                      visualDensity: VisualDensity.compact,
                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM))),
                    ),
                    icon: FaIcon(
                      widget.entry.key.contains(conflictSeparator) ? FontAwesomeIcons.codeCommit : FontAwesomeIcons.scroll,
                      color: tertiaryInfo,
                      size: textXS,
                    ),
                    label: Text(
                      "${t.open} ${widget.entry.key.contains(conflictSeparator) ? t.commit : t.fileDiff}".toUpperCase(),
                      style: TextStyle(color: tertiaryInfo, fontSize: textXS, overflow: TextOverflow.ellipsis, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                SizedBox(width: spaceSM),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      await viewOrEditFile(
                        context,
                        "${await uiSettingsManager.getGitDirPath(true)}/${widget.entry.key.contains(conflictSeparator) ? widget.filePath : widget.entry.key}",
                      );
                    },
                    style: ButtonStyle(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: WidgetStatePropertyAll(EdgeInsets.zero),
                      backgroundColor: WidgetStatePropertyAll(tertiaryDark),
                      visualDensity: VisualDensity.compact,
                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM))),
                    ),
                    icon: FaIcon(FontAwesomeIcons.filePen, color: tertiaryInfo, size: textXS),
                    label: Text(
                      t.openEditFile.toUpperCase(),
                      style: TextStyle(color: tertiaryInfo, fontSize: textXS, overflow: TextOverflow.ellipsis, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                SizedBox(width: spaceSM),
              ],
            ),
            SizedBox(height: spaceXS),
          ],
          expanded
              ? AnimatedSize(
                  duration: Duration(milliseconds: 200),
                  child: SizedBox(
                    height: _maxContentHeight,
                    width: double.infinity,
                    child: Padding(
                      padding: EdgeInsets.only(left: spaceSM, bottom: spaceSM),
                      child: Editor(type: EditorType.DIFF, text: widget.entry.value, verticalScrollController: scrollController),
                    ),
                  ),
                )
              : SizedBox.shrink(),
        ],
      ),
    );
  }
}
