// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get dismiss => '閉じる';

  @override
  String get skip => 'スキップ';

  @override
  String get done => '完了';

  @override
  String get confirm => '確認';

  @override
  String get ok => 'OK';

  @override
  String get select => '選択';

  @override
  String get cancel => 'キャンセル';

  @override
  String get learnMore => '詳細はこちら';

  @override
  String get loadingElipsis => '読み込み中…';

  @override
  String get previous => '前へ';

  @override
  String get next => '次へ';

  @override
  String get finish => '終了';

  @override
  String get rename => '名前変更';

  @override
  String get renameDescription => 'Rename the selected file or folder';

  @override
  String get selectAllDescription => 'Select all visible files and folders';

  @override
  String get deselectAllDescription => 'Deselect all selected files and folders';

  @override
  String get add => '追加';

  @override
  String get delete => '削除';

  @override
  String get optionalLabel => '(任意)';

  @override
  String get ios => 'iOS';

  @override
  String get android => 'Android';

  @override
  String get syncStarting => '変更を検出中…';

  @override
  String get syncStartPull => '変更を同期中…';

  @override
  String get syncStartPush => 'ローカルの変更を同期中…';

  @override
  String get syncNotRequired => '同期は不要です！';

  @override
  String get syncComplete => 'リポジトリの同期が完了しました！';

  @override
  String get syncInProgress => '同期が進行中です';

  @override
  String get syncScheduled => '同期がスケジュールされました';

  @override
  String get detectingChanges => '変更を検出中…';

  @override
  String get thisActionCannotBeUndone => 'この操作は取り消せません。';

  @override
  String get cloneProgressLabel => 'クローン進行状況';

  @override
  String get forcePushProgressLabel => '強制プッシュ進行状況';

  @override
  String get forcePullProgressLabel => '強制プル進行状況';

  @override
  String get moreSyncOptionsLabel => 'その他の同期オプション';

  @override
  String get repositorySettingsLabel => 'リポジトリ設定';

  @override
  String get addBranchLabel => 'ブランチを追加';

  @override
  String get deselectDirLabel => 'ディレクトリの選択を解除';

  @override
  String get selectDirLabel => 'ディレクトリを選択';

  @override
  String get syncMessagesLabel => '同期メッセージの有効化/無効化';

  @override
  String get backLabel => '戻る';

  @override
  String get authDropdownLabel => '認証ドロップダウン';

  @override
  String get premiumDialogTitle => 'プレミアムをアンロック';

  @override
  String get restorePurchase => '購入を復元';

  @override
  String get verifyGhSponsorTitle => 'GitHubスポンサーシップを確認';

  @override
  String get verifyGhSponsorMsg => 'GitHubスポンサーの方は、プレミアム機能に無料でアクセスできます。スポンサーのステータスを確認するため、GitHubで認証を行ってください。';

  @override
  String get verifyGhSponsorNote => '注意：新しいスポンサーシップがアプリに反映されるまで、最大1日かかる場合があります。';

  @override
  String get premiumStoreOnlyBanner => 'Store version only — Get it on the App Store or Play Store';

  @override
  String get premiumMultiRepoTitle => 'Manage Multiple Repos';

  @override
  String get premiumMultiRepoSubtitle => 'One app. All your repositories.\nEach with its own credentials and settings.';

  @override
  String get premiumUnlimitedContainers => 'Unlimited containers';

  @override
  String get premiumIndependentAuth => 'Independent auth per repo';

  @override
  String get premiumAutoAddSubmodules => 'Auto-add submodules';

  @override
  String get premiumEnhancedSyncSubtitle => 'Automated background sync on iOS.\nAs low as once per minute.';

  @override
  String get premiumSyncPerMinute => 'Sync as often as every minute';

  @override
  String get premiumServerTriggered => 'Server push notifications';

  @override
  String get premiumWorksAppClosed => 'Works even when app is closed';

  @override
  String get premiumReliableDelivery => 'Reliable, on-schedule delivery';

  @override
  String get premiumGitLfsTitle => 'Git LFS';

  @override
  String get premiumGitLfsSubtitle => 'Full support for Git Large File Storage.\nSync repos with large binary files effortlessly.';

  @override
  String get premiumFullLfsSupport => 'Full Git LFS support';

  @override
  String get premiumTrackLargeFiles => 'Track large binary files';

  @override
  String get premiumAutoLfsPullPush => 'Automatic LFS pull/push';

  @override
  String get premiumGitFiltersTitle => 'Git Filters';

  @override
  String get premiumGitFiltersSubtitle => 'Support for git filters including git-lfs,\ngit-crypt, and more coming soon.';

  @override
  String get premiumGitLfsFilter => 'git-lfs filter';

  @override
  String get premiumGitCryptFilter => 'git-crypt filter';

  @override
  String get premiumMoreFiltersSoon => 'More filters coming soon';

  @override
  String get premiumGitHooksTitle => 'Git Hooks';

  @override
  String get premiumGitHooksSubtitle => 'Run pre-commit hooks automatically\nbefore every sync.';

  @override
  String get premiumHookTrailingWhitespace => 'trailing-whitespace';

  @override
  String get premiumHookEndOfFileFixer => 'end-of-file-fixer';

  @override
  String get premiumHookCheckYamlJson => 'check-yaml / check-json';

  @override
  String get premiumHookMixedLineEnding => 'mixed-line-ending';

  @override
  String get premiumHookDetectPrivateKey => 'detect-private-key';

  @override
  String get switchToClientMode => 'クライアントモードに切り替え…';

  @override
  String get switchToSyncMode => '同期モードに切り替え…';

  @override
  String get clientMode => 'クライアントモード';

  @override
  String get clientModeDescription => '拡張Git UI\n(上級者向け)';

  @override
  String get syncMode => '同期モード';

  @override
  String get syncModeDescription => '自動同期\n(初心者向け)';

  @override
  String get syncNow => '変更を同期';

  @override
  String get syncAllChanges => 'すべての変更を同期';

  @override
  String get stageAndCommit => 'ステージングとコミット';

  @override
  String get downloadChanges => '変更をダウンロード';

  @override
  String get uploadChanges => '変更をアップロード';

  @override
  String get downloadAndOverwrite => 'ダウンロード + 上書き';

  @override
  String get uploadAndOverwrite => 'アップロード + 上書き';

  @override
  String get fetchRemote => '%s をフェッチ';

  @override
  String get pullChanges => 'プル';

  @override
  String get pushChanges => 'プッシュ';

  @override
  String get updateSubmodules => 'サブモジュールを更新';

  @override
  String get forcePush => '強制プッシュ';

  @override
  String get forcePushing => '強制プッシュ中…';

  @override
  String get confirmForcePush => '強制プッシュの確認';

  @override
  String get confirmForcePushMsg => '本当にこれらの変更を強制プッシュしますか？実行中のマージコンフリクトはすべて中止されます。';

  @override
  String get forcePull => '強制プル';

  @override
  String get forcePulling => '強制プル中…';

  @override
  String get confirmForcePull => '強制プルの確認';

  @override
  String get confirmForcePullMsg => '本当にこれらの変更を強制プルしますか？実行中のマージコンフリクトはすべて無視されます。';

  @override
  String get localHistoryOverwriteWarning => 'この操作はローカルの履歴を上書きし、元に戻すことはできません。';

  @override
  String get forcePushPullMessage => 'プロセスが完了するまで、アプリを閉じたり終了したりしないでください。';

  @override
  String get manualSync => '手動同期';

  @override
  String get manualSyncMsg => '同期したいファイルを選択してください';

  @override
  String get commit => 'コミット';

  @override
  String get unstage => 'ステージ解除';

  @override
  String get stage => 'ステージング';

  @override
  String get selectAll => 'すべて選択';

  @override
  String get deselectAll => '選択解除';

  @override
  String get noUncommittedChanges => '未コミットの変更はありません';

  @override
  String get discardChanges => '変更を破棄';

  @override
  String get discardChangesTitle => '変更を破棄しますか？';

  @override
  String get discardChangesMsg => '\"%s\" へのすべての変更を破棄してもよろしいですか？';

  @override
  String get mergeConflictItemMessage => 'マージコンフリクトが発生しています！タップして解決してください';

  @override
  String get mergeConflict => 'マージコンフリクト';

  @override
  String get mergeDialogMessage => 'エディタを使用してマージコンフリクトを解決してください';

  @override
  String get commitMessage => 'コミットメッセージ';

  @override
  String get abortMerge => 'マージを中止';

  @override
  String get keepChanges => '変更を保持';

  @override
  String get local => 'ローカル';

  @override
  String get both => '両方';

  @override
  String get remote => 'リモート';

  @override
  String get merge => 'マージ';

  @override
  String get merging => 'マージ中…';

  @override
  String get clearSelection => 'Clear Selection';

  @override
  String get keepSelected => 'Keep Selected';

  @override
  String get resolveAll => 'Resolve All';

  @override
  String get allLocal => 'All Local';

  @override
  String get allRemote => 'All Remote';

  @override
  String get iosClearDataTitle => '新規インストールですか？';

  @override
  String get iosClearDataMsg =>
      '再インストールの可能性がありますが、誤検知の場合もあります。iOSではアプリを削除して再インストールしてもキーチェーンが消去されないため、一部のデータが安全に保存されたままになっている場合があります。\n\n新規インストールでない場合、またはリセットしたくない場合は、このステップをスキップして構いません。';

  @override
  String get clearDataConfirmTitle => 'アプリデータのリセットを確認';

  @override
  String get clearDataConfirmMsg => 'これにより、キーチェーンのエントリを含むすべてのアプリデータが完全に削除されます。続行してもよろしいですか？';

  @override
  String get iosClearDataAction => 'すべてのデータを消去';

  @override
  String get legacyAppUserDialogTitle => '新バージョンへようこそ！';

  @override
  String get legacyAppUserDialogMessagePart1 => 'パフォーマンスの向上と将来の成長のために、アプリをゼロから再構築しました。';

  @override
  String get legacyAppUserDialogMessagePart2 =>
      '残念ながら、古い設定を引き継ぐことができないため、再度設定を行う必要があります。\n\nお気に入りの機能はすべて残っています。マルチリポジトリ対応は、今後の開発を支援するための少額の一回限りのアップグレードの一部となりました。';

  @override
  String get legacyAppUserDialogMessagePart3 => '引き続きご利用いただきありがとうございます :)';

  @override
  String get setUp => 'セットアップ';

  @override
  String get welcomeSetupPrompt => 'Would you like to go through a quick setup to get started?';

  @override
  String get welcomePositive => '開始する';

  @override
  String get welcomeNeutral => 'スキップ';

  @override
  String get welcomeNegative => '使い方は知っている';

  @override
  String get notificationDialogTitle => '通知を有効にする';

  @override
  String get allFilesAccessDialogTitle => '「全ファイルへのアクセス」を有効にする';

  @override
  String get authorDetailsPromptTitle => '作成者情報が必要です';

  @override
  String get authorDetailsPromptMessage => '作成者名またはメールアドレスが設定されていません。同期する前にリポジトリ設定で更新してください。';

  @override
  String get authorDetailsShowcasePrompt => '作成者情報を入力してください';

  @override
  String get goToSettings => '設定へ移動';

  @override
  String get onboardingSyncSettingsTitle => 'Sync Settings';

  @override
  String get onboardingSyncSettingsSubtitle => 'Choose how to keep your repos in sync.';

  @override
  String get onboardingAppSyncFeatureOpen => 'Trigger sync on app open';

  @override
  String get onboardingAppSyncFeatureClose => 'Trigger sync on app close';

  @override
  String get onboardingAppSyncFeatureSelect => 'Select which apps to monitor';

  @override
  String get onboardingScheduledSyncFeatureFreq => 'Set your preferred sync frequency';

  @override
  String get onboardingScheduledSyncFeatureCustom => 'Choose custom intervals on Android';

  @override
  String get onboardingScheduledSyncFeatureBg => 'Works in the background';

  @override
  String get onboardingQuickSyncFeatureTile => 'Sync via Quick Settings tile';

  @override
  String get onboardingQuickSyncFeatureShortcut => 'Sync via app shortcuts';

  @override
  String get onboardingQuickSyncFeatureWidget => 'Sync via home screen widget';

  @override
  String get onboardingOtherSyncFeatureAndroid => 'Android intents';

  @override
  String get onboardingOtherSyncFeatureIos => 'iOS intents';

  @override
  String get onboardingOtherSyncDescription => 'Explore additional sync methods for your platform';

  @override
  String get onboardingTapToConfigure => 'Tap to configure';

  @override
  String get showcaseGlobalSettingsTitle => 'Global Settings';

  @override
  String get showcaseGlobalSettingsSubtitle => 'Your app-wide preferences and tools.';

  @override
  String get showcaseGlobalSettingsFeatureTheme => 'Adjust theme, language, and display options';

  @override
  String get showcaseGlobalSettingsFeatureBackup => 'Back up or restore your configuration';

  @override
  String get showcaseGlobalSettingsFeatureSetup => 'Restart the guided setup or UI tour';

  @override
  String get showcaseSyncProgressTitle => 'Sync Status';

  @override
  String get showcaseSyncProgressSubtitle => 'See what\'s happening at a glance.';

  @override
  String get showcaseSyncProgressFeatureWatch => 'Watch active sync operations in real time';

  @override
  String get showcaseSyncProgressFeatureConfirm => 'Confirms when a sync completes successfully';

  @override
  String get showcaseSyncProgressFeatureErrors => 'Tap to view errors or open the log viewer';

  @override
  String get showcaseAddMoreTitle => 'Your Containers';

  @override
  String get showcaseAddMoreSubtitle => 'Manage multiple repositories in one place.';

  @override
  String get showcaseAddMoreFeatureSwitch => 'Switch between repo containers instantly';

  @override
  String get showcaseAddMoreFeatureManage => 'Rename or delete containers as needed';

  @override
  String get showcaseAddMoreFeaturePremium => 'Add more containers with Premium';

  @override
  String get showcaseControlTitle => 'Sync Controls';

  @override
  String get showcaseControlSubtitle => 'Your hands-on sync and commit tools.';

  @override
  String get showcaseControlFeatureSync => 'Trigger a manual sync with one tap';

  @override
  String get showcaseControlFeatureHistory => 'View your recent commit history';

  @override
  String get showcaseControlFeatureConflicts => 'Resolve merge conflicts when they arise';

  @override
  String get showcaseControlFeatureMore => 'Access force push, force pull, and more';

  @override
  String get showcaseAutoSyncTitle => 'Auto Sync';

  @override
  String get showcaseAutoSyncSubtitle => 'Keep your repos in sync automatically.';

  @override
  String get showcaseAutoSyncFeatureApp => 'Sync when selected apps open or close';

  @override
  String get showcaseAutoSyncFeatureSchedule => 'Schedule periodic background syncs';

  @override
  String get showcaseAutoSyncFeatureQuick => 'Sync via quick tiles, shortcuts, or widgets';

  @override
  String get showcaseAutoSyncFeaturePremium => 'Unlock enhanced sync rates with Premium';

  @override
  String get showcaseSetupGuideTitle => 'Setup & Guide';

  @override
  String get showcaseSetupGuideSubtitle => 'Revisit the walkthrough anytime.';

  @override
  String get showcaseSetupGuideFeatureSetup => 'Re-run the guided setup from scratch';

  @override
  String get showcaseSetupGuideFeatureTour => 'Take a quick tour of the UI highlights';

  @override
  String get showcaseRepoTitle => 'Your Repository';

  @override
  String get showcaseRepoSubtitle => 'Your command center for managing this repository.';

  @override
  String get showcaseRepoFeatureAuth => 'Authenticate with your git provider';

  @override
  String get showcaseRepoFeatureDir => 'Switch or select your local directory';

  @override
  String get showcaseRepoFeatureBrowse => 'Browse and edit files directly';

  @override
  String get showcaseRepoFeatureRemote => 'View or change the remote URL';

  @override
  String get currentBranch => '現在のブランチ';

  @override
  String get detachedHead => 'Detached Head';

  @override
  String get commitsNotFound => 'コミットが見つかりません…';

  @override
  String get repoNotFound => 'リポジトリが見つかりません…';

  @override
  String get committed => 'コミット済み';

  @override
  String get additions => '%s ++';

  @override
  String get deletions => '%s --';

  @override
  String get modifyRemoteUrl => 'リモートURLを変更';

  @override
  String get modify => '変更';

  @override
  String get remoteUrl => 'リモートURL';

  @override
  String get setRemoteUrl => 'リモートURLを設定';

  @override
  String get launchInBrowser => 'ブラウザで開く';

  @override
  String get auth => '認証';

  @override
  String get openFileExplorer => '閲覧と編集';

  @override
  String get syncSettings => '同期設定';

  @override
  String get enableApplicationObserver => 'App Sync設定';

  @override
  String get appSyncDescription => '選択したアプリが開かれた、または閉じられた時に自動同期します';

  @override
  String get accessibilityServiceDisclosureTitle => 'ユーザー補助サービスの開示';

  @override
  String get accessibilityServiceDisclosureMessage =>
      'ユーザー体験を向上させるため、GitSyncはAndroidのユーザー補助サービスを使用してアプリの開閉を検出します。\n\nこれにより、データを保存または共有することなく、カスタマイズされた機能を提供できます。\n\n次の画面でGitSyncを有効にしてください';

  @override
  String get search => '検索';

  @override
  String get searchEllipsis => '検索…';

  @override
  String get applicationNotSet => 'アプリを選択';

  @override
  String get selectApplication => 'アプリを選択してください';

  @override
  String get multipleApplicationSelected => '選択済み (%s)';

  @override
  String get saveApplication => '保存';

  @override
  String get syncOnAppClosed => 'アプリが閉じられた時に同期';

  @override
  String get syncOnAppOpened => 'アプリが開かれた時に同期';

  @override
  String get scheduledSyncSettings => 'スケジュール同期設定';

  @override
  String get scheduledSyncDescription => 'バックグラウンドで定期的に自動同期します';

  @override
  String get sync => '同期';

  @override
  String get iosDefaultSyncRate => 'iOSが許可した時';

  @override
  String get scheduledSync => 'Scheduled Sync';

  @override
  String get custom => 'Custom';

  @override
  String get interval15min => '15 min';

  @override
  String get interval30min => '30 min';

  @override
  String get interval1hour => '1 hour';

  @override
  String get interval6hours => '6 hours';

  @override
  String get interval12hours => '12 hours';

  @override
  String get interval1day => '1 day';

  @override
  String get interval1week => '1 week';

  @override
  String get minutes => 'minute(s)';

  @override
  String get hours => 'hour(s)';

  @override
  String get days => 'day(s)';

  @override
  String get weeks => 'week(s)';

  @override
  String get enhancedScheduledSync => '拡張スケジュール同期';

  @override
  String get quickSyncSettings => 'クイック同期設定';

  @override
  String get quickSyncDescription => 'カスタマイズ可能なクイックタイル、ショートカット、またはウィジェットを使用して同期します';

  @override
  String get otherSyncSettings => 'その他の同期設定';

  @override
  String get useForTileSync => '同期タイルに使用';

  @override
  String get useForTileManualSync => '手動同期タイルに使用';

  @override
  String get useForShortcutSync => '同期ショートカットに使用';

  @override
  String get useForShortcutManualSync => '手動同期ショートカットに使用';

  @override
  String get useForWidgetSync => '同期ウィジェットに使用';

  @override
  String get useForWidgetManualSync => '手動同期ウィジェットに使用';

  @override
  String get selectYourGitProviderAndAuthenticate => 'Gitプロバイダーを選択して認証してください';

  @override
  String get oauthProviders => 'OAuthプロバイダー';

  @override
  String get gitProtocols => 'Gitプロトコル';

  @override
  String get oauthNoAffiliation => 'サードパーティによる認証。提携や推奨を意味するものではありません。';

  @override
  String get replacesExistingAuth => '既存のコンテナ認証を\n置き換えます';

  @override
  String get oauth => 'OAuth';

  @override
  String get copyFromContainer => 'コンテナからコピー';

  @override
  String get or => 'または';

  @override
  String get enterPAT => '個人アクセストークン（PAT）を入力';

  @override
  String get usePAT => 'PATを使用';

  @override
  String get oauthAllRepos => 'OAuth (全リポジトリ)';

  @override
  String get oauthScoped => 'OAuth (スコープ限定)';

  @override
  String get ensureTokenScope => 'フル機能を利用するために、トークンに \"repo\" スコープが含まれていることを確認してください。';

  @override
  String get user => 'ユーザー';

  @override
  String get exampleUser => 'JohnSmith12';

  @override
  String get token => 'トークン';

  @override
  String get exampleToken => 'ghp_1234abcd5678efgh';

  @override
  String get login => 'ログイン';

  @override
  String get pubKey => '公開鍵';

  @override
  String get privKey => '秘密鍵';

  @override
  String get passphrase => 'パスフェーズ';

  @override
  String get privateKey => '秘密鍵';

  @override
  String get sshPubKeyExample => 'ssh-ed25519 AABBCCDDEEFF112233445566';

  @override
  String get sshPrivKeyExample => '-----BEGIN OPENSSH PRIVATE KEY----- AABBCCDDEEFF112233445566';

  @override
  String get generateKeys => '鍵を生成';

  @override
  String get confirmKeySaved => '公開鍵の保存を確認';

  @override
  String get copiedText => 'テキストをコピーしました！';

  @override
  String get confirmPrivKeyCopy => '秘密鍵のコピーを確認';

  @override
  String get confirmPrivKeyCopyMsg => '秘密鍵をクリップボードにコピーしてもよろしいですか？\n\nこの鍵にアクセスできる人は誰でもあなたのアカウントを操作できます。安全な場所にのみ貼り付け、その後クリップボードを消去してください。';

  @override
  String get understood => '了解しました';

  @override
  String get importPrivateKey => '秘密鍵をインポート';

  @override
  String get importPrivateKeyMsg => '既存のアカウントを使用するには、以下に秘密鍵を貼り付けてください。\n\nこの鍵にアクセスできる人は誰でもあなたのアカウントを操作できるため、安全な環境で貼り付けていることを確認してください。';

  @override
  String get importKey => 'インポート';

  @override
  String get cloneRepo => 'リモートリポジトリをクローン';

  @override
  String get clone => 'クローン';

  @override
  String get chooseHowToClone => 'クローン方法を選択してください：';

  @override
  String get directCloningMsg => '直接クローン：選択したフォルダ内にリポジトリをクローンします';

  @override
  String get nestedCloningMsg => 'ネストされたクローン：選択したフォルダ内にリポジトリ名の新しいフォルダを作成します';

  @override
  String get directClone => '直接クローン';

  @override
  String get nestedClone => 'ネストされたクローン';

  @override
  String get gitRepoUrlHint => 'https://git.abc/xyz.git';

  @override
  String get invalidRepositoryUrlTitle => '無効なリポジトリURLです！';

  @override
  String get invalidRepositoryUrlMessage => '無効なリポジトリURLです！';

  @override
  String get cloneAnyway => '強制的にクローン';

  @override
  String get iHaveALocalRepository => 'ローカルリポジトリがある場合';

  @override
  String get cloningRepository => 'リポジトリをクローン中…';

  @override
  String get cloneMessagePart1 => 'この画面を閉じないでください';

  @override
  String get cloneMessagePart2 => 'リポジトリのサイズによっては時間がかかる場合があります\n';

  @override
  String get selectCloneDirectory => 'クローン先のフォルダを選択';

  @override
  String get confirmCloneOverwriteTitle => 'フォルダが空ではありません';

  @override
  String get confirmCloneOverwriteMsg => '選択したフォルダには既にファイルが含まれています。クローンを実行すると内容が上書きされます。';

  @override
  String get confirmCloneOverwriteWarning => 'この操作は取り消せません。';

  @override
  String get confirmCloneOverwriteAction => '上書き';

  @override
  String get repoSearchLimits => 'リポジトリ検索の制限';

  @override
  String get repoSearchLimitsDescription =>
      'リポジトリ検索はAPIから返される最初の100件のリポジトリのみを調査するため、目的のリポジトリが表示されない場合があります。\n\n目的のリポジトリが検索結果に表示されない場合は、HTTPSまたはSSHのURLを使用して直接クローンしてください。';

  @override
  String get repositorySettings => 'リポジトリ設定';

  @override
  String get settings => '設定';

  @override
  String get signedCommitsLabel => '署名付きコミット';

  @override
  String get signedCommitsDescription => '身元を確認するためにコミットに署名します';

  @override
  String get importCommitKey => '鍵をインポート';

  @override
  String get commitKeyImported => '鍵をインポートしました';

  @override
  String get useSshKey => 'コミット署名に認証キーを使用';

  @override
  String get syncMessageLabel => '同期メッセージ';

  @override
  String get syncMessageDescription => '日付と時刻には %s を使用';

  @override
  String get syncMessageTimeFormatLabel => '同期メッセージの日時形式';

  @override
  String get syncMessageTimeFormatDescription => '標準的な日時フォーマット構文を使用します';

  @override
  String get remoteLabel => 'デフォルトのリモート';

  @override
  String get defaultRemote => 'origin';

  @override
  String get authorNameLabel => '作成者名';

  @override
  String get authorNameDescription => 'used to identify you in commit history';

  @override
  String get authorName => 'JohnSmith12';

  @override
  String get authorEmailLabel => '作成者のメールアドレス';

  @override
  String get authorEmailDescription => 'attached to your commits for attribution';

  @override
  String get authorEmail => 'john12@smith.com';

  @override
  String get gitIgnore => '.gitignore';

  @override
  String get gitIgnoreDescription => 'すべてのデバイスで無視するファイルやフォルダのリスト';

  @override
  String get gitIgnoreHint => '.trash/\n./…';

  @override
  String get gitInfoExclude => '.git/info/exclude';

  @override
  String get gitInfoExcludeDescription => 'このデバイスでのみ無視するファイルやフォルダのリスト';

  @override
  String get gitInfoExcludeHint => '.trash/\n./…';

  @override
  String get disableSsl => 'SSLを無効化';

  @override
  String get disableSslDescription => 'HTTPリポジトリのセキュア接続を無効化';

  @override
  String get disableSslPromptTitle => 'SSLを無効にしますか？';

  @override
  String get disableSslPromptMsg => 'クローンしたアドレスは \"http\" で始まっており、安全ではありません。SSLを無効にするとURLと一致しますが、セキュリティは低下します。';

  @override
  String get optimisedSync => '最適化された同期';

  @override
  String get optimisedSyncDescription => '全体の同期操作をインテリジェントに削減します';

  @override
  String get proceedAnyway => '続行しますか？';

  @override
  String get moreOptions => 'その他のオプション';

  @override
  String get untrackAll => 'すべての追跡を解除';

  @override
  String get globalSettings => 'グローバル設定';

  @override
  String get darkMode => 'ダーク\nモード';

  @override
  String get lightMode => 'ライト\nモード';

  @override
  String get system => 'システム';

  @override
  String get language => '言語';

  @override
  String get browseEditDir => '閲覧・編集ディレクトリ';

  @override
  String get enableLineWrap => 'エディタの折り返しを有効にする';

  @override
  String get excludeFromRecents => '最近使ったアプリから除外';

  @override
  String get backupRestoreTitle => '暗号化された設定の復元';

  @override
  String get encryptedBackup => '暗号化バックアップ';

  @override
  String get encryptedRestore => '暗号化復元';

  @override
  String get backup => 'バックアップ';

  @override
  String get restore => '復元';

  @override
  String get selectBackupLocation => 'バックアップの保存場所を選択';

  @override
  String get backupFileTemplate => 'backup_%s.gsbak';

  @override
  String get enterPassword => '%s のパスワードを入力';

  @override
  String get invalidPassword => 'パスワードが無効です';

  @override
  String get community => 'コミュニティ';

  @override
  String get guides => 'ガイド';

  @override
  String get documentation => 'ガイド & Wiki';

  @override
  String get viewDocumentation => 'ガイド & Wikiを表示';

  @override
  String get requestAFeature => '機能のリクエスト';

  @override
  String get contributeTitle => '開発を支援する';

  @override
  String get improveTranslations => '翻訳を改善する';

  @override
  String get joinTheDiscussion => 'Discordに参加する';

  @override
  String get noLogFilesFound => 'ログファイルが見つかりません！';

  @override
  String get guidedSetup => 'ガイド付きセットアップ';

  @override
  String get uiGuide => 'UIガイド';

  @override
  String get viewPrivacyPolicy => 'プライバシーポリシー';

  @override
  String get viewEula => '利用規約 (EULA)';

  @override
  String get shareLogs => 'ログを共有';

  @override
  String get logsEmailSubjectTemplate => 'GitSync ログ (%s)';

  @override
  String get logsEmailRecipient => 'bugsviscouspotential@gmail.com';

  @override
  String get repositoryDefaults => 'リポジトリのデフォルト設定';

  @override
  String get miscellaneous => 'その他';

  @override
  String get dangerZone => 'デッドゾーン';

  @override
  String get file => 'ファイル';

  @override
  String get folder => 'フォルダ';

  @override
  String get directory => 'ディレクトリ';

  @override
  String get confirmFileDirDeleteMsg => '本当に %s \"%s\" %s を削除しますか？';

  @override
  String get deleteMultipleSuffix => 'および他 %s 個の項目とその内容';

  @override
  String get deleteSingularSuffix => 'とその内容';

  @override
  String get createAFile => 'ファイルを作成';

  @override
  String get fileName => 'ファイル名';

  @override
  String get createADir => 'ディレクトリを作成';

  @override
  String get dirName => 'フォルダ名';

  @override
  String get renameFileDir => '%s の名前を変更';

  @override
  String get fileTooLarge => 'ファイルが %s 行を超えています';

  @override
  String get readOnly => '読み取り専用';

  @override
  String get cut => '切り取り';

  @override
  String get copy => 'コピー';

  @override
  String get paste => '貼り付け';

  @override
  String get experimental => '実験的機能';

  @override
  String get experimentalMsg => '自己責任で使用してください';

  @override
  String get codeEditorLimits => 'コードエディタの制限';

  @override
  String get codeEditorLimitsDescription =>
      'コードエディタは基本的で機能的な編集を提供しますが、エッジケースや負荷の高い使用については十分なテストが行われていません。\n\nバグを見つけたり、機能の提案がある場合は、フィードバックをお待ちしています！グローバル設定または以下の「バグレポート」や「機能リクエスト」をご利用ください。';

  @override
  String get openFile => 'ファイルを開く';

  @override
  String get openFileDescription => 'ファイル内容のプレビュー/編集';

  @override
  String get viewGitLog => 'Gitログを表示';

  @override
  String get viewGitLogDescription => 'Gitの完全なログ履歴を表示';

  @override
  String get ignoreUntrack => '.gitignore + 追跡解除';

  @override
  String get ignoreUntrackDescription => 'ファイルを.gitignoreに追加して追跡を解除';

  @override
  String get excludeUntrack => '.git/info/exclude + 追跡解除';

  @override
  String get excludeUntrackDescription => 'ファイルをローカルのexcludeファイルに追加して追跡を解除';

  @override
  String get ignoreOnly => '.gitignoreへの追加のみ';

  @override
  String get ignoreOnlyDescription => 'ファイルを.gitignoreにのみ追加';

  @override
  String get excludeOnly => '.git/info/excludeへの追加のみ';

  @override
  String get excludeOnlyDescription => 'ファイルをローカルのexcludeファイルにのみ追加';

  @override
  String get untrack => 'ファイルの追跡を解除';

  @override
  String get untrackDescription => '指定したファイルの追跡を解除';

  @override
  String get selected => '選択済み';

  @override
  String get ignoreAndUntrack => '無視 & 追跡解除';

  @override
  String get open => '開く';

  @override
  String get fileDiff => 'ファイルの差分';

  @override
  String get openEditFile => 'ファイルを開く/編集';

  @override
  String get filesChanged => '個のファイルが変更されました';

  @override
  String get commits => '個のコミット';

  @override
  String get defaultContainerName => 'エイリアス';

  @override
  String get renameRepository => 'コンテナの名前を変更';

  @override
  String get renameRepositoryMsg => 'リポジトリコンテナの新しいエイリアスを入力してください';

  @override
  String get addMore => 'さらに追加';

  @override
  String get addRepository => 'コンテナを追加';

  @override
  String get addRepositoryMsg => '新しいリポジトリコンテナに固有のエイリアスを付けてください。後で識別しやすくなります。';

  @override
  String get confirmRepositoryDelete => 'コンテナ削除の確認';

  @override
  String get confirmRepositoryDeleteMsg => '本当にリポジトリコンテナ \"%s\" を削除しますか？';

  @override
  String get deleteRepoDirectoryCheckbox => 'リポジトリのディレクトリとそのすべての内容も削除する';

  @override
  String get confirmRepositoryDeleteTitle => 'コンテナ削除の確認';

  @override
  String get confirmRepositoryDeleteMessage => '本当にリポジトリ \"%s\" とその内容を削除しますか？';

  @override
  String get submodulesFoundTitle => 'サブモジュールが見つかりました';

  @override
  String get submodulesFoundMessage => '追加したリポジトリにサブモジュールが含まれています。これらを個別のリポジトリとしてアプリに自動追加しますか？\n\nこれはプレミアム機能です。';

  @override
  String get submodulesFoundAction => 'サブモジュールを追加';

  @override
  String get addRemote => 'Add Remote';

  @override
  String get deleteRemote => 'Delete Remote';

  @override
  String get renameRemote => 'Rename Remote';

  @override
  String get remoteName => 'Remote Name';

  @override
  String get confirmDeleteRemote => 'Are you sure you want to delete the remote \"%s\"?';

  @override
  String get confirmBranchCheckoutTitle => 'ブランチをチェックアウトしますか？';

  @override
  String get confirmBranchCheckoutMsgPart1 => '本当にブランチ ';

  @override
  String get confirmBranchCheckoutMsgPart2 => ' をチェックアウトしますか？';

  @override
  String get unsavedChangesMayBeLost => '保存されていない変更は失われる可能性があります。';

  @override
  String get checkout => 'チェックアウト';

  @override
  String get create => '作成';

  @override
  String get createBranch => '新しいブランチを作成';

  @override
  String get createBranchName => 'ブランチ名';

  @override
  String get createBranchBasedOn => 'ベース';

  @override
  String get attemptAutoFix => '自動修復を試みますか？';

  @override
  String get troubleshooting => 'トラブルシューティング';

  @override
  String get youreOffline => 'オフラインです。';

  @override
  String get someFeaturesMayNotWork => '一部の機能が動作しない可能性があります。';

  @override
  String get unsupportedGitAttributes => 'このリポジトリはストア版でのみ利用可能なGit機能を使用しています。';

  @override
  String get tapToOpenPlayStore => 'タップして更新してください。';

  @override
  String get ongoingMergeConflict => '進行中のマージコンフリクト';

  @override
  String get networkStallRetry => 'Poor network — will retry shortly';

  @override
  String get networkUnavailableRetry => 'ネットワークが利用不可です！\n接続復旧時に再試行します';

  @override
  String get failedToResolveAddressMessage => 'Could not reach the server. Check your internet connection or verify the repository URL is correct.';

  @override
  String get pullFailed => 'プルに失敗しました！未コミットの変更がないか確認して再試行してください。';

  @override
  String get reportABug => 'バグを報告';

  @override
  String get errorOccurredTitle => 'エラーが発生しました！';

  @override
  String get errorOccurredMessagePart1 => '問題が発生した場合は、下のボタンからすぐにバグレポートを作成してください。';

  @override
  String get errorOccurredMessagePart2 => 'または、長押しでクリップボードにコピーするか、閉じて続行してください。';

  @override
  String get cloneFailed => 'リポジトリのクローンに失敗しました！';

  @override
  String get mergingExceptionMessage => 'マージ中';

  @override
  String get fieldCannotBeEmpty => 'このフィールドは必須です';

  @override
  String get androidLimitedFilepathCharacters =>
      'これはAndroidのファイル命名制限による問題です。別のデバイスで該当するファイルの名前を変更してから再同期してください。\n\nサポートされていない文字: \" * / : < > ? \\ |';

  @override
  String get emptyNameOrEmail => 'Git構成に作成者名またはメールアドレスが不足しています。設定を更新して含めてください。';

  @override
  String get errorReadingZlibStream => 'これは特定のデバイスで発生する既知の問題で、アプリの最終レガシーバージョンで解決可能です。継続的なアクセスのためにダウンロードしてください（一部の機能が制限される場合があります）。';

  @override
  String get gitObsidianFoundTitle => 'Obsidian Git 警告';

  @override
  String get gitObsidianFoundMessage =>
      'このリポジトリには Obsidian Git プラグインが有効な Obsidian ボールトが含まれているようです。\n\n競合を避けるため、このデバイスではプラグインを無効にしてください！詳細はリンク先のドキュメントで確認できます。';

  @override
  String get gitObsidianFoundAction => 'ドキュメントを表示';

  @override
  String get githubIssueOauthTitle => 'GitHubを連携して自動報告';

  @override
  String get githubIssueOauthMsg => 'バグを報告し、その進捗を追跡するには、GitHubアカウントを連携する必要があります。この連携はグローバル設定でいつでもリセットできます。';

  @override
  String get includeLogs => 'ログファイルを含める';

  @override
  String get issueReportTitleTitle => 'タイトル';

  @override
  String get issueReportTitleDesc => '問題を要約した短い言葉';

  @override
  String get issueReportDescTitle => '詳細';

  @override
  String get issueReportDescDesc => '起きていることを詳しく説明してください';

  @override
  String get issueReportMinimalReproTitle => '再現手順';

  @override
  String get issueReportMinimalReproDesc => 'エラーに至るまでに行った手順を説明してください';

  @override
  String get includeLogFiles => 'ログファイルを含める';

  @override
  String get includeLogFilesDescription =>
      'ログファイルを含めると、根本原因の特定が大幅に早まるため、強く推奨します。\n\n「ログファイルを含める」を無効にする場合は、関連するログの抜粋をレポートに貼り付けてください。\n\n送信前に目のアイコンを使用して、機密情報が含まれていないかログを確認できます。\n\nログの添付は任意です。';

  @override
  String get report => '報告する';

  @override
  String get issueReportSuccessTitle => '報告が完了しました';

  @override
  String get issueReportSuccessMsg =>
      '問題が報告されました。進捗を確認したりメッセージに返信したりするために、このページをブックマークしてください。\n\n解決が難しくなるため、重複した報告は避けてください。\n\n7日間アクティビティがない問題は自動的にクローズされます。';

  @override
  String get trackIssue => '問題を追跡・メッセージに返信';

  @override
  String get createNewRepository => 'Create New Repository';

  @override
  String get noGitRepoFoundMsg => 'No git repository was found in the selected folder. Would you like to create a new one here?';

  @override
  String get remoteSetupLaterMsg => 'You can set up a remote later to sync with a server.';

  @override
  String get localOnlyNoRemote => 'Local only — add a remote to sync';

  @override
  String get noRemoteConfigured => 'No remote configured';
}
