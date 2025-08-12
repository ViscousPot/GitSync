// App Name
const String appName = "Git Sync";

// Routes
const String settings_main = "/settings_main";
const String clone_repo_main = "/clone_repo_main";
const String global_settings_main = "/global_settings_main";

// Paths
const String gitIgnorePath = ".gitignore";
const String gitPath = ".git";
const String gitConfigPath = ".git/config";
const String gitIndexPath = ".git/index";
const String gitLockPath = ".git/index.lock";
const String gitFetchHeadPath = ".git/FETCH_HEAD";
const String gitMergeHeadPath = ".git/MERGE_HEAD";
const String gitMergeMsgPath = ".git/MERGE_MSG";
const String gitInfoExcludePath = ".git/info/exclude";

// Bug Notification
const String reportABug = "Report a Bug";
const String reportBug = "<GitSync Error> Tap to send a bug report";

const String applicationError = "Application Error!";
const String operationInProgressError = "Background operation in progress. Please try again later.";
const String networkUnavailable = "Network unavailable!";
const String invalidIndexHeaderError = "Invalid index data! Incorrect header signature detected.";
const String invalidDataInIndex = "invalid data in index - invalid entry";
const String corruptedLooseFetchHead = "corrupted loose reference file: FETCH_HEAD";
const String missingAuthorDetailsError = "Missing repository author details. Please set your name and email in the repository settings.";
const String authMethodMismatchError = "Authentication method mismatch. Use SSH for SSH repositories and HTTPS for HTTP repositories.";
const String outOfMemory = "Application ran out of memory!";
const String invalidRemote = "Invalid remote! Modify this in settings";
const String largeFile = "Singular files larger than 50MB not supported!";
const String cloneFailed = "Failed to clone repository!";
const String directoryNotEmpty = "Folder not empty. Please choose another.";
const String inaccessibleDirectoryMessage = "Inaccessible directory! Please select a different location.";
const String autoRebaseFailedException =
    "Remote is further ahead than local and we could not automatically rebase for you, as it would cause non fast-forward update.";
const String nonExistingException = "Remote ref didn't exist.";
const String rejectedNodeleteException = "Remote ref update was rejected, because remote side doesn't support/allow deleting refs.";
const String rejectedException = "Remote ref update was rejected.";
const String rejectionWithReasonException = "Remote ref update was rejected because %s.";
const String remoteChangedException =
    "Remote ref update was rejected, because old object id on remote repository wasn't the same as defined expected old object.";
const String mergingExceptionMessage = "MERGING";
const String repositoryNotFound = "Repository not found!";

// Sync Dialogs
const String resolvingMerge = "Resolving merge…";

const String conflictStart = "<<<<<<<";
const String conflictSeparator = "=======";
const String conflictEnd = ">>>>>>>";

// Merge Conflict Notification
const String mergeConflictNotificationTitle = "<Merge Conflict> Tap to fix";
const String mergeConflictNotificationBody = "There is an irreconcilable difference between the local and remote changes";

// Settings Page
const String syncMessage = "Last Sync: %s (Mobile)";
const String syncMessageTimeFormat = "yyyy-MM-dd HH:mm";

const String documentationLink = "https://gitsync.viscouspotenti.al/wiki/";
const String privacyPolicyLink = "https://gitsync.viscouspotenti.al/wiki/privacy-policy/";
const String eulaLink = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/";
const String githubDiscussionsLink = "https://github.com/ViscousPot/GitSync/discussions";
const String multiRepoDocsLink = "https://gitsync.viscouspotenti.al/wiki/multi-repo-support";
const String enhancedShcheduledSyncDocsLink =
    "https://gitsync.viscouspotenti.al/wiki/sync-options/background/scheduled#enhanced-scheduled-sync-ios-only";
const String syncOptionsDocsLink = "https://gitsync.viscouspotenti.al/wiki/sync-options";
const String syncOptionsBGDocsLink = "https://gitsync.viscouspotenti.al/wiki/sync-options/background";
const String githubFeatureTemplate = "https://github.com/ViscousPot/GitSync/issues/new?template=FEATURE_REQUEST.yaml";
const String contributeLink = "https://github.com/sponsors/ViscousPot?sponsor=ViscousPot&frequency=one-time&amount=15";
const String githubIssueTemplate =
    "https://www.github.com/ViscousPot/GitSync/issues/new?template=BUG_REPORT.yaml&title=[Bug]:%20(%s)%%20Application%%20Error!&labels=%s,bug&logs=%s";

// Constants
const mergeConflictReference = "merge_conflict";
const appLifecycleStateResumed = "AppLifecycleState.resumed";

const iosFolderAccessDebounceReference = "ios_folder_access";
const mergeConflictDebounceReference = "merge_conflict_scroll";
const selectApplicationSearchReference = "select_application_search";
const scheduledSyncSetDebounceReference = "scheduled_sync_set";
const dismissErrorDebounceReference = "dismiss_error";

const scheduledSyncKey = "scheduled_sync_";
const networkScheduledSyncKey = "network_scheduled_sync_";

final sshPattern = RegExp(r'^(ssh://[^@]+@|git@)[a-zA-Z0-9.-]+([:/])(\S+)/(\S+)(\.git)?$');
final httpsPattern = RegExp(r'^(https?://)[a-zA-Z0-9.-]+([:/])(\S+)/(\S+)(\.git)?$');
const gitSyncIconRes = "gitsync_notif";

const gitSyncNotifyChannelId = "git_sync_notify_channel";
const gitSyncNotifyChannelName = "Git Sync Merge Conflict";

const gitSyncBugChannelId = "git_sync_bug_channel";
const gitSyncBugChannelName = "Git Sync Bug";
