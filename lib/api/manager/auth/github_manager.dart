import 'dart:convert';
import 'package:GitSync/api/helper.dart';
import 'package:GitSync/api/logger.dart';
import 'package:GitSync/constant/strings.dart';
import 'package:GitSync/constant/reactions.dart';
import 'package:GitSync/type/action_run.dart';
import 'package:GitSync/type/issue.dart';
import 'package:GitSync/type/issue_detail.dart';
import 'package:GitSync/type/pr_detail.dart';
import 'package:GitSync/type/pull_request.dart';
import 'package:GitSync/type/release.dart';
import 'package:GitSync/type/tag.dart';

import '../../manager/auth/git_provider_manager.dart';
import '../../../constant/secrets.dart';
import 'package:oauth2_client/github_oauth2_client.dart';
import 'package:oauth2_client/oauth2_client.dart';

class GithubManager extends GitProviderManager {
  static const String _domain = "github.com";

  GithubManager();

  bool get oAuthSupport => true;

  get clientId => gitHubClientId;
  get clientSecret => gitHubClientSecret;
  get scopes => ["user", "user:email", "repo", "workflow", "read:org"];

  bool get supportsTokenRefresh => false;

  OAuth2Client get oauthClient => GitHubOAuth2Client(redirectUri: 'gitsync://auth', customUriScheme: 'gitsync');

  @override
  Future<(String, String)?> getUsernameAndEmail(String accessToken) async {
    final response = await httpGet(
      Uri.parse("https://api.$_domain/user"),
      headers: {"Accept": "application/json", "Authorization": "token $accessToken"},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(utf8.decode(response.bodyBytes));
      String? email = jsonData["email"];
      if (email == null) {
        final emailResp = await httpGet(
          Uri.parse("https://api.$_domain/user/emails"),
          headers: {"Accept": "application/json", "Authorization": "token $accessToken"},
        );
        if (emailResp.statusCode == 200) {
          final emails = (json.decode(utf8.decode(emailResp.bodyBytes)) as List);
          final primaryOrFirst = emails.firstWhere(
            (e) => e["visibility"] != "private" && e["primary"] == true,
            orElse: () => emails.firstWhere(
              (e) => e["visibility"] != "private",
              orElse: () => emails.firstWhere((e) => e["primary"] == true, orElse: () => emails[0]),
            ),
          );
          email = primaryOrFirst?["email"];
        }
      }

      return ((jsonData["login"] as String?) ?? "", email ?? "");
    }

    return null;
  }

  @override
  Future<String?> getToken(String token, Future<void> Function(String p1, DateTime? p2, String p3) setAccessRefreshToken) async {
    if (supportsTokenRefresh) return super.getToken(token, setAccessRefreshToken);
    return token.split(conflictSeparator).first;
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

  static const String _issuesQuery = """
query(\$owner: String!, \$repo: String!, \$states: [IssueState!], \$after: String, \$labels: [String!], \$filterBy: IssueFilters) {
  repository(owner: \$owner, name: \$repo) {
    issues(first: 30, states: \$states, after: \$after, labels: \$labels, filterBy: \$filterBy, orderBy: {field: CREATED_AT, direction: DESC}) {
      nodes {
        title
        number
        state
        author { login }
        createdAt
        comments { totalCount }
        labels(first: 10) {
          nodes { name color }
        }
        timelineItems(itemTypes: [CROSS_REFERENCED_EVENT], first: 50) {
          nodes {
            ... on CrossReferencedEvent {
              source {
                ... on PullRequest { number }
              }
            }
          }
        }
      }
      pageInfo { hasNextPage endCursor }
    }
  }
}
""";

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
    final Map<String, dynamic> filterBy = {};
    if (authorFilter != null && authorFilter.isNotEmpty) filterBy["createdBy"] = authorFilter;
    if (assigneeFilter != null && assigneeFilter.isNotEmpty) filterBy["assignee"] = assigneeFilter;

    final Map<String, dynamic> variables = {
      "owner": owner,
      "repo": repo,
      if (state != "all") "states": [state == "open" ? "OPEN" : "CLOSED"],
      if (labelFilter != null && labelFilter.isNotEmpty) "labels": labelFilter.split(",").map((l) => l.trim()).toList(),
      if (filterBy.isNotEmpty) "filterBy": filterBy,
    };

    await _getIssuesGraphQL(accessToken, variables, updateCallback, nextPageCallback);
  }

