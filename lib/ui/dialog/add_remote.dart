import 'package:GitSync/api/helper.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';
import 'package:GitSync/global.dart';
import 'package:sprintf/sprintf.dart';

Future<void> showDialog(
  BuildContext context,
  Future<void> Function(String name, String url) callback, {
  String? oauthProviderName,
  Future<void> Function()? onCreateRemote,
}) async {
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
              if (oauthProviderName != null && onCreateRemote != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () async {
                      Navigator.of(context).canPop() ? Navigator.pop(context) : null;
                      await onCreateRemote();
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(colours.tertiaryInfo),
                      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM)),
                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD))),
                    ),
                    child: Text(
                      sprintf(t.createOnProvider, [oauthProviderName.toUpperCase()]).toUpperCase(),
                      style: TextStyle(color: colours.primaryDark, fontSize: textMD, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(height: spaceMD),
                Row(
                  children: [
                    Expanded(child: Container(height: 1, color: colours.tertiaryDark)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: spaceSM),
                      child: Text(
                        t.orEnterManually.toUpperCase(),
                        style: TextStyle(color: colours.secondaryLight, fontSize: textXS, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(child: Container(height: 1, color: colours.tertiaryDark)),
                  ],
                ),
              ],
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
            onPressed: (nameController.text.trim().isNotEmpty && urlController.text.trim().isNotEmpty)
                ? () async {
                    Navigator.of(context).canPop() ? Navigator.pop(context) : null;
                    await callback(nameController.text.trim(), urlController.text.trim());
                  }
                : null,
            child: Text(
              t.add.toUpperCase(),
              style: TextStyle(
                color: (nameController.text.trim().isNotEmpty && urlController.text.trim().isNotEmpty)
                    ? colours.primaryPositive
                    : colours.secondaryPositive,
                fontSize: textMD,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
