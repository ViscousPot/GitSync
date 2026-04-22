import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import 'package:sprintf/sprintf.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/src/rust/api/git_manager.dart' as GitManagerRs;

Future<void> showDialog(
  BuildContext context,
  List<GitManagerRs.Commit> selectedCommits,
  String? currentBranch,
  List<String> branchNames,
  Future<void> Function(String targetBranch) callback,
) {
  bool loading = false;
  String? selectedBranch = currentBranch;

  return mat.showDialog(
    context: context,
    builder: (BuildContext context) => StatefulBuilder(
      builder: (context, setState) => BaseAlertDialog(
        title: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Text(
            t.cherryPickCommits,
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
                    TextSpan(text: "${sprintf(t.cherryPickCommitsMsg, [selectedCommits.length])} "),
                  ],
                ),
              ),
              SizedBox(height: spaceXS),
              ...selectedCommits.map(
                (commit) => Padding(
                  padding: EdgeInsets.only(bottom: spaceXXXS),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(color: colours.tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusXS)),
                        padding: EdgeInsets.symmetric(horizontal: spaceXS, vertical: spaceXXXS),
                        child: Text(
                          commit.reference.substring(0, 7).toUpperCase(),
                          style: TextStyle(color: colours.tertiaryInfo, fontSize: textXS, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(width: spaceXS),
                      Expanded(
                        child: Text(
                          commit.commitMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colours.secondaryLight, fontSize: textXS),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: spaceMD),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(borderRadius: BorderRadius.all(cornerRadiusSM), color: colours.secondaryDark),
                    child: DropdownButton<String>(
                      isDense: true,
                      isExpanded: true,
                      padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceXS),
                      value: branchNames.contains(selectedBranch) ? selectedBranch : null,
                      menuMaxHeight: 250,
                      dropdownColor: colours.secondaryDark,
                      borderRadius: BorderRadius.all(cornerRadiusSM),
                      selectedItemBuilder: (context) => branchNames
                          .map(
                            (name) => Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  name.toUpperCase(),
                                  style: TextStyle(fontSize: textMD, fontWeight: FontWeight.bold, color: colours.primaryLight),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                      underline: const SizedBox.shrink(),
                      onChanged: (value) {
                        selectedBranch = value;
                        setState(() {});
                      },
                      items: branchNames
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(
                                item.toUpperCase(),
                                style: TextStyle(
                                  fontSize: textSM,
                                  color: colours.primaryLight,
                                  fontWeight: FontWeight.bold,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  Positioned(
                    top: -spaceXS,
                    left: spaceMD,
                    child: Text(
                      t.cherryPickTargetBranch.toUpperCase(),
                      style: TextStyle(color: colours.secondaryLight, fontSize: textXXS, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              SizedBox(height: spaceSM),
              Text(
                t.cherryPickCommitsWarning,
                style: TextStyle(color: colours.tertiaryWarning, fontWeight: FontWeight.bold, fontSize: textSM),
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
              t.cherryPick.toUpperCase(),
              style: TextStyle(
                color: selectedBranch != null ? colours.primaryPositive : colours.secondaryPositive,
                fontSize: textMD,
                fontWeight: FontWeight.bold,
              ),
            ),
            iconAlignment: IconAlignment.end,
            icon: loading
                ? SizedBox(
                    height: spaceMD,
                    width: spaceMD,
                    child: CircularProgressIndicator(color: colours.primaryPositive),
                  )
                : SizedBox.shrink(),
            onPressed: selectedBranch != null
                ? () async {
                    loading = true;
                    setState(() {});
                    await callback(selectedBranch!);
                    loading = false;
                    setState(() {});
                    Navigator.of(context).canPop() ? Navigator.pop(context) : null;
                  }
                : null,
          ),
        ],
      ),
    ),
  );
}
