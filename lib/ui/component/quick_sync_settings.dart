import 'dart:io';

import 'package:GitSync/constant/strings.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/constant/colors.dart';
import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/global.dart';
import 'package:url_launcher/url_launcher.dart';

class QuickSyncSettings extends StatefulWidget {
  const QuickSyncSettings({super.key});

  @override
  State<QuickSyncSettings> createState() => _QuickSyncSettingsState();
}

class _QuickSyncSettingsState extends State<QuickSyncSettings> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: secondaryDark, borderRadius: BorderRadius.all(cornerRadiusMD)),
      child: FutureBuilder(
        future: uiSettingsManager.getBool(StorageKey.setman_otherSyncSettingsExpanded),
        builder: (context, snapshot) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    uiSettingsManager.setBool(StorageKey.setman_otherSyncSettingsExpanded, !(snapshot.data ?? false));
                    setState(() {});
                  },
                  iconAlignment: IconAlignment.end,
                  style: ButtonStyle(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceLG, vertical: spaceMD)),
                    shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none)),
                  ),
                  icon: FaIcon(
                    (snapshot.data ?? false) ? FontAwesomeIcons.chevronUp : FontAwesomeIcons.chevronDown,
                    color: primaryLight,
                    size: textXL,
                  ),
                  label: SizedBox(
                    width: double.infinity,
                    child: Row(
                      children: [
                        AnimatedSize(
                          duration: Duration(milliseconds: 200),
                          child: SizedBox(width: (snapshot.data ?? false) ? spaceMD + spaceXXS : 0),
                        ),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.quickSyncSettings,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFeatures: [FontFeature.enable('smcp')],
                                  color: primaryLight,
                                  fontSize: textLG,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (snapshot.data == true) ...[
                                SizedBox(height: spaceXXXXS),
                                Text(
                                  t.quickSyncDescription,
                                  style: TextStyle(color: secondaryLight, fontSize: textMD),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: Duration(milliseconds: 200),
                  top: 0,
                  left: 0,
                  bottom: 0,
                  child: (snapshot.data ?? false)
                      ? SizedBox(
                          height: spaceXL,
                          width: spaceXL,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            style: ButtonStyle(
                              tapTargetSize: MaterialTapTargetSize.padded,
                              shape: WidgetStatePropertyAll(
                                RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
                              ),
                            ),
                            onPressed: () async {
                              launchUrl(Uri.parse(quickSyncDocsLink));
                            },
                            icon: FaIcon(FontAwesomeIcons.circleQuestion, color: primaryLight, size: textLG),
                          ),
                        )
                      : SizedBox.shrink(),
                ),
              ],
            ),
            AnimatedSize(
              duration: Duration(milliseconds: 200),
              child: SizedBox(
                height: (snapshot.data ?? false) ? null : 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: (snapshot.data ?? false)
                      ? [
                          if (!Platform.isIOS)
                            TextButton.icon(
                              onPressed: () async {
                                await repoManager.setInt(StorageKey.repoman_tileSyncIndex, await repoManager.getInt(StorageKey.repoman_repoIndex));
                                setState(() {});
                              },
                              iconAlignment: IconAlignment.end,
                              style: ButtonStyle(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: WidgetStatePropertyAll(
                                  EdgeInsets.only(left: spaceMD + spaceXS, right: spaceLG, top: spaceMD, bottom: spaceMD),
                                ),
                                shape: WidgetStatePropertyAll(
                                  RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
                                ),
                              ),
                              icon: FutureBuilder(
                                future: (() async =>
                                    await repoManager.getInt(StorageKey.repoman_tileSyncIndex) ==
                                    await repoManager.getInt(StorageKey.repoman_repoIndex))(),
                                builder: (context, snapshot) => FaIcon(
                                  snapshot.data == true ? FontAwesomeIcons.solidCircleCheck : FontAwesomeIcons.circle,
                                  color: snapshot.data == true ? primaryPositive : secondaryLight,
                                  size: textLG,
                                ),
                              ),
                              label: SizedBox(
                                width: double.infinity,
                                child: Text(
                                  t.useForTileSync,
                                  style: TextStyle(color: primaryLight, fontSize: textMD),
                                ),
                              ),
                            ),
                          if (!Platform.isIOS)
                            TextButton.icon(
                              onPressed: () async {
                                await repoManager.setInt(
                                  StorageKey.repoman_tileManualSyncIndex,
                                  await repoManager.getInt(StorageKey.repoman_repoIndex),
                                );
                                setState(() {});
                              },
                              iconAlignment: IconAlignment.end,
                              style: ButtonStyle(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: WidgetStatePropertyAll(
                                  EdgeInsets.only(left: spaceMD + spaceXS, right: spaceLG, top: spaceMD, bottom: spaceMD),
                                ),
                                shape: WidgetStatePropertyAll(
                                  RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
                                ),
                              ),
                              icon: FutureBuilder(
                                future: (() async =>
                                    await repoManager.getInt(StorageKey.repoman_tileManualSyncIndex) ==
                                    await repoManager.getInt(StorageKey.repoman_repoIndex))(),
                                builder: (context, snapshot) => FaIcon(
                                  snapshot.data == true ? FontAwesomeIcons.solidCircleCheck : FontAwesomeIcons.circle,
                                  color: snapshot.data == true ? primaryPositive : secondaryLight,
                                  size: textLG,
                                ),
                              ),
                              label: SizedBox(
                                width: double.infinity,
                                child: Text(
                                  t.useForTileManualSync,
                                  style: TextStyle(color: primaryLight, fontSize: textMD),
                                ),
                              ),
                            ),
                          TextButton.icon(
                            onPressed: () async {
                              await repoManager.setInt(StorageKey.repoman_shortcutSyncIndex, await repoManager.getInt(StorageKey.repoman_repoIndex));
                              setState(() {});
                            },
                            iconAlignment: IconAlignment.end,
                            style: ButtonStyle(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: WidgetStatePropertyAll(
                                EdgeInsets.only(left: spaceMD + spaceXS, right: spaceLG, top: spaceMD, bottom: spaceMD),
                              ),
                              shape: WidgetStatePropertyAll(
                                RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
                              ),
                            ),
                            icon: FutureBuilder(
                              future: (() async =>
                                  await repoManager.getInt(StorageKey.repoman_shortcutSyncIndex) ==
                                  await repoManager.getInt(StorageKey.repoman_repoIndex))(),
                              builder: (context, snapshot) => FaIcon(
                                snapshot.data == true ? FontAwesomeIcons.solidCircleCheck : FontAwesomeIcons.circle,
                                color: snapshot.data == true ? primaryPositive : secondaryLight,
                                size: textLG,
                              ),
                            ),
                            label: SizedBox(
                              width: double.infinity,
                              child: Text(
                                t.useForShortcutSync,
                                style: TextStyle(color: primaryLight, fontSize: textMD),
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              await repoManager.setInt(
                                StorageKey.repoman_shortcutManualSyncIndex,
                                await repoManager.getInt(StorageKey.repoman_repoIndex),
                              );
                              setState(() {});
                            },
                            iconAlignment: IconAlignment.end,
                            style: ButtonStyle(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: WidgetStatePropertyAll(
                                EdgeInsets.only(left: spaceMD + spaceXS, right: spaceLG, top: spaceMD, bottom: spaceMD),
                              ),
                              shape: WidgetStatePropertyAll(
                                RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
                              ),
                            ),
                            icon: FutureBuilder(
                              future: (() async =>
                                  await repoManager.getInt(StorageKey.repoman_shortcutManualSyncIndex) ==
                                  await repoManager.getInt(StorageKey.repoman_repoIndex))(),
                              builder: (context, snapshot) => FaIcon(
                                snapshot.data == true ? FontAwesomeIcons.solidCircleCheck : FontAwesomeIcons.circle,
                                color: snapshot.data == true ? primaryPositive : secondaryLight,
                                size: textLG,
                              ),
                            ),
                            label: SizedBox(
                              width: double.infinity,
                              child: Text(
                                t.useForShortcutManualSync,
                                style: TextStyle(color: primaryLight, fontSize: textMD),
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              await repoManager.setInt(StorageKey.repoman_widgetSyncIndex, await repoManager.getInt(StorageKey.repoman_repoIndex));
                              setState(() {});
                            },
                            iconAlignment: IconAlignment.end,
                            style: ButtonStyle(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: WidgetStatePropertyAll(
                                EdgeInsets.only(left: spaceMD + spaceXS, right: spaceLG, top: spaceMD, bottom: spaceMD),
                              ),
                              shape: WidgetStatePropertyAll(
                                RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
                              ),
                            ),
                            icon: FutureBuilder(
                              future: (() async =>
                                  await repoManager.getInt(StorageKey.repoman_widgetSyncIndex) ==
                                  await repoManager.getInt(StorageKey.repoman_repoIndex))(),
                              builder: (context, snapshot) => FaIcon(
                                snapshot.data == true ? FontAwesomeIcons.solidCircleCheck : FontAwesomeIcons.circle,
                                color: snapshot.data == true ? primaryPositive : secondaryLight,
                                size: textLG,
                              ),
                            ),
                            label: SizedBox(
                              width: double.infinity,
                              child: Text(
                                t.useForWidgetSync,
                                style: TextStyle(color: primaryLight, fontSize: textMD),
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              await repoManager.setInt(
                                StorageKey.repoman_widgetManualSyncIndex,
                                await repoManager.getInt(StorageKey.repoman_repoIndex),
                              );
                              setState(() {});
                            },
                            iconAlignment: IconAlignment.end,
                            style: ButtonStyle(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: WidgetStatePropertyAll(
                                EdgeInsets.only(left: spaceMD + spaceXS, right: spaceLG, top: spaceMD, bottom: spaceMD),
                              ),
                              shape: WidgetStatePropertyAll(
                                RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
                              ),
                            ),
                            icon: FutureBuilder(
                              future: (() async =>
                                  await repoManager.getInt(StorageKey.repoman_widgetManualSyncIndex) ==
                                  await repoManager.getInt(StorageKey.repoman_repoIndex))(),
                              builder: (context, snapshot) => FaIcon(
                                snapshot.data == true ? FontAwesomeIcons.solidCircleCheck : FontAwesomeIcons.circle,
                                color: snapshot.data == true ? primaryPositive : secondaryLight,
                                size: textLG,
                              ),
                            ),
                            label: SizedBox(
                              width: double.infinity,
                              child: Text(
                                t.useForWidgetManualSync,
                                style: TextStyle(color: primaryLight, fontSize: textMD),
                              ),
                            ),
                          ),
                        ]
                      : [],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
