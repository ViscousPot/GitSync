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
              push ? context.t.forcePushing : context.t.forcePulling,
              style: TextStyle(color: context.colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: textXL,
              width: textXL,
              child: Center(
                child: CircularProgressIndicator(
                  backgroundColor: context.colours.secondaryLight,
                  color: context.colours.primaryPositive,
                  semanticsLabel: push ? context.t.forcePushProgressLabel : context.t.forcePullProgressLabel,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Text(
                context.t.forcePushPullMessage,
                style: TextStyle(color: context.colours.tertiaryNegative, fontSize: textMD, fontWeight: FontWeight.bold),
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
