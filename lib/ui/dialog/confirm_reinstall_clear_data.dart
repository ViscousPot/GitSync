import 'package:GitSync/ui/dialog/confirm_clear_data.dart' as ConfirmClearDataDialog;
import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';
import 'package:GitSync/global.dart';

Future<void> showDialog(BuildContext context, Future<void> Function() deleteContentsCallback) {
  bool overwriting = false;

  return mat.showDialog(
    context: context,
    builder: (BuildContext context) => PopScope(
      canPop: !overwriting,
      child: BaseAlertDialog(
        title: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Text(
            context.t.iosClearDataTitle,
            style: TextStyle(color: context.colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
          ),
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Text(
                context.t.iosClearDataMsg,
                style: TextStyle(color: context.colours.primaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
              ),
              SizedBox(height: spaceSM),
              Text(
                context.t.confirmCloneOverwriteWarning,
                style: TextStyle(color: context.colours.tertiaryNegative, fontWeight: FontWeight.bold, fontSize: textSM),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          StatefulBuilder(
            builder: (context, setState) => TextButton.icon(
              label: Text(
                context.t.iosClearDataAction.toUpperCase(),
                style: TextStyle(color: context.colours.tertiaryNegative, fontSize: textMD),
              ),
              iconAlignment: IconAlignment.start,
              icon: overwriting
                  ? SizedBox(
                      height: spaceMD,
                      width: spaceMD,
                      child: CircularProgressIndicator(color: context.colours.tertiaryNegative),
                    )
                  : SizedBox.shrink(),
              onPressed: () async {
                await ConfirmClearDataDialog.showDialog(context, () async {
                  overwriting = true;
                  setState(() {});
                  await deleteContentsCallback();
                  overwriting = false;
                  setState(() {});

                  Navigator.of(context).canPop() ? Navigator.pop(context) : null;
                });
              },
            ),
          ),
          TextButton(
            child: Text(
              context.t.skip.toUpperCase(),
              style: TextStyle(color: context.colours.primaryLight, fontSize: textMD),
            ),
            onPressed: () {
              Navigator.of(context).canPop() ? Navigator.pop(context) : null;
            },
          ),
        ],
      ),
    ),
  );
}
