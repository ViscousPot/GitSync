import 'dart:io';

import 'package:GitSync/api/helper.dart';
import 'package:GitSync/constant/strings.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/global.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workmanager/workmanager.dart';

class ScheduledSyncSettings extends StatefulWidget {
  final bool isOnboarding;

  const ScheduledSyncSettings({super.key, this.isOnboarding = false});

  @override
  State<ScheduledSyncSettings> createState() => _ScheduledSyncSettingsState();
}

class _ScheduledSyncSettingsState extends State<ScheduledSyncSettings> {
  final recurFrequency = ["never", "min", "hour", "day", "week"];

  String? _customFrequency;
  int? _customRate;
  bool _customError = false;

  static const List<(String, String, int)> _presets = [
    ('interval30min', 'min', 30),
    ('interval1hour', 'hour', 1),
    ('interval6hours', 'hour', 6),
    ('interval12hours', 'hour', 12),
    ('interval1day', 'day', 1),
    ('interval1week', 'week', 1),
  ];

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
      );
    });
  }

  String _presetLabel(String key) {
    switch (key) {
      case 'interval30min':
        return t.interval30min;
      case 'interval1hour':
        return t.interval1hour;
      case 'interval6hours':
        return t.interval6hours;
      case 'interval12hours':
        return t.interval12hours;
      case 'interval1day':
        return t.interval1day;
      case 'interval1week':
        return t.interval1week;
      default:
        return key;
    }
  }

  String _frequencyLabel(String freq) {
    switch (freq) {
      case 'min':
        return t.minutes;
      case 'hour':
        return t.hours;
      case 'day':
        return t.days;
      case 'week':
        return t.weeks;
      default:
        return freq;
    }
  }

  bool _matchesPreset(String frequency, int rate, (String, String, int) preset) {
    return frequency == preset.$2 && rate == preset.$3;
  }

  bool _isCustom(String frequency, int rate) {
    return _customFrequency != null || !_presets.any((p) => _matchesPreset(frequency, rate, p));
  }

  Widget _buildEnableToggle(bool isEnabled) {
    return Padding(
      padding: widget.isOnboarding ? EdgeInsets.zero : EdgeInsets.symmetric(horizontal: spaceMD + spaceXS),
      child: TextButton.icon(
        onPressed: () async {
          _customFrequency = null;
          _customRate = null;
          _customError = false;
          if (isEnabled) {
            await setScheduledSync("never", 1);
          } else {
            await setScheduledSync("min", 15);
          }
        },
        iconAlignment: IconAlignment.end,
        style: ButtonStyle(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: WidgetStatePropertyAll(EdgeInsets.only(left: spaceMD, top: spaceXS, bottom: spaceXS, right: spaceXS)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none)),
          backgroundColor: WidgetStatePropertyAll(colours.tertiaryDark),
        ),
        icon: Container(
          margin: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceXXS),
          width: spaceLG,
          child: FittedBox(
            fit: BoxFit.fill,
            child: Switch(
              value: isEnabled,
              onChanged: (value) async {
                _customFrequency = null;
                _customRate = null;
                _customError = false;
                if (value) {
                  await setScheduledSync("min", 15);
                } else {
                  await setScheduledSync("never", 1);
                }
              },
              padding: EdgeInsets.zero,
              thumbColor: WidgetStatePropertyAll(isEnabled ? colours.primaryPositive : colours.tertiaryDark),
              trackOutlineColor: WidgetStatePropertyAll(Colors.transparent),
              activeThumbColor: colours.primaryPositive,
              inactiveTrackColor: colours.tertiaryLight,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
        label: Text(
          t.scheduledSync,
          style: TextStyle(color: colours.primaryLight, fontSize: textMD),
        ),
      ),
    );
  }

  Widget _buildChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: animFast,
        padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceXS),
        decoration: BoxDecoration(color: selected ? colours.tertiaryInfo : colours.tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: selected ? colours.primaryDark : colours.primaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildIntervalChips(String frequency, int rate) {
    final isCustomSelected = _isCustom(frequency, rate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: widget.isOnboarding ? EdgeInsets.zero : EdgeInsets.symmetric(horizontal: spaceMD + spaceXS),
          child: Column(
            spacing: spaceXS,
            children: [
              Row(
                spacing: spaceXS,
                children: [
                  ..._presets.slice(0, 3).map((preset) {
                    final selected = !isCustomSelected && _matchesPreset(frequency, rate, preset);
                    return Expanded(
                      child: _buildChip(_presetLabel(preset.$1), selected, () async {
                        _customFrequency = null;
                        _customRate = null;
                        _customError = false;
                        await setScheduledSync(preset.$2, preset.$3);
                      }),
                    );
                  }),
                ],
              ),
              Row(
                spacing: spaceXS,
                children: [
                  ..._presets.slice(3, 6).map((preset) {
                    final selected = !isCustomSelected && _matchesPreset(frequency, rate, preset);
                    return Expanded(
                      child: _buildChip(_presetLabel(preset.$1), selected, () async {
                        _customFrequency = null;
                        _customRate = null;
                        _customError = false;
                        await setScheduledSync(preset.$2, preset.$3);
                      }),
                    );
                  }),
                ],
              ),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AnimatedSize(
                      duration: animFast,
                      child: isCustomSelected ? _buildCustomInputs(frequency, rate) : SizedBox.shrink(),
                    ),
                    Expanded(
                      child: _buildChip(
                        isCustomSelected ? t.confirm : t.custom,
                        isCustomSelected,
                        isCustomSelected
                            ? () async {
                                final freq = _customFrequency ?? frequency;
                                final r = _customRate ?? rate;
                                final min = freq == "min" ? 15 : 1;

                                if (r < min || r > 1000) {
                                  setState(() {
                                    _customError = true;
                                  });
                                  return;
                                }

                                _customFrequency = null;
                                _customRate = null;
                                _customError = false;
                                await setScheduledSync(freq, r);
                              }
                            : () {
                                if (!isCustomSelected) {
                                  setState(() {
                                    _customFrequency = frequency;
                                    _customRate = rate;
                                  });
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomInputs(String frequency, int rate) {
    final customFreq = _customFrequency ?? frequency;
    final customRate = _customRate ?? rate;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedContainer(
            duration: animFast,
            width: spaceXL,
            decoration: BoxDecoration(
              color: colours.tertiaryDark,
              borderRadius: BorderRadius.all(cornerRadiusSM),
              border: Border.all(color: _customError ? colours.tertiaryNegative : Colors.transparent, width: 1.5),
            ),
            child: TextField(
              contextMenuBuilder: globalContextMenuBuilder,
              maxLines: 1,
              controller: TextEditingController(text: customRate.toString()),
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: _customError ? colours.tertiaryNegative : colours.primaryLight,
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
              onChanged: (value) {
                _customRate = int.tryParse(value);
                if (_customError) {
                  setState(() {
                    _customError = false;
                  });
                }
              },
            ),
          ),
          SizedBox(width: spaceXS),
          Container(
            decoration: BoxDecoration(color: colours.tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
            child: DropdownButton(
              isDense: true,
              padding: EdgeInsets.symmetric(vertical: spaceXXS, horizontal: spaceXS),
              value: customFreq,
              menuMaxHeight: 250,
              borderRadius: BorderRadius.all(cornerRadiusSM),
              underline: const SizedBox.shrink(),
              dropdownColor: colours.primaryDark,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _customFrequency = value;
                    _customRate = value == "min" ? 15 : 1;
                    _customError = false;
                  });
                }
              },
              items: recurFrequency.sublist(1).map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(
                    _frequencyLabel(item),
                    style: TextStyle(fontSize: textSM, color: colours.primaryLight, fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(width: spaceXS),
          // IconButton(
          //   padding: EdgeInsets.all(spaceXS),
          //   style: ButtonStyle(
          //     backgroundColor: WidgetStatePropertyAll(colours.tertiaryInfo),
          //     tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          //     shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM))),
          //   ),
          //   constraints: BoxConstraints(),
          //   onPressed: () async {
          //   },
          //   icon: FaIcon(FontAwesomeIcons.check, color: colours.primaryDark, size: textMD),
          // ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return FutureBuilder(
      future: (() async {
        final parts = (await uiSettingsManager.getString(StorageKey.setman_schedule)).split("|");
        return (parts.first, int.tryParse(parts.last) ?? 0);
      })(),
      builder: (context, scheduleSnapshot) {
        final frequency = scheduleSnapshot.data?.$1 ?? "never";
        final rate = scheduleSnapshot.data?.$2 ?? 0;
        final isEnabled = frequency != "never";

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEnableToggle(isEnabled),
            SizedBox(height: spaceXS),
            AnimatedSize(
              duration: animFast,
              child: isEnabled
                  ? (Platform.isIOS
                        ? Padding(
                            padding: widget.isOnboarding
                                ? EdgeInsets.only(bottom: spaceSM)
                                : EdgeInsets.only(left: spaceMD + spaceXS, right: spaceMD + spaceXS, bottom: spaceSM),
                            child: Text(
                              t.iosDefaultSyncRate,
                              style: TextStyle(fontSize: textMD, color: colours.tertiaryLight),
                            ),
                          )
                        : Padding(
                            padding: EdgeInsets.only(bottom: spaceSM),
                            child: _buildIntervalChips(frequency, rate),
                          ))
                  : SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isOnboarding) {
      return _buildBody();
    }

    return Container(
      decoration: BoxDecoration(color: colours.secondaryDark, borderRadius: BorderRadius.all(cornerRadiusMD)),
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
                    color: colours.primaryLight,
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
                                t.scheduledSyncSettings,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFeatures: [FontFeature.enable('smcp')],
                                  color: colours.primaryLight,
                                  fontSize: textLG,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (snapshot.data == true) ...[
                                SizedBox(height: spaceXXXXS),
                                Text(
                                  t.scheduledSyncDescription,
                                  style: TextStyle(color: colours.secondaryLight, fontSize: textMD),
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
                              launchUrl(Uri.parse(scheduledSyncDocsLink));
                            },
                            icon: FaIcon(FontAwesomeIcons.circleQuestion, color: colours.primaryLight, size: textLG),
                          ),
                        )
                      : SizedBox.shrink(),
                ),
              ],
            ),
            AnimatedSize(
              duration: animFast,
              child: SizedBox(height: (snapshot.data ?? false) ? null : 0, child: (snapshot.data ?? false) ? _buildBody() : null),
            ),
          ],
        ),
      ),
    );
  }
}
