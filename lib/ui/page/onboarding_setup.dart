import 'dart:io';
import 'dart:math' as math;

import 'package:GitSync/api/helper.dart';
import 'package:GitSync/constant/icons.dart';
import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/constant/strings.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/type/git_provider.dart';
import 'package:GitSync/ui/component/https_auth_form.dart';
import 'package:GitSync/ui/component/ssh_auth_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sprintf/sprintf.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:GitSync/api/manager/auth/github_manager.dart';
import 'package:GitSync/api/manager/auth/github_app_manager.dart';
import 'package:GitSync/api/manager/auth/git_provider_manager.dart';
import 'package:GitSync/api/accessibility_service_helper.dart';
import 'package:GitSync/ui/component/auto_sync_settings.dart';
import 'package:GitSync/ui/component/scheduled_sync_settings.dart';
import 'package:GitSync/ui/component/quick_sync_settings.dart';
import 'package:GitSync/ui/dialog/prominent_disclosure.dart' as ProminentDisclosureDialog;
import 'package:GitSync/ui/page/clone_repo_main.dart';
import 'package:GitSync/ui/page/unlock_premium.dart';

class RightAngleLinePainter extends CustomPainter {
  final double animationValue;
  final Color colour;
  final double curveDimen;

  RightAngleLinePainter(this.animationValue, this.colour, [this.curveDimen = 200]);

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
  bool shouldRepaint(covariant RightAngleLinePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.colour != colour;
  }
}

class ParallelBendLinePainter extends CustomPainter {
  final double animationValue;
  final Color colour;
  final double curveDimen;

  ParallelBendLinePainter(this.animationValue, this.colour, [this.curveDimen = 400]);

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
      ..moveTo(0, size.height / 2)
      ..lineTo((size.width / 2) - curveDimen, size.height / 2)
      ..arcTo(
        Rect.fromPoints(Offset((size.width / 2) - curveDimen, size.height / 2), Offset((size.width / 2), (size.height / 2) + curveDimen)),
        -math.pi / 2,
        math.pi / 4,
        false,
      )
      ..arcTo(
        Rect.fromPoints(
          Offset((size.width / 2) + curveDimen / 4, (size.height / 2) - (curveDimen / 2) + (curveDimen / 4)),
          Offset((size.width / 2) + curveDimen * 1.25, (size.height / 2) + (curveDimen / 2) + (curveDimen / 4)),
        ),
        3 * math.pi / 4,
        -math.pi / 4,
        false,
      )
      ..lineTo(size.width, size.height / 2 + (curveDimen / 2) + (curveDimen / 4));

    final metrics = fullPath.computeMetrics().first;
    final path = metrics.extractPath(0, metrics.length * animationValue);

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ParallelBendLinePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.colour != colour;
  }
}

class GentleArchLinePainter extends CustomPainter {
  final double animationValue;
  final Color colour;
  final double curveDimen;

  GentleArchLinePainter(this.animationValue, this.colour, [this.curveDimen = 200]);

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
      ..quadraticBezierTo(size.width / 2, size.height - curveDimen, size.width, size.height);

    final metrics = fullPath.computeMetrics().first;
    final path = metrics.extractPath(0, metrics.length * animationValue);

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant GentleArchLinePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.colour != colour;
  }
}

enum Screen {
  LegacyAppUser,
  Welcome,
  ClientSyncMode,
  BrowseAndEdit,
  EnableNotifications,
  EnableAllFilesAccess,
  AlmostThere,
  Authenticate,
  SyncSettings,
}

class OnboardingSetup extends StatefulWidget {
  const OnboardingSetup({super.key, this.legacy = false});

  final legacy;

  @override
  State<OnboardingSetup> createState() => _OnboardingSetup();
}

