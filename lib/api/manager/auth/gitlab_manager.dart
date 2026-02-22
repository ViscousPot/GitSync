import 'dart:convert';
import 'package:GitSync/api/helper.dart';
import 'package:GitSync/api/logger.dart';
import 'package:GitSync/type/action_run.dart';
import 'package:GitSync/type/issue.dart';
import 'package:GitSync/type/pull_request.dart';
import 'package:GitSync/type/release.dart';
import 'package:GitSync/type/tag.dart';

import '../../manager/auth/git_provider_manager.dart';
import '../../../constant/secrets.dart';
import 'package:oauth2_client/oauth2_client.dart';

class GitlabManager extends GitProviderManager {
  static const String _domain = "gitlab.com";

  GitlabManager();

  bool get oAuthSupport => true;

  get clientId => gitlabClientId;
  get clientSecret => gitlabClientSecret;
  get scopes => ["read_user", "read_api", "read_repository", "write_repository"];

  OAuth2Client get oauthClient => OAuth2Client(
    authorizeUrl: 'https://gitlab.com/oauth/authorize',
    tokenUrl: 'https://gitlab.com/oauth/token',
    redirectUri: 'gitsync://auth',
    customUriScheme: 'gitsync',
  );

  @override
  Future<(String, String)?> getUsernameAndEmail(String accessToken) async {
    final response = await httpGet(Uri.parse("https://$_domain/api/v4/user"), headers: {"Authorization": "Bearer $accessToken"});

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(utf8.decode(response.bodyBytes));
      return (jsonData["username"] as String, jsonData["email"] as String);
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
      "https://$_domain/api/v4/projects?membership=true&per_page=100",
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
      final response = await httpGet(Uri.parse(url), headers: {"Authorization": "Bearer $accessToken"});

      if (response.statusCode == 200) {
        final List<dynamic> jsonArray = json.decode(utf8.decode(response.bodyBytes));
        final List<(String, String)> repoList = jsonArray.map((repo) => ("${repo["name"]}", "${repo["http_url_to_repo"]}")).toList();

        updateCallback(repoList);

        final String? nextLink = response.headers["x-next-page"];
        if (nextLink != null && nextLink.isNotEmpty) {
          final nextUrl = Uri.parse(url).replace(queryParameters: {...Uri.parse(url).queryParameters, "page": nextLink}).toString();
          nextPageCallback(() => _getReposRequest(accessToken, nextUrl, updateCallback, nextPageCallback));
        } else {
          nextPageCallback(null);
        }
      }
    } catch (e, st) {
      Logger.logError(LogType.GetRepos, e, st);
    }
  }

  @override
  Future<void> getIssues(
    String accessToken,
    String owner,
    String repo,
    String state,
    String? authorFilter,
    String? labelFilter,
    String? assigneeFilter,
    Function(List<Issue>) updateCallback,
    Function(Function()?) nextPageCallback,
  ) async {
    final gitlabState = state == "open" ? "opened" : state;
    var url = "https://$_domain/api/v4/projects/$owner%2F$repo/issues?state=$gitlabState&per_page=30";
    if (authorFilter != null && authorFilter.isNotEmpty) url += "&author_username=$authorFilter";
    if (labelFilter != null && labelFilter.isNotEmpty) url += "&labels=$labelFilter";
    if (assigneeFilter != null && assigneeFilter.isNotEmpty) url += "&assignee_username=$assigneeFilter";
    await _getIssuesRequest(accessToken, url, updateCallback, nextPageCallback);
  }

  Future<void> _getIssuesRequest(
    String accessToken,
    String url,
    Function(List<Issue>) updateCallback,
    Function(Function()?) nextPageCallback,
  ) async {
    try {
      final response = await httpGet(Uri.parse(url), headers: {"Authorization": "Bearer $accessToken"});

      if (response.statusCode == 200) {
        final List<dynamic> jsonArray = json.decode(utf8.decode(response.bodyBytes));
        final List<Issue> issues = jsonArray
            .map((item) => Issue(
                  title: item["title"] ?? "",
                  number: item["iid"] ?? 0,
                  isOpen: item["state"] == "opened",
                  authorUsername: item["author"]?["username"] ?? "",
                  createdAt: DateTime.tryParse(item["created_at"] ?? "") ?? DateTime.now(),
                  commentCount: item["user_notes_count"] ?? 0,
                  labels: (item["labels"] as List<dynamic>?)?.map((l) => IssueLabel(name: l.toString())).toList() ?? [],
                ))
            .toList();

        updateCallback(issues);

        final String? nextLink = response.headers["x-next-page"];
        if (nextLink != null && nextLink.isNotEmpty) {
          final nextUrl = Uri.parse(url).replace(queryParameters: {...Uri.parse(url).queryParameters, "page": nextLink}).toString();
          nextPageCallback(() => _getIssuesRequest(accessToken, nextUrl, updateCallback, nextPageCallback));
        } else {
          nextPageCallback(null);
        }
      } else {
        updateCallback([]);
        nextPageCallback(null);
      }
    } catch (e, st) {
      Logger.logError(LogType.GetIssues, e, st);
      updateCallback([]);
      nextPageCallback(null);
    }
  }

  @override
  Future<void> getPullRequests(
    String accessToken,
    String owner,
    String repo,
    String state,
    String? authorFilter,
    String? labelFilter,
    String? assigneeFilter,
    Function(List<PullRequest>) updateCallback,
    Function(Function()?) nextPageCallback,
  ) async {
    final gitlabState = state == "open" ? "opened" : state;
    var url = "https://$_domain/api/v4/projects/$owner%2F$repo/merge_requests?state=$gitlabState&per_page=30";
    if (authorFilter != null && authorFilter.isNotEmpty) url += "&author_username=$authorFilter";
    if (labelFilter != null && labelFilter.isNotEmpty) url += "&labels=$labelFilter";
    if (assigneeFilter != null && assigneeFilter.isNotEmpty) url += "&assignee_username=$assigneeFilter";
    await _getPullRequestsRequest(accessToken, url, updateCallback, nextPageCallback);
  }

  Future<void> _getPullRequestsRequest(
    String accessToken,
    String url,
    Function(List<PullRequest>) updateCallback,
    Function(Function()?) nextPageCallback,
  ) async {
    try {
      final response = await httpGet(Uri.parse(url), headers: {"Authorization": "Bearer $accessToken"});

      if (response.statusCode == 200) {
        final List<dynamic> jsonArray = json.decode(utf8.decode(response.bodyBytes));
        final List<PullRequest> prs = jsonArray
            .map((item) {
              final stateStr = item["state"] ?? "";
              final PrState prState = switch (stateStr) {
                "opened" => PrState.open,
                "merged" => PrState.merged,
                _ => PrState.closed,
              };

              return PullRequest(
                title: item["title"] ?? "",
                number: item["iid"] ?? 0,
                state: prState,
                authorUsername: item["author"]?["username"] ?? "",
                createdAt: DateTime.tryParse(item["created_at"] ?? "") ?? DateTime.now(),
                commentCount: item["user_notes_count"] ?? 0,
                labels: (item["labels"] as List<dynamic>?)?.map((l) => IssueLabel(name: l.toString())).toList() ?? [],
              );
            })
            .toList();

        updateCallback(prs);

        final String? nextLink = response.headers["x-next-page"];
        if (nextLink != null && nextLink.isNotEmpty) {
          final nextUrl = Uri.parse(url).replace(queryParameters: {...Uri.parse(url).queryParameters, "page": nextLink}).toString();
          nextPageCallback(() => _getPullRequestsRequest(accessToken, nextUrl, updateCallback, nextPageCallback));
        } else {
          nextPageCallback(null);
        }
      } else {
        updateCallback([]);
        nextPageCallback(null);
      }
    } catch (e, st) {
      Logger.logError(LogType.GetPullRequests, e, st);
      updateCallback([]);
      nextPageCallback(null);
    }
  }

  @override
  Future<void> getTags(
    String accessToken,
    String owner,
    String repo,
    Function(List<Tag>) updateCallback,
    Function(Function()?) nextPageCallback,
  ) async {
    final url = "https://$_domain/api/v4/projects/$owner%2F$repo/repository/tags?per_page=30";
    await _getTagsRequest(accessToken, url, updateCallback, nextPageCallback);
  }

  Future<void> _getTagsRequest(
    String accessToken,
    String url,
    Function(List<Tag>) updateCallback,
    Function(Function()?) nextPageCallback,
  ) async {
    try {
      final response = await httpGet(Uri.parse(url), headers: {"Authorization": "Bearer $accessToken"});

      if (response.statusCode == 200) {
        final List<dynamic> jsonArray = json.decode(utf8.decode(response.bodyBytes));
        final List<Tag> tags = jsonArray
            .map((item) => Tag(
                  name: item["name"] ?? "",
                  sha: item["target"] ?? "",
                  createdAt: DateTime.tryParse(item["commit"]?["created_at"] ?? "") ?? DateTime.now(),
                  message: (item["message"] as String?)?.isNotEmpty == true ? item["message"] as String : null,
                ))
            .toList();

        updateCallback(tags);

        final String? nextLink = response.headers["x-next-page"];
        if (nextLink != null && nextLink.isNotEmpty) {
          final nextUrl = Uri.parse(url).replace(queryParameters: {...Uri.parse(url).queryParameters, "page": nextLink}).toString();
          nextPageCallback(() => _getTagsRequest(accessToken, nextUrl, updateCallback, nextPageCallback));
        } else {
          nextPageCallback(null);
        }
      } else {
        updateCallback([]);
        nextPageCallback(null);
      }
    } catch (e, st) {
      Logger.logError(LogType.GetTags, e, st);
      updateCallback([]);
      nextPageCallback(null);
    }
  }

  @override
  Future<void> getReleases(
    String accessToken,
    String owner,
    String repo,
    Function(List<Release>) updateCallback,
    Function(Function()?) nextPageCallback,
  ) async {
    final url = "https://$_domain/api/v4/projects/$owner%2F$repo/releases?per_page=20";
    await _getReleasesRequest(accessToken, url, updateCallback, nextPageCallback);
  }

  Future<void> _getReleasesRequest(
    String accessToken,
    String url,
    Function(List<Release>) updateCallback,
    Function(Function()?) nextPageCallback,
  ) async {
    try {
      final response = await httpGet(Uri.parse(url), headers: {"Authorization": "Bearer $accessToken"});

      if (response.statusCode == 200) {
        final List<dynamic> jsonArray = json.decode(utf8.decode(response.bodyBytes));
        final List<Release> releases = jsonArray.map((item) {
          final List<ReleaseAsset> assets = [];
          final links = item["assets"]?["links"] as List<dynamic>? ?? [];
          for (final link in links) {
            assets.add(ReleaseAsset(name: link["name"] ?? "", downloadUrl: link["direct_asset_url"] ?? link["url"] ?? ""));
          }
          final sources = item["assets"]?["sources"] as List<dynamic>? ?? [];
          for (final source in sources) {
            assets.add(ReleaseAsset(name: "Source (${source["format"] ?? ""})", downloadUrl: source["url"] ?? ""));
          }

          return Release(
            name: item["name"] ?? "",
            tagName: item["tag_name"] ?? "",
            description: item["description"] ?? "",
            authorUsername: item["author"]?["username"] ?? "",
            createdAt: DateTime.tryParse(item["released_at"] ?? item["created_at"] ?? "") ?? DateTime.now(),
            commitSha: item["commit"]?["short_id"] as String?,
            assets: assets,
          );
        }).toList();

        updateCallback(releases);

        final String? nextLink = response.headers["x-next-page"];
        if (nextLink != null && nextLink.isNotEmpty) {
          final nextUrl = Uri.parse(url).replace(queryParameters: {...Uri.parse(url).queryParameters, "page": nextLink}).toString();
          nextPageCallback(() => _getReleasesRequest(accessToken, nextUrl, updateCallback, nextPageCallback));
        } else {
          nextPageCallback(null);
        }
      } else {
        updateCallback([]);
        nextPageCallback(null);
      }
    } catch (e, st) {
      Logger.logError(LogType.GetReleases, e, st);
      updateCallback([]);
      nextPageCallback(null);
    }
  }

  @override
  Future<void> getActionRuns(
    String accessToken,
    String owner,
    String repo,
    String state,
    Function(List<ActionRun>) updateCallback,
    Function(Function()?) nextPageCallback,
  ) async {
    var url = "https://$_domain/api/v4/projects/$owner%2F$repo/pipelines?per_page=30";
    if (state == "success") url += "&status=success";
    if (state == "failed") url += "&status=failed";
    await _getActionRunsRequest(accessToken, url, updateCallback, nextPageCallback);
  }

  Future<void> _getActionRunsRequest(
    String accessToken,
    String url,
    Function(List<ActionRun>) updateCallback,
    Function(Function()?) nextPageCallback,
  ) async {
    try {
      final response = await httpGet(Uri.parse(url), headers: {"Authorization": "Bearer $accessToken"});

      if (response.statusCode == 200) {
        final List<dynamic> jsonArray = json.decode(utf8.decode(response.bodyBytes));
        final List<ActionRun> actionRuns = jsonArray.map((item) {
          final statusStr = item["status"] as String? ?? "";
          final ActionRunStatus status = switch (statusStr) {
            "success" => ActionRunStatus.success,
            "failed" => ActionRunStatus.failure,
            "canceled" => ActionRunStatus.cancelled,
            "skipped" => ActionRunStatus.skipped,
            "running" => ActionRunStatus.inProgress,
            _ => ActionRunStatus.pending,
          };

          final durationSec = item["duration"] as num?;
          final Duration? duration = durationSec != null ? Duration(seconds: durationSec.toInt()) : null;

          return ActionRun(
            name: "Pipeline #${item["iid"] ?? item["id"] ?? 0}",
            number: item["iid"] ?? item["id"] ?? 0,
            status: status,
            event: item["source"] ?? "",
            authorUsername: item["user"]?["username"] ?? "",
            createdAt: DateTime.tryParse(item["created_at"] ?? "") ?? DateTime.now(),
            duration: duration,
            branch: item["ref"] as String?,
          );
        }).toList();

        updateCallback(actionRuns);

        final String? nextLink = response.headers["x-next-page"];
        if (nextLink != null && nextLink.isNotEmpty) {
          final nextUrl = Uri.parse(url).replace(queryParameters: {...Uri.parse(url).queryParameters, "page": nextLink}).toString();
          nextPageCallback(() => _getActionRunsRequest(accessToken, nextUrl, updateCallback, nextPageCallback));
        } else {
          nextPageCallback(null);
        }
      } else {
        updateCallback([]);
        nextPageCallback(null);
      }
    } catch (e, st) {
      Logger.logError(LogType.GetActionRuns, e, st);
      updateCallback([]);
      nextPageCallback(null);
    }
  }
}
