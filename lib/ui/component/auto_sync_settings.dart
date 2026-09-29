import 'dart:io';

import 'package:GitSync/api/manager/storage.dart';
import 'package:animated_reorderable_list/animated_reorderable_list.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/api/accessibility_service_helper.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/constant/strings.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/ui/dialog/select_application.dart' as SelectApplicationDialog;
import 'package:GitSync/ui/dialog/prominent_disclosure.dart' as ProminentDisclosureDialog;
import 'package:sprintf/sprintf.dart';
import 'package:url_launcher/url_launcher.dart';

class AutoSyncSettings extends StatefulWidget {
  final bool isOnboarding;

  const AutoSyncSettings({super.key, this.isOnboarding = false});

  @override
  State<AutoSyncSettings> createState() => _AutoSyncSettingsState();
}

class _AutoSyncSettingsState extends State<AutoSyncSettings> {
  Future<bool> getExpanded() async {
    return (Platform.isIOS || (Platform.isAndroid && await AccessibilityServiceHelper.isAccessibilityServiceEnabled())) &&
        await uiSettingsManager.getBool(StorageKey.setman_applicationObserverExpanded);
  }

  Widget _buildBody(AsyncSnapshot applicationPackagesSnapshot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: widget.isOnboarding ? EdgeInsets.zero : EdgeInsets.symmetric(horizontal: spaceMD + spaceXS),
          child: TextButton.icon(
            onPressed: (Platform.isAndroid && (applicationPackagesSnapshot.data ?? {}).isEmpty)
                ? null
                : () async {
                    uiSettingsManager.setBool(
                      StorageKey.setman_syncOnAppOpened,
                      !(await uiSettingsManager.getBool(StorageKey.setman_syncOnAppOpened)),
                    );
                    setState(() {});
                  },
            iconAlignment: IconAlignment.end,
            style: ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: WidgetStatePropertyAll(EdgeInsets.only(left: spaceMD, top: spaceXS, bottom: spaceXS, right: spaceXS)),

              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none)),
              backgroundColor: WidgetStatePropertyAll(context.colours.tertiaryDark),
            ),
            icon: FutureBuilder(
              future: uiSettingsManager.getBool(StorageKey.setman_syncOnAppOpened),
              builder: (context, snapshot) => Container(
                margin: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceXXS),
                width: spaceLG,
                child: FittedBox(
                  fit: BoxFit.fill,
                  child: Switch(
                    value: (Platform.isAndroid && (applicationPackagesSnapshot.data ?? {}).isEmpty) ? false : snapshot.data ?? false,
                    onChanged: (value) {
                      uiSettingsManager.setBool(StorageKey.setman_syncOnAppOpened, value);
                      setState(() {});
                    },
                    padding: EdgeInsets.zero,
                    thumbColor: WidgetStatePropertyAll(
                      ((Platform.isAndroid && (applicationPackagesSnapshot.data ?? {}).isEmpty) ? false : snapshot.data ?? false)
                          ? context.colours.primaryPositive
                          : context.colours.tertiaryDark,
                    ),
                    trackOutlineColor: WidgetStatePropertyAll(Colors.transparent),
                    activeThumbColor: context.colours.primaryPositive,
                    inactiveTrackColor: context.colours.tertiaryLight,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ),
            label: Text(
              Platform.isIOS ? context.t.iosSyncOnAppOpened : context.t.syncOnAppOpened,
              style: TextStyle(
                color: (Platform.isAndroid && (applicationPackagesSnapshot.data ?? {}).isEmpty)
                    ? context.colours.tertiaryLight
                    : context.colours.primaryLight,
                fontSize: textMD,
              ),
            ),
          ),
        ),
        SizedBox(height: spaceMD),
        Padding(
          padding: widget.isOnboarding ? EdgeInsets.zero : EdgeInsets.symmetric(horizontal: spaceMD + spaceXS),
          child: TextButton.icon(
            onPressed: (Platform.isAndroid && (applicationPackagesSnapshot.data ?? {}).isEmpty)
                ? null
                : () async {
                    uiSettingsManager.setBool(
                      StorageKey.setman_syncOnAppClosed,
                      !(await uiSettingsManager.getBool(StorageKey.setman_syncOnAppClosed)),
                    );
                    setState(() {});
                  },
            iconAlignment: IconAlignment.end,
            style: ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: WidgetStatePropertyAll(EdgeInsets.only(left: spaceMD, top: spaceXS, bottom: spaceXS, right: spaceXS)),

              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none)),
              backgroundColor: WidgetStatePropertyAll(context.colours.tertiaryDark),
            ),
            icon: FutureBuilder(
              future: uiSettingsManager.getBool(StorageKey.setman_syncOnAppClosed),
              builder: (context, snapshot) => Container(
                margin: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceXXS),
                width: spaceLG,
                child: FittedBox(
                  fit: BoxFit.fill,
                  child: Switch(
                    value: (Platform.isAndroid && (applicationPackagesSnapshot.data ?? {}).isEmpty) ? false : snapshot.data ?? false,
                    onChanged: (value) {
                      uiSettingsManager.setBool(StorageKey.setman_syncOnAppClosed, value);
                      setState(() {});
                    },
                    padding: EdgeInsets.zero,
                    thumbColor: WidgetStatePropertyAll(
                      ((Platform.isAndroid && (applicationPackagesSnapshot.data ?? {}).isEmpty) ? false : snapshot.data ?? false)
                          ? context.colours.primaryPositive
                          : context.colours.tertiaryDark,
                    ),
                    activeThumbColor: context.colours.primaryPositive,
                    inactiveTrackColor: context.colours.tertiaryLight,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ),
            label: Text(
              Platform.isIOS ? context.t.iosSyncOnAppClosed : context.t.syncOnAppClosed,
              style: TextStyle(
                color: (Platform.isAndroid && (applicationPackagesSnapshot.data ?? {}).isEmpty)
                    ? context.colours.tertiaryLight
                    : context.colours.primaryLight,
                fontSize: textMD,
              ),
            ),
          ),
        ),
        if (Platform.isIOS) SizedBox(height: spaceSM),
        if (Platform.isIOS)
          Padding(
            padding: widget.isOnboarding ? EdgeInsets.zero : EdgeInsets.symmetric(horizontal: spaceMD + spaceXS),
            child: TextButton.icon(
              onPressed: () async {
                await launchUrl(Uri.parse(iosAppSyncDocsLink));
              },
              iconAlignment: IconAlignment.start,
              style: ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceXS)),
                shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none)),
              ),
              icon: FaIcon(FontAwesomeIcons.squareArrowUpRight, color: context.colours.tertiaryInfo, size: textSM),
              label: SizedBox(
                width: double.infinity,
                child: Text(
                  context.t.iosAppSyncDocsLinkText,
                  style: TextStyle(color: context.colours.tertiaryInfo, fontSize: textSM, fontWeight: FontWeight.normal),
                ),
              ),
            ),
          ),
        if (Platform.isAndroid) SizedBox(height: spaceMD),
        if (Platform.isAndroid)
          Padding(
            padding: widget.isOnboarding ? EdgeInsets.zero : EdgeInsets.symmetric(horizontal: spaceMD + spaceXS),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    await SelectApplicationDialog.showDialog(context, applicationPackagesSnapshot.data);
                    setState(() {});
                  },
                  iconAlignment: IconAlignment.start,
                  style: ButtonStyle(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: WidgetStatePropertyAll(EdgeInsets.all(spaceMD)),
                    shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none)),
                    backgroundColor: WidgetStatePropertyAll(context.colours.tertiaryDark),
                  ),
                  icon: (applicationPackagesSnapshot.data ?? {}).isEmpty
                      ? FaIcon(FontAwesomeIcons.circlePlus, color: context.colours.primaryLight, size: textXL)
                      : ((applicationPackagesSnapshot.data ?? {}).length == 1
                            ? FutureBuilder(
                                future: AccessibilityServiceHelper.getApplicationIcon(applicationPackagesSnapshot.data!.first),
                                builder: (context, iconSnapshot) =>
                                    iconSnapshot.data == null ? SizedBox.shrink() : Image.memory(height: textXL, width: textXL, iconSnapshot.data!),
                              )
                            : null),
                  label: FutureBuilder(
                    future: (applicationPackagesSnapshot.data ?? {}).length == 1
                        ? AccessibilityServiceHelper.getApplicationLabel(applicationPackagesSnapshot.data!.first)
                        : Future.value(null),
                    builder: (context, labelSnapshot) => Text(
                      ((applicationPackagesSnapshot.data ?? {}).isEmpty
                              ? context.t.applicationNotSet
                              : ((applicationPackagesSnapshot.data ?? {}).length == 1
                                    ? (labelSnapshot.data ?? "")
                                    : sprintf(context.t.multipleApplicationSelected, [(applicationPackagesSnapshot.data ?? {}).length])))
                          .toUpperCase(),
                      style: TextStyle(color: context.colours.primaryLight, fontSize: textMD),
                    ),
                  ),
                ),
                (applicationPackagesSnapshot.data ?? {}).length <= 1
                    ? SizedBox.shrink()
                    : Expanded(
                        child: Container(
                          padding: EdgeInsets.only(left: spaceMD),
                          height: textXL + textMD,
                          child: AnimatedListView(
                            shrinkWrap: true,
                            scrollDirection: Axis.horizontal,
                            items: (applicationPackagesSnapshot.data ?? {}).toList(),
                            isSameItem: (a, b) => a == b,
                            itemBuilder: (context, index) {
                              final packageName = (applicationPackagesSnapshot.data ?? {}).toList()[index];

                              return Padding(
                                key: Key(packageName),
                                padding: EdgeInsets.only(right: spaceMD),
                                child: FutureBuilder(
                                  future: AccessibilityServiceHelper.getApplicationIcon(packageName),
                                  builder: (context, iconSnapshot) => iconSnapshot.data == null
                                      ? SizedBox.shrink()
                                      : Image.memory(height: textXL + textMD, width: textXL + textMD, iconSnapshot.data!),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
              ],
            ),
          ),
        SizedBox(height: spaceMD),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isOnboarding) {
      return FutureBuilder(
        future: uiSettingsManager.getApplicationPackages(),
        builder: (context, applicationPackagesSnapshot) => _buildBody(applicationPackagesSnapshot),
      );
    }

    return Container(
      decoration: BoxDecoration(color: context.colours.secondaryDark, borderRadius: BorderRadius.all(cornerRadiusMD)),
      child: FutureBuilder(
        future: AccessibilityServiceHelper.isAccessibilityServiceEnabled(),
        builder: (BuildContext context, AsyncSnapshot accessibilityServiceEnabledSnapshot) => FutureBuilder(
          future: getExpanded(),
          builder: (BuildContext context, AsyncSnapshot expandedSnapshot) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      final enabled = (expandedSnapshot.data ?? false);

                      if (Platform.isIOS) {
                        uiSettingsManager.setBool(StorageKey.setman_applicationObserverExpanded, !enabled);
                        setState(() {});
                        return;
                      }

                      if (!enabled && !(accessibilityServiceEnabledSnapshot.data ?? false)) {
                        await ProminentDisclosureDialog.showDialog(context, () async {
                          await AccessibilityServiceHelper.openAccessibilitySettings();
                          setState(() {});
                        });

                        setState(() {});
                        return;
                      }

                      uiSettingsManager.setBool(StorageKey.setman_applicationObserverExpanded, !enabled);
                      setState(() {});
                    },
                    iconAlignment: IconAlignment.end,
                    style: ButtonStyle(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceLG, vertical: spaceMD)),
                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none)),
                    ),
                    icon: FaIcon(
                      (expandedSnapshot.data ?? false) ? FontAwesomeIcons.chevronUp : FontAwesomeIcons.chevronDown,
                      color: (accessibilityServiceEnabledSnapshot.data ?? false) ? context.colours.primaryLight : context.colours.secondaryLight,
                      size: textXL,
                    ),
                    label: SizedBox(
                      width: double.infinity,
                      child: Row(
                        children: [
                          AnimatedSize(
                            duration: animFast,
                            child: SizedBox(width: (expandedSnapshot.data ?? false) ? spaceMD + spaceXXS : 0),
                          ),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.t.enableApplicationObserver,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFeatures: [FontFeature.enable('smcp')],
                                    color: context.colours.primaryLight,
                                    fontSize: textLG,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (expandedSnapshot.data == true) ...[
                                  SizedBox(height: spaceXXXXS),
                                  Text(
                                    Platform.isIOS ? context.t.appSyncIosDescription : context.t.appSyncDescription,
                                    style: TextStyle(color: context.colours.secondaryLight, fontSize: textMD),
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
                    duration: animFast,
                    top: 0,
                    left: 0,
                    bottom: 0,
                    child: (expandedSnapshot.data ?? false)
                        ? SizedBox(
                            width: spaceXL,
                            height: spaceXL,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              style: ButtonStyle(
                                tapTargetSize: MaterialTapTargetSize.padded,
                                shape: WidgetStatePropertyAll(
                                  RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
                                ),
                              ),
                              onPressed: () async {
                                launchUrl(Uri.parse(autoSyncDocsLink));
                              },
                              icon: FaIcon(FontAwesomeIcons.circleQuestion, color: context.colours.primaryLight, size: textLG),
                            ),
                          )
                        : SizedBox.shrink(),
                  ),
                ],
              ),
              FutureBuilder(
                future: uiSettingsManager.getApplicationPackages(),
                builder: (context, applicationPackagesSnapshot) => AnimatedSize(
                  duration: animFast,
                  child: SizedBox(
                    height: (expandedSnapshot.data ?? false) ? null : 0,
                    child: (expandedSnapshot.data ?? false) ? _buildBody(applicationPackagesSnapshot) : SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
