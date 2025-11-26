import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import '../../../constant/colors.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';

Future<void> showDialog(BuildContext context, int syncs, Future<void> Function() callback) {
  return mat.showDialog(
    context: context,
    builder: (BuildContext context) => BaseAlertDialog(
      title: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Text(
          "You've Done It!",
          style: TextStyle(color: primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
        ),
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            Text(
              "Your last $syncs syncs were a success! Thank you for being a user of GitSync.\n\nWe'd love to hear your thoughts! If you’re enjoying the app, could you take a moment to leave us a review?\nYour feedback helps us improve and grow.",
              style: const TextStyle(color: primaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(
            "Not Now".toUpperCase(),
            style: TextStyle(color: primaryLight, fontSize: textMD),
          ),
          onPressed: () {
            Navigator.of(context).canPop() ? Navigator.pop(context) : null;
          },
        ),
        TextButton(
          child: Text(
            "Leave Review".toUpperCase(),
            style: TextStyle(color: tertiaryPositive, fontSize: textMD),
          ),
          onPressed: () async {
            await callback();
            Navigator.of(context).canPop() ? Navigator.pop(context) : null;
          },
        ),
      ],
    ),
  );
}
