import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/constant/colors.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/global.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SyncClientModeToggle extends StatefulWidget {
  const SyncClientModeToggle({super.key, this.global = false});

  final bool global;

  @override
  State<SyncClientModeToggle> createState() => _SyncClientModeToggleState();
}

class _SyncClientModeToggleState extends State<SyncClientModeToggle> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: widget.global ? repoManager.getBool(StorageKey.repoman_defaultClientModeEnabled) : uiSettingsManager.getClientModeEnabled(),
      builder: (context, clientModeEnabledSnapshot) => Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(topLeft: cornerRadiusMD, topRight: Radius.zero, bottomLeft: cornerRadiusMD, bottomRight: Radius.zero),
                color: clientModeEnabledSnapshot.data != true ? tertiaryInfo : tertiaryDark,
              ),
              child: TextButton.icon(
                onPressed: () async {
                  if (widget.global) {
                    await repoManager.setBool(StorageKey.repoman_defaultClientModeEnabled, false);
                  } else {
                    await uiSettingsManager.setBoolNullable(StorageKey.setman_clientModeEnabled, false);
                  }
                  setState(() {});
                },
                style: ButtonStyle(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: spaceSM, horizontal: spaceMD)),
                  backgroundColor: WidgetStatePropertyAll(clientModeEnabledSnapshot.data != true ? tertiaryInfo : tertiaryDark),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: cornerRadiusMD,
                        topRight: Radius.zero,
                        bottomLeft: cornerRadiusMD,
                        bottomRight: Radius.zero,
                      ),

                      side: clientModeEnabledSnapshot.data != true ? BorderSide.none : BorderSide(width: 3, color: tertiaryInfo),
                    ),
                  ),
                ),
                icon: FaIcon(
                  FontAwesomeIcons.arrowsRotate,
                  color: clientModeEnabledSnapshot.data != true ? tertiaryDark : primaryLight,
                  size: textMD,
                ),
                label: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedDefaultTextStyle(
                        child: Text(
                          t.syncMode,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: textMD, fontWeight: FontWeight.bold),
                        ),
                        style: TextStyle(
                          color: clientModeEnabledSnapshot.data != true ? tertiaryDark : primaryLight,
                          fontSize: textMD,
                          fontWeight: FontWeight.bold,
                        ),
                        duration: Duration(milliseconds: 200),
                      ),
                      SizedBox(height: spaceXXXXS),
                      AnimatedDefaultTextStyle(
                        child: Text(
                          t.syncModeDescription,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: textXS, fontWeight: FontWeight.bold),
                        ),
                        style: TextStyle(
                          color: clientModeEnabledSnapshot.data != true ? tertiaryDark : primaryLight,
                          fontSize: textMD,
                          fontWeight: FontWeight.bold,
                        ),
                        duration: Duration(milliseconds: 200),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(topLeft: Radius.zero, topRight: cornerRadiusMD, bottomLeft: Radius.zero, bottomRight: cornerRadiusMD),
                color: clientModeEnabledSnapshot.data == true ? tertiaryInfo : tertiaryDark,
              ),
              child: TextButton.icon(
                onPressed: () async {
                  if (widget.global) {
                    await repoManager.setBool(StorageKey.repoman_defaultClientModeEnabled, true);
                  } else {
                    await uiSettingsManager.setBoolNullable(StorageKey.setman_clientModeEnabled, true);
                  }
                  setState(() {});
                },
                style: ButtonStyle(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: spaceSM, horizontal: spaceMD)),
                  backgroundColor: WidgetStatePropertyAll(clientModeEnabledSnapshot.data == true ? tertiaryInfo : tertiaryDark),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.zero,
                        topRight: cornerRadiusMD,
                        bottomLeft: Radius.zero,
                        bottomRight: cornerRadiusMD,
                      ),
                      side: clientModeEnabledSnapshot.data == true ? BorderSide.none : BorderSide(width: 3, color: tertiaryInfo),
                    ),
                  ),
                ),
                iconAlignment: IconAlignment.end,
                icon: FaIcon(FontAwesomeIcons.codeCompare, color: clientModeEnabledSnapshot.data == true ? tertiaryDark : primaryLight, size: textMD),
                label: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedDefaultTextStyle(
                        child: Text(
                          t.clientMode,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: textMD, fontWeight: FontWeight.bold),
                        ),
                        style: TextStyle(
                          color: clientModeEnabledSnapshot.data == true ? tertiaryDark : primaryLight,
                          fontSize: textMD,
                          fontWeight: FontWeight.bold,
                        ),
                        duration: Duration(milliseconds: 200),
                      ),
                      SizedBox(height: spaceXXXXS),
                      AnimatedDefaultTextStyle(
                        child: Text(
                          t.clientModeDescription,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: textXS, fontWeight: FontWeight.bold),
                        ),
                        style: TextStyle(
                          color: clientModeEnabledSnapshot.data == true ? tertiaryDark : primaryLight,
                          fontSize: textXS,
                          fontWeight: FontWeight.bold,
                        ),
                        duration: Duration(milliseconds: 200),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
