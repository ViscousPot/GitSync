import 'package:GitSync/api/logger.dart';
import 'package:GitSync/api/manager/git_manager.dart';
import 'package:GitSync/constant/strings.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';
import 'package:GitSync/global.dart';

final Map<List<String>, (String?, Future<void> Function([int? repomanRepoindex])?)> autoFixMessageCallbackMap = {
  [invalidIndexHeaderError]: (null, ([_]) async => await runGitOperation(LogType.DiscardGitIndex, (event) => event)),
  [invalidDataInIndexInvalidEntry]: (null, ([_]) async => await runGitOperation(LogType.DiscardGitIndex, (event) => event)),
  [invalidDataInIndexExtensionIsTruncated]: (null, ([_]) async => await runGitOperation(LogType.DiscardGitIndex, (event) => event)),
  [corruptedLooseFetchHead]: (null, ([_]) async => await runGitOperation(LogType.DiscardFetchHead, (event) => event)),
  [corruptedLooseObjectError]: (null, ([_]) async => await runGitOperation(LogType.PruneCorruptedObjects, (event) => event)),
  [theIndexIsLocked]: (null, ([_]) async => await runGitOperation(LogType.DiscardGitIndex, (event) => event)),
  [androidInvalidCharacterInFilenamePrefix, androidInvalidCharacterInFilenameSuffix]: (
    t.androidLimitedFilepathCharacters,
    ([int? repomanRepoindex]) async {
      launchUrl(Uri.parse(androidLimitedFilepathCharactersLink));
    },
  ),
  [emptyNameOrEmail]: (t.emptyNameOrEmail, null),
  [failedToResolveAddress]: (t.failedToResolveAddressMessage, null),
  [errorReadingZlibStream]: (
    t.errorReadingZlibStream,
    ([int? repomanRepoindex]) async {
      launchUrl(Uri.parse(release1708Link));
    },
  ),
};
late final GlobalKey errorDialogKey = GlobalKey();

Future<void> showDialog(BuildContext context, String error, Function()? callback) {
  bool autoFixing = false;

  final autoFixKey = autoFixMessageCallbackMap.keys.firstWhereOrNull((textArray) => textArray.every((text) => error.contains(text)));

  return mat.showDialog(
    context: context,
    builder: (BuildContext context) => BaseAlertDialog(
      expandable: callback != null,
      key: errorDialogKey,
      title: SizedBox(
        child: Text(
          callback == null ? t.cloneFailed : t.errorOccurredTitle,
          style: TextStyle(color: colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
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
                        style: TextStyle(color: colours.primaryPositive, fontSize: textSM, fontWeight: FontWeight.bold),
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
                          backgroundColor: WidgetStatePropertyAll(colours.secondaryDark),
                          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceMD)),
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(cornerRadiusMD),
                              side: BorderSide(color: colours.primaryPositive, width: spaceXXXS),
                            ),
                          ),
                        ),
                        icon: autoFixing
                            ? SizedBox(
                                height: textSM,
                                width: textSM,
                                child: CircularProgressIndicator(color: colours.primaryPositive),
                              )
                            : FaIcon(FontAwesomeIcons.hammer, color: colours.primaryPositive, size: textLG),
                        label: Text(
                          t.attemptAutoFix.toUpperCase(),
                          style: TextStyle(color: colours.primaryPositive, fontSize: textSM, fontWeight: FontWeight.bold),
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
                        style: TextStyle(color: colours.tertiaryNegative, fontWeight: FontWeight.bold, fontSize: textSM),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            ...callback == null
                ? []
                : [
                    SizedBox(height: spaceMD),
                    Text(
                      t.errorOccurredMessagePart1,
                      style: TextStyle(color: colours.primaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
                    ),
                    SizedBox(height: spaceSM),
                    Text(
                      t.errorOccurredMessagePart2,
                      style: TextStyle(color: colours.primaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
                    ),
                  ],
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
                backgroundColor: WidgetStatePropertyAll(colours.tertiaryInfo),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM), side: BorderSide.none)),
              ),
              icon: FaIcon(FontAwesomeIcons.solidFileLines, color: colours.secondaryDark, size: textSM),
              label: Text(
                t.troubleshooting.toUpperCase(),
                style: TextStyle(color: colours.primaryDark, fontSize: textSM, fontWeight: FontWeight.bold),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  child: Text(
                    t.dismiss.toUpperCase(),
                    style: TextStyle(color: colours.primaryLight, fontSize: textMD),
                  ),
                  onPressed: () {
                    Navigator.of(context).canPop() ? Navigator.pop(context) : null;
                  },
                ),
                TextButton(
                  child: Text(
                    (callback == null ? t.ok : t.reportABug).toUpperCase(),
                    style: TextStyle(color: colours.tertiaryNegative, fontSize: textMD),
                  ),
                  onPressed: () async {
                    if (callback != null) callback();
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
