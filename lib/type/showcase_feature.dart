import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/type/git_provider.dart';

enum ShowcaseFeature {
  issues(icon: FontAwesomeIcons.solidCircleDot, storageKey: 'issues'),
  pullRequests(icon: FontAwesomeIcons.codePullRequest, storageKey: 'pull_requests'),
  tags(icon: FontAwesomeIcons.tag, storageKey: 'tags'),
  releases(icon: FontAwesomeIcons.rocket, storageKey: 'releases'),
  actions(icon: FontAwesomeIcons.bolt, storageKey: 'actions');
  // snippets(icon: FontAwesomeIcons.code, label: 'SNIPPETS', storageKey: 'snippets');

  const ShowcaseFeature({required this.icon, required this.storageKey});

  final FaIconData icon;
  final String storageKey;

  String label(BuildContext context) => switch (this) {
    ShowcaseFeature.issues => context.t.issues,
    ShowcaseFeature.pullRequests => context.t.pullRequests,
    ShowcaseFeature.tags => context.t.tags,
    ShowcaseFeature.releases => context.t.releases,
    ShowcaseFeature.actions => context.t.actions,
  };

  static const defaultPinned = [ShowcaseFeature.issues, ShowcaseFeature.pullRequests];

  static ShowcaseFeature? fromStorageKey(String key) {
    for (final feature in ShowcaseFeature.values) {
      if (feature.storageKey == key) return feature;
    }
    return null;
  }

  static List<ShowcaseFeature> fromStorageKeys(List<String> keys) {
    final features = <ShowcaseFeature>[];
    for (final key in keys) {
      final feature = fromStorageKey(key);
      if (feature != null) features.add(feature);
    }
    return features;
  }

  static List<String> toStorageKeys(List<ShowcaseFeature> features) {
    return features.map((f) => f.storageKey).toList();
  }

  String labelForProvider(BuildContext context, GitProvider? provider) => switch ((this, provider)) {
    (ShowcaseFeature.pullRequests, GitProvider.GITLAB) => context.t.mergeRequests,
    // (ShowcaseFeature.snippets, GitProvider.GITHUB) => 'GISTS',
    (ShowcaseFeature.actions, GitProvider.GITLAB) => context.t.jobs,
    _ => label(context),
  };

  static List<ShowcaseFeature> availableFor(GitProvider? provider) => switch (provider) {
    GitProvider.GITEA || GitProvider.CODEBERG => values,
    _ => values,
  };
}
