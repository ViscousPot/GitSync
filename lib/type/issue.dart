enum IssueSortOption { newest, oldest, mostCommented, recentlyUpdated }

class Milestone {
  final String id;
  final String title;
  const Milestone({required this.id, required this.title});
}

class GitProject {
  final String id;
  final String title;
  const GitProject({required this.id, required this.title});
}

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
  final List<int> linkedPrNumbers;
  final List<IssueLabel> labels;

  const Issue({
    required this.title,
    required this.number,
    required this.isOpen,
    required this.authorUsername,
    required this.createdAt,
    required this.commentCount,
    this.linkedPrNumbers = const [],
    required this.labels,
  });

  int get linkedPrCount => linkedPrNumbers.length;
}
