import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import '../../../constant/colors.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';
import 'package:GitSync/global.dart';

Future<void> showDialog(BuildContext context, Future<void> Function() deleteContentsCallback, Future<void> Function() cloneCallback) {
  bool overwriting = false;

  return mat.showDialog(
    context: context,
    builder: (BuildContext context) => PopScope(
      canPop: !overwriting,
      child: BaseAlertDialog(
        title: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Text(
            t.confirmCloneOverwriteTitle,
            style: TextStyle(color: primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
          ),
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Text(
                t.confirmCloneOverwriteMsg,
                style: const TextStyle(color: primaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
              ),
              SizedBox(height: spaceSM),
              Text(
                t.confirmCloneOverwriteWarning,
                style: const TextStyle(color: tertiaryNegative, fontWeight: FontWeight.bold, fontSize: textSM),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          StatefulBuilder(
            builder: (context, setState) => TextButton.icon(
              label: Text(
                t.confirmCloneOverwriteAction.toUpperCase(),
                style: TextStyle(color: tertiaryNegative, fontSize: textMD),
              ),
              iconAlignment: IconAlignment.start,
              icon: overwriting
                  ? SizedBox(
                      height: spaceMD,
                      width: spaceMD,
                      child: CircularProgressIndicator(color: tertiaryNegative),
                    )
                  : SizedBox.shrink(),
              onPressed: () async {
                overwriting = true;
                setState(() {});
                await deleteContentsCallback();
                overwriting = false;
                setState(() {});

                Navigator.of(context).canPop() ? Navigator.pop(context) : null;
                await cloneCallback();
              },
            ),
          ),
          TextButton(
            child: Text(
              t.cancel.toUpperCase(),
              style: TextStyle(color: primaryLight, fontSize: textMD),
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
