import 'dart:math' as math;

import 'package:GitSync/ui/dialog/onboarding_controller.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import '../../../constant/dimens.dart';
import 'package:GitSync/global.dart';
import '../../../ui/dialog/base_alert_dialog.dart';

Future<void> showDialog(BuildContext context, TickerProvider tickerProvider, Function callback) {
  late AnimationController _controller = AnimationController(
    vsync: tickerProvider,
    duration: Duration(seconds: 2), // Animation duration
  )..forward();
  return mat.showDialog(
    context: context,
    builder: (BuildContext context) => BaseAlertDialog(
      expandable: false,
      expanded: true,
      scrollable: false,
      contentPadding: EdgeInsets.zero,
      content: Stack(
        children: [
          Positioned(
            top: -spaceXXL * 1.5,
            left: -spaceXXL * 2,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 2,
              child: Transform.flip(
                flipX: true,
                flipY: true,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height / 2),
                      painter: LinePainter(_controller.value, colours.primaryLight, 100),
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned(
            top: -spaceXXL * 2.5,
            left: -spaceXXL,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 2,
              child: Transform.flip(
                flipX: true,
                flipY: true,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height / 2),
                      painter: LinePainter(_controller.value, colours.tertiaryNegative, 100),
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned(
            top: -spaceXXL * 3.5,
            left: 0,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 2,
              child: Transform.flip(
                flipX: true,
                flipY: true,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height / 2),
                      painter: LinePainter(_controller.value, colours.tertiaryPositive, 100),
                    );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: spaceSM * 2, left: spaceMD * 2, right: spaceMD * 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: MediaQuery.of(context).size.width),
                    Image.asset(
                      'assets/app_icon.png',
                      width: spaceXXL, // Adjust width as needed
                      height: spaceXXL,
                    ),
                    SizedBox(height: spaceMD),
                    Padding(
                      padding: EdgeInsets.only(right: MediaQuery.of(context).size.width / 5),
                      child: Text(
                        t.legacyAppUserDialogTitle,
                        style: TextStyle(
                          color: colours.primaryLight,
                          fontSize: textMD * 2,
                          fontFamily: "AtkinsonHyperlegible",
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: MediaQuery.of(context).size.width / 4),
                      child: Text(
                        t.legacyAppUserDialogMessagePart1,
                        textAlign: TextAlign.right,
                        style: TextStyle(color: colours.primaryLight, fontWeight: FontWeight.bold, fontSize: textXS * 2),
                      ),
                    ),
                    SizedBox(height: spaceXL),
                    Text(
                      t.legacyAppUserDialogMessagePart2,
                      style: TextStyle(color: colours.secondaryLight, fontWeight: FontWeight.bold, fontSize: textMD),
                    ),
                    SizedBox(height: spaceSM),
                    Text(
                      t.legacyAppUserDialogMessagePart3,
                      style: TextStyle(color: colours.secondaryLight, fontWeight: FontWeight.bold, fontSize: textMD),
                    ),
                    SizedBox(height: spaceXL),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 3,
                          child: TextButton(
                            style: ButtonStyle(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceXS)),
                              backgroundColor: WidgetStatePropertyAll(colours.tertiaryPositive),
                              shape: WidgetStatePropertyAll(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(cornerRadiusMD),
                                  side: BorderSide(width: spaceXXXS, color: colours.secondaryPositive, strokeAlign: BorderSide.strokeAlignCenter),
                                ),
                              ),
                            ),
                            child: Text(
                              t.setUp.toUpperCase(),
                              style: TextStyle(color: colours.secondaryDark, fontWeight: FontWeight.bold, fontSize: textMD),
                            ),
                            onPressed: () async {
                              Navigator.of(context).canPop() ? Navigator.pop(context) : null;
                              callback();
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: spaceLG),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
