import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:GitSync/api/helper.dart';
import 'package:GitSync/api/logger.dart';
import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/constant/values.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/ui/component/button_setting.dart';
import 'package:GitSync/ui/component/code_line_number_render_object.dart';
import 'package:GitSync/ui/dialog/info_dialog.dart' as InfoDialog;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mmap2/mmap2.dart';
import 'package:mmap2_flutter/mmap2_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../constant/strings.dart';
import 'package:path/path.dart' as p;
import 'package:GitSync/constant/langDiff.dart';
import 'package:re_editor/re_editor.dart' as ReEditor;

class LogsChunkAnalyzer implements ReEditor.CodeChunkAnalyzer {
  static const List<String> matchSubstrings = ["RecentCommits:", "GitStatus:", "Getting local directory", ".git folder found"];

  const LogsChunkAnalyzer();

  @override
  List<ReEditor.CodeChunk> run(ReEditor.CodeLines codeLines) {
    final List<ReEditor.CodeChunk> chunks = [];
    int? runStart;

    for (int i = 0; i < codeLines.length; i++) {
      final String line = codeLines[i].text;
      final bool matches = _lineMatches(line);

      if (matches) {
        runStart ??= i;
      } else {
        if (runStart != null) {
          chunks.add(ReEditor.CodeChunk(runStart, i - 1));
          runStart = null;
        }
      }
    }

    if (runStart != null) {
      chunks.add(ReEditor.CodeChunk(runStart, codeLines.length - 1));
    }

    return chunks;
  }

  bool _lineMatches(String line) {
    final String trimmed = line;
    if (RegExp(r'^.*\s\[E\]\s.*$').hasMatch(line)) return true;
    if (RegExp(r'^(?!.*\s\[(I|W|E|D|V|T)\]\s).*$').hasMatch(line)) return true;
    for (final String sub in matchSubstrings) {
      if (trimmed.contains(sub)) {
        return true;
      }
    }
    return false;
  }
}

class CodeLineNumber extends LeafRenderObjectWidget {
  final ReEditor.CodeLineEditingController controller;
  final ReEditor.CodeIndicatorValueNotifier notifier;
  final TextStyle focusedTextStyle;
  final int? minNumberCount;
  final String Function(int lineIndex)? customLineIndex2Text;
  final TextStyle Function(int lineIndex) customLineIndex2TextStyle;

  const CodeLineNumber({
    super.key,
    required this.notifier,
    required this.controller,
    required this.focusedTextStyle,
    this.minNumberCount,
    this.customLineIndex2Text,
    required this.customLineIndex2TextStyle,
  });

  @override
  RenderObject createRenderObject(BuildContext context) => CodeLineNumberRenderObject(
    controller: controller,
    notifier: notifier,
    focusedTextStyle: focusedTextStyle,
    minNumberCount: minNumberCount ?? 3,
    customLineIndex2Text: customLineIndex2Text,
    customLineIndex2TextStyle: customLineIndex2TextStyle,
  );

  @override
  void updateRenderObject(BuildContext context, covariant CodeLineNumberRenderObject renderObject) {
    renderObject
      ..controller = controller
      ..notifier = notifier
      ..focusedTextStyle = focusedTextStyle
      ..minNumberCount = minNumberCount ?? 3;
    super.updateRenderObject(context, renderObject);
  }
}

enum PopupMenuItemType { primary, danger }

class PopupMenuItemData {
  const PopupMenuItemData({this.icon, required this.label, required this.onPressed, this.danger = false});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool danger;
}

class ContextMenuControllerImpl implements ReEditor.SelectionToolbarController {
  OverlayEntry? _overlayEntry;
  bool _isFirstRender = true;
  bool readonly;

  ContextMenuControllerImpl(this.readonly);

