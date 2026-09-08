import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/global.dart';

class FetchErrorState extends StatelessWidget {
  final Function() onRetry;

  const FetchErrorState({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FaIcon(FontAwesomeIcons.circleExclamation, color: context.colours.primaryNegative, size: textXL),
        SizedBox(height: spaceSM),
        Text(
          context.t.fetchFailed.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(color: context.colours.secondaryLight, fontWeight: FontWeight.bold, fontSize: textLG),
        ),
        SizedBox(height: spaceSM),
        TextButton(
          onPressed: onRetry,
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(context.colours.secondaryDark),
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM), side: BorderSide.none)),
          ),
          child: Text(
            context.t.retry.toUpperCase(),
            style: TextStyle(color: context.colours.primaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
