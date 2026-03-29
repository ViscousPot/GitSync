import 'dart:io';

import 'package:GitSync/api/ai_completion_service.dart';
import 'package:GitSync/api/ai_tools.dart';
import 'package:GitSync/api/manager/git_manager.dart';
import 'package:GitSync/global.dart';

String? _repoPath(ToolContext? context) => context?.repoPath ?? uiSettingsManager.gitDirPath?.$1;

class GitStatusTool extends AiTool {
  @override String get name => 'git_status';
  @override String get description => 'Get the current git status: uncommitted files, staged files, current branch, and pending conflicts.';
  @override ToolConfirmation get confirmation => ToolConfirmation.none;
  @override Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}, 'required': []};

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final ri = context?.repoIndex;
    final branch = await GitManager.getBranchName(repoIndex: ri);
    final uncommitted = await GitManager.getUncommittedFilePaths(ri);
    final staged = await GitManager.getStagedFilePaths(repoIndex: ri);
    final conflicts = await GitManager.getConflicting(ri);
    return ok({
      'branch': branch,
      'uncommitted': uncommitted.map((e) => e.$1).toList(),
      'staged': staged.map((e) => e.$1).toList(),
      'conflicts': conflicts.map((e) => e.$1).toList(),
    });
  }
}

class GitLogTool extends AiTool {
  @override String get name => 'git_log';
  @override String get description => 'Get recent commits in the repository.';
  @override ToolConfirmation get confirmation => ToolConfirmation.none;
  @override Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'count': {'type': 'integer', 'description': 'Number of recent commits to retrieve (max 50)', 'default': 10},
    },
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final count = (input['count'] as int?) ?? 10;
    final commits = await GitManager.getRecentCommits(repoIndex: context?.repoIndex);
    final limited = commits.take(count.clamp(1, 50)).toList();
    return ok(limited.map((c) => {
      'sha': c.reference.length >= 7 ? c.reference.substring(0, 7) : c.reference,
      'message': c.commitMessage,
      'author': c.authorUsername,
      'timestamp': DateTime.fromMillisecondsSinceEpoch(c.timestamp * 1000).toIso8601String(),
      'additions': c.additions,
      'deletions': c.deletions,
      'unpushed': c.unpushed,
      if (c.tags.isNotEmpty) 'tags': c.tags,
    }).toList());
  }
}

class GitDiffTool extends AiTool {
  @override String get name => 'git_diff';
  @override String get description => 'Get the diff for a specific file (working directory changes) or between commits.';
  @override ToolConfirmation get confirmation => ToolConfirmation.none;
  @override Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'file_path': {'type': 'string', 'description': 'Relative path to the file to diff (for working directory diff)'},
      'commit_sha': {'type': 'string', 'description': 'Commit SHA to diff (shows changes introduced by this commit)'},
      'end_sha': {'type': 'string', 'description': 'End commit SHA for range diff'},
    },
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final filePath = input['file_path'] as String?;
    final commitSha = input['commit_sha'] as String?;
    final endSha = input['end_sha'] as String?;

    if (filePath != null) {
      final diff = await GitManager.getWorkdirFileDiff(filePath, repoIndex: context?.repoIndex);
      if (diff == null) return err('No diff available for $filePath');
      final lines = diff.lines.map((l) => '${l.origin} ${l.content}').join();
      return ok({'file': diff.filePath, 'insertions': diff.insertions, 'deletions': diff.deletions, 'diff': lines});
    }

    if (commitSha != null) {
      final diff = await GitManager.getCommitDiff(commitSha, endSha, repoIndex: context?.repoIndex);
      if (diff == null) return err('No diff available for commit $commitSha');
      return ok({'insertions': diff.insertions, 'deletions': diff.deletions, 'diff': formatDiffParts(diff.diffParts)});
    }

    return err('Provide either file_path or commit_sha');
  }
}

