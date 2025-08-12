import 'package:GitSync/global.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import '../../../constant/colors.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Future<void> showDialog(BuildContext context, Function(String text) callback) {
  final textController = TextEditingController();
  return mat.showDialog(
    context: context,
    builder:
        (BuildContext context) => BaseAlertDialog(
          backgroundColor: secondaryDark,
          title: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Text(t.createAFile, style: TextStyle(color: primaryLight, fontSize: textXL, fontWeight: FontWeight.bold)),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                SizedBox(height: spaceMD),
                TextField(
                  controller: textController,
                  maxLines: 1,
                  style: TextStyle(
                    color: primaryLight,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                    decorationThickness: 0,
                    fontSize: textMD,
                  ),
                  decoration: InputDecoration(
                    fillColor: tertiaryDark,
                    filled: true,
                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(cornerRadiusSM), borderSide: BorderSide.none),
                    isCollapsed: true,
                    label: Text(t.fileName.toUpperCase(), style: TextStyle(color: secondaryLight, fontSize: textSM, fontWeight: FontWeight.bold)),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    contentPadding: const EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context).cancel.toUpperCase(), style: TextStyle(color: primaryLight, fontSize: textMD)),
              onPressed: () {
                Navigator.of(context).canPop() ? Navigator.pop(context) : null;
              },
            ),
            TextButton(
              child: Text(AppLocalizations.of(context).create.toUpperCase(), style: TextStyle(color: primaryPositive, fontSize: textMD)),
              onPressed: () async {
                callback(textController.text);
                Navigator.of(context).canPop() ? Navigator.pop(context) : null;
              },
            ),
          ],
        ),
  );
}
