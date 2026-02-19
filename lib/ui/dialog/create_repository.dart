import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';
import 'package:GitSync/global.dart';

Future<void> showDialog(
  BuildContext context,
  VoidCallback onConfirm,
) async {
  return mat.showDialog(
    context: context,
    builder: (BuildContext context) => BaseAlertDialog(
      title: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Text(
          t.createNewRepository,
          style: TextStyle(color: colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
        ),
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            SizedBox(height: spaceMD),
            Text(
              t.noGitRepoFoundMsg,
              style: TextStyle(color: colours.primaryLight, fontSize: textMD),
            ),
            SizedBox(height: spaceMD),
            Text(
              t.remoteSetupLaterMsg,
              style: TextStyle(color: colours.tertiaryLight, fontSize: textSM),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(
            t.cancel.toUpperCase(),
            style: TextStyle(color: colours.primaryLight, fontSize: textMD),
          ),
          onPressed: () {
            Navigator.of(context).canPop() ? Navigator.pop(context) : null;
          },
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).canPop() ? Navigator.pop(context) : null;
            onConfirm();
          },
          child: Text(
            t.create.toUpperCase(),
            style: TextStyle(color: colours.primaryPositive, fontSize: textMD),
          ),
        ),
      ],
    ),
  );
}