  void _removeOverLayEntry() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isFirstRender = true;
  }

  @override
  void hide(BuildContext context) {
    _removeOverLayEntry();
  }

  @override
  void show({required context, required controller, required anchors, renderRect, required layerLink, required ValueNotifier<bool> visibility}) {
    _removeOverLayEntry();
    _overlayEntry ??= OverlayEntry(
      builder: (context) => ReEditor.CodeEditorTapRegion(
        child: ValueListenableBuilder(
          valueListenable: controller,
          builder: (_, _, child) {
            final isNotEmpty = controller.selectedText.isNotEmpty;
            final isAllSelected = controller.isAllSelected;
            final hasSelected = controller.selectedText.isNotEmpty;
            List<PopupMenuItemData> menus = [
              if (isNotEmpty) PopupMenuItemData(label: t.copy, onPressed: controller.copy),
              if (!readonly) PopupMenuItemData(label: t.paste, onPressed: controller.paste),
              if (isNotEmpty && !readonly) PopupMenuItemData(label: t.cut, onPressed: controller.cut),
              if (hasSelected && !isAllSelected) PopupMenuItemData(label: t.selectAll, onPressed: controller.selectAll),
            ];
            if (_isFirstRender) {
              _isFirstRender = false;
            } else if (controller.selectedText.isEmpty) {
              _removeOverLayEntry();
            }
            return TextSelectionToolbar(
              anchorAbove: anchors.primaryAnchor,
              anchorBelow: anchors.secondaryAnchor ?? Offset.zero,
              toolbarBuilder: (context, child) => Material(
                borderRadius: const BorderRadius.all(cornerRadiusMax),
                clipBehavior: Clip.antiAlias,
                color: colours.primaryDark,
                elevation: 1.0,
                type: MaterialType.card,
                child: child,
              ),
              children: menus.asMap().entries.map((MapEntry<int, PopupMenuItemData> entry) {
                return TextSelectionToolbarTextButton(
                  padding: TextSelectionToolbarTextButton.getPadding(entry.key, menus.length),
                  alignment: AlignmentDirectional.centerStart,
                  onPressed: () {
                    if (entry.value.onPressed == null) {
                      return;
                    }
                    entry.value.onPressed!();
                    _removeOverLayEntry();
                  },
                  child: Text(
                    entry.value.label,
                    style: TextStyle(fontSize: textMD, color: colours.primaryLight, fontWeight: FontWeight.w500),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }
}

enum EditorType { DEFAULT, LOGS, DIFF }

class CodeEditor extends StatefulWidget {
  const CodeEditor({super.key, required this.paths, this.type = EditorType.DEFAULT});

  final List<String> paths;
  final EditorType type;

  @override
  State<CodeEditor> createState() => _CodeEditor();
}

class _CodeEditor extends State<CodeEditor> {
  int index = 0;
  bool prevEnabled = false;
  bool nextEnabled = true;
  late GlobalKey key = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colours.secondaryDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: colours.secondaryDark,
          systemNavigationBarColor: colours.secondaryDark,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        leading: getBackButton(context, () => (Navigator.of(context).canPop() ? Navigator.pop(context) : null)),
        title: SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  p.basename(widget.paths[index]),
                  style: TextStyle(fontSize: textLG, color: colours.primaryLight, fontWeight: FontWeight.bold),
                ),
              ),
              if (widget.paths.length > 1)
                Row(
                  children: [
                    SizedBox(width: spaceXS),
                    IconButton(
                      onPressed: prevEnabled
                          ? () async {
                              if (widget.paths.isEmpty) return;

                              index = (index - 1).clamp(0, widget.paths.length - 1);
                              prevEnabled = index > 0;
                              nextEnabled = index < widget.paths.length - 1;
                              key = GlobalKey();
                              if (mounted) setState(() {});
                            }
                          : null,
                      icon: FaIcon(FontAwesomeIcons.caretLeft),
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(colours.tertiaryDark),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM), side: BorderSide.none)),
                      ),
                      color: colours.primaryLight,
                      disabledColor: colours.tertiaryLight,
                      iconSize: textSM,
                    ),
                    SizedBox(width: spaceXS),
                    IconButton(
                      onPressed: nextEnabled
                          ? () async {
                              if (widget.paths.isEmpty) return;

                              index = (index + 1).clamp(0, widget.paths.length - 1);
                              prevEnabled = index > 0;
                              nextEnabled = index < widget.paths.length - 1;
                              key = GlobalKey();
                              if (mounted) setState(() {});
                            }
                          : null,
                      icon: FaIcon(FontAwesomeIcons.caretRight),
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(colours.tertiaryDark),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM), side: BorderSide.none)),
                      ),
                      color: colours.primaryLight,
                      disabledColor: colours.tertiaryLight,
                      iconSize: textSM,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      body: Editor(key: key, path: widget.paths[index], type: widget.type),
    );
  }
}

