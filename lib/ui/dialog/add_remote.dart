import 'package:GitSync/api/helper.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';
import 'package:GitSync/global.dart';

Future<void> showDialog(
  BuildContext context,
  Future<void> Function(String name, String url) callback,
) async {
  final nameController = TextEditingController();
  final urlController = TextEditingController();

  return mat.showDialog(
    context: context,
    builder: (BuildContext context) => StatefulBuilder(
      builder: (context, setState) => BaseAlertDialog(
        title: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Text(
            t.addRemote,
            style: TextStyle(color: colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
          ),
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              SizedBox(height: spaceMD),
              TextField(
                contextMenuBuilder: globalContextMenuBuilder,
                controller: nameController,
                maxLines: 1,
                style: TextStyle(
                  color: colours.primaryLight,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                  decorationThickness: 0,
                  fontSize: textMD,
                ),
                decoration: InputDecoration(
                  fillColor: colours.secondaryDark,
                  filled: true,
                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(cornerRadiusSM), borderSide: BorderSide.none),
                  isCollapsed: true,
                  label: Text(
                    t.remoteName.toUpperCase(),
                    style: TextStyle(color: colours.secondaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  contentPadding: const EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
              SizedBox(height: spaceMD + spaceXS),
              TextField(
                contextMenuBuilder: globalContextMenuBuilder,
                controller: urlController,
                maxLines: 1,
                style: TextStyle(
                  color: colours.primaryLight,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                  decorationThickness: 0,
                  fontSize: textMD,
                ),
                decoration: InputDecoration(
                  fillColor: colours.secondaryDark,
                  filled: true,
                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(cornerRadiusSM), borderSide: BorderSide.none),
                  isCollapsed: true,
                  label: Text(
                    t.remoteUrl.toUpperCase(),
                    style: TextStyle(color: colours.secondaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  contentPadding: const EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
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
            onPressed: () {
              Navigator.of(context).canPop() ? Navigator.pop(context) : null;
            },
          ),
          TextButton(
            onPressed: (nameController.text.isNotEmpty && urlController.text.isNotEmpty)
                ? () async {
                    Navigator.of(context).canPop() ? Navigator.pop(context) : null;
                    await callback(nameController.text, urlController.text);
                  }
                : null,
            child: Text(
              t.add.toUpperCase(),
              style: TextStyle(
                color: (nameController.text.isNotEmpty && urlController.text.isNotEmpty) ? colours.primaryPositive : colours.secondaryPositive,
                fontSize: textMD,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
