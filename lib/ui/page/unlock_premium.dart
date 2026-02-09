import 'dart:io';

import 'package:GitSync/constant/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:GitSync/global.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sprintf/sprintf.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../constant/dimens.dart';
import 'package:GitSync/api/manager/auth/github_manager.dart';
import 'package:GitSync/api/manager/storage.dart';

const double _featureCardHeight =
    spaceXXXS * 2 +
    spaceSM * 2 +
    textXS * 1.5 +
    spaceMD +
    spaceLG +
    spaceXXXS * 4 +
    textSM * 1.5 +
    spaceMD +
    textXL * 1.5 +
    spaceSM +
    textSM * 1.5 +
    5 * (spaceXXXS * 2 + textMD * 1.5);

class UnlockPremium extends StatefulWidget {
  const UnlockPremium({super.key, this.onboarding = false});
  final bool onboarding;
  @override
  State<UnlockPremium> createState() => _UnlockPremiumState();
}

class _UnlockPremiumState extends State<UnlockPremium> {
  final pageController = PageController();
  int currentPage = 0;
  final price = "\$15.00";

  Widget _featureRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: spaceXXXS),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, color: colours.premiumAccent, size: textMD),
          SizedBox(width: spaceSM),
          Text(
            text,
            style: TextStyle(color: colours.primaryLight, fontSize: textSM, fontWeight: FontWeight.bold, fontFamily: 'AtkinsonHyperlegible'),
          ),
        ],
      ),
    );
  }

  Widget _featureCard({
    required List<Widget> badgeIcons,
    required String badgeLabel,
    required String title,
    required String subtitle,
    required List<Widget> featureRows,
    String? tag,
    bool showStoreBanner = false,
  }) {
    final double dimOpacity = showStoreBanner ? 0.4 : 1.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: spaceXS),
      decoration: BoxDecoration(
        color: colours.premiumSurface,
        borderRadius: BorderRadius.all(cornerRadiusMD),
        border: Border.all(color: colours.premiumBorder, width: spaceXXXS),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          if (showStoreBanner) ...[
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => launchUrl(Uri.parse("https://play.google.com/store/apps/details?id=com.viscouspot.gitsync")),
                style: ButtonStyle(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM)),
                  visualDensity: VisualDensity.compact,
                  shape: WidgetStatePropertyAll(RoundedRectangleBorder()),
                  backgroundColor: WidgetStatePropertyAll(colours.premiumBorder),
                ),

                icon: FaIcon(FontAwesomeIcons.store, color: colours.premiumAccent, size: textXS),
                label: Text(
                  "Exclusive Features: Store Version Only!",
                  style: TextStyle(color: colours.premiumAccent, fontSize: textXS, fontWeight: FontWeight.w900, fontFamily: 'AtkinsonHyperlegible'),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(height: spaceMD),
          ],
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: spaceLG, right: spaceLG, bottom: spaceLG, top: showStoreBanner ? 0 : spaceLG),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Opacity(
                    opacity: dimOpacity,
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: spaceXXXS, vertical: spaceXXXS),
                          decoration: BoxDecoration(
                            color: colours.premiumBg,
                            borderRadius: BorderRadius.all(cornerRadiusMax),
                            border: Border.all(color: colours.premiumBorder, width: spaceXXXS),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: spaceXS, vertical: spaceXXXS),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ...badgeIcons.expand((icon) => [icon, SizedBox(width: spaceXXS)]),
                                    SizedBox(width: spaceXS),
                                    Text(
                                      badgeLabel.toUpperCase(),
                                      style: TextStyle(color: colours.premiumAccent, fontSize: textXS, fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                              ),
                              if (tag != null) ...[
                                SizedBox(width: spaceXXS),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: spaceXS, vertical: spaceXXXS),
                                  decoration: BoxDecoration(color: colours.premiumAccent, borderRadius: BorderRadius.all(cornerRadiusMax)),
                                  child: Text(
                                    tag.toUpperCase(),
                                    style: TextStyle(color: colours.premiumBg, fontSize: textXS, fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(height: spaceMD),
                        Text(
                          title,
                          style: TextStyle(
                            color: colours.primaryLight,
                            fontSize: textXL,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'AtkinsonHyperlegible',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: spaceSM),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: colours.premiumTextSecondary,
                            fontSize: textSM,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'AtkinsonHyperlegible',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Opacity(
                      opacity: dimOpacity,
                      child: SingleChildScrollView(child: Column(children: featureRows)),
                    ),
                  ),
                  SizedBox.shrink(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyGhSponsor() async {
    final result = await GithubManager().launchOAuthFlow(["user", "user:email"]);
    if (result == null) return;

    await repoManager.setStringNullable(StorageKey.repoman_ghSponsorToken, result.$3);
    await premiumManager.updateGitHubSponsorPremium();
    if (mounted && premiumManager.hasPremiumNotifier.value == true) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      _featureCard(
        badgeIcons: [
          FaIcon(FontAwesomeIcons.solidSquarePlus, color: colours.premiumAccent, size: textSM),
          FaIcon(FontAwesomeIcons.solidSquareMinus, color: colours.tertiaryNegative, size: textSM),
          FaIcon(FontAwesomeIcons.squarePen, color: colours.tertiaryInfo, size: textSM),
        ],
        badgeLabel: t.addMore,
        title: t.premiumMultiRepoTitle,
        subtitle: t.premiumMultiRepoSubtitle,
        featureRows: [
          _featureRow(FontAwesomeIcons.solidCircleCheck, t.premiumUnlimitedContainers),
          _featureRow(FontAwesomeIcons.key, t.premiumIndependentAuth),
          _featureRow(FontAwesomeIcons.folderTree, t.premiumAutoAddSubmodules),
        ],
      ),

      if (Platform.isIOS)
        _featureCard(
          showStoreBanner: true,
          badgeIcons: [
            FaIcon(FontAwesomeIcons.solidBell, color: colours.tertiaryInfo, size: textSM),
            FaIcon(FontAwesomeIcons.server, color: colours.tertiaryInfo, size: textSM),
          ],
          badgeLabel: "ESS",
          tag: "ios-only",
          title: t.enhancedScheduledSync,
          subtitle: t.premiumEnhancedSyncSubtitle,
          featureRows: [
            _featureRow(FontAwesomeIcons.arrowsRotate, t.premiumSyncPerMinute),
            _featureRow(FontAwesomeIcons.server, t.premiumServerTriggered),
            _featureRow(FontAwesomeIcons.batteryFull, t.premiumWorksAppClosed),
            _featureRow(FontAwesomeIcons.solidClock, t.premiumReliableDelivery),
          ],
        ),

      _featureCard(
        showStoreBanner: true,
        badgeIcons: [
          FaIcon(FontAwesomeIcons.fileArrowUp, color: colours.tertiaryWarning, size: textSM),
          FaIcon(FontAwesomeIcons.fileArrowDown, color: colours.tertiaryInfo, size: textSM),
        ],
        badgeLabel: "LARGE FILES",
        title: t.premiumGitLfsTitle,
        subtitle: t.premiumGitLfsSubtitle,
        featureRows: [
          _featureRow(FontAwesomeIcons.solidCircleCheck, t.premiumFullLfsSupport),
          _featureRow(FontAwesomeIcons.fileCirclePlus, t.premiumTrackLargeFiles),

          _featureRow(FontAwesomeIcons.download, t.premiumAutoLfsPullPush),
        ],
      ),

      _featureCard(
        showStoreBanner: true,
        badgeIcons: [FaIcon(FontAwesomeIcons.filter, color: colours.premiumAccent, size: textSM)],
        badgeLabel: "FILTERS",
        title: t.premiumGitFiltersTitle,
        subtitle: t.premiumGitFiltersSubtitle,
        featureRows: [
          _featureRow(FontAwesomeIcons.solidCircleCheck, t.premiumGitLfsFilter),
          _featureRow(FontAwesomeIcons.lock, t.premiumGitCryptFilter),
          _featureRow(FontAwesomeIcons.wandMagicSparkles, t.premiumMoreFiltersSoon),
        ],
      ),

      // _featureCard(
      //   showStoreBanner: true,
      //   badgeIcons: [
      //     FaIcon(FontAwesomeIcons.codeCommit, color: colours.premiumAccent, size: textSM),
      //   ],
      //   badgeLabel: "HOOKS",
      //   title: t.premiumGitHooksTitle,
      //   subtitle: t.premiumGitHooksSubtitle,
      //   featureRows: [
      //     _featureRow(FontAwesomeIcons.magnifyingGlass, t.premiumHookTrailingWhitespace),
      //     _featureRow(FontAwesomeIcons.solidFileLines, t.premiumHookEndOfFileFixer),
      //     _featureRow(FontAwesomeIcons.code, t.premiumHookCheckYamlJson),
      //     _featureRow(FontAwesomeIcons.textSlash, t.premiumHookMixedLineEnding),
      //     _featureRow(FontAwesomeIcons.fileShield, t.premiumHookDetectPrivateKey),
      //   ],
      // ),
    ];

    return Scaffold(
      backgroundColor: colours.premiumBg,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: colours.premiumBg,
          systemNavigationBarColor: colours.premiumBg,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(left: spaceXL, right: spaceXL, top: spaceXL, bottom: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: spaceXL,
                      height: spaceXL,
                      decoration: BoxDecoration(
                        border: BoxBorder.all(width: spaceXXXS, color: colours.premiumAccent, strokeAlign: BorderSide.strokeAlignOutside),
                        shape: BoxShape.circle,
                        color: Colors.white,
                        image: DecorationImage(fit: BoxFit.fill, image: AssetImage('assets/app_icon.png')),
                      ),
                    ),
                    SizedBox(height: spaceLG),
                    Row(
                      children: [
                        FaIcon(FontAwesomeIcons.solidGem, color: colours.premiumAccent, size: textLG * 2),
                        SizedBox(width: spaceSM),
                        Text(
                          "Premium",
                          style: TextStyle(color: colours.primaryLight, fontSize: textLG * 2, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Column(
                          children: [
                            SizedBox(height: spaceLG),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: spaceLG, vertical: spaceMD),
                              child: SizedBox(
                                height: _featureCardHeight,
                                child: PageView(
                                  controller: pageController,
                                  onPageChanged: (index) {
                                    setState(() {
                                      currentPage = index;
                                    });
                                  },
                                  children: cards,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(bottom: spaceXL),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(cards.length, (index) {
                                  final isActive = currentPage == index;
                                  return AnimatedContainer(
                                    duration: Duration(milliseconds: 200),
                                    margin: EdgeInsets.symmetric(horizontal: spaceXXXS),
                                    width: spaceXS,
                                    height: spaceXS,
                                    decoration: BoxDecoration(
                                      color: isActive ? colours.premiumAccent : colours.premiumAccent.withValues(alpha: 0.3),
                                      shape: BoxShape.circle,
                                    ),
                                  );
                                }),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(bottom: spaceSM, left: spaceMD, right: spaceMD),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextButton(
                                    style: ButtonStyle(
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceXS)),
                                      backgroundColor: WidgetStatePropertyAll(colours.premiumAccent),
                                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD))),
                                    ),
                                    child: Text(
                                      sprintf("purchase now — %s", [price]).toUpperCase(),
                                      style: TextStyle(color: colours.premiumBg, fontWeight: FontWeight.bold, fontSize: textMD),
                                    ),
                                    onPressed: () async {
                                      await launchUrl(Uri.parse(contributeLink));
                                      if (context.mounted) {
                                        await _verifyGhSponsor();
                                      }
                                    },
                                  ),
                                  SizedBox(height: spaceMD),
                                  Stack(
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: TextButton(
                                          style: ButtonStyle(
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceXS)),
                                            backgroundColor: WidgetStatePropertyAll(colours.premiumSurface),
                                            shape: WidgetStatePropertyAll(
                                              RoundedRectangleBorder(
                                                borderRadius: BorderRadius.all(cornerRadiusMD),
                                                side: BorderSide(
                                                  width: spaceXXXS,
                                                  color: colours.premiumBorder,
                                                  strokeAlign: BorderSide.strokeAlignCenter,
                                                ),
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            t.restorePurchase.toUpperCase(),
                                            style: TextStyle(color: colours.premiumTextSecondary, fontWeight: FontWeight.bold, fontSize: textMD),
                                          ),
                                          onPressed: () async {
                                            await _verifyGhSponsor();
                                          },
                                        ),
                                      ),
                                      // Positioned(
                                      //   right: 0,
                                      //   top: 0,
                                      //   bottom: 0,
                                      //   child: IconButton(
                                      //     padding: EdgeInsets.zero,
                                      //     style: ButtonStyle(
                                      //       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      //       padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceSM)),
                                      //       backgroundColor: WidgetStatePropertyAll(colours.premiumAccent),
                                      //       shape: WidgetStatePropertyAll(
                                      //         RoundedRectangleBorder(
                                      //           borderRadius: BorderRadius.all(cornerRadiusMD),
                                      //           side: BorderSide(width: spaceXXXS, color: colours.premiumAccent, strokeAlign: BorderSide.strokeAlignCenter),
                                      //         ),
                                      //       ),
                                      //     ),
                                      //     constraints: BoxConstraints(),
                                      //     onPressed: () async {
                                      //       await _verifyGhSponsor();
                                      //     },
                                      //     icon: Row(
                                      //       crossAxisAlignment: CrossAxisAlignment.center,
                                      //       children: [
                                      //         Column(
                                      //           mainAxisAlignment: MainAxisAlignment.center,
                                      //           crossAxisAlignment: CrossAxisAlignment.end,
                                      //           children: [
                                      //             Text(
                                      //               "github".toUpperCase(),
                                      //               maxLines: 1,
                                      //               textAlign: TextAlign.center,
                                      //               style: TextStyle(color: colours.premiumBg, fontWeight: FontWeight.w900, fontSize: textXS, height: 1),
                                      //             ),
                                      //             SizedBox(height: spaceXXXXS),
                                      //             Text(
                                      //               "sponsors".toUpperCase(),
                                      //               maxLines: 1,
                                      //               textAlign: TextAlign.center,
                                      //               style: TextStyle(color: colours.premiumBg, fontWeight: FontWeight.w900, fontSize: textXS, height: 1),
                                      //             ),
                                      //           ],
                                      //         ),
                                      //         SizedBox(width: spaceXS),
                                      //         FaIcon(FontAwesomeIcons.github, color: colours.premiumBg),
                                      //       ],
                                      //     ),
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                  // SizedBox(height: spaceMD),
                                  // TextButton(
                                  //   style: ButtonStyle(
                                  //     tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  //     padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceXS)),
                                  //     backgroundColor: WidgetStatePropertyAll(colours.premiumSurface),
                                  //     shape: WidgetStatePropertyAll(
                                  //       RoundedRectangleBorder(
                                  //         borderRadius: BorderRadius.all(cornerRadiusMD),
                                  //         side: BorderSide(width: spaceXXXS, color: colours.premiumBorder, strokeAlign: BorderSide.strokeAlignCenter),
                                  //       ),
                                  //     ),
                                  //   ),
                                  //   child: Text(
                                  //     "enterprise".toUpperCase(),
                                  //     style: TextStyle(color: colours.premiumTextSecondary, fontWeight: FontWeight.bold, fontSize: textMD),
                                  //   ),
                                  //   onPressed: () async {},
                                  // ),
                                  if (widget.onboarding) ...[
                                    SizedBox(height: spaceMD),
                                    TextButton(
                                      style: ButtonStyle(
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceXS)),
                                        backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                                        shape: WidgetStatePropertyAll(
                                          RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(cornerRadiusMD),
                                            side: BorderSide(
                                              width: spaceXXXS,
                                              color: colours.premiumBorder,
                                              strokeAlign: BorderSide.strokeAlignCenter,
                                            ),
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        t.skip.toUpperCase(),
                                        style: TextStyle(color: colours.premiumTextSecondary, fontWeight: FontWeight.bold, fontSize: textMD),
                                      ),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                  SizedBox(height: spaceSM),
                                  Text(
                                    "Purchased via GitHub Sponsors · may take up to 1 day to activate\nRestore Purchase · sign in with GitHub to verify sponsor status\nEnterprise · volume licensing and custom billing for teams",
                                    style: TextStyle(color: colours.premiumTextSecondary, fontSize: textXXS, fontFamily: 'AtkinsonHyperlegible'),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@pragma('vm:entry-point')
Route<bool?> createUnlockPremiumRoute(BuildContext context, Object? args) {
  (args as Map<dynamic, dynamic>);
  return PageRouteBuilder(
    settings: const RouteSettings(name: unlock_premium),
    pageBuilder: (context, animation, secondaryAnimation) => UnlockPremium(onboarding: args["onboarding"] ?? false),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      const curve = Curves.ease;
      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}
