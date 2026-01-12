import 'package:GitSync/global.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';

Future<void> showDialog(BuildContext context, String title, String info, [Widget? extra]) {
  return mat.showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) => BaseAlertDialog(
      backgroundColor: colours.secondaryDark,
      title: Row(
        children: [
          FaIcon(FontAwesomeIcons.circleInfo, color: colours.secondaryLight, size: textMD),
          SizedBox(width: spaceXS),
          Text(
            title,
            style: TextStyle(
              color: colours.secondaryLight,
              fontFeatures: [FontFeature.enable('smcp')],
              fontSize: textMD,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            Text(
              info,
              style: TextStyle(color: colours.primaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
            ),
            extra ?? SizedBox.shrink(),
          ],
        ),
      ),
    ),
  );
}
