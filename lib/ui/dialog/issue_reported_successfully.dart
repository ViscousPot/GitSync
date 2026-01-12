import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';
import 'package:GitSync/global.dart';

Future<void> showDialog(BuildContext context, String issueUrl) {
  return mat.showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => BaseAlertDialog(
      title: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Text(
          t.issueReportSuccessTitle,
          style: TextStyle(color: colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
        ),
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            Text(
              t.issueReportSuccessMsg,
              style: TextStyle(color: colours.primaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(
            t.trackIssue.toUpperCase(),
            style: TextStyle(color: colours.primaryPositive, fontSize: textMD),
          ),
          onPressed: () async {
            Navigator.of(context).canPop() ? Navigator.pop(context) : null;
            await launchUrl(Uri.parse(issueUrl));
          },
        ),
      ],
    ),
  );
}
