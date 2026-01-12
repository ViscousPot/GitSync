import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import 'package:GitSync/global.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sprintf/sprintf.dart';
import 'package:GitSync/api/manager/storage.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';

import 'confirm_remove_container.dart' as ConfirmRemoveContainer;

Future<void> showDialog(BuildContext context, Function(bool deleteContents) callback) async {
  final containerName = await repoManager.getRepoName(await repoManager.getInt(StorageKey.repoman_repoIndex));
  bool deleteContents = false;

  return mat.showDialog(
    context: context,
    builder: (BuildContext context) => BaseAlertDialog(
      title: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Text(
          t.confirmRepositoryDelete,
          style: TextStyle(color: colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
        ),
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            Text(
              sprintf(t.confirmRepositoryDeleteMsg, [containerName]),
              style: TextStyle(color: colours.primaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
            ),
            SizedBox(height: spaceSM),
            StatefulBuilder(
              builder: (context, setState) => TextButton.icon(
                onPressed: () async {
                  deleteContents = !deleteContents;
                  setState(() {});
                },
                style: ButtonStyle(shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM)))),
                label: Padding(
                  padding: EdgeInsets.only(left: spaceSM),
                  child: Text(
                    t.deleteRepoDirectoryCheckbox,
                    style: TextStyle(color: colours.primaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                  ),
                ),
                iconAlignment: IconAlignment.start,
                icon: FaIcon(
                  deleteContents ? FontAwesomeIcons.solidSquareCheck : FontAwesomeIcons.squareCheck,
                  color: colours.primaryPositive,
                  size: textLG,
                ),
              ),
            ),
            SizedBox(height: spaceSM),
            Text(
              t.thisActionCannotBeUndone,
              style: TextStyle(color: colours.primaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(
            t.confirm.toUpperCase(),
            style: TextStyle(color: colours.primaryLight, fontSize: textMD),
          ),
          onPressed: () async {
            if (deleteContents) {
              await ConfirmRemoveContainer.showDialog(context, containerName, () async {
                callback(true);
                Navigator.of(context).canPop() ? Navigator.pop(context) : null;
              });
              return;
            }

            callback(false);
            Navigator.of(context).canPop() ? Navigator.pop(context) : null;
          },
        ),
        TextButton(
          child: Text(
            t.cancel.toUpperCase(),
            style: TextStyle(color: colours.primaryPositive, fontSize: textMD),
          ),
          onPressed: () async {
            Navigator.of(context).canPop() ? Navigator.pop(context) : null;
          },
        ),
      ],
    ),
  );
}