class GitCommitShowTool extends AiTool {
  @override String get name => 'git_commit_show';
  @override String get description => 'Show the full details and diff of a specific commit.';
  @override ToolConfirmation get confirmation => ToolConfirmation.none;
  @override Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'sha': {'type': 'string', 'description': 'Commit SHA'},
    },
    'required': ['sha'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final sha = input['sha'] as String;
    final diff = await GitManager.getCommitDiff(sha, null, repoIndex: context?.repoIndex);
    if (diff == null) return err('Could not get diff for commit $sha');
    return ok({'insertions': diff.insertions, 'deletions': diff.deletions, 'diff': formatDiffParts(diff.diffParts)});
  }
}

class GitStageTool extends AiTool {
  @override String get name => 'git_stage';
  @override String get description => 'Stage files for the next commit.';
  @override ToolConfirmation get confirmation => ToolConfirmation.none;
  @override Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'paths': {'type': 'array', 'items': {'type': 'string'}, 'description': "File paths to stage. Use ['.'] to stage all."},
    },
    'required': ['paths'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final paths = (input['paths'] as List).cast<String>();
    await GitManager.stageFilePaths(paths, repoIndex: context?.repoIndex);
    return ok('Staged ${paths.length} file(s)');
  }
}

class GitUnstageTool extends AiTool {
  @override String get name => 'git_unstage';
  @override String get description => 'Unstage previously staged files.';
  @override ToolConfirmation get confirmation => ToolConfirmation.none;
  @override Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'paths': {'type': 'array', 'items': {'type': 'string'}, 'description': 'File paths to unstage'},
    },
    'required': ['paths'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final paths = (input['paths'] as List).cast<String>();
    await GitManager.unstageFilePaths(paths, repoIndex: context?.repoIndex);
    return ok('Unstaged ${paths.length} file(s)');
  }
}

class GitCommitTool extends AiTool {
  @override String get name => 'git_commit';
  @override String get description => 'Commit staged changes with a message.';
  @override ToolConfirmation get confirmation => ToolConfirmation.warn;
  @override Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'message': {'type': 'string', 'description': 'The commit message'},
    },
    'required': ['message'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final message = input['message'] as String;
    await GitManager.commitChanges(message, repoIndex: context?.repoIndex);
    return ok('Committed with message: $message');
  }
}

class GitPushTool extends AiTool {
  @override String get name => 'git_push';
  @override String get description => 'Push local commits to the remote repository.';
  @override ToolConfirmation get confirmation => ToolConfirmation.confirm;
  @override Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}, 'required': []};

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    await GitManager.pushChanges(repoIndex: context?.repoIndex);
    return ok('Pushed successfully');
  }
}

class GitPullTool extends AiTool {
  @override String get name => 'git_pull';
  @override String get description => 'Pull changes from the remote repository.';
  @override ToolConfirmation get confirmation => ToolConfirmation.confirm;
  @override Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}, 'required': []};

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    await GitManager.pullChanges(repoIndex: context?.repoIndex);
    return ok('Pulled successfully');
  }
}

class GitBranchListTool extends AiTool {
  @override String get name => 'git_branch_list';
  @override String get description => 'List all local and remote branches.';
  @override ToolConfirmation get confirmation => ToolConfirmation.none;
  @override Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}, 'required': []};

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final branches = await GitManager.getBranchNames(repoIndex: context?.repoIndex);
    return ok(branches.map((b) => {'name': b.$1, 'ref': b.$2}).toList());
  }
}

class GitBranchCreateTool extends AiTool {
  @override String get name => 'git_branch_create';
  @override String get description => 'Create a new branch from a source branch.';
  @override ToolConfirmation get confirmation => ToolConfirmation.warn;
  @override Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'name': {'type': 'string', 'description': 'New branch name'},
      'based_on': {'type': 'string', 'description': 'Source branch to branch from'},
    },
    'required': ['name', 'based_on'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final name = input['name'] as String;
    final basedOn = input['based_on'] as String;
    await GitManager.createBranch(name, basedOn, repoIndex: context?.repoIndex);
    return ok('Created branch $name from $basedOn');
  }
}

class GitBranchCheckoutTool extends AiTool {
  @override String get name => 'git_branch_checkout';
  @override String get description => 'Switch to a different branch.';
  @override ToolConfirmation get confirmation => ToolConfirmation.warn;
  @override Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'name': {'type': 'string', 'description': 'Branch name to check out'},
    },
    'required': ['name'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final name = input['name'] as String;
    await GitManager.checkoutBranch(name, repoIndex: context?.repoIndex);
    return ok('Checked out branch $name');
  }
}

