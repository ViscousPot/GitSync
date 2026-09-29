import 'package:GitSync/api/helper.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';
import 'package:GitSync/global.dart';
import 'package:sprintf/sprintf.dart';

Future<void> showDialog(BuildContext context, String commitSha, Future<void> Function(String branchName) callback) async {
  final textController = TextEditingController();

  return mat.showDialog(
    context: context,
    builder: (BuildContext context) => StatefulBuilder(
      builder: (context, setState) => BaseAlertDialog(
        title: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Text(
            context.t.createBranchFromCommit,
            style: TextStyle(color: context.colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
          ),
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Text(
                sprintf(context.t.createBranchFromCommitMsg, [commitSha.substring(0, 7).toUpperCase()]),
                style: TextStyle(color: context.colours.secondaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
              ),
              SizedBox(height: spaceMD),
              TextField(
                contextMenuBuilder: globalContextMenuBuilder,
                controller: textController,
                maxLines: 1,
                style: TextStyle(
                  color: context.colours.primaryLight,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                  decorationThickness: 0,
                  fontSize: textMD,
                ),
                decoration: InputDecoration(
                  fillColor: context.colours.secondaryDark,
                  filled: true,
                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(cornerRadiusSM), borderSide: BorderSide.none),
                  isCollapsed: true,
                  label: Text(
                    context.t.createBranchName.toUpperCase(),
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
            onPressed: textController.text.isNotEmpty
                ? () async {
                    Navigator.of(context).canPop() ? Navigator.pop(context) : null;
                    await callback(textController.text);
                  }
                : null,
            child: Text(
              context.t.create.toUpperCase(),
              style: TextStyle(
                color: textController.text.isNotEmpty ? context.colours.primaryPositive : context.colours.secondaryPositive,
                fontSize: textMD,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