  Future<void> _getIssuesGraphQL(
    String accessToken,
    Map<String, dynamic> variables,
    Function(List<Issue>) updateCallback,
    Function(Function()?) nextPageCallback,
  ) async {
    try {
      final response = await httpPost(
        Uri.parse("https://api.$_domain/graphql"),
        headers: {"Authorization": "bearer $accessToken", "Content-Type": "application/json"},
        body: json.encode({"query": _issuesQuery, "variables": variables}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(utf8.decode(response.bodyBytes));
        final issuesData = jsonData["data"]?["repository"]?["issues"];
        if (issuesData == null) {
          updateCallback([]);
          nextPageCallback(null);
          return;
        }

        final nodes = issuesData["nodes"] as List<dynamic>? ?? [];
        final List<Issue> issues = nodes.map((item) {
          final timelineNodes = item["timelineItems"]?["nodes"] as List<dynamic>? ?? [];
          final linkedPrCount = timelineNodes.where((node) {
            final source = node["source"];
            return source is Map && source.containsKey("number");
          }).length;

          return Issue(
            title: item["title"] ?? "",
            number: item["number"] ?? 0,
            isOpen: item["state"] == "OPEN",
            authorUsername: item["author"]?["login"] ?? "",
            createdAt: DateTime.tryParse(item["createdAt"] ?? "") ?? DateTime.now(),
            commentCount: item["comments"]?["totalCount"] ?? 0,
            linkedPrCount: linkedPrCount,
            labels: (item["labels"]?["nodes"] as List<dynamic>?)
                    ?.map((l) => IssueLabel(name: l["name"] ?? "", color: l["color"]))
                    .toList() ??
                [],
          );
        }).toList();

        updateCallback(issues);

        final pageInfo = issuesData["pageInfo"];
        if (pageInfo?["hasNextPage"] == true) {
          final nextVars = Map<String, dynamic>.from(variables);
          nextVars["after"] = pageInfo["endCursor"];
          nextPageCallback(() => _getIssuesGraphQL(accessToken, nextVars, updateCallback, nextPageCallback));
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

  static const String _pullRequestsQuery = """
query(\$owner: String!, \$repo: String!, \$states: [PullRequestState!], \$after: String, \$labels: [String!]) {
  repository(owner: \$owner, name: \$repo) {
    pullRequests(first: 30, states: \$states, after: \$after, labels: \$labels, orderBy: {field: UPDATED_AT, direction: DESC}) {
      nodes {
        title
        number
        state
        author { login }
        createdAt
        comments { totalCount }
        labels(first: 10) {
          nodes { name color }
        }
        closingIssuesReferences { totalCount }
        commits(last: 1) {
          nodes {
            commit {
              statusCheckRollup { state }
            }
          }
        }
      }
      pageInfo { hasNextPage endCursor }
    }
  }
}
""";

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
    final Map<String, dynamic> variables = {
      "owner": owner,
      "repo": repo,
      if (state == "open") "states": ["OPEN"],
      if (state == "closed") "states": ["CLOSED", "MERGED"],
      if (labelFilter != null && labelFilter.isNotEmpty) "labels": labelFilter.split(",").map((l) => l.trim()).toList(),
    };

    await _getPullRequestsGraphQL(accessToken, variables, updateCallback, nextPageCallback);
  }

  Future<void> _getPullRequestsGraphQL(
    String accessToken,
    Map<String, dynamic> variables,
    Function(List<PullRequest>) updateCallback,
    Function(Function()?) nextPageCallback,
  ) async {
    try {
      final response = await httpPost(
        Uri.parse("https://api.$_domain/graphql"),
        headers: {"Authorization": "bearer $accessToken", "Content-Type": "application/json"},
        body: json.encode({"query": _pullRequestsQuery, "variables": variables}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(utf8.decode(response.bodyBytes));
        final prsData = jsonData["data"]?["repository"]?["pullRequests"];
        if (prsData == null) {
          updateCallback([]);
          nextPageCallback(null);
          return;
        }

        final nodes = prsData["nodes"] as List<dynamic>? ?? [];
        final List<PullRequest> prs = nodes.map((item) {
          final stateStr = item["state"] ?? "";
          final PrState prState = switch (stateStr) {
            "OPEN" => PrState.open,
            "MERGED" => PrState.merged,
            _ => PrState.closed,
          };

          final rollupState = (item["commits"]?["nodes"] as List<dynamic>?)
              ?.firstOrNull?["commit"]?["statusCheckRollup"]?["state"] as String?;
          final CheckStatus checkStatus = switch (rollupState) {
            "SUCCESS" => CheckStatus.success,
            "FAILURE" || "ERROR" => CheckStatus.failure,
            "PENDING" || "EXPECTED" => CheckStatus.pending,
            _ => CheckStatus.none,
          };

          return PullRequest(
            title: item["title"] ?? "",
            number: item["number"] ?? 0,
            state: prState,
            authorUsername: item["author"]?["login"] ?? "",
            createdAt: DateTime.tryParse(item["createdAt"] ?? "") ?? DateTime.now(),
            commentCount: item["comments"]?["totalCount"] ?? 0,
            linkedIssueCount: item["closingIssuesReferences"]?["totalCount"] ?? 0,
            checkStatus: checkStatus,
            labels: (item["labels"]?["nodes"] as List<dynamic>?)
                    ?.map((l) => IssueLabel(name: l["name"] ?? "", color: l["color"]))
                    .toList() ??
                [],
          );
        }).toList();

        updateCallback(prs);

        final pageInfo = prsData["pageInfo"];
        if (pageInfo?["hasNextPage"] == true) {
          final nextVars = Map<String, dynamic>.from(variables);
          nextVars["after"] = pageInfo["endCursor"];
          nextPageCallback(() => _getPullRequestsGraphQL(accessToken, nextVars, updateCallback, nextPageCallback));
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

  static const String _tagsQuery = """
query(\$owner: String!, \$repo: String!, \$after: String) {
  repository(owner: \$owner, name: \$repo) {
    refs(refPrefix: "refs/tags/", first: 30, after: \$after, orderBy: {field: TAG_COMMIT_DATE, direction: DESC}) {
      nodes {
        name
        target {
          ... on Tag {
            message
            tagger { date }
            target {
              ... on Commit { oid committedDate }
              ... on Tag { target { ... on Commit { oid committedDate } } }
            }
          }
          ... on Commit { oid committedDate }
        }
      }
      pageInfo { hasNextPage endCursor }
    }
  }
}
""";

  @override
  Future<void> getTags(
    String accessToken,
    String owner,
    String repo,
    Function(List<Tag>) updateCallback,
    Function(Function()?) nextPageCallback,
  ) async {
    final Map<String, dynamic> variables = {"owner": owner, "repo": repo};
    await _getTagsGraphQL(accessToken, variables, updateCallback, nextPageCallback);
  }

  Future<void> _getTagsGraphQL(
    String accessToken,
    Map<String, dynamic> variables,
    Function(List<Tag>) updateCallback,
    Function(Function()?) nextPageCallback,
  ) async {
    try {
      final response = await httpPost(
        Uri.parse("https://api.$_domain/graphql"),
        headers: {"Authorization": "bearer $accessToken", "Content-Type": "application/json"},
        body: json.encode({"query": _tagsQuery, "variables": variables}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(utf8.decode(response.bodyBytes));
        final refsData = jsonData["data"]?["repository"]?["refs"];
        if (refsData == null) {
          updateCallback([]);
          nextPageCallback(null);
          return;
        }

        final nodes = refsData["nodes"] as List<dynamic>? ?? [];
        final List<Tag> tags = nodes.map((item) {
          final target = item["target"] as Map<String, dynamic>? ?? {};
          final bool isAnnotated = target.containsKey("tagger");

          if (isAnnotated) {
            final innerTarget = target["target"] as Map<String, dynamic>? ?? {};
            final String sha = innerTarget["oid"] as String? ?? innerTarget["target"]?["oid"] as String? ?? "";
            final String dateStr = target["tagger"]?["date"] as String? ?? "";
            final String? message = (target["message"] as String?)?.isNotEmpty == true ? target["message"] as String : null;
            return Tag(
              name: item["name"] ?? "",
              sha: sha,
              createdAt: DateTime.tryParse(dateStr) ?? DateTime.now(),
              message: message,
            );
          } else {
            return Tag(
              name: item["name"] ?? "",
              sha: target["oid"] as String? ?? "",
              createdAt: DateTime.tryParse(target["committedDate"] as String? ?? "") ?? DateTime.now(),
            );
          }
        }).toList();

        updateCallback(tags);

        final pageInfo = refsData["pageInfo"];
        if (pageInfo?["hasNextPage"] == true) {
          final nextVars = Map<String, dynamic>.from(variables);
          nextVars["after"] = pageInfo["endCursor"];
          nextPageCallback(() => _getTagsGraphQL(accessToken, nextVars, updateCallback, nextPageCallback));
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

  static const String _releasesQuery = """
query(\$owner: String!, \$repo: String!, \$after: String) {
  repository(owner: \$owner, name: \$repo) {
    releases(first: 20, after: \$after, orderBy: {field: CREATED_AT, direction: DESC}) {
      nodes {
        name tagName description isPrerelease isDraft createdAt
        author { login }
        releaseAssets(first: 20) {
          nodes { name downloadUrl size downloadCount }
        }
      }
      pageInfo { hasNextPage endCursor }
    }
  }
}
""";

  @override
  Future<void> getReleases(
    String accessToken,
    String owner,
    String repo,
    Function(List<Release>) updateCallback,
    Function(Function()?) nextPageCallback,
  ) async {
    final Map<String, dynamic> variables = {"owner": owner, "repo": repo};
    await _getReleasesGraphQL(accessToken, variables, updateCallback, nextPageCallback);
  }

  Future<void> _getReleasesGraphQL(
    String accessToken,
    Map<String, dynamic> variables,
    Function(List<Release>) updateCallback,
    Function(Function()?) nextPageCallback,
  ) async {
    try {
      final response = await httpPost(
        Uri.parse("https://api.$_domain/graphql"),
        headers: {"Authorization": "bearer $accessToken", "Content-Type": "application/json"},
        body: json.encode({"query": _releasesQuery, "variables": variables}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(utf8.decode(response.bodyBytes));
        final releasesData = jsonData["data"]?["repository"]?["releases"];
        if (releasesData == null) {
          updateCallback([]);
          nextPageCallback(null);
          return;
        }

        final nodes = releasesData["nodes"] as List<dynamic>? ?? [];
        final List<Release> releases = nodes.map((item) {
          final assetNodes = item["releaseAssets"]?["nodes"] as List<dynamic>? ?? [];
          final assets = assetNodes
              .map((a) => ReleaseAsset(
                    name: a["name"] ?? "",
                    downloadUrl: a["downloadUrl"] ?? "",
                    size: a["size"] as int?,
                    downloadCount: a["downloadCount"] as int?,
                  ))
              .toList();

          return Release(
            name: item["name"] ?? "",
            tagName: item["tagName"] ?? "",
            description: item["description"] ?? "",
            authorUsername: item["author"]?["login"] ?? "",
            createdAt: DateTime.tryParse(item["createdAt"] ?? "") ?? DateTime.now(),
            commitSha: null,
            isPrerelease: item["isPrerelease"] == true,
            isDraft: item["isDraft"] == true,
            assets: assets,
          );
        }).toList();

        updateCallback(releases);

        final pageInfo = releasesData["pageInfo"];
        if (pageInfo?["hasNextPage"] == true) {
          final nextVars = Map<String, dynamic>.from(variables);
          nextVars["after"] = pageInfo["endCursor"];
          nextPageCallback(() => _getReleasesGraphQL(accessToken, nextVars, updateCallback, nextPageCallback));
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
    var url = "https://api.$_domain/repos/$owner/$repo/actions/runs?per_page=30";
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
        updateCallback([]);
        nextPageCallback(null);
      }
    } catch (e, st) {
      Logger.logError(LogType.GetActionRuns, e, st);
      updateCallback([]);
      nextPageCallback(null);
    }
  }

  static const String _issueDetailQuery = """
query(\$owner: String!, \$repo: String!, \$number: Int!) {
  repository(owner: \$owner, name: \$repo) {
    viewerPermission
    issue(number: \$number) {
      id
      title
      number
      state
      body
      createdAt
      author { login }
      labels(first: 20) {
        nodes { name color }
      }
      reactions(first: 100) {
        nodes {
          content
          user { login }
        }
      }
      comments(first: 100) {
        nodes {
          id
          databaseId
          body
          createdAt
          author { login }
          reactions(first: 50) {
            nodes {
              content
              user { login }
            }
          }
        }
      }
    }
  }
}
""";

  List<IssueReaction> _aggregateReactions(List<dynamic> nodes, String viewerLogin) {
    final Map<String, (int, bool)> counts = {};
    for (final node in nodes) {
      final content = githubReactionNamesReverse[node["content"] as String? ?? ""] ?? (node["content"] as String? ?? "").toLowerCase();
      final isViewer = (node["user"]?["login"] as String? ?? "") == viewerLogin;
      final existing = counts[content];
      counts[content] = (
        (existing?.$1 ?? 0) + 1,
        (existing?.$2 ?? false) || isViewer,
      );
    }
    return counts.entries.map((e) => IssueReaction(content: e.key, count: e.value.$1, viewerHasReacted: e.value.$2)).toList();
  }

  @override
  Future<IssueDetail?> getIssueDetail(String accessToken, String owner, String repo, int issueNumber) async {
    try {
      // Get viewer login for reaction matching
      final userResp = await httpGet(
        Uri.parse("https://api.$_domain/user"),
        headers: {"Authorization": "token $accessToken"},
      );
      final viewerLogin = userResp.statusCode == 200 ? (json.decode(utf8.decode(userResp.bodyBytes))["login"] as String? ?? "") : "";

      final response = await httpPost(
        Uri.parse("https://api.$_domain/graphql"),
        headers: {"Authorization": "bearer $accessToken", "Content-Type": "application/json"},
        body: json.encode({"query": _issueDetailQuery, "variables": {"owner": owner, "repo": repo, "number": issueNumber}}),
      );

      if (response.statusCode != 200) return null;

      final jsonData = json.decode(utf8.decode(response.bodyBytes));
      final repoData = jsonData["data"]?["repository"];
      final issue = repoData?["issue"];
      if (issue == null) return null;

      final permStr = repoData?["viewerPermission"] as String? ?? "READ";
      final permission = switch (permStr) {
        "ADMIN" => ViewerPermission.admin,
        "MAINTAIN" => ViewerPermission.maintain,
        "WRITE" => ViewerPermission.write,
        "TRIAGE" => ViewerPermission.triage,
        _ => ViewerPermission.read,
      };

      final reactionNodes = issue["reactions"]?["nodes"] as List<dynamic>? ?? [];
      final commentNodes = issue["comments"]?["nodes"] as List<dynamic>? ?? [];

      final comments = commentNodes.map((c) {
        final commentReactionNodes = c["reactions"]?["nodes"] as List<dynamic>? ?? [];
        return IssueComment(
          id: "${c["databaseId"] ?? c["id"] ?? ""}",
          authorUsername: c["author"]?["login"] ?? "",
          body: c["body"] ?? "",
          createdAt: DateTime.tryParse(c["createdAt"] ?? "") ?? DateTime.now(),
          reactions: _aggregateReactions(commentReactionNodes, viewerLogin),
        );
      }).toList();

      return IssueDetail(
        id: issue["id"] ?? "",
        title: issue["title"] ?? "",
        number: issue["number"] ?? 0,
        isOpen: issue["state"] == "OPEN",
        authorUsername: issue["author"]?["login"] ?? "",
        createdAt: DateTime.tryParse(issue["createdAt"] ?? "") ?? DateTime.now(),
        body: issue["body"] ?? "",
        labels: (issue["labels"]?["nodes"] as List<dynamic>?)
                ?.map((l) => IssueLabel(name: l["name"] ?? "", color: l["color"]))
                .toList() ??
            [],
        reactions: _aggregateReactions(reactionNodes, viewerLogin),
        comments: comments,
        viewerPermission: permission,
      );
    } catch (e, st) {
      Logger.logError(LogType.GetIssueDetail, e, st);
      return null;
    }
  }

  static const String _prDetailQuery = """
query(\$owner: String!, \$repo: String!, \$number: Int!) {
  repository(owner: \$owner, name: \$repo) {
    viewerPermission
    pullRequest(number: \$number) {
      id
      title
      number
      state
      body
      createdAt
      additions
      deletions
      changedFiles
      baseRefName
      headRefName
      headRepositoryOwner { login }
      author { login }
      labels(first: 20) {
        nodes { name color }
      }
      reactions(first: 100) {
        nodes {
          content
          user { login }
        }
      }
      timelineItems(first: 100, itemTypes: [ISSUE_COMMENT, PULL_REQUEST_COMMIT, CROSS_REFERENCED_EVENT, HEAD_REF_FORCE_PUSHED_EVENT]) {
        nodes {
          __typename
          ... on IssueComment {
            id
            databaseId
            body
            createdAt
            author { login }
            reactions(first: 50) {
              nodes {
                content
                user { login }
              }
            }
          }
          ... on PullRequestCommit {
            commit {
              oid
              abbreviatedOid
              message
              author { name user { login } }
              committedDate
            }
          }
          ... on CrossReferencedEvent {
            actor { login }
            createdAt
            isCrossRepository
            source {
              __typename
              ... on PullRequest { number title repository { nameWithOwner } }
              ... on Issue { number title repository { nameWithOwner } }
            }
          }
          ... on HeadRefForcePushedEvent {
            actor { login }
            createdAt
            beforeCommit { abbreviatedOid }
            afterCommit { abbreviatedOid }
          }
        }
      }
      commits(last: 1) {
        nodes {
          commit {
            statusCheckRollup {
              state
              contexts(first: 100) {
                nodes {
                  __typename
                  ... on CheckRun {
                    name
                    status
                    conclusion
                    startedAt
                    completedAt
                  }
                  ... on StatusContext {
                    context
                    state
                    createdAt
                  }
                }
              }
            }
          }
        }
      }
      reviews(first: 50) {
        nodes {
          author { login }
          state
          createdAt
        }
      }
    }
  }
}
""";

  @override
  Future<PrDetail?> getPrDetail(String accessToken, String owner, String repo, int prNumber) async {
    try {
      // Get viewer login for reaction matching
      final userResp = await httpGet(
        Uri.parse("https://api.$_domain/user"),
        headers: {"Authorization": "token $accessToken"},
      );
      final viewerLogin = userResp.statusCode == 200 ? (json.decode(utf8.decode(userResp.bodyBytes))["login"] as String? ?? "") : "";

      final response = await httpPost(
        Uri.parse("https://api.$_domain/graphql"),
        headers: {"Authorization": "bearer $accessToken", "Content-Type": "application/json"},
        body: json.encode({"query": _prDetailQuery, "variables": {"owner": owner, "repo": repo, "number": prNumber}}),
      );

      if (response.statusCode != 200) return null;

      final jsonData = json.decode(utf8.decode(response.bodyBytes));
      final repoData = jsonData["data"]?["repository"];
      final pr = repoData?["pullRequest"];
      if (pr == null) return null;

      final permStr = repoData?["viewerPermission"] as String? ?? "READ";
      final permission = switch (permStr) {
        "ADMIN" => ViewerPermission.admin,
        "MAINTAIN" => ViewerPermission.maintain,
        "WRITE" => ViewerPermission.write,
        "TRIAGE" => ViewerPermission.triage,
        _ => ViewerPermission.read,
      };

      final prStateStr = pr["state"] ?? "";
      final prState = switch (prStateStr) {
        "OPEN" => PrState.open,
        "MERGED" => PrState.merged,
        _ => PrState.closed,
      };

      // Reactions
      final reactionNodes = pr["reactions"]?["nodes"] as List<dynamic>? ?? [];

      // Timeline items
      final timelineNodes = pr["timelineItems"]?["nodes"] as List<dynamic>? ?? [];
      final List<PrTimelineItem> timelineItems = [];
      final List<PrCommit> allCommits = [];

      for (final node in timelineNodes) {
        final typeName = node["__typename"] as String? ?? "";
        if (typeName == "IssueComment") {
          final commentReactionNodes = node["reactions"]?["nodes"] as List<dynamic>? ?? [];
          final comment = IssueComment(
            id: "${node["databaseId"] ?? node["id"] ?? ""}",
            authorUsername: node["author"]?["login"] ?? "",
            body: node["body"] ?? "",
            createdAt: DateTime.tryParse(node["createdAt"] ?? "") ?? DateTime.now(),
            reactions: _aggregateReactions(commentReactionNodes, viewerLogin),
          );
          timelineItems.add(PrTimelineItem(type: PrTimelineItemType.comment, comment: comment, createdAt: comment.createdAt));
        } else if (typeName == "PullRequestCommit") {
          final c = node["commit"];
          if (c == null) continue;
          final commit = PrCommit(
            sha: c["oid"] ?? "",
            shortSha: c["abbreviatedOid"] ?? (c["oid"] as String? ?? "").substring(0, (c["oid"] as String? ?? "").length.clamp(0, 7)),
            message: c["message"] ?? "",
            authorUsername: c["author"]?["user"]?["login"] ?? c["author"]?["name"] ?? "",
            createdAt: DateTime.tryParse(c["committedDate"] ?? "") ?? DateTime.now(),
          );
          allCommits.add(commit);
          timelineItems.add(PrTimelineItem(type: PrTimelineItemType.commit, commit: commit, createdAt: commit.createdAt));
        } else if (typeName == "CrossReferencedEvent") {
          final source = node["source"] as Map<String, dynamic>?;
          if (source == null) continue;
          final sourceType = source["__typename"] as String? ?? "";
          final createdAt = DateTime.tryParse(node["createdAt"] ?? "") ?? DateTime.now();
          final crossRef = PrCrossReference(
            sourceType: sourceType,
            sourceNumber: source["number"] as int? ?? 0,
            sourceTitle: source["title"] as String? ?? "",
            isCrossRepository: node["isCrossRepository"] == true,
            sourceRepoName: node["isCrossRepository"] == true ? (source["repository"]?["nameWithOwner"] as String?) : null,
            actorUsername: node["actor"]?["login"] ?? "",
            createdAt: createdAt,
          );
          timelineItems.add(PrTimelineItem(type: PrTimelineItemType.crossReference, crossReference: crossRef, createdAt: createdAt));
        } else if (typeName == "HeadRefForcePushedEvent") {
          final createdAt = DateTime.tryParse(node["createdAt"] ?? "") ?? DateTime.now();
          final forcePush = PrForcePush(
            beforeSha: node["beforeCommit"]?["abbreviatedOid"] ?? "",
            afterSha: node["afterCommit"]?["abbreviatedOid"] ?? "",
            actorUsername: node["actor"]?["login"] ?? "",
            createdAt: createdAt,
          );
          timelineItems.add(PrTimelineItem(type: PrTimelineItemType.forcePush, forcePush: forcePush, createdAt: createdAt));
        }
      }

      // Check runs
      final List<PrCheckRun> checkRuns = [];
      final rollupNode = (pr["commits"]?["nodes"] as List<dynamic>?)?.firstOrNull;
      final rollup = rollupNode?["commit"]?["statusCheckRollup"];
      final rollupState = rollup?["state"] as String?;
      final CheckStatus overallCheckStatus = switch (rollupState) {
        "SUCCESS" => CheckStatus.success,
        "FAILURE" || "ERROR" => CheckStatus.failure,
        "PENDING" || "EXPECTED" => CheckStatus.pending,
        _ => CheckStatus.none,
      };

      final contextNodes = rollup?["contexts"]?["nodes"] as List<dynamic>? ?? [];
      for (final ctx in contextNodes) {
        final ctxType = ctx["__typename"] as String? ?? "";
        if (ctxType == "CheckRun") {
          final statusStr = ctx["status"] as String? ?? "";
          final CheckRunStatus status = switch (statusStr) {
            "COMPLETED" => CheckRunStatus.completed,
            "IN_PROGRESS" => CheckRunStatus.inProgress,
            _ => CheckRunStatus.queued,
          };
          checkRuns.add(PrCheckRun(
            name: ctx["name"] ?? "",
            status: status,
            conclusion: (ctx["conclusion"] as String?)?.toLowerCase(),
            startedAt: DateTime.tryParse(ctx["startedAt"] ?? ""),
            completedAt: DateTime.tryParse(ctx["completedAt"] ?? ""),
          ));
        } else if (ctxType == "StatusContext") {
          final stateStr = ctx["state"] as String? ?? "";
          final CheckRunStatus status = switch (stateStr) {
            "SUCCESS" || "FAILURE" || "ERROR" => CheckRunStatus.completed,
            "PENDING" || "EXPECTED" => CheckRunStatus.queued,
            _ => CheckRunStatus.queued,
          };
          final String? conclusion = switch (stateStr) {
            "SUCCESS" => "success",
            "FAILURE" => "failure",
            "ERROR" => "failure",
            _ => null,
          };
          checkRuns.add(PrCheckRun(
            name: ctx["context"] ?? "",
            status: status,
            conclusion: conclusion,
            startedAt: DateTime.tryParse(ctx["createdAt"] ?? ""),
          ));
        }
      }

      // Changed files (REST API to get patch content)
      final List<PrChangedFile> changedFiles = [];
      try {
        final filesResp = await httpGet(
          Uri.parse("https://api.$_domain/repos/$owner/$repo/pulls/$prNumber/files?per_page=100"),
          headers: {"Authorization": "token $accessToken", "Accept": "application/json"},
        );
        if (filesResp.statusCode == 200) {
          final files = json.decode(utf8.decode(filesResp.bodyBytes)) as List<dynamic>;
          for (final f in files) {
            changedFiles.add(PrChangedFile(
              filename: f["filename"] ?? "",
              additions: f["additions"] as int? ?? 0,
              deletions: f["deletions"] as int? ?? 0,
              status: f["status"] ?? "modified",
              patch: f["patch"] as String?,
            ));
          }
        }
      } catch (_) {}

      // Reviews
      final reviewNodes = pr["reviews"]?["nodes"] as List<dynamic>? ?? [];
      final reviews = reviewNodes.map((r) {
        final stateStr = r["state"] as String? ?? "";
        final state = switch (stateStr) {
          "APPROVED" => PrReviewState.approved,
          "CHANGES_REQUESTED" => PrReviewState.changesRequested,
          "COMMENTED" => PrReviewState.commented,
          "DISMISSED" => PrReviewState.dismissed,
          _ => PrReviewState.pending,
        };
        return PrReview(
          authorUsername: r["author"]?["login"] ?? "",
          state: state,
          createdAt: DateTime.tryParse(r["createdAt"] ?? "") ?? DateTime.now(),
        );
      }).toList();

      return PrDetail(
        id: pr["id"] ?? "",
        title: pr["title"] ?? "",
        body: pr["body"] ?? "",
        authorUsername: pr["author"]?["login"] ?? "",
        baseBranch: pr["baseRefName"] ?? "",
        headBranch: pr["headRefName"] ?? "",
        headRepoOwner: pr["headRepositoryOwner"]?["login"] ?? pr["author"]?["login"] ?? "",
        number: pr["number"] ?? 0,
        additions: pr["additions"] as int? ?? 0,
        deletions: pr["deletions"] as int? ?? 0,
        changedFileCount: pr["changedFiles"] as int? ?? 0,
        state: prState,
        createdAt: DateTime.tryParse(pr["createdAt"] ?? "") ?? DateTime.now(),
        labels: (pr["labels"]?["nodes"] as List<dynamic>?)
                ?.map((l) => IssueLabel(name: l["name"] ?? "", color: l["color"]))
                .toList() ??
            [],
        reactions: _aggregateReactions(reactionNodes, viewerLogin),
        timelineItems: timelineItems,
        commits: allCommits,
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
        Uri.parse("https://api.$_domain/repos/$owner/$repo/issues/$issueNumber/comments"),
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
      final mutation = close
          ? 'mutation { closeIssue(input: {issueId: "$issueId"}) { issue { state } } }'
          : 'mutation { reopenIssue(input: {issueId: "$issueId"}) { issue { state } } }';

      final response = await httpPost(
        Uri.parse("https://api.$_domain/graphql"),
        headers: {"Authorization": "bearer $accessToken", "Content-Type": "application/json"},
        body: json.encode({"query": mutation}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data["errors"] == null;
      }
      return false;
    } catch (e, st) {
      Logger.logError(LogType.UpdateIssueState, e, st);
      return false;
    }
  }

  @override
  Future<bool> addReaction(String accessToken, String owner, String repo, int issueNumber, String targetId, String reaction, bool isComment) async {
    try {
      final url = isComment
          ? "https://api.$_domain/repos/$owner/$repo/issues/comments/$targetId/reactions"
          : "https://api.$_domain/repos/$owner/$repo/issues/$issueNumber/reactions";

      final response = await httpPost(
        Uri.parse(url),
        headers: {"Authorization": "token $accessToken", "Content-Type": "application/json", "Accept": "application/vnd.github+json"},
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
      // Get viewer login
      final userResp = await httpGet(
        Uri.parse("https://api.$_domain/user"),
        headers: {"Authorization": "token $accessToken"},
      );
      if (userResp.statusCode != 200) return false;
      final viewerLogin = json.decode(utf8.decode(userResp.bodyBytes))["login"] as String? ?? "";

      // List reactions filtered by content
      final listUrl = isComment
          ? "https://api.$_domain/repos/$owner/$repo/issues/comments/$targetId/reactions?content=${Uri.encodeComponent(reaction)}&per_page=100"
          : "https://api.$_domain/repos/$owner/$repo/issues/$issueNumber/reactions?content=${Uri.encodeComponent(reaction)}&per_page=100";

      final listResp = await httpGet(
        Uri.parse(listUrl),
        headers: {"Authorization": "token $accessToken", "Accept": "application/vnd.github+json"},
      );
      if (listResp.statusCode != 200) return false;

      final reactions = json.decode(utf8.decode(listResp.bodyBytes)) as List<dynamic>;
      final viewerReaction = reactions.firstWhere(
        (r) => (r["user"]?["login"] as String? ?? "") == viewerLogin,
        orElse: () => null,
      );
      if (viewerReaction == null) return false;

      // Delete the reaction
      final deleteUrl = isComment
          ? "https://api.$_domain/repos/$owner/$repo/issues/comments/$targetId/reactions/${viewerReaction["id"]}"
          : "https://api.$_domain/repos/$owner/$repo/issues/$issueNumber/reactions/${viewerReaction["id"]}";

      final deleteResp = await httpDelete(
        Uri.parse(deleteUrl),
        headers: {"Authorization": "token $accessToken", "Accept": "application/vnd.github+json"},
      );

      return deleteResp.statusCode == 204;
    } catch (e, st) {
      Logger.logError(LogType.RemoveReaction, e, st);
      return false;
    }
  }
}
