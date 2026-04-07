import 'dart:convert';
import 'package:GitSync/api/helper.dart';
import 'package:GitSync/api/logger.dart';
import 'package:GitSync/constant/reactions.dart';
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

class GitlabManager extends GitProviderManager {
  static const String _domain = "gitlab.com";

  GitlabManager();

  bool get oAuthSupport => true;

  get clientId => gitlabClientId;
  get clientSecret => gitlabClientSecret;
  get scopes => ["read_user", "api", "write_repository"];

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
  Future<(String, String?)?> createRepo(String accessToken, String username, String repoName, bool isPrivate) async {
    try {
      final response = await httpPost(
        Uri.parse("https://$_domain/api/v4/projects"),
        headers: {"Authorization": "Bearer $accessToken", "Content-Type": "application/json"},
        body: json.encode({"name": repoName, "visibility": isPrivate ? "private" : "public"}),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> jsonData = json.decode(utf8.decode(response.bodyBytes));
        return (jsonData["http_url_to_repo"] as String, null);
      }

      if (response.statusCode == 400 && username.isNotEmpty) {
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
    String? searchFilter,
    String? sortOption,
    String? milestoneFilter,
    String? projectFilter,
    Function(List<Issue>) updateCallback,
    Function(Function()?) nextPageCallback,
  ) async {
    final gitlabState = state == "open" ? "opened" : state;
    var url = "https://$_domain/api/v4/projects/$owner%2F$repo/issues?state=$gitlabState&per_page=30";

    switch (sortOption) {
      case "oldest":
        url += "&order_by=created_at&sort=asc";
      case "recentlyUpdated":
        url += "&order_by=updated_at&sort=desc";
      default:
        url += "&order_by=created_at&sort=desc";
    }

    if (authorFilter != null && authorFilter.isNotEmpty) url += "&author_username=$authorFilter";
    if (labelFilter != null && labelFilter.isNotEmpty) url += "&labels=$labelFilter";
    if (assigneeFilter != null && assigneeFilter.isNotEmpty) url += "&assignee_username=$assigneeFilter";
    if (searchFilter != null && searchFilter.isNotEmpty) url += "&search=${Uri.encodeComponent(searchFilter)}";
    if (milestoneFilter != null && milestoneFilter.isNotEmpty) url += "&milestone=${Uri.encodeComponent(milestoneFilter)}";
    await _getIssuesRequest(accessToken, url, updateCallback, nextPageCallback);
  }

  @override
  Future<List<Milestone>> getMilestones(String accessToken, String owner, String repo) async {
    try {
      final response = await httpGet(
        Uri.parse("https://$_domain/api/v4/projects/$owner%2F$repo/milestones?state=active&per_page=100"),
        headers: {"Authorization": "Bearer $accessToken"},
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
        Uri.parse("https://$_domain/api/v4/projects/$owner%2F$repo/labels?per_page=100"),
        headers: {"Authorization": "Bearer $accessToken"},
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
        Uri.parse("https://$_domain/api/v4/projects/$owner%2F$repo/members?per_page=100"),
        headers: {"Authorization": "Bearer $accessToken"},
      );
      if (response.statusCode == 200) {
        final List<dynamic> jsonArray = json.decode(utf8.decode(response.bodyBytes));
        return jsonArray.map((m) => m["username"] as String? ?? "").where((n) => n.isNotEmpty).toList();
      }
    } catch (e, st) {
      Logger.logError(LogType.GetIssues, e, st);
    }
    return [];
  }

  Future<void> _getIssuesRequest(String accessToken, String url, Function(List<Issue>) updateCallback, Function(Function()?) nextPageCallback) async {
    try {
      final response = await httpGet(Uri.parse(url), headers: {"Authorization": "Bearer $accessToken"});

      if (response.statusCode == 200) {
        final List<dynamic> jsonArray = json.decode(utf8.decode(response.bodyBytes));
        final List<Issue> issues = jsonArray
            .map(
              (item) => Issue(
                title: item["title"] ?? "",
                number: item["iid"] ?? 0,
                isOpen: item["state"] == "opened",
                authorUsername: item["author"]?["username"] ?? "",
                createdAt: DateTime.tryParse(item["created_at"] ?? "") ?? DateTime.now(),
                commentCount: item["user_notes_count"] ?? 0,
                labels: (item["labels"] as List<dynamic>?)?.map((l) => IssueLabel(name: l.toString())).toList() ?? [],
              ),
            )
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
    String? searchFilter,
    String? sortOption,
    String? reviewerFilter,
    String? milestoneFilter,
    Function(List<PullRequest>) updateCallback,
    Function(Function()?) nextPageCallback,
  ) async {
    final gitlabState = state == "open" ? "opened" : state;
    var url = "https://$_domain/api/v4/projects/$owner%2F$repo/merge_requests?state=$gitlabState&per_page=30";

    switch (sortOption) {
      case "oldest":
        url += "&order_by=created_at&sort=asc";
      case "recentlyUpdated":
        url += "&order_by=updated_at&sort=desc";
      default:
        url += "&order_by=created_at&sort=desc";
    }

    if (authorFilter != null && authorFilter.isNotEmpty) url += "&author_username=$authorFilter";
    if (labelFilter != null && labelFilter.isNotEmpty) url += "&labels=$labelFilter";
    if (assigneeFilter != null && assigneeFilter.isNotEmpty) url += "&assignee_username=$assigneeFilter";
    if (searchFilter != null && searchFilter.isNotEmpty) url += "&search=${Uri.encodeComponent(searchFilter)}";
    if (reviewerFilter != null && reviewerFilter.isNotEmpty) url += "&reviewer_username=$reviewerFilter";
    if (milestoneFilter != null && milestoneFilter.isNotEmpty) url += "&milestone=${Uri.encodeComponent(milestoneFilter)}";
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
        final List<PullRequest> prs = jsonArray.map((item) {
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
        }).toList();

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

  Future<void> _getTagsRequest(String accessToken, String url, Function(List<Tag>) updateCallback, Function(Function()?) nextPageCallback) async {
    try {
      final response = await httpGet(Uri.parse(url), headers: {"Authorization": "Bearer $accessToken"});

      if (response.statusCode == 200) {
        final List<dynamic> jsonArray = json.decode(utf8.decode(response.bodyBytes));
        final List<Tag> tags = jsonArray
            .map(
              (item) => Tag(
                name: item["name"] ?? "",
                sha: item["target"] ?? "",
                createdAt: DateTime.tryParse(item["commit"]?["created_at"] ?? "") ?? DateTime.now(),
                message: (item["message"] as String?)?.isNotEmpty == true ? item["message"] as String : null,
              ),
            )
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

  @override
  Future<Map<ShowcaseFeature, int?>> getFeatureCounts(String accessToken, String owner, String repo, [List<ShowcaseFeature>? features]) async {
    final counts = <ShowcaseFeature, int?>{};
    final requested = features ?? ShowcaseFeature.values;
    final headers = {"Authorization": "Bearer $accessToken"};
    final base = "https://$_domain/api/v4/projects/$owner%2F$repo";

    int? parseTotal(dynamic response) => response.statusCode == 200 ? int.tryParse(response.headers["x-total"] ?? "") : null;

    try {
      final futures = <ShowcaseFeature, Future>{};
      if (requested.contains(ShowcaseFeature.issues))
        futures[ShowcaseFeature.issues] = httpGet(Uri.parse("$base/issues?state=opened&per_page=1"), headers: headers);
      if (requested.contains(ShowcaseFeature.pullRequests))
        futures[ShowcaseFeature.pullRequests] = httpGet(Uri.parse("$base/merge_requests?state=opened&per_page=1"), headers: headers);
      if (requested.contains(ShowcaseFeature.tags))
        futures[ShowcaseFeature.tags] = httpGet(Uri.parse("$base/repository/tags?per_page=1"), headers: headers);
      if (requested.contains(ShowcaseFeature.releases))
        futures[ShowcaseFeature.releases] = httpGet(Uri.parse("$base/releases?per_page=1"), headers: headers);
      if (requested.contains(ShowcaseFeature.actions))
        futures[ShowcaseFeature.actions] = httpGet(Uri.parse("$base/pipelines?per_page=1"), headers: headers);

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
      final projectId = "$owner%2F$repo";
      final headers = {"Authorization": "Bearer $accessToken"};

      // Fetch issue, notes, and award_emoji in parallel
      final results = await Future.wait([
        httpGet(Uri.parse("https://$_domain/api/v4/projects/$projectId/issues/$issueNumber"), headers: headers),
        httpGet(Uri.parse("https://$_domain/api/v4/projects/$projectId/issues/$issueNumber/notes?per_page=100&sort=asc"), headers: headers),
        httpGet(Uri.parse("https://$_domain/api/v4/projects/$projectId/issues/$issueNumber/award_emoji"), headers: headers),
      ]);

      final issueResp = results[0];
      final notesResp = results[1];
      final emojiResp = results[2];

      if (issueResp.statusCode != 200) return null;

      final issue = json.decode(utf8.decode(issueResp.bodyBytes));

      // Get viewer username for reaction matching
      final userResp = await httpGet(Uri.parse("https://$_domain/api/v4/user"), headers: headers);
      final viewerUsername = userResp.statusCode == 200 ? (json.decode(utf8.decode(userResp.bodyBytes))["username"] as String? ?? "") : "";

      // Parse issue reactions
      final List<IssueReaction> reactions = [];
      if (emojiResp.statusCode == 200) {
        final emojis = json.decode(utf8.decode(emojiResp.bodyBytes)) as List<dynamic>;
        final Map<String, (int, bool, int?)> counts = {};
        for (final emoji in emojis) {
          final name = gitlabReactionNamesReverse[emoji["name"] as String? ?? ""] ?? (emoji["name"] as String? ?? "");
          final isViewer = (emoji["user"]?["username"] as String? ?? "") == viewerUsername;
          final awardId = emoji["id"] as int?;
          final existing = counts[name];
          counts[name] = ((existing?.$1 ?? 0) + 1, (existing?.$2 ?? false) || isViewer, isViewer ? awardId : existing?.$3);
        }
        for (final e in counts.entries) {
          reactions.add(IssueReaction(content: e.key, count: e.value.$1, viewerHasReacted: e.value.$2, awardId: e.value.$3));
        }
      }

      // Parse comments (notes), filtering out system notes
      final List<IssueComment> comments = [];
      if (notesResp.statusCode == 200) {
        final notes = json.decode(utf8.decode(notesResp.bodyBytes)) as List<dynamic>;
        for (final note in notes) {
          if (note["system"] == true) continue;

          // Fetch per-note reactions
          List<IssueReaction> noteReactions = [];
          try {
            final noteEmojiResp = await httpGet(
              Uri.parse("https://$_domain/api/v4/projects/$projectId/issues/$issueNumber/notes/${note["id"]}/award_emoji"),
              headers: headers,
            );
            if (noteEmojiResp.statusCode == 200) {
              final noteEmojis = json.decode(utf8.decode(noteEmojiResp.bodyBytes)) as List<dynamic>;
              final Map<String, (int, bool, int?)> noteCounts = {};
              for (final emoji in noteEmojis) {
                final name = gitlabReactionNamesReverse[emoji["name"] as String? ?? ""] ?? (emoji["name"] as String? ?? "");
                final isViewer = (emoji["user"]?["username"] as String? ?? "") == viewerUsername;
                final awardId = emoji["id"] as int?;
                final existing = noteCounts[name];
                noteCounts[name] = ((existing?.$1 ?? 0) + 1, (existing?.$2 ?? false) || isViewer, isViewer ? awardId : existing?.$3);
              }
              noteReactions = noteCounts.entries
                  .map((e) => IssueReaction(content: e.key, count: e.value.$1, viewerHasReacted: e.value.$2, awardId: e.value.$3))
                  .toList();
            }
          } catch (_) {}

          comments.add(
            IssueComment(
              id: "${note["id"]}",
              authorUsername: note["author"]?["username"] ?? "",
              body: note["body"] ?? "",
              createdAt: DateTime.tryParse(note["created_at"] ?? "") ?? DateTime.now(),
              reactions: noteReactions,
            ),
          );
        }
      }

      return IssueDetail(
        id: "${issue["iid"]}",
        title: issue["title"] ?? "",
        number: issue["iid"] ?? 0,
        isOpen: issue["state"] == "opened",
        authorUsername: issue["author"]?["username"] ?? "",
        createdAt: DateTime.tryParse(issue["created_at"] ?? "") ?? DateTime.now(),
        body: issue["description"] ?? "",
        labels: (issue["labels"] as List<dynamic>?)?.map((l) => IssueLabel(name: l.toString())).toList() ?? [],
        reactions: reactions,
        comments: comments,
        viewerPermission: ViewerPermission.write,
      );
    } catch (e, st) {
      Logger.logError(LogType.GetIssueDetail, e, st);
      return null;
    }
  }

  @override
  Future<PrDetail?> getPrDetail(String accessToken, String owner, String repo, int prNumber) async {
    try {
      final projectId = "$owner%2F$repo";
      final headers = {"Authorization": "Bearer $accessToken"};

      // Fetch MR detail, notes, commits, changes, pipelines, and award emoji in parallel
      final results = await Future.wait([
        httpGet(Uri.parse("https://$_domain/api/v4/projects/$projectId/merge_requests/$prNumber"), headers: headers),
        httpGet(Uri.parse("https://$_domain/api/v4/projects/$projectId/merge_requests/$prNumber/notes?per_page=100&sort=asc"), headers: headers),
        httpGet(Uri.parse("https://$_domain/api/v4/projects/$projectId/merge_requests/$prNumber/commits"), headers: headers),
        httpGet(Uri.parse("https://$_domain/api/v4/projects/$projectId/merge_requests/$prNumber/changes"), headers: headers),
        httpGet(Uri.parse("https://$_domain/api/v4/projects/$projectId/merge_requests/$prNumber/pipelines"), headers: headers),
        httpGet(Uri.parse("https://$_domain/api/v4/projects/$projectId/merge_requests/$prNumber/award_emoji"), headers: headers),
      ]);

      final mrResp = results[0];
      final notesResp = results[1];
      final commitsResp = results[2];
      final changesResp = results[3];
      final pipelinesResp = results[4];
      final emojiResp = results[5];

      if (mrResp.statusCode != 200) return null;

      final mr = json.decode(utf8.decode(mrResp.bodyBytes));

      // Get viewer username
      final userResp = await httpGet(Uri.parse("https://$_domain/api/v4/user"), headers: headers);
      final viewerUsername = userResp.statusCode == 200 ? (json.decode(utf8.decode(userResp.bodyBytes))["username"] as String? ?? "") : "";

      // State
      final stateStr = mr["state"] ?? "";
      final prState = switch (stateStr) {
        "opened" => PrState.open,
        "merged" => PrState.merged,
        _ => PrState.closed,
      };

      // MR body reactions
      final List<IssueReaction> reactions = [];
      if (emojiResp.statusCode == 200) {
        final emojis = json.decode(utf8.decode(emojiResp.bodyBytes)) as List<dynamic>;
        final Map<String, (int, bool, int?)> counts = {};
        for (final emoji in emojis) {
          final name = gitlabReactionNamesReverse[emoji["name"] as String? ?? ""] ?? (emoji["name"] as String? ?? "");
          final isViewer = (emoji["user"]?["username"] as String? ?? "") == viewerUsername;
          final awardId = emoji["id"] as int?;
          final existing = counts[name];
          counts[name] = ((existing?.$1 ?? 0) + 1, (existing?.$2 ?? false) || isViewer, isViewer ? awardId : existing?.$3);
        }
        for (final e in counts.entries) {
          reactions.add(IssueReaction(content: e.key, count: e.value.$1, viewerHasReacted: e.value.$2, awardId: e.value.$3));
        }
      }

      // Commits
      final List<PrCommit> commits = [];
      if (commitsResp.statusCode == 200) {
        final commitList = json.decode(utf8.decode(commitsResp.bodyBytes)) as List<dynamic>;
        for (final c in commitList) {
          final sha = c["id"] as String? ?? "";
          commits.add(
            PrCommit(
              sha: sha,
              shortSha: c["short_id"] ?? sha.substring(0, sha.length.clamp(0, 7)),
              message: c["message"] ?? "",
              authorUsername: c["author_name"] ?? "",
              createdAt: DateTime.tryParse(c["created_at"] ?? "") ?? DateTime.now(),
            ),
          );
        }
      }

      // Notes (comments), selectively parsing system notes for cross-references and force pushes
      final List<IssueComment> commentList = [];
      final List<PrTimelineItem> systemTimelineItems = [];
      final crossRefPattern = RegExp(r'mentioned in (!|#)(\d+)');
      final forcePushPattern = RegExp(r'force[ -]?pushed');
      if (notesResp.statusCode == 200) {
        final notes = json.decode(utf8.decode(notesResp.bodyBytes)) as List<dynamic>;
        for (final note in notes) {
          if (note["system"] == true) {
            final body = note["body"] as String? ?? "";
            final noteCreatedAt = DateTime.tryParse(note["created_at"] ?? "") ?? DateTime.now();
            final noteAuthor = note["author"]?["username"] as String? ?? "";

            final crossRefMatch = crossRefPattern.firstMatch(body);
            if (crossRefMatch != null) {
              final isMr = crossRefMatch.group(1) == "!";
              final refNumber = int.tryParse(crossRefMatch.group(2) ?? "") ?? 0;
              final crossRef = PrCrossReference(
                sourceType: isMr ? "PullRequest" : "Issue",
                sourceNumber: refNumber,
                sourceTitle: "",
                isCrossRepository: false,
                actorUsername: noteAuthor,
                createdAt: noteCreatedAt,
              );
              systemTimelineItems.add(PrTimelineItem(type: PrTimelineItemType.crossReference, crossReference: crossRef, createdAt: noteCreatedAt));
              continue;
            }

            if (forcePushPattern.hasMatch(body)) {
              final shaPattern = RegExp(r'([0-9a-f]{7,40})');
              final shas = shaPattern.allMatches(body).map((m) => m.group(0)!).toList();
              final forcePush = PrForcePush(
                beforeSha: shas.length >= 1 ? shas[0].substring(0, shas[0].length.clamp(0, 7)) : "",
                afterSha: shas.length >= 2 ? shas[1].substring(0, shas[1].length.clamp(0, 7)) : "",
                actorUsername: noteAuthor,
                createdAt: noteCreatedAt,
              );
              systemTimelineItems.add(PrTimelineItem(type: PrTimelineItemType.forcePush, forcePush: forcePush, createdAt: noteCreatedAt));
              continue;
            }

            // Skip other system notes
            continue;
          }

          List<IssueReaction> noteReactions = [];
          try {
            final noteEmojiResp = await httpGet(
              Uri.parse("https://$_domain/api/v4/projects/$projectId/merge_requests/$prNumber/notes/${note["id"]}/award_emoji"),
              headers: headers,
            );
            if (noteEmojiResp.statusCode == 200) {
              final noteEmojis = json.decode(utf8.decode(noteEmojiResp.bodyBytes)) as List<dynamic>;
              final Map<String, (int, bool, int?)> noteCounts = {};
              for (final emoji in noteEmojis) {
                final name = gitlabReactionNamesReverse[emoji["name"] as String? ?? ""] ?? (emoji["name"] as String? ?? "");
                final isViewer = (emoji["user"]?["username"] as String? ?? "") == viewerUsername;
                final awardId = emoji["id"] as int?;
                final existing = noteCounts[name];
                noteCounts[name] = ((existing?.$1 ?? 0) + 1, (existing?.$2 ?? false) || isViewer, isViewer ? awardId : existing?.$3);
              }
              noteReactions = noteCounts.entries
                  .map((e) => IssueReaction(content: e.key, count: e.value.$1, viewerHasReacted: e.value.$2, awardId: e.value.$3))
                  .toList();
            }
          } catch (_) {}

          commentList.add(
            IssueComment(
              id: "${note["id"]}",
              authorUsername: note["author"]?["username"] ?? "",
              body: note["body"] ?? "",
              createdAt: DateTime.tryParse(note["created_at"] ?? "") ?? DateTime.now(),
              reactions: noteReactions,
            ),
          );
        }
      }

      // Interleave comments + commits + system timeline items into timeline
      final List<PrTimelineItem> timelineItems = [];
      for (final comment in commentList) {
        timelineItems.add(PrTimelineItem(type: PrTimelineItemType.comment, comment: comment, createdAt: comment.createdAt));
      }
      for (final commit in commits) {
        timelineItems.add(PrTimelineItem(type: PrTimelineItemType.commit, commit: commit, createdAt: commit.createdAt));
      }
      timelineItems.addAll(systemTimelineItems);
      timelineItems.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      // Pipelines → check runs
      final List<PrCheckRun> checkRuns = [];
      CheckStatus overallCheckStatus = CheckStatus.none;
      if (pipelinesResp.statusCode == 200) {
        final pipelines = json.decode(utf8.decode(pipelinesResp.bodyBytes)) as List<dynamic>;
        for (final p in pipelines) {
          final statusStr = p["status"] as String? ?? "";
          final CheckRunStatus status = switch (statusStr) {
            "success" || "failed" || "canceled" || "skipped" => CheckRunStatus.completed,
            "running" => CheckRunStatus.inProgress,
            _ => CheckRunStatus.queued,
          };
          final String? conclusion = switch (statusStr) {
            "success" => "success",
            "failed" => "failure",
            "canceled" => "cancelled",
            "skipped" => "skipped",
            _ => null,
          };
          checkRuns.add(
            PrCheckRun(
              name: "Pipeline #${p["iid"] ?? p["id"] ?? 0}",
              status: status,
              conclusion: conclusion,
              startedAt: DateTime.tryParse(p["created_at"] ?? ""),
              completedAt: DateTime.tryParse(p["updated_at"] ?? ""),
            ),
          );
        }
        if (pipelines.isNotEmpty) {
          final latest = pipelines.first["status"] as String? ?? "";
          overallCheckStatus = switch (latest) {
            "success" => CheckStatus.success,
            "failed" => CheckStatus.failure,
            "running" || "pending" || "created" => CheckStatus.pending,
            _ => CheckStatus.none,
          };
        }
      }

      // Changed files
      final List<PrChangedFile> changedFiles = [];
      int totalAdditions = 0;
      int totalDeletions = 0;
      if (changesResp.statusCode == 200) {
        final changesData = json.decode(utf8.decode(changesResp.bodyBytes));
        final changes = changesData["changes"] as List<dynamic>? ?? [];
        for (final f in changes) {
          final bool newFile = f["new_file"] == true;
          final bool deletedFile = f["deleted_file"] == true;
          final bool renamedFile = f["renamed_file"] == true;
          final status = deletedFile
              ? "removed"
              : newFile
              ? "added"
              : renamedFile
              ? "renamed"
              : "modified";

          // GitLab doesn't give per-file +/- counts in the changes API, so count diff lines
          final diff = f["diff"] as String? ?? "";
          int adds = 0, dels = 0;
          for (final line in diff.split('\n')) {
            if (line.startsWith('+') && !line.startsWith('+++')) adds++;
            if (line.startsWith('-') && !line.startsWith('---')) dels++;
          }
          totalAdditions += adds;
          totalDeletions += dels;

          changedFiles.add(
            PrChangedFile(
              filename: f["new_path"] ?? f["old_path"] ?? "",
              additions: adds,
              deletions: dels,
              status: status,
              patch: diff.isNotEmpty ? diff : null,
            ),
          );
        }
      }

      // Reviews — GitLab doesn't have formal PR reviews; skip
      final List<PrReview> reviews = [];

      return PrDetail(
        id: "${mr["iid"]}",
        title: mr["title"] ?? "",
        body: mr["description"] ?? "",
        authorUsername: mr["author"]?["username"] ?? "",
        baseBranch: mr["target_branch"] ?? "",
        headBranch: mr["source_branch"] ?? "",
        headRepoOwner: mr["author"]?["username"] ?? "",
        number: mr["iid"] ?? 0,
        additions: totalAdditions,
        deletions: totalDeletions,
        changedFileCount: changedFiles.length,
        state: prState,
        createdAt: DateTime.tryParse(mr["created_at"] ?? "") ?? DateTime.now(),
        labels: (mr["labels"] as List<dynamic>?)?.map((l) => IssueLabel(name: l.toString())).toList() ?? [],
        reactions: reactions,
        timelineItems: timelineItems,
        commits: commits,
        checkRuns: checkRuns,
        changedFiles: changedFiles,
        reviews: reviews,
        overallCheckStatus: overallCheckStatus,
        viewerPermission: ViewerPermission.write,
      );
    } catch (e, st) {
      Logger.logError(LogType.GetPrDetail, e, st);
      return null;
    }
  }

  @override
  Future<IssueComment?> addIssueComment(String accessToken, String owner, String repo, int issueNumber, String body) async {
    try {
      final projectId = "$owner%2F$repo";
      final response = await httpPost(
        Uri.parse("https://$_domain/api/v4/projects/$projectId/issues/$issueNumber/notes"),
        headers: {"Authorization": "Bearer $accessToken", "Content-Type": "application/json"},
        body: json.encode({"body": body}),
      );

      if (response.statusCode == 201) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return IssueComment(
          id: "${data["id"]}",
          authorUsername: data["author"]?["username"] ?? "",
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
      final projectId = "$owner%2F$repo";
      final response = await httpPut(
        Uri.parse("https://$_domain/api/v4/projects/$projectId/issues/$issueNumber"),
        headers: {"Authorization": "Bearer $accessToken", "Content-Type": "application/json"},
        body: json.encode({"state_event": close ? "close" : "reopen"}),
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
      final projectId = "$owner%2F$repo";
      final emojiName = gitlabReactionNames[reaction] ?? reaction;
      final String url;
      if (isComment) {
        url = "https://$_domain/api/v4/projects/$projectId/issues/$issueNumber/notes/$targetId/award_emoji";
      } else {
        url = "https://$_domain/api/v4/projects/$projectId/issues/$issueNumber/award_emoji";
      }

      final response = await httpPost(
        Uri.parse(url),
        headers: {"Authorization": "Bearer $accessToken", "Content-Type": "application/json"},
        body: json.encode({"name": emojiName}),
      );

      return response.statusCode == 201;
    } catch (e, st) {
      Logger.logError(LogType.AddReaction, e, st);
      return false;
    }
  }

  @override
  Future<bool> removeReaction(
    String accessToken,
    String owner,
    String repo,
    int issueNumber,
    String targetId,
    String reaction,
    bool isComment,
  ) async {
    try {
      final projectId = "$owner%2F$repo";
      final emojiName = gitlabReactionNames[reaction] ?? reaction;

      // First find the award emoji ID
      final String listUrl;
      if (isComment) {
        listUrl = "https://$_domain/api/v4/projects/$projectId/issues/$issueNumber/notes/$targetId/award_emoji";
      } else {
        listUrl = "https://$_domain/api/v4/projects/$projectId/issues/$issueNumber/award_emoji";
      }

      final listResp = await httpGet(Uri.parse(listUrl), headers: {"Authorization": "Bearer $accessToken"});
      if (listResp.statusCode != 200) return false;

      final userResp = await httpGet(Uri.parse("https://$_domain/api/v4/user"), headers: {"Authorization": "Bearer $accessToken"});
      final viewerUsername = userResp.statusCode == 200 ? (json.decode(utf8.decode(userResp.bodyBytes))["username"] as String? ?? "") : "";

      final emojis = json.decode(utf8.decode(listResp.bodyBytes)) as List<dynamic>;
      final match = emojis.firstWhere((e) => e["name"] == emojiName && (e["user"]?["username"] ?? "") == viewerUsername, orElse: () => null);
      if (match == null) return false;

      final awardId = match["id"];
      final String deleteUrl;
      if (isComment) {
        deleteUrl = "https://$_domain/api/v4/projects/$projectId/issues/$issueNumber/notes/$targetId/award_emoji/$awardId";
      } else {
        deleteUrl = "https://$_domain/api/v4/projects/$projectId/issues/$issueNumber/award_emoji/$awardId";
      }

      final deleteResp = await httpDelete(Uri.parse(deleteUrl), headers: {"Authorization": "Bearer $accessToken"});
      return deleteResp.statusCode == 204;
    } catch (e, st) {
      Logger.logError(LogType.RemoveReaction, e, st);
      return false;
    }
  }

  @override
  Future<CreateIssueResult?> createIssue(
    String accessToken,
    String owner,
    String repo,
    String title,
    String body, {
    List<String>? labels,
    List<String>? assignees,
  }) async {
    try {
      final projectId = "$owner%2F$repo";
      final payload = <String, dynamic>{"title": title, "description": body};
      if (labels != null && labels.isNotEmpty) payload["labels"] = labels.join(",");

      final response = await httpPost(
        Uri.parse("https://$_domain/api/v4/projects/$projectId/issues"),
        headers: {"Authorization": "Bearer $accessToken", "Content-Type": "application/json"},
        body: json.encode(payload),
      );

      if (response.statusCode == 201) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return CreateIssueResult(number: data["iid"] as int, htmlUrl: data["web_url"]?.toString());
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
      final projectId = "$owner%2F$repo";
      final payload = <String, dynamic>{};
      if (title != null) payload["title"] = title;
      if (body != null) payload["description"] = body;

      final response = await httpPut(
        Uri.parse("https://$_domain/api/v4/projects/$projectId/issues/$issueNumber"),
        headers: {"Authorization": "Bearer $accessToken", "Content-Type": "application/json"},
        body: json.encode(payload),
      );

      return response.statusCode == 200;
    } catch (e, st) {
      Logger.logError(LogType.UpdateIssue, e, st);
      return false;
    }
  }

  @override
  Future<CreateIssueResult?> createPullRequest(
    String accessToken,
    String owner,
    String repo,
    String title,
    String body,
    String head,
    String base,
  ) async {
    try {
      final projectId = "$owner%2F$repo";
      final response = await httpPost(
        Uri.parse("https://$_domain/api/v4/projects/$projectId/merge_requests"),
        headers: {"Authorization": "Bearer $accessToken", "Content-Type": "application/json"},
        body: json.encode({"title": title, "description": body, "source_branch": head, "target_branch": base}),
      );

      if (response.statusCode == 201) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return CreateIssueResult(number: data["iid"] as int, htmlUrl: data["web_url"]?.toString());
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
      final projectId = "$owner%2F$repo";
      final results = await Future.wait([
        httpGet(
          Uri.parse("https://$_domain/api/v4/projects/$projectId/repository/branches?per_page=100"),
          headers: {"Authorization": "Bearer $accessToken"},
        ),
        httpGet(Uri.parse("https://$_domain/api/v4/projects/$projectId"), headers: {"Authorization": "Bearer $accessToken"}),
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