class _OnboardingSetup extends State<OnboardingSetup> with WidgetsBindingObserver, RestorationMixin, TickerProviderStateMixin {
  late AnimationController _controller = AnimationController(vsync: this, duration: animationDuration, reverseDuration: reverseAnimationDuration)
    ..forward();
  late final Animation<double> _curvedAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut, reverseCurve: Curves.easeIn);

  late final AnimationController _wiggleController = AnimationController(vsync: this, duration: Duration(milliseconds: 400))..repeat(reverse: true);
  late final Animation<double> _wiggleAnimation = Tween<double>(
    begin: -10 * math.pi / 180,
    end: 10 * math.pi / 180,
  ).animate(CurvedAnimation(parent: _wiggleController, curve: Curves.easeInOut));

  late final buttonWidth = (MediaQuery.of(context).size.width - (spaceSM * 6)) / 3;
  final animationValue = ValueNotifier<double>(0.0);
  final screenIndex = ValueNotifier<Screen>(Screen.Welcome);
  final clientModeEnabled = ValueNotifier<bool>(false);

  final animationDuration = Duration(seconds: 2);
  final reverseAnimationDuration = Duration(milliseconds: 800);

  bool hasSkipped = false;

  final expandedProtocol = ValueNotifier<GitProvider?>(null);
  final _syncSettingsPage = ValueNotifier<int>(0);
  final _syncPageController = PageController();
  final _expandedSyncCard = ValueNotifier<int>(-1); // -1 = none expanded

  final clientSyncModeScrollController = ScrollController();

  @override
  String? get restorationId => 'onboarding_setup';

  late final _restorableCloneRepo = RestorableRouteFuture<String?>(
    onPresent: (navigator, arguments) {
      return navigator.restorablePush(createOnboardingCloneRepoMainRoute);
    },
    onComplete: (result) async {
      if (!mounted) return;
      final step = await repoManager.getInt(StorageKey.repoman_onboardingStep);
      if (step == 4) {
        screenIndex.value = Screen.SyncSettings;
      } else {
        Navigator.of(context).pop();
      }
    },
  );

  void _showCloneRepoPage() {
    _restorableCloneRepo.present();
  }

  bool _isBackNavigating = false;
  bool _notificationsScreenWasShown = false;

  Future<void> _completeOAuthAuth((String, String, String) credentials, GitProvider provider) async {
    await uiSettingsManager.setGitHttpAuthCredentials(credentials.$1, credentials.$2, credentials.$3);
    await uiSettingsManager.setStringNullable(StorageKey.setman_gitProvider, provider.name);
    await repoManager.setOnboardingStep(3);
    _showCloneRepoPage();
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    if (widget.legacy) {
      screenIndex.value = Screen.LegacyAppUser;
    } else {
      _resumeFromStep();
    }

    screenIndex.addListener(() async {
      _controller.forward();

      if (screenIndex.value == Screen.ClientSyncMode) {
        clientModeEnabled.value = await uiSettingsManager.getBoolNullable(StorageKey.setman_clientModeEnabled, true) ?? false;
        clientSyncModeScrollController.animateTo(
          clientModeEnabled.value ? 0 : clientSyncModeScrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _resumeFromStep() async {
    final step = await repoManager.getInt(StorageKey.repoman_onboardingStep);
    if (!mounted) return;
    if (step == 3) {
      _showCloneRepoPage();
    } else if (step == 4) {
      screenIndex.value = Screen.SyncSettings;
    } else if (step > 0) {
      screenIndex.value = onboardingStepToScreen(step);
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _controller.dispose();
    _wiggleController.dispose();
    _syncSettingsPage.dispose();
    _syncPageController.dispose();
    _expandedSyncCard.dispose();
    super.dispose();
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_restorableCloneRepo, clone_repo_main);
  }

  void _handleSystemBack() {
    if (_isBackNavigating) return;
    _isBackNavigating = true;

    switch (screenIndex.value) {
      case Screen.Welcome:
      case Screen.LegacyAppUser:
        _isBackNavigating = false;

      case Screen.ClientSyncMode:
        _controller.reverse().then((_) {
          if (!mounted) return;
          screenIndex.value = Screen.Welcome;
          _isBackNavigating = false;
        });

      case Screen.BrowseAndEdit:
        _controller.reverse().then((_) {
          if (!mounted) return;
          screenIndex.value = Screen.ClientSyncMode;
          _isBackNavigating = false;
        });

      case Screen.EnableNotifications:
        _controller.reverse().then((_) {
          if (!mounted) return;
          screenIndex.value = hasSkipped ? Screen.ClientSyncMode : Screen.BrowseAndEdit;
          _isBackNavigating = false;
        });

      case Screen.EnableAllFilesAccess:
        _controller.reverse().then((_) {
          if (!mounted) return;
          screenIndex.value = _notificationsScreenWasShown ? Screen.EnableNotifications : (hasSkipped ? Screen.ClientSyncMode : Screen.BrowseAndEdit);
          _isBackNavigating = false;
        });

      case Screen.AlmostThere:
        _controller.reverse().then((_) {
          if (!mounted) return;
          screenIndex.value = Screen.BrowseAndEdit;
          _isBackNavigating = false;
        });

      case Screen.Authenticate:
        if (expandedProtocol.value != null) {
          expandedProtocol.value = null;
          _isBackNavigating = false;
        } else {
          _controller.reverse().then((_) {
            if (!mounted) return;
            screenIndex.value = Screen.AlmostThere;
            _isBackNavigating = false;
          });
        }

      case Screen.SyncSettings:
        _isBackNavigating = false;
    }
  }

  Screen onboardingStepToScreen(int step) {
    switch (step) {
      case 0:
        return Screen.Welcome;
      case 1:
        return Screen.AlmostThere;
      case 2:
        return Screen.Authenticate;
      default:
        return Screen.Welcome;
    }
  }

  Widget get legacyAppUser => Stack(
    children: [
      Positioned(
        top: -spaceXXL,
        left: -spaceXXL * 2,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height / 2,
          child: Transform.flip(
            flipX: true,
            flipY: true,
            child: AnimatedBuilder(
              animation: _curvedAnimation,
              builder: (context, child) {
                return RepaintBoundary(
                  child: CustomPaint(
                    size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height / 2),
                    painter: RightAngleLinePainter(_curvedAnimation.value, colours.primaryLight, 100),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      Positioned(
        top: -spaceXXL * 2,
        left: -spaceXXL,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height / 2,
          child: Transform.flip(
            flipX: true,
            flipY: true,
            child: AnimatedBuilder(
              animation: _curvedAnimation,
              builder: (context, child) {
                return RepaintBoundary(
                  child: CustomPaint(
                    size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height / 2),
                    painter: RightAngleLinePainter(_curvedAnimation.value, colours.tertiaryNegative, 100),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      Positioned(
        top: -spaceXXL * 3,
        left: 0,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height / 2,
          child: Transform.flip(
            flipX: true,
            flipY: true,
            child: AnimatedBuilder(
              animation: _curvedAnimation,
              builder: (context, child) {
                return RepaintBoundary(
                  child: CustomPaint(
                    size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height / 2),
                    painter: RightAngleLinePainter(_curvedAnimation.value, colours.tertiaryPositive, 100),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      FadeTransition(
        opacity: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
        child: Padding(
          padding: EdgeInsets.only(top: spaceSM * 2, left: spaceMD * 2, right: spaceMD * 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: MediaQuery.of(context).size.width, height: spaceLG + spaceXXL + spaceMD),
                  Padding(
                    padding: EdgeInsets.only(right: MediaQuery.of(context).size.width / 5),
                    child: Text(
                      t.legacyAppUserDialogTitle,
                      style: TextStyle(
                        color: colours.primaryLight,
                        fontSize: textMD * 2,
                        fontFamily: "AtkinsonHyperlegible",
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 10.0, color: colours.primaryDark, offset: Offset.zero)],
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
                      style: TextStyle(
                        color: colours.primaryLight,
                        fontWeight: FontWeight.bold,
                        fontSize: textXS * 2,
                        fontFamily: "AtkinsonHyperlegible",
                      ),
                    ),
                  ),
                  SizedBox(height: spaceXL),
                  Text(
                    t.legacyAppUserDialogMessagePart2,
                    style: TextStyle(
                      color: colours.secondaryLight,
                      fontWeight: FontWeight.bold,
                      fontSize: textMD,
                      fontFamily: "AtkinsonHyperlegible",
                    ),
                  ),
                  SizedBox(height: spaceSM),
                  Text(
                    t.legacyAppUserDialogMessagePart3,
                    style: TextStyle(
                      color: colours.secondaryLight,
                      fontWeight: FontWeight.bold,
                      fontSize: textMD,
                      fontFamily: "AtkinsonHyperlegible",
                    ),
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
                            style: TextStyle(
                              color: colours.secondaryDark,
                              fontWeight: FontWeight.bold,
                              fontSize: textMD,
                              fontFamily: "AtkinsonHyperlegible",
                            ),
                          ),
                          onPressed: () async {
                            await _controller.reverse();
                            screenIndex.value = onboardingStepToScreen(await repoManager.getInt(StorageKey.repoman_onboardingStep));
                            // Future.delayed(
                            //   Duration(milliseconds: animationDuration.inMilliseconds),
                            //   () async => ,
                            // );
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
      ),
    ],
  );

  Future<void> showNotificationsOrNext() async {
    if (!await Permission.notification.isGranted) {
      _notificationsScreenWasShown = true;
      await _controller.reverse();
      screenIndex.value = Screen.EnableNotifications;
    } else {
      await showAllFilesAccessOrNext();
    }
  }

  Future<bool> showAllFilesAccessOrNext() async {
    if (!(Platform.isIOS || await requestStoragePerm(false))) {
      await _controller.reverse();
      screenIndex.value = Screen.EnableAllFilesAccess;
      return true;
    }

    await showAlmostThereOrSkip();
    return false;
  }

  Future<void> showAlmostThereOrSkip() async {
    await repoManager.setOnboardingStep(1);
    if (hasSkipped) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    await _controller.reverse();
    screenIndex.value = Screen.AlmostThere;
  }

  Widget get welcome => Stack(
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
                  painter: RightAngleLinePainter(_curvedAnimation.value, colours.tertiaryPositive, 100),
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
                  painter: RightAngleLinePainter(_curvedAnimation.value, colours.primaryLight, 100),
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
                  painter: RightAngleLinePainter(_curvedAnimation.value, colours.tertiaryNegative, 100),
                ),
              );
            },
          ),
        ),
      ),
      FadeTransition(
        opacity: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: spaceXXL, vertical: spaceXL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(width: MediaQuery.of(context).size.width, height: spaceXXL * 2.5),
                      Text(
                        "Effortless File Syncing",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colours.primaryLight,
                          fontSize: textXXL,
                          fontFamily: "AtkinsonHyperlegible",
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: spaceXL),
                  width: double.infinity,
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: colours.primaryLight, fontSize: textXS * 2, fontFamily: "AtkinsonHyperlegible"),
                      children: [
                        TextSpan(
                          text: 'Works\n',
                          style: TextStyle(color: colours.tertiaryNegative, fontWeight: FontWeight.bold, fontFamily: "AtkinsonHyperlegible"),
                        ),
                        TextSpan(text: 'in the background,\n'),
                        TextSpan(
                          text: 'your work\n',
                          style: TextStyle(color: colours.tertiaryNegative, fontWeight: FontWeight.bold, fontFamily: "AtkinsonHyperlegible"),
                        ),
                        TextSpan(text: 'always in focus'),
                      ],
                    ),
                  ),
                ),
              ],
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
                          padding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceXXS),
                          child: Text(
                            t.welcomeSetupPrompt,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: textSM,
                              color: colours.primaryLight,
                              fontWeight: FontWeight.bold,
                              fontFamily: "AtkinsonHyperlegible",
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: spaceLG),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
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
                              style: TextStyle(
                                color: colours.tertiaryDark,
                                fontWeight: FontWeight.bold,
                                fontSize: textMD,
                                fontFamily: "AtkinsonHyperlegible",
                              ),
                            ),
                            onPressed: () async {
                              hasSkipped = true;
                              await _controller.reverse();
                              screenIndex.value = Screen.ClientSyncMode;
                            },
                          ),
                        ),
                        SizedBox(width: spaceSM),
                        SizedBox(
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
                              style: TextStyle(
                                color: colours.tertiaryDark,
                                fontWeight: FontWeight.bold,
                                fontSize: textMD,
                                fontFamily: "AtkinsonHyperlegible",
                              ),
                            ),
                            onPressed: () async {
                              hasSkipped = true;
                              await repoManager.setOnboardingStep(-1);
                              await _controller.reverse();
                              screenIndex.value = Screen.ClientSyncMode;
                            },
                          ),
                        ),
                        SizedBox(width: spaceSM),
                        Expanded(
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
                              style: TextStyle(
                                color: colours.secondaryDark,
                                fontWeight: FontWeight.bold,
                                fontSize: textMD,
                                fontFamily: "AtkinsonHyperlegible",
                              ),
                            ),
                            onPressed: () async {
                              await _controller.reverse();
                              screenIndex.value = Screen.ClientSyncMode;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // SizedBox(width: double.infinity),
          ],
        ),
      ),
    ],
  );

  Widget get clientSyncMode => Stack(
    children: [
      Positioned(
        left: -spaceXXL * 2.5,
        right: 0,
        // top: spaceXXL * 2.5,
        top: -spaceXXL * 3,
        bottom: 0,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height / 2,
          child: AnimatedBuilder(
            animation: _curvedAnimation,
            builder: (context, child) {
              return RepaintBoundary(
                child: CustomPaint(
                  size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height / 2),
                  painter: ParallelBendLinePainter(_curvedAnimation.value, colours.primaryLight, 100),
                ),
              );
            },
          ),
        ),
      ),
      Positioned(
        left: -spaceXXL * 3.5,
        right: 0,
        top: -spaceXXL,
        bottom: 0,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height / 2,
          child: AnimatedBuilder(
            animation: _curvedAnimation,
            builder: (context, child) {
              return RepaintBoundary(
                child: CustomPaint(
                  size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height / 2),
                  painter: ParallelBendLinePainter(_curvedAnimation.value, colours.tertiaryNegative, 100),
                ),
              );
            },
          ),
        ),
      ),
      Positioned(
        left: -spaceXXL * 4.5,
        right: 0,
        top: spaceXXL,
        bottom: 0,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height / 2,
          child: AnimatedBuilder(
            animation: _curvedAnimation,
            builder: (context, child) {
              return RepaintBoundary(
                child: CustomPaint(
                  size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height / 2),
                  painter: ParallelBendLinePainter(_curvedAnimation.value, colours.tertiaryPositive, 100),
                ),
              );
            },
          ),
        ),
      ),
      FadeTransition(
        opacity: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
        child: Padding(
          padding: EdgeInsets.only(top: spaceSM * 2, left: spaceMD * 2, right: spaceMD * 2),
          child: ValueListenableBuilder(
            valueListenable: clientModeEnabled,
            builder: (context, isClientMode, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: MediaQuery.of(context).size.width, height: spaceLG + spaceXXL + spaceMD),
                      Text(
                        "Choose your focus",
                        style: TextStyle(
                          color: colours.primaryLight,
                          fontSize: textMD * 2,
                          fontFamily: "AtkinsonHyperlegible",
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: spaceXS),
                      Text(
                        "You can change this later in settings",
                        style: TextStyle(
                          color: colours.secondaryLight,
                          fontSize: textSM,
                          fontFamily: "AtkinsonHyperlegible",
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: spaceMD),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) => SingleChildScrollView(
                            controller: clientSyncModeScrollController,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minHeight: constraints.maxHeight),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: GestureDetector(
                                      onTap: () async {
                                        clientModeEnabled.value = true;
                                        clientSyncModeScrollController.animateTo(
                                          clientModeEnabled.value ? 0 : clientSyncModeScrollController.position.maxScrollExtent,
                                          duration: Duration(milliseconds: 200),
                                          curve: Curves.easeInOut,
                                        );
                                        await uiSettingsManager.setBoolNullable(StorageKey.setman_clientModeEnabled, true);
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.all(spaceMD).add(EdgeInsets.only(top: spaceMD)),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            AnimatedContainer(
                                              duration: Duration(milliseconds: 200),
                                              padding: EdgeInsets.only(left: spaceSM, right: spaceSM, bottom: spaceXXXS, top: spaceXS),
                                              decoration: BoxDecoration(
                                                color: isClientMode ? colours.tertiaryDark : Colors.transparent,
                                                borderRadius: BorderRadius.only(topLeft: cornerRadiusSM, topRight: cornerRadiusSM),
                                                border: BoxBorder.all(
                                                  width: spaceXS,
                                                  color: isClientMode ? colours.tertiaryDark : Colors.transparent,
                                                  strokeAlign: BorderSide.strokeAlignOutside,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  AnimatedDefaultTextStyle(
                                                    duration: Duration(milliseconds: 200),
                                                    style: TextStyle(
                                                      color: isClientMode ? colours.tertiaryInfo : colours.primaryLight,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: textXL,
                                                      fontFamily: "AtkinsonHyperlegible",
                                                    ),
                                                    child: Text("Client Mode"),
                                                  ),
                                                  SizedBox(width: spaceSM),
                                                  FaIcon(
                                                    FontAwesomeIcons.codeCompare,
                                                    color: isClientMode ? colours.tertiaryInfo : colours.secondaryLight,
                                                    size: textXL,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            AnimatedContainer(
                                              duration: Duration(milliseconds: 200),
                                              padding: EdgeInsets.only(left: spaceSM, right: spaceSM, top: spaceXS, bottom: spaceSM),
                                              decoration: BoxDecoration(
                                                color: isClientMode ? colours.tertiaryDark : Colors.transparent,
                                                borderRadius: BorderRadius.only(topLeft: cornerRadiusSM, bottomLeft: cornerRadiusSM),
                                                border: BoxBorder.all(
                                                  width: spaceXS,
                                                  color: isClientMode ? colours.tertiaryDark : Colors.transparent,
                                                  strokeAlign: BorderSide.strokeAlignOutside,
                                                ),
                                              ),
                                              child: AnimatedDefaultTextStyle(
                                                duration: Duration(milliseconds: 200),
                                                style: TextStyle(
                                                  color: isClientMode ? colours.primaryLight : colours.secondaryLight,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: textSM,
                                                  fontFamily: "AtkinsonHyperlegible",
                                                ),
                                                child: Text("Everything you would expect from a git client", textAlign: TextAlign.end),
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                _modeFeatureItem(FontAwesomeIcons.codeBranch, "Branch management", isClientMode),
                                                _modeFeatureItem(FontAwesomeIcons.arrowUpFromBracket, "Manual commit & push", isClientMode),
                                                _modeFeatureItem(FontAwesomeIcons.codePullRequest, "Diff viewer", isClientMode, false, true),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: spaceMD),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: GestureDetector(
                                      onTap: () async {
                                        clientModeEnabled.value = false;
                                        clientSyncModeScrollController.animateTo(
                                          clientModeEnabled.value ? 0 : clientSyncModeScrollController.position.maxScrollExtent,
                                          duration: Duration(milliseconds: 200),
                                          curve: Curves.easeInOut,
                                        );
                                        await uiSettingsManager.setBoolNullable(StorageKey.setman_clientModeEnabled, false);
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.all(spaceMD).add(EdgeInsets.only(bottom: spaceMD)),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            AnimatedContainer(
                                              duration: Duration(milliseconds: 200),
                                              padding: EdgeInsets.only(left: spaceSM, right: spaceSM, bottom: spaceXXXS, top: spaceXS),
                                              decoration: BoxDecoration(
                                                color: !isClientMode ? colours.tertiaryDark : Colors.transparent,
                                                borderRadius: BorderRadius.only(topLeft: cornerRadiusSM, topRight: cornerRadiusSM),
                                                border: BoxBorder.all(
                                                  width: spaceXS,
                                                  color: !isClientMode ? colours.tertiaryDark : Colors.transparent,
                                                  strokeAlign: BorderSide.strokeAlignOutside,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  FaIcon(
                                                    FontAwesomeIcons.arrowsRotate,
                                                    color: !isClientMode ? colours.tertiaryInfo : colours.secondaryLight,
                                                    size: textXL,
                                                  ),
                                                  SizedBox(width: spaceSM),
                                                  AnimatedDefaultTextStyle(
                                                    duration: Duration(milliseconds: 200),
                                                    style: TextStyle(
                                                      color: !isClientMode ? colours.tertiaryInfo : colours.primaryLight,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: textXL,
                                                      fontFamily: "AtkinsonHyperlegible",
                                                    ),
                                                    child: Text("Sync Mode"),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            AnimatedContainer(
                                              duration: Duration(milliseconds: 200),
                                              padding: EdgeInsets.only(left: spaceSM, right: spaceSM, top: spaceXS, bottom: spaceSM),
                                              decoration: BoxDecoration(
                                                color: !isClientMode ? colours.tertiaryDark : Colors.transparent,
                                                borderRadius: BorderRadius.only(topRight: cornerRadiusSM, bottomRight: cornerRadiusSM),
                                                border: BoxBorder.all(
                                                  width: spaceXS,
                                                  color: !isClientMode ? colours.tertiaryDark : Colors.transparent,
                                                  strokeAlign: BorderSide.strokeAlignOutside,
                                                ),
                                              ),
                                              child: AnimatedDefaultTextStyle(
                                                duration: Duration(milliseconds: 200),
                                                style: TextStyle(
                                                  color: !isClientMode ? colours.primaryLight : colours.secondaryLight,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: textSM,
                                                  fontFamily: "AtkinsonHyperlegible",
                                                ),
                                                child: Text("Automated file syncing in the background"),
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                _modeFeatureItem(FontAwesomeIcons.clockRotateLeft, "Auto commit & push", !isClientMode, true),
                                                _modeFeatureItem(FontAwesomeIcons.gear, "Background operation", !isClientMode, true),
                                                _modeFeatureItem(
                                                  FontAwesomeIcons.triangleExclamation,
                                                  "Easy conflict resolution",
                                                  !isClientMode,
                                                  true,
                                                  true,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    SizedBox(height: spaceLG),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          child: TextButton.icon(
                            onPressed: () async {
                              await _controller.reverse();
                              screenIndex.value = Screen.Welcome;
                            },
                            style: ButtonStyle(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceXS)),
                              backgroundColor: WidgetStatePropertyAll(colours.tertiaryInfo),
                              shape: WidgetStatePropertyAll(
                                RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
                              ),
                            ),
                            icon: FaIcon(FontAwesomeIcons.arrowLeft, color: colours.secondaryDark, size: textSM),
                            label: Text(
                              t.backLabel.toUpperCase(),
                              style: TextStyle(
                                color: colours.primaryDark,
                                fontWeight: FontWeight.bold,
                                fontSize: textMD,
                                fontFamily: "AtkinsonHyperlegible",
                              ),
                            ),
                          ),
                        ),
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
                              t.next.toUpperCase(),
                              style: TextStyle(
                                color: colours.secondaryDark,
                                fontWeight: FontWeight.bold,
                                fontSize: textMD,
                                fontFamily: "AtkinsonHyperlegible",
                              ),
                            ),
                            onPressed: () async {
                              await _controller.reverse();
                              if (hasSkipped) {
                                await showNotificationsOrNext();
                              } else {
                                screenIndex.value = Screen.BrowseAndEdit;
                              }
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
        ),
      ),
    ],
  );

  Widget get browseAndEdit => Stack(
    children: [
      Positioned(
        left: -spaceXXL * 3,
        right: -spaceXXL * 3,
        top: 0,
        bottom: -spaceXXL * 3,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height / 2,
          child: Transform.rotate(
            angle: -45 * math.pi / 180,
            child: AnimatedBuilder(
              animation: _curvedAnimation,
              builder: (context, child) {
                return RepaintBoundary(
                  child: CustomPaint(
                    size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height / 2),
                    painter: ParallelBendLinePainter(_curvedAnimation.value, colours.primaryLight, 100),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      Positioned(
        left: -spaceXXL * 2,
        right: -spaceXXL * 1.5,
        top: 0,
        bottom: -spaceXXL,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height / 2,
          child: Transform.rotate(
            angle: -45 * math.pi / 180,
            child: AnimatedBuilder(
              animation: _curvedAnimation,
              builder: (context, child) {
                return RepaintBoundary(
                  child: CustomPaint(
                    size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height / 2),
                    painter: ParallelBendLinePainter(_curvedAnimation.value, colours.tertiaryNegative, 100),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      Positioned(
        left: -spaceXXL * 2.5,
        right: -spaceXXL * 1.5,
        top: 0,
        bottom: spaceXXL,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height / 2,
          child: Transform.rotate(
            angle: -45 * math.pi / 180,
            child: AnimatedBuilder(
              animation: _curvedAnimation,
              builder: (context, child) {
                return RepaintBoundary(
                  child: CustomPaint(
                    size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height / 2),
                    painter: ParallelBendLinePainter(_curvedAnimation.value, colours.tertiaryPositive, 100),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      FadeTransition(
        opacity: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
        child: Padding(
          padding: EdgeInsets.only(top: spaceSM * 2, left: spaceMD * 2, right: spaceMD * 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: MediaQuery.of(context).size.width, height: spaceLG + spaceXXL + spaceMD),
                    Text(
                      "Browse & Edit",
                      style: TextStyle(
                        color: colours.primaryLight,
                        fontSize: textMD * 2,
                        fontFamily: "AtkinsonHyperlegible",
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: spaceXS),
                    Text(
                      "Built-in tools for your files",
                      style: TextStyle(
                        color: colours.secondaryLight,
                        fontSize: textSM,
                        fontFamily: "AtkinsonHyperlegible",
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: spaceMD),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          controller: clientSyncModeScrollController,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: constraints.maxHeight),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(right: spaceXL, top: spaceLG),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.only(left: spaceSM, right: spaceSM, bottom: spaceXXXS, top: spaceXS),
                                        decoration: BoxDecoration(
                                          color: colours.tertiaryDark,
                                          borderRadius: BorderRadius.only(topLeft: cornerRadiusSM, topRight: cornerRadiusSM),
                                          border: BoxBorder.all(
                                            width: spaceXS,
                                            color: colours.tertiaryDark,
                                            strokeAlign: BorderSide.strokeAlignOutside,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            FaIcon(FontAwesomeIcons.folderOpen, color: colours.tertiaryPositive, size: textXL),
                                            SizedBox(width: spaceSM),
                                            Text(
                                              "File Explorer",
                                              style: TextStyle(
                                                color: colours.primaryLight,
                                                fontWeight: FontWeight.bold,
                                                fontSize: textXL,
                                                fontFamily: "AtkinsonHyperlegible",
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.only(left: spaceSM, right: spaceSM, top: spaceXS, bottom: spaceSM),
                                        decoration: BoxDecoration(
                                          color: colours.tertiaryDark,
                                          borderRadius: BorderRadius.only(topRight: cornerRadiusSM, bottomRight: cornerRadiusSM),
                                          border: BoxBorder.all(
                                            width: spaceXS,
                                            color: colours.tertiaryDark,
                                            strokeAlign: BorderSide.strokeAlignOutside,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _browseFeatureItem(FontAwesomeIcons.eyeSlash, "View hidden files"),
                                            _browseFeatureItem(FontAwesomeIcons.clockRotateLeft, "View git log"),
                                            _browseFeatureItem(FontAwesomeIcons.ban, "Untrack and ignore files"),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: spaceMD),
                                // Expanded(child: SizedBox()),
                                Padding(
                                  padding: EdgeInsets.only(bottom: spaceLG),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Container(
                                              padding: EdgeInsets.only(left: spaceSM, right: spaceSM, bottom: spaceXXXS, top: spaceXS),
                                              decoration: BoxDecoration(
                                                color: colours.tertiaryDark,
                                                borderRadius: BorderRadius.only(topLeft: cornerRadiusSM, topRight: cornerRadiusSM),
                                                border: BoxBorder.all(
                                                  width: spaceXS,
                                                  color: colours.tertiaryDark,
                                                  strokeAlign: BorderSide.strokeAlignOutside,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    "Code Editor",
                                                    style: TextStyle(
                                                      color: colours.primaryLight,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: textXL,
                                                      fontFamily: "AtkinsonHyperlegible",
                                                    ),
                                                  ),
                                                  SizedBox(width: spaceSM),
                                                  FaIcon(FontAwesomeIcons.code, color: colours.tertiaryNegative, size: textXL),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.only(left: spaceSM, right: spaceSM, top: spaceXS, bottom: spaceSM),
                                              decoration: BoxDecoration(
                                                color: colours.tertiaryDark,
                                                borderRadius: BorderRadius.only(topLeft: cornerRadiusSM, bottomLeft: cornerRadiusSM),
                                                border: BoxBorder.all(
                                                  width: spaceXS,
                                                  color: colours.tertiaryDark,
                                                  strokeAlign: BorderSide.strokeAlignOutside,
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  _browseFeatureItem(FontAwesomeIcons.paintbrush, "Syntax highlighting"),
                                                  _browseFeatureItem(FontAwesomeIcons.floppyDisk, "Auto-saving"),
                                                  _browseFeatureItem(FontAwesomeIcons.flask, "Experimental feature"),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // SizedBox(height: spaceLG),
                  ],
                ),
              ),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        child: TextButton.icon(
                          onPressed: () async {
                            await _controller.reverse();
                            screenIndex.value = Screen.ClientSyncMode;
                          },
                          style: ButtonStyle(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceXS)),
                            backgroundColor: WidgetStatePropertyAll(colours.tertiaryInfo),
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
                            ),
                          ),
                          icon: FaIcon(FontAwesomeIcons.arrowLeft, color: colours.secondaryDark, size: textSM),
                          label: Text(
                            t.backLabel.toUpperCase(),
                            style: TextStyle(
                              color: colours.primaryDark,
                              fontWeight: FontWeight.bold,
                              fontSize: textMD,
                              fontFamily: "AtkinsonHyperlegible",
                            ),
                          ),
                        ),
                      ),
                      TextButton(
                        style: ButtonStyle(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceSM)),
                          backgroundColor: WidgetStatePropertyAll(colours.tertiaryPositive),
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(cornerRadiusMD),
                              side: BorderSide(width: spaceXXXS, color: colours.secondaryPositive, strokeAlign: BorderSide.strokeAlignCenter),
                            ),
                          ),
                        ),
                        child: Text(
                          "Premium Features".toUpperCase(),
                          style: TextStyle(
                            color: colours.secondaryDark,
                            fontWeight: FontWeight.bold,
                            fontSize: textMD,
                            fontFamily: "AtkinsonHyperlegible",
                          ),
                        ),
                        onPressed: () async {
                          await _controller.reverse();
                          if (context.mounted) {
                            await Navigator.of(context).push(createUnlockPremiumRoute(context, {"onboarding": true}));
                          }
                          if (mounted) {
                            await showNotificationsOrNext();
                          }
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: spaceLG),
                ],
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _modeFeatureItem(IconData icon, String text, bool isSelected, [bool right = false, bool last = false]) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      padding: EdgeInsets.only(left: spaceSM, right: spaceSM, top: spaceXS, bottom: spaceXS),
      decoration: BoxDecoration(
        color: isSelected ? colours.tertiaryDark : Colors.transparent,
        borderRadius: BorderRadius.only(
          topLeft: !right ? cornerRadiusSM : Radius.zero,
          bottomLeft: right && last || !right ? cornerRadiusSM : Radius.zero,
          topRight: right ? cornerRadiusSM : Radius.zero,
          bottomRight: !right && last || right ? cornerRadiusSM : Radius.zero,
        ),
        border: BoxBorder.all(
          width: spaceXS,
          color: isSelected ? colours.tertiaryDark : Colors.transparent,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, color: isSelected ? colours.tertiaryInfo : colours.tertiaryLight, size: textSM),
          SizedBox(width: spaceSM),
          Text(
            text,
            style: TextStyle(
              color: isSelected ? colours.primaryLight : colours.secondaryLight,
              fontSize: textSM,
              fontWeight: FontWeight.bold,
              fontFamily: "AtkinsonHyperlegible",
            ),
          ),
        ],
      ),
    );
  }

  Widget _browseFeatureItem(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: spaceXXXS),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, color: colours.tertiaryInfo, size: textSM),
          SizedBox(width: spaceSM),
          Text(
            text,
            style: TextStyle(color: colours.primaryLight, fontSize: textSM, fontWeight: FontWeight.bold, fontFamily: "AtkinsonHyperlegible"),
          ),
        ],
      ),
    );
  }

  Widget _notificationBulletItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: spaceXXXS),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "\u2022",
            style: TextStyle(color: colours.tertiaryLight, fontSize: textSM, fontWeight: FontWeight.bold, fontFamily: "AtkinsonHyperlegible"),
          ),
          SizedBox(width: spaceSM),
          Text(
            text,
            style: TextStyle(color: colours.tertiaryLight, fontSize: textSM, fontWeight: FontWeight.bold, fontFamily: "AtkinsonHyperlegible"),
          ),
        ],
      ),
    );
  }

  // Widget _almostThereCard(IconData icon, String text) {
  //   return Container(
  //     width: double.infinity,
  //     padding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceSM),
  //     decoration: BoxDecoration(color: colours.tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusMD)),
  //     child: Row(
  //       children: [
  //         FaIcon(icon, color: colours.tertiaryInfo, size: textSM),
  //         SizedBox(width: spaceSM),
  //         Expanded(
  //           child: Text(
  //             text,
  //             style: TextStyle(color: colours.primaryLight, fontSize: textSM, fontWeight: FontWeight.bold, fontFamily: "AtkinsonHyperlegible"),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget get enableNotifications => Stack(
    children: [
      Positioned(
        left: -spaceXXL,
        right: -spaceXXL,
        top: 0,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height / 2,
          child: AnimatedBuilder(
            animation: _curvedAnimation,
            builder: (context, child) {
              return RepaintBoundary(
                child: CustomPaint(
                  size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height / 2),
                  painter: GentleArchLinePainter(_curvedAnimation.value, colours.primaryLight, 200),
                ),
              );
            },
          ),
        ),
      ),
      Positioned(
        left: -spaceXXL,
        right: -spaceXXL,
        top: spaceXXL,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height / 2,
          child: AnimatedBuilder(
            animation: _curvedAnimation,
            builder: (context, child) {
              return RepaintBoundary(
                child: CustomPaint(
                  size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height / 2),
                  painter: GentleArchLinePainter(_curvedAnimation.value, colours.tertiaryNegative, 200),
                ),
              );
            },
          ),
        ),
      ),
      Positioned(
        left: -spaceXXL,
        right: -spaceXXL,
        top: spaceXXL * 2,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height / 2,
          child: AnimatedBuilder(
            animation: _curvedAnimation,
            builder: (context, child) {
              return RepaintBoundary(
                child: CustomPaint(
                  size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height / 2),
                  painter: GentleArchLinePainter(_curvedAnimation.value, colours.tertiaryPositive, 200),
                ),
              );
            },
          ),
        ),
      ),
      FadeTransition(
        opacity: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
        child: Padding(
          padding: EdgeInsets.only(top: spaceSM * 2, left: spaceMD * 2, right: spaceMD * 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: MediaQuery.of(context).size.width, height: spaceLG + spaceXXL + spaceMD),
                    Text(
                      t.notificationDialogTitle,
                      style: TextStyle(
                        color: colours.primaryLight,
                        fontSize: textMD * 2,
                        fontFamily: "AtkinsonHyperlegible",
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: spaceXS),
                    Text(
                      "Notifications keep you informed about:",
                      style: TextStyle(
                        color: colours.tertiaryLight,
                        fontSize: textSM,
                        fontFamily: "AtkinsonHyperlegible",
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: spaceSM),
                    Padding(
                      padding: EdgeInsets.only(left: spaceMD),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _notificationBulletItem("Sync status updates"),
                          _notificationBulletItem("Merge conflict alerts"),
                          _notificationBulletItem("Bug report notifications"),
                        ],
                      ),
                    ),
                    SizedBox(height: spaceSM),
                    Text(
                      "All notifications are off by default.",
                      style: TextStyle(color: colours.tertiaryLight, fontSize: textSM, fontFamily: "AtkinsonHyperlegible"),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _wiggleAnimation,
                    builder: (context, child) {
                      return Transform.rotate(angle: _wiggleAnimation.value, child: child);
                    },
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      style: ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      constraints: BoxConstraints(),
                      onPressed: () async {
                        if (await Permission.notification.request().isGranted) {
                          await showAllFilesAccessOrNext();
                        }
                      },
                      icon: FaIcon(
                        semanticLabel: "tap to grant notifications",
                        FontAwesomeIcons.solidBell,
                        color: colours.tertiaryPositive,
                        size: spaceXXL,
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () async {
                          await showAllFilesAccessOrNext();
                        },
                        style: ButtonStyle(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceXS)),
                          backgroundColor: WidgetStatePropertyAll(colours.tertiaryInfo),
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
                          ),
                        ),
                        child: Text(
                          t.skip.toUpperCase(),
                          style: TextStyle(
                            color: colours.primaryDark,
                            fontWeight: FontWeight.bold,
                            fontSize: textMD,
                            fontFamily: "AtkinsonHyperlegible",
                          ),
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
      ),
    ],
  );

  Widget get enableAllFilesAccess => Stack(
    children: [
      Positioned(
        left: -spaceXXL,
        right: -spaceXXL,
        bottom: spaceXXL,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height / 2,
          child: Transform.flip(
            flipY: true,
            child: AnimatedBuilder(
              animation: _curvedAnimation,
              builder: (context, child) {
                return RepaintBoundary(
                  child: CustomPaint(
                    size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height / 2),
                    painter: GentleArchLinePainter(_curvedAnimation.value, colours.primaryLight, 200),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      Positioned(
        left: -spaceXXL,
        right: -spaceXXL,
        bottom: spaceXXL * 2,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height / 2,
          child: Transform.flip(
            flipY: true,
            child: AnimatedBuilder(
              animation: _curvedAnimation,
              builder: (context, child) {
                return RepaintBoundary(
                  child: CustomPaint(
                    size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height / 2),
                    painter: GentleArchLinePainter(_curvedAnimation.value, colours.tertiaryNegative, 200),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      Positioned(
        left: -spaceXXL,
        right: -spaceXXL,
        bottom: spaceXXL * 3,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height / 2,
          child: Transform.flip(
            flipY: true,
            child: AnimatedBuilder(
              animation: _curvedAnimation,
              builder: (context, child) {
                return RepaintBoundary(
                  child: CustomPaint(
                    size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height / 2),
                    painter: GentleArchLinePainter(_curvedAnimation.value, colours.tertiaryPositive, 200),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      FadeTransition(
        opacity: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
        child: Padding(
          padding: EdgeInsets.only(top: spaceSM * 2, left: spaceMD * 2, right: spaceMD * 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: MediaQuery.of(context).size.width, height: spaceLG + spaceXXL + spaceMD),
                    Text(
                      t.allFilesAccessDialogTitle,
                      style: TextStyle(
                        color: colours.primaryLight,
                        fontSize: textMD * 2,
                        fontFamily: "AtkinsonHyperlegible",
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: spaceXS),
                    Text(
                      "File access is required for:",
                      style: TextStyle(
                        color: colours.tertiaryLight,
                        fontSize: textSM,
                        fontFamily: "AtkinsonHyperlegible",
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: spaceSM),
                    Padding(
                      padding: EdgeInsets.only(left: spaceMD),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _notificationBulletItem("Syncing your repository"),
                          _notificationBulletItem("Reading and writing files"),
                          _notificationBulletItem("Accessing your selected directory"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _wiggleAnimation,
                    builder: (context, child) {
                      return Transform.rotate(angle: _wiggleAnimation.value, child: child);
                    },
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      style: ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      constraints: BoxConstraints(),
                      onPressed: () async {
                        if (await requestStoragePerm()) {
                          await showAlmostThereOrSkip();
                        }
                      },
                      icon: FaIcon(
                        FontAwesomeIcons.folderOpen,
                        semanticLabel: "tap to grant file access",
                        color: colours.tertiaryPositive,
                        size: spaceXXL,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget get almostThere => Stack(
    children: [
      Positioned(
        left: -spaceXXL * 4,
        right: -spaceXXL * 2.5,
        top: spaceXXL,
        bottom: -spaceXXL * 3,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height / 2,
          child: Transform.flip(
            flipY: true,
            child: Transform.rotate(
              angle: -45 * math.pi / 180,
              child: AnimatedBuilder(
                animation: _curvedAnimation,
                builder: (context, child) {
                  return RepaintBoundary(
                    child: CustomPaint(
                      size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height / 2),
                      painter: ParallelBendLinePainter(_curvedAnimation.value, colours.primaryLight, 100),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
      Positioned(
        left: -spaceXXL * 4,
        right: -spaceXXL * 3,
        top: spaceXXL,
        bottom: -spaceXXL,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height / 2,
          child: Transform.flip(
            flipY: true,
            child: Transform.rotate(
              angle: -45 * math.pi / 180,
              child: AnimatedBuilder(
                animation: _curvedAnimation,
                builder: (context, child) {
                  return RepaintBoundary(
                    child: CustomPaint(
                      size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height / 2),
                      painter: ParallelBendLinePainter(_curvedAnimation.value, colours.tertiaryNegative, 100),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
      Positioned(
        left: -spaceXXL * 4,
        right: -spaceXXL * 3.5,
        top: spaceXXL,
        bottom: spaceXXL,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height / 2,
          child: Transform.flip(
            flipY: true,
            child: Transform.rotate(
              angle: -45 * math.pi / 180,
              child: AnimatedBuilder(
                animation: _curvedAnimation,
                builder: (context, child) {
                  return RepaintBoundary(
                    child: CustomPaint(
                      size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height / 2),
                      painter: ParallelBendLinePainter(_curvedAnimation.value, colours.tertiaryPositive, 100),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
      FadeTransition(
        opacity: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
        child: Padding(
          padding: EdgeInsets.only(top: spaceSM * 2, left: spaceMD * 2, right: spaceMD * 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: MediaQuery.of(context).size.width, height: spaceLG + spaceXXL + spaceMD),
                    Text(
                      "Almost there!",
                      style: TextStyle(
                        color: colours.primaryLight,
                        fontSize: textMD * 2,
                        fontFamily: "AtkinsonHyperlegible",
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: spaceXS),
                    Text(
                      "Here's what's next:",
                      style: TextStyle(
                        color: colours.tertiaryLight,
                        fontSize: textSM,
                        fontFamily: "AtkinsonHyperlegible",
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: spaceLG),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          controller: clientSyncModeScrollController,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: constraints.maxHeight),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceSM),
                                      margin: EdgeInsets.only(left: MediaQuery.of(context).size.width / 3),
                                      decoration: BoxDecoration(color: colours.tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusMD)),
                                      child: Row(
                                        children: [
                                          FaIcon(FontAwesomeIcons.rightToBracket, color: colours.tertiaryInfo, size: textSM),
                                          SizedBox(width: spaceSM),
                                          Expanded(
                                            child: Text(
                                              "Authenticate with your Git provider",
                                              style: TextStyle(
                                                color: colours.primaryLight,
                                                fontSize: textMD,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: "AtkinsonHyperlegible",
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: spaceXXS),
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceSM),
                                      margin: EdgeInsets.only(left: MediaQuery.of(context).size.width / 3),
                                      decoration: BoxDecoration(color: colours.tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusMD)),
                                      child: Row(
                                        children: [
                                          FaIcon(FontAwesomeIcons.codeBranch, color: colours.tertiaryInfo, size: textSM),
                                          SizedBox(width: spaceSM),
                                          Expanded(
                                            child: Text(
                                              "Clone a repository to your device",
                                              style: TextStyle(
                                                color: colours.primaryLight,
                                                fontSize: textMD,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: "AtkinsonHyperlegible",
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: spaceMD),
                                // Expanded(child: SizedBox()),
                                Column(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceSM),
                                      margin: EdgeInsets.only(right: MediaQuery.of(context).size.width / 3),
                                      decoration: BoxDecoration(color: colours.tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusMD)),
                                      child: Row(
                                        children: [
                                          FaIcon(FontAwesomeIcons.gear, color: colours.tertiaryInfo, size: textSM),
                                          SizedBox(width: spaceSM),
                                          Expanded(
                                            child: Text(
                                              "Configure your sync settings",
                                              style: TextStyle(
                                                color: colours.primaryLight,
                                                fontSize: textMD,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: "AtkinsonHyperlegible",
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: spaceXXS),
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceSM),
                                      margin: EdgeInsets.only(right: MediaQuery.of(context).size.width / 3),
                                      decoration: BoxDecoration(color: colours.tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusMD)),
                                      child: Row(
                                        children: [
                                          FaIcon(FontAwesomeIcons.solidFileLines, color: colours.tertiaryInfo, size: textSM),
                                          SizedBox(width: spaceSM),
                                          Expanded(
                                            child: Text(
                                              "Check the wiki if you need help",
                                              style: TextStyle(
                                                color: colours.primaryLight,
                                                fontSize: textMD,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: "AtkinsonHyperlegible",
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: spaceXXS),
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceSM),
                                      margin: EdgeInsets.only(right: MediaQuery.of(context).size.width / 3),
                                      decoration: BoxDecoration(color: colours.tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusMD)),
                                      child: Row(
                                        children: [
                                          FaIcon(FontAwesomeIcons.solidCircleCheck, color: colours.tertiaryInfo, size: textSM),
                                          SizedBox(width: spaceSM),
                                          Expanded(
                                            child: Text(
                                              "Then you'll be all set!",
                                              style: TextStyle(
                                                color: colours.primaryLight,
                                                fontSize: textMD,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: "AtkinsonHyperlegible",
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: spaceLG),
                  ],
                ),
              ),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        child: TextButton.icon(
                          onPressed: () async {
                            await _controller.reverse();
                            screenIndex.value = Screen.BrowseAndEdit;
                          },
                          style: ButtonStyle(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceXS)),
                            backgroundColor: WidgetStatePropertyAll(colours.tertiaryInfo),
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
                            ),
                          ),
                          icon: FaIcon(FontAwesomeIcons.arrowLeft, color: colours.secondaryDark, size: textSM),
                          label: Text(
                            t.backLabel.toUpperCase(),
                            style: TextStyle(
                              color: colours.primaryDark,
                              fontWeight: FontWeight.bold,
                              fontSize: textMD,
                              fontFamily: "AtkinsonHyperlegible",
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          SizedBox(
                            // width: MediaQuery.of(context).size.width / 3,
                            child: TextButton.icon(
                              onPressed: () async {
                                launchUrl(Uri.parse(documentationLink));
                              },
                              style: ButtonStyle(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceXS)),
                                backgroundColor: WidgetStatePropertyAll(colours.tertiaryInfo),
                                shape: WidgetStatePropertyAll(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(cornerRadiusMD),
                                    side: BorderSide(
                                      width: spaceXXXS,
                                      color: HSLColor.fromColor(colours.secondaryInfo).withLightness(0.35).toColor(),
                                      strokeAlign: BorderSide.strokeAlignCenter,
                                    ),
                                  ),
                                ),
                              ),
                              icon: FaIcon(FontAwesomeIcons.solidFileLines, color: colours.secondaryDark, size: textSM),
                              label: Text(
                                t.documentation.toUpperCase(),
                                style: TextStyle(
                                  color: colours.primaryDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: textMD,
                                  fontFamily: "AtkinsonHyperlegible",
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: spaceSM),
                          TextButton(
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
                              "setup".toUpperCase(),
                              style: TextStyle(
                                color: colours.secondaryDark,
                                fontWeight: FontWeight.bold,
                                fontSize: textMD,
                                fontFamily: "AtkinsonHyperlegible",
                              ),
                            ),
                            onPressed: () async {
                              await repoManager.setOnboardingStep(2);
                              await _controller.reverse();
                              screenIndex.value = Screen.Authenticate;
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: spaceLG),
                ],
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget get authenticate => Stack(
    children: [
      FadeTransition(
        opacity: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
        child: Padding(
          padding: EdgeInsets.only(top: spaceSM * 2, left: spaceMD * 2, right: spaceMD * 2),
          child: ValueListenableBuilder<GitProvider?>(
            valueListenable: expandedProtocol,
            builder: (context, expanded, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(width: MediaQuery.of(context).size.width, height: spaceLG + spaceXXL + spaceMD),
                  Text(
                    "Authenticate",
                    style: TextStyle(
                      color: colours.primaryLight,
                      fontSize: textMD * 2,
                      fontFamily: "AtkinsonHyperlegible",
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: spaceXS),
                  Text(
                    "Authenticate with your preferred git provider",
                    style: TextStyle(color: colours.tertiaryLight, fontSize: textSM, fontFamily: "AtkinsonHyperlegible", fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: spaceLG),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            key: ValueKey('card-list'),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedSize(
                                duration: Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                                child: SizedBox(
                                  height: expanded == null ? null : 0,
                                  child: Column(
                                    children: [
                                      Text(
                                        t.oauthProviders.toUpperCase(),
                                        style: TextStyle(
                                          color: colours.secondaryLight,
                                          fontSize: textSM,
                                          fontFamily: "AtkinsonHyperlegible",
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: spaceSM),
                                      SizedBox(
                                        width: double.infinity,
                                        child: TextButton.icon(
                                          onPressed: () async {
                                            uiSettingsManager.setBool(StorageKey.setman_githubScopedOauth, false);

                                            final gitProviderManager = GithubManager();

                                            final result = await gitProviderManager.launchOAuthFlow();

                                            if (result == null) return;

                                            await _completeOAuthAuth(result, GitProvider.GITHUB);
                                          },
                                          style: ButtonStyle(
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM)),
                                            backgroundColor: WidgetStatePropertyAll(colours.tertiaryDark),
                                            alignment: Alignment.centerLeft,
                                            shape: WidgetStatePropertyAll(
                                              RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
                                            ),
                                          ),
                                          icon: FaIcon(
                                            Platform.isIOS ? FontAwesomeIcons.gitAlt : FontAwesomeIcons.github,
                                            color: colours.primaryLight,
                                            size: textSM,
                                          ),
                                          label: Text(
                                            "GITHUB (ALL REPOS)",
                                            style: TextStyle(
                                              color: colours.primaryLight,
                                              fontSize: textMD,
                                              fontFamily: "AtkinsonHyperlegible",
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: spaceXXS),
                                      SizedBox(
                                        width: double.infinity,
                                        child: TextButton.icon(
                                          onPressed: () async {
                                            uiSettingsManager.setBool(StorageKey.setman_githubScopedOauth, true);

                                            final gitProviderManager = GithubAppManager();

                                            final result = await gitProviderManager.launchOAuthFlow();

                                            if (result == null) return;

                                            final token = await gitProviderManager.getToken(result.$3, (_, _, _) async {});
                                            if (token == null) return;

                                            final githubAppInstallations = await gitProviderManager.getGitHubAppInstallations(token);
                                            if (githubAppInstallations.isEmpty) {
                                              await launchUrl(Uri.parse(githubAppsLink));
                                            } else {
                                              await launchUrl(Uri.parse(sprintf(githubInstallationsLink, [githubAppInstallations[0]["id"]])));
                                            }

                                            await _completeOAuthAuth(result, GitProvider.GITHUB);
                                          },
                                          style: ButtonStyle(
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM)),
                                            backgroundColor: WidgetStatePropertyAll(colours.tertiaryDark),
                                            alignment: Alignment.centerLeft,
                                            shape: WidgetStatePropertyAll(
                                              RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
                                            ),
                                          ),
                                          icon: FaIcon(
                                            Platform.isIOS ? FontAwesomeIcons.gitAlt : FontAwesomeIcons.github,
                                            color: colours.primaryLight,
                                            size: textSM,
                                          ),
                                          label: Text(
                                            "GITHUB (SCOPED)",
                                            style: TextStyle(
                                              color: colours.primaryLight,
                                              fontSize: textMD,
                                              fontFamily: "AtkinsonHyperlegible",
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: spaceXXS),
                                      SizedBox(
                                        width: double.infinity,
                                        child: TextButton.icon(
                                          onPressed: () async {
                                            final gitProviderManager = GitProviderManager.getGitProviderManager(GitProvider.GITLAB, false);
                                            if (gitProviderManager == null) return;
                                            final result = await gitProviderManager.launchOAuthFlow();
                                            if (result == null) return;
                                            await _completeOAuthAuth(result, GitProvider.GITLAB);
                                          },
                                          style: ButtonStyle(
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM)),
                                            backgroundColor: WidgetStatePropertyAll(colours.tertiaryDark),
                                            alignment: Alignment.centerLeft,
                                            shape: WidgetStatePropertyAll(
                                              RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
                                            ),
                                          ),
                                          icon: FaIcon(
                                            Platform.isIOS ? FontAwesomeIcons.gitAlt : gitlab_logo,
                                            color: Platform.isIOS ? colours.primaryLight : colours.gitlabOrange,
                                            size: textSM,
                                          ),
                                          label: Text(
                                            "GITLAB",
                                            style: TextStyle(
                                              color: colours.primaryLight,
                                              fontSize: textMD,
                                              fontFamily: "AtkinsonHyperlegible",
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: spaceXXS),
                                      SizedBox(
                                        width: double.infinity,
                                        child: TextButton.icon(
                                          onPressed: () async {
                                            final gitProviderManager = GitProviderManager.getGitProviderManager(GitProvider.GITEA, false);
                                            if (gitProviderManager == null) return;
                                            final result = await gitProviderManager.launchOAuthFlow();
                                            if (result == null) return;
                                            await _completeOAuthAuth(result, GitProvider.GITEA);
                                          },
                                          style: ButtonStyle(
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM)),
                                            backgroundColor: WidgetStatePropertyAll(colours.tertiaryDark),
                                            alignment: Alignment.centerLeft,
                                            shape: WidgetStatePropertyAll(
                                              RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
                                            ),
                                          ),
                                          icon: FaIcon(
                                            Platform.isIOS ? FontAwesomeIcons.gitAlt : gitea_logo,
                                            color: Platform.isIOS ? colours.primaryLight : colours.giteaGreen,
                                            size: textSM,
                                          ),
                                          label: Text(
                                            "GITEA",
                                            style: TextStyle(
                                              color: colours.primaryLight,
                                              fontSize: textMD,
                                              fontFamily: "AtkinsonHyperlegible",
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: spaceSM),

                                      Container(
                                        height: 2,
                                        margin: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM),
                                        color: colours.tertiaryDark,
                                      ),
                                      SizedBox(height: spaceSM),
                                      Text(
                                        t.gitProtocols.toUpperCase(),
                                        style: TextStyle(
                                          color: colours.secondaryLight,
                                          fontSize: textSM,
                                          fontFamily: "AtkinsonHyperlegible",
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: spaceSM),
                                    ],
                                  ),
                                ),
                              ),
                              AnimatedSize(
                                duration: Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                                child: SizedBox(
                                  height: expanded == null || expanded == GitProvider.HTTPS ? null : 0,
                                  width: double.infinity,
                                  child: TextButton.icon(
                                    onPressed: () {
                                      expandedProtocol.value = expandedProtocol.value == GitProvider.HTTPS ? null : GitProvider.HTTPS;
                                    },
                                    style: ButtonStyle(
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM)),
                                      backgroundColor: WidgetStatePropertyAll(colours.tertiaryDark),
                                      alignment: Alignment.centerLeft,
                                      shape: WidgetStatePropertyAll(
                                        RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
                                      ),
                                    ),
                                    icon: FaIcon(
                                      FontAwesomeIcons.lock,
                                      color: colours.primaryLight,
                                      size: expanded == null || expanded == GitProvider.HTTPS ? textSM : 0,
                                    ),
                                    label: Text(
                                      "HTTPS",
                                      style: TextStyle(
                                        color: colours.primaryLight,
                                        fontSize: textMD,
                                        fontFamily: "AtkinsonHyperlegible",
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: expanded == null ? spaceXXS : 0),
                              AnimatedSize(
                                duration: Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                                child: SizedBox(
                                  height: expanded == null || expanded == GitProvider.SSH ? null : 0,
                                  width: double.infinity,
                                  child: TextButton.icon(
                                    onPressed: () {
                                      expandedProtocol.value = expandedProtocol.value == GitProvider.SSH ? null : GitProvider.SSH;
                                    },
                                    style: ButtonStyle(
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM)),
                                      backgroundColor: WidgetStatePropertyAll(colours.tertiaryDark),
                                      alignment: Alignment.centerLeft,
                                      shape: WidgetStatePropertyAll(
                                        RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
                                      ),
                                    ),
                                    icon: FaIcon(
                                      FontAwesomeIcons.terminal,
                                      color: colours.primaryLight,
                                      size: expanded == null || expanded == GitProvider.SSH ? textSM : 0,
                                    ),
                                    label: Text(
                                      "SSH",
                                      style: TextStyle(
                                        color: colours.primaryLight,
                                        fontSize: textMD,
                                        fontFamily: "AtkinsonHyperlegible",
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          expanded == null
                              ? SizedBox.shrink()
                              : expanded == GitProvider.HTTPS
                              ? Column(
                                  key: ValueKey('https-form'),
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    HttpsAuthForm(
                                      onAuthenticated: (username, token) async {
                                        await uiSettingsManager.setGitHttpAuthCredentials(username, "", token);
                                        await uiSettingsManager.setStringNullable(StorageKey.setman_gitProvider, GitProvider.HTTPS.name);
                                        await repoManager.setOnboardingStep(3);
                                        _showCloneRepoPage();
                                      },
                                    ),
                                  ],
                                )
                              : Column(
                                  key: ValueKey('ssh-form'),
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SshAuthForm(
                                      parentContext: context,
                                      onAuthenticated: (passphrase, privateKey) async {
                                        uiSettingsManager.setGitSshAuthCredentials(passphrase, privateKey);
                                        await uiSettingsManager.setStringNullable(StorageKey.setman_gitProvider, GitProvider.SSH.name);
                                        await repoManager.setOnboardingStep(3);
                                        _showCloneRepoPage();
                                      },
                                    ),
                                  ],
                                ),
                          // AnimatedSwitcher(
                          //   duration: Duration(milliseconds: 400),
                          //   switchInCurve: Curves.easeOut,
                          //   switchOutCurve: Curves.easeIn,
                          //   transitionBuilder: (child, animation) {
                          //     return FadeTransition(opacity: animation, child: child);
                          //   },
                          //   child: expanded == null
                          //       ?
                          //       : expanded == GitProvider.HTTPS
                          //       ? Column(
                          //           key: ValueKey('https-form'),
                          //           crossAxisAlignment: CrossAxisAlignment.start,
                          //           children: [
                          //             _protocolHeader(FontAwesomeIcons.lock, "HTTPS"),
                          //             HttpsAuthForm(
                          //               onAuthenticated: (username, token) async {
                          //                 await uiSettingsManager.setGitHttpAuthCredentials(username, "", token);
                          //                 await uiSettingsManager.setStringNullable(StorageKey.setman_gitProvider, GitProvider.HTTPS.name);
                          //                 await repoManager.setOnboardingStep(3);
                          //               },
                          //             ),
                          //           ],
                          //         )
                          //       : Column(
                          //           key: ValueKey('ssh-form'),
                          //           crossAxisAlignment: CrossAxisAlignment.start,
                          //           children: [
                          //             _protocolHeader(FontAwesomeIcons.terminal, "SSH"),
                          //             SshAuthForm(
                          //               parentContext: context,
                          //               onAuthenticated: (passphrase, privateKey) async {
                          //                 uiSettingsManager.setGitSshAuthCredentials(passphrase, privateKey);
                          //                 await uiSettingsManager.setStringNullable(StorageKey.setman_gitProvider, GitProvider.SSH.name);
                          //                 await repoManager.setOnboardingStep(3);
                          //               },
                          //             ),
                          //           ],
                          //         ),
                          // ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: spaceMD),
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            child: TextButton.icon(
                              onPressed: () async {
                                if (expandedProtocol.value != null) {
                                  expandedProtocol.value = null;
                                } else {
                                  await _controller.reverse();
                                  screenIndex.value = Screen.AlmostThere;
                                }
                              },
                              style: ButtonStyle(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceXS)),
                                backgroundColor: WidgetStatePropertyAll(colours.tertiaryInfo),
                                shape: WidgetStatePropertyAll(
                                  RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
                                ),
                              ),
                              icon: FaIcon(FontAwesomeIcons.arrowLeft, color: colours.secondaryDark, size: textSM),
                              label: Text(
                                t.backLabel.toUpperCase(),
                                style: TextStyle(
                                  color: colours.primaryDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: textMD,
                                  fontFamily: "AtkinsonHyperlegible",
                                ),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              await repoManager.setOnboardingStep(3);
                              _showCloneRepoPage();
                            },
                            style: ButtonStyle(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceXS)),
                              backgroundColor: WidgetStatePropertyAll(colours.tertiaryInfo),
                              shape: WidgetStatePropertyAll(
                                RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
                              ),
                            ),
                            child: Text(
                              t.skip.toUpperCase(),
                              style: TextStyle(
                                color: colours.primaryDark,
                                fontWeight: FontWeight.bold,
                                fontSize: textMD,
                                fontFamily: "AtkinsonHyperlegible",
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: spaceLG),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ],
  );

  Widget _onboardingSyncCard({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<(IconData, String)> features,
    required Widget? settingsBody,
    VoidCallback? onTap,
    Future<bool> Function(BuildContext)? onBeforeExpand,
  }) {
    return ValueListenableBuilder<int>(
      valueListenable: _expandedSyncCard,
      builder: (context, expandedIndex, _) {
        final isExpanded = expandedIndex == index;
        return GestureDetector(
          onTap: () async {
            if (onTap != null) {
              onTap();
              return;
            }
            if (onBeforeExpand != null && !isExpanded) {
              final canExpand = await onBeforeExpand(context);
              if (!canExpand) return;
            }
            _expandedSyncCard.value = isExpanded ? -1 : index;
          },
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: spaceXS),
            padding: EdgeInsets.all(spaceMD),
            decoration: BoxDecoration(
              color: colours.secondaryDark,
              borderRadius: BorderRadius.all(cornerRadiusMD),
              border: Border.all(color: colours.tertiaryDark, width: spaceXXXS),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                FaIcon(icon, color: colours.tertiaryInfo, size: textMD * 2),
                SizedBox(height: spaceSM),
                Text(
                  title,
                  style: TextStyle(color: colours.primaryLight, fontWeight: FontWeight.bold, fontSize: textMD, fontFamily: 'AtkinsonHyperlegible'),
                ),
                SizedBox(height: spaceXXXS),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(color: colours.tertiaryLight, fontSize: textSM, fontFamily: 'AtkinsonHyperlegible'),
                  ),
                SizedBox(height: spaceSM),
                Container(
                  height: spaceXXXS,
                  decoration: BoxDecoration(color: colours.tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusXS)),
                ),
                SizedBox(height: spaceSM),
                Expanded(
                  child: Stack(
                    children: [
                      AnimatedCrossFade(
                        duration: Duration(milliseconds: 200),
                        crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                        firstChild: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...features.map(
                              (f) => Padding(
                                padding: EdgeInsets.symmetric(vertical: spaceXXXS),
                                child: Row(
                                  children: [
                                    FaIcon(f.$1, color: colours.tertiaryInfo, size: textSM),
                                    SizedBox(width: spaceSM),
                                    Expanded(
                                      child: Text(
                                        f.$2,
                                        style: TextStyle(
                                          color: colours.primaryLight,
                                          fontSize: textSM,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'AtkinsonHyperlegible',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        secondChild: SingleChildScrollView(reverse: title == t.scheduledSyncSettings, child: settingsBody),
                      ),
                      AnimatedPositioned(
                        duration: Duration(milliseconds: 200),
                        bottom: isExpanded ? -spaceXXL : 0,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(color: colours.tertiaryInfo, borderRadius: BorderRadius.all(cornerRadiusMax)),
                              padding: EdgeInsets.symmetric(vertical: spaceXXS, horizontal: spaceXS),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FaIcon(
                                    settingsBody != null ? FontAwesomeIcons.chevronDown : FontAwesomeIcons.squareArrowUpRight,
                                    color: colours.tertiaryLight,
                                    size: textXS,
                                  ),
                                  SizedBox(width: spaceXXS),
                                  Text(
                                    settingsBody != null ? t.onboardingTapToConfigure : "Launch the wiki",
                                    style: TextStyle(
                                      color: colours.tertiaryLight,
                                      fontWeight: FontWeight.bold,
                                      fontSize: textXS,
                                      fontFamily: 'AtkinsonHyperlegible',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget get syncSettings {
    final syncCards = <Widget>[
      if (Platform.isAndroid)
        _onboardingSyncCard(
          index: 0,
          icon: FontAwesomeIcons.solidBell,
          title: t.enableApplicationObserver,
          subtitle: t.appSyncDescription,
          features: [
            (FontAwesomeIcons.rightToBracket, t.onboardingAppSyncFeatureOpen),
            (FontAwesomeIcons.rightFromBracket, t.onboardingAppSyncFeatureClose),
            (FontAwesomeIcons.list, t.onboardingAppSyncFeatureSelect),
          ],
          settingsBody: AutoSyncSettings(isOnboarding: true),
          onBeforeExpand: (context) async {
            if (await AccessibilityServiceHelper.isAccessibilityServiceEnabled()) {
              return true;
            }
            await ProminentDisclosureDialog.showDialog(context, () async {
              await AccessibilityServiceHelper.openAccessibilitySettings();
            });
            return await AccessibilityServiceHelper.isAccessibilityServiceEnabled();
          },
        ),
      _onboardingSyncCard(
        index: 1,
        icon: FontAwesomeIcons.clockRotateLeft,
        title: t.scheduledSyncSettings,
        subtitle: t.scheduledSyncDescription,
        features: [
          (FontAwesomeIcons.clock, t.onboardingScheduledSyncFeatureFreq),
          (FontAwesomeIcons.sliders, t.onboardingScheduledSyncFeatureCustom),
          (FontAwesomeIcons.gear, t.onboardingScheduledSyncFeatureBg),
        ],
        settingsBody: ScheduledSyncSettings(isOnboarding: true),
      ),
      _onboardingSyncCard(
        index: 2,
        icon: FontAwesomeIcons.barsStaggered,
        title: t.quickSyncSettings,
        subtitle: t.quickSyncDescription,
        features: [
          (FontAwesomeIcons.tableCells, t.onboardingQuickSyncFeatureTile),
          (FontAwesomeIcons.bolt, t.onboardingQuickSyncFeatureShortcut),
          (FontAwesomeIcons.tableColumns, t.onboardingQuickSyncFeatureWidget),
        ],
        settingsBody: QuickSyncSettings(isOnboarding: true),
      ),
      _onboardingSyncCard(
        index: 3,
        icon: FontAwesomeIcons.ellipsis,
        title: t.otherSyncSettings,
        subtitle: t.onboardingOtherSyncDescription,
        features: [(FontAwesomeIcons.android, t.onboardingOtherSyncFeatureAndroid), (FontAwesomeIcons.apple, t.onboardingOtherSyncFeatureIos)],
        settingsBody: null,
        onTap: () => launchUrl(Uri.parse(syncOptionsDocsLink)),
      ),
    ];

    return Stack(
      children: [
        Positioned(
          left: 0,
          right: -spaceXXL * 3.5,
          top: spaceXXL * 0.2,
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height / 2,
            child: Transform.flip(
              flipY: true,
              child: AnimatedBuilder(
                animation: _curvedAnimation,
                builder: (context, child) {
                  return RepaintBoundary(
                    child: CustomPaint(
                      size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height / 2),
                      painter: ParallelBendLinePainter(_curvedAnimation.value, colours.primaryLight, 100),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: -spaceXXL * 4.5,
          top: spaceXXL * 1.2,
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height / 2,
            child: Transform.flip(
              flipY: true,
              child: AnimatedBuilder(
                animation: _curvedAnimation,
                builder: (context, child) {
                  return RepaintBoundary(
                    child: CustomPaint(
                      size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height / 2),
                      painter: ParallelBendLinePainter(_curvedAnimation.value, colours.tertiaryNegative, 100),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: -spaceXXL * 5.5,
          top: spaceXXL * 2.2,
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height / 2,
            child: Transform.flip(
              flipY: true,
              child: AnimatedBuilder(
                animation: _curvedAnimation,
                builder: (context, child) {
                  return RepaintBoundary(
                    child: CustomPaint(
                      size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height / 2),
                      painter: ParallelBendLinePainter(_curvedAnimation.value, colours.tertiaryPositive, 100),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        FadeTransition(
          opacity: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
          child: Padding(
            padding: EdgeInsets.only(top: spaceSM * 2, left: spaceMD * 2, right: spaceMD * 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: MediaQuery.of(context).size.width, height: spaceLG + spaceXXL + spaceMD),
                      Text(
                        t.onboardingSyncSettingsTitle,
                        style: TextStyle(
                          color: colours.primaryLight,
                          fontSize: textMD * 2,
                          fontFamily: "AtkinsonHyperlegible",
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: spaceXS),
                      Text(
                        t.onboardingSyncSettingsSubtitle,
                        style: TextStyle(
                          color: colours.tertiaryLight,
                          fontSize: textSM,
                          fontFamily: "AtkinsonHyperlegible",
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).viewInsets.bottom != 0 ? spaceLG : spaceLG * 3.5),
                      Expanded(
                        child: ValueListenableBuilder<int>(
                          valueListenable: _syncSettingsPage,
                          builder: (context, currentPage, _) => Column(
                            children: [
                              Expanded(
                                child: PageView(
                                  controller: _syncPageController,
                                  onPageChanged: (index) {
                                    _syncSettingsPage.value = index;
                                    _expandedSyncCard.value = -1;
                                  },
                                  children: syncCards,
                                ),
                              ),
                              SizedBox(height: spaceSM),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(syncCards.length, (index) {
                                  final isActive = currentPage == index;
                                  return AnimatedContainer(
                                    duration: Duration(milliseconds: 200),
                                    margin: EdgeInsets.symmetric(horizontal: spaceXXXS),
                                    width: spaceXS,
                                    height: spaceXS,
                                    decoration: BoxDecoration(
                                      color: isActive ? colours.tertiaryInfo : colours.tertiaryInfo.withValues(alpha: 0.3),
                                      shape: BoxShape.circle,
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: spaceLG),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          style: ButtonStyle(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceXS)),
                            backgroundColor: WidgetStatePropertyAll(colours.tertiaryInfo),
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
                            ),
                          ),
                          child: Text(
                            t.skip.toUpperCase(),
                            style: TextStyle(
                              color: colours.primaryDark,
                              fontWeight: FontWeight.bold,
                              fontSize: textMD,
                              fontFamily: "AtkinsonHyperlegible",
                            ),
                          ),
                          onPressed: () async {
                            await repoManager.setOnboardingStep(5);
                            if (mounted) Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
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
                            t.done.toUpperCase(),
                            style: TextStyle(
                              color: colours.secondaryDark,
                              fontWeight: FontWeight.bold,
                              fontSize: textMD,
                              fontFamily: "AtkinsonHyperlegible",
                            ),
                          ),
                          onPressed: () async {
                            await repoManager.setOnboardingStep(5);
                            if (mounted) Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: spaceLG),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: screenIndex,
      builder: (context, screenIndexValue, _) {
        final isEntryScreen = screenIndexValue == Screen.Welcome || screenIndexValue == Screen.LegacyAppUser;
        Widget child = welcome;
        switch (screenIndexValue) {
          case Screen.LegacyAppUser:
            child = legacyAppUser;
          case Screen.Welcome:
            child = welcome;
          case Screen.ClientSyncMode:
            child = clientSyncMode;
          case Screen.BrowseAndEdit:
            child = browseAndEdit;
          case Screen.EnableNotifications:
            child = enableNotifications;
          case Screen.EnableAllFilesAccess:
            child = enableAllFilesAccess;
          case Screen.AlmostThere:
            child = almostThere;
          case Screen.Authenticate:
            child = authenticate;
          case Screen.SyncSettings:
            child = syncSettings;
        }
        return PopScope(
          canPop: isEntryScreen,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _handleSystemBack();
          },
          child: Scaffold(
            backgroundColor: colours.primaryDark,
            body: AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle.light.copyWith(
                statusBarColor: colours.primaryDark,
                systemNavigationBarColor: colours.primaryDark,
                statusBarIconBrightness: Brightness.light,
                systemNavigationBarIconBrightness: Brightness.light,
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    top: spaceSM * 2 + spaceLG,
                    left: screenIndexValue == Screen.Welcome ? 1 : spaceMD * 2,
                    right: screenIndexValue == Screen.Welcome ? 1 : MediaQuery.of(context).size.width - spaceXXL - (spaceMD * 2),
                    child: Center(
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                        width: screenIndexValue == Screen.Welcome ? spaceXXL * 2.5 : spaceXXL,
                        height: screenIndexValue == Screen.Welcome ? spaceXXL * 2.5 : spaceXXL,
                        child: Image.asset('assets/app_icon.png', fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  child,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

@pragma('vm:entry-point')
Route<String?> createOnboardingSetupRoute(BuildContext context, Object? args) {
  (args as Map<dynamic, dynamic>);

  return PageRouteBuilder(
    settings: const RouteSettings(name: onboarding_setup),
    pageBuilder: (context, animation, secondaryAnimation) => OnboardingSetup(legacy: args["legacy"] ?? false),
    transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
  );
}
