import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/api/issue_duplicate_finder.dart';

Future<bool> showDialog(BuildContext context, DuplicateIssue duplicate) async {
  final proceed = await mat.showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => BaseAlertDialog(
      title: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Text(
          context.t.issueDuplicateTitle,
          style: TextStyle(color: context.colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
        ),
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            Text(
              context.t.issueDuplicateMsg,
              style: TextStyle(color: context.colours.primaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
            ),
            SizedBox(height: spaceMD),
            Text(
              '#${duplicate.number}',
              style: TextStyle(color: context.colours.secondaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
            ),
            Text(
              duplicate.title,
              style: TextStyle(color: context.colours.primaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(
            context.t.viewIssue.toUpperCase(),
            style: TextStyle(color: context.colours.primaryLight, fontSize: textMD),
          ),
          onPressed: () async {
            Navigator.of(context).canPop() ? Navigator.pop(context, false) : null;
            await launchUrl(Uri.parse(duplicate.htmlUrl));
          },
        ),

        TextButton(
          child: Text(
            context.t.sendMessage.toUpperCase(),
            style: TextStyle(color: context.colours.primaryPositive, fontSize: textMD),
          ),
          onPressed: () => Navigator.of(context).canPop() ? Navigator.pop(context, true) : null,
        ),
      ],
    ),
  );

  return proceed ?? false;
}
