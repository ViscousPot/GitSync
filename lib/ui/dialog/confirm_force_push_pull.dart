import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';
import 'package:GitSync/global.dart';

Future<void> showDialog(BuildContext context, Function() callback, {push = false}) {
  return mat.showDialog(
    context: context,
    builder: (BuildContext context) => BaseAlertDialog(
      title: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Text(
          push ? context.t.confirmForcePush : context.t.confirmForcePull,
          style: TextStyle(color: context.colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
        ),
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            Text(
              push ? context.t.confirmForcePushMsg : context.t.confirmForcePullMsg,
              style: TextStyle(color: context.colours.primaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
            ),
            SizedBox(height: spaceSM),
            Text(
              context.t.localHistoryOverwriteWarning,
              style: TextStyle(color: context.colours.tertiaryNegative, fontWeight: FontWeight.bold, fontSize: textSM),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(
            context.t.cancel.toUpperCase(),
            style: TextStyle(color: context.colours.primaryLight, fontSize: textMD),
          ),
          onPressed: () {
            Navigator.of(context).canPop() ? Navigator.pop(context) : null;
          },
        ),
        TextButton(
          child: Text(
            (push ? context.t.forcePush : context.t.forcePull).toUpperCase(),
            style: TextStyle(color: context.colours.primaryPositive, fontSize: textMD),
          ),
          onPressed: () async {
            Navigator.of(context).canPop() ? Navigator.pop(context) : null;
            callback();
          },
        ),
      ],
    ),
  );
}
