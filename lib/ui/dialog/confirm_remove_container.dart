import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import 'package:sprintf/sprintf.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';
import 'package:GitSync/global.dart';

Future<void> showDialog(BuildContext context, String containerName, Future<void> Function() callback) {
  return mat.showDialog(
    context: context,
    builder: (BuildContext context) => BaseAlertDialog(
      title: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Text(
          context.t.confirmRepositoryDeleteTitle,
          style: TextStyle(color: context.colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
        ),
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            Text(
              sprintf(context.t.confirmRepositoryDeleteMessage, [containerName]),
              style: TextStyle(color: context.colours.primaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
            ),
            SizedBox(height: spaceMD),
            Text(
              context.t.thisActionCannotBeUndone,
              style: TextStyle(color: context.colours.primaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
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
            context.t.delete.toUpperCase(),
            style: TextStyle(color: context.colours.tertiaryNegative, fontSize: textMD),
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
