import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/type/git_provider.dart';

enum ShowcaseFeature {
  issues(icon: FontAwesomeIcons.solidCircleDot, label: 'ISSUES', storageKey: 'issues'),
  pullRequests(icon: FontAwesomeIcons.codePullRequest, label: 'PULL REQUESTS', storageKey: 'pull_requests'),
  tags(icon: FontAwesomeIcons.tag, label: 'TAGS', storageKey: 'tags'),
  releases(icon: FontAwesomeIcons.rocket, label: 'RELEASES', storageKey: 'releases'),
  actions(icon: FontAwesomeIcons.bolt, label: 'ACTIONS', storageKey: 'actions');
  // snippets(icon: FontAwesomeIcons.code, label: 'SNIPPETS', storageKey: 'snippets');

  const ShowcaseFeature({required this.icon, required this.label, required this.storageKey});

  final FaIconData icon;
  final String label;
  final String storageKey;

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

  String labelForProvider(GitProvider? provider) => switch ((this, provider)) {
    (ShowcaseFeature.pullRequests, GitProvider.GITLAB) => 'MERGE REQUESTS',
    // (ShowcaseFeature.snippets, GitProvider.GITHUB) => 'GISTS',
    (ShowcaseFeature.actions, GitProvider.GITLAB) => 'JOBS',
    _ => label,
  };

  static List<ShowcaseFeature> availableFor(GitProvider? provider) => switch (provider) {
    GitProvider.GITEA || GitProvider.CODEBERG => values,
    _ => values,
  };
}
