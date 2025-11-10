import 'package:GitSync/src/rust/api/git_manager.dart' as GitManagerRs;
import 'package:GitSync/ui/component/diff_file.dart';
import 'package:collection/collection.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/api/manager/git_manager.dart';
import 'package:intl/intl.dart';
import 'package:sprintf/sprintf.dart';
import '../../../constant/colors.dart';
import '../../../constant/dimens.dart';
import '../../../global.dart';
import '../../../ui/dialog/base_alert_dialog.dart';

Future<void> showDialog(BuildContext parentContext, GitManagerRs.Commit startCommit, GitManagerRs.Commit endCommit) async {
  bool copiedStartCommitReference = false;
  bool copiedEndCommitReference = false;

  print("////email ${startCommit.authorEmail}");

  final diff = await GitManager.getDiff(startCommit.reference, endCommit.reference);
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
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
                    onTap: () {
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      startCommit.commitMessage,
                      textAlign: TextAlign.left,
                      softWrap: true,
                      style: const TextStyle(color: tertiaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: spaceXXXS, vertical: spaceXXXXS),
                    decoration: BoxDecoration(borderRadius: BorderRadius.all(cornerRadiusXS), color: secondaryDark),
                    child: Text(
                      "${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.fromMillisecondsSinceEpoch(startCommit.timestamp * 1000))}",
                      maxLines: 1,
                      style: const TextStyle(color: tertiaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              SizedBox(height: spaceXXS),
              SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    Text(
                      "${startCommit.authorUsername}",
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
                              startCommit.authorEmail,
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
              SizedBox(height: spaceXS),
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
                ...diffFiles.entries
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