class GitBranchDeleteTool extends AiTool {
  @override String get name => 'git_branch_delete';
  @override String get description => 'Delete a local branch.';
  @override ToolConfirmation get confirmation => ToolConfirmation.confirm;
  @override Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'name': {'type': 'string', 'description': 'Branch name to delete'},
    },
    'required': ['name'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final name = input['name'] as String;
    await GitManager.deleteBranch(name, repoIndex: context?.repoIndex);
    return ok('Deleted branch $name');
  }
}

class GitDiscardTool extends AiTool {
  @override String get name => 'git_discard';
  @override String get description => 'Discard uncommitted changes to specified files. THIS IS IRREVERSIBLE.';
  @override ToolConfirmation get confirmation => ToolConfirmation.confirm;
  @override Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'paths': {'type': 'array', 'items': {'type': 'string'}, 'description': 'File paths to discard changes for'},
    },
    'required': ['paths'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final paths = (input['paths'] as List).cast<String>();
    await GitManager.discardChanges(paths, repoIndex: context?.repoIndex);
    return ok('Discarded changes for ${paths.length} file(s)');
  }
}

class GitAmendCommitTool extends AiTool {
  @override String get name => 'git_amend_commit';
  @override String get description => 'Amend the most recent commit message.';
  @override ToolConfirmation get confirmation => ToolConfirmation.confirm;
  @override ToolTier get tier => ToolTier.advanced;
  @override Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'message': {'type': 'string', 'description': 'New commit message'},
    },
    'required': ['message'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final message = input['message'] as String;
    await GitManager.amendCommit(message, repoIndex: context?.repoIndex);
    return ok('Amended commit with message: $message');
  }
}

class GitRevertCommitTool extends AiTool {
  @override String get name => 'git_revert_commit';
  @override String get description => 'Revert a commit by creating a new commit that undoes its changes. May fail if there are conflicts.';
  @override ToolConfirmation get confirmation => ToolConfirmation.confirm;
  @override ToolTier get tier => ToolTier.advanced;
  @override Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'commit_sha': {'type': 'string', 'description': 'SHA of the commit to revert'},
    },
    'required': ['commit_sha'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final sha = input['commit_sha'] as String;
    await GitManager.revertCommit(sha, repoIndex: context?.repoIndex);
    return ok('Reverted commit $sha');
  }
}

class GitResetToCommitTool extends AiTool {
  @override String get name => 'git_reset_to_commit';
  @override String get description => 'Hard reset to a specific commit. ALL commits after this point will be permanently lost. This cannot be undone.';
  @override ToolConfirmation get confirmation => ToolConfirmation.danger;
  @override ToolTier get tier => ToolTier.advanced;
  @override Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'commit_sha': {'type': 'string', 'description': 'SHA of the commit to reset to'},
    },
    'required': ['commit_sha'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final sha = input['commit_sha'] as String;
    await GitManager.resetToCommit(sha, repoIndex: context?.repoIndex);
    return ok('Reset to commit $sha');
  }
}

class GitCherryPickTool extends AiTool {
  @override String get name => 'git_cherry_pick';
  @override String get description => 'Apply a commit from one branch onto a target branch.';
  @override ToolConfirmation get confirmation => ToolConfirmation.confirm;
  @override ToolTier get tier => ToolTier.advanced;
  @override Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'commit_sha': {'type': 'string', 'description': 'SHA of the commit to cherry-pick'},
      'target_branch': {'type': 'string', 'description': 'Branch to apply the commit onto'},
    },
    'required': ['commit_sha', 'target_branch'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final sha = input['commit_sha'] as String;
    final targetBranch = input['target_branch'] as String;
    await GitManager.cherryPickCommit(sha, targetBranch, repoIndex: context?.repoIndex);
    return ok('Cherry-picked commit $sha onto $targetBranch');
  }
}

