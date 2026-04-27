import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import 'package:sprintf/sprintf.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';
import 'package:GitSync/api/ai_completion_service.dart';
import 'package:GitSync/api/manager/git_manager.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/ui/component/ai_wand_field.dart';
import 'package:GitSync/src/rust/api/git_manager.dart' as GitManagerRs;

Future<void> showDialog(
  BuildContext context,
  List<GitManagerRs.Commit> selectedCommits,
  String initialMessage,
  Future<void> Function(String squashMessage) callback,
) {
  bool loading = false;
  final messageController = TextEditingController(text: initialMessage);
  final hasPushed = selectedCommits.any((c) => !c.unpushed);

  return mat.showDialog(
    context: context,
    builder: (BuildContext context) => StatefulBuilder(
      builder: (context, setState) => BaseAlertDialog(
        title: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Text(
            t.squashCommits,
            style: TextStyle(color: colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
          ),
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(color: colours.primaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
                  children: [
                    TextSpan(text: sprintf(t.squashCommitsMsg, [selectedCommits.length])),
                  ],
                ),
              ),
              SizedBox(height: spaceXS),
              ...selectedCommits.map(
                (commit) => Padding(
                  padding: EdgeInsets.only(bottom: spaceXXXS),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(color: colours.tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusXS)),
                        padding: EdgeInsets.symmetric(horizontal: spaceXS, vertical: spaceXXXS),
                        child: Text(
                          commit.reference.substring(0, 7).toUpperCase(),
                          style: TextStyle(color: colours.tertiaryInfo, fontSize: textXS, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(width: spaceXS),
                      Expanded(
                        child: Text(
                          commit.commitMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colours.secondaryLight, fontSize: textXS),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: spaceMD),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AiWandField(
                    multiline: true,
                    onPressed: () async {
                      final buffer = StringBuffer();
                      for (final commit in selectedCommits) {
                        final shortSha = commit.reference.substring(0, 7);
                        buffer.writeln('$shortSha (+${commit.additions}/-${commit.deletions}): ${commit.commitMessage}');
                        final diff = await GitManager.getCommitDiff(commit.reference, '${commit.reference}^');
                        if (diff != null) {
                          buffer.writeln('Files: ${diff.diffParts.keys.join(", ")}');
                          buffer.write(formatDiffParts(diff.diffParts, maxChars: 2000));
                        }
                        buffer.writeln();
                        if (buffer.length > 4000) break;
                      }
                      final result = await aiComplete(
                        systemPrompt:
                            "Combine these commits into a single squash commit message. Use conventional commit format. Output only the message, nothing else.",
                        userPrompt: buffer.toString(),
                      );
                      if (result != null) {
                        messageController.text = result.trim();
                        setState(() {});
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(borderRadius: BorderRadius.all(cornerRadiusSM), color: colours.secondaryDark),
                      padding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceXS),
                      child: TextField(
                        controller: messageController,
                        maxLines: 5,
                        minLines: 3,
                        style: TextStyle(color: colours.primaryLight, fontSize: textSM),
                        decoration: InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -spaceXS,
                    left: spaceMD,
                    child: Text(
                      t.squashCommitMessage.toUpperCase(),
                      style: TextStyle(color: colours.secondaryLight, fontSize: textXXS, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              SizedBox(height: spaceSM),
              Text(
                t.squashCommitsWarning,
                style: TextStyle(color: hasPushed ? colours.primaryNegative : colours.tertiaryWarning, fontWeight: FontWeight.bold, fontSize: textSM),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(
              t.cancel.toUpperCase(),
              style: TextStyle(color: colours.primaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.of(context).canPop() ? Navigator.pop(context) : null;
            },
          ),
          TextButton.icon(
            label: Text(
              t.squash.toUpperCase(),
              style: TextStyle(color: colours.primaryPositive, fontSize: textMD, fontWeight: FontWeight.bold),
            ),
            iconAlignment: IconAlignment.end,
            icon: loading
                ? SizedBox(
                    height: spaceMD,
                    width: spaceMD,
                    child: CircularProgressIndicator(color: colours.primaryPositive),
                  )
                : SizedBox.shrink(),
            onPressed: () async {
              final message = messageController.text.trim();
              if (message.isEmpty) return;
              loading = true;
              setState(() {});
              await callback(message);
              loading = false;
              setState(() {});
              Navigator.of(context).canPop() ? Navigator.pop(context) : null;
            },
          ),
        ],
      ),
    ),
  );
}
