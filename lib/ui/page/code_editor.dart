import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:GitSync/api/helper.dart';
import 'package:GitSync/api/logger.dart';
import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/constant/colors.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/constant/values.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/ui/component/button_setting.dart';
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
                color: primaryDark,
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
                    style: TextStyle(fontSize: textMD, color: primaryLight, fontWeight: FontWeight.w500),
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
  GlobalKey key = GlobalKey();

  @override
  void initState() {
    super.initState();
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
        leading: getBackButton(context, () => (Navigator.of(context).canPop() ? Navigator.pop(context) : null)) ?? SizedBox.shrink(),
        title: SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  p.basename(widget.paths[index]),
                  style: TextStyle(fontSize: textLG, color: primaryLight, fontWeight: FontWeight.bold),
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
                              setState(() {});
                            }
                          : null,
                      icon: FaIcon(FontAwesomeIcons.caretLeft),
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(tertiaryDark),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM), side: BorderSide.none)),
                      ),
                      color: primaryLight,
                      disabledColor: tertiaryLight,
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
                              setState(() {});
                            }
                          : null,
                      icon: FaIcon(FontAwesomeIcons.caretRight),
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(tertiaryDark),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM), side: BorderSide.none)),
                      ),
                      color: primaryLight,
                      disabledColor: tertiaryLight,
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
      setState(() {});
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
            print("//// $deletionStartLineNumber $insertionStartLineNumber");
            hunkStartIndex = indexedLine.$1;
            return ("", "");
          }

          if (RegExp(r"(?<=-{5}deletion-{5}).*$").firstMatch(indexedLine.$2) != null) {
            return ("${deletionStartLineNumber - 1 + (indexedLine.$1 - hunkStartIndex)}", "");
          }
          if (RegExp(r"(?<=\+{5}insertion\+{5}).*$").firstMatch(indexedLine.$2) != null) {
            return ("", "${insertionStartLineNumber - 1 + (indexedLine.$1 - hunkStartIndex)}");
          }
          print(indexedLine);
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
        setState(() {});
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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.type == EditorType.DEFAULT || controller.text.isEmpty) return;

      final chunkController = ReEditor.CodeChunkController(controller, LogsChunkAnalyzer());
      while (chunkController.value.isEmpty) {
        await Future.delayed(Duration(milliseconds: 100));
      }
      int offset = 0;

      if (widget.type == EditorType.LOGS) {
        for (final chunk in chunkController.value) {
          chunkController.collapse(chunk.index - offset);
          offset += max(0, chunk.end - chunk.index - 1);
        }
      }
      logsCollapsed = true;
      setState(() {});
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

      if (writeMmap == null) return;

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
    controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
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
            color: widget.type == EditorType.DIFF ? Colors.transparent : tertiaryDark,
          ),
          margin: widget.type == EditorType.DIFF ? EdgeInsets.zero : EdgeInsets.only(left: spaceSM, right: spaceSM, bottom: spaceLG),
          padding: widget.type == EditorType.DIFF ? EdgeInsets.zero : EdgeInsets.only(right: spaceXS, top: spaceXXXXS),
          clipBehavior: Clip.hardEdge,
          child: widget.type == EditorType.LOGS && !logsCollapsed
              ? Center(child: CircularProgressIndicator(color: primaryLight))
              : ReEditor.CodeEditor(
                  controller: controller,
                  scrollController: ReEditor.CodeScrollController(verticalScroller: verticalController, horizontalScroller: horizontalController),
                  wordWrap: editorLineWrap,
                  chunkAnalyzer: widget.type == EditorType.LOGS ? LogsChunkAnalyzer() : ReEditor.DefaultCodeChunkAnalyzer(),
                  style: ReEditor.CodeEditorStyle(
                    textColor: Color(0xfff8f8f2),
                    fontSize: textMD,
                    fontFamily: "RobotoMono",
                    codeTheme: ReEditor.CodeHighlightTheme(
                      languages: languages,
                      theme: {
                        'root': TextStyle(color: primaryLight),
                        'comment': TextStyle(color: secondaryLight),
                        'quote': TextStyle(color: tertiaryInfo),
                        'variable': TextStyle(color: secondaryWarning),
                        'template-variable': TextStyle(color: secondaryWarning),
                        'tag': TextStyle(color: secondaryWarning),
                        'name': TextStyle(color: secondaryWarning),
                        'selector-id': TextStyle(color: secondaryWarning),
                        'selector-class': TextStyle(color: secondaryWarning),
                        'regexp': TextStyle(color: secondaryWarning),
                        'number': TextStyle(color: primaryWarning),
                        'built_in': TextStyle(color: primaryWarning),
                        'builtin-name': TextStyle(color: primaryWarning),
                        'literal': TextStyle(color: primaryWarning),
                        'type': TextStyle(color: primaryWarning),
                        'params': TextStyle(color: primaryWarning),
                        'meta': TextStyle(color: primaryWarning),
                        'link': TextStyle(color: primaryWarning),
                        'attribute': TextStyle(color: tertiaryInfo),
                        'string': TextStyle(color: primaryPositive),
                        'symbol': TextStyle(color: primaryPositive),
                        'bullet': TextStyle(color: primaryPositive),
                        'title': TextStyle(color: tertiaryInfo, fontWeight: FontWeight.w500),
                        'section': TextStyle(color: tertiaryInfo, fontWeight: FontWeight.w500),
                        'keyword': TextStyle(color: tertiaryNegative),
                        'selector-tag': TextStyle(color: tertiaryNegative),
                        'emphasis': TextStyle(fontStyle: FontStyle.italic),
                        'strong': TextStyle(fontWeight: FontWeight.bold),

                        'logRoot': TextStyle(color: primaryLight, fontFamily: "Roboto"),
                        'logComment': TextStyle(color: secondaryLight, fontFamily: "Roboto"),
                        'logDate': TextStyle(color: tertiaryInfo.withAlpha(170), fontFamily: "Roboto"),
                        'logTime': TextStyle(color: tertiaryInfo, fontFamily: "Roboto"),
                        'logLevel': TextStyle(color: tertiaryPositive, fontFamily: "Roboto"),
                        'logComponent': TextStyle(color: primaryPositive, fontFamily: "Roboto"),
                        'logError': TextStyle(color: tertiaryNegative, fontFamily: "Roboto"),

                        'diffRoot': TextStyle(color: tertiaryLight),
                        'diffHunkHeader': TextStyle(
                          backgroundColor: tertiaryDark,
                          color: tertiaryLight,
                          fontWeight: FontWeight.w500,
                          fontFamily: "Roboto",
                        ),
                        'eof': TextStyle(backgroundColor: tertiaryDark, color: tertiaryLight, fontWeight: FontWeight.w500, fontFamily: "Roboto"),
                        'diffHide': TextStyle(wordSpacing: 0, fontSize: 0, fontFamily: "Roboto"),
                        'addition': TextStyle(color: tertiaryPositive, fontWeight: FontWeight.w400),
                        'deletion': TextStyle(color: tertiaryNegative, fontWeight: FontWeight.w400),
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
                          ReEditor.DefaultCodeLineNumber(
                            controller: editingController,
                            notifier: notifier,
                            customLineIndex2Text: (lineIndex) {
                              return "${deletionDiffLineNumbers.length > lineIndex ? deletionDiffLineNumbers[lineIndex] : ""}";
                            },
                          ),
                        if (widget.type == EditorType.DIFF && insertionDiffLineNumbers.any((item) => item.isNotEmpty))
                          ReEditor.DefaultCodeLineNumber(
                            controller: editingController,
                            notifier: notifier,
                            customLineIndex2Text: (lineIndex) {
                              return "${insertionDiffLineNumbers.length > lineIndex ? insertionDiffLineNumbers[lineIndex] : ""}";
                            },
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
              decoration: BoxDecoration(color: primaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
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
                                  textColor: primaryDark,
                                  iconColor: primaryDark,
                                  buttonColor: tertiaryNegative,
                                  onPressed: () async {
                                    await Logger.reportIssue(context, From.CODE_EDITOR);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                        visualDensity: VisualDensity.compact,
                        icon: FaIcon(FontAwesomeIcons.circleInfo, color: secondaryLight, size: textMD),
                      ),
                      Text(
                        t.experimental.toUpperCase(),
                        style: TextStyle(color: primaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: spaceXS),
                    ],
                  ),
                  SizedBox(height: spaceXXXS),
                  Text(
                    t.experimentalMsg,
                    style: TextStyle(color: secondaryLight, fontSize: textSM),
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
                          child: CircularProgressIndicator(color: primaryLight),
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