class GitSquashCommitsTool extends AiTool {
  @override String get name => 'git_squash_commits';
  @override String get description => 'Squash multiple commits into one, starting from the oldest commit SHA. All commits from that point to HEAD are combined. This rewrites history.';
  @override ToolConfirmation get confirmation => ToolConfirmation.danger;
  @override ToolTier get tier => ToolTier.advanced;
  @override Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'oldest_commit_sha': {'type': 'string', 'description': 'SHA of the oldest commit in the range to squash'},
      'message': {'type': 'string', 'description': 'Commit message for the squashed commit'},
    },
    'required': ['oldest_commit_sha', 'message'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final oldestSha = input['oldest_commit_sha'] as String;
    final message = input['message'] as String;
    await GitManager.squashCommits(oldestSha, message, repoIndex: context?.repoIndex);
    return ok('Squashed commits from $oldestSha to HEAD with message: $message');
  }
}

class GitIgnoreReadTool extends AiTool {
  @override String get name => 'git_gitignore_read';
  @override String get description => 'Read the current .gitignore file contents.';
  @override ToolConfirmation get confirmation => ToolConfirmation.none;
  @override Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}, 'required': []};

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final root = _repoPath(context);
    if (root == null) return err('No repository open');
    final file = File('$root/.gitignore');
    if (!await file.exists()) return ok('No .gitignore file found');
    return ok(await file.readAsString());
  }
}

class GitIgnoreWriteTool extends AiTool {
  @override String get name => 'git_gitignore_write';
  @override String get description => 'Replace the .gitignore file with new contents.';
  @override ToolConfirmation get confirmation => ToolConfirmation.warn;
  @override ToolTier get tier => ToolTier.advanced;
  @override Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'content': {'type': 'string', 'description': 'Full .gitignore file content'},
    },
    'required': ['content'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final content = input['content'] as String;
    final root = _repoPath(context);
    if (root == null) return err('No repository open');
    await File('$root/.gitignore').writeAsString(content);
    return ok('Updated .gitignore');
  }
}

class GitUndoCommitTool extends AiTool {
  @override String get name => 'git_undo_commit';
  @override String get description => 'Undo the most recent commit. The commit is removed but all changes are kept as staged files.';
  @override ToolConfirmation get confirmation => ToolConfirmation.confirm;
  @override Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}, 'required': []};

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    await GitManager.undoCommit(repoIndex: context?.repoIndex);
    return ok('Undid the most recent commit. Changes are now staged.');
  }
}

class GitCreateTagTool extends AiTool {
  @override String get name => 'git_create_tag';
  @override String get description => 'Create a tag on a specific commit.';
  @override ToolConfirmation get confirmation => ToolConfirmation.warn;
  @override ToolTier get tier => ToolTier.advanced;
  @override Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'tag_name': {'type': 'string', 'description': 'Name for the tag (e.g. v1.0.0)'},
      'commit_sha': {'type': 'string', 'description': 'Commit SHA to tag'},
    },
    'required': ['tag_name', 'commit_sha'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final tagName = input['tag_name'] as String;
    final commitSha = input['commit_sha'] as String;
    await GitManager.createTag(tagName, commitSha, repoIndex: context?.repoIndex);
    return ok('Created tag $tagName on commit $commitSha');
  }
}

class GitFetchTool extends AiTool {
  @override String get name => 'git_fetch';
  @override String get description => 'Fetch latest changes from the remote without merging. Use this to check for updates before pulling.';
  @override ToolConfirmation get confirmation => ToolConfirmation.confirm;
  @override Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}, 'required': []};

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    await GitManager.fetchRemote(repoIndex: context?.repoIndex);
    return ok('Fetched from remote');
  }
}

class GitBranchRenameTool extends AiTool {
  @override String get name => 'git_branch_rename';
  @override String get description => 'Rename a local branch.';
  @override ToolConfirmation get confirmation => ToolConfirmation.warn;
  @override ToolTier get tier => ToolTier.advanced;
  @override Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'old_name': {'type': 'string', 'description': 'Current branch name'},
      'new_name': {'type': 'string', 'description': 'New branch name'},
    },
    'required': ['old_name', 'new_name'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final oldName = input['old_name'] as String;
    final newName = input['new_name'] as String;
    await GitManager.renameBranch(oldName, newName, repoIndex: context?.repoIndex);
    return ok('Renamed branch $oldName to $newName');
  }
}

