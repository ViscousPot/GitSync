import 'package:GitSync/constant/strings.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';
import 'package:GitSync/global.dart';

Future<void> showDialog(BuildContext context, Function(bool directClone) callback) {
  bool directClone = true;

  return mat.showDialog(
    context: context,
    builder: (BuildContext context) => BaseAlertDialog(
      title: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Text(
          t.selectCloneDirectory,
          style: TextStyle(color: colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t.chooseHowToClone,
            style: TextStyle(
              color: colours.primaryLight,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
              decorationThickness: 0,
              fontSize: textMD,
            ),
          ),
          SizedBox(height: spaceXS),
          Text(
            "${bullet} ${t.directCloningMsg}\n${bullet} ${t.nestedCloningMsg}",
            style: TextStyle(color: colours.primaryLight, decoration: TextDecoration.none, decorationThickness: 0, fontSize: textMD),
          ),
          SizedBox(height: spaceMD + spaceSM),
          StatefulBuilder(
            builder: (BuildContext context, void Function(void Function()) setState) => Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: animFast,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: cornerRadiusMD,
                        topRight: Radius.zero,
                        bottomLeft: cornerRadiusMD,
                        bottomRight: Radius.zero,
                      ),
                      color: directClone == true ? colours.tertiaryInfo : colours.tertiaryDark,
                    ),
                    child: TextButton.icon(
                      onPressed: () async {
                        directClone = true;
                        setState(() {});
                      },
                      style: ButtonStyle(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: spaceSM, horizontal: spaceMD)),
                        backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: cornerRadiusMD,
                              topRight: Radius.zero,
                              bottomLeft: cornerRadiusMD,
                              bottomRight: Radius.zero,
                            ),

                            side: directClone == true ? BorderSide.none : BorderSide(width: 3, color: colours.tertiaryInfo),
                          ),
                        ),
                      ),
                      icon: FaIcon(
                        FontAwesomeIcons.solidFolderOpen,
                        color: directClone == true ? colours.tertiaryDark : colours.primaryLight,
                        size: textMD,
                      ),
                      label: SizedBox(
                        width: double.infinity,
                        child: AnimatedDefaultTextStyle(
                          child: Text(
                            t.directClone,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: textMD, fontWeight: FontWeight.bold),
                          ),
                          style: TextStyle(
                            color: directClone == true ? colours.tertiaryDark : colours.primaryLight,
                            fontSize: textMD,
                            fontWeight: FontWeight.bold,
                          ),
                          duration: animFast,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: AnimatedContainer(
                    duration: animFast,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.zero,
                        topRight: cornerRadiusMD,
                        bottomLeft: Radius.zero,
                        bottomRight: cornerRadiusMD,
                      ),
                      color: directClone != true ? colours.tertiaryInfo : colours.tertiaryDark,
                    ),
                    child: TextButton.icon(
                      onPressed: () async {
                        directClone = false;
                        setState(() {});
                      },
                      style: ButtonStyle(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: spaceSM, horizontal: spaceMD)),
                        backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.zero,
                              topRight: cornerRadiusMD,
                              bottomLeft: Radius.zero,
                              bottomRight: cornerRadiusMD,
                            ),
                            side: directClone != true ? BorderSide.none : BorderSide(width: 3, color: colours.tertiaryInfo),
                          ),
                        ),
                      ),
                      iconAlignment: IconAlignment.end,
                      icon: FaIcon(
                        FontAwesomeIcons.folderTree,
                        color: directClone != true ? colours.tertiaryDark : colours.primaryLight,
                        size: textMD,
                      ),
                      label: SizedBox(
                        width: double.infinity,
                        child: AnimatedDefaultTextStyle(
                          child: Text(
                            t.nestedClone,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: textMD, fontWeight: FontWeight.bold),
                          ),
                          style: TextStyle(
                            color: directClone != true ? colours.tertiaryDark : colours.primaryLight,
                            fontSize: textMD,
                            fontWeight: FontWeight.bold,
                          ),
                          duration: animFast,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
          child: Text(
            t.select.toUpperCase(),
            style: TextStyle(color: colours.primaryPositive, fontSize: textMD),
          ),
          onPressed: () async {
            callback(directClone);
            Navigator.of(context).canPop() ? Navigator.pop(context) : null;
          },
        ),
      ],
    ),
  );
}
