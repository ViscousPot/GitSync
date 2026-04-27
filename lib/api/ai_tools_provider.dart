import 'dart:async';

import 'package:GitSync/api/ai_tools.dart';
import 'package:GitSync/api/manager/auth/git_provider_manager.dart';
import 'package:GitSync/api/manager/git_manager.dart';
import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/type/action_run.dart';
import 'package:GitSync/type/issue.dart';
import 'package:GitSync/type/pr_detail.dart';
import 'package:GitSync/type/pull_request.dart';
import 'package:GitSync/type/release.dart';
import 'package:GitSync/type/tag.dart';

Future<_ProviderContext?> _getContext(ToolContext? toolContext) async {
  final ctx = toolContext;
  if (ctx != null) {
    if (ctx.providerManager == null || ctx.owner.isEmpty) return null;
    if (ctx.accessToken.isEmpty) return null;
    return _ProviderContext(manager: ctx.providerManager!, accessToken: ctx.accessToken, owner: ctx.owner, repo: ctx.repo);
  }

  final gitProvider = await uiSettingsManager.getGitProvider();
  if (!gitProvider.isOAuthProvider) return null;

  final remote = await GitManager.getRemoteUrlLink();
  if (remote == null) return null;

  final githubAppOauth = await uiSettingsManager.getBool(StorageKey.setman_githubScopedOauth);
  final credentials = await uiSettingsManager.getGitHttpAuthCredentials();
  final accessToken = credentials.$2;
  if (accessToken.isEmpty) return null;

  final segments = Uri.parse(remote.$1).pathSegments;
  if (segments.length < 2) return null;

  final manager = GitProviderManager.getGitProviderManager(gitProvider, githubAppOauth);
  if (manager == null) return null;

  return _ProviderContext(
    manager: manager,
    accessToken: accessToken,
    owner: segments[segments.length - 2],
    repo: segments[segments.length - 1].replaceAll('.git', ''),
  );
}

class _ProviderContext {
  final GitProviderManager manager;
  final String accessToken;
  final String owner;
  final String repo;
  _ProviderContext({required this.manager, required this.accessToken, required this.owner, required this.repo});
}

class ListIssuesTool extends AiTool {
  @override
  String get name => 'list_issues';
  @override
  String get description => 'List issues in the repository. Returns title, number, state, author, labels, and comment count.';
  @override
  ToolConfirmation get confirmation => ToolConfirmation.none;
  @override
  ToolTier get tier => ToolTier.contextual;
  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'state': {
        'type': 'string',
        'enum': ['open', 'closed'],
        'description': 'Filter by issue state',
        'default': 'open',
      },
      'search': {'type': 'string', 'description': 'Search string to filter issues'},
      'label': {'type': 'string', 'description': 'Filter by label name'},
      'author': {'type': 'string', 'description': 'Filter by author username'},
    },
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final ctx = await _getContext(context);
    if (ctx == null) return err('OAuth not configured for this repository');

    final state = (input['state'] as String?) ?? 'open';
    final search = input['search'] as String?;
    final label = input['label'] as String?;
    final author = input['author'] as String?;

    final completer = Completer<List<Issue>>();
    await ctx.manager.getIssues(ctx.accessToken, ctx.owner, ctx.repo, state, author, label, null, search, null, null, null, (issues) {
      if (!completer.isCompleted) completer.complete(issues);
    }, (_) {});

    final issues = await completer.future.timeout(const Duration(seconds: 30), onTimeout: () => []);
    return ok(
      issues
          .take(30)
          .map(
            (i) => {
              'number': i.number,
              'title': i.title,
              'state': i.isOpen ? 'open' : 'closed',
              'author': i.authorUsername,
              'comments': i.commentCount,
              'labels': i.labels.map((l) => l.name).toList(),
              'created_at': i.createdAt.toIso8601String(),
            },
          )
          .toList(),
    );
  }
}

