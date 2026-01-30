import 'package:GitSync/api/helper.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';
import 'package:GitSync/global.dart';

Future<void> showDialog(
  BuildContext context,
  String? branchName,
  List<String>? branchNames,
  Future<void> Function(String branchName, String basedOn) callback,
) async {
  final textController = TextEditingController();
  String? basedOnBranchName = branchName;

  return mat.showDialog(
    context: context,
    builder: (BuildContext context) => StatefulBuilder(
      builder: (context, setState) => BaseAlertDialog(
        title: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Text(
            t.createBranch,
            style: TextStyle(color: colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
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
                  color: colours.primaryLight,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                  decorationThickness: 0,
                  fontSize: textMD,
                ),
                decoration: InputDecoration(
                  fillColor: colours.secondaryDark,
                  filled: true,
                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(cornerRadiusSM), borderSide: BorderSide.none),
                  isCollapsed: true,
                  label: Text(
                    t.createBranchName.toUpperCase(),
                    style: TextStyle(color: colours.secondaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
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
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(borderRadius: BorderRadius.all(cornerRadiusSM), color: colours.secondaryDark),
                    child: DropdownButton(
                      isDense: true,
                      isExpanded: true,
                      hint: Text(
                        t.detachedHead.toUpperCase(),
                        style: TextStyle(fontSize: textMD, fontWeight: FontWeight.bold, color: colours.secondaryLight),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceXS),
                      value: branchNames?.contains(branchName) == true ? branchName : null,
                      menuMaxHeight: 250,
                      dropdownColor: colours.secondaryDark,
                      borderRadius: BorderRadius.all(cornerRadiusSM),
                      selectedItemBuilder: (context) => List.generate(
                        (branchNames ?? []).length,
                        (index) => Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              (branchNames ?? [])[index].toUpperCase(),
                              style: TextStyle(fontSize: textMD, fontWeight: FontWeight.bold, color: colours.primaryLight),
                            ),
                          ],
                        ),
                      ),
                      underline: const SizedBox.shrink(),
                      onChanged: <String>(value) async {
                        basedOnBranchName = value;
                        setState(() {});
                      },
                      items: (branchNames ?? [])
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
                      t.createBranchBasedOn.toUpperCase(),
                      style: TextStyle(color: colours.secondaryLight, fontSize: textXXS, fontWeight: FontWeight.bold),
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
              style: TextStyle(color: colours.primaryLight, fontSize: textMD),
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
                color: (textController.text.isNotEmpty && basedOnBranchName != null) ? colours.primaryPositive : colours.secondaryPositive,
                fontSize: textMD,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
