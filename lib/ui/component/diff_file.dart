import 'package:GitSync/api/helper.dart';
import 'package:GitSync/constant/colors.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/ui/page/code_editor.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sprintf/sprintf.dart';

final insertionRegex = RegExp(r'\+{5}insertion\+{5}');
final deletionRegex = RegExp(r'-{5}deletion-{5}');

class DiffFile extends StatefulWidget {
  DiffFile(this.entry, this.expandedDefault, {super.key});

  final MapEntry<String, String> entry;
  final bool expandedDefault;

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
                child: FaIcon(
                  expanded ? FontAwesomeIcons.chevronDown : FontAwesomeIcons.chevronRight,
                  color: expanded ? secondaryLight : primaryLight,
                  size: textSM,
                ),
              ),
              label: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: ExtendedText(
                      widget.entry.key,
                      maxLines: 1,
                      textAlign: TextAlign.left,
                      overflowWidget: TextOverflowWidget(
                        position: TextOverflowPosition.start,
                        child: Text(
                          "…",
                          style: TextStyle(color: primaryLight, fontSize: textMD),
                        ),
                      ),
                      style: TextStyle(color: primaryLight, fontSize: textMD),
                    ),
                  ),
                  Row(
                    children: [
                      SizedBox(width: spaceMD),
                      Text(
                        sprintf(t.additions, [insertions]),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: tertiaryPositive, fontSize: textSM, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: spaceMD),
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
