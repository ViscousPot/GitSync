import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/global.dart';
import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

class CustomShowcase extends StatelessWidget {
  const CustomShowcase({
    super.key,
    required this.globalKey,
    required this.child,
    required this.description,
    this.customTooltipActions,
    this.cornerRadius,
    this.targetPadding,
    this.first = false,
    this.last = false,
  });

  final GlobalKey globalKey;
  final Widget child;
  final String description;
  final List<TooltipActionButton>? customTooltipActions;
  final Radius? cornerRadius;
  final EdgeInsets? targetPadding;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) => Showcase(
    key: globalKey,
    targetBorderRadius: cornerRadius == null ? null : BorderRadius.all(cornerRadius!),
    description: description,
    descTextStyle: TextStyle(fontSize: textMD, fontWeight: FontWeight.w500, color: colours.primaryDark),
    targetPadding: targetPadding ?? EdgeInsets.all(spaceSM),
    tooltipActions: [
      ...customTooltipActions ?? [],
      ...!first
          ? [
              TooltipActionButton(
                type: TooltipDefaultActionType.previous,
                backgroundColor: colours.primaryLight,
                textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: textSM, color: colours.primaryDark),
                name: t.previous.toUpperCase(),
              ),
            ]
          : [],
      ...!last
          ? [
              TooltipActionButton(
                type: TooltipDefaultActionType.next,
                backgroundColor: colours.primaryLight,
                textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: textSM, color: colours.primaryDark),
                name: t.next.toUpperCase(),
              ),
            ]
          : [
              TooltipActionButton(
                type: TooltipDefaultActionType.next,
                backgroundColor: colours.primaryLight,
                textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: textSM, color: colours.primaryDark),
                name: t.finish.toUpperCase(),
              ),
            ],
    ],
    tooltipBackgroundColor: colours.tertiaryInfo,
    textColor: colours.secondaryDark,
    child: child,
  );
}
