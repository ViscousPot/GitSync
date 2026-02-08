import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/api/helper.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/constant/strings.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/ui/dialog/base_alert_dialog.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:url_launcher/url_launcher.dart';

class LinePainter extends CustomPainter {
  final double animationValue;
  final Color colour;
  final double curveDimen;

  LinePainter(this.animationValue, this.colour, [this.curveDimen = 200]);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colour
      ..style = PaintingStyle.stroke
      ..strokeWidth = spaceLG;

    final shadowPaint = Paint()
      ..color = colours.tertiaryDark.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = spaceLG + 2
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.0);

    final fullPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, curveDimen)
      ..arcTo(Rect.fromPoints(Offset(0, curveDimen), Offset(curveDimen, 0)), math.pi, math.pi / 2, false)
      ..lineTo(size.width, 0);

    final metrics = fullPath.computeMetrics().first;
    final path = metrics.extractPath(0, metrics.length * animationValue);

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant LinePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.colour != colour;
  }
}

class OnboardingController {
  final BuildContext context;
  final Future<void> Function() showAuthDialog;
  final Future<void> Function() showCloneRepoPage;
  final Future<void> Function(bool initialClientModeEnabled) completeUiGuideShowcase;
  final List<GlobalKey> showCaseKeys;
  bool hasSkipped = false;
  late final GlobalKey _currentDialog = GlobalKey();

  OnboardingController(this.context, this.showAuthDialog, this.showCloneRepoPage, this.completeUiGuideShowcase, this.showCaseKeys);

  void _showDialog(BaseAlertDialog dialog, {bool cancelable = true}) {
    mat.showDialog(context: context, builder: (BuildContext context) => dialog, barrierDismissible: cancelable);
  }

  Future<void> show(TickerProvider tickerProvider) async {
    final initialClientModeEnabled = await uiSettingsManager.getClientModeEnabled();

    switch (await repoManager.getInt(StorageKey.repoman_onboardingStep)) {
      case 0:
        await welcomeDialog(tickerProvider);
      case 1:
        await showAlmostThereOrSkip();
      case 2:
        await authDialog();
      case 3:
        await showCloneRepoPage();
      case 4:
        await uiSettingsManager.setBoolNullable(StorageKey.setman_clientModeEnabled, false);
        await repoManager.setOnboardingStep(4);
        ShowCaseWidget.of(context).startShowCase(showCaseKeys);
        while (!ShowCaseWidget.of(context).isShowCaseCompleted) {
          await Future.delayed(Duration(milliseconds: 100));
        }
        await completeUiGuideShowcase(initialClientModeEnabled);
    }
  }

  // Future<void> dismissAll() async {
  //   if (_currentDialog.currentContext != null) {
  //     Navigator.of(context).canPop() ? Navigator.pop(context) : null;
  //   }
  // }

