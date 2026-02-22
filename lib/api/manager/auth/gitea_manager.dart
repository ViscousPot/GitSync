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

class GiteaManager extends GitProviderManager {
  static const String _domain = "gitea.com";

  GiteaManager();

  bool get oAuthSupport => true;

  get clientId => giteaClientId;
  get clientSecret => giteaClientSecret;
  get scopes => null;

  OAuth2Client get oauthClient => OAuth2Client(
    authorizeUrl: 'https://gitea.com/login/oauth/authorize',
    tokenUrl: 'https://gitea.com/login/oauth/access_token',
    redirectUri: 'gitsync://auth',
    customUriScheme: 'gitsync',
  );

  @override
  Future<(String, String)?> getUsernameAndEmail(String accessToken) async {
    final response = await httpGet(
      Uri.parse("https://$_domain/api/v1/user"),
      headers: {"Accept": "application/json", "Authorization": "token $accessToken"},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(utf8.decode(response.bodyBytes));
      return (jsonData["login"] as String, jsonData["email"] as String);
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
    await getReposRequest(
      accessToken,
      searchString == "" ? "https://$_domain/api/v1/user/repos" : "https://$_domain/api/v1/user/repos?limit=100",
      searchString == ""
          ? updateCallback
          : (list) => updateCallback(list.where((item) => item.$1.toLowerCase().contains(searchString.toLowerCase())).toList()),
      searchString == "" ? nextPageCallback : (_) => {},
    );
  }

  Future<void> getReposRequest(
    String accessToken,
    String url,
    Function(List<(String, String)>) updateCallback,
    Function(Function()?) nextPageCallback,
  ) async {
    try {
      final response = await httpGet(Uri.parse(url), headers: {"Accept": "application/json", "Authorization": "token $accessToken"});

      if (response.statusCode == 200) {
        final List<dynamic> jsonArray = json.decode(utf8.decode(response.bodyBytes));
        final List<(String, String)> repoList = jsonArray.map((repo) => ("${repo["name"]}", "${repo["clone_url"]}")).toList();

        updateCallback(repoList);

        final String? linkHeader = response.headers["link"];
        if (linkHeader != null) {
          final match = RegExp(r'<([^>]+)>; rel="next"').firstMatch(linkHeader);
          final String? nextLink = match?.group(1);
          if (nextLink != null) {
            nextPageCallback(() => getReposRequest(accessToken, nextLink, updateCallback, nextPageCallback));
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
    var url = "https://$_domain/api/v1/repos/$owner/$repo/issues?state=$state&type=issues&limit=30";
    if (authorFilter != null && authorFilter.isNotEmpty) url += "&created_by=$authorFilter";
    if (labelFilter != null && labelFilter.isNotEmpty) url += "&labels=$labelFilter";
    if (assigneeFilter != null && assigneeFilter.isNotEmpty) url += "&assigned_by=$assigneeFilter";
    await _getIssuesRequest(accessToken, url, updateCallback, nextPageCallback);
  }

  Future<void> _getIssuesRequest(
    String accessToken,
    String url,
    Function(List<Issue>) updateCallback,
    Function(Function()?) nextPageCallback,
  ) async {
    try {
      final response = await httpGet(Uri.parse(url), headers: {"Accept": "application/json", "Authorization": "token $accessToken"});

      if (response.statusCode == 200) {
        final List<dynamic> jsonArray = json.decode(utf8.decode(response.bodyBytes));
        final List<Issue> issues = jsonArray
            .map((item) => Issue(
                  title: item["title"] ?? "",
                  number: item["number"] ?? 0,
                  isOpen: item["state"] == "open",
                  authorUsername: item["user"]?["login"] ?? "",
                  createdAt: DateTime.tryParse(item["created_at"] ?? "") ?? DateTime.now(),
                  commentCount: item["comments"] ?? 0,
                  labels: (item["labels"] as List<dynamic>?)
                          ?.map((l) => IssueLabel(name: l["name"] ?? "", color: l["color"]))
                          .toList() ??
                      [],
                ))
            .toList();

        updateCallback(issues);

        final String? linkHeader = response.headers["link"];
        if (linkHeader != null) {
          final match = RegExp(r'<([^>]+)>; rel="next"').firstMatch(linkHeader);
          final String? nextLink = match?.group(1);
          if (nextLink != null) {
            nextPageCallback(() => _getIssuesRequest(accessToken, nextLink, updateCallback, nextPageCallback));
          } else {
            nextPageCallback(null);
          }
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
    var url = "https://$_domain/api/v1/repos/$owner/$repo/pulls?state=$state&limit=30";
    if (authorFilter != null && authorFilter.isNotEmpty) url += "&created_by=$authorFilter";
    if (labelFilter != null && labelFilter.isNotEmpty) url += "&labels=$labelFilter";
    if (assigneeFilter != null && assigneeFilter.isNotEmpty) url += "&assigned_by=$assigneeFilter";
    await _getPullRequestsRequest(accessToken, url, updateCallback, nextPageCallback);
  }

  Future<void> _getPullRequestsRequest(
    String accessToken,
    String url,
    Function(List<PullRequest>) updateCallback,
    Function(Function()?) nextPageCallback,
  ) async {
    try {
      final response = await httpGet(Uri.parse(url), headers: {"Accept": "application/json", "Authorization": "token $accessToken"});

      if (response.statusCode == 200) {
        final List<dynamic> jsonArray = json.decode(utf8.decode(response.bodyBytes));

        // Extract owner/repo from URL for status requests
        final uri = Uri.parse(url);
        final pathSegments = uri.pathSegments;
        final reposIdx = pathSegments.indexOf('repos');
        final owner = pathSegments[reposIdx + 1];
        final repo = pathSegments[reposIdx + 2];

        // Fetch combined commit status for each PR in parallel
        final statusFutures = jsonArray.map((item) async {
          final sha = item["head"]?["sha"] as String?;
          if (sha == null || sha.isEmpty) return CheckStatus.none;
          try {
            final statusResp = await httpGet(
              Uri.parse("https://$_domain/api/v1/repos/$owner/$repo/commits/$sha/status"),
              headers: {"Accept": "application/json", "Authorization": "token $accessToken"},
            );
            if (statusResp.statusCode == 200) {
              final statusData = json.decode(utf8.decode(statusResp.bodyBytes));
              final state = statusData["state"] as String? ?? "";
              return switch (state) {
                "success" => CheckStatus.success,
                "failure" || "error" => CheckStatus.failure,
                "pending" || "warning" => CheckStatus.pending,
                _ => CheckStatus.none,
              };
            }
          } catch (_) {}
          return CheckStatus.none;
        }).toList();

        final statuses = await Future.wait(statusFutures);

        final List<PullRequest> prs = [];
        for (var i = 0; i < jsonArray.length; i++) {
          final item = jsonArray[i];
          final bool isMerged = item["merged"] == true || (item["merged_at"] != null && item["merged_at"] != "");
          final PrState prState = isMerged
              ? PrState.merged
              : item["state"] == "open"
                  ? PrState.open
                  : PrState.closed;

          prs.add(PullRequest(
            title: item["title"] ?? "",
            number: item["number"] ?? 0,
            state: prState,
            authorUsername: item["user"]?["login"] ?? "",
            createdAt: DateTime.tryParse(item["created_at"] ?? "") ?? DateTime.now(),
            commentCount: item["comments"] ?? 0,
            checkStatus: statuses[i],
            labels: (item["labels"] as List<dynamic>?)
                    ?.map((l) => IssueLabel(name: l["name"] ?? "", color: l["color"]))
                    .toList() ??
                [],
          ));
        }

        updateCallback(prs);

        final String? linkHeader = response.headers["link"];
        if (linkHeader != null) {
          final match = RegExp(r'<([^>]+)>; rel="next"').firstMatch(linkHeader);
          final String? nextLink = match?.group(1);
          if (nextLink != null) {
            nextPageCallback(() => _getPullRequestsRequest(accessToken, nextLink, updateCallback, nextPageCallback));
          } else {
            nextPageCallback(null);
          }
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
    final url = "https://$_domain/api/v1/repos/$owner/$repo/tags?limit=30";
    await _getTagsRequest(accessToken, url, updateCallback, nextPageCallback);
  }

  Future<void> _getTagsRequest(
    String accessToken,
    String url,
    Function(List<Tag>) updateCallback,
    Function(Function()?) nextPageCallback,
  ) async {
    try {
      final response = await httpGet(Uri.parse(url), headers: {"Accept": "application/json", "Authorization": "token $accessToken"});

      if (response.statusCode == 200) {
        final List<dynamic> jsonArray = json.decode(utf8.decode(response.bodyBytes));
        final List<Tag> tags = jsonArray
            .map((item) => Tag(
                  name: item["name"] ?? "",
                  sha: item["commit"]?["sha"] ?? "",
                  createdAt: DateTime.tryParse(item["commit"]?["created"] ?? "") ?? DateTime.now(),
                  message: (item["message"] as String?)?.isNotEmpty == true ? item["message"] as String : null,
                ))
            .toList();

        updateCallback(tags);

        final String? linkHeader = response.headers["link"];
        if (linkHeader != null) {
          final match = RegExp(r'<([^>]+)>; rel="next"').firstMatch(linkHeader);
          final String? nextLink = match?.group(1);
          if (nextLink != null) {
            nextPageCallback(() => _getTagsRequest(accessToken, nextLink, updateCallback, nextPageCallback));
          } else {
            nextPageCallback(null);
          }
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
    final url = "https://$_domain/api/v1/repos/$owner/$repo/releases?limit=20";
    await _getReleasesRequest(accessToken, url, updateCallback, nextPageCallback);
  }

  Future<void> _getReleasesRequest(
    String accessToken,
    String url,
    Function(List<Release>) updateCallback,
    Function(Function()?) nextPageCallback,
  ) async {
    try {
      final response = await httpGet(Uri.parse(url), headers: {"Accept": "application/json", "Authorization": "token $accessToken"});

      if (response.statusCode == 200) {
        final List<dynamic> jsonArray = json.decode(utf8.decode(response.bodyBytes));
        final List<Release> releases = jsonArray.map((item) {
          final assetList = item["assets"] as List<dynamic>? ?? [];
          final assets = assetList
              .map((a) => ReleaseAsset(
                    name: a["name"] ?? "",
                    downloadUrl: a["browser_download_url"] ?? "",
                    size: a["size"] as int?,
                    downloadCount: a["download_count"] as int?,
                  ))
              .toList();

          final targetCommitish = item["target_commitish"] as String? ?? "";
          final commitSha = RegExp(r'^[0-9a-f]{7,}$').hasMatch(targetCommitish) ? targetCommitish : null;

          return Release(
            name: item["name"] ?? "",
            tagName: item["tag_name"] ?? "",
            description: item["body"] ?? "",
            authorUsername: item["author"]?["login"] ?? "",
            createdAt: DateTime.tryParse(item["created_at"] ?? "") ?? DateTime.now(),
            commitSha: commitSha,
            isPrerelease: item["prerelease"] == true,
            isDraft: item["draft"] == true,
            assets: assets,
          );
        }).toList();

        updateCallback(releases);

        final String? linkHeader = response.headers["link"];
        if (linkHeader != null) {
          final match = RegExp(r'<([^>]+)>; rel="next"').firstMatch(linkHeader);
          final String? nextLink = match?.group(1);
          if (nextLink != null) {
            nextPageCallback(() => _getReleasesRequest(accessToken, nextLink, updateCallback, nextPageCallback));
          } else {
            nextPageCallback(null);
          }
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
    var url = "https://$_domain/api/v1/repos/$owner/$repo/actions/runs?limit=30";
    if (state == "success") url += "&status=success";
    if (state == "failed") url += "&status=failure";
    await _getActionRunsRequest(accessToken, url, updateCallback, nextPageCallback);
  }

  Future<void> _getActionRunsRequest(
    String accessToken,
    String url,
    Function(List<ActionRun>) updateCallback,
    Function(Function()?) nextPageCallback,
  ) async {
    try {
      final response = await httpGet(Uri.parse(url), headers: {"Accept": "application/json", "Authorization": "token $accessToken"});

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(utf8.decode(response.bodyBytes));
        final runs = jsonData["workflow_runs"] as List<dynamic>? ?? [];
        final List<ActionRun> actionRuns = runs.map((item) {
          final conclusion = item["conclusion"] as String?;
          final statusStr = item["status"] as String? ?? "";
          final ActionRunStatus status = switch (conclusion) {
            "success" => ActionRunStatus.success,
            "failure" => ActionRunStatus.failure,
            "cancelled" => ActionRunStatus.cancelled,
            "skipped" => ActionRunStatus.skipped,
            _ => statusStr == "in_progress" ? ActionRunStatus.inProgress : ActionRunStatus.pending,
          };

          final startedAt = DateTime.tryParse(item["run_started_at"] ?? "");
          final updatedAt = DateTime.tryParse(item["updated_at"] ?? "");
          final Duration? duration = (startedAt != null && updatedAt != null && conclusion != null)
              ? updatedAt.difference(startedAt)
              : null;

          final prs = item["pull_requests"] as List<dynamic>? ?? [];
          final int? prNumber = prs.isNotEmpty ? prs[0]["number"] as int? : null;

          return ActionRun(
            name: item["name"] ?? "",
            number: item["run_number"] ?? 0,
            status: status,
            event: item["event"] ?? "",
            prNumber: prNumber,
            authorUsername: item["actor"]?["login"] ?? "",
            createdAt: DateTime.tryParse(item["created_at"] ?? "") ?? DateTime.now(),
            duration: duration,
            branch: item["head_branch"] as String?,
          );
        }).toList();

        updateCallback(actionRuns);

        final String? linkHeader = response.headers["link"];
        if (linkHeader != null) {
          final match = RegExp(r'<([^>]+)>; rel="next"').firstMatch(linkHeader);
          final String? nextLink = match?.group(1);
          if (nextLink != null) {
            nextPageCallback(() => _getActionRunsRequest(accessToken, nextLink, updateCallback, nextPageCallback));
          } else {
            nextPageCallback(null);
          }
        } else {
          nextPageCallback(null);
        }
      } else {
        // Graceful fallback: older Gitea (pre-1.19) returns 404
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
