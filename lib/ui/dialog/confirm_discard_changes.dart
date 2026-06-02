import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import 'package:sprintf/sprintf.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';
import 'package:GitSync/global.dart';

Future<void> showDialog(BuildContext context, List<String> selectedFiles, Future<void> Function() callback) {
  return mat.showDialog(
    context: context,
    builder: (BuildContext context) {
      final loading = ValueNotifier<bool>(false);
      return BaseAlertDialog(
        title: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Text(
            t.discardChangesTitle,
            style: TextStyle(color: colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
          ),
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Text(
                selectedFiles.length == 1
                    ? sprintf(t.discardChangesMsg, [selectedFiles[0]])
                    : sprintf(t.discardChangesMsg, [""]).replaceAll("\"\"?", "\n\n${selectedFiles.map((file) => " $file").join("\n")}"),
                style: TextStyle(color: colours.primaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
              ),
              SizedBox(height: spaceMD),
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
              t.cancel.toUpperCase(),
              style: TextStyle(color: colours.primaryLight, fontSize: textMD),
            ),
            onPressed: () {
              Navigator.of(context).canPop() ? Navigator.pop(context) : null;
            },
          ),
          ListenableBuilder(
            listenable: loading,
            builder: (context, _) => TextButton.icon(
              onPressed: loading.value
                  ? null
                  : () async {
                      loading.value = true;
                      await callback();
                      Navigator.of(context).canPop() ? Navigator.pop(context) : null;
                    },
              style: ButtonStyle(
                alignment: Alignment.center,
                padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM)),
                shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM), side: BorderSide.none)),
              ),
              icon: loading.value
                  ? Container(
                      height: textSM,
                      width: textSM,
                      margin: EdgeInsets.only(right: spaceXXXS),
                      child: CircularProgressIndicator(color: colours.tertiaryNegative),
                    )
                  : null,
              label: Text(
                t.discardChanges.toUpperCase(),
                style: TextStyle(color: colours.tertiaryNegative, fontSize: textMD),
              ),
            ),
          ),
        ],
      );
    },
  );
}
