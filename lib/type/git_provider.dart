enum GitProvider {
  CODEBERG,
  GITHUB,
  GITEA,
  GITLAB,
  HTTPS,
  SSH;

  bool get isOAuthProvider => this == GITHUB || this == GITEA || this == CODEBERG || this == GITLAB;

  String? commitUrl(String webBaseUrl, String sha) => switch (this) {
    GITHUB || GITEA || CODEBERG => '$webBaseUrl/commit/$sha',
    GITLAB => '$webBaseUrl/-/commit/$sha',
    HTTPS || SSH => null,
  };
}
