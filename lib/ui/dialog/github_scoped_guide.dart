import 'package:GitSync/global.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';

Future<bool> showLoginGuide(BuildContext context) async {
  final result = await mat.showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => BaseAlertDialog(
      backgroundColor: context.colours.secondaryDark,
      title: Row(
        children: [
          FaIcon(FontAwesomeIcons.circleInfo, color: context.colours.secondaryLight, size: textMD),
          SizedBox(width: spaceXS),
          Expanded(
            child: Text(
              context.t.githubScopedLoginTitle,
              style: TextStyle(
                color: context.colours.secondaryLight,
                fontFeatures: [FontFeature.enable('smcp')],
                fontSize: textMD,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            Text(
              context.t.githubScopedLoginMsg,
              style: TextStyle(color: context.colours.primaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton.icon(
          icon: FaIcon(FontAwesomeIcons.squareArrowUpRight, color: context.colours.secondaryDark, size: textMD),
          label: Text(
            context.t.continueLabel.toUpperCase(),
            style: TextStyle(color: context.colours.secondaryDark, fontSize: textMD, fontWeight: FontWeight.bold),
          ),
          style: ButtonStyle(
            alignment: Alignment.center,
            backgroundColor: WidgetStatePropertyAll(context.colours.primaryPositive),
            padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceXS)),
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none)),
          ),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<bool> showRepoSelectionGuide(BuildContext context) async {
  final result = await mat.showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => BaseAlertDialog(
      backgroundColor: context.colours.secondaryDark,
      title: Row(
        children: [
          FaIcon(FontAwesomeIcons.circleInfo, color: context.colours.secondaryLight, size: textMD),
          SizedBox(width: spaceXS),
          Expanded(
            child: Text(
              context.t.githubScopedRepoTitle,
              style: TextStyle(
                color: context.colours.secondaryLight,
                fontFeatures: [FontFeature.enable('smcp')],
                fontSize: textMD,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            Text(
              context.t.githubScopedRepoMsg,
              style: TextStyle(color: context.colours.primaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton.icon(
          icon: FaIcon(FontAwesomeIcons.squareArrowUpRight, color: context.colours.secondaryDark, size: textMD),
          label: Text(
            context.t.continueLabel.toUpperCase(),
            style: TextStyle(color: context.colours.secondaryDark, fontSize: textMD, fontWeight: FontWeight.bold),
          ),
          style: ButtonStyle(
            alignment: Alignment.center,
            backgroundColor: WidgetStatePropertyAll(context.colours.primaryPositive),
            padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceXS)),
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none)),
          ),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
        ),
      ],
    ),
  );
  return result ?? false;
}
