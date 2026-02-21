import 'package:GitSync/type/issue.dart';

enum PrState { open, merged, closed }

enum CheckStatus { success, failure, pending, none }

class PullRequest {
  final String title;
  final int number;
  final PrState state;
  final String authorUsername;
  final DateTime createdAt;
  final int commentCount;
  final int linkedIssueCount;
  final CheckStatus checkStatus;
  final List<IssueLabel> labels;

  const PullRequest({
    required this.title,
    required this.number,
    required this.state,
    required this.authorUsername,
    required this.createdAt,
    required this.commentCount,
    this.linkedIssueCount = 0,
    this.checkStatus = CheckStatus.none,
    required this.labels,
  });
}
