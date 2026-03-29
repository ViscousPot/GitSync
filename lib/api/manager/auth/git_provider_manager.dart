import 'dart:io';

import 'package:GitSync/api/helper.dart';
import 'package:GitSync/api/manager/auth/github_app_manager.dart';
import 'package:GitSync/constant/strings.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/type/issue.dart';
import 'package:GitSync/type/issue_detail.dart';
import 'package:GitSync/type/issue_template.dart';
import 'package:GitSync/type/pr_detail.dart';
import 'package:GitSync/type/pull_request.dart';
import 'package:GitSync/type/action_run.dart';
import 'package:GitSync/type/release.dart';
import 'package:GitSync/type/showcase_feature.dart';
import 'package:GitSync/type/tag.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/api/manager/auth/gitlab_manager.dart';
import 'package:oauth2_client/github_oauth2_client.dart';
import 'package:oauth2_client/oauth2_client.dart';
import '../../manager/auth/gitea_manager.dart';
import '../../manager/auth/github_manager.dart';
import '../../../constant/dimens.dart';
import '../../../constant/icons.dart';
import '../../../type/git_provider.dart';

class GitProviderManager {
  // ignore: non_constant_identifier_names
  static Map<GitProvider, FaIcon> get GitProviderIconsMap => {
    GitProvider.GITHUB: Platform.isIOS
        ? FaIcon(FontAwesomeIcons.gitAlt, size: textLG, color: colours.primaryLight)
        : FaIcon(FontAwesomeIcons.github, size: textMD, color: colours.primaryLight),
    GitProvider.GITEA: Platform.isIOS
        ? FaIcon(FontAwesomeIcons.gitAlt, size: textLG, color: colours.primaryLight)
        : FaIcon(gitea_logo, size: textMD, color: colours.giteaGreen),
    GitProvider.GITLAB: Platform.isIOS
        ? FaIcon(FontAwesomeIcons.gitAlt, size: textLG, color: colours.primaryLight)
        : FaIcon(gitlab_logo, size: textMD, color: colours.gitlabOrange),
    GitProvider.HTTPS: FaIcon(FontAwesomeIcons.lock, size: textMD, color: colours.primaryLight),
    GitProvider.SSH: FaIcon(FontAwesomeIcons.terminal, size: textMD, color: colours.primaryLight),
  };

  static GitProviderManager? getGitProviderManager(GitProvider provider, bool githubAppOauth) {
    return switch (provider) {
      GitProvider.GITHUB => githubAppOauth ? GithubAppManager() : GithubManager(),
      GitProvider.GITEA => GiteaManager(),
      GitProvider.GITLAB => GitlabManager(),
      GitProvider.HTTPS => null,
      GitProvider.SSH => null,
    };
  }

  String get clientId => "";
  String get clientSecret => "";
  List<String>? get scopes => null;

  OAuth2Client get oauthClient => GitHubOAuth2Client(redirectUri: 'gitsync://auth', customUriScheme: 'gitsync');

  Future<String?> getToken(String token, Future<void> Function(String p1, DateTime? p2, String p3) setAccessRefreshToken) async {
    final tokenParts = token.split(conflictSeparator);
    final accessToken = tokenParts.first;
    final expirationDate = tokenParts.length >= 2 && int.tryParse(tokenParts[1]) != null
        ? DateTime.fromMillisecondsSinceEpoch(int.parse(tokenParts[1]))
        : null;
    final refreshToken = tokenParts.last;

    if (!token.contains(conflictSeparator) || refreshToken.isEmpty || expirationDate == null || expirationDate.isAfter(DateTime.now())) {
      return accessToken;
    }

    if (accessToken.isEmpty) return null;

    final client = oauthClient;
    final refreshed = await client.refreshToken(refreshToken, clientId: clientId, clientSecret: clientSecret);

    if (refreshed.accessToken != null) {
      if (refreshed.accessToken == null || refreshed.refreshToken == null) return null;
      await setAccessRefreshToken(refreshed.accessToken!, refreshed.expirationDate, refreshed.refreshToken!);
      return refreshed.accessToken;
    }
    return null;
  }

