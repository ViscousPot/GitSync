import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';
import 'package:GitSync/global.dart';

Future<void> showDialog(BuildContext context, {push = false}) async {
  return mat.showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => PopScope(
      child: BaseAlertDialog(
        title: Row(
          mainAxisAlignment: mat.MainAxisAlignment.spaceBetween,
          children: [
            Text(
              push ? t.forcePushing : t.forcePulling,
              style: TextStyle(color: colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: textXL,
              width: textXL,
              child: Center(
                child: CircularProgressIndicator(
                  backgroundColor: colours.secondaryLight,
                  color: colours.primaryPositive,
                  semanticsLabel: push ? t.forcePushProgressLabel : t.forcePullProgressLabel,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Text(
                t.forcePushPullMessage,
                style: TextStyle(color: colours.tertiaryNegative, fontSize: textMD, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: spaceMD),
            ],
          ),
        ),
        actions: null,
      ),
    ),
  );
}
