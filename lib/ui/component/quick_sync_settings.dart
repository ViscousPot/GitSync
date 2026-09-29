import 'dart:io';

import 'package:GitSync/constant/strings.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/global.dart';
import 'package:url_launcher/url_launcher.dart';

class QuickSyncSettings extends StatefulWidget {
  final bool isOnboarding;

  const QuickSyncSettings({super.key, this.isOnboarding = false});

  @override
  State<QuickSyncSettings> createState() => _QuickSyncSettingsState();
}

class _QuickSyncSettingsState extends State<QuickSyncSettings> {
  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                widget.isOnboarding
                    ? EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceMD)
                    : EdgeInsets.only(left: spaceMD + spaceXS, right: spaceLG, top: spaceMD, bottom: spaceMD),
              ),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none)),
            ),
            icon: FutureBuilder(
              future: (() async =>
                  await repoManager.getInt(StorageKey.repoman_tileSyncIndex) == await repoManager.getInt(StorageKey.repoman_repoIndex))(),
              builder: (context, snapshot) => FaIcon(
                snapshot.data == true ? FontAwesomeIcons.solidCircleCheck : FontAwesomeIcons.circle,
                color: snapshot.data == true ? context.colours.primaryPositive : context.colours.secondaryLight,
                size: textLG,
              ),
            ),
            label: SizedBox(
              width: double.infinity,
              child: Text(
                context.t.useForTileSync,
                style: TextStyle(color: context.colours.primaryLight, fontSize: textMD),
              ),
            ),
          ),
        if (!Platform.isIOS)
          TextButton.icon(
            onPressed: () async {
              await repoManager.setInt(StorageKey.repoman_tileManualSyncIndex, await repoManager.getInt(StorageKey.repoman_repoIndex));
              setState(() {});
            },
            iconAlignment: IconAlignment.end,
            style: ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: WidgetStatePropertyAll(
                widget.isOnboarding
                    ? EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceMD)
                    : EdgeInsets.only(left: spaceMD + spaceXS, right: spaceLG, top: spaceMD, bottom: spaceMD),
              ),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none)),
            ),
            icon: FutureBuilder(
              future: (() async =>
                  await repoManager.getInt(StorageKey.repoman_tileManualSyncIndex) == await repoManager.getInt(StorageKey.repoman_repoIndex))(),
              builder: (context, snapshot) => FaIcon(
                snapshot.data == true ? FontAwesomeIcons.solidCircleCheck : FontAwesomeIcons.circle,
                color: snapshot.data == true ? context.colours.primaryPositive : context.colours.secondaryLight,
                size: textLG,
              ),
            ),
            label: SizedBox(
              width: double.infinity,
              child: Text(
                context.t.useForTileManualSync,
                style: TextStyle(color: context.colours.primaryLight, fontSize: textMD),
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
              widget.isOnboarding
                  ? EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceMD)
                  : EdgeInsets.only(left: spaceMD + spaceXS, right: spaceLG, top: spaceMD, bottom: spaceMD),
            ),
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none)),
          ),
          icon: FutureBuilder(
            future: (() async =>
                await repoManager.getInt(StorageKey.repoman_shortcutSyncIndex) == await repoManager.getInt(StorageKey.repoman_repoIndex))(),
            builder: (context, snapshot) => FaIcon(
              snapshot.data == true ? FontAwesomeIcons.solidCircleCheck : FontAwesomeIcons.circle,
              color: snapshot.data == true ? context.colours.primaryPositive : context.colours.secondaryLight,
              size: textLG,
            ),
          ),
          label: SizedBox(
            width: double.infinity,
            child: Text(
              context.t.useForShortcutSync,
              style: TextStyle(color: context.colours.primaryLight, fontSize: textMD),
            ),
          ),
        ),
        TextButton.icon(
          onPressed: () async {
            await repoManager.setInt(StorageKey.repoman_shortcutManualSyncIndex, await repoManager.getInt(StorageKey.repoman_repoIndex));
            setState(() {});
          },
          iconAlignment: IconAlignment.end,
          style: ButtonStyle(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: WidgetStatePropertyAll(
              widget.isOnboarding
                  ? EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceMD)
                  : EdgeInsets.only(left: spaceMD + spaceXS, right: spaceLG, top: spaceMD, bottom: spaceMD),
            ),
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none)),
          ),
          icon: FutureBuilder(
            future: (() async =>
                await repoManager.getInt(StorageKey.repoman_shortcutManualSyncIndex) == await repoManager.getInt(StorageKey.repoman_repoIndex))(),
            builder: (context, snapshot) => FaIcon(
              snapshot.data == true ? FontAwesomeIcons.solidCircleCheck : FontAwesomeIcons.circle,
              color: snapshot.data == true ? context.colours.primaryPositive : context.colours.secondaryLight,
              size: textLG,
            ),
          ),
          label: SizedBox(
            width: double.infinity,
            child: Text(
              context.t.useForShortcutManualSync,
              style: TextStyle(color: context.colours.primaryLight, fontSize: textMD),
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
              widget.isOnboarding
                  ? EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceMD)
                  : EdgeInsets.only(left: spaceMD + spaceXS, right: spaceLG, top: spaceMD, bottom: spaceMD),
            ),
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none)),
          ),
          icon: FutureBuilder(
            future: (() async =>
                await repoManager.getInt(StorageKey.repoman_widgetSyncIndex) == await repoManager.getInt(StorageKey.repoman_repoIndex))(),
            builder: (context, snapshot) => FaIcon(
              snapshot.data == true ? FontAwesomeIcons.solidCircleCheck : FontAwesomeIcons.circle,
              color: snapshot.data == true ? context.colours.primaryPositive : context.colours.secondaryLight,
              size: textLG,
            ),
          ),
          label: SizedBox(
            width: double.infinity,
            child: Text(
              context.t.useForWidgetSync,
              style: TextStyle(color: context.colours.primaryLight, fontSize: textMD),
            ),
          ),
        ),
        TextButton.icon(
          onPressed: () async {
            await repoManager.setInt(StorageKey.repoman_widgetManualSyncIndex, await repoManager.getInt(StorageKey.repoman_repoIndex));
            setState(() {});
          },
          iconAlignment: IconAlignment.end,
          style: ButtonStyle(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: WidgetStatePropertyAll(
              widget.isOnboarding
                  ? EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceMD)
                  : EdgeInsets.only(left: spaceMD + spaceXS, right: spaceLG, top: spaceMD, bottom: spaceMD),
            ),
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none)),
          ),
          icon: FutureBuilder(
            future: (() async =>
                await repoManager.getInt(StorageKey.repoman_widgetManualSyncIndex) == await repoManager.getInt(StorageKey.repoman_repoIndex))(),
            builder: (context, snapshot) => FaIcon(
              snapshot.data == true ? FontAwesomeIcons.solidCircleCheck : FontAwesomeIcons.circle,
              color: snapshot.data == true ? context.colours.primaryPositive : context.colours.secondaryLight,
              size: textLG,
            ),
          ),
          label: SizedBox(
            width: double.infinity,
            child: Text(
              context.t.useForWidgetManualSync,
              style: TextStyle(color: context.colours.primaryLight, fontSize: textMD),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isOnboarding) {
      return _buildBody();
    }

    return Container(
      decoration: BoxDecoration(color: context.colours.secondaryDark, borderRadius: BorderRadius.all(cornerRadiusMD)),
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
                    color: context.colours.primaryLight,
                    size: textXL,
                  ),
                  label: SizedBox(
                    width: double.infinity,
                    child: Row(
                      children: [
                        AnimatedSize(
                          duration: animFast,
                          child: SizedBox(width: (snapshot.data ?? false) ? spaceMD + spaceXXS : 0),
                        ),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.t.quickSyncSettings,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFeatures: [FontFeature.enable('smcp')],
                                  color: context.colours.primaryLight,
                                  fontSize: textLG,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (snapshot.data == true) ...[
                                SizedBox(height: spaceXXXXS),
                                Text(
                                  context.t.quickSyncDescription,
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
                            icon: FaIcon(FontAwesomeIcons.circleQuestion, color: context.colours.primaryLight, size: textLG),
                          ),
                        )
                      : SizedBox.shrink(),
                ),
              ],
            ),
            AnimatedSize(
              duration: animFast,
              child: SizedBox(height: (snapshot.data ?? false) ? null : 0, child: (snapshot.data ?? false) ? _buildBody() : SizedBox.shrink()),
            ),
          ],
        ),
      ),
    );
  }
}