class GetIssueDetailTool extends AiTool {
  @override
  String get name => 'get_issue_detail';
  @override
  String get description => 'Get full details of a specific issue including body, comments, and reactions.';
  @override
  ToolConfirmation get confirmation => ToolConfirmation.none;
  @override
  ToolTier get tier => ToolTier.contextual;
  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'issue_number': {'type': 'integer', 'description': 'The issue number'},
    },
    'required': ['issue_number'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final ctx = await _getContext(context);
    if (ctx == null) return err('OAuth not configured for this repository');

    final number = input['issue_number'] as int;
    final detail = await ctx.manager.getIssueDetail(ctx.accessToken, ctx.owner, ctx.repo, number);
    if (detail == null) return err('Issue #$number not found');

    return ok({
      'number': detail.number,
      'title': detail.title,
      'state': detail.isOpen ? 'open' : 'closed',
      'author': detail.authorUsername,
      'body': detail.body,
      'labels': detail.labels.map((l) => l.name).toList(),
      'created_at': detail.createdAt.toIso8601String(),
      'comments': detail.comments.map((c) => {'author': c.authorUsername, 'body': c.body, 'created_at': c.createdAt.toIso8601String()}).toList(),
    });
  }
}

class CreateIssueTool extends AiTool {
  @override
  String get name => 'create_issue';
  @override
  String get description => 'Create a new issue in the repository.';
  @override
  ToolConfirmation get confirmation => ToolConfirmation.confirm;
  @override
  ToolTier get tier => ToolTier.contextual;
  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'title': {'type': 'string', 'description': 'Issue title'},
      'body': {'type': 'string', 'description': 'Issue body (markdown)'},
      'labels': {
        'type': 'array',
        'items': {'type': 'string'},
        'description': 'Label names to assign',
      },
      'assignees': {
        'type': 'array',
        'items': {'type': 'string'},
        'description': 'Usernames to assign',
      },
    },
    'required': ['title', 'body'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final ctx = await _getContext(context);
    if (ctx == null) return err('OAuth not configured for this repository');

    final title = input['title'] as String;
    final body = input['body'] as String;
    final labels = (input['labels'] as List?)?.cast<String>();
    final assignees = (input['assignees'] as List?)?.cast<String>();

    final result = await ctx.manager.createIssue(ctx.accessToken, ctx.owner, ctx.repo, title, body, labels: labels, assignees: assignees);
    if (result == null || result.error != null) {
      return err(result?.error ?? 'Failed to create issue');
    }
    return ok({'number': result.number, 'url': result.htmlUrl});
  }
}

class AddIssueCommentTool extends AiTool {
  @override
  String get name => 'add_issue_comment';
  @override
  String get description => 'Add a comment to an issue or pull request.';
  @override
  ToolConfirmation get confirmation => ToolConfirmation.confirm;
  @override
  ToolTier get tier => ToolTier.contextual;
  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'issue_number': {'type': 'integer', 'description': 'The issue or PR number'},
      'body': {'type': 'string', 'description': 'Comment body (markdown)'},
    },
    'required': ['issue_number', 'body'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final ctx = await _getContext(context);
    if (ctx == null) return err('OAuth not configured for this repository');

    final number = input['issue_number'] as int;
    final body = input['body'] as String;

    final comment = await ctx.manager.addIssueComment(ctx.accessToken, ctx.owner, ctx.repo, number, body);
    if (comment == null) return err('Failed to add comment');
    return ok('Comment added to #$number');
  }
}

class UpdateIssueTool extends AiTool {
  @override
  String get name => 'update_issue';
  @override
  String get description => 'Update an issue title and/or body.';
  @override
  ToolConfirmation get confirmation => ToolConfirmation.confirm;
  @override
  ToolTier get tier => ToolTier.advanced;
  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'issue_number': {'type': 'integer', 'description': 'The issue number'},
      'title': {'type': 'string', 'description': 'New title (omit to keep current)'},
      'body': {'type': 'string', 'description': 'New body (omit to keep current)'},
    },
    'required': ['issue_number'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final ctx = await _getContext(context);
    if (ctx == null) return err('OAuth not configured for this repository');

    final number = input['issue_number'] as int;
    final title = input['title'] as String?;
    final body = input['body'] as String?;

    final success = await ctx.manager.updateIssue(ctx.accessToken, ctx.owner, ctx.repo, number, title: title, body: body);
    return success ? ok('Updated issue #$number') : err('Failed to update issue #$number');
  }
}

