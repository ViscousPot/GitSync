import 'package:GitSync/api/helper.dart';
import 'package:GitSync/api/manager/git_manager.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import '../../../constant/colors.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';
import 'package:GitSync/global.dart';

Future<void> showDialog(BuildContext context, Future<void> Function(String branchName, String basedOn) callback) async {
  final textController = TextEditingController();
  String? basedOnBranchName = await GitManager.getBranchName();

  return mat.showDialog(
    context: context,
    builder: (BuildContext context) => StatefulBuilder(
      builder: (context, setState) => BaseAlertDialog(
        title: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Text(
            t.createBranch,
            style: TextStyle(color: primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
          ),
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              SizedBox(height: spaceMD),
              TextField(
                contextMenuBuilder: globalContextMenuBuilder,
                controller: textController,
                maxLines: 1,
                style: TextStyle(
                  color: primaryLight,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                  decorationThickness: 0,
                  fontSize: textMD,
                ),
                decoration: InputDecoration(
                  fillColor: secondaryDark,
                  filled: true,
                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(cornerRadiusSM), borderSide: BorderSide.none),
                  isCollapsed: true,
                  label: Text(
                    t.createBranchName.toUpperCase(),
                    style: TextStyle(color: secondaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  contentPadding: const EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
              SizedBox(height: spaceMD + spaceXS),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  FutureBuilder(
                    future: GitManager.getBranchName(),
                    builder: (context, branchNameSnapshot) => FutureBuilder(
                      future: GitManager.getBranchNames(),
                      builder: (context, branchNamesSnapshot) => Container(
                        width: double.infinity,
                        decoration: BoxDecoration(borderRadius: BorderRadius.all(cornerRadiusSM), color: secondaryDark),
                        child: DropdownButton(
                          isDense: true,
                          isExpanded: true,
                          hint: Text(
                            t.detachedHead.toUpperCase(),
                            style: TextStyle(fontSize: textMD, fontWeight: FontWeight.bold, color: secondaryLight),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceXS),
                          value: branchNamesSnapshot.data?.contains(branchNameSnapshot.data) == true ? branchNameSnapshot.data : null,
                          menuMaxHeight: 250,
                          dropdownColor: secondaryDark,
                          borderRadius: BorderRadius.all(cornerRadiusSM),
                          selectedItemBuilder: (context) => List.generate(
                            (branchNamesSnapshot.data ?? []).length,
                            (index) => Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  (branchNamesSnapshot.data ?? [])[index].toUpperCase(),
                                  style: TextStyle(fontSize: textMD, fontWeight: FontWeight.bold, color: primaryLight),
                                ),
                              ],
                            ),
                          ),
                          underline: const SizedBox.shrink(),
                          onChanged: <String>(value) async {
                            basedOnBranchName = value;
                            setState(() {});
                          },
                          items: (branchNamesSnapshot.data ?? [])
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(
                                    item.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: textSM,
                                      color: primaryLight,
                                      fontWeight: FontWeight.bold,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -spaceXS,
                    left: spaceMD,
                    child: Text(
                      t.createBranchBasedOn.toUpperCase(),
                      style: TextStyle(color: secondaryLight, fontSize: textXXS, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(
              t.cancel.toUpperCase(),
              style: TextStyle(color: primaryLight, fontSize: textMD),
            ),
            onPressed: () {
              Navigator.of(context).canPop() ? Navigator.pop(context) : null;
            },
          ),
          TextButton(
            onPressed: (textController.text.isNotEmpty && basedOnBranchName != null)
                ? () async {
                    Navigator.of(context).canPop() ? Navigator.pop(context) : null;
                    await callback(textController.text, basedOnBranchName!);
                  }
                : null,
            child: Text(
              t.add.toUpperCase(),
              style: TextStyle(
                color: (textController.text.isNotEmpty && basedOnBranchName != null) ? primaryPositive : secondaryPositive,
                fontSize: textMD,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
