class IssueLabel {
  final String name;
  final String? color; // hex without '#', null for GitLab
  const IssueLabel({required this.name, this.color});
}

class Issue {
  final String title;
  final int number;
  final bool isOpen;
  final String authorUsername;
  final DateTime createdAt;
  final int commentCount;
  final int linkedPrCount;
  final List<IssueLabel> labels;

  const Issue({
    required this.title,
    required this.number,
    required this.isOpen,
    required this.authorUsername,
    required this.createdAt,
    required this.commentCount,
    this.linkedPrCount = 0,
    required this.labels,
  });
}
