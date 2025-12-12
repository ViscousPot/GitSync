import 'dart:io';

import 'package:GitSync/api/helper.dart';
import 'package:GitSync/constant/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/constant/colors.dart';
import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/global.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workmanager/workmanager.dart';

class ScheduledSyncSettings extends StatefulWidget {
  const ScheduledSyncSettings({super.key});

  @override
  State<ScheduledSyncSettings> createState() => _ScheduledSyncSettingsState();
}

class _ScheduledSyncSettingsState extends State<ScheduledSyncSettings> {
  final recurFrequency = ["never", "min", "hour", "day", "week"];

  Future<void> setScheduledSync(String? frequency, int rate) async {
    // TODO: run these when repo/container is delete for cleanup
    await uiSettingsManager.setString(StorageKey.setman_schedule, "$frequency|$rate");
    final repoIndex = await repoManager.getInt(StorageKey.repoman_repoIndex);

    if (frequency == "never") {
      setState(() {});
      await Workmanager().cancelAll();
      return;
    }

    int multiplier = 1;
    switch (frequency) {
      case "hour":
        multiplier = 60;
      case "day":
        multiplier = 1440;
      case "week":
        multiplier = 10080;
    }

    debounce(scheduledSyncSetDebounceReference, 1000, () async {
      setState(() {});
      await Workmanager().cancelByUniqueName("$scheduledSyncKey$repoIndex");
      await Workmanager().registerPeriodicTask(
        "$scheduledSyncKey$repoIndex",
        scheduledSyncSetDebounceReference,
        inputData: {"repoIndex": repoIndex},
        frequency: Duration(minutes: multiplier * rate),
        constraints: Constraints(networkType: NetworkType.connected),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: secondaryDark, borderRadius: BorderRadius.all(cornerRadiusMD)),
      child: FutureBuilder(
        future: uiSettingsManager.getBool(StorageKey.setman_scheduledSyncSettingsExpanded),
        builder: (context, snapshot) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    await uiSettingsManager.setBool(StorageKey.setman_scheduledSyncSettingsExpanded, !(snapshot.data ?? false));
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
                                t.scheduledSyncSettings,
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
                                  t.scheduledSyncDescription,
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
                              launchUrl(Uri.parse(scheduledSyncDocsLink));
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
              child: Container(
                height: (snapshot.data ?? false) ? null : 0,
                padding: EdgeInsets.symmetric(horizontal: spaceMD + spaceXS, vertical: 0),
                child: (snapshot.data ?? false)
                    ? FutureBuilder(
                        future: (() async {
                          final parts = (await uiSettingsManager.getString(StorageKey.setman_schedule)).split("|");
                          return (parts.first, int.tryParse(parts.last) ?? 0);
                        })(),
                        builder: (context, scheduleSnapshot) => SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                margin: EdgeInsets.symmetric(vertical: spaceSM, horizontal: 0),
                                decoration: BoxDecoration(color: tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
                                child: DropdownButton(
                                  isDense: true,
                                  padding: EdgeInsets.symmetric(vertical: spaceXXS, horizontal: spaceXS),
                                  value: scheduleSnapshot.data?.$1 != "never",
                                  menuMaxHeight: 250,
                                  borderRadius: BorderRadius.all(cornerRadiusSM),
                                  underline: const SizedBox.shrink(),
                                  dropdownColor: tertiaryDark,
                                  onChanged: (value) {},
                                  items: [true, false].map((item) {
                                    return DropdownMenuItem(
                                      value: item,
                                      onTap: () async {
                                        if (item == true) {
                                          await setScheduledSync("min", 15);
                                          return;
                                        } else {
                                          await setScheduledSync("never", 1);
                                        }
                                        if (item == false) return;
                                      },
                                      child: Row(
                                        children: [
                                          FaIcon(
                                            (item ? FontAwesomeIcons.arrowsRotate : FontAwesomeIcons.ban),
                                            color: (!item ? tertiaryNegative : primaryLight),
                                            size: textSM,
                                          ),
                                          SizedBox(width: spaceXS),
                                          Text(
                                            (item ? t.sync : t.dontSync).toUpperCase(),
                                            style: TextStyle(
                                              fontSize: textSM,
                                              color: primaryLight,
                                              fontWeight: FontWeight.bold,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              // enhancedScheduledSync == true ?  :
                              ...scheduleSnapshot.data?.$1 == "never"
                                  ? []
                                  : (Platform.isIOS
                                        ? [
                                            SizedBox(width: spaceSM),
                                            Text(
                                              t.iosDefaultSyncRate.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: textSM,
                                                color: primaryLight,
                                                fontWeight: FontWeight.bold,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ]
                                        : [
                                            SizedBox(width: spaceSM),
                                            Text(
                                              t.aboutEvery.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: textSM,
                                                color: primaryLight,
                                                fontWeight: FontWeight.bold,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            SizedBox(width: spaceXS),
                                            Container(
                                              width: spaceXL,
                                              margin: EdgeInsets.symmetric(vertical: spaceSM, horizontal: 0),
                                              decoration: BoxDecoration(color: tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
                                              child: TextField(
                                                contextMenuBuilder: globalContextMenuBuilder,
                                                maxLines: 1,
                                                controller: TextEditingController(text: scheduleSnapshot.data?.$2.toString()),
                                                keyboardType: TextInputType.number,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter.digitsOnly,
                                                  TextInputFormatter.withFunction((oldValue, newValue) {
                                                    final text = newValue.text;
                                                    if (text.isEmpty) {
                                                      return newValue;
                                                    }
                                                    final value = int.tryParse(text);
                                                    if (value == null || value < (scheduleSnapshot.data?.$1 == "min" ? 15 : 1) || value > 1000) {
                                                      return oldValue;
                                                    }
                                                    return newValue;
                                                  }),
                                                ],
                                                style: TextStyle(
                                                  color: primaryLight,
                                                  fontWeight: FontWeight.bold,
                                                  decoration: TextDecoration.none,
                                                  decorationThickness: 0,
                                                  fontSize: textMD,
                                                ),
                                                decoration: InputDecoration(
                                                  border: const OutlineInputBorder(borderSide: BorderSide.none),
                                                  isCollapsed: true,
                                                  contentPadding: EdgeInsets.symmetric(vertical: spaceXXS, horizontal: spaceXS),
                                                  hintText: "0",
                                                  floatingLabelBehavior: FloatingLabelBehavior.always,
                                                  isDense: true,
                                                ),
                                                onChanged: (value) async {
                                                  await setScheduledSync(
                                                    scheduleSnapshot.data?.$1,
                                                    int.tryParse(value) ?? (scheduleSnapshot.data?.$1 == "min" ? 15 : 1),
                                                  );
                                                },
                                              ),
                                            ),
                                            SizedBox(width: spaceXS),
                                            Container(
                                              margin: EdgeInsets.symmetric(vertical: spaceSM, horizontal: 0),
                                              decoration: BoxDecoration(color: tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
                                              child: DropdownButton(
                                                isDense: true,
                                                padding: EdgeInsets.symmetric(vertical: spaceXXS, horizontal: spaceXS),
                                                value: scheduleSnapshot.data?.$1,
                                                menuMaxHeight: 250,
                                                borderRadius: BorderRadius.all(cornerRadiusSM),
                                                underline: const SizedBox.shrink(),
                                                dropdownColor: primaryDark,
                                                onChanged: (value) async {
                                                  await setScheduledSync(value, (value == "min" ? 15 : 1));
                                                },
                                                items: recurFrequency.sublist(1).map((item) {
                                                  return DropdownMenuItem(
                                                    value: item,
                                                    child: Row(
                                                      children: [
                                                        Text(
                                                          "$item(s)".toUpperCase(),
                                                          style: TextStyle(
                                                            fontSize: textSM,
                                                            color: primaryLight,
                                                            fontWeight: FontWeight.bold,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ]),
                            ],
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
