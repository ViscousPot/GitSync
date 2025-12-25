import 'package:GitSync/api/manager/auth/github_manager.dart';
import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/global.dart';
import 'package:flutter/material.dart' as mat;
import 'package:GitSync/constant/colors.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/ui/dialog/base_alert_dialog.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'enter_gh_sponsor_pat.dart' as EnterGhSponsorPatDialog;

Future<void> showDialog(BuildContext context) async {
  return mat.showDialog(
    context: context,
    builder: (BuildContext context) => BaseAlertDialog(
      title: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Text(
          t.verifyGhSponsorTitle,
          style: TextStyle(color: primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
        ),
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            Text(
              t.verifyGhSponsorMsg,
              style: TextStyle(color: primaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
            ),
            SizedBox(height: spaceSM),
            Text(
              t.verifyGhSponsorNote,
              style: TextStyle(color: tertiaryInfo, fontWeight: FontWeight.bold, fontSize: textSM),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(vertical: spaceMD),
          child: TextButton.icon(
            onPressed: () async {
              final result = await GithubManager().launchOAuthFlow(["user", "user:email"]);
              if (result == null) return;

              await repoManager.setStringNullable(StorageKey.repoman_ghSponsorToken, result.$3);
              await premiumManager.updateGitHubSponsorPremium();
              if (context.mounted) Navigator.of(context).canPop() ? Navigator.pop(context) : null;
            },
            style: ButtonStyle(
              alignment: Alignment.center,
              backgroundColor: WidgetStatePropertyAll(primaryPositive),
              padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM)),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none)),
            ),
            icon: FaIcon(FontAwesomeIcons.squareArrowUpRight, color: secondaryDark, size: textLG),
            label: Text(
              t.oauth.toUpperCase(),
              style: TextStyle(color: secondaryDark, fontSize: textSM, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: spaceMD),
          child: TextButton.icon(
            onPressed: () async {
              EnterGhSponsorPatDialog.showDialog(context, (text) async {
                if (text.isEmpty) return;
                await repoManager.setStringNullable(StorageKey.repoman_ghSponsorToken, text);
                await premiumManager.updateGitHubSponsorPremium();
                if (premiumManager.hasPremiumNotifier.value == false) {
                  Fluttertoast.showToast(msg: "User does not have Premium", toastLength: Toast.LENGTH_SHORT, gravity: null);
                }
                if (context.mounted) Navigator.of(context).canPop() ? Navigator.pop(context) : null;
              });
            },
            style: ButtonStyle(
              alignment: Alignment.center,
              backgroundColor: WidgetStatePropertyAll(tertiaryLight),
              padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM)),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none)),
            ),
            icon: FaIcon(FontAwesomeIcons.qrcode, color: secondaryDark, size: textLG),
            label: Text(
              t.usePAT.toUpperCase(),
              style: TextStyle(color: secondaryDark, fontSize: textSM, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    ),
  );
}
