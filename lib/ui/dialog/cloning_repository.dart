import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import '../../../api/manager/git_manager.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';
import 'package:GitSync/global.dart';

Future<void> showDialog(BuildContext context, String repoUrl, String dir, Function(String?) callback) async {
  String task = "";
  double progress = 0.0;
  StateSetter? setState;

  GitManager.clone(
    repoUrl,
    dir,
    (newTask) {
      task = newTask;
      setState?.call(() {});
    },
    (newProgress) {
      progress = newProgress / 100.0;
      setState?.call(() {});
    },
  ).then((result) {
    Navigator.of(context).canPop() ? Navigator.pop(context) : null;
    callback(result);
  });

  return mat.showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => PopScope(
      canPop: false,
      child: BaseAlertDialog(
        title: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Text(
            t.cloningRepository,
            style: TextStyle(color: colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
          ),
        ),
        content: StatefulBuilder(
          builder: (context, internalSetState) {
            setState = internalSetState;
            return SingleChildScrollView(
              child: ListBody(
                children: [
                  Text(
                    t.cloneMessagePart1,
                    style: TextStyle(color: colours.tertiaryNegative, fontWeight: FontWeight.bold, fontSize: textMD),
                  ),
                  Text(
                    t.cloneMessagePart2,
                    style: TextStyle(color: colours.primaryLight, fontSize: textMD),
                  ),
                  SizedBox(height: spaceMD),
                  Text(
                    task,
                    maxLines: 1,
                    style: TextStyle(color: colours.primaryLight, fontSize: textMD, overflow: TextOverflow.ellipsis),
                  ),
                  SizedBox(height: spaceMD),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: colours.secondaryLight,
                    color: colours.primaryPositive,
                    semanticsLabel: t.cloneProgressLabel,
                  ),
                ],
              ),
            );
          },
        ),
        actions: null,
      ),
    ),
  );

  // return (setTask, setProgress);
}