  Future<void> authDialog() async {
    _showDialog(
      BaseAlertDialog(
        key: _currentDialog,
        title: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Text(
            t.authDialogTitle,
            style: TextStyle(color: colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
          ),
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Text(
                t.authDialogMessage,
                style: TextStyle(color: colours.primaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: <Widget>[
          TextButton(
            style: ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceXS)),
            ),
            child: Text(
              t.skip.toUpperCase(),
              style: TextStyle(color: colours.secondaryLight, fontSize: textSM),
            ),
            onPressed: () async {
              Navigator.of(context).canPop() ? Navigator.pop(context) : null;
            },
          ),
          TextButton(
            style: ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceXS)),
            ),
            child: Text(
              t.ok.toUpperCase(),
              style: TextStyle(color: colours.primaryPositive, fontSize: textSM),
            ),
            onPressed: () async {
              Navigator.of(context).canPop() ? Navigator.pop(context) : null;
              await showAuthDialog();
            },
          ),
        ],
      ),
      cancelable: false,
    );
  }

  Future<void> almostThereDialog() async {
    _showDialog(
      BaseAlertDialog(
        key: _currentDialog,
        title: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Text(
            t.almostThereDialogTitle,
            style: TextStyle(color: colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
          ),
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Text(
                Platform.isAndroid ? t.almostThereDialogMessageAndroid : t.almostThereDialogMessageIos,
                style: TextStyle(color: colours.primaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
              ),
              SizedBox(height: spaceMD),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      launchUrl(Uri.parse(documentationLink));
                    },
                    style: ButtonStyle(
                      alignment: Alignment.center,
                      backgroundColor: WidgetStatePropertyAll(colours.tertiaryInfo),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM), side: BorderSide.none)),
                    ),
                    icon: FaIcon(FontAwesomeIcons.solidFileLines, color: colours.secondaryDark, size: textSM),
                    // icon:
                    label: Text(
                      t.documentation.toUpperCase(),
                      style: TextStyle(color: colours.primaryDark, fontSize: textSM, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: <Widget>[
          TextButton(
            style: ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceXS)),
            ),
            child: Text(
              t.cancel.toUpperCase(),
              style: TextStyle(color: colours.secondaryLight, fontSize: textSM),
            ),
            onPressed: () async {
              Navigator.of(context).canPop() ? Navigator.pop(context) : null;
            },
          ),
          TextButton(
            style: ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceXS)),
            ),
            child: Text(
              t.ok.toUpperCase(),
              style: TextStyle(color: colours.primaryPositive, fontSize: textSM),
            ),
            onPressed: () async {
              await repoManager.setOnboardingStep(2);
              Navigator.of(context).canPop() ? Navigator.pop(context) : null;
              await authDialog();
            },
          ),
        ],
      ),
    );
  }

  Future<void> showAlmostThereOrSkip() async {
    await repoManager.setOnboardingStep(1);
    if (hasSkipped) return;
    await almostThereDialog();
  }

  Future<void> enableAllFilesDialog([bool standalone = false]) async {
    _showDialog(
      BaseAlertDialog(
        key: _currentDialog,
        title: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Text(
            t.allFilesAccessDialogTitle,
            style: TextStyle(color: colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
          ),
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Text(
                t.allFilesAccessDialogMessage,
                style: TextStyle(color: colours.primaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: <Widget>[
          FutureBuilder(
            future: requestStoragePerm(false),
            builder: (context, snapshot) => TextButton(
              style: ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceXS)),
              ),
              child: Text(
                (snapshot.data == true ? t.done : t.ok).toUpperCase(),
                style: TextStyle(color: colours.primaryPositive, fontSize: textSM),
              ),
              onPressed: () async {
                if (await requestStoragePerm()) {
                  Navigator.of(context).canPop() ? Navigator.pop(context) : null;
                  await showAlmostThereOrSkip();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> showAllFilesAccessOrNext() async {
    if (!(Platform.isIOS || await requestStoragePerm(false))) {
      await enableAllFilesDialog();
      return true;
    }

    await showAlmostThereOrSkip();
    return false;
  }

  Future<void> enableNotificationsDialog() async {
    _showDialog(
      BaseAlertDialog(
        key: _currentDialog,
        title: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Text(
            t.notificationDialogTitle,
            style: TextStyle(color: colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
          ),
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Text(
                t.notificationDialogMessage,
                style: TextStyle(color: colours.primaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: <Widget>[
          TextButton(
            style: ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceXS)),
            ),
            child: Text(
              t.skip.toUpperCase(),
              style: TextStyle(color: colours.secondaryLight, fontSize: textSM),
            ),
            onPressed: () async {
              Navigator.of(context).canPop() ? Navigator.pop(context) : null;
              await showAllFilesAccessOrNext();
            },
          ),
          FutureBuilder(
            future: Permission.notification.isGranted,
            builder: (context, snapshot) => TextButton(
              style: ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceXS)),
              ),
              child: Text(
                (snapshot.data == true ? t.done : t.ok).toUpperCase(),
                style: TextStyle(color: colours.primaryPositive, fontSize: textSM),
              ),
              onPressed: () async {
                if (await Permission.notification.request().isGranted) {
                  Navigator.of(context).canPop() ? Navigator.pop(context) : null;
                  await showAllFilesAccessOrNext();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> showNotificationsOrNext() async {
    if (!await Permission.notification.isGranted) {
      await enableNotificationsDialog();
      return true;
    } else {
      return await showAllFilesAccessOrNext();
    }
  }

  Future<void> welcomeDialog(TickerProvider tickerProvider) async {
    final buttonWidth = (MediaQuery.of(context).size.width - (spaceSM * 6)) / 3;
    final animationValue = ValueNotifier<double>(0.0);
    Future.delayed(Duration(seconds: 3), () async {
      animationValue.value = 1;
    });
    late AnimationController _controller = AnimationController(
      vsync: tickerProvider,
      duration: Duration(seconds: 2), // Animation duration
    )..forward();
    final _curvedAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _showDialog(
      BaseAlertDialog(
        key: _currentDialog,
        expandable: true,
        expanded: true,
        scrollable: false,
        titlePadding: EdgeInsets.symmetric(horizontal: spaceXXL, vertical: spaceXL),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: MediaQuery.of(context).size.width),
            Image.asset(
              'assets/app_icon.png',
              width: spaceXXL * 3, // Adjust width as needed
              height: spaceXXL * 3,
            ),
            Text(
              "Effortless File Syncing",
              textAlign: TextAlign.center,
              style: TextStyle(color: colours.primaryLight, fontSize: textXXL, fontFamily: "AtkinsonHyperlegible", fontWeight: FontWeight.bold),
            ),
          ],
        ),
        contentPadding: EdgeInsets.all(0),
        content: Stack(
          children: [
            Positioned(
              bottom: -spaceXXL * 2,
              right: 0,
              child: SizedBox(
                width: MediaQuery.of(context).size.width / 9 * 5,
                height: MediaQuery.of(context).size.height / 2,
                child: AnimatedBuilder(
                  animation: _curvedAnimation,
                  builder: (context, child) {
                    return RepaintBoundary(
                      child: CustomPaint(
                        size: Size(MediaQuery.of(context).size.width / 9 * 5, MediaQuery.of(context).size.height / 2),
                        painter: LinePainter(_curvedAnimation.value, colours.primaryLight, 100),
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: -spaceXXL * 2,
              child: SizedBox(
                width: MediaQuery.of(context).size.width / 9 * 5,
                height: MediaQuery.of(context).size.height / 2,
                child: AnimatedBuilder(
                  animation: _curvedAnimation,
                  builder: (context, child) {
                    return RepaintBoundary(
                      child: CustomPaint(
                        size: Size(MediaQuery.of(context).size.width / 9 * 5, MediaQuery.of(context).size.height / 2),
                        painter: LinePainter(_curvedAnimation.value, colours.tertiaryPositive, 100),
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              bottom: -spaceXXL,
              right: -spaceXXL,
              child: SizedBox(
                width: MediaQuery.of(context).size.width / 9 * 5,
                height: MediaQuery.of(context).size.height / 2,
                child: AnimatedBuilder(
                  animation: _curvedAnimation,
                  builder: (context, child) {
                    return RepaintBoundary(
                      child: CustomPaint(
                        size: Size(MediaQuery.of(context).size.width / 9 * 5, MediaQuery.of(context).size.height / 2),
                        painter: LinePainter(_curvedAnimation.value, colours.tertiaryNegative, 100),
                      ),
                    );
                  },
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: spaceXL),
                  width: double.infinity,
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: colours.primaryLight, fontSize: textXS * 2, fontFamily: "AtkinsonHyperlegible"),
                      children: [
                        TextSpan(
                          text: 'Works\n',
                          style: TextStyle(color: colours.tertiaryNegative, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: 'in the background,\n'),
                        TextSpan(
                          text: 'your work\n',
                          style: TextStyle(color: colours.tertiaryNegative, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: 'always in focus'),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: spaceLG),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ValueListenableBuilder(
                        valueListenable: animationValue,
                        builder: (context, animation, child) => AnimatedPositioned(
                          duration: Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                          top: -spaceXL * 1.5 * animation,
                          left: spaceXL * 2,
                          right: spaceXL * 2,
                          child: AnimatedOpacity(
                            duration: Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                            opacity: 1 * animation,
                            child: Container(
                              decoration: BoxDecoration(
                                color: colours.tertiaryDark,
                                borderRadius: BorderRadius.all(cornerRadiusMax),
                                border: BoxBorder.all(width: 2, color: colours.primaryLight),
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 100,
                                    blurStyle: BlurStyle.normal,
                                    color: colours.primaryDark,
                                    offset: Offset.zero,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              // margin: EdgeInsets.symmetric(horizontal: spaceXL * 2),
                              padding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceXXS),
                              child: Text(
                                t.welcomeSetupPrompt,
                                textAlign: TextAlign.center,

                                style: TextStyle(fontSize: textSM, color: colours.primaryLight, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // SizedBox(height: spaceMD),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: buttonWidth,
                            child: TextButton(
                              style: ButtonStyle(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceXS)),
                                backgroundColor: WidgetStatePropertyAll(colours.primaryLight),
                                shape: WidgetStatePropertyAll(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(cornerRadiusMD),
                                    side: BorderSide(width: spaceXXXS, color: colours.tertiaryDark, strokeAlign: BorderSide.strokeAlignCenter),
                                  ),
                                ),
                              ),
                              child: Text(
                                t.welcomeNeutral.toUpperCase(),
                                style: TextStyle(color: colours.tertiaryDark, fontWeight: FontWeight.bold, fontSize: textMD),
                              ),
                              onPressed: () async {
                                hasSkipped = true;
                                Navigator.of(context).canPop() ? Navigator.pop(context) : null;
                                await showNotificationsOrNext();
                              },
                            ),
                          ),
                          SizedBox(width: spaceSM),
                          SizedBox(
                            width: buttonWidth,
                            child: TextButton(
                              style: ButtonStyle(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceXS)),
                                backgroundColor: WidgetStatePropertyAll(colours.primaryLight),
                                shape: WidgetStatePropertyAll(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(cornerRadiusMD),
                                    side: BorderSide(width: spaceXXXS, color: colours.tertiaryDark, strokeAlign: BorderSide.strokeAlignCenter),
                                  ),
                                ),
                              ),
                              child: Text(
                                t.welcomeNegative.toUpperCase(),
                                style: TextStyle(color: colours.tertiaryDark, fontWeight: FontWeight.bold, fontSize: textMD),
                              ),
                              onPressed: () async {
                                hasSkipped = true;
                                await repoManager.setOnboardingStep(-1);
                                Navigator.of(context).canPop() ? Navigator.pop(context) : null;
                                await showNotificationsOrNext();
                              },
                            ),
                          ),
                          SizedBox(width: spaceSM),
                          SizedBox(
                            width: buttonWidth,
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
                                t.welcomePositive.toUpperCase(),
                                style: TextStyle(color: colours.secondaryDark, fontWeight: FontWeight.bold, fontSize: textMD),
                              ),
                              onPressed: () async {
                                Navigator.of(context).canPop() ? Navigator.pop(context) : null;
                                await showNotificationsOrNext();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // SizedBox(width: double.infinity),
              ],
            ),
          ],
        ),
        // actionsAlignment: MainAxisAlignment.end,
        // actions: <Widget>[],
      ),
    );
  }
}
