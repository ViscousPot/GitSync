import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/global.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:showcaseview/showcaseview.dart';

class CustomShowcase extends StatelessWidget {
  const CustomShowcase({
    super.key,
    required this.globalKey,
    required this.child,
    this.description,
    this.title,
    this.richContent,
    this.richContentHeight,
    this.richContentWidth,
    this.customTooltipActions,
    this.cornerRadius,
    this.targetPadding,
    this.first = false,
    this.last = false,
  }) : assert(description != null || richContent != null, 'Either description or richContent must be provided');

  final GlobalKey globalKey;
  final Widget child;
  final String? description;
  final String? title;
  final Widget? richContent;
  final double? richContentHeight;
  final double? richContentWidth;
  final List<TooltipActionButton>? customTooltipActions;
  final Radius? cornerRadius;
  final EdgeInsets? targetPadding;
  final bool first;
  final bool last;

  List<TooltipActionButton> _buildTooltipActions() => [
    ...customTooltipActions ?? [],
    ...!first
        ? [
            TooltipActionButton(
              type: TooltipDefaultActionType.previous,
              backgroundColor: colours.showcaseBtnSecondary,
              textStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: textSM,
                color: colours.showcaseFeatureIcon,
                fontFamily: 'AtkinsonHyperlegible',
              ),
              name: t.previous.toUpperCase(),
              borderRadius: BorderRadius.all(cornerRadiusMD),
              padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceXS),
            ),
          ]
        : [],
    ...!last
        ? [
            TooltipActionButton(
              type: TooltipDefaultActionType.next,
              backgroundColor: colours.showcaseBtnPrimary,
              textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: textSM, color: colours.showcaseBtnText, fontFamily: 'AtkinsonHyperlegible'),
              name: t.next.toUpperCase(),
              borderRadius: BorderRadius.all(cornerRadiusMD),
              padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceXS),
            ),
          ]
        : [
            TooltipActionButton(
              type: TooltipDefaultActionType.next,
              backgroundColor: colours.showcaseBtnPrimary,
              textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: textSM, color: colours.showcaseBtnText, fontFamily: 'AtkinsonHyperlegible'),
              name: t.finish.toUpperCase(),
              borderRadius: BorderRadius.all(cornerRadiusMD),
              padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceXS),
            ),
          ],
  ];

  @override
  Widget build(BuildContext context) {
    if (richContent != null) {
      return Showcase.withWidget(
        key: globalKey,
        targetBorderRadius: cornerRadius == null ? null : BorderRadius.all(cornerRadius!),
        targetPadding: targetPadding ?? EdgeInsets.all(spaceSM),
        overlayOpacity: 0.85,
        tooltipActionConfig: TooltipActionConfig(alignment: MainAxisAlignment.end, actionGap: spaceXS, gapBetweenContentAndAction: spaceMD),
        tooltipActions: _buildTooltipActions(),
        height: richContentHeight ?? 280,
        width: richContentWidth ?? MediaQuery.of(context).size.width - (spaceLG * 2),
        container: richContent!,
        child: child,
      );
    }

    return Showcase(
      key: globalKey,
      targetBorderRadius: cornerRadius == null ? null : BorderRadius.all(cornerRadius!),
      title: title,
      titleTextStyle: TextStyle(fontSize: textXL, fontWeight: FontWeight.bold, color: colours.showcaseTitle, fontFamily: 'AtkinsonHyperlegible'),
      description: description,
      descTextStyle: TextStyle(fontSize: textSM, fontWeight: FontWeight.bold, color: colours.showcaseDesc, fontFamily: 'AtkinsonHyperlegible'),
      targetPadding: targetPadding ?? EdgeInsets.all(spaceSM),
      tooltipBackgroundColor: colours.showcaseBg,
      textColor: colours.showcaseTitle,
      tooltipBorderRadius: BorderRadius.all(cornerRadiusMD),
      tooltipPadding: EdgeInsets.all(spaceMD),
      overlayOpacity: 0.85,
      tooltipActionConfig: TooltipActionConfig(alignment: MainAxisAlignment.end, actionGap: spaceXS, gapBetweenContentAndAction: spaceMD),
      tooltipActions: _buildTooltipActions(),
      child: child,
    );
  }
}

class ShowcaseTooltipContent extends StatelessWidget {
  const ShowcaseTooltipContent({super.key, required this.title, this.subtitle, required this.featureRows});

  final String title;
  final String? subtitle;
  final List<ShowcaseFeatureRow> featureRows;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Container(
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: colours.showcaseBg,
          border: Border.all(color: colours.showcaseBorder),
          borderRadius: BorderRadius.all(cornerRadiusMD),
        ),
        padding: EdgeInsets.all(spaceMD),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: textXL, fontWeight: FontWeight.bold, color: colours.showcaseTitle, fontFamily: 'AtkinsonHyperlegible'),
            ),
            if (subtitle != null) ...[
              SizedBox(height: spaceXS),
              Text(
                subtitle!,
                style: TextStyle(fontSize: textSM, fontWeight: FontWeight.bold, color: colours.showcaseDesc, fontFamily: 'AtkinsonHyperlegible'),
              ),
            ],
            SizedBox(height: spaceMD),
            ...featureRows,
          ],
        ),
      ),
    ],
  );
}

class ShowcaseFeatureRow extends StatelessWidget {
  const ShowcaseFeatureRow({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: spaceXXXS),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FaIcon(icon, color: colours.showcaseFeatureIcon, size: textSM),
        SizedBox(width: spaceSM),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: colours.showcaseTitle, fontSize: textSM, fontWeight: FontWeight.bold, fontFamily: 'AtkinsonHyperlegible'),
          ),
        ),
      ],
    ),
  );
}
