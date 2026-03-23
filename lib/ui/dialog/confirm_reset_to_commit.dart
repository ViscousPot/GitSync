import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';
import 'package:GitSync/global.dart';

Future<void> showDialog(BuildContext context, String commitSha, String commitMessage, Future<void> Function() callback) {
  bool loading = false;

  return mat.showDialog(
    context: context,
    builder: (BuildContext context) => StatefulBuilder(
      builder: (context, setState) => BaseAlertDialog(
        title: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Text(
            t.resetToCommit,
            style: TextStyle(color: colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
          ),
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(color: colours.primaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
                  children: [
                    TextSpan(text: "${t.resetToCommitMsg} "),
                    TextSpan(
                      text: "[${commitSha.substring(0, 7).toUpperCase()}]",
                      style: TextStyle(color: colours.tertiaryInfo),
                    ),
                    TextSpan(text: "."),
                  ],
                ),
              ),
              SizedBox(height: spaceXS),
              Text(
                commitMessage,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colours.secondaryLight, fontSize: textSM),
              ),
              SizedBox(height: spaceSM),
              Text(
                t.resetToCommitWarning,
                style: TextStyle(color: colours.primaryNegative, fontWeight: FontWeight.bold, fontSize: textSM),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(
              t.cancel.toUpperCase(),
              style: TextStyle(color: colours.primaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.of(context).canPop() ? Navigator.pop(context) : null;
            },
          ),
          TextButton.icon(
            label: Text(
              t.reset.toUpperCase(),
              style: TextStyle(color: colours.primaryNegative, fontSize: textMD, fontWeight: FontWeight.bold),
            ),
            iconAlignment: IconAlignment.end,
            icon: loading
                ? SizedBox(
                    height: spaceMD,
                    width: spaceMD,
                    child: CircularProgressIndicator(color: colours.primaryNegative),
                  )
                : SizedBox.shrink(),
            onPressed: () async {
              loading = true;
              setState(() {});
              await callback();
              loading = false;
              setState(() {});
              Navigator.of(context).canPop() ? Navigator.pop(context) : null;
            },
          ),
        ],
      ),
    ),
  );
}
