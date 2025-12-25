import 'package:GitSync/api/helper.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import '../../../constant/colors.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';
import 'package:GitSync/global.dart';

Future<void> showDialog(BuildContext context, Function(String text) callback) {
  final textController = TextEditingController();
  return mat.showDialog(
    context: context,
    builder: (BuildContext context) => BaseAlertDialog(
      backgroundColor: secondaryDark,
      title: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Text(
          t.enterPAT,
          style: TextStyle(color: primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
        ),
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            TextField(
              contextMenuBuilder: globalContextMenuBuilder,
              controller: textController,
              maxLines: 1,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
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
                contentPadding: const EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(
            t.cancel.toUpperCase(),
            style: TextStyle(color: primaryLight, fontSize: textMD),
          ),
          onPressed: () {
            Navigator.of(context).canPop() ? Navigator.pop(context) : null;
          },
        ),
        TextButton(
          child: Text(
            t.confirm.toUpperCase(),
            style: TextStyle(color: primaryPositive, fontSize: textMD),
          ),
          onPressed: () async {
            callback(textController.text);
            Navigator.of(context).canPop() ? Navigator.pop(context) : null;
          },
        ),
      ],
    ),
  );
}
