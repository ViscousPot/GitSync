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
        backgroundColor: context.colours.secondaryDark,
        title: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Text(
            context.t.renameRemote.toUpperCase(),
            style: TextStyle(color: context.colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
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
                    context.t.remoteName.toUpperCase(),
                    style: TextStyle(color: context.colours.secondaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
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
              context.t.cancel.toUpperCase(),
              style: TextStyle(color: context.colours.primaryLight, fontSize: textMD),
            ),
            onPressed: () {
              Navigator.of(context).canPop() ? Navigator.pop(context) : null;
            },
          ),
          TextButton(
            onPressed: (nameController.text.trim().isNotEmpty && nameController.text.trim() != currentName)
                ? () async {
                    Navigator.of(context).canPop() ? Navigator.pop(context) : null;
                    await callback(nameController.text.trim());
                  }
                : null,
            child: Text(
              context.t.rename.toUpperCase(),
              style: TextStyle(
                color: (nameController.text.trim().isNotEmpty && nameController.text.trim() != currentName)
                    ? context.colours.primaryPositive
                    : context.colours.secondaryPositive,
                fontSize: textMD,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
