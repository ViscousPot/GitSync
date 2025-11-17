import 'dart:convert';
import 'package:GitSync/api/helper.dart';
import 'package:GitSync/api/logger.dart';

import '../../manager/auth/git_provider_manager.dart';
import '../../../constant/secrets.dart';
import 'package:oauth2_client/github_oauth2_client.dart';
import 'package:oauth2_client/oauth2_client.dart';

class GithubAppManager extends GitProviderManager {
  static const String _domain = "github.com";

  GithubAppManager();

  bool get oAuthSupport => true;

  get clientId => gitHubAppClientId;
  get clientSecret => gitHubAppClientSecret;
  get scopes => ["user", "user:email", "repo", "workflow"];

  OAuth2Client get oauthClient => GitHubOAuth2Client(redirectUri: 'gitsync://auth', customUriScheme: 'gitsync');

  Future<List<Map<String, dynamic>>> getGitHubAppInstallations(String accessToken) async {
    try {
      final response = await httpGet(
        Uri.parse("https://api.$_domain/user/installations"),
        headers: {"Accept": "application/vnd.github.v3+json", "Authorization": "token $accessToken"},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return List<Map<String, dynamic>>.from(jsonResponse['installations'] ?? []).where((item) => item["client_id"] == gitHubAppClientId).toList();
      }
      return [];
    } catch (e, st) {
      Logger.logError(LogType.Global, e, st);
      return [];
    }
  }

  @override
  Future<(String, String)?> getUsernameAndEmail(String accessToken) async {
    final response = await httpGet(
      Uri.parse("https://api.$_domain/user"),
      headers: {"Accept": "application/json", "Authorization": "token $accessToken"},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      String? email = jsonData["email"];
      if (email == null) {
        final emailResp = await httpGet(
          Uri.parse("https://api.$_domain/user/emails"),
          headers: {"Accept": "application/json", "Authorization": "token $accessToken"},
        );
        if (emailResp.statusCode == 200) {
          final emails = (json.decode(emailResp.body) as List).where((e) => e["visibility"] != "private").toList();
          final primaryOrFirst = emails.firstWhere((e) => e["primary"] == true, orElse: () => emails[0]);
          email = primaryOrFirst?["email"];
        }
      }

      return ((jsonData["login"] as String?) ?? "", email ?? "");
    }

    return null;
  }

  @override
  Future<void> getRepos(
    String accessToken,
    String searchString,
    Function(List<(String, String)>) updateCallback,
    Function(Function()?) nextPageCallback,
  ) async {
    await _getReposRequest(
      accessToken,
      searchString == "" ? "https://api.$_domain/user/repos" : "https://api.$_domain/user/repos?per_page=100",
      searchString == ""
          ? updateCallback
          : (list) => updateCallback(list.where((item) => item.$1.toLowerCase().contains(searchString.toLowerCase())).toList()),

      searchString == "" ? nextPageCallback : (_) => {},
    );
  }

  Future<void> _getReposRequest(
    String accessToken,
    String url,
    Function(List<(String, String)>) updateCallback,
    Function(Function()?) nextPageCallback,
  ) async {
    try {
      final response = await httpGet(Uri.parse(url), headers: {"Accept": "application/json", "Authorization": "token $accessToken"});

      if (response.statusCode == 200) {
        final List<dynamic> jsonArray = json.decode(response.body);
        final List<(String, String)> repoList = jsonArray.map((repo) => ("${repo["name"]}", "${repo["clone_url"]}")).toList();

        updateCallback(repoList);

        final String? linkHeader = response.headers["link"];
        if (linkHeader != null) {
          final match = RegExp(r'<([^>]+)>; rel="next"').firstMatch(linkHeader);
          final String? nextLink = match?.group(1);
          if (nextLink != null) {
            nextPageCallback(() => _getReposRequest(accessToken, nextLink, updateCallback, nextPageCallback));
          } else {
            nextPageCallback(null);
          }
        } else {
          nextPageCallback(null);
        }
      }
    } catch (e, st) {
      Logger.logError(LogType.GetRepos, e, st);
    }
  }
}
