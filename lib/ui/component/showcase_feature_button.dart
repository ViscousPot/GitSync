import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/type/git_provider.dart';
import 'package:GitSync/type/showcase_feature.dart';
import 'package:GitSync/ui/page/issues_page.dart';
import 'package:GitSync/ui/page/pull_requests_page.dart';
import 'package:GitSync/ui/page/releases_page.dart';
import 'package:GitSync/ui/page/actions_page.dart';
import 'package:GitSync/ui/page/tags_page.dart';
import 'package:GitSync/ui/page/create_issue_page.dart';
import 'package:GitSync/ui/page/create_pr_page.dart';

class ShowcaseFeatureButton extends StatelessWidget {
  const ShowcaseFeatureButton({
    super.key,
    required this.feature,
    required this.onPressed,
    this.onPinToggle,
    this.isPinned = false,
    this.onAdd,
    this.gitProvider,
  });

  final ShowcaseFeature feature;
  final VoidCallback onPressed;
  final VoidCallback? onPinToggle;
  final bool isPinned;
  final VoidCallback? onAdd;
  final GitProvider? gitProvider;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: onPressed,
            icon: FaIcon(feature.icon, color: colours.showcaseFeatureIcon, size: textMD),
            label: SizedBox(
              width: double.infinity,
              child: Text(
                feature.labelForProvider(gitProvider),
                style: TextStyle(color: colours.showcaseFeatureIcon, fontSize: textSM, fontWeight: FontWeight.bold),
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: colours.showcaseBg,
              padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceXS),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(cornerRadiusSM),
                side: BorderSide(color: colours.showcaseBorder, width: spaceXXXXS),
              ),
            ),
          ),
        ),
        if (onPinToggle != null)
          Positioned(
            left: -spaceXXXS,
            top: -spaceXXXS,
            child: GestureDetector(
              onTap: onPinToggle,
              child: Container(
                width: spaceMD,
                height: spaceMD,
                decoration: BoxDecoration(color: isPinned ? colours.primaryLight : colours.tertiaryDark, shape: BoxShape.circle),
                child: Center(
                  child: Transform.rotate(
                    angle: 0.785398,
                    child: FaIcon(FontAwesomeIcons.thumbtack, color: isPinned ? colours.primaryDark : colours.tertiaryLight, size: textXXS),
                  ),
                ),
              ),
            ),
          ),
        if (onAdd != null)
          Positioned(
            right: 0,
            top: spaceXXS,
            bottom: spaceXXS,
            child: AspectRatio(
              aspectRatio: 1,
              child: TextButton(
                onPressed: onAdd,
                style: TextButton.styleFrom(
                  backgroundColor: colours.showcaseBorder,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM)),
                ),
                child: FaIcon(FontAwesomeIcons.plus, color: colours.showcaseFeatureIcon, size: textSM),
              ),
            ),
          ),
      ],
    );
  }
}

/// Returns an updated pinned list after toggling [feature], or null if the toggle is rejected.
/// - Unpinning with only 1 pinned: rejected (returns null)
/// - Pinning with 2 already pinned: evicts the oldest (first in list)
List<ShowcaseFeature>? togglePin(List<ShowcaseFeature> current, ShowcaseFeature feature) {
  final pinned = List<ShowcaseFeature>.of(current);

  if (pinned.contains(feature)) {
    if (pinned.length <= 1) return null;
    pinned.remove(feature);
  } else {
    if (pinned.length >= 2) {
      pinned.removeAt(0);
    }
    pinned.add(feature);
  }

  return pinned;
}

/// Returns a callback for the add button on a [ShowcaseFeature], or null if not supported.
VoidCallback? resolveFeatureOnAdd({
  required BuildContext context,
  required ShowcaseFeature feature,
  required GitProvider? gitProvider,
  required String? remoteWebUrl,
}) {
  if (feature != ShowcaseFeature.issues && feature != ShowcaseFeature.pullRequests) return null;
  return () async {
    if (remoteWebUrl == null || gitProvider == null) return;
    final githubAppOauth = await uiSettingsManager.getBool(StorageKey.setman_githubScopedOauth);
    final accessToken = (await uiSettingsManager.getGitHttpAuthCredentials()).$2;
    if (!context.mounted) return;
    if (feature == ShowcaseFeature.issues) {
      Navigator.of(context).push(createCreateIssuePageRoute(
        gitProvider: gitProvider,
        remoteWebUrl: remoteWebUrl,
        accessToken: accessToken,
        githubAppOauth: githubAppOauth,
      ));
    } else {
      Navigator.of(context).push(createCreatePrPageRoute(
        gitProvider: gitProvider,
        remoteWebUrl: remoteWebUrl,
        accessToken: accessToken,
        githubAppOauth: githubAppOauth,
      ));
    }
  };
}

/// Maps a [ShowcaseFeature] to its navigation callback.
VoidCallback resolveFeatureOnPressed({
  required BuildContext context,
  required ShowcaseFeature feature,
  required GitProvider? gitProvider,
  required String? remoteWebUrl,
}) {
  return () async {
    if (remoteWebUrl == null || gitProvider == null) return;
    final githubAppOauth = await uiSettingsManager.getBool(StorageKey.setman_githubScopedOauth);
    final accessToken = (await uiSettingsManager.getGitHttpAuthCredentials()).$2;
    if (!context.mounted) return;

    switch (feature) {
      case ShowcaseFeature.issues:
        Navigator.of(
          context,
        ).push(createIssuesPageRoute(gitProvider: gitProvider, remoteWebUrl: remoteWebUrl, accessToken: accessToken, githubAppOauth: githubAppOauth));
      case ShowcaseFeature.pullRequests:
        Navigator.of(context).push(
          createPullRequestsPageRoute(gitProvider: gitProvider, remoteWebUrl: remoteWebUrl, accessToken: accessToken, githubAppOauth: githubAppOauth),
        );
      case ShowcaseFeature.tags:
        Navigator.of(
          context,
        ).push(createTagsPageRoute(gitProvider: gitProvider, remoteWebUrl: remoteWebUrl, accessToken: accessToken, githubAppOauth: githubAppOauth));
      case ShowcaseFeature.releases:
        Navigator.of(context).push(
          createReleasesPageRoute(gitProvider: gitProvider, remoteWebUrl: remoteWebUrl, accessToken: accessToken, githubAppOauth: githubAppOauth),
        );
      case ShowcaseFeature.actions:
        Navigator.of(context).push(
          createActionsPageRoute(gitProvider: gitProvider, remoteWebUrl: remoteWebUrl, accessToken: accessToken, githubAppOauth: githubAppOauth),
        );
    }
  };
}
