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
  String get dontShowAgain => '今後表示しない';

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
  String get renameDescription => '選択したファイルまたはフォルダの名前を変更';

  @override
  String get selectAllDescription => '表示中のファイルとフォルダをすべて選択';

  @override
  String get deselectAllDescription => '選択をすべて解除';

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
  String get premiumStoreOnlyBanner => 'ストア版限定 — App StoreまたはPlay Storeで入手';

  @override
  String get premiumMultiRepoTitle => 'マルチリポジトリ管理';

  @override
  String get premiumMultiRepoSubtitle => '1つのアプリですべてのリポジトリ。\nそれぞれに独自の認証情報と設定。';

  @override
  String get premiumUnlimitedContainers => '無制限のコンテナ';

  @override
  String get premiumIndependentAuth => 'リポジトリごとに独立した認証';

  @override
  String get premiumAutoAddSubmodules => 'サブモジュールを自動追加';

  @override
  String get premiumEnhancedSyncSubtitle => 'iOSでの自動バックグラウンド同期。\n最短1分間隔。';

  @override
  String get premiumSyncPerMinute => '1分ごとの同期';

  @override
  String get premiumServerTriggered => 'サーバープッシュ通知';

  @override
  String get premiumWorksAppClosed => 'アプリ終了時も動作';

  @override
  String get premiumReliableDelivery => '確実な定期配信';

  @override
  String get premiumGitLfsTitle => 'Git LFS';

  @override
  String get premiumGitLfsSubtitle => 'Git LFSを完全サポート。\n大容量バイナリファイルも簡単に同期。';

  @override
  String get premiumFullLfsSupport => 'Git LFS完全サポート';

  @override
  String get premiumTrackLargeFiles => '大容量バイナリファイルを追跡';

  @override
  String get premiumAutoLfsPullPush => 'LFSプル/プッシュ自動実行';

  @override
  String get premiumGitFiltersTitle => 'Gitフィルター';

  @override
  String get premiumGitFiltersSubtitle => 'git-lfsやgit-cryptなどのGitフィルターに対応。\nさらに追加予定。';

  @override
  String get premiumGitLfsFilter => 'git-lfsフィルター';

  @override
  String get premiumGitCryptFilter => 'git-cryptフィルター';

  @override
  String get premiumMoreFiltersSoon => 'さらにフィルター追加予定';

  @override
  String get premiumGitHooksTitle => 'Gitフック';

  @override
  String get premiumGitHooksSubtitle => '毎回の同期前にpre-commitフックを自動実行。';

  @override
  String get premiumHookTrailingWhitespace => '末尾の空白チェック';

  @override
  String get premiumHookEndOfFileFixer => 'ファイル末尾修正';

  @override
  String get premiumHookCheckYamlJson => 'YAML/JSONチェック';

  @override
  String get premiumHookMixedLineEnding => '改行コード統一';

  @override
  String get premiumHookDetectPrivateKey => '秘密鍵の検出';

  @override
  String get switchToClientMode => 'クライアントモードに切り替え…';

  @override
  String get switchToSyncMode => '同期モードに切り替え…';

  @override
  String get defaultTo => 'デフォルト設定';

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
  String get resolveLater => '後で解決';

  @override
  String get keepChanges => '変更を保持';

  @override
  String get current => '現在の';

  @override
  String get both => '両方';

  @override
  String get remote => 'リモート';

  @override
  String get incoming => '受信';

  @override
  String get merge => 'マージ';

  @override
  String get resolve => '解決';

  @override
  String get merging => 'マージ中…';

  @override
  String get resolving => '解決中…';

  @override
  String get clearSelection => '選択をクリア';

  @override
  String get keepSelected => '選択を保持';

  @override
  String get resolveAll => 'すべて解決';

  @override
  String get allCurrent => '現在のすべて';

  @override
  String get allIncoming => '受信のすべて';

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
  String get welcomeSetupPrompt => 'クイックセットアップを実行しますか？';

  @override
  String get welcomePositive => '開始する';

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
  String get onboardingSyncSettingsTitle => '同期設定';

  @override
  String get onboardingSyncSettingsSubtitle => 'リポジトリの同期方法を選択します';

  @override
  String get onboardingAppSyncFeatureOpen => 'アプリ起動時に同期';

  @override
  String get onboardingAppSyncFeatureClose => 'アプリ終了時に同期';

  @override
  String get onboardingAppSyncFeatureSelect => '監視するアプリを選択';

  @override
  String get onboardingScheduledSyncFeatureFreq => '同期頻度を設定';

  @override
  String get onboardingScheduledSyncFeatureCustom => 'Androidでカスタム間隔を選択';

  @override
  String get onboardingScheduledSyncFeatureBg => 'バックグラウンドで動作';

  @override
  String get onboardingQuickSyncFeatureTile => 'クイック設定タイルで同期';

  @override
  String get onboardingQuickSyncFeatureShortcut => 'アプリショートカットで同期';

  @override
  String get onboardingQuickSyncFeatureWidget => 'ホーム画面ウィジェットで同期';

  @override
  String get onboardingOtherSyncFeatureAndroid => 'Androidインテント';

  @override
  String get onboardingOtherSyncFeatureIos => 'iOSインテント';

  @override
  String get onboardingOtherSyncDescription => 'プラットフォームのその他の同期方法を確認';

  @override
  String get onboardingTapToConfigure => 'タップして設定';

  @override
  String get showcaseGlobalSettingsTitle => 'グローバル設定';

  @override
  String get showcaseGlobalSettingsSubtitle => 'アプリ全体の設定とツール';

  @override
  String get showcaseGlobalSettingsFeatureTheme => 'テーマ、言語、表示オプションを調整';

  @override
  String get showcaseGlobalSettingsFeatureBackup => '設定のバックアップと復元';

  @override
  String get showcaseGlobalSettingsFeatureSetup => 'ガイド付きセットアップやUIツアーを再開';

  @override
  String get showcaseSyncProgressTitle => '同期ステータス';

  @override
  String get showcaseSyncProgressSubtitle => '状況をひと目で確認';

  @override
  String get showcaseSyncProgressFeatureWatch => '同期操作をリアルタイムで表示';

  @override
  String get showcaseSyncProgressFeatureConfirm => '同期完了を通知';

  @override
  String get showcaseSyncProgressFeatureErrors => 'タップしてエラー表示またはログビューアを開く';

  @override
  String get showcaseAddMoreTitle => 'コンテナ';

  @override
  String get showcaseAddMoreSubtitle => '複数のリポジトリを一元管理';

  @override
  String get showcaseAddMoreFeatureSwitch => 'リポジトリコンテナを即座に切り替え';

  @override
  String get showcaseAddMoreFeatureManage => 'コンテナの名前変更や削除';

  @override
  String get showcaseAddMoreFeaturePremium => 'プレミアムでコンテナを追加';

  @override
  String get showcaseControlTitle => '同期コントロール';

  @override
  String get showcaseControlSubtitle => '同期とコミットのツール';

  @override
  String get showcaseControlFeatureSync => 'ワンタップで手動同期';

  @override
  String get showcaseControlFeatureHistory => '最近のコミット履歴を表示';

  @override
  String get showcaseControlFeatureConflicts => 'マージ競合を解決';

  @override
  String get showcaseControlFeatureMore => 'フォースプッシュ、フォースプルなど';

  @override
  String get showcaseAutoSyncTitle => '自動同期';

  @override
  String get showcaseAutoSyncSubtitle => 'リポジトリを自動で同期';

  @override
  String get showcaseAutoSyncFeatureApp => '選択したアプリの開閉時に同期';

  @override
  String get showcaseAutoSyncFeatureSchedule => '定期的なバックグラウンド同期';

  @override
  String get showcaseAutoSyncFeatureQuick => 'クイックタイル、ショートカット、ウィジェットで同期';

  @override
  String get showcaseAutoSyncFeaturePremium => 'プレミアムで同期レートを向上';

  @override
  String get showcaseSetupGuideTitle => 'セットアップ & ガイド';

  @override
  String get showcaseSetupGuideSubtitle => 'いつでもウォークスルーを再表示';

  @override
  String get showcaseSetupGuideFeatureSetup => 'セットアップを最初から実行';

  @override
  String get showcaseSetupGuideFeatureTour => 'UIのハイライトをツアー';

  @override
  String get showcaseRepoTitle => 'リポジトリ';

  @override
  String get showcaseRepoSubtitle => 'このリポジトリを管理するコマンドセンター';

  @override
  String get showcaseRepoFeatureAuth => 'Gitプロバイダで認証';

  @override
  String get showcaseRepoFeatureDir => 'ローカルディレクトリを選択または変更';

  @override
  String get showcaseRepoFeatureBrowse => 'ファイルを直接参照・編集';

  @override
  String get showcaseRepoFeatureRemote => 'リモートURLを表示または変更';

  @override
  String get onboardingClientMode => 'クライアントモード';

  @override
  String get onboardingClientModeDescription => 'Gitクライアントに期待されるすべての機能';

  @override
  String get onboardingClientFeatureBranch => 'ブランチ管理';

  @override
  String get onboardingClientFeatureCommit => '手動コミット & プッシュ';

  @override
  String get onboardingClientFeatureDiff => '差分ビューア';

  @override
  String get onboardingSyncMode => '同期モード';

  @override
  String get onboardingSyncModeDescription => '自動ファイル同期をバックグラウンドで実行';

  @override
  String get onboardingSyncFeatureAutoCommit => '自動コミット & プッシュ';

  @override
  String get onboardingSyncFeatureBackground => 'バックグラウンド動作';

  @override
  String get onboardingSyncFeatureConflict => '簡単な競合解決';

  @override
  String get onboardingFileExplorer => 'ファイルエクスプローラ';

  @override
  String get onboardingBrowseFeatureHidden => '隠しファイルを表示';

  @override
  String get onboardingBrowseFeatureLog => 'Gitログを表示';

  @override
  String get onboardingBrowseFeatureIgnore => 'ファイルの追跡解除と無視';

  @override
  String get onboardingCodeEditor => 'コードエディタ';

  @override
  String get onboardingEditFeatureSyntax => '構文ハイライト';

  @override
  String get onboardingEditFeatureAutosave => '自動保存';

  @override
  String get onboardingEditFeatureExperimental => '実験的機能';

  @override
  String get onboardingNotificationDescription => '通知は以下をお知らせします：';

  @override
  String get onboardingNotificationFeatureSync => '同期ステータスの更新';

  @override
  String get onboardingNotificationFeatureConflict => 'マージ競合の警告';

  @override
  String get onboardingNotificationFeatureBug => 'バグ報告の通知';

  @override
  String get onboardingNotificationDefault => '通知はすべてデフォルトでオフです';

  @override
  String get onboardingFileAccessDescription => 'ファイルアクセスが必要な機能：';

  @override
  String get onboardingFileAccessFeatureSync => 'リポジトリの同期';

  @override
  String get onboardingFileAccessFeatureReadWrite => 'ファイルの読み書き';

  @override
  String get onboardingFileAccessFeatureDirectory => '選択したディレクトリへのアクセス';

  @override
  String get onboardingPremiumFeatures => 'プレミアム機能';

  @override
  String get onboardingWelcomeTitle => '簡単ファイル同期';

  @override
  String get onboardingWelcomeDescWorks => 'バックグラウンドで\n';

  @override
  String get onboardingWelcomeDescBackground => '動作し、\n';

  @override
  String get onboardingWelcomeDescYourWork => 'あなたの作業に\n';

  @override
  String get onboardingWelcomeDescFocus => '集中できます';

  @override
  String get onboardingChooseYourFocus => 'フォーカスを選択';

  @override
  String get onboardingChangeLaterInSettings => '設定から後で変更できます';

  @override
  String get onboardingBrowseEditTitle => '参照 & 編集';

  @override
  String get onboardingBrowseEditSubtitle => 'ファイル用の内蔵ツール';

  @override
  String get onboardingAlmostThereTitle => 'もう少しです！';

  @override
  String get onboardingAlmostThereSubtitle => '次に行うこと：';

  @override
  String get onboardingStepAuthenticate => 'Gitプロバイダで認証';

  @override
  String get onboardingStepClone => 'リポジトリを端末にクローン';

  @override
  String get onboardingStepSyncSettings => '同期設定を構成';

  @override
  String get onboardingStepWiki => '必要に応じてWikiを確認';

  @override
  String get onboardingStepAllSet => '以上で準備完了！';

  @override
  String get onboardingAuthTitle => '認証';

  @override
  String get onboardingAuthSubtitle => '希望のGitプロバイダで認証';

  @override
  String get onboardingLaunchWiki => 'Wikiを開く';

  @override
  String get onboardingHowYouFoundUsTitle => 'GitSyncをどのように知りましたか？';

  @override
  String get onboardingHowYouFoundUsSubtitle => 'ユーザーがどこから来たのか教えてください（複数選択可）';

  @override
  String get sourceReddit => 'Reddit';

  @override
  String get sourceYoutube => 'YouTube';

  @override
  String get sourceDiscord => 'Discord';

  @override
  String get sourceMedium => 'Medium';

  @override
  String get sourceGoogle => 'Google検索';

  @override
  String get sourceGithubFdroid => 'GitHub / F-Droid';

  @override
  String get sourceStore => 'Playストア / App Store';

  @override
  String get sourceWordOfMouth => '口コミ';

  @override
  String get sourceAdvertisements => '広告';

  @override
  String get sourceObsidian => 'Obsidian Gitプラグイン';

  @override
  String get sourceAiSearch => 'AI検索（ChatGPT、Claude、Grok）';

  @override
  String get sourceOther => 'その他';

  @override
  String get sourceOtherHint => '出典を教えてください';

  @override
  String get currentBranch => '現在のブランチ';

  @override
  String get detachedHead => 'Detached Head';

  @override
  String get unbornBranch => '未生成ブランチ';

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
  String get appSyncIosDescription => 'GitSyncの開閉時に自動同期';

  @override
  String get iosAppSyncDocsLinkText => '他のアプリの開閉時に同期する';

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
  String get iosSyncOnAppClosed => 'GitSyncが閉じられた時に同期';

  @override
  String get iosSyncOnAppOpened => 'GitSyncが開かれた時に同期';

  @override
  String get scheduledSyncSettings => 'スケジュール同期設定';

  @override
  String get scheduledSyncDescription => 'バックグラウンドで定期的に自動同期します';

  @override
  String get tabHome => 'ホーム';

  @override
  String get iosDefaultSyncRate => 'iOSが許可した時';

  @override
  String get every => 'ごと';

  @override
  String get scheduledSync => '定期同期';

  @override
  String get custom => 'カスタム';

  @override
  String get interval15min => '15分';

  @override
  String get interval30min => '30分';

  @override
  String get interval1hour => '1時間';

  @override
  String get interval6hours => '6時間';

  @override
  String get interval12hours => '12時間';

  @override
  String get interval1day => '1日';

  @override
  String get interval1week => '1週間';

  @override
  String get minutes => '分';

  @override
  String get hours => '時間';

  @override
  String get days => '日';

  @override
  String get weeks => '週間';

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
  String get remoteAuthMismatchTitle => 'このリモートでは認証が機能しません';

  @override
  String get remoteAuthMismatchUsesSsh => 'このリモートはSSHを使用 — タップして切り替え';

  @override
  String get remoteAuthMismatchUsesHttps => 'このリモートはHTTPSまたはOAuthを使用 — タップして切り替え';

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
  String get passphrase => 'パスフレーズ';

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
  String get advancedOptions => '詳細オプション';

  @override
  String get shallowClone => 'シャロークローン（深さ）';

  @override
  String get bareClone => 'ベアクローン';

  @override
  String get cloneDepthPlaceholder => 'フル';

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
  String get defaultSyncMessageLabel => 'デフォルト同期メッセージ';

  @override
  String get syncMessageDescription => '日付と時刻には %s を使用';

  @override
  String get syncMessageTimeFormatLabel => '同期メッセージの日時形式';

  @override
  String get defaultSyncMessageTimeFormatLabel => 'デフォルト同期メッセージの時刻形式';

  @override
  String get syncMessageTimeFormatDescription => '標準的な日時フォーマット構文を使用します';

  @override
  String get remoteLabel => 'デフォルトのリモート';

  @override
  String get defaultRemote => 'origin';

  @override
  String get authorNameLabel => '作成者名';

  @override
  String get defaultAuthorNameLabel => 'デフォルトの作成者名';

  @override
  String get authorNameDescription => 'コミット履歴であなたを識別するために使用';

  @override
  String get authorName => 'JohnSmith12';

  @override
  String get authorEmailLabel => '作成者のメールアドレス';

  @override
  String get defaultAuthorEmailLabel => 'デフォルトの作成者メール';

  @override
  String get authorEmailDescription => 'コミットにattributionとして添付';

  @override
  String get authorEmail => 'john12@smith.com';

  @override
  String get postFooterLabel => '投稿フッター';

  @override
  String get postFooterDescription => '作成するIssue、コメント、PRの末尾に追加';

  @override
  String get postFooterDialogInfo =>
      'このテキストは、作成するIssue、コメント、プルリクエストの末尾に自動的に追加されます。リポジトリ設定で変更または削除できます。\n\n新しいリポジトリのデフォルトは、グローバル設定の「リポジトリのデフォルト」で設定できます。';

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
  String get dangerZone => '危険ゾーン';

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
  String get openInTextastic => 'Open in Textastic';

  @override
  String get openInTextasticDescription => 'Open file in Textastic app';

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
  String get addRemote => 'リモートを追加';

  @override
  String get deleteRemote => 'リモートを削除';

  @override
  String get renameRemote => 'リモートの名前を変更';

  @override
  String get remoteName => 'リモート名';

  @override
  String get confirmDeleteRemote => 'リモート「%s」を削除してもよろしいですか？';

  @override
  String get orEnterManually => 'または手動で入力';

  @override
  String get createOnProvider => '%sで作成';

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
  String get renameBranch => 'ブランチ名を変更';

  @override
  String get deleteBranch => 'ブランチを削除しますか？';

  @override
  String get confirmDeleteBranchMsg => 'ブランチ「%s」を削除してもよろしいですか？';

  @override
  String get menuAmendCommit => 'コミットを修正';

  @override
  String get menuAmendCommitDesc => '最新のコミットメッセージまたは内容を変更';

  @override
  String get menuUndoCommit => 'コミットを元に戻す';

  @override
  String get menuUndoCommitDesc => 'コミットを元に戻すが、変更はステージに保持';

  @override
  String get menuResetToCommit => 'このコミットにリセット';

  @override
  String get menuResetToCommitDesc => 'このコミット以降のコミットをすべて破棄';

  @override
  String get menuCheckoutCommit => 'コミットをチェックアウト';

  @override
  String get menuCheckoutCommitDesc => 'このコミットをチェックアウト（デタッチドHEAD）';

  @override
  String get menuRevertCommit => 'コミットの変更を打ち消し';

  @override
  String get menuRevertCommitDesc => 'これらの変更を取り消す新しいコミットを作成';

  @override
  String get menuCreateBranch => 'コミットからブランチを作成';

  @override
  String get menuCreateBranchDesc => 'このコミットから新しいブランチを作成';

  @override
  String get menuCreateTag => 'タグを作成';

  @override
  String get menuCreateTagDesc => 'このコミットにタグを作成';

  @override
  String get menuCherryPick => 'コミットをチェリーピック';

  @override
  String get menuCherryPickDesc => 'このコミットを現在のブランチに適用';

  @override
  String get menuSelectCommits => 'コミットを選択';

  @override
  String get menuSelectCommitsDesc => 'バッチ操作用に複数のコミットを選択';

  @override
  String get menuCopySha => 'SHAをコピー';

  @override
  String get menuCopyShaDesc => 'コミットハッシュ全体をクリップボードにコピー';

  @override
  String get menuCopyTag => 'タグをコピー';

  @override
  String get menuCopyTagDesc => 'タグ名をクリップボードにコピー';

  @override
  String get menuViewOnProvider => '%sで表示';

  @override
  String get menuViewOnProviderDesc => 'ブラウザでこのコミットを開く';

  @override
  String get createBranchFromCommit => 'コミットからブランチを作成';

  @override
  String get createBranchFromCommitMsg => 'コミット%sから新しいブランチを作成します';

  @override
  String get checkoutCommit => 'コミットをチェックアウト';

  @override
  String get checkoutCommitMsg => 'コミット%sでデタッチドHEAD状態になります';

  @override
  String get checkoutCommitDetachedWarning => 'どのブランチにも属しません。変更を保持するには新しいブランチを作成してください';

  @override
  String get createTagOnCommit => 'タグを作成';

  @override
  String get createTagOnCommitMsg => 'コミット%sにタグを作成します';

  @override
  String get tagName => 'タグ名';

  @override
  String get revertCommit => 'コミットを打ち消し';

  @override
  String get revertCommitMsg => 'コミット%sによる変更を取り消します';

  @override
  String get revertCommitWarning => '変更を取り消す新しいコミットが作成されます';

  @override
  String get revert => '打ち消し';

  @override
  String get amendCommit => 'コミットを修正';

  @override
  String get amendCommitMsg => 'コミット%sのメッセージを編集';

  @override
  String get amendCommitWarning => 'コミットが書き換えられます。すでにプッシュ済みの場合はフォースプッシュが必要です';

  @override
  String get amend => '修正';

  @override
  String get undoCommit => 'コミットを元に戻す';

  @override
  String get undoCommitMsg => 'コミット%sを元に戻す';

  @override
  String get undoCommitWarning => 'コミットは削除されますが、変更はステージに残ります';

  @override
  String get undo => '元に戻す';

  @override
  String get resetToCommit => 'コミットにリセット';

  @override
  String get resetToCommitMsg => 'コミット%sにリセット';

  @override
  String get resetToCommitWarning => 'このコミット以降のすべてのコミットと作業ディレクトリの変更は完全に失われます。元に戻せません';

  @override
  String get reset => 'リセット';

  @override
  String get cherryPickCommit => 'コミットをチェリーピック';

  @override
  String get cherryPickCommitMsg => 'コミット%sから変更を適用';

  @override
  String get cherryPickCommitWarning => '変更がターゲットブランチと重なる場合、マージ競合が発生する可能性があります';

  @override
  String get cherryPickTargetBranch => 'ターゲットブランチ';

  @override
  String get cherryPick => 'チェリーピック';

  @override
  String get cherryPickCommits => 'コミットをチェリーピック';

  @override
  String get cherryPickCommitsMsg => '%s件のコミットから変更を適用';

  @override
  String get cherryPickCommitsWarning => 'コミットは時系列順に適用されます。各ステップで競合が発生する可能性があります';

  @override
  String get squashCommits => 'コミットをスカッシュ';

  @override
  String get squashCommitsMsg => '%s件のコミットを1つに統合';

  @override
  String get squashCommitsWarning => 'コミット履歴が書き換えられます。プッシュ済みの場合はフォースプッシュが必要です';

  @override
  String get squash => 'スカッシュ';

  @override
  String get squashCommitMessage => 'スカッシュメッセージ';

  @override
  String get selectCommits => 'コミットを選択';

  @override
  String get selectedCount => '%s件選択中';

  @override
  String get squashRequiresConsecutive => 'スカッシュには最新コミットからの連続したコミットが必要です';

  @override
  String get issues => 'Issue';

  @override
  String get issueFilterOpen => 'オープン';

  @override
  String get issueFilterClosed => 'クローズ';

  @override
  String get issueFilterAll => 'すべて';

  @override
  String get issuesNotFound => 'Issueが見つかりません…';

  @override
  String get filterAuthor => '作成者';

  @override
  String get filterLabels => 'ラベル';

  @override
  String get filterAssignee => '担当者';

  @override
  String get filterMilestone => 'マイルストーン';

  @override
  String get filterProject => 'プロジェクト';

  @override
  String get filterNone => 'なし';

  @override
  String get filterMilestonesEmpty => 'マイルストーンが見つかりません';

  @override
  String get filterProjectsEmpty => 'プロジェクトが見つかりません';

  @override
  String get sortNewest => '新しい順';

  @override
  String get sortOldest => '古い順';

  @override
  String get sortMostCommented => 'コメント最多順';

  @override
  String get sortRecentlyUpdated => '更新日順';

  @override
  String get filterSidebar => 'フィルター';

  @override
  String get filterReviewer => 'レビュアー';

  @override
  String get pullRequests => 'プルリクエスト';

  @override
  String get pullRequestsNotFound => 'プルリクエストが見つかりません…';

  @override
  String get tags => 'タグ';

  @override
  String get tagsNotFound => 'タグが見つかりません…';

  @override
  String get releases => 'リリース';

  @override
  String get releasesNotFound => 'リリースが見つかりません…';

  @override
  String get preRelease => 'プレリリース';

  @override
  String get draft => '下書き';

  @override
  String get releaseAssets => 'アセット';

  @override
  String get noAssets => 'アセットなし';

  @override
  String get actions => 'アクション';

  @override
  String get actionsNotFound => 'アクションが見つかりません…';

  @override
  String get actionFilterAll => 'すべて';

  @override
  String get actionFilterSuccess => '成功';

  @override
  String get actionFilterFailed => '失敗';

  @override
  String get attemptAutoFix => '自動修復を試みますか？';

  @override
  String get troubleshooting => 'トラブルシューティング';

  @override
  String get youreOffline => 'オフラインです。';

  @override
  String get someFeaturesMayNotWork => '一部の機能が動作しない可能性があります。';

  @override
  String get unsupportedGitAttributes => 'このリポジトリはストア版でのみ利用可能なGitフィルターを使用しています。';

  @override
  String get tapToOpenPlayStore => 'タップして更新してください。';

  @override
  String get ongoingMergeConflict => '進行中のマージコンフリクト';

  @override
  String get networkStallRetry => 'ネットワーク不良 — まもなく再試行';

  @override
  String get networkUnavailableRetry => 'ネットワークが利用不可です！\n接続復旧時に再試行します';

  @override
  String get networkStallManual => 'ネットワーク不良 — もう一度お試しください';

  @override
  String get networkUnavailableManual => 'ネットワークが利用できません — もう一度お試しください';

  @override
  String get networkRetryComplete => 'キューに入れた操作が完了しました';

  @override
  String get failedToResolveAddressMessage => 'サーバーに到達できませんでした。インターネット接続を確認するか、リポジトリURLが正しいか確認してください';

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
  String get issueDuplicateTitle => 'Already Reported';

  @override
  String get issueDuplicateMsg =>
      'This bug has already been reported and is being tracked in an open issue. \n\nOpen the issue to follow progress, or send your report as a message there so it reaches us without creating a duplicate.';

  @override
  String get viewIssue => 'View Issue';

  @override
  String get sendMessage => 'Send As Message';

  @override
  String get issueCommentSuccessTitle => 'Message Sent';

  @override
  String get issueCommentSuccessMsg =>
      'Your report has been added to the existing issue. Bookmark this page to track progress and respond to messages. \n\nIssues with no activity for 7 days are automatically closed.';

  @override
  String get issueCommentFailedMsg => 'Your message couldn’t be sent. Please check your connection and try again.';

  @override
  String get createNewRepository => '新しいリポジトリを作成';

  @override
  String get noGitRepoFoundMsg => '選択したフォルダにGitリポジトリが見つかりませんでした。ここに新しいリポジトリを作成しますか？';

  @override
  String get remoteSetupLaterMsg => 'ローカルリポジトリが作成されます。\n認証してリモートを追加すると同期できるようになります。';

  @override
  String get localOnlyNoRemote => 'ローカルのみ — 同期するにはリモートを追加';

  @override
  String get noRemoteConfigured => 'リモートが設定されていません';

  @override
  String get createRemoteRepo => 'リモートリポジトリを作成';

  @override
  String get repoName => 'リポジトリ名';

  @override
  String get repoPublic => 'パブリック';

  @override
  String get repoPrivate => 'プライベート';

  @override
  String get creatingRemoteRepo => 'リモートリポジトリを作成中…';

  @override
  String get remoteRepoCreated => 'リモートリポジトリが作成され、originとしてリンクされました';

  @override
  String get remoteRepoCreateFailed => 'リモートリポジトリの作成に失敗しました';

  @override
  String get noRemoteDetectedMsg => 'このリポジトリにはリモートが設定されていません。作成しますか？';

  @override
  String get createAndLinkRemote => 'リモートを作成してリンク';

  @override
  String get createLocalOnly => 'ローカルのみ';

  @override
  String get initMainBranch => 'mainブランチを初期化';

  @override
  String get continueLabel => '続行';

  @override
  String get githubScopedLoginTitle => 'ステップ1：GitHubにサインイン';

  @override
  String get githubScopedLoginMsg => 'GitHubにリダイレクトされてサインインします。\n\nリポジトリにアクセスできるアカウントでログインし、GitSyncを承認してください。';

  @override
  String get githubScopedRepoTitle => 'ステップ2：リポジトリを選択';

  @override
  String get githubScopedRepoMsg => 'GitSyncがアクセスできるリポジトリを選択してください。\n\n終了したらブラウザを閉じてアプリに戻ります。';

  @override
  String get issueDescription => '説明';

  @override
  String get issueNoDescription => '説明なし';

  @override
  String get issueComments => 'コメント';

  @override
  String get issueNoComments => 'コメントはまだありません';

  @override
  String get issueAddComment => 'コメントを追加…';

  @override
  String get issueSubmitComment => '送信';

  @override
  String get issueCloseIssue => 'Issueをクローズ';

  @override
  String get issueReopenIssue => 'Issueを再オープン';

  @override
  String get issueAddReaction => 'リアクションを追加';

  @override
  String get issueWriteDisabled => '書き込みアクセスがありません';

  @override
  String get issueStateUpdated => 'Issueの状態を更新しました';

  @override
  String get issueCommentAdded => 'コメントを追加しました';

  @override
  String get issueCommentFailed => 'コメントの追加に失敗しました';

  @override
  String get issueStateUpdateFailed => 'Issueの状態の更新に失敗しました';

  @override
  String get issueReactionFailed => 'リアクションの更新に失敗しました';

  @override
  String get issuePreview => 'プレビュー';

  @override
  String get issueWrite => '編集';

  @override
  String get issueEditSuccess => 'Issueを更新しました';

  @override
  String get issueEditFailed => 'Issueの更新に失敗しました';

  @override
  String get createIssue => 'Issueを作成';

  @override
  String get createIssueTitle => 'タイトル';

  @override
  String get createIssueTitleHint => 'Issueのタイトル';

  @override
  String get createIssueBody => '説明';

  @override
  String get createIssueBodyHint => 'Issueの説明…';

  @override
  String get createIssueSubmit => 'Issueを送信';

  @override
  String get createIssueSuccess => 'Issueを作成しました';

  @override
  String get createIssueFailed => 'Issueの作成に失敗しました';

  @override
  String get createIssueBlankIssue => '空のIssue';

  @override
  String get createIssueSelectTemplate => 'テンプレートを選択';

  @override
  String get createIssueRequired => '必須';

  @override
  String get createPr => 'プルリクエストを作成';

  @override
  String get createPrTitle => 'タイトル';

  @override
  String get createPrTitleHint => 'プルリクエストのタイトル';

  @override
  String get createPrBody => '説明';

  @override
  String get createPrBodyHint => '変更内容の説明…';

  @override
  String get createPrSubmit => 'プルリクエストを作成';

  @override
  String get createPrSuccess => 'プルリクエストを作成しました';

  @override
  String get createPrFailed => 'プルリクエストの作成に失敗しました';

  @override
  String get createPrBaseBranch => 'ベース';

  @override
  String get createPrHeadBranch => '比較';

  @override
  String get createPrSelectBranch => 'ブランチを選択';

  @override
  String get prDescription => '説明';

  @override
  String get prNoDescription => '説明なし';

  @override
  String get prActivity => 'アクティビティ';

  @override
  String get prNoActivity => 'アクティビティはまだありません';

  @override
  String get prCommits => 'コミット';

  @override
  String get prCommitsNotFound => 'コミットが見つかりません';

  @override
  String get prChecks => 'チェック';

  @override
  String get prChecksNotFound => 'チェックが見つかりません';

  @override
  String get prAllChecksPassed => 'すべてのチェックに合格';

  @override
  String prChecksFailed(Object count) {
    return '$count件のチェックが失敗';
  }

  @override
  String get prChecksPending => 'チェック待機中';

  @override
  String get prFilesChanged => '変更されたファイル';

  @override
  String get prFilesChangedNotFound => '変更されたファイルが見つかりません';

  @override
  String get prConversation => '会話';

  @override
  String get prApproved => '承認済み';

  @override
  String get prChangesRequested => '変更リクエスト済み';

  @override
  String get prCommented => 'コメント済み';

  @override
  String get prNotFound => 'プルリクエストが見つかりません';

  @override
  String get prCommentAdded => 'コメントを追加しました';

  @override
  String get prCommentFailed => 'コメントの追加に失敗しました';

  @override
  String get prReactionFailed => 'リアクションの更新に失敗しました';

  @override
  String get prMentionedInPr => 'このプルリクエストで言及';

  @override
  String get prMentionedInIssue => 'このIssueで言及';

  @override
  String prForcePushed(Object after, Object before) {
    return '$beforeから$afterにフォースプッシュ';
  }

  @override
  String get recentCommits => '最近のコミット';

  @override
  String get branchManagement => 'ブランチ管理';

  @override
  String get providerTools => 'プロバイダツール';

  @override
  String get tabChat => 'チャット';

  @override
  String get tabFiles => 'ファイル';

  @override
  String get chatComingSoon => 'チャット機能は近日公開';

  @override
  String get chatComingSoonSubtitle => 'Claude Codeでファイルと対話';

  @override
  String get noRepoSetup => 'まずリポジトリを設定してください';

  @override
  String get enableAiFeatures => 'AI機能を有効化';

  @override
  String get hideAiFeatures => 'AI機能を非表示';

  @override
  String get hideAiFeaturesConfirmTitle => 'AI機能を非表示にしますか？';

  @override
  String get hideAiFeaturesConfirmMsg => 'これによりAIタブとアプリ内のすべてのAIボタンが削除されます。グローバル設定からいつでも再有効化できます';

  @override
  String get aiSetupTitle => 'AIのセットアップ';

  @override
  String get aiSetupMsg => 'この機能を使用するにはAIプロバイダを設定してください。AI設定に移動しますか？';
}
