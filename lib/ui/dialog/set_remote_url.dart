import 'package:GitSync/api/helper.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import 'package:GitSync/global.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';

Future<void> showDialog(BuildContext context, String? oldRemoteUrl, Future<void> Function(String newRemoteUrl) callback) async {
  final newRemoteController = TextEditingController(text: oldRemoteUrl);

  // TODO: Dialog doesn't open without this (investigate)
  await Future.delayed(Duration(milliseconds: 500));

  return await mat.showDialog(
    context: context,
    builder: (BuildContext context) => BaseAlertDialog(
      expandable: false,
      backgroundColor: context.colours.secondaryDark,
      title: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Text(
          context.t.setRemoteUrl.toUpperCase(),
          style: TextStyle(color: context.colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
        ),
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            SizedBox(height: spaceMD),
            TextField(
              contextMenuBuilder: globalContextMenuBuilder,
              controller: newRemoteController,
              maxLines: 1,
              style: TextStyle(
                color: context.colours.primaryLight,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
                decorationThickness: 0,
                fontSize: textMD,
              ),
              decoration: InputDecoration(
                fillColor: context.colours.tertiaryDark,
                filled: true,
                border: const OutlineInputBorder(borderRadius: BorderRadius.all(cornerRadiusSM), borderSide: BorderSide.none),
                isCollapsed: true,
                label: Text(
                  context.t.remoteUrl.toUpperCase(),
                  style: TextStyle(color: context.colours.secondaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                ),
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
            context.t.modify.toUpperCase(),
            style: TextStyle(color: context.colours.primaryPositive, fontSize: textMD),
          ),
          onPressed: () async {
            callback(newRemoteController.text);
            Navigator.of(context).canPop() ? Navigator.pop(context) : null;
          },
        ),
      ],
    ),
  );
}
