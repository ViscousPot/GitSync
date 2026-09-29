import 'dart:io';

import 'package:GitSync/global.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import 'package:sprintf/sprintf.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';
import 'package:path/path.dart' as p;

Future<void> showDialog(BuildContext context, List<String> selectedPaths, Future<void> Function() callback) {
  final oldPath = selectedPaths[0];
  final entity = FileSystemEntity.typeSync(oldPath);
  if (entity == FileSystemEntityType.notFound) {
    throw Exception('Path does not exist.');
  }
  String text = sprintf(context.t.confirmFileDirDeleteMsg, [
    entity == FileSystemEntityType.directory ? context.t.directory.toLowerCase() : context.t.file.toLowerCase(),
    p.basename(oldPath),
    sprintf(selectedPaths.length > 1 ? context.t.deleteMultipleSuffix : context.t.deleteSingularSuffix, [selectedPaths.length - 1]),
  ]);

  return mat.showDialog(
    context: context,
    builder: (BuildContext context) => BaseAlertDialog(
      title: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Text(
          context.t.confirmFileDirDeleteTitle,
          style: TextStyle(color: context.colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
        ),
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            Text(
              text,
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
