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

  String? issuesUrl(String webBaseUrl) => switch (this) {
    GITHUB || GITEA || CODEBERG => '$webBaseUrl/issues',
    GITLAB => '$webBaseUrl/-/issues',
    HTTPS || SSH => null,
  };

  String? issueUrl(String webBaseUrl, int number) => switch (this) {
    GITHUB || GITEA || CODEBERG => '$webBaseUrl/issues/$number',
    GITLAB => '$webBaseUrl/-/issues/$number',
    HTTPS || SSH => null,
  };

  String? pullRequestsUrl(String webBaseUrl) => switch (this) {
    GITHUB || GITEA || CODEBERG => '$webBaseUrl/pulls',
    GITLAB => '$webBaseUrl/-/merge_requests',
    HTTPS || SSH => null,
  };

  String? pullRequestUrl(String webBaseUrl, int number) => switch (this) {
    GITHUB => '$webBaseUrl/pull/$number',
    GITEA || CODEBERG => '$webBaseUrl/pulls/$number',
    GITLAB => '$webBaseUrl/-/merge_requests/$number',
    HTTPS || SSH => null,
  };

  String? releasesUrl(String webBaseUrl) => switch (this) {
    GITHUB || GITEA || CODEBERG => '$webBaseUrl/releases',
    GITLAB => '$webBaseUrl/-/releases',
    HTTPS || SSH => null,
  };

  String? tagsUrl(String webBaseUrl) => switch (this) {
    GITHUB || GITEA || CODEBERG => '$webBaseUrl/tags',
    GITLAB => '$webBaseUrl/-/tags',
    HTTPS || SSH => null,
  };

  String? actionsUrl(String webBaseUrl) => switch (this) {
    GITHUB => '$webBaseUrl/actions',
    GITEA || CODEBERG => '$webBaseUrl/actions',
    GITLAB => '$webBaseUrl/-/pipelines',
    HTTPS || SSH => null,
  };
}