class RepoInfoTool extends AiTool {
  @override String get name => 'repo_info';
  @override String get description => 'Get a summary of the repository: remote URL, current branch, author config.';
  @override ToolConfirmation get confirmation => ToolConfirmation.none;
  @override Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}, 'required': []};

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final branch = await GitManager.getBranchName(repoIndex: context?.repoIndex);
    final remote = await GitManager.getRemoteUrlLink(repoIndex: context?.repoIndex);
    return ok({
      'branch': branch,
      'remote_url': remote?.$1,
      'remote_name': remote?.$2,
      'author_name': context?.authorName ?? await uiSettingsManager.getAuthorName(),
      'author_email': context?.authorEmail ?? await uiSettingsManager.getAuthorEmail(),
    });
  }
}

class GitForcePullTool extends AiTool {
  @override String get name => 'git_force_pull';
  @override String get description => 'Force pull from remote, discarding all local commits that conflict. Local uncommitted changes may be lost.';
  @override ToolConfirmation get confirmation => ToolConfirmation.danger;
  @override ToolTier get tier => ToolTier.advanced;
  @override Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}, 'required': []};

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    await GitManager.forcePull(repoIndex: context?.repoIndex);
    return ok('Force pulled from remote');
  }
}

class GitForcePushTool extends AiTool {
  @override String get name => 'git_force_push';
  @override String get description => 'Force push to remote, overwriting remote history. This affects all collaborators and cannot be undone.';
  @override ToolConfirmation get confirmation => ToolConfirmation.danger;
  @override ToolTier get tier => ToolTier.advanced;
  @override Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}, 'required': []};

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    await GitManager.forcePush(repoIndex: context?.repoIndex);
    return ok('Force pushed to remote');
  }
}

class GitDownloadAndOverwriteTool extends AiTool {
  @override String get name => 'git_download_and_overwrite';
  @override String get description => 'Replace ALL local files with the remote version. Every local change and commit will be permanently lost.';
  @override ToolConfirmation get confirmation => ToolConfirmation.danger;
  @override ToolTier get tier => ToolTier.advanced;
  @override Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}, 'required': []};

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    await GitManager.downloadAndOverwrite(repoIndex: context?.repoIndex);
    return ok('Downloaded and overwrote local with remote');
  }
}

class GitUploadAndOverwriteTool extends AiTool {
  @override String get name => 'git_upload_and_overwrite';
  @override String get description => 'Replace ALL remote files with the local version. The entire remote history will be overwritten.';
  @override ToolConfirmation get confirmation => ToolConfirmation.danger;
  @override ToolTier get tier => ToolTier.advanced;
  @override Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}, 'required': []};

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    await GitManager.uploadAndOverwrite(repoIndex: context?.repoIndex);
    return ok('Uploaded and overwrote remote with local');
  }
}

class GitPruneCorruptedObjectsTool extends AiTool {
  @override String get name => 'git_prune_corrupted_objects';
  @override String get description => 'Repair the repository by pruning corrupted git objects.';
  @override ToolConfirmation get confirmation => ToolConfirmation.confirm;
  @override ToolTier get tier => ToolTier.advanced;
  @override Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}, 'required': []};

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    await GitManager.pruneCorruptedObjects(repoIndex: context?.repoIndex);
    return ok('Pruned corrupted objects');
  }
}

class GitGetDisableSslTool extends AiTool {
  @override String get name => 'git_get_disable_ssl';
  @override String get description => 'Check whether SSL verification is disabled for this repository.';
  @override ToolConfirmation get confirmation => ToolConfirmation.none;
  @override ToolTier get tier => ToolTier.advanced;
  @override Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}, 'required': []};

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final disabled = await GitManager.getDisableSsl(repoIndex: context?.repoIndex);
    return ok({'ssl_disabled': disabled});
  }
}

class GitSetDisableSslTool extends AiTool {
  @override String get name => 'git_set_disable_ssl';
  @override String get description => 'Enable or disable SSL verification for this repository.';
  @override ToolConfirmation get confirmation => ToolConfirmation.confirm;
  @override ToolTier get tier => ToolTier.advanced;
  @override Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'disable': {'type': 'boolean', 'description': 'Set to true to disable SSL verification, false to enable'},
    },
    'required': ['disable'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final disable = input['disable'] as bool;
    await GitManager.setDisableSsl(disable, repoIndex: context?.repoIndex);
    return ok('SSL verification ${disable ? 'disabled' : 'enabled'}');
  }
}