class Editor extends StatefulWidget {
  const Editor({super.key, this.verticalScrollController, this.text, this.path, this.type = EditorType.DEFAULT});

  final String? text;
  final String? path;
  final EditorType type;
  final ScrollController? verticalScrollController;

  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> with WidgetsBindingObserver {
  final fileSaving = ValueNotifier(false);
  final ReEditor.CodeLineEditingController controller = ReEditor.CodeLineEditingController();
  final ScrollController horizontalController = ScrollController();
  ScrollController verticalController = ScrollController();
  Mmap? writeMmap;
  Map<String, ReEditor.CodeHighlightThemeMode> languages = {};
  bool logsCollapsed = false;
  List<String> deletionDiffLineNumbers = [];
  List<String> insertionDiffLineNumbers = [];
  bool editorLineWrap = false;

  @override
  void initState() {
    super.initState();
    MmapFlutter.initialize();

    initAsync(() async {
      editorLineWrap = await repoManager.getBool(StorageKey.repoman_editorLineWrap);
      if (mounted) setState(() {});
    });

    if (widget.type == EditorType.DIFF) {
      initAsync(() async {
        deletionDiffLineNumbers.clear();
        insertionDiffLineNumbers.clear();
        int deletionStartLineNumber = 0;
        int insertionStartLineNumber = 0;
        int hunkStartIndex = 0;
        final indexedLines = (widget.text ?? "").split("\n").indexed;
        final diffLineNumbers = indexedLines.map((indexedLine) {
          final hunkHeader = RegExp(
            "(?:^@@ +-(\\d+),(\\d+) +\\+(\\d+),(\\d+) +@@|^\\*\\*\\* +\\d+,\\d+ +\\*\\*\\*\\*\$|^--- +\\d+,\\d+ +----\$).*\$",
          ).firstMatch(indexedLine.$2);
          if (hunkHeader != null) {
            deletionStartLineNumber = int.tryParse(hunkHeader.group(1) ?? "") ?? 0;
            insertionStartLineNumber = int.tryParse(hunkHeader.group(3) ?? "") ?? 0;
            hunkStartIndex = indexedLine.$1;
            return ("", "");
          }

          if (RegExp(r"(?<=-{5}deletion-{5}).*$").firstMatch(indexedLine.$2) != null &&
              RegExp(r"(?<=\+{5}insertion\+{5}).*$").firstMatch(indexedLine.$2) != null) {
            return (
              "-$conflictSeparator${deletionStartLineNumber - 1 + (indexedLine.$1 - hunkStartIndex)}",
              "+$conflictSeparator${insertionStartLineNumber - 1 + (indexedLine.$1 - hunkStartIndex)}",
            );
          }
          if (RegExp(r"(?<=-{5}deletion-{5}).*$").firstMatch(indexedLine.$2) != null) {
            return ("-$conflictSeparator${deletionStartLineNumber - 1 + (indexedLine.$1 - hunkStartIndex)}", "");
          }
          if (RegExp(r"(?<=\+{5}insertion\+{5}).*$").firstMatch(indexedLine.$2) != null) {
            return ("", "+$conflictSeparator${insertionStartLineNumber - 1 + (indexedLine.$1 - hunkStartIndex)}");
          }
          if (indexedLine.$1 == indexedLines.length - 1 && indexedLine.$2.isEmpty) {
            return ("", "");
          }
          return (
            "${deletionStartLineNumber - 1 + (indexedLine.$1 - hunkStartIndex)}",
            "${insertionStartLineNumber - 1 + (indexedLine.$1 - hunkStartIndex)}",
          );
        });
        deletionDiffLineNumbers.addAll(diffLineNumbers.map((item) => item.$1));
        insertionDiffLineNumbers.addAll(diffLineNumbers.map((item) => item.$2));
        if (mounted) setState(() {});
      });
    }

    if (widget.verticalScrollController != null) verticalController = widget.verticalScrollController!;

    try {
      _mapFile();
      controller.text = writeMmap == null ? widget.text ?? "" : utf8.decode(writeMmap!.writableData, allowMalformed: true);
      if (widget.type == EditorType.LOGS) controller.text = controller.text.split("\n").reversed.join("\n");

      controller.addListener(_onTextChanged);
    } catch (e) {
      print(e);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      initAsync(() async {
        if (widget.type != EditorType.LOGS || controller.text.isEmpty) return;

        final chunkController = ReEditor.CodeChunkController(controller, LogsChunkAnalyzer());
        try {
          while (chunkController.value.isEmpty) {
            await Future.delayed(Duration(milliseconds: 100));
          }
          int offset = 0;

          for (final chunk in chunkController.value) {
            chunkController.collapse(chunk.index - offset);
            offset += max(0, chunk.end - chunk.index - 1);
          }
          logsCollapsed = true;
          if (mounted) setState(() {});
        } catch (e) {
          if (e.toString().contains("A _CodeLineEditingControllerImpl was used after being disposed.")) {
            return;
          }
          throw e;
        }
      });
    });

    languages = {
      ...(widget.path != null && (extensionToLanguageMap.keys.contains(p.extension(widget.path!).replaceFirst('.', '')))
          ? extensionToLanguageMap[p.extension(widget.path!).replaceFirst('.', '')]!
          : extensionToLanguageMap["txt"]!),
      if (widget.type == EditorType.DIFF) "diff": langDiff,
    }.map((key, value) => MapEntry(key, ReEditor.CodeHighlightThemeMode(mode: value)));
  }

