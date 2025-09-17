import 'package:GitSync/api/manager/git_manager.dart';
import 'package:GitSync/constant/strings.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../constant/colors.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';
import 'package:GitSync/global.dart';

final Map<String, Future<void> Function([int? repomanRepoindex])> autoFixCallbackMap = {
  invalidIndexHeaderError: GitManager.deleteGitIndex,
  invalidDataInIndexInvalidEntry: GitManager.deleteGitIndex,
  invalidDataInIndexExtensionIsTruncated: GitManager.deleteGitIndex,
  corruptedLooseFetchHead: GitManager.deleteFetchHead,
  theIndexIsLocked: GitManager.deleteGitIndex,
};
final GlobalKey errorDialogKey = GlobalKey();

Future<void> showDialog(BuildContext context, String error, Function() callback) {
  bool autoFixing = false;

  return mat.showDialog(
    context: context,
    builder: (BuildContext context) => BaseAlertDialog(
      key: errorDialogKey,
      title: SizedBox(
        child: Text(
          t.errorOccurredTitle,
          style: TextStyle(color: primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
        ),
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            Text(
              error,
              style: const TextStyle(color: tertiaryNegative, fontWeight: FontWeight.bold, fontSize: textSM),
            ),
            SizedBox(height: spaceMD),
            ...autoFixCallbackMap.containsKey(error.split(";")[0])
                ? [
                    // SizedBox(height: spaceSM),
                    StatefulBuilder(
                      builder: (context, setState) => TextButton.icon(
                        onPressed: () async {
                          autoFixing = true;
                          setState(() {});

                          // await Future.delayed(Duration(seconds: 1), () {});
                          await (autoFixCallbackMap[error] ?? () async {})();

                          autoFixing = false;
                          setState(() {});

                          Navigator.of(context).canPop() ? Navigator.pop(context) : null;
                        },
                        style: ButtonStyle(
                          alignment: Alignment.center,
                          backgroundColor: WidgetStatePropertyAll(secondaryDark),
                          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceMD)),
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(cornerRadiusMD),
                              side: BorderSide(color: primaryPositive, width: spaceXXXS),
                            ),
                          ),
                        ),
                        icon: autoFixing
                            ? SizedBox(
                                height: textSM,
                                width: textSM,
                                child: CircularProgressIndicator(color: primaryPositive),
                              )
                            : FaIcon(FontAwesomeIcons.bugSlash, color: primaryPositive, size: textLG),
                        label: Text(
                          t.attemptAutoFix.toUpperCase(),
                          style: TextStyle(color: primaryPositive, fontSize: textSM, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    SizedBox(height: spaceMD),
                  ]
                : [],
            Text(
              t.errorOccurredMessagePart1,
              style: const TextStyle(color: primaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
            ),
            SizedBox(height: spaceSM),
            Text(
              t.errorOccurredMessagePart2,
              style: const TextStyle(color: primaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(
            t.dismiss.toUpperCase(),
            style: TextStyle(color: primaryLight, fontSize: textMD),
          ),
          onPressed: () {
            Navigator.of(context).canPop() ? Navigator.pop(context) : null;
          },
        ),
        TextButton(
          child: Text(
            t.reportABug.toUpperCase(),
            style: TextStyle(color: tertiaryNegative, fontSize: textMD),
          ),
          onPressed: () async {
            callback();
            Navigator.of(context).canPop() ? Navigator.pop(context) : null;
          },
        ),
      ],
    ),
  );
}