class CloseReopenIssueTool extends AiTool {
  @override
  String get name => 'close_reopen_issue';
  @override
  String get description => 'Close or reopen an issue.';
  @override
  ToolConfirmation get confirmation => ToolConfirmation.confirm;
  @override
  ToolTier get tier => ToolTier.advanced;
  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'issue_number': {'type': 'integer', 'description': 'The issue number'},
      'action': {
        'type': 'string',
        'enum': ['close', 'reopen'],
        'description': 'Whether to close or reopen',
      },
    },
    'required': ['issue_number', 'action'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final ctx = await _getContext(context);
    if (ctx == null) return err('OAuth not configured for this repository');

    final number = input['issue_number'] as int;
    final close = (input['action'] as String) == 'close';

    final detail = await ctx.manager.getIssueDetail(ctx.accessToken, ctx.owner, ctx.repo, number);
    if (detail == null) return err('Issue #$number not found');

    final success = await ctx.manager.updateIssueState(ctx.accessToken, ctx.owner, ctx.repo, number, detail.id, close);
    return success ? ok('${close ? 'Closed' : 'Reopened'} issue #$number') : err('Failed to ${close ? 'close' : 'reopen'} issue #$number');
  }
}

class ListPullRequestsTool extends AiTool {
  @override
  String get name => 'list_pull_requests';
  @override
  String get description => 'List pull requests in the repository.';
  @override
  ToolConfirmation get confirmation => ToolConfirmation.none;
  @override
  ToolTier get tier => ToolTier.contextual;
  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'state': {
        'type': 'string',
        'enum': ['open', 'merged', 'closed'],
        'description': 'Filter by PR state',
        'default': 'open',
      },
      'search': {'type': 'string', 'description': 'Search string to filter PRs'},
      'author': {'type': 'string', 'description': 'Filter by author username'},
      'label': {'type': 'string', 'description': 'Filter by label name'},
    },
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final ctx = await _getContext(context);
    if (ctx == null) return err('OAuth not configured for this repository');

    final state = (input['state'] as String?) ?? 'open';
    final search = input['search'] as String?;
    final author = input['author'] as String?;
    final label = input['label'] as String?;

    final completer = Completer<List<PullRequest>>();
    await ctx.manager.getPullRequests(ctx.accessToken, ctx.owner, ctx.repo, state, author, label, null, search, null, null, null, (prs) {
      if (!completer.isCompleted) completer.complete(prs);
    }, (_) {});

    final prs = await completer.future.timeout(const Duration(seconds: 30), onTimeout: () => []);
    return ok(
      prs
          .take(30)
          .map(
            (pr) => {
              'number': pr.number,
              'title': pr.title,
              'state': pr.state.name,
              'author': pr.authorUsername,
              'comments': pr.commentCount,
              'check_status': pr.checkStatus.name,
              'labels': pr.labels.map((l) => l.name).toList(),
              'created_at': pr.createdAt.toIso8601String(),
            },
          )
          .toList(),
    );
  }
}

class GetPrDetailTool extends AiTool {
  @override
  String get name => 'get_pr_detail';
  @override
  String get description => 'Get full details of a specific pull request including body, comments, commits, and check status.';
  @override
  ToolConfirmation get confirmation => ToolConfirmation.none;
  @override
  ToolTier get tier => ToolTier.contextual;
  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'pr_number': {'type': 'integer', 'description': 'The pull request number'},
    },
    'required': ['pr_number'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final ctx = await _getContext(context);
    if (ctx == null) return err('OAuth not configured for this repository');

    final number = input['pr_number'] as int;
    final detail = await ctx.manager.getPrDetail(ctx.accessToken, ctx.owner, ctx.repo, number);
    if (detail == null) return err('PR #$number not found');

    return ok({
      'number': detail.number,
      'title': detail.title,
      'state': detail.state.name,
      'author': detail.authorUsername,
      'body': detail.body,
      'head_branch': detail.headBranch,
      'base_branch': detail.baseBranch,
      'labels': detail.labels.map((l) => l.name).toList(),
      'created_at': detail.createdAt.toIso8601String(),
      'commits': detail.commits
          .take(20)
          .map((c) => {'sha': c.sha.length >= 7 ? c.sha.substring(0, 7) : c.sha, 'message': c.message, 'author': c.authorUsername})
          .toList(),
      'comments': detail.timelineItems
          .where((t) => t.type == PrTimelineItemType.comment && t.comment != null)
          .take(20)
          .map((t) => {'author': t.comment!.authorUsername, 'body': t.comment!.body, 'created_at': t.comment!.createdAt.toIso8601String()})
          .toList(),
      'changed_files': detail.changedFileCount,
      'additions': detail.additions,
      'deletions': detail.deletions,
    });
  }
}