class GitSetRemoteUrlTool extends AiTool {
  @override String get name => 'git_set_remote_url';
  @override String get description => 'Change the remote URL for the repository.';
  @override ToolConfirmation get confirmation => ToolConfirmation.danger;
  @override ToolTier get tier => ToolTier.advanced;
  @override Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'url': {'type': 'string', 'description': 'New remote URL'},
    },
    'required': ['url'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final url = input['url'] as String;
    await GitManager.setRemoteUrl(url, repoIndex: context?.repoIndex);
    return ok('Remote URL set to $url');
  }
}

class GitAddRemoteTool extends AiTool {
  @override String get name => 'git_add_remote';
  @override String get description => 'Add a new remote to the repository.';
  @override ToolConfirmation get confirmation => ToolConfirmation.confirm;
  @override ToolTier get tier => ToolTier.advanced;
  @override Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'name': {'type': 'string', 'description': 'Remote name (e.g. "upstream")'},
      'url': {'type': 'string', 'description': 'Remote URL'},
    },
    'required': ['name', 'url'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final name = input['name'] as String;
    final url = input['url'] as String;
    await GitManager.addRemote(name, url, repoIndex: context?.repoIndex);
    return ok('Added remote $name ($url)');
  }
}

class GitDeleteRemoteTool extends AiTool {
  @override String get name => 'git_delete_remote';
  @override String get description => 'Delete a remote from the repository.';
  @override ToolConfirmation get confirmation => ToolConfirmation.danger;
  @override ToolTier get tier => ToolTier.advanced;
  @override Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'name': {'type': 'string', 'description': 'Remote name to delete'},
    },
    'required': ['name'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final name = input['name'] as String;
    await GitManager.deleteRemote(name, repoIndex: context?.repoIndex);
    return ok('Deleted remote $name');
  }
}

class GitRenameRemoteTool extends AiTool {
  @override String get name => 'git_rename_remote';
  @override String get description => 'Rename a remote.';
  @override ToolConfirmation get confirmation => ToolConfirmation.confirm;
  @override ToolTier get tier => ToolTier.advanced;
  @override Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'old_name': {'type': 'string', 'description': 'Current remote name'},
      'new_name': {'type': 'string', 'description': 'New remote name'},
    },
    'required': ['old_name', 'new_name'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final oldName = input['old_name'] as String;
    final newName = input['new_name'] as String;
    await GitManager.renameRemote(oldName, newName, repoIndex: context?.repoIndex);
    return ok('Renamed remote $oldName to $newName');
  }
}

class GitCheckoutCommitTool extends AiTool {
  @override String get name => 'git_checkout_commit';
  @override String get description => 'Check out a specific commit (detached HEAD). You will not be on any branch after this.';
  @override ToolConfirmation get confirmation => ToolConfirmation.danger;
  @override ToolTier get tier => ToolTier.advanced;
  @override Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'commit_sha': {'type': 'string', 'description': 'Commit SHA to check out'},
    },
    'required': ['commit_sha'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final sha = input['commit_sha'] as String;
    await GitManager.checkoutCommit(sha, repoIndex: context?.repoIndex);
    return ok('Checked out commit $sha (detached HEAD)');
  }
}

class GitCreateBranchFromCommitTool extends AiTool {
  @override String get name => 'git_branch_create_from_commit';
  @override String get description => 'Create a new branch starting at a specific commit.';
  @override ToolConfirmation get confirmation => ToolConfirmation.warn;
  @override ToolTier get tier => ToolTier.advanced;
  @override Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'name': {'type': 'string', 'description': 'New branch name'},
      'commit_sha': {'type': 'string', 'description': 'Commit SHA to branch from'},
    },
    'required': ['name', 'commit_sha'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final name = input['name'] as String;
    final sha = input['commit_sha'] as String;
    await GitManager.createBranchFromCommit(name, sha, repoIndex: context?.repoIndex);
    return ok('Created branch $name at commit $sha');
  }
}

