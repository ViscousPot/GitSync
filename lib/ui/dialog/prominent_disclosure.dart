import 'dart:io';

import 'package:GitSync/global.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';

Future<void> showDialog(BuildContext context, Future<void> Function() callback) {
  if (Platform.isIOS) return Future.value();

  return mat.showDialog(
    context: context,
    builder: (BuildContext context) => BaseAlertDialog(
      title: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Text(
          t.accessibilityServiceDisclosureTitle,
          style: TextStyle(color: colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
        ),
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            Text(
              t.accessibilityServiceDisclosureMessage,
              style: TextStyle(color: colours.primaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
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
          child: Text(
            t.ok.toUpperCase(),
            style: TextStyle(color: colours.primaryPositive, fontSize: textMD),
          ),
          onPressed: () async {
            Navigator.of(context).canPop() ? Navigator.pop(context) : null;
            await callback();
          },
        ),
      ],
    ),
  );
}
