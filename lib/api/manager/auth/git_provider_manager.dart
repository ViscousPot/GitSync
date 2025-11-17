import 'dart:io';

import 'package:GitSync/api/helper.dart';
import 'package:GitSync/api/manager/auth/github_app_manager.dart';
import 'package:GitSync/constant/strings.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/api/manager/auth/gitlab_manager.dart';
import 'package:oauth2_client/github_oauth2_client.dart';
import 'package:oauth2_client/oauth2_client.dart';
import '../../manager/auth/gitea_manager.dart';
import '../../manager/auth/github_manager.dart';
import '../../../constant/colors.dart';
import '../../../constant/dimens.dart';
import '../../../constant/icons.dart';
import '../../../type/git_provider.dart';

class GitProviderManager {
  // ignore: non_constant_identifier_names
  static Map<GitProvider, FaIcon> GitProviderIconsMap = {
    GitProvider.GITHUB: Platform.isIOS
        ? FaIcon(FontAwesomeIcons.gitAlt, size: textLG, color: primaryLight)
        : FaIcon(FontAwesomeIcons.github, size: textMD, color: primaryLight),
    GitProvider.GITEA: Platform.isIOS
        ? FaIcon(FontAwesomeIcons.gitAlt, size: textLG, color: primaryLight)
        : FaIcon(gitea_logo, size: textMD, color: giteaGreen),
    GitProvider.GITLAB: Platform.isIOS
        ? FaIcon(FontAwesomeIcons.gitAlt, size: textLG, color: primaryLight)
        : FaIcon(gitlab_logo, size: textMD, color: gitlabOrange),
    GitProvider.HTTPS: FaIcon(FontAwesomeIcons.lock, size: textMD, color: primaryLight),
    GitProvider.SSH: FaIcon(FontAwesomeIcons.terminal, size: textMD, color: primaryLight),
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

  Future<void> getRepos(
    String accessToken,
    String searchString,
    Function(List<(String, String)>) updateCallback,
    Function(Function()?) nextPageCallback,
  ) async {}
}
