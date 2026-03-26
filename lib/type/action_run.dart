enum ActionRunStatus { success, failure, pending, cancelled, skipped, inProgress }

class ActionRun {
  final String name;
  final int number;
  final ActionRunStatus status;
  final String event;
  final int? prNumber;
  final String authorUsername;
  final DateTime createdAt;
  final Duration? duration;
  final String? branch;

  const ActionRun({
    required this.name,
    required this.number,
    required this.status,
    required this.event,
    this.prNumber,
    required this.authorUsername,
    required this.createdAt,
    this.duration,
    this.branch,
  });
}