class CreatePullRequestTool extends AiTool {
  @override
  String get name => 'create_pull_request';
  @override
  String get description => 'Create a new pull request.';
  @override
  ToolConfirmation get confirmation => ToolConfirmation.confirm;
  @override
  ToolTier get tier => ToolTier.contextual;
  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'title': {'type': 'string', 'description': 'PR title'},
      'body': {'type': 'string', 'description': 'PR description (markdown)'},
      'head': {'type': 'string', 'description': 'Source branch name (the branch with changes)'},
      'base': {'type': 'string', 'description': 'Target branch name (the branch to merge into)'},
    },
    'required': ['title', 'body', 'head', 'base'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final ctx = await _getContext(context);
    if (ctx == null) return err('OAuth not configured for this repository');

    final title = input['title'] as String;
    final body = input['body'] as String;
    final head = input['head'] as String;
    final base = input['base'] as String;

    final result = await ctx.manager.createPullRequest(ctx.accessToken, ctx.owner, ctx.repo, title, body, head, base);
    if (result == null || result.error != null) {
      return err(result?.error ?? 'Failed to create pull request');
    }
    return ok({'number': result.number, 'url': result.htmlUrl});
  }
}

class ListLabelsTool extends AiTool {
  @override
  String get name => 'list_labels';
  @override
  String get description => 'List all labels available in the repository.';
  @override
  ToolConfirmation get confirmation => ToolConfirmation.none;
  @override
  ToolTier get tier => ToolTier.advanced;
  @override
  Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}, 'required': []};

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final ctx = await _getContext(context);
    if (ctx == null) return err('OAuth not configured for this repository');

    final labels = await ctx.manager.getLabels(ctx.accessToken, ctx.owner, ctx.repo);
    return ok(labels);
  }
}

class ListMilestonesTool extends AiTool {
  @override
  String get name => 'list_milestones';
  @override
  String get description => 'List active milestones in the repository.';
  @override
  ToolConfirmation get confirmation => ToolConfirmation.none;
  @override
  ToolTier get tier => ToolTier.advanced;
  @override
  Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}, 'required': []};

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final ctx = await _getContext(context);
    if (ctx == null) return err('OAuth not configured for this repository');

    final milestones = await ctx.manager.getMilestones(ctx.accessToken, ctx.owner, ctx.repo);
    return ok(milestones.map((m) => {'id': m.id, 'title': m.title}).toList());
  }
}

class ListCollaboratorsTool extends AiTool {
  @override
  String get name => 'list_collaborators';
  @override
  String get description => 'List collaborators on the repository.';
  @override
  ToolConfirmation get confirmation => ToolConfirmation.none;
  @override
  ToolTier get tier => ToolTier.advanced;
  @override
  Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}, 'required': []};

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final ctx = await _getContext(context);
    if (ctx == null) return err('OAuth not configured for this repository');

    final collaborators = await ctx.manager.getCollaborators(ctx.accessToken, ctx.owner, ctx.repo);
    return ok(collaborators);
  }
}

class ListTagsTool extends AiTool {
  @override
  String get name => 'list_tags';
  @override
  String get description => 'List tags in the repository.';
  @override
  ToolConfirmation get confirmation => ToolConfirmation.none;
  @override
  ToolTier get tier => ToolTier.advanced;
  @override
  Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}, 'required': []};

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final ctx = await _getContext(context);
    if (ctx == null) return err('OAuth not configured for this repository');

    final completer = Completer<List<Tag>>();
    await ctx.manager.getTags(ctx.accessToken, ctx.owner, ctx.repo, (tags) {
      if (!completer.isCompleted) completer.complete(tags);
    }, (_) {});
    final tags = await completer.future.timeout(const Duration(seconds: 30), onTimeout: () => []);
    return ok(
      tags
          .take(50)
          .map(
            (t) => {
              'name': t.name,
              'sha': t.sha.length >= 7 ? t.sha.substring(0, 7) : t.sha,
              'created_at': t.createdAt.toIso8601String(),
              if (t.message != null) 'message': t.message,
            },
          )
          .toList(),
    );
  }
}

