import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';
import 'package:GitSync/global.dart';

Future<void> showDialog(BuildContext context, Future<void> Function() collectOauth) {
  return mat.showDialog(
    context: context,
    builder: (BuildContext context) => BaseAlertDialog(
      backgroundColor: colours.secondaryDark,
      title: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Text(
          t.githubIssueOauthTitle,
          style: TextStyle(color: colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
        ),
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            Text(
              t.githubIssueOauthMsg,
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
          onPressed: () async {
            Navigator.of(context).canPop() ? Navigator.pop(context) : null;
          },
        ),
        TextButton.icon(
          icon: FaIcon(FontAwesomeIcons.squareArrowUpRight, color: colours.secondaryDark, size: textMD),
          label: Text(
            t.oauth.toUpperCase(),
            style: TextStyle(color: colours.secondaryDark, fontSize: textMD, fontWeight: FontWeight.bold),
          ),
          style: ButtonStyle(
            alignment: Alignment.center,
            backgroundColor: WidgetStatePropertyAll(colours.primaryPositive),
            padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceXS)),
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none)),
          ),
          onPressed: () async {
            await collectOauth();
            Navigator.of(context).canPop() ? Navigator.pop(context) : null;
          },
        ),
      ],
    ),
  );
}
