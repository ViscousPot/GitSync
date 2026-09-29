import 'dart:async';
import 'package:GitSync/api/logger.dart';
import 'package:GitSync/api/manager/git_manager.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';
import 'package:GitSync/global.dart';

Future<void> showDialog(BuildContext context, String repoUrl, String dir, Function(String?) callback, {int? depth, bool bare = false}) async {
  WakelockPlus.enable();
  String task = "";
  double progress = 0.0;
  StateSetter? setState;

  final taskSub = FlutterBackgroundService().on("cloneTaskCallback").listen((event) async {
    if (event == null) return;
    task = event["task"];
    if (context.mounted) setState?.call(() {});
  });
  final progressSub = FlutterBackgroundService().on("cloneProgressCallback").listen((event) async {
    if (event == null) return;
    progress = event["progress"] / 100.0;
    if (context.mounted) setState?.call(() {});
  });

  runGitOperation(LogType.Clone, (event) => event?["result"] as String?, {"repoUrl": repoUrl, "repoPath": dir, "depth": depth, "bare": bare}).then((
    result,
  ) {
    taskSub.cancel();
    progressSub.cancel();
    WakelockPlus.disable();
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    if (rootNavigator.canPop()) rootNavigator.pop();
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
            context.t.cloningRepository,
            style: TextStyle(color: context.colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
          ),
        ),
        content: StatefulBuilder(
          builder: (context, internalSetState) {
            setState = internalSetState;
            return SingleChildScrollView(
              child: ListBody(
                children: [
                  Text(
                    context.t.cloneMessagePart1,
                    style: TextStyle(color: context.colours.tertiaryNegative, fontWeight: FontWeight.bold, fontSize: textMD),
                  ),
                  Text(
                    context.t.cloneMessagePart2,
                    style: TextStyle(color: context.colours.primaryLight, fontSize: textMD),
                  ),
                  SizedBox(height: spaceMD),
                  Text(
                    task,
                    maxLines: 1,
                    style: TextStyle(color: context.colours.primaryLight, fontSize: textMD, overflow: TextOverflow.ellipsis),
                  ),
                  SizedBox(height: spaceMD),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: context.colours.secondaryLight,
                    color: context.colours.primaryPositive,
                    semanticsLabel: context.t.cloneProgressLabel,
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
}