class ListReleasesTool extends AiTool {
  @override
  String get name => 'list_releases';
  @override
  String get description => 'List releases in the repository.';
  @override
  ToolConfirmation get confirmation => ToolConfirmation.none;
  @override
  ToolTier get tier => ToolTier.advanced;
  @override
  Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}, 'required': []};

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final ctx = await _getContext(context);
    if (ctx == null) return err('OAuth not configured for this repository');

    final completer = Completer<List<Release>>();
    await ctx.manager.getReleases(ctx.accessToken, ctx.owner, ctx.repo, (releases) {
      if (!completer.isCompleted) completer.complete(releases);
    }, (_) {});
    final releases = await completer.future.timeout(const Duration(seconds: 30), onTimeout: () => []);
    return ok(
      releases
          .take(20)
          .map(
            (r) => {
              'name': r.name,
              'tag': r.tagName,
              'author': r.authorUsername,
              'created_at': r.createdAt.toIso8601String(),
              'description': r.description.length > 500 ? '${r.description.substring(0, 500)}...' : r.description,
              'prerelease': r.isPrerelease,
              'draft': r.isDraft,
              'assets': r.assets.map((a) => {'name': a.name, 'download_url': a.downloadUrl}).toList(),
            },
          )
          .toList(),
    );
  }
}

class ListActionRunsTool extends AiTool {
  @override
  String get name => 'list_action_runs';
  @override
  String get description => 'List CI/CD action runs (GitHub Actions, GitLab Pipelines, Gitea Actions).';
  @override
  ToolConfirmation get confirmation => ToolConfirmation.none;
  @override
  ToolTier get tier => ToolTier.advanced;
  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'state': {'type': 'string', 'description': 'Filter by status (e.g. success, failure, pending)', 'default': ''},
    },
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final ctx = await _getContext(context);
    if (ctx == null) return err('OAuth not configured for this repository');

    final state = (input['state'] as String?) ?? '';
    final completer = Completer<List<ActionRun>>();
    await ctx.manager.getActionRuns(ctx.accessToken, ctx.owner, ctx.repo, state, (runs) {
      if (!completer.isCompleted) completer.complete(runs);
    }, (_) {});
    final runs = await completer.future.timeout(const Duration(seconds: 30), onTimeout: () => []);
    return ok(
      runs
          .take(20)
          .map(
            (r) => {
              'name': r.name,
              'number': r.number,
              'status': r.status.name,
              'event': r.event,
              'author': r.authorUsername,
              'created_at': r.createdAt.toIso8601String(),
              if (r.branch != null) 'branch': r.branch,
              if (r.prNumber != null) 'pr_number': r.prNumber,
              if (r.duration != null) 'duration_seconds': r.duration!.inSeconds,
            },
          )
          .toList(),
    );
  }
}

class AddReactionTool extends AiTool {
  @override
  String get name => 'add_reaction';
  @override
  String get description => 'Add an emoji reaction to an issue, PR, or comment.';
  @override
  ToolConfirmation get confirmation => ToolConfirmation.none;
  @override
  ToolTier get tier => ToolTier.advanced;
  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'issue_number': {'type': 'integer', 'description': 'Issue or PR number'},
      'reaction': {'type': 'string', 'description': 'Reaction emoji (e.g. "+1", "heart", "laugh", "hooray", "rocket", "eyes")'},
      'comment_id': {'type': 'string', 'description': 'Comment ID to react to. Omit to react to the issue/PR itself.'},
    },
    'required': ['issue_number', 'reaction'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final ctx = await _getContext(context);
    if (ctx == null) return err('OAuth not configured for this repository');

    final number = input['issue_number'] as int;
    final reaction = input['reaction'] as String;
    final commentId = input['comment_id'] as String?;
    final isComment = commentId != null;

    final success = await ctx.manager.addReaction(ctx.accessToken, ctx.owner, ctx.repo, number, commentId ?? '$number', reaction, isComment);
    return success ? ok('Added $reaction reaction') : err('Failed to add reaction');
  }
}