  Future<(String, String, String)?> launchOAuthFlow([List<String>? scopeOverride]) async {
    final response = await oauthClient.getTokenWithAuthCodeFlow(clientId: clientId, clientSecret: clientSecret, scopes: scopeOverride ?? scopes);

    if (response.accessToken == null) return null;

    final usernameAndEmail = await getUsernameAndEmail(response.accessToken!);
    if (usernameAndEmail == null) return null;

    return (
      usernameAndEmail.$1,
      usernameAndEmail.$2,
      buildAccessRefreshToken(response.accessToken ?? "", response.expirationDate, response.refreshToken),
    );
  }

  Future<(String, String)?> getUsernameAndEmail(String accessToken) async {
    return null;
  }

  Future<(String, String?)?> createRepo(String accessToken, String username, String repoName, bool isPrivate) async {
    return null;
  }

  Future<void> getRepos(
    String accessToken,
    String searchString,
    Function(List<(String, String)>) updateCallback,
    Function(Function()?) nextPageCallback,
  ) async {}

  Future<void> getIssues(
    String accessToken,
    String owner,
    String repo,
    String state,
    String? authorFilter,
    String? labelFilter,
    String? assigneeFilter,
    String? searchFilter,
    String? sortOption,
    String? milestoneFilter,
    String? projectFilter,
    Function(List<Issue>) updateCallback,
    Function(Function()?) nextPageCallback,
  ) async {}

  Future<List<Milestone>> getMilestones(String accessToken, String owner, String repo) async {
    return [];
  }

  Future<List<GitProject>> getProjects(String accessToken, String owner, String repo) async {
    return [];
  }

  Future<List<String>> getLabels(String accessToken, String owner, String repo) async {
    return [];
  }

  Future<List<String>> getCollaborators(String accessToken, String owner, String repo) async {
    return [];
  }

  Future<void> getPullRequests(
    String accessToken,
    String owner,
    String repo,
    String state,
    String? authorFilter,
    String? labelFilter,
    String? assigneeFilter,
    String? searchFilter,
    String? sortOption,
    String? reviewerFilter,
    String? milestoneFilter,
    Function(List<PullRequest>) updateCallback,
    Function(Function()?) nextPageCallback,
  ) async {}

  Future<void> getTags(
    String accessToken,
    String owner,
    String repo,
    Function(List<Tag>) updateCallback,
    Function(Function()?) nextPageCallback,
  ) async {}

  Future<void> getReleases(
    String accessToken,
    String owner,
    String repo,
    Function(List<Release>) updateCallback,
    Function(Function()?) nextPageCallback,
  ) async {}

  Future<void> getActionRuns(
    String accessToken,
    String owner,
    String repo,
    String state,
    Function(List<ActionRun>) updateCallback,
    Function(Function()?) nextPageCallback,
  ) async {}

  Future<IssueDetail?> getIssueDetail(String accessToken, String owner, String repo, int issueNumber) async {
    return null;
  }

  Future<PrDetail?> getPrDetail(String accessToken, String owner, String repo, int prNumber) async {
    return null;
  }

  Future<IssueComment?> addIssueComment(String accessToken, String owner, String repo, int issueNumber, String body) async {
    return null;
  }

  Future<bool> updateIssueState(String accessToken, String owner, String repo, int issueNumber, String issueId, bool close) async {
    return false;
  }

  Future<bool> addReaction(String accessToken, String owner, String repo, int issueNumber, String targetId, String reaction, bool isComment) async {
    return false;
  }

  Future<bool> removeReaction(String accessToken, String owner, String repo, int issueNumber, String targetId, String reaction, bool isComment) async {
    return false;
  }

  Future<CreateIssueResult?> createIssue(String accessToken, String owner, String repo, String title, String body, {List<String>? labels, List<String>? assignees}) async {
    return null;
  }

  Future<List<IssueTemplate>> getIssueTemplates(String accessToken, String owner, String repo) async {
    return [];
  }

  Future<bool> updateIssue(String accessToken, String owner, String repo, int issueNumber, {String? title, String? body}) async {
    return false;
  }

  Future<CreateIssueResult?> createPullRequest(String accessToken, String owner, String repo, String title, String body, String head, String base) async {
    return null;
  }

  Future<Map<ShowcaseFeature, int?>> getFeatureCounts(String accessToken, String owner, String repo, [List<ShowcaseFeature>? features]) async {
    return {};
  }

  Future<(List<String>, String?)> getRepoBranches(String accessToken, String owner, String repo) async {
    return (<String>[], null);
  }

  Future<List<IssueTemplate>> getPrTemplates(String accessToken, String owner, String repo) async {
    return [];
  }
}
