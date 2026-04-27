import 'package:GitSync/type/issue.dart';

class IssueReaction {
  final String content;
  final int count;
  final bool viewerHasReacted;
  final int? awardId; // GitLab award_emoji ID for removal

  const IssueReaction({required this.content, required this.count, this.viewerHasReacted = false, this.awardId});
}

class IssueComment {
  final String id;
  final String authorUsername;
  final String body;
  final DateTime createdAt;
  final List<IssueReaction> reactions;

  const IssueComment({required this.id, required this.authorUsername, required this.body, required this.createdAt, this.reactions = const []});
}

enum ViewerPermission { admin, maintain, write, triage, read, none }

class IssueDetail {
  final String id;
  final String title;
  final int number;
  final bool isOpen;
  final String authorUsername;
  final DateTime createdAt;
  final String body;
  final List<IssueLabel> labels;
  final List<IssueReaction> reactions;
  final List<IssueComment> comments;
  final ViewerPermission viewerPermission;

  const IssueDetail({
    required this.id,
    required this.title,
    required this.number,
    required this.isOpen,
    required this.authorUsername,
    required this.createdAt,
    required this.body,
    this.labels = const [],
    this.reactions = const [],
    this.comments = const [],
    this.viewerPermission = ViewerPermission.read,
  });

  bool get canComment => viewerPermission != ViewerPermission.none;

  bool get canWrite =>
      viewerPermission == ViewerPermission.admin ||
      viewerPermission == ViewerPermission.maintain ||
      viewerPermission == ViewerPermission.write ||
      viewerPermission == ViewerPermission.triage;

  IssueDetail copyWith({
    String? id,
    String? title,
    int? number,
    bool? isOpen,
    String? authorUsername,
    DateTime? createdAt,
    String? body,
    List<IssueLabel>? labels,
    List<IssueReaction>? reactions,
    List<IssueComment>? comments,
    ViewerPermission? viewerPermission,
  }) {
    return IssueDetail(
      id: id ?? this.id,
      title: title ?? this.title,
      number: number ?? this.number,
      isOpen: isOpen ?? this.isOpen,
      authorUsername: authorUsername ?? this.authorUsername,
      createdAt: createdAt ?? this.createdAt,
      body: body ?? this.body,
      labels: labels ?? this.labels,
      reactions: reactions ?? this.reactions,
      comments: comments ?? this.comments,
      viewerPermission: viewerPermission ?? this.viewerPermission,
    );
  }
}
