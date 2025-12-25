import 'package:GitSync/constant/strings.dart';
import 'package:GitSync/src/rust/api/git_manager.dart' as GitManagerRs;
import 'package:GitSync/ui/component/diff_file.dart';
import 'package:collection/collection.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sprintf/sprintf.dart';
import '../../../constant/colors.dart';
import '../../../constant/dimens.dart';
import '../../../global.dart';
import '../../../ui/dialog/base_alert_dialog.dart';

Future<void> showDialog(
  BuildContext parentContext,
  GitManagerRs.Diff? diff,
  String titleText,
  (GitManagerRs.Commit, GitManagerRs.Commit?)? data, [
  String? openedFromFile,
]) async {
  bool copiedStartCommitReference = false;
  bool copiedEndCommitReference = false;
  bool commitMessageExpanded = false;

  final dirPath = await uiSettingsManager.getGitDirPath(true);

  final diffFiles =
      diff?.diffParts.map(
        (key, value) => MapEntry(
          key,
          value.entries
              .sortedBy((entry) => (int.tryParse(RegExp(r'\+([^,]+),').firstMatch(entry.key)?.group(1) ?? "") ?? 0))
              .map((entry) => "${entry.key}${entry.value}")
              .join("\n"),
        ),
      ) ??
      {};

  return await mat.showDialog(
    context: parentContext,
    barrierColor: Colors.transparent,
    builder: (BuildContext context) => StatefulBuilder(
      builder: (context, setState) {
        void copyStartCommitReference() async {
          copiedStartCommitReference = true;
          setState(() {});

          await Clipboard.setData(ClipboardData(text: data?.$1.reference ?? ""));

          await Future.delayed(Duration(seconds: 2), () {
            copiedStartCommitReference = false;
            setState(() {});
          });
        }

        void copyEndCommitReference() async {
          copiedEndCommitReference = true;
          setState(() {});

          await Clipboard.setData(ClipboardData(text: data?.$1.reference ?? ""));

          await Future.delayed(Duration(seconds: 2), () {
            copiedEndCommitReference = false;
            setState(() {});
          });
        }

        return OrientationBuilder(
          builder: (context, orientation) => BaseAlertDialog(
            expandable: true,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: data == null
                          ? null
                          : () {
                              copyStartCommitReference();
                            },
                      child: Row(
                        children: [
                          if (data != null)
                            Padding(
                              padding: EdgeInsets.only(bottom: spaceXS),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                style: ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                constraints: BoxConstraints(),
                                onPressed: () async => copyStartCommitReference(),
                                icon: FaIcon(
                                  copiedStartCommitReference ? FontAwesomeIcons.clipboardCheck : FontAwesomeIcons.solidCopy,
                                  size: copiedStartCommitReference ? textMD : textSM,
                                  color: copiedStartCommitReference ? primaryPositive : tertiaryLight,
                                ),
                              ),
                            ),
                          if (data != null) SizedBox(width: spaceXXXXS),
                          SizedBox(
                            width: data != null ? null : MediaQuery.of(context).size.width - (spaceXXL * 2),
                            child: ExtendedText(
                              "${(data != null ? titleText : titleText.replaceAll("$dirPath/", "")).toUpperCase()}",
                              maxLines: data != null ? null : 1,
                              textAlign: TextAlign.center,
                              overflowWidget: TextOverflowWidget(
                                position: TextOverflowPosition.start,
                                child: Text(
                                  "…",
                                  style: TextStyle(color: primaryLight, fontSize: textXL),
                                ),
                              ),
                              style: TextStyle(
                                color: copiedStartCommitReference ? tertiaryPositive : primaryLight,
                                fontSize: textXL,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (data != null) ...[
                      SizedBox(width: spaceXS),
                      FaIcon(FontAwesomeIcons.rightLeft, color: tertiaryLight, size: textMD),
                      SizedBox(width: spaceXS),
                      GestureDetector(
                        onTap: data?.$2 == null
                            ? null
                            : () {
                                copyEndCommitReference();
                              },
                        child: Row(
                          children: [
                            Text(
                              (data?.$2?.reference.substring(0, 7) ?? "EMPTY").toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: copiedEndCommitReference ? tertiaryPositive : secondaryLight,
                                fontSize: textXL,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: spaceXXXXS),
                            Padding(
                              padding: EdgeInsets.only(bottom: spaceXS),
                              child: data?.$2 == null
                                  ? null
                                  : IconButton(
                                      padding: EdgeInsets.zero,
                                      style: ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                      constraints: BoxConstraints(),
                                      onPressed: () async => copyEndCommitReference(),
                                      icon: FaIcon(
                                        copiedEndCommitReference ? FontAwesomeIcons.clipboardCheck : FontAwesomeIcons.solidCopy,
                                        size: copiedEndCommitReference ? textMD : textSM,
                                        color: copiedEndCommitReference ? primaryPositive : tertiaryLight,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                if (data != null) ...[
                  SizedBox(height: spaceXS),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Container(
                                constraints: BoxConstraints(maxHeight: textSM * 5),
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
                                    child: Text(
                                      data.$1.commitMessage.contains("\n") && !commitMessageExpanded
                                          ? data.$1.commitMessage.split("\n").first
                                          : data.$1.commitMessage,
                                      maxLines: commitMessageExpanded ? null : 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.left,
                                      softWrap: true,
                                      style: const TextStyle(color: tertiaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (data.$1.commitMessage.contains("\n")) ...[
                              SizedBox(width: spaceXXXXS),
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: spaceXXXXS),
                                child: IconButton(
                                  padding: EdgeInsets.all(spaceXXXS),
                                  style: ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                  visualDensity: VisualDensity.compact,
                                  constraints: BoxConstraints(),
                                  onPressed: () async {
                                    commitMessageExpanded = !commitMessageExpanded;
                                    setState(() {});
                                  },
                                  icon: FaIcon(commitMessageExpanded ? FontAwesomeIcons.chevronUp : FontAwesomeIcons.chevronDown, size: textSM),
                                ),
                              ),
                              SizedBox(width: spaceXXXXS),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: spaceXXXS, vertical: spaceXXXXS),
                        decoration: BoxDecoration(borderRadius: BorderRadius.all(cornerRadiusXS), color: secondaryDark),
                        child: Text(
                          "${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.fromMillisecondsSinceEpoch(data.$1.timestamp * 1000))}",
                          maxLines: 1,
                          style: const TextStyle(color: tertiaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
                if (data != null) ...[
                  SizedBox(height: spaceXXS),
                  SizedBox(
                    width: double.infinity,
                    child: Row(
                      children: [
                        Text(
                          "${data?.$1.authorUsername}",
                          textAlign: TextAlign.left,
                          maxLines: 1,
                          style: const TextStyle(color: tertiaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: spaceSM),
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                "\<",
                                textAlign: TextAlign.left,
                                maxLines: 1,
                                style: const TextStyle(color: tertiaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                              ),
                              Flexible(
                                child: Text(
                                  "${data?.$1.authorEmail}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: tertiaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text(
                                "\>",
                                textAlign: TextAlign.left,
                                maxLines: 1,
                                style: const TextStyle(color: tertiaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: spaceXS),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: spaceXS),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${diff?.diffParts.keys.length ?? 0} ${t.filesChanged}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: primaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Text(
                            sprintf(t.additions, [diff?.insertions ?? 0]),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: tertiaryPositive, fontSize: textMD, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: spaceMD),
                          Text(
                            sprintf(t.deletions, [diff?.deletions ?? 0]),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: tertiaryNegative, fontSize: textMD, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            contentPadding: EdgeInsets.only(top: spaceXS),
            contentBuilder: (expanded) {
              List<Widget> children = diffFiles.entries
                  .sortedBy((entry) => entry.key.contains(conflictSeparator) ? entry.key.split(conflictSeparator).first : entry.key)
                  .indexed
                  .map(
                    (indexedEntry) => DiffFile(
                      key: Key(indexedEntry.$2.key),
                      orientation: orientation,
                      openedFromFile: openedFromFile,
                      indexedEntry.$2,
                      titleText,
                      diffFiles.keys.first.contains(conflictSeparator) ? indexedEntry.$1 == diffFiles.entries.length - 1 : indexedEntry.$1 == 0,
                    ),
                  )
                  .toList();

              if (diffFiles.keys.first.contains(conflictSeparator)) children = children.reversed.toList();
              return SingleChildScrollView(child: ListBody(children: children));
            },
            actionsAlignment: MainAxisAlignment.center,
            actions: <Widget>[],
          ),
        );
      },
    ),
  );
}
