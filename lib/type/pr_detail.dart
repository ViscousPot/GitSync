import 'package:GitSync/type/issue.dart';
import 'package:GitSync/type/issue_detail.dart';
import 'package:GitSync/type/pull_request.dart';

enum PrTimelineItemType { comment, commit, crossReference, forcePush }

class PrTimelineItem {
  final PrTimelineItemType type;
  final IssueComment? comment;
  final PrCommit? commit;
  final PrCrossReference? crossReference;
  final PrForcePush? forcePush;
  final DateTime createdAt;

  const PrTimelineItem({required this.type, this.comment, this.commit, this.crossReference, this.forcePush, required this.createdAt});
}

class PrCrossReference {
  final String sourceType;
  final int sourceNumber;
  final String sourceTitle;
  final bool isCrossRepository;
  final String? sourceRepoName;
  final String actorUsername;
  final DateTime createdAt;

  const PrCrossReference({
    required this.sourceType,
    required this.sourceNumber,
    required this.sourceTitle,
    required this.isCrossRepository,
    this.sourceRepoName,
    required this.actorUsername,
    required this.createdAt,
  });
}

class PrForcePush {
  final String beforeSha;
  final String afterSha;
  final String actorUsername;
  final DateTime createdAt;

  const PrForcePush({required this.beforeSha, required this.afterSha, required this.actorUsername, required this.createdAt});
}

class PrCommit {
  final String sha;
  final String shortSha;
  final String message;
  final String authorUsername;
  final DateTime createdAt;

  const PrCommit({required this.sha, required this.shortSha, required this.message, required this.authorUsername, required this.createdAt});
}

enum CheckRunStatus { queued, inProgress, completed }

class PrCheckRun {
  final String name;
  final CheckRunStatus status;
  final String? conclusion;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const PrCheckRun({required this.name, required this.status, this.conclusion, this.startedAt, this.completedAt});
}

class PrChangedFile {
  final String filename;
  final int additions;
  final int deletions;
  final String status;
  final String? patch;

  const PrChangedFile({required this.filename, required this.additions, required this.deletions, required this.status, this.patch});
}

enum PrReviewState { approved, changesRequested, commented, dismissed, pending }

class PrReview {
  final String authorUsername;
  final PrReviewState state;
  final DateTime createdAt;

  const PrReview({required this.authorUsername, required this.state, required this.createdAt});
}

class PrDetail {
  final String id;
  final String title;
  final String body;
  final String authorUsername;
  final String baseBranch;
  final String headBranch;
  final String headRepoOwner;
  final int number;
  final int additions;
  final int deletions;
  final int changedFileCount;
  final PrState state;
  final DateTime createdAt;
  final List<IssueLabel> labels;
  final List<IssueReaction> reactions;
  final List<PrTimelineItem> timelineItems;
  final List<PrCommit> commits;
  final List<PrCheckRun> checkRuns;
  final List<PrChangedFile> changedFiles;
  final List<PrReview> reviews;
  final CheckStatus overallCheckStatus;
  final ViewerPermission viewerPermission;

  const PrDetail({
    required this.id,
    required this.title,
    required this.body,
    required this.authorUsername,
    required this.baseBranch,
    required this.headBranch,
    required this.headRepoOwner,
    required this.number,
    required this.additions,
    required this.deletions,
    required this.changedFileCount,
    required this.state,
    required this.createdAt,
    this.labels = const [],
    this.reactions = const [],
    this.timelineItems = const [],
    this.commits = const [],
    this.checkRuns = const [],
    this.changedFiles = const [],
    this.reviews = const [],
    this.overallCheckStatus = CheckStatus.none,
    this.viewerPermission = ViewerPermission.read,
  });

  bool get canComment => viewerPermission != ViewerPermission.none;

  PrDetail copyWith({
    String? id,
    String? title,
    String? body,
    String? authorUsername,
    String? baseBranch,
    String? headBranch,
    String? headRepoOwner,
    int? number,
    int? additions,
    int? deletions,
    int? changedFileCount,
    PrState? state,
    DateTime? createdAt,
    List<IssueLabel>? labels,
    List<IssueReaction>? reactions,
    List<PrTimelineItem>? timelineItems,
    List<PrCommit>? commits,
    List<PrCheckRun>? checkRuns,
    List<PrChangedFile>? changedFiles,
    List<PrReview>? reviews,
    CheckStatus? overallCheckStatus,
    ViewerPermission? viewerPermission,
  }) {
    return PrDetail(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      authorUsername: authorUsername ?? this.authorUsername,
      baseBranch: baseBranch ?? this.baseBranch,
      headBranch: headBranch ?? this.headBranch,
      headRepoOwner: headRepoOwner ?? this.headRepoOwner,
      number: number ?? this.number,
      additions: additions ?? this.additions,
      deletions: deletions ?? this.deletions,
      changedFileCount: changedFileCount ?? this.changedFileCount,
      state: state ?? this.state,
      createdAt: createdAt ?? this.createdAt,
      labels: labels ?? this.labels,
      reactions: reactions ?? this.reactions,
      timelineItems: timelineItems ?? this.timelineItems,
      commits: commits ?? this.commits,
      checkRuns: checkRuns ?? this.checkRuns,
      changedFiles: changedFiles ?? this.changedFiles,
      reviews: reviews ?? this.reviews,
      overallCheckStatus: overallCheckStatus ?? this.overallCheckStatus,
      viewerPermission: viewerPermission ?? this.viewerPermission,
    );
  }
}