class RemoveReactionTool extends AiTool {
  @override
  String get name => 'remove_reaction';
  @override
  String get description => 'Remove your emoji reaction from an issue, PR, or comment.';
  @override
  ToolConfirmation get confirmation => ToolConfirmation.none;
  @override
  ToolTier get tier => ToolTier.advanced;
  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'issue_number': {'type': 'integer', 'description': 'Issue or PR number'},
      'reaction': {'type': 'string', 'description': 'Reaction emoji to remove'},
      'comment_id': {'type': 'string', 'description': 'Comment ID. Omit for issue/PR reaction.'},
    },
    'required': ['issue_number', 'reaction'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final ctx = await _getContext(context);
    if (ctx == null) return err('OAuth not configured for this repository');

    final number = input['issue_number'] as int;
    final reaction = input['reaction'] as String;
    final commentId = input['comment_id'] as String?;
    final isComment = commentId != null;

    final success = await ctx.manager.removeReaction(ctx.accessToken, ctx.owner, ctx.repo, number, commentId ?? '$number', reaction, isComment);
    return success ? ok('Removed $reaction reaction') : err('Failed to remove reaction');
  }
}

class GetIssueTemplatesTool extends AiTool {
  @override
  String get name => 'get_issue_templates';
  @override
  String get description => 'Get available issue templates for the repository.';
  @override
  ToolConfirmation get confirmation => ToolConfirmation.none;
  @override
  ToolTier get tier => ToolTier.advanced;
  @override
  Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}, 'required': []};

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final ctx = await _getContext(context);
    if (ctx == null) return err('OAuth not configured for this repository');

    final templates = await ctx.manager.getIssueTemplates(ctx.accessToken, ctx.owner, ctx.repo);
    return ok(
      templates
          .map(
            (t) => {
              'name': t.name,
              'description': t.description,
              if (t.title != null) 'title': t.title,
              if (t.body != null) 'body': t.body,
              'labels': t.labels,
              'assignees': t.assignees,
            },
          )
          .toList(),
    );
  }
}

class GetPrTemplatesTool extends AiTool {
  @override
  String get name => 'get_pr_templates';
  @override
  String get description => 'Get available pull request templates for the repository.';
  @override
  ToolConfirmation get confirmation => ToolConfirmation.none;
  @override
  ToolTier get tier => ToolTier.advanced;
  @override
  Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}, 'required': []};

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final ctx = await _getContext(context);
    if (ctx == null) return err('OAuth not configured for this repository');

    final templates = await ctx.manager.getPrTemplates(ctx.accessToken, ctx.owner, ctx.repo);
    return ok(templates.map((t) => {'name': t.name, 'description': t.description, if (t.body != null) 'body': t.body}).toList());
  }
}

class ListRemoteBranchesTool extends AiTool {
  @override
  String get name => 'list_remote_branches';
  @override
  String get description => 'List branches on the remote repository (via provider API), including the default branch.';
  @override
  ToolConfirmation get confirmation => ToolConfirmation.none;
  @override
  ToolTier get tier => ToolTier.advanced;
  @override
  Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}, 'required': []};

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final ctx = await _getContext(context);
    if (ctx == null) return err('OAuth not configured for this repository');

    final result = await ctx.manager.getRepoBranches(ctx.accessToken, ctx.owner, ctx.repo);
    return ok({'branches': result.$1, 'default_branch': result.$2});
  }
}