  void _mapFile() {
    writeMmap?.close();
    if (widget.path == null) return;
    writeMmap = Mmap.fromFile(widget.path!, mode: AccessMode.write);
  }

  void _onTextChanged() async {
    if (widget.path != null) {
      fileSaving.value = true;

      await Future.delayed(Duration(seconds: 1));

      final newBytes = Uint8List.fromList(controller.text.codeUnits);

      if (writeMmap == null || !writeMmap!.isOpen) return;

      if (newBytes.length != writeMmap!.writableData.length) {
        File(widget.path!).writeAsStringSync(controller.text);
        _mapFile();
      } else {
        writeMmap!.writableData.setAll(0, newBytes);
        writeMmap!.sync();
      }

      fileSaving.value = false;
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onTextChanged);
    writeMmap?.sync();
    writeMmap?.close();
    writeMmap = null;
    controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(cornerRadiusMD),
            color: widget.type == EditorType.DIFF ? Colors.transparent : colours.tertiaryDark,
          ),
          margin: widget.type == EditorType.DIFF ? EdgeInsets.zero : EdgeInsets.only(left: spaceSM, right: spaceSM, bottom: spaceLG),
          padding: widget.type == EditorType.DIFF ? EdgeInsets.zero : EdgeInsets.only(right: spaceXS, top: spaceXXXXS),
          clipBehavior: Clip.hardEdge,
          child: widget.type == EditorType.LOGS && !logsCollapsed
              ? Center(child: CircularProgressIndicator(color: colours.primaryLight))
              : ReEditor.CodeEditor(
                  controller: controller,
                  scrollController: ReEditor.CodeScrollController(verticalScroller: verticalController, horizontalScroller: horizontalController),
                  wordWrap: editorLineWrap,
                  chunkAnalyzer: widget.type == EditorType.LOGS ? LogsChunkAnalyzer() : ReEditor.DefaultCodeChunkAnalyzer(),
                  style: ReEditor.CodeEditorStyle(
                    textColor: colours.tertiaryLight,
                    fontSize: textMD,
                    fontFamily: "RobotoMono",
                    codeTheme: ReEditor.CodeHighlightTheme(
                      languages: languages,
                      theme: {
                        'root': TextStyle(color: colours.primaryLight),
                        'comment': TextStyle(color: colours.secondaryLight),
                        'quote': TextStyle(color: colours.tertiaryInfo),
                        'variable': TextStyle(color: colours.secondaryWarning),
                        'template-variable': TextStyle(color: colours.secondaryWarning),
                        'tag': TextStyle(color: colours.secondaryWarning),
                        'name': TextStyle(color: colours.secondaryWarning),
                        'selector-id': TextStyle(color: colours.secondaryWarning),
                        'selector-class': TextStyle(color: colours.secondaryWarning),
                        'regexp': TextStyle(color: colours.secondaryWarning),
                        'number': TextStyle(color: colours.primaryWarning),
                        'built_in': TextStyle(color: colours.primaryWarning),
                        'builtin-name': TextStyle(color: colours.primaryWarning),
                        'literal': TextStyle(color: colours.primaryWarning),
                        'type': TextStyle(color: colours.primaryWarning),
                        'params': TextStyle(color: colours.primaryWarning),
                        'meta': TextStyle(color: colours.primaryWarning),
                        'link': TextStyle(color: colours.primaryWarning),
                        'attribute': TextStyle(color: colours.tertiaryInfo),
                        'string': TextStyle(color: colours.primaryPositive),
                        'symbol': TextStyle(color: colours.primaryPositive),
                        'bullet': TextStyle(color: colours.primaryPositive),
                        'title': TextStyle(color: colours.tertiaryInfo, fontWeight: FontWeight.w500),
                        'section': TextStyle(color: colours.tertiaryInfo, fontWeight: FontWeight.w500),
                        'keyword': TextStyle(color: colours.tertiaryNegative),
                        'selector-tag': TextStyle(color: colours.tertiaryNegative),
                        'emphasis': TextStyle(fontStyle: FontStyle.italic),
                        'strong': TextStyle(fontWeight: FontWeight.bold),

                        'logRoot': TextStyle(color: colours.primaryLight, fontFamily: "Roboto"),
                        'logComment': TextStyle(color: colours.secondaryLight, fontFamily: "Roboto"),
                        'logDate': TextStyle(color: colours.tertiaryInfo.withAlpha(170), fontFamily: "Roboto"),
                        'logTime': TextStyle(color: colours.tertiaryInfo, fontFamily: "Roboto"),
                        'logLevel': TextStyle(color: colours.tertiaryPositive, fontFamily: "Roboto"),
                        'logComponent': TextStyle(color: colours.primaryPositive, fontFamily: "Roboto"),
                        'logError': TextStyle(color: colours.tertiaryNegative, fontFamily: "Roboto"),

                        'diffRoot': TextStyle(color: colours.tertiaryLight),
                        'diffHunkHeader': TextStyle(
                          backgroundColor: colours.tertiaryDark,
                          color: colours.tertiaryLight,
                          fontWeight: FontWeight.w500,
                          fontFamily: "Roboto",
                        ),
                        'eof': TextStyle(
                          backgroundColor: colours.tertiaryDark,
                          color: colours.tertiaryLight,
                          fontWeight: FontWeight.w500,
                          fontFamily: "Roboto",
                        ),
                        'diffHide': TextStyle(wordSpacing: 0, fontSize: 0, fontFamily: "Roboto"),
                        'addition': TextStyle(color: colours.tertiaryPositive, fontWeight: FontWeight.w400),
                        'deletion': TextStyle(color: colours.tertiaryNegative, fontWeight: FontWeight.w400),
                      },
                    ),
                  ),
                  readOnly: widget.type == EditorType.LOGS || widget.type == EditorType.DIFF,
                  showCursorWhenReadOnly: true,
                  toolbarController: ContextMenuControllerImpl(widget.type == EditorType.LOGS || widget.type == EditorType.DIFF),
                  indicatorBuilder: (context, editingController, chunkController, notifier) {
                    return Row(
                      children: [
                        if (widget.type == EditorType.DEFAULT) ReEditor.DefaultCodeLineNumber(controller: editingController, notifier: notifier),
                        if (widget.type == EditorType.DIFF && deletionDiffLineNumbers.any((item) => item.isNotEmpty))
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: spaceXXXXS / 2),
                            child: CodeLineNumber(
                              controller: editingController,
                              notifier: notifier,
                              focusedTextStyle: TextStyle(color: colours.secondaryLight, fontSize: textMD),
                              customLineIndex2TextStyle: (lineIndex) {
                                return TextStyle(
                                  fontFamily: "RobotoMono",
                                  color: deletionDiffLineNumbers[lineIndex].split(conflictSeparator).first == "-"
                                      ? colours.tertiaryNegative
                                      : colours.tertiaryLight,
                                  fontSize: textMD,
                                );
                              },
                              customLineIndex2Text: (lineIndex) {
                                return "${deletionDiffLineNumbers.length > lineIndex ? deletionDiffLineNumbers[lineIndex].split(conflictSeparator).last : ""}";
                              },
                            ),
                          ),
                        if (widget.type == EditorType.DIFF &&
                            insertionDiffLineNumbers.any((item) => item.isNotEmpty) &&
                            deletionDiffLineNumbers.any((item) => item.isNotEmpty))
                          Container(width: spaceXXXS),
                        if (widget.type == EditorType.DIFF && insertionDiffLineNumbers.any((item) => item.isNotEmpty))
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: spaceXXXXS / 2),
                            child: CodeLineNumber(
                              controller: editingController,
                              notifier: notifier,
                              focusedTextStyle: TextStyle(color: colours.secondaryLight, fontSize: textMD),
                              customLineIndex2TextStyle: (lineIndex) {
                                return TextStyle(
                                  fontFamily: "RobotoMono",
                                  color: insertionDiffLineNumbers[lineIndex].split(conflictSeparator).first == "+"
                                      ? colours.tertiaryPositive
                                      : colours.tertiaryLight,
                                  fontSize: textMD,
                                );
                              },
                              customLineIndex2Text: (lineIndex) {
                                return "${insertionDiffLineNumbers.length > lineIndex ? insertionDiffLineNumbers[lineIndex].split(conflictSeparator).last : ""}";
                              },
                            ),
                          ),
                        if (widget.type == EditorType.DEFAULT || widget.type == EditorType.LOGS)
                          ReEditor.DefaultCodeChunkIndicator(width: 20, controller: chunkController, notifier: notifier),
                      ],
                    );
                  },
                ),
        ),
        if (widget.type == EditorType.DEFAULT)
          Positioned(
            bottom: spaceXXL,
            child: Container(
              decoration: BoxDecoration(color: colours.primaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
              padding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceXS),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        style: ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        constraints: BoxConstraints(),
                        onPressed: () async {
                          await InfoDialog.showDialog(
                            context,
                            t.codeEditorLimits,
                            t.codeEditorLimitsDescription,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
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
                                SizedBox(height: spaceSM),
                                ButtonSetting(
                                  text: t.reportABug,
                                  icon: FontAwesomeIcons.bug,
                                  textColor: colours.primaryDark,
                                  iconColor: colours.primaryDark,
                                  buttonColor: colours.tertiaryNegative,
                                  onPressed: () async {
                                    await Logger.reportIssue(context, From.CODE_EDITOR);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                        visualDensity: VisualDensity.compact,
                        icon: FaIcon(FontAwesomeIcons.circleInfo, color: colours.secondaryLight, size: textMD),
                      ),
                      Text(
                        t.experimental.toUpperCase(),
                        style: TextStyle(color: colours.primaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: spaceXS),
                    ],
                  ),
                  SizedBox(height: spaceXXXS),
                  Text(
                    t.experimentalMsg,
                    style: TextStyle(color: colours.secondaryLight, fontSize: textSM),
                  ),
                ],
              ),
            ),
          ),
        widget.type == EditorType.DEFAULT
            ? Positioned(
                top: spaceMD,
                right: spaceMD + spaceSM,
                child: ValueListenableBuilder(
                  valueListenable: fileSaving,
                  builder: (context, saving, _) => saving
                      ? Container(
                          height: spaceMD + spaceXXS,
                          width: spaceMD + spaceXXS,
                          child: CircularProgressIndicator(color: colours.primaryLight),
                        )
                      : SizedBox.shrink(),
                ),
              )
            : SizedBox.shrink(),
      ],
    );
  }
}

Route createCodeEditorRoute(List<String> paths, {EditorType type = EditorType.DEFAULT}) {
  return PageRouteBuilder(
    settings: const RouteSettings(name: code_editor),
    pageBuilder: (context, animation, secondaryAnimation) => CodeEditor(paths: paths, type: type),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      const curve = Curves.ease;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}
