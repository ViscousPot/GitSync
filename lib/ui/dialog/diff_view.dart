import 'package:GitSync/src/rust/api/git_manager.dart' as GitManagerRs;
import 'package:GitSync/ui/component/diff_file.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/api/manager/git_manager.dart';
import 'package:GitSync/constant/strings.dart';
import 'package:sprintf/sprintf.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../constant/colors.dart';
import '../../../constant/dimens.dart';
import '../../../global.dart';
import '../../../ui/dialog/base_alert_dialog.dart';

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

Future<void> showDialog(BuildContext parentContext, GitManagerRs.Commit startCommit, GitManagerRs.Commit endCommit) async {
  bool copiedStartCommitReference = false;
  bool copiedEndCommitReference = false;

  final diff = await GitManager.getDiff(startCommit.reference, endCommit.reference);

  return await mat.showDialog(
    context: parentContext,
    barrierColor: Colors.transparent,
    builder: (BuildContext context) => StatefulBuilder(
      builder: (context, setState) {
        void copyStartCommitReference() async {
          copiedStartCommitReference = true;
          setState(() {});

          await Clipboard.setData(ClipboardData(text: startCommit.reference));

          await Future.delayed(Duration(seconds: 2), () {
            copiedStartCommitReference = false;
            setState(() {});
          });
        }

        void copyEndCommitReference() async {
          copiedEndCommitReference = true;
          setState(() {});

          await Clipboard.setData(ClipboardData(text: startCommit.reference));

          await Future.delayed(Duration(seconds: 2), () {
            copiedEndCommitReference = false;
            setState(() {});
          });
        }

        return BaseAlertDialog(
          expandable: true,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onLongPress: () {
                      copyStartCommitReference();
                    },
                    child: Row(
                      children: [
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
                        SizedBox(width: spaceXXXXS),
                        Text(
                          startCommit.reference.substring(0, 7).toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: copiedStartCommitReference ? tertiaryPositive : primaryLight,
                            fontSize: textXL,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: spaceXS),
                  FaIcon(FontAwesomeIcons.rightLeft, color: tertiaryLight, size: textMD),
                  SizedBox(width: spaceXS),
                  GestureDetector(
                    onLongPress: () {
                      copyEndCommitReference();
                    },
                    child: Row(
                      children: [
                        Text(
                          endCommit.reference.substring(0, 7).toUpperCase(),
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
                          child: IconButton(
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
              ),
              SizedBox(height: spaceXS),
              Text(
                startCommit.commitMessage,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: const TextStyle(color: tertiaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: spaceXXS),
              Text(
                "${startCommit.author} ${t.committed} ${timeago.format(DateTime.fromMillisecondsSinceEpoch(startCommit.timestamp * 1000), locale: 'en').replaceFirstMapped(RegExp(r'^[A-Z]'), (match) => match.group(0)!.toLowerCase())}",
                textAlign: TextAlign.center,
                maxLines: 1,
                style: const TextStyle(color: tertiaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: spaceSM),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: spaceXS),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${diff?.filesChanged ?? 0} file(s) changed",
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
          contentBuilder: (expanded) => SingleChildScrollView(
            child: ListBody(
              children: [
                ...(diff?.diffParts ?? {}).entries
                    .sortedBy((entry) => entry.key)
                    .indexed
                    .map((indexedEntry) => DiffFile(key: Key(indexedEntry.$2.key), indexedEntry.$2, indexedEntry.$1 == 0)),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[],
        );
      },
    ),
  );
}