class CreateRepoTool extends AiTool {
  @override
  String get name => 'create_repo';
  @override
  String get description => 'Create a new repository on the remote provider.';
  @override
  ToolConfirmation get confirmation => ToolConfirmation.confirm;
  @override
  ToolTier get tier => ToolTier.advanced;
  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'repo_name': {'type': 'string', 'description': 'Repository name'},
      'private': {'type': 'boolean', 'description': 'Whether the repo should be private', 'default': false},
    },
    'required': ['repo_name'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final ctx = await _getContext(context);
    if (ctx == null) return err('OAuth not configured for this repository');

    final repoName = input['repo_name'] as String;
    final isPrivate = (input['private'] as bool?) ?? false;
    final username = context?.username ?? (await uiSettingsManager.getGitHttpAuthCredentials()).$1;

    final result = await ctx.manager.createRepo(ctx.accessToken, username, repoName, isPrivate);
    if (result == null) return err('Failed to create repository');
    if (result.$2 != null) return err(result.$2!);
    return ok({'clone_url': result.$1});
  }
}

class ListReposTool extends AiTool {
  @override
  String get name => 'list_repos';
  @override
  String get description => 'List repositories accessible to the authenticated user.';
  @override
  ToolConfirmation get confirmation => ToolConfirmation.none;
  @override
  ToolTier get tier => ToolTier.advanced;
  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'search': {'type': 'string', 'description': 'Search filter', 'default': ''},
    },
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final ctx = await _getContext(context);
    if (ctx == null) return err('OAuth not configured for this repository');

    final search = (input['search'] as String?) ?? '';
    final completer = Completer<List<(String, String)>>();
    await ctx.manager.getRepos(ctx.accessToken, search, (repos) {
      if (!completer.isCompleted) completer.complete(repos);
    }, (_) {});
    final repos = await completer.future.timeout(const Duration(seconds: 30), onTimeout: () => []);
    return ok(repos.take(30).map((r) => {'name': r.$1, 'clone_url': r.$2}).toList());
  }
}

class ListProjectsTool extends AiTool {
  @override
  String get name => 'list_projects';
  @override
  String get description => 'List projects associated with the repository (GitHub Projects).';
  @override
  ToolConfirmation get confirmation => ToolConfirmation.none;
  @override
  ToolTier get tier => ToolTier.advanced;
  @override
  Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}, 'required': []};

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final ctx = await _getContext(context);
    if (ctx == null) return err('OAuth not configured for this repository');

    final projects = await ctx.manager.getProjects(ctx.accessToken, ctx.owner, ctx.repo);
    return ok(projects.map((p) => {'id': p.id, 'title': p.title}).toList());
  }
}

class GetSettingsInfoTool extends AiTool {
  @override
  String get name => 'get_settings_info';
  @override
  String get description => 'Get current repository settings: git provider, sync message template, commit footer, and client mode status.';
  @override
  ToolConfirmation get confirmation => ToolConfirmation.none;
  @override
  ToolTier get tier => ToolTier.advanced;
  @override
  Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}, 'required': []};

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    if (context != null) {
      return ok({
        'git_provider': context.gitProvider?.name ?? 'unknown',
        'is_oauth_provider': context.gitProvider?.isOAuthProvider ?? false,
        'author_name': context.authorName,
        'author_email': context.authorEmail,
      });
    }
    final gitProvider = await uiSettingsManager.getGitProvider();
    final syncMessage = await uiSettingsManager.getSyncMessage();
    final postFooter = await uiSettingsManager.getPostFooter();
    final clientMode = await uiSettingsManager.getClientModeEnabled();
    return ok({
      'git_provider': gitProvider.name,
      'is_oauth_provider': gitProvider.isOAuthProvider,
      'sync_message_template': syncMessage,
      'commit_footer': postFooter,
      'client_mode_enabled': clientMode,
    });
  }
}

List<AiTool> allProviderTools() => [
  ListIssuesTool(),
  GetIssueDetailTool(),
  CreateIssueTool(),
  AddIssueCommentTool(),
  UpdateIssueTool(),
  CloseReopenIssueTool(),
  ListPullRequestsTool(),
  GetPrDetailTool(),
  CreatePullRequestTool(),
  ListLabelsTool(),
  ListMilestonesTool(),
  ListCollaboratorsTool(),
  ListTagsTool(),
  ListReleasesTool(),
  ListActionRunsTool(),
  AddReactionTool(),
  RemoveReactionTool(),
  GetIssueTemplatesTool(),
  GetPrTemplatesTool(),
  ListRemoteBranchesTool(),
  CreateRepoTool(),
  ListReposTool(),
  ListProjectsTool(),
  GetSettingsInfoTool(),
];
