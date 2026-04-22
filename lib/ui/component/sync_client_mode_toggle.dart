import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/providers/riverpod_providers.dart';
import 'package:GitSync/ui/component/provider_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SyncClientModeToggle extends ConsumerStatefulWidget {
  const SyncClientModeToggle({super.key, this.global = false});

  final bool global;

  @override
  ConsumerState<SyncClientModeToggle> createState() => _SyncClientModeToggleState();
}

class _SyncClientModeToggleState extends ConsumerState<SyncClientModeToggle> {
  Widget _buildToggle(bool? clientModeEnabled) {
    return Row(
      children: [
        Expanded(
          child: AnimatedContainer(
            duration: animFast,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(topLeft: cornerRadiusMD, topRight: Radius.zero, bottomLeft: cornerRadiusMD, bottomRight: Radius.zero),
              color: clientModeEnabled != true ? colours.tertiaryInfo : colours.tertiaryDark,
            ),
            child: TextButton.icon(
              onPressed: () async {
                if (widget.global) {
                  await repoManager.setBool(StorageKey.repoman_defaultClientModeEnabled, false);
                  setState(() {});
                } else {
                  ref.read(clientModeEnabledProvider.notifier).set(false);
                }
              },
              style: ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: spaceSM, horizontal: spaceMD)),
                backgroundColor: WidgetStatePropertyAll(clientModeEnabled != true ? colours.tertiaryInfo : colours.tertiaryDark),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: cornerRadiusMD,
                      topRight: Radius.zero,
                      bottomLeft: cornerRadiusMD,
                      bottomRight: Radius.zero,
                    ),

                    side: clientModeEnabled != true ? BorderSide.none : BorderSide(width: 3, color: colours.tertiaryInfo),
                  ),
                ),
              ),
              icon: FaIcon(
                FontAwesomeIcons.arrowsRotate,
                color: clientModeEnabled != true ? colours.primaryDark : colours.primaryLight,
                size: textMD,
              ),
              label: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...widget.global
                        ? [
                            Center(
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 1, horizontal: spaceXXS),
                                decoration: BoxDecoration(
                                  color: clientModeEnabled != true ? colours.tertiaryDark : colours.tertiaryInfo,
                                  borderRadius: BorderRadius.all(cornerRadiusMD),
                                ),
                                child: AnimatedDefaultTextStyle(
                                  child: Text(
                                    t.defaultTo.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: textSM, fontWeight: FontWeight.w800),
                                  ),
                                  style: TextStyle(
                                    color: clientModeEnabled != true ? colours.primaryLight : colours.primaryDark,
                                    fontSize: textMD,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  duration: animFast,
                                ),
                              ),
                            ),
                            SizedBox(height: spaceXS),
                          ]
                        : [],
                    AnimatedDefaultTextStyle(
                      child: Text(
                        t.syncMode,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: textMD, fontWeight: FontWeight.bold),
                      ),
                      style: TextStyle(
                        color: clientModeEnabled != true ? colours.primaryDark : colours.primaryLight,
                        fontSize: textMD,
                        fontWeight: FontWeight.bold,
                      ),
                      duration: animFast,
                    ),
                    SizedBox(height: spaceXXXXS),
                    AnimatedDefaultTextStyle(
                      child: Text(
                        t.syncModeDescription,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: textXS, fontWeight: FontWeight.bold),
                      ),
                      style: TextStyle(
                        color: clientModeEnabled != true ? colours.primaryDark : colours.primaryLight,
                        fontSize: textMD,
                        fontWeight: FontWeight.bold,
                      ),
                      duration: animFast,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: AnimatedContainer(
            duration: animFast,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(topLeft: Radius.zero, topRight: cornerRadiusMD, bottomLeft: Radius.zero, bottomRight: cornerRadiusMD),
              color: clientModeEnabled == true ? colours.tertiaryInfo : colours.tertiaryDark,
            ),
            child: TextButton.icon(
              onPressed: () async {
                if (widget.global) {
                  await repoManager.setBool(StorageKey.repoman_defaultClientModeEnabled, true);
                  setState(() {});
                } else {
                  ref.read(clientModeEnabledProvider.notifier).set(true);
                }
              },
              style: ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: spaceSM, horizontal: spaceMD)),
                backgroundColor: WidgetStatePropertyAll(clientModeEnabled == true ? colours.tertiaryInfo : colours.tertiaryDark),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.zero,
                      topRight: cornerRadiusMD,
                      bottomLeft: Radius.zero,
                      bottomRight: cornerRadiusMD,
                    ),
                    side: clientModeEnabled == true ? BorderSide.none : BorderSide(width: 3, color: colours.tertiaryInfo),
                  ),
                ),
              ),
              iconAlignment: IconAlignment.end,
              icon: FaIcon(FontAwesomeIcons.codeCompare, color: clientModeEnabled == true ? colours.primaryDark : colours.primaryLight, size: textMD),
              label: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...widget.global
                        ? [
                            Center(
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 1, horizontal: spaceXXS),
                                decoration: BoxDecoration(
                                  color: clientModeEnabled != true ? colours.tertiaryInfo : colours.tertiaryDark,
                                  borderRadius: BorderRadius.all(cornerRadiusMD),
                                ),
                                child: AnimatedDefaultTextStyle(
                                  child: Text(
                                    t.defaultTo.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: textSM, fontWeight: FontWeight.w800),
                                  ),
                                  style: TextStyle(
                                    color: clientModeEnabled != true ? colours.primaryDark : colours.primaryLight,
                                    fontSize: textMD,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  duration: animFast,
                                ),
                              ),
                            ),
                            SizedBox(height: spaceXS),
                          ]
                        : [],
                    AnimatedDefaultTextStyle(
                      child: Text(
                        t.clientMode,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: textMD, fontWeight: FontWeight.bold),
                      ),
                      style: TextStyle(
                        color: clientModeEnabled == true ? colours.primaryDark : colours.primaryLight,
                        fontSize: textMD,
                        fontWeight: FontWeight.bold,
                      ),
                      duration: animFast,
                    ),
                    SizedBox(height: spaceXXXXS),
                    AnimatedDefaultTextStyle(
                      child: Text(
                        t.clientModeDescription,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: textXS, fontWeight: FontWeight.bold),
                      ),
                      style: TextStyle(
                        color: clientModeEnabled == true ? colours.primaryDark : colours.primaryLight,
                        fontSize: textXS,
                        fontWeight: FontWeight.bold,
                      ),
                      duration: animFast,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.global) {
      return FutureBuilder(
        future: repoManager.getBool(StorageKey.repoman_defaultClientModeEnabled),
        builder: (context, snapshot) => _buildToggle(snapshot.data),
      );
    }
    return ProviderBuilder<bool>(
      provider: clientModeEnabledProvider,
      builder: (context, clientModeEnabledAsync) => _buildToggle(clientModeEnabledAsync.valueOrNull),
    );
  }
}
