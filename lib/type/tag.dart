class Tag {
  final String name;
  final String sha;
  final DateTime createdAt;
  final String? message; // annotation message, null for lightweight tags

  const Tag({required this.name, required this.sha, required this.createdAt, this.message});
}
