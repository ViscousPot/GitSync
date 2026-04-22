import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';
import 'package:GitSync/api/ai_completion_service.dart';
import 'package:GitSync/api/manager/git_manager.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/ui/component/ai_wand_field.dart';

Future<void> showDialog(BuildContext context, String commitSha, String commitMessage, Future<void> Function(String newMessage) callback) {
  bool loading = false;
  final controller = TextEditingController(text: commitMessage);

  return mat.showDialog(
    context: context,
    builder: (BuildContext context) => StatefulBuilder(
      builder: (context, setState) => BaseAlertDialog(
        title: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Text(
            t.amendCommit,
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
                    TextSpan(text: "${t.amendCommitMsg} "),
                    TextSpan(
                      text: "[${commitSha.substring(0, 7).toUpperCase()}]",
                      style: TextStyle(color: colours.tertiaryInfo),
                    ),
                    TextSpan(text: "."),
                  ],
                ),
              ),
              SizedBox(height: spaceSM),
              AiWandField(
                multiline: true,
                onPressed: () async {
                  final diff = await GitManager.getCommitDiff(commitSha, '$commitSha^');
                  final diffText = diff != null ? formatDiffParts(diff.diffParts) : '';
                  final prompt =
                      "Commit ${commitSha.substring(0, 7)}:\n"
                      "Current message: ${controller.text}\n\n"
                      "Changes (+${diff?.insertions ?? 0}/-${diff?.deletions ?? 0}):\n$diffText";
                  final result = await aiComplete(
                    systemPrompt:
                        "Improve this git commit message based on the actual changes. Use conventional commit format. Output only the improved message, nothing else.",
                    userPrompt: prompt,
                  );
                  if (result != null) controller.text = result.trim();
                },
                child: TextField(
                  controller: controller,
                  maxLines: 3,
                  style: TextStyle(color: colours.primaryLight, fontSize: textSM),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(cornerRadiusSM)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(cornerRadiusSM),
                      borderSide: BorderSide(color: colours.tertiaryDark),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(cornerRadiusSM),
                      borderSide: BorderSide(color: colours.tertiaryInfo),
                    ),
                  ),
                ),
              ),
              SizedBox(height: spaceSM),
              Text(
                t.amendCommitWarning,
                style: TextStyle(color: colours.tertiaryWarning, fontWeight: FontWeight.bold, fontSize: textSM),
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
              t.amend.toUpperCase(),
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
              if (controller.text.trim().isEmpty) return;
              loading = true;
              setState(() {});
              await callback(controller.text.trim());
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
