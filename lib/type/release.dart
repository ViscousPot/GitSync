class ReleaseAsset {
  final String name;
  final String downloadUrl;
  final int? size;
  final int? downloadCount;

  const ReleaseAsset({required this.name, required this.downloadUrl, this.size, this.downloadCount});
}

class Release {
  final String name;
  final String tagName;
  final String description;
  final String authorUsername;
  final DateTime createdAt;
  final String? commitSha;
  final bool isPrerelease;
  final bool isDraft;
  final List<ReleaseAsset> assets;

  const Release({
    required this.name,
    required this.tagName,
    required this.description,
    required this.authorUsername,
    required this.createdAt,
    this.commitSha,
    this.isPrerelease = false,
    this.isDraft = false,
    required this.assets,
  });
}
