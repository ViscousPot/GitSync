import 'package:GitSync/api/manager/git_manager.dart';
import 'package:GitSync/constant/strings.dart';
import 'package:GitSync/ui/page/settings_main.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../constant/colors.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';
import 'package:GitSync/global.dart';

final Map<List<String>, (String?, Future<void> Function([int? repomanRepoindex])?)> autoFixMessageCallbackMap = {
  [invalidIndexHeaderError]: (null, GitManager.deleteGitIndex),
  [invalidDataInIndexInvalidEntry]: (null, GitManager.deleteGitIndex),
  [invalidDataInIndexExtensionIsTruncated]: (null, GitManager.deleteGitIndex),
  [corruptedLooseFetchHead]: (null, GitManager.deleteFetchHead),
  [theIndexIsLocked]: (null, GitManager.deleteGitIndex),
  [androidInvalidCharacterInFilenamePrefix, androidInvalidCharacterInFilenameSuffix]: (
    t.androidLimitedFilepathCharacters,
    ([int? repomanRepoindex]) async {
      launchUrl(Uri.parse(androidLimitedFilepathCharactersLink));
    },
  ),
  [emptyNameOrEmail]: (t.emptyNameOrEmail, null),
  [errorReadingZlibStream]: (
    t.errorReadingZlibStream,
    ([int? repomanRepoindex]) async {
      launchUrl(Uri.parse(release1708Link));
    },
  ),
};
final GlobalKey errorDialogKey = GlobalKey();

Future<void> showDialog(BuildContext context, String error, Function() callback) {
  bool autoFixing = false;

  final autoFixKey = autoFixMessageCallbackMap.keys.firstWhereOrNull((textArray) => textArray.every((text) => error.contains(text)));

  return mat.showDialog(
    context: context,
    builder: (BuildContext context) => BaseAlertDialog(
      expandable: true,
      key: errorDialogKey,
      title: SizedBox(
        child: Text(
          t.errorOccurredTitle,
          style: TextStyle(color: primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
        ),
      ),
      contentBuilder: (expanded) =>
          (expanded
          ? (List<Widget> children) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)
          : (List<Widget> children) => SingleChildScrollView(child: ListBody(children: children)))([
            ...autoFixMessageCallbackMap[autoFixKey]?.$1 != null
                ? [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: spaceXS),
                      child: Text(
                        autoFixMessageCallbackMap[autoFixKey]?.$1 ?? "",
                        style: TextStyle(color: primaryPositive, fontSize: textSM, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(height: spaceMD),
                  ]
                : [],
            ...autoFixMessageCallbackMap[autoFixKey]?.$2 != null
                ? [
                    StatefulBuilder(
                      builder: (context, setState) => TextButton.icon(
                        onPressed: () async {
                          autoFixing = true;
                          setState(() {});

                          await (autoFixMessageCallbackMap[autoFixKey]?.$2 ?? () async {})();

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
                            : FaIcon(FontAwesomeIcons.hammer, color: primaryPositive, size: textLG),
                        label: Text(
                          t.attemptAutoFix.toUpperCase(),
                          style: TextStyle(color: primaryPositive, fontSize: textSM, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    SizedBox(height: spaceMD),
                  ]
                : [],
            (expanded ? (child) => Flexible(child: child) : (child) => child)(
              GestureDetector(
                onLongPress: () {
                  Clipboard.setData(ClipboardData(text: error));
                },
                child: SizedBox(
                  height: expanded ? null : MediaQuery.sizeOf(context).height / 3,
                  child: ShaderMask(
                    shaderCallback: (Rect rect) {
                      return LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.transparent, Colors.transparent, Colors.black],
                        stops: [0.0, 0.1, 0.9, 1.0],
                      ).createShader(rect);
                    },
                    blendMode: BlendMode.dstOut,
                    child: SingleChildScrollView(
                      child: Text(
                        error,
                        style: const TextStyle(color: tertiaryNegative, fontWeight: FontWeight.bold, fontSize: textSM),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: spaceMD),
            Text(
              t.errorOccurredMessagePart1,
              style: const TextStyle(color: primaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
            ),
            SizedBox(height: spaceSM),
            Text(
              t.errorOccurredMessagePart2,
              style: const TextStyle(color: primaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
            ),
          ]),
      actions: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () async {
                launchUrl(Uri.parse(troubleshootingLink));
              },
              style: ButtonStyle(
                alignment: Alignment.center,
                backgroundColor: WidgetStatePropertyAll(tertiaryInfo),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM), side: BorderSide.none)),
              ),
              icon: FaIcon(FontAwesomeIcons.solidFileLines, color: secondaryDark, size: textSM),
              label: Text(
                t.troubleshooting.toUpperCase(),
                style: TextStyle(color: primaryDark, fontSize: textSM, fontWeight: FontWeight.bold),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
          ],
        ),
      ],
    ),
  );
}