class GitUpdateSubmodulesTool extends AiTool {
  @override String get name => 'git_update_submodules';
  @override String get description => 'Update and sync all git submodules in the repository.';
  @override ToolConfirmation get confirmation => ToolConfirmation.confirm;
  @override ToolTier get tier => ToolTier.advanced;
  @override Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}, 'required': []};

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    await GitManager.updateSubmodules(repoIndex: context?.repoIndex);
    return ok('Updated submodules');
  }
}

class GitAbortMergeTool extends AiTool {
  @override String get name => 'git_abort_merge';
  @override String get description => 'Abort an in-progress merge and return to the pre-merge state.';
  @override ToolConfirmation get confirmation => ToolConfirmation.confirm;
  @override ToolTier get tier => ToolTier.advanced;
  @override Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}, 'required': []};

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    await GitManager.abortMerge(repoIndex: context?.repoIndex);
    return ok('Merge aborted');
  }
}

class GitListRemotesTool extends AiTool {
  @override String get name => 'git_list_remotes';
  @override String get description => 'List all configured remote names.';
  @override ToolConfirmation get confirmation => ToolConfirmation.none;
  @override ToolTier get tier => ToolTier.advanced;
  @override Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}, 'required': []};

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final remotes = await GitManager.listRemotes(context?.repoIndex);
    return ok(remotes);
  }
}

class GitUntrackAllTool extends AiTool {
  @override String get name => 'git_untrack';
  @override String get description => 'Remove files from git tracking without deleting them from disk.';
  @override ToolConfirmation get confirmation => ToolConfirmation.confirm;
  @override ToolTier get tier => ToolTier.advanced;
  @override Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'paths': {'type': 'array', 'items': {'type': 'string'}, 'description': 'File paths to untrack. Omit to untrack all.'},
    },
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final paths = (input['paths'] as List?)?.cast<String>();
    await GitManager.untrackAll(filePaths: paths, repoIndex: context?.repoIndex);
    return ok('Untracked ${paths != null ? '${paths.length} file(s)' : 'all files'}');
  }
}

class GitStageLinesTool extends AiTool {
  @override String get name => 'git_stage_lines';
  @override String get description => 'Stage specific lines from a file (partial staging).';
  @override ToolConfirmation get confirmation => ToolConfirmation.warn;
  @override ToolTier get tier => ToolTier.advanced;
  @override Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'file_path': {'type': 'string', 'description': 'Path to the file'},
      'line_indices': {'type': 'array', 'items': {'type': 'integer'}, 'description': 'Line indices to stage (0-based)'},
    },
    'required': ['file_path', 'line_indices'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final path = input['file_path'] as String;
    final lines = (input['line_indices'] as List).cast<int>();
    await GitManager.stageFileLines(path, lines, repoIndex: context?.repoIndex);
    return ok('Staged ${lines.length} line(s) from $path');
  }
}

class GitMoreCommitsTool extends AiTool {
  @override String get name => 'git_log_more';
  @override String get description => 'Get more commit history beyond what git_log returned. Use skip to paginate.';
  @override ToolConfirmation get confirmation => ToolConfirmation.none;
  @override ToolTier get tier => ToolTier.advanced;
  @override Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'skip': {'type': 'integer', 'description': 'Number of commits to skip (use the count from the previous git_log call)'},
    },
    'required': ['skip'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final skip = input['skip'] as int;
    final commits = await GitManager.getMoreRecentCommits(skip, repoIndex: context?.repoIndex);
    return ok(commits.map((c) => {
      'sha': c.reference.length >= 7 ? c.reference.substring(0, 7) : c.reference,
      'message': c.commitMessage,
      'author': c.authorUsername,
      'timestamp': DateTime.fromMillisecondsSinceEpoch(c.timestamp * 1000).toIso8601String(),
      'additions': c.additions,
      'deletions': c.deletions,
      'unpushed': c.unpushed,
      if (c.tags.isNotEmpty) 'tags': c.tags,
    }).toList());
  }
}

class GitRecommendedActionTool extends AiTool {
  @override String get name => 'git_recommended_action';
  @override String get description => 'Get the app\'s recommended sync action for the current repository state (e.g. push, pull, commit, etc).';
  @override ToolConfirmation get confirmation => ToolConfirmation.none;
  @override ToolTier get tier => ToolTier.advanced;
  @override Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}, 'required': []};

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final action = await GitManager.getRecommendedAction(repoIndex: context?.repoIndex);
    return ok({'recommended_action': action});
  }
}

