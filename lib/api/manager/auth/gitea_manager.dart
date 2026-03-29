import 'dart:convert';
import 'package:GitSync/api/helper.dart';
import 'package:GitSync/api/logger.dart';
import 'package:GitSync/type/action_run.dart';
import 'package:GitSync/type/issue.dart';
import 'package:GitSync/type/issue_detail.dart';
import 'package:GitSync/type/issue_template.dart';
import 'package:GitSync/type/pr_detail.dart';
import 'package:GitSync/type/pull_request.dart';
import 'package:GitSync/type/release.dart';
import 'package:GitSync/type/showcase_feature.dart';
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
  Future<(String, String?)?> createRepo(String accessToken, String username, String repoName, bool isPrivate) async {
    try {
      final response = await httpPost(
        Uri.parse("https://$_domain/api/v1/user/repos"),
        headers: {"Accept": "application/json", "Authorization": "token $accessToken", "Content-Type": "application/json"},
        body: json.encode({"name": repoName, "private": isPrivate, "auto_init": false}),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> jsonData = json.decode(utf8.decode(response.bodyBytes));
        return (jsonData["clone_url"] as String, null);
      }

      if (response.statusCode == 409 && username.isNotEmpty) {
        return ("https://$_domain/$username/$repoName.git", null);
      }

      return null;
    } catch (e, st) {
      Logger.logError(LogType.GetRepos, e, st);
      return null;
    }
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
      searchString == "" ? "https://$_domain/api/v1/user/repos" : "https://$_domain/api/v1/user/repos?limit=100",
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
        final List<dynamic> jsonArray = json.decode(utf8.decode(response.bodyBytes));
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

  @override
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
  ) async {
    var url = "https://$_domain/api/v1/repos/$owner/$repo/issues?state=$state&type=issues&limit=30";

    final giteaSort = switch (sortOption) {
      "oldest" => "oldest",
      "mostCommented" => "mostcomment",
      "recentlyUpdated" => "recentupdate",
      _ => "newest",
    };
    url += "&sort=$giteaSort";

    if (authorFilter != null && authorFilter.isNotEmpty) url += "&created_by=$authorFilter";
    if (labelFilter != null && labelFilter.isNotEmpty) url += "&labels=$labelFilter";
    if (assigneeFilter != null && assigneeFilter.isNotEmpty) url += "&assigned_by=$assigneeFilter";
    if (searchFilter != null && searchFilter.isNotEmpty) url += "&q=${Uri.encodeComponent(searchFilter)}";
    if (milestoneFilter != null && milestoneFilter.isNotEmpty) url += "&milestones=${Uri.encodeComponent(milestoneFilter)}";
    await _getIssuesRequest(accessToken, url, updateCallback, nextPageCallback);
  }

  @override
  Future<List<Milestone>> getMilestones(String accessToken, String owner, String repo) async {
    try {
      final response = await httpGet(
        Uri.parse("https://$_domain/api/v1/repos/$owner/$repo/milestones?state=open&limit=100"),
        headers: {"Accept": "application/json", "Authorization": "token $accessToken"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonArray = json.decode(utf8.decode(response.bodyBytes));
        return jsonArray.map((m) => Milestone(id: m["title"] ?? "", title: m["title"] ?? "")).toList();
      }
    } catch (e, st) {
      Logger.logError(LogType.GetIssues, e, st);
    }
    return [];
  }

  @override
  Future<List<String>> getLabels(String accessToken, String owner, String repo) async {
    try {
      final response = await httpGet(
        Uri.parse("https://$_domain/api/v1/repos/$owner/$repo/labels?limit=100"),
        headers: {"Accept": "application/json", "Authorization": "token $accessToken"},
      );
      if (response.statusCode == 200) {
        final List<dynamic> jsonArray = json.decode(utf8.decode(response.bodyBytes));
        return jsonArray.map((l) => l["name"] as String? ?? "").where((n) => n.isNotEmpty).toList();
      }
    } catch (e, st) {
      Logger.logError(LogType.GetIssues, e, st);
    }
    return [];
  }

  @override
  Future<List<String>> getCollaborators(String accessToken, String owner, String repo) async {
    try {
      final response = await httpGet(
        Uri.parse("https://$_domain/api/v1/repos/$owner/$repo/collaborators?limit=100"),
        headers: {"Accept": "application/json", "Authorization": "token $accessToken"},
      );
      if (response.statusCode == 200) {
        final List<dynamic> jsonArray = json.decode(utf8.decode(response.bodyBytes));
        return jsonArray.map((c) => c["login"] as String? ?? "").where((n) => n.isNotEmpty).toList();
      }
    } catch (e, st) {
      Logger.logError(LogType.GetIssues, e, st);
    }
    return [];
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
    String? searchFilter,
    String? sortOption,
    String? reviewerFilter,
    String? milestoneFilter,
    Function(List<PullRequest>) updateCallback,
    Function(Function()?) nextPageCallback,
  ) async {
    var url = "https://$_domain/api/v1/repos/$owner/$repo/pulls?state=$state&limit=30";

    final giteaSort = switch (sortOption) {
      "oldest" => "oldest",
      "recentlyUpdated" => "recentupdate",
      _ => "newest",
    };
    url += "&sort=$giteaSort";

    if (authorFilter != null && authorFilter.isNotEmpty) url += "&created_by=$authorFilter";
    if (labelFilter != null && labelFilter.isNotEmpty) url += "&labels=$labelFilter";
    if (assigneeFilter != null && assigneeFilter.isNotEmpty) url += "&assigned_by=$assigneeFilter";
    if (searchFilter != null && searchFilter.isNotEmpty) url += "&q=${Uri.encodeComponent(searchFilter)}";
    if (milestoneFilter != null && milestoneFilter.isNotEmpty) url += "&milestones=${Uri.encodeComponent(milestoneFilter)}";
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

  @override
  Future<Map<ShowcaseFeature, int?>> getFeatureCounts(String accessToken, String owner, String repo, [List<ShowcaseFeature>? features]) async {
    final counts = <ShowcaseFeature, int?>{};
    final requested = features ?? ShowcaseFeature.values;
    final headers = {"Accept": "application/json", "Authorization": "token $accessToken"};
    final base = "https://$_domain/api/v1/repos/$owner/$repo";

    int? parseTotal(dynamic response) => response.statusCode == 200 ? int.tryParse(response.headers["x-total-count"] ?? "") : null;

    try {
      final futures = <ShowcaseFeature, Future>{};
      if (requested.contains(ShowcaseFeature.issues)) futures[ShowcaseFeature.issues] = httpGet(Uri.parse("$base/issues?state=open&type=issues&limit=1"), headers: headers);
      if (requested.contains(ShowcaseFeature.pullRequests)) futures[ShowcaseFeature.pullRequests] = httpGet(Uri.parse("$base/pulls?state=open&limit=1"), headers: headers);
      if (requested.contains(ShowcaseFeature.tags)) futures[ShowcaseFeature.tags] = httpGet(Uri.parse("$base/tags?limit=1"), headers: headers);
      if (requested.contains(ShowcaseFeature.releases)) futures[ShowcaseFeature.releases] = httpGet(Uri.parse("$base/releases?limit=1"), headers: headers);
      if (requested.contains(ShowcaseFeature.actions)) futures[ShowcaseFeature.actions] = httpGet(Uri.parse("$base/actions/tasks?limit=1"), headers: headers);

      final results = await Future.wait(futures.values);
      final keys = futures.keys.toList();
      for (var i = 0; i < keys.length; i++) {
        counts[keys[i]] = parseTotal(results[i]);
      }
    } catch (e, st) {
      Logger.logError(LogType.GetFeatureCounts, e, st);
    }
    return counts;
  }

  @override
  Future<IssueDetail?> getIssueDetail(String accessToken, String owner, String repo, int issueNumber) async {
    try {
      final headers = {"Accept": "application/json", "Authorization": "token $accessToken"};

      // Fetch issue, comments, and reactions in parallel
      final results = await Future.wait([
        httpGet(Uri.parse("https://$_domain/api/v1/repos/$owner/$repo/issues/$issueNumber"), headers: headers),
        httpGet(Uri.parse("https://$_domain/api/v1/repos/$owner/$repo/issues/$issueNumber/comments"), headers: headers),
        httpGet(Uri.parse("https://$_domain/api/v1/repos/$owner/$repo/issues/$issueNumber/reactions"), headers: headers),
      ]);

      final issueResp = results[0];
      final commentsResp = results[1];
      final reactionsResp = results[2];

      if (issueResp.statusCode != 200) return null;

      final issue = json.decode(utf8.decode(issueResp.bodyBytes));

      // Get viewer username
      final userResp = await httpGet(Uri.parse("https://$_domain/api/v1/user"), headers: headers);
      final viewerLogin = userResp.statusCode == 200 ? (json.decode(utf8.decode(userResp.bodyBytes))["login"] as String? ?? "") : "";

      // Parse viewer permission from repo permissions
      ViewerPermission permission = ViewerPermission.read;
      final repoResp = await httpGet(Uri.parse("https://$_domain/api/v1/repos/$owner/$repo"), headers: headers);
      if (repoResp.statusCode == 200) {
        final repoData = json.decode(utf8.decode(repoResp.bodyBytes));
        final perms = repoData["permissions"] as Map<String, dynamic>?;
        if (perms?["admin"] == true) {
          permission = ViewerPermission.admin;
        } else if (perms?["push"] == true) {
          permission = ViewerPermission.write;
        } else if (perms?["pull"] == true) {
          permission = ViewerPermission.read;
        }
      }

      // Parse issue reactions
      List<IssueReaction> reactions = [];
      if (reactionsResp.statusCode == 200) {
        final reactionList = json.decode(utf8.decode(reactionsResp.bodyBytes)) as List<dynamic>;
        final Map<String, (int, bool)> counts = {};
        for (final r in reactionList) {
          final content = r["type"] as String? ?? "";
          final isViewer = (r["user"]?["login"] as String? ?? "") == viewerLogin;
          final existing = counts[content];
          counts[content] = ((existing?.$1 ?? 0) + 1, (existing?.$2 ?? false) || isViewer);
        }
        reactions = counts.entries.map((e) => IssueReaction(content: e.key, count: e.value.$1, viewerHasReacted: e.value.$2)).toList();
      }

      // Parse comments
      List<IssueComment> comments = [];
      if (commentsResp.statusCode == 200) {
        final commentList = json.decode(utf8.decode(commentsResp.bodyBytes)) as List<dynamic>;
        for (final c in commentList) {
          // Fetch per-comment reactions
          List<IssueReaction> commentReactions = [];
          try {
            final crResp = await httpGet(
              Uri.parse("https://$_domain/api/v1/repos/$owner/$repo/issues/comments/${c["id"]}/reactions"),
              headers: headers,
            );
            if (crResp.statusCode == 200) {
              final crList = json.decode(utf8.decode(crResp.bodyBytes)) as List<dynamic>;
              final Map<String, (int, bool)> crCounts = {};
              for (final r in crList) {
                final content = r["type"] as String? ?? "";
                final isViewer = (r["user"]?["login"] as String? ?? "") == viewerLogin;
                final existing = crCounts[content];
                crCounts[content] = ((existing?.$1 ?? 0) + 1, (existing?.$2 ?? false) || isViewer);
              }
              commentReactions = crCounts.entries.map((e) => IssueReaction(content: e.key, count: e.value.$1, viewerHasReacted: e.value.$2)).toList();
            }
          } catch (_) {}

          comments.add(IssueComment(
            id: "${c["id"]}",
            authorUsername: c["user"]?["login"] ?? "",
            body: c["body"] ?? "",
            createdAt: DateTime.tryParse(c["created_at"] ?? "") ?? DateTime.now(),
            reactions: commentReactions,
          ));
        }
      }

      return IssueDetail(
        id: "${issue["id"]}",
        title: issue["title"] ?? "",
        number: issue["number"] ?? 0,
        isOpen: issue["state"] == "open",
        authorUsername: issue["user"]?["login"] ?? "",
        createdAt: DateTime.tryParse(issue["created_at"] ?? "") ?? DateTime.now(),
        body: issue["body"] ?? "",
        labels: (issue["labels"] as List<dynamic>?)
                ?.map((l) => IssueLabel(name: l["name"] ?? "", color: l["color"]))
                .toList() ??
            [],
        reactions: reactions,
        comments: comments,
        viewerPermission: permission,
      );
    } catch (e, st) {
      Logger.logError(LogType.GetIssueDetail, e, st);
      return null;
    }
  }

  @override
  Future<PrDetail?> getPrDetail(String accessToken, String owner, String repo, int prNumber) async {
    try {
      final headers = {"Accept": "application/json", "Authorization": "token $accessToken"};

      // Fetch PR detail, comments, commits, files, reactions, and reviews in parallel
      final results = await Future.wait([
        httpGet(Uri.parse("https://$_domain/api/v1/repos/$owner/$repo/pulls/$prNumber"), headers: headers),
        httpGet(Uri.parse("https://$_domain/api/v1/repos/$owner/$repo/issues/$prNumber/comments"), headers: headers),
        httpGet(Uri.parse("https://$_domain/api/v1/repos/$owner/$repo/pulls/$prNumber/commits"), headers: headers),
        httpGet(Uri.parse("https://$_domain/api/v1/repos/$owner/$repo/pulls/$prNumber/files"), headers: headers),
        httpGet(Uri.parse("https://$_domain/api/v1/repos/$owner/$repo/issues/$prNumber/reactions"), headers: headers),
        httpGet(Uri.parse("https://$_domain/api/v1/repos/$owner/$repo/pulls/$prNumber/reviews"), headers: headers),
      ]);

      final prResp = results[0];
      final commentsResp = results[1];
      final commitsResp = results[2];
      final filesResp = results[3];
      final reactionsResp = results[4];
      final reviewsResp = results[5];

      if (prResp.statusCode != 200) return null;

      final pr = json.decode(utf8.decode(prResp.bodyBytes));

      // Get viewer username
      final userResp = await httpGet(Uri.parse("https://$_domain/api/v1/user"), headers: headers);
      final viewerLogin = userResp.statusCode == 200 ? (json.decode(utf8.decode(userResp.bodyBytes))["login"] as String? ?? "") : "";

      // Viewer permission
      ViewerPermission permission = ViewerPermission.read;
      final repoResp = await httpGet(Uri.parse("https://$_domain/api/v1/repos/$owner/$repo"), headers: headers);
      if (repoResp.statusCode == 200) {
        final repoData = json.decode(utf8.decode(repoResp.bodyBytes));
        final perms = repoData["permissions"] as Map<String, dynamic>?;
        if (perms?["admin"] == true) {
          permission = ViewerPermission.admin;
        } else if (perms?["push"] == true) {
          permission = ViewerPermission.write;
        } else if (perms?["pull"] == true) {
          permission = ViewerPermission.read;
        }
      }

      // State
      final bool isMerged = pr["merged"] == true || (pr["merged_at"] != null && pr["merged_at"] != "");
      final prState = isMerged
          ? PrState.merged
          : pr["state"] == "open"
              ? PrState.open
              : PrState.closed;

      // Reactions
      List<IssueReaction> reactions = [];
      if (reactionsResp.statusCode == 200) {
        final reactionList = json.decode(utf8.decode(reactionsResp.bodyBytes)) as List<dynamic>;
        final Map<String, (int, bool)> counts = {};
        for (final r in reactionList) {
          final content = r["type"] as String? ?? "";
          final isViewer = (r["user"]?["login"] as String? ?? "") == viewerLogin;
          final existing = counts[content];
          counts[content] = ((existing?.$1 ?? 0) + 1, (existing?.$2 ?? false) || isViewer);
        }
        reactions = counts.entries.map((e) => IssueReaction(content: e.key, count: e.value.$1, viewerHasReacted: e.value.$2)).toList();
      }

      // Commits
      final List<PrCommit> commits = [];
      if (commitsResp.statusCode == 200) {
        final commitList = json.decode(utf8.decode(commitsResp.bodyBytes)) as List<dynamic>;
        for (final c in commitList) {
          final sha = c["sha"] as String? ?? "";
          commits.add(PrCommit(
            sha: sha,
            shortSha: sha.substring(0, sha.length.clamp(0, 7)),
            message: c["commit"]?["message"] ?? "",
            authorUsername: c["author"]?["login"] ?? c["commit"]?["author"]?["name"] ?? "",
            createdAt: DateTime.tryParse(c["commit"]?["author"]?["date"] ?? c["created"] ?? "") ?? DateTime.now(),
          ));
        }
      }

      // Comments
      final List<IssueComment> commentList = [];
      if (commentsResp.statusCode == 200) {
        final comments = json.decode(utf8.decode(commentsResp.bodyBytes)) as List<dynamic>;
        for (final c in comments) {
          List<IssueReaction> commentReactions = [];
          try {
            final crResp = await httpGet(
              Uri.parse("https://$_domain/api/v1/repos/$owner/$repo/issues/comments/${c["id"]}/reactions"),
              headers: headers,
            );
            if (crResp.statusCode == 200) {
              final crList = json.decode(utf8.decode(crResp.bodyBytes)) as List<dynamic>;
              final Map<String, (int, bool)> crCounts = {};
              for (final r in crList) {
                final content = r["type"] as String? ?? "";
                final isViewer = (r["user"]?["login"] as String? ?? "") == viewerLogin;
                final existing = crCounts[content];
                crCounts[content] = ((existing?.$1 ?? 0) + 1, (existing?.$2 ?? false) || isViewer);
              }
              commentReactions = crCounts.entries.map((e) => IssueReaction(content: e.key, count: e.value.$1, viewerHasReacted: e.value.$2)).toList();
            }
          } catch (_) {}

          commentList.add(IssueComment(
            id: "${c["id"]}",
            authorUsername: c["user"]?["login"] ?? "",
            body: c["body"] ?? "",
            createdAt: DateTime.tryParse(c["created_at"] ?? "") ?? DateTime.now(),
            reactions: commentReactions,
          ));
        }
      }

      // Fetch timeline for cross-references
      final List<PrTimelineItem> crossRefItems = [];
      try {
        final timelineResp = await httpGet(
          Uri.parse("https://$_domain/api/v1/repos/$owner/$repo/issues/$prNumber/timeline"),
          headers: headers,
        );
        if (timelineResp.statusCode == 200) {
          final events = json.decode(utf8.decode(timelineResp.bodyBytes)) as List<dynamic>;
          for (final event in events) {
            final eventType = event["type"] as String? ?? "";
            if (eventType == "commit_ref" || eventType == "cross_ref" || eventType == "ref") {
              final refIssue = event["ref_issue"] as Map<String, dynamic>?;
              final refComment = event["ref_comment"] as Map<String, dynamic>?;
              final createdAt = DateTime.tryParse(event["created_at"] ?? "") ?? DateTime.now();
              final actorUsername = event["user"]?["login"] as String? ?? "";

              if (refIssue != null) {
                final isPr = refIssue["pull_request"] != null;
                final crossRef = PrCrossReference(
                  sourceType: isPr ? "PullRequest" : "Issue",
                  sourceNumber: refIssue["number"] as int? ?? 0,
                  sourceTitle: refIssue["title"] as String? ?? "",
                  isCrossRepository: false,
                  actorUsername: actorUsername,
                  createdAt: createdAt,
                );
                crossRefItems.add(PrTimelineItem(type: PrTimelineItemType.crossReference, crossReference: crossRef, createdAt: createdAt));
              } else if (refComment != null) {
                final refIssueInComment = refComment["ref_issue"] as Map<String, dynamic>?;
                if (refIssueInComment != null) {
                  final isPr = refIssueInComment["pull_request"] != null;
                  final crossRef = PrCrossReference(
                    sourceType: isPr ? "PullRequest" : "Issue",
                    sourceNumber: refIssueInComment["number"] as int? ?? 0,
                    sourceTitle: refIssueInComment["title"] as String? ?? "",
                    isCrossRepository: false,
                    actorUsername: actorUsername,
                    createdAt: createdAt,
                  );
                  crossRefItems.add(PrTimelineItem(type: PrTimelineItemType.crossReference, crossReference: crossRef, createdAt: createdAt));
                }
              }
            }
          }
        }
      } catch (_) {}

      // Interleave comments + commits + cross-references into timeline
      final List<PrTimelineItem> timelineItems = [];
      for (final comment in commentList) {
        timelineItems.add(PrTimelineItem(type: PrTimelineItemType.comment, comment: comment, createdAt: comment.createdAt));
      }
      for (final commit in commits) {
        timelineItems.add(PrTimelineItem(type: PrTimelineItemType.commit, commit: commit, createdAt: commit.createdAt));
      }
      timelineItems.addAll(crossRefItems);
      timelineItems.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      // Changed files
      final List<PrChangedFile> changedFiles = [];
      int totalAdditions = 0;
      int totalDeletions = 0;
      if (filesResp.statusCode == 200) {
        final files = json.decode(utf8.decode(filesResp.bodyBytes)) as List<dynamic>;
        for (final f in files) {
          final adds = f["additions"] as int? ?? 0;
          final dels = f["deletions"] as int? ?? 0;
          totalAdditions += adds;
          totalDeletions += dels;
          changedFiles.add(PrChangedFile(
            filename: f["filename"] ?? "",
            additions: adds,
            deletions: dels,
            status: f["status"] ?? "modified",
            patch: f["patch"] as String?,
          ));
        }
      }

      // Check status from head commit
      final List<PrCheckRun> checkRuns = [];
      CheckStatus overallCheckStatus = CheckStatus.none;
      final headSha = pr["head"]?["sha"] as String? ?? "";
      if (headSha.isNotEmpty) {
        try {
          final statusResp = await httpGet(
            Uri.parse("https://$_domain/api/v1/repos/$owner/$repo/commits/$headSha/status"),
            headers: headers,
          );
          if (statusResp.statusCode == 200) {
            final statusData = json.decode(utf8.decode(statusResp.bodyBytes));
            final state = statusData["state"] as String? ?? "";
            overallCheckStatus = switch (state) {
              "success" => CheckStatus.success,
              "failure" || "error" => CheckStatus.failure,
              "pending" || "warning" => CheckStatus.pending,
              _ => CheckStatus.none,
            };
            final statuses = statusData["statuses"] as List<dynamic>? ?? [];
            for (final s in statuses) {
              final sState = s["status"] as String? ?? "";
              final CheckRunStatus crStatus = switch (sState) {
                "success" || "failure" || "error" => CheckRunStatus.completed,
                "pending" => CheckRunStatus.queued,
                _ => CheckRunStatus.queued,
              };
              final String? conclusion = switch (sState) {
                "success" => "success",
                "failure" || "error" => "failure",
                _ => null,
              };
              checkRuns.add(PrCheckRun(
                name: s["context"] ?? s["description"] ?? "",
                status: crStatus,
                conclusion: conclusion,
                startedAt: DateTime.tryParse(s["created_at"] ?? ""),
              ));
            }
          }
        } catch (_) {}
      }

      // Reviews
      final List<PrReview> reviews = [];
      if (reviewsResp.statusCode == 200) {
        final reviewList = json.decode(utf8.decode(reviewsResp.bodyBytes)) as List<dynamic>;
        for (final r in reviewList) {
          final stateStr = r["state"] as String? ?? "";
          final state = switch (stateStr) {
            "APPROVED" => PrReviewState.approved,
            "REQUEST_CHANGES" => PrReviewState.changesRequested,
            "COMMENT" => PrReviewState.commented,
            _ => PrReviewState.pending,
          };
          reviews.add(PrReview(
            authorUsername: r["user"]?["login"] ?? "",
            state: state,
            createdAt: DateTime.tryParse(r["submitted_at"] ?? "") ?? DateTime.now(),
          ));
        }
      }

      return PrDetail(
        id: "${pr["id"]}",
        title: pr["title"] ?? "",
        body: pr["body"] ?? "",
        authorUsername: pr["user"]?["login"] ?? "",
        baseBranch: pr["base"]?["label"] ?? "",
        headBranch: pr["head"]?["label"] ?? "",
        headRepoOwner: pr["head"]?["repo"]?["owner"]?["login"] ?? pr["user"]?["login"] ?? "",
        number: pr["number"] ?? 0,
        additions: totalAdditions,
        deletions: totalDeletions,
        changedFileCount: changedFiles.length,
        state: prState,
        createdAt: DateTime.tryParse(pr["created_at"] ?? "") ?? DateTime.now(),
        labels: (pr["labels"] as List<dynamic>?)
                ?.map((l) => IssueLabel(name: l["name"] ?? "", color: l["color"]))
                .toList() ??
            [],
        reactions: reactions,
        timelineItems: timelineItems,
        commits: commits,
        checkRuns: checkRuns,
        changedFiles: changedFiles,
        reviews: reviews,
        overallCheckStatus: overallCheckStatus,
        viewerPermission: permission,
      );
    } catch (e, st) {
      Logger.logError(LogType.GetPrDetail, e, st);
      return null;
    }
  }

  @override
  Future<IssueComment?> addIssueComment(String accessToken, String owner, String repo, int issueNumber, String body) async {
    try {
      final response = await httpPost(
        Uri.parse("https://$_domain/api/v1/repos/$owner/$repo/issues/$issueNumber/comments"),
        headers: {"Authorization": "token $accessToken", "Content-Type": "application/json", "Accept": "application/json"},
        body: json.encode({"body": body}),
      );

      if (response.statusCode == 201) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return IssueComment(
          id: "${data["id"]}",
          authorUsername: data["user"]?["login"] ?? "",
          body: data["body"] ?? "",
          createdAt: DateTime.tryParse(data["created_at"] ?? "") ?? DateTime.now(),
        );
      }
      return null;
    } catch (e, st) {
      Logger.logError(LogType.AddIssueComment, e, st);
      return null;
    }
  }

  @override
  Future<bool> updateIssueState(String accessToken, String owner, String repo, int issueNumber, String issueId, bool close) async {
    try {
      final response = await httpPatch(
        Uri.parse("https://$_domain/api/v1/repos/$owner/$repo/issues/$issueNumber"),
        headers: {"Authorization": "token $accessToken", "Content-Type": "application/json"},
        body: json.encode({"state": close ? "closed" : "open"}),
      );

      return response.statusCode == 200;
    } catch (e, st) {
      Logger.logError(LogType.UpdateIssueState, e, st);
      return false;
    }
  }

  @override
  Future<bool> addReaction(String accessToken, String owner, String repo, int issueNumber, String targetId, String reaction, bool isComment) async {
    try {
      final String url;
      if (isComment) {
        url = "https://$_domain/api/v1/repos/$owner/$repo/issues/comments/$targetId/reactions";
      } else {
        url = "https://$_domain/api/v1/repos/$owner/$repo/issues/$issueNumber/reactions";
      }

      final response = await httpPost(
        Uri.parse(url),
        headers: {"Authorization": "token $accessToken", "Content-Type": "application/json"},
        body: json.encode({"content": reaction}),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e, st) {
      Logger.logError(LogType.AddReaction, e, st);
      return false;
    }
  }

  @override
  Future<bool> removeReaction(String accessToken, String owner, String repo, int issueNumber, String targetId, String reaction, bool isComment) async {
    try {
      final String url;
      if (isComment) {
        url = "https://$_domain/api/v1/repos/$owner/$repo/issues/comments/$targetId/reactions";
      } else {
        url = "https://$_domain/api/v1/repos/$owner/$repo/issues/$issueNumber/reactions";
      }

      final response = await httpDelete(
        Uri.parse(url),
        headers: {"Authorization": "token $accessToken", "Content-Type": "application/json"},
        body: json.encode({"content": reaction}),
      );

      return response.statusCode == 200;
    } catch (e, st) {
      Logger.logError(LogType.RemoveReaction, e, st);
      return false;
    }
  }

  @override
  Future<CreateIssueResult?> createIssue(String accessToken, String owner, String repo, String title, String body, {List<String>? labels, List<String>? assignees}) async {
    try {
      final response = await httpPost(
        Uri.parse("https://$_domain/api/v1/repos/$owner/$repo/issues"),
        headers: {"Authorization": "token $accessToken", "Content-Type": "application/json", "Accept": "application/json"},
        body: json.encode({"title": title, "body": body}),
      );

      if (response.statusCode == 201) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return CreateIssueResult(number: data["number"] as int, htmlUrl: data["html_url"]?.toString());
      }
      final responseBody = utf8.decode(response.bodyBytes);
      Logger.logError(LogType.CreateIssue, "HTTP ${response.statusCode}: $responseBody", StackTrace.current);
      try {
        final data = json.decode(responseBody);
        final message = data["message"]?.toString();
        if (message != null && message.isNotEmpty) return CreateIssueResult.failure(message);
      } catch (_) {}
      return CreateIssueResult.failure(responseBody);
    } catch (e, st) {
      Logger.logError(LogType.CreateIssue, e, st);
      return CreateIssueResult.failure(e.toString());
    }
  }

  @override
  Future<bool> updateIssue(String accessToken, String owner, String repo, int issueNumber, {String? title, String? body}) async {
    try {
      final payload = <String, dynamic>{};
      if (title != null) payload["title"] = title;
      if (body != null) payload["body"] = body;

      final response = await httpPatch(
        Uri.parse("https://$_domain/api/v1/repos/$owner/$repo/issues/$issueNumber"),
        headers: {"Authorization": "token $accessToken", "Content-Type": "application/json", "Accept": "application/json"},
        body: json.encode(payload),
      );

      return response.statusCode == 200;
    } catch (e, st) {
      Logger.logError(LogType.UpdateIssue, e, st);
      return false;
    }
  }

  @override
  Future<CreateIssueResult?> createPullRequest(String accessToken, String owner, String repo, String title, String body, String head, String base) async {
    try {
      final response = await httpPost(
        Uri.parse("https://$_domain/api/v1/repos/$owner/$repo/pulls"),
        headers: {"Authorization": "token $accessToken", "Content-Type": "application/json", "Accept": "application/json"},
        body: json.encode({"title": title, "body": body, "head": head, "base": base}),
      );

      if (response.statusCode == 201) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return CreateIssueResult(number: data["number"] as int, htmlUrl: data["html_url"]?.toString());
      }
      final responseBody = utf8.decode(response.bodyBytes);
      Logger.logError(LogType.CreatePullRequest, "HTTP ${response.statusCode}: $responseBody", StackTrace.current);
      try {
        final data = json.decode(responseBody);
        final message = data["message"]?.toString();
        if (message != null && message.isNotEmpty) return CreateIssueResult.failure(message);
      } catch (_) {}
      return CreateIssueResult.failure(responseBody);
    } catch (e, st) {
      Logger.logError(LogType.CreatePullRequest, e, st);
      return CreateIssueResult.failure(e.toString());
    }
  }

  @override
  Future<(List<String>, String?)> getRepoBranches(String accessToken, String owner, String repo) async {
    try {
      final results = await Future.wait([
        httpGet(
          Uri.parse("https://$_domain/api/v1/repos/$owner/$repo/branches?limit=100"),
          headers: {"Authorization": "token $accessToken", "Accept": "application/json"},
        ),
        httpGet(
          Uri.parse("https://$_domain/api/v1/repos/$owner/$repo"),
          headers: {"Authorization": "token $accessToken", "Accept": "application/json"},
        ),
      ]);

      final branches = <String>[];
      if (results[0].statusCode == 200) {
        final list = json.decode(utf8.decode(results[0].bodyBytes)) as List;
        for (final b in list) {
          branches.add(b["name"]?.toString() ?? '');
        }
      }

      String? defaultBranch;
      if (results[1].statusCode == 200) {
        final data = json.decode(utf8.decode(results[1].bodyBytes));
        defaultBranch = data["default_branch"]?.toString();
      }

      return (branches, defaultBranch);
    } catch (e, st) {
      Logger.logError(LogType.GetRepoBranches, e, st);
      return (<String>[], null);
    }
  }
}
