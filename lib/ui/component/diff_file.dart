import 'package:GitSync/constant/colors.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/global.dart';
import 'package:collection/collection.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sprintf/sprintf.dart';

final insertionRegex = RegExp(r'\+{5}insertion\+{5}');
final deletionRegex = RegExp(r'-{5}deletion-{5}');

class DiffFile extends StatefulWidget {
  DiffFile(this.entry, this.expandedDefault, {super.key});

  final MapEntry<String, Map<String, String>> entry;
  final bool expandedDefault;

  @override
  State<DiffFile> createState() => _DiffFileState();
}

class _DiffFileState extends State<DiffFile> {
  bool expanded = false;
  int insertions = 0;
  int deletions = 0;

  @override
  void initState() {
    super.initState();
    expanded = widget.expandedDefault;
    insertions = 0;
    deletions = 0;
    for (var value in widget.entry.value.values) {
      insertions += insertionRegex.allMatches(value).length;
      deletions += deletionRegex.allMatches(value).length;
    }
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
              ? Padding(
                  padding: EdgeInsets.only(left: spaceSM, right: spaceSM, bottom: spaceSM),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: expanded ? MediaQuery.sizeOf(context).height * 0.8 : MediaQuery.sizeOf(context).height / 3,
                        minWidth: MediaQuery.sizeOf(context).width,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...widget.entry.value.entries
                                .sortedBy((entry) => (int.tryParse(RegExp(r'\+([^,]+),').firstMatch(entry.key)?.group(1) ?? "") ?? 0))
                                .map(
                                  (entry) => Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        color: tertiaryDark,
                                        child: Text(
                                          entry.key,
                                          maxLines: 1,
                                          style: TextStyle(color: tertiaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      ...entry.value.split("\n").indexed.map((indexedLine) {
                                        final lineParts = splitTextWithMarkers(indexedLine.$2);

                                        return Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              "${indexedLine.$1 + (int.tryParse(RegExp(r'\+([^,]+),').firstMatch(entry.key)?.group(1) ?? "") ?? 0)}",
                                              style: TextStyle(color: tertiaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                                            ),
                                            SizedBox(width: spaceSM),
                                            Text.rich(
                                              TextSpan(
                                                children: lineParts
                                                    .map(
                                                      (part) => TextSpan(
                                                        text: part.$1.isEmpty ? "-" : part.$1,
                                                        style: TextStyle(
                                                          color: part.$1.isEmpty
                                                              ? Colors.transparent
                                                              : (part.$2 == 1
                                                                    ? tertiaryPositive
                                                                    : (part.$2 == -1 ? tertiaryNegative : secondaryLight)),
                                                          decoration: part.$2 == -1 ? TextDecoration.lineThrough : TextDecoration.none,
                                                          decorationThickness: 2,
                                                          decorationColor: tertiaryNegative,
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                              ),

                                              style: TextStyle(color: secondaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : SizedBox.shrink(),
        ],
      ),
    );
  }
}
