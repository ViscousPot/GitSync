import 'package:GitSync/api/manager/git_manager.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';
import 'package:GitSync/global.dart';

Future<void> showDialog(BuildContext context) {
  bool clearing = false;

  return mat.showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) => StatefulBuilder(
      builder: (context, setState) => PopScope(
        canPop: !clearing,
        child: BaseAlertDialog(
          title: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Text(
              t.crashQueueClearTitle,
              style: TextStyle(color: colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              t.crashQueueClearMsg,
              style: TextStyle(color: colours.primaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
            ),
          ),
          actions: <Widget>[
            TextButton.icon(
              label: Text(
                t.crashQueueClearAction.toUpperCase(),
                style: TextStyle(color: colours.primaryPositive, fontSize: textMD),
              ),
              iconAlignment: IconAlignment.start,
              icon: clearing
                  ? SizedBox(
                      height: spaceMD,
                      width: spaceMD,
                      child: CircularProgressIndicator(color: colours.primaryPositive),
                    )
                  : SizedBox.shrink(),
              onPressed: () async {
                clearing = true;
                setState(() {});
                await GitManager.clearLocks();
                clearing = false;
                setState(() {});

                Navigator.of(context).canPop() ? Navigator.pop(context) : null;
              },
            ),
            TextButton(
              child: Text(
                t.dismiss.toUpperCase(),
                style: TextStyle(color: colours.primaryLight, fontSize: textMD),
              ),
              onPressed: clearing
                  ? null
                  : () {
                      Navigator.of(context).canPop() ? Navigator.pop(context) : null;
                    },
            ),
          ],
        ),
      ),
    ),
  );
}
