import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';
import 'package:GitSync/global.dart';

Future<void> showDialog(BuildContext context, String branchName, Future<void> Function() callback) {
  bool loading = false;

  return mat.showDialog(
    context: context,
    builder: (BuildContext context) => StatefulBuilder(
      builder: (context, setState) => BaseAlertDialog(
        title: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Text(
            context.t.confirmBranchCheckoutTitle,
            style: TextStyle(color: context.colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
          ),
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(color: context.colours.primaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
                  children: [
                    TextSpan(text: context.t.confirmBranchCheckoutMsgPart1),
                    TextSpan(
                      text: "[$branchName]",
                      style: TextStyle(color: context.colours.tertiaryInfo),
                    ),
                    TextSpan(text: context.t.confirmBranchCheckoutMsgPart2),
                  ],
                ),
              ),
              SizedBox(height: spaceSM),
              Text(
                context.t.unsavedChangesMayBeLost,
                style: TextStyle(color: context.colours.tertiaryNegative, fontWeight: FontWeight.bold, fontSize: textSM),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(
              context.t.cancel.toUpperCase(),
              style: TextStyle(color: context.colours.primaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.of(context).canPop() ? Navigator.pop(context) : null;
            },
          ),
          TextButton.icon(
            label: Text(
              context.t.checkout.toUpperCase(),
              style: TextStyle(color: context.colours.primaryPositive, fontSize: textMD, fontWeight: FontWeight.bold),
            ),
            iconAlignment: IconAlignment.end,
            icon: loading
                ? SizedBox(
                    height: spaceMD,
                    width: spaceMD,
                    child: CircularProgressIndicator(color: context.colours.primaryPositive),
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
