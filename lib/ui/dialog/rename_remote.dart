import 'package:GitSync/api/helper.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import 'package:GitSync/global.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';

Future<void> showDialog(BuildContext context, String currentName, Future<void> Function(String newName) callback) async {
  final nameController = TextEditingController(text: currentName);

  return await mat.showDialog(
    context: context,
    builder: (BuildContext context) => StatefulBuilder(
      builder: (context, setState) => BaseAlertDialog(
        expandable: false,
        backgroundColor: colours.secondaryDark,
        title: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Text(
            t.renameRemote.toUpperCase(),
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
                  fillColor: colours.tertiaryDark,
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
            onPressed: (nameController.text.isNotEmpty && nameController.text != currentName)
                ? () async {
                    Navigator.of(context).canPop() ? Navigator.pop(context) : null;
                    await callback(nameController.text);
                  }
                : null,
            child: Text(
              t.rename.toUpperCase(),
              style: TextStyle(
                color: (nameController.text.isNotEmpty && nameController.text != currentName) ? colours.primaryPositive : colours.secondaryPositive,
                fontSize: textMD,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