class GitInfoExcludeReadTool extends AiTool {
  @override String get name => 'git_info_exclude_read';
  @override String get description => 'Read the .git/info/exclude file (local-only gitignore, not committed).';
  @override ToolConfirmation get confirmation => ToolConfirmation.none;
  @override ToolTier get tier => ToolTier.advanced;
  @override Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}, 'required': []};

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final content = await GitManager.readGitInfoExclude(repoIndex: context?.repoIndex);
    return ok(content);
  }
}

class GitInfoExcludeWriteTool extends AiTool {
  @override String get name => 'git_info_exclude_write';
  @override String get description => 'Write the .git/info/exclude file (local-only gitignore, not committed).';
  @override ToolConfirmation get confirmation => ToolConfirmation.warn;
  @override ToolTier get tier => ToolTier.advanced;
  @override Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'content': {'type': 'string', 'description': 'Full file content'},
    },
    'required': ['content'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final content = input['content'] as String;
    await GitManager.writeGitInfoExclude(content, repoIndex: context?.repoIndex);
    return ok('Updated .git/info/exclude');
  }
}

class GitHasFiltersTool extends AiTool {
  @override String get name => 'git_has_filters';
  @override String get description => 'Check if git filters (git-crypt, LFS, etc.) are configured in this repository.';
  @override ToolConfirmation get confirmation => ToolConfirmation.none;
  @override ToolTier get tier => ToolTier.advanced;
  @override Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}, 'required': []};

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final hasFilters = await GitManager.hasGitFilters(context?.repoIndex);
    return ok({'has_filters': hasFilters});
  }
}

class GitSubmodulePathsTool extends AiTool {
  @override String get name => 'git_submodule_paths';
  @override String get description => 'List all submodule paths in the repository.';
  @override ToolConfirmation get confirmation => ToolConfirmation.none;
  @override ToolTier get tier => ToolTier.advanced;
  @override Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}, 'required': []};

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final root = _repoPath(context);
    if (root == null) return err('No repository open');
    final paths = await GitManager.getSubmodulePaths(root, repoIndex: context?.repoIndex);
    return ok(paths);
  }
}

List<AiTool> allGitTools() => [
  GitStatusTool(),
  GitLogTool(),
  GitDiffTool(),
  GitCommitShowTool(),
  GitStageTool(),
  GitUnstageTool(),
  GitCommitTool(),
  GitPushTool(),
  GitPullTool(),
  GitBranchListTool(),
  GitBranchCreateTool(),
  GitBranchCheckoutTool(),
  GitBranchDeleteTool(),
  GitDiscardTool(),
  GitAmendCommitTool(),
  GitUndoCommitTool(),
  GitCreateTagTool(),
  GitRevertCommitTool(),
  GitResetToCommitTool(),
  GitCherryPickTool(),
  GitSquashCommitsTool(),
  GitFetchTool(),
  GitBranchRenameTool(),
  GitForcePullTool(),
  GitForcePushTool(),
  GitDownloadAndOverwriteTool(),
  GitUploadAndOverwriteTool(),
  GitPruneCorruptedObjectsTool(),
  GitGetDisableSslTool(),
  GitSetDisableSslTool(),
  GitSetRemoteUrlTool(),
  GitAddRemoteTool(),
  GitDeleteRemoteTool(),
  GitRenameRemoteTool(),
  GitCheckoutCommitTool(),
  GitCreateBranchFromCommitTool(),
  GitUpdateSubmodulesTool(),
  GitAbortMergeTool(),
  GitListRemotesTool(),
  GitUntrackAllTool(),
  GitStageLinesTool(),
  GitMoreCommitsTool(),
  GitRecommendedActionTool(),
  GitInfoExcludeReadTool(),
  GitInfoExcludeWriteTool(),
  GitHasFiltersTool(),
  GitSubmodulePathsTool(),
  GitIgnoreReadTool(),
  GitIgnoreWriteTool(),
  RepoInfoTool(),
];
