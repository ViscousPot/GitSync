import 'package:GitSync/api/helper.dart';
import 'package:GitSync/ui/dialog/info_dialog.dart' as InfoDialog;
import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';
import 'package:GitSync/global.dart';

Future<void> showDialog(BuildContext context, Future<void> Function(String, String, String, bool) report, {String? initialTitle, List<(String, String)>? deviceInfoEntries}) {
  final titleController = TextEditingController(text: initialTitle);
  final descriptionController = TextEditingController();
  final minimalReproController = TextEditingController();
  bool includeLogFiles = true;

  return mat.showDialog(
    context: context,
    barrierColor: Colors.transparent,
    builder: (BuildContext context) => StatefulBuilder(
      builder: (context, setState) => BaseAlertDialog(
        expandable: true,
        backgroundColor: colours.secondaryDark,
        title: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Text(
            t.reportABug.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(color: colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
          ),
        ),
        contentBuilder: (expanded) => Column(
              children: [
                (expanded ? (Widget child) => Expanded(child: child) : (Widget child) => Flexible(child: child))(
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: spaceMD),
                              child: Text(
                                t.issueReportTitleTitle.toUpperCase(),
                                style: TextStyle(color: colours.primaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: spaceMD),
                              child: Text(
                                t.issueReportTitleDesc,
                                style: TextStyle(color: colours.secondaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(height: spaceSM),
                            TextField(
                              contextMenuBuilder: globalContextMenuBuilder,
                              controller: titleController,
                              maxLines: 1,
                              minLines: 1,
                              style: TextStyle(
                                color: colours.primaryLight,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.none,
                                decorationThickness: 0,
                                fontSize: textMD,
                              ),
                              decoration: InputDecoration(
                                fillColor: colours.tertiaryDark,
                                filled: true,
                                border: const OutlineInputBorder(borderRadius: BorderRadius.all(cornerRadiusMD), borderSide: BorderSide.none),
                                isCollapsed: true,
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                contentPadding: const EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM),
                                errorText: titleController.text.isEmpty ? t.fieldCannotBeEmpty : null,
                                errorStyle: TextStyle(color: colours.tertiaryNegative),
                                isDense: true,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                        ),
                        SizedBox(height: spaceMD),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: spaceMD),
                              child: Text(
                                t.issueReportDescTitle.toUpperCase(),
                                style: TextStyle(color: colours.primaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: spaceMD),
                              child: Text(
                                t.issueReportDescDesc,
                                style: TextStyle(color: colours.secondaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(height: spaceSM),
                            TextField(
                              contextMenuBuilder: globalContextMenuBuilder,
                              controller: descriptionController,
                              maxLines: null,
                              minLines: 3,
                              style: TextStyle(
                                color: colours.primaryLight,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.none,
                                decorationThickness: 0,
                                fontSize: textMD,
                              ),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM),
                                border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(cornerRadiusMD)),
                                errorText: descriptionController.text.isEmpty ? t.fieldCannotBeEmpty : null,
                                errorStyle: TextStyle(color: colours.tertiaryNegative),
                                isCollapsed: true,
                                fillColor: colours.tertiaryDark,
                                filled: true,
                                isDense: true,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                        ),
                        SizedBox(height: spaceMD),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: spaceMD),
                              child: Text(
                                t.issueReportMinimalReproTitle.toUpperCase(),
                                style: TextStyle(color: colours.primaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: spaceMD),
                              child: Text(
                                t.issueReportMinimalReproDesc,
                                style: TextStyle(color: colours.secondaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(height: spaceSM),
                            TextField(
                              contextMenuBuilder: globalContextMenuBuilder,
                              controller: minimalReproController,
                              maxLines: null,
                              minLines: 3,
                              style: TextStyle(
                                color: colours.primaryLight,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.none,
                                decorationThickness: 0,
                                fontSize: textMD,
                              ),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM),
                                border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(cornerRadiusMD)),
                                isCollapsed: true,
                                errorText: minimalReproController.text.isEmpty ? t.fieldCannotBeEmpty : null,
                                errorStyle: TextStyle(color: colours.tertiaryNegative),
                                fillColor: colours.tertiaryDark,
                                filled: true,
                                isDense: true,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: spaceMD),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      style: ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      constraints: BoxConstraints(),
                      onPressed: () async {
                        openLogViewer(context, deviceInfoEntries: deviceInfoEntries);
                      },
                      icon: FaIcon(FontAwesomeIcons.eye, color: colours.tertiaryInfo, size: textSM),
                    ),
                    SizedBox(width: spaceXS),
                    TextButton.icon(
                      onPressed: () async {
                        includeLogFiles = !includeLogFiles;
                        if (includeLogFiles == false) {
                          await InfoDialog.showDialog(context, t.includeLogFiles, t.includeLogFilesDescription);
                        }
                        setState(() {});
                      },
                      style: ButtonStyle(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceSM)),
                        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM), side: BorderSide.none)),
                      ),
                      icon: FaIcon(
                        includeLogFiles ? FontAwesomeIcons.solidSquareCheck : FontAwesomeIcons.squareCheck,
                        color: colours.primaryPositive,
                        size: textSM,
                      ),
                      label: Text(
                        t.includeLogs,
                        textAlign: TextAlign.end,
                        style: TextStyle(color: colours.secondaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        actions: <Widget>[
          TextButton(
            child: Text(
              t.cancel.toUpperCase(),
              style: TextStyle(color: colours.primaryLight, fontSize: textMD),
            ),
            onPressed: () async {
              Navigator.of(context).canPop() ? Navigator.pop(context) : null;
            },
          ),

          TextButton.icon(
            icon: FaIcon(
              FontAwesomeIcons.solidPaperPlane,
              color: minimalReproController.text.isEmpty || descriptionController.text.isEmpty || titleController.text.isEmpty
                  ? colours.tertiaryLight
                  : colours.primaryPositive,
              size: textMD,
            ),
            label: Text(
              t.report.toUpperCase(),
              style: TextStyle(
                color: minimalReproController.text.isEmpty || descriptionController.text.isEmpty || titleController.text.isEmpty
                    ? colours.tertiaryLight
                    : colours.primaryPositive,
                fontSize: textMD,
              ),
            ),
            onPressed: minimalReproController.text.isEmpty || descriptionController.text.isEmpty || titleController.text.isEmpty
                ? null
                : () async {
                    Navigator.of(context).canPop() ? Navigator.pop(context) : null;
                    await report(titleController.text, descriptionController.text, minimalReproController.text, includeLogFiles);
                  },
          ),
        ],
      ),
    ),
  );
}
