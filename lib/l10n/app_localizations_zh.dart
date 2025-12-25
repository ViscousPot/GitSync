// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get dismiss => '关闭';

  @override
  String get skip => '跳过';

  @override
  String get done => '完成';

  @override
  String get confirm => '确认';

  @override
  String get ok => '确定';

  @override
  String get select => '选择';

  @override
  String get cancel => '取消';

  @override
  String get learnMore => '了解更多';

  @override
  String get loadingElipsis => '加载中…';

  @override
  String get previous => '之前';

  @override
  String get next => '下一个';

  @override
  String get finish => '结束';

  @override
  String get rename => '重命名';

  @override
  String get add => '添加';

  @override
  String get delete => '删除';

  @override
  String get optionalLabel => '（选填）';

  @override
  String get ios => 'iOS';

  @override
  String get android => 'Android';

  @override
  String get syncStarting => '检测更改中…';

  @override
  String get syncStartPull => '同步更改中…';

  @override
  String get syncStartPush => '同步本地更改中…';

  @override
  String get syncNotRequired => '无需同步！';

  @override
  String get syncComplete => '仓库同步完成！';

  @override
  String get syncInProgress => '同步进行中';

  @override
  String get syncScheduled => '同步已预定';

  @override
  String get detectingChanges => '检测更改中…';

  @override
  String get thisActionCannotBeUndone => '此操作无法撤销。';

  @override
  String get cloneProgressLabel => '克隆进度';

  @override
  String get forcePushProgressLabel => '强制推送进度';

  @override
  String get forcePullProgressLabel => '强制拉取进度';

  @override
  String get moreSyncOptionsLabel => '更多同步选项';

  @override
  String get repositorySettingsLabel => '仓库设置';

  @override
  String get addBranchLabel => '添加分支';

  @override
  String get deselectDirLabel => '取消选择目录';

  @override
  String get selectDirLabel => '选择目录';

  @override
  String get syncMessagesLabel => '禁用/启用同步消息';

  @override
  String get backLabel => '返回';

  @override
  String get authDropdownLabel => '认证下拉菜单';

  @override
  String get premiumDialogTitle => '解锁高级版';

  @override
  String get premiumDialogMessage => '多仓库支持是高级会员功能的一部分。\n只需一次支付 %s 即可永久解锁。\n\n高级功能：\n • 多仓库支持\n\n或者，连接您的 GitHub 账户以检查您是否是符合条件的 GitHub 赞助者。';

  @override
  String get premiumDialogButtonText => '以 %s 解锁';

  @override
  String get premiumDialogGitHubButtonText => '使用 GitHub 赞助';

  @override
  String get restorePurchase => '恢复购买';

  @override
  String get verifyGhSponsorTitle => '验证 GitHub 赞助';

  @override
  String get verifyGhSponsorMsg => '如果您已经赞助了 GitSync，可以自由使用高级功能。请使用 GitHub 进行身份验证，以便我们验证您的赞助者状态。';

  @override
  String get verifyGhSponsorNote => '注意：新的赞助者可能需要等待最多 1 天才会生效。';

  @override
  String get switchToClientMode => '切换到客户端模式…';

  @override
  String get switchToSyncMode => '切换到同步模式…';

  @override
  String get clientMode => '客户端模式';

  @override
  String get clientModeDescription => 'Expanded Git UI\n(Advanced)';

  @override
  String get syncMode => '同步模式';

  @override
  String get syncModeDescription => 'Automated syncing\n(Beginner-friendly)';

  @override
  String get syncNow => '立即同步';

  @override
  String get syncAllChanges => '同步所有更改';

  @override
  String get stageAndCommit => '暂存及提交';

  @override
  String get downloadChanges => '下载更改';

  @override
  String get uploadChanges => 'Upload Changes';

  @override
  String get downloadAndOverwrite => 'Download + Overwrite';

  @override
  String get uploadAndOverwrite => 'Upload + Overwrite';

  @override
  String get fetchRemote => 'Fetch %s';

  @override
  String get pullChanges => '拉取更改';

  @override
  String get pushChanges => '推送更改';

  @override
  String get updateSubmodules => 'Update Submodules';

  @override
  String get forcePush => '强制推送';

  @override
  String get forcePushing => '强制推送中…';

  @override
  String get confirmForcePush => '确认强制推送';

  @override
  String get confirmForcePushMsg => '您确定要强制推送这些更改吗？任何正在进行的合并冲突将被中止。';

  @override
  String get forcePull => '强制拉取';

  @override
  String get forcePulling => '强制拉取中…';

  @override
  String get confirmForcePull => '确认强制拉取';

  @override
  String get confirmForcePullMsg => '您确定要强制拉取这些更改吗？任何正在进行的合并冲突将被忽略。';

  @override
  String get localHistoryOverwriteWarning => '此操作将覆盖本地历史记录且无法撤销。';

  @override
  String get forcePushPullMessage => '请在过程完成之前不要关闭或退出应用。';

  @override
  String get manualSync => '手动同步';

  @override
  String get manualSyncMsg => '选择您要同步的文件';

  @override
  String get commit => 'Commit';

  @override
  String get unstage => 'Unstage';

  @override
  String get stage => 'Stage';

  @override
  String get selectAll => '全选';

  @override
  String get deselectAll => '取消全选';

  @override
  String get noUncommittedChanges => '没有未提交的更改';

  @override
  String get discardChanges => '丢弃更改';

  @override
  String get discardChangesTitle => '丢弃更改？';

  @override
  String get discardChangesMsg => '您确定要丢弃对 \"%s\" 的所有更改吗？';

  @override
  String get mergeConflictItemMessage => '存在合并冲突！点击解决';

  @override
  String get mergeConflict => '合并冲突';

  @override
  String get mergeDialogMessage => '使用编辑器解决合并冲突';

  @override
  String get commitMessage => '提交信息';

  @override
  String get abortMerge => '中止合并';

  @override
  String get keepChanges => '保留更改';

  @override
  String get local => '本地';

  @override
  String get both => '两者';

  @override
  String get remote => '远程';

  @override
  String get merge => '合并';

  @override
  String get merging => '合并中…';

  @override
  String get resolvingMerge => '解决合并中…';

  @override
  String get iosClearDataTitle => 'Is this a fresh install?';

  @override
  String get iosClearDataMsg =>
      'We detected that this might be a reinstallation, but it could also be a false alarm. On iOS, your Keychain isn’t cleared when you delete and reinstall the app, so some data may still be stored securely.\n\nIf this isn’t a fresh install, or you don’t want to reset, you can safely skip this step.';

  @override
  String get clearDataConfirmTitle => '确认数据清除';

  @override
  String get clearDataConfirmMsg => '这将永久删除所有应用数据，包括本地密钥。您确定要继续吗？';

  @override
  String get iosClearDataAction => '清除所有数据';

  @override
  String get legacyAppUserDialogTitle => '欢迎使用新版本！';

  @override
  String get legacyAppUserDialogMessagePart1 => '我们重构了应用，以获得更好的性能和未来发展。';

  @override
  String get legacyAppUserDialogMessagePart2 => '遗憾的是，您的旧设置与登录状态无法继承，因此您需要重新设置与认证。\n\n您喜爱的所有功能都还在。多仓库支持现在是一个小的一次性升级的一部分，有助于支持持续开发。';

  @override
  String get legacyAppUserDialogMessagePart3 => '感谢您继续支持我们 :)';

  @override
  String get setUp => '设置';

  @override
  String get welcome => '欢迎！';

  @override
  String get welcomeMessage => '看起来这是您的第一次使用 GitSync。\n\n您想要进行引导设置来开始使用吗？';

  @override
  String get welcomePositive => '开始引导';

  @override
  String get welcomeNeutral => '跳过';

  @override
  String get welcomeNegative => '我很熟练';

  @override
  String get notificationDialogTitle => '启用通知权限';

  @override
  String get notificationDialogMessage => '请启用通知权限以获得最佳体验。\n\n应用使用通知来：\n  • 弹出同步消息（可选）\n  • 错误报告';

  @override
  String get allFilesAccessDialogTitle => '启用\"所有文件访问权限\"';

  @override
  String get allFilesAccessDialogMessage => '没有\"所有文件访问权限\"您无法使用 GitSync！请启用它以获得最佳体验。\n\n应用使用\"所有文件访问权限\"将您的仓库同步到设备上选定的目录。应用不会尝试访问所选目录之外的任何文件。';

  @override
  String get almostThereDialogTitle => '快完成了！';

  @override
  String get almostThereDialogMessageAndroid =>
      '很快，我们将进行身份验证并将您的仓库克隆到本地设备上，为同步做准备。\n\n设置完成后，有几种方式可以触发同步：\n\n  • 从应用内\n  • 从快速磁贴\n  • 使用自动同步\n  • 使用自定义 intent （高级）';

  @override
  String get almostThereDialogMessageIos => '很快，我们将进行身份验证并将您的仓库克隆到设备上，为同步做准备。\n\n设置完成后，有几种方式可以触发同步：\n\n  • 从应用内';

  @override
  String get authDialogTitle => '使用 Git 服务商进行身份验证';

  @override
  String get authDialogMessage => '请使用您选择的 Git 服务商进行身份验证，然后克隆您的仓库！';

  @override
  String get authorDetailsPromptTitle => '需要提交者信息';

  @override
  String get authorDetailsPromptMessage => '您的提交者昵称或邮箱缺失。请在仓库设置中更新它们。';

  @override
  String get authorDetailsShowcasePrompt => 'Fill out your author details';

  @override
  String get goToSettings => '前往设置';

  @override
  String get enableAutosyncTitle => 'Enable App Sync';

  @override
  String get enableAutosyncMessage =>
      'Keep your data up-to-date effortlessly. Turn on App Sync to automatically sync in the background whenever apps are opened or closed.';

  @override
  String get addMoreHint => '点击此按钮向应用添加其他仓库';

  @override
  String get globalSettingsHint => '点击此按钮访问全局应用设置';

  @override
  String get syncProgressHint => '在此处跟踪活动同步操作的状态';

  @override
  String get controlHint => '使用这些控件手动同步或管理仓库操作';

  @override
  String get configHint => '使用此部分配置仓库设置并初始化设置';

  @override
  String get autoSyncOptionsHint => '使用这些设置启用后台同步并确保您的数据自动保持最新';

  @override
  String get guidedSetupHint => '需要演示或想要重新查看界面时，点击此处重新开始设置或界面指南';

  @override
  String get detachedHead => '分离的 HEAD';

  @override
  String get commitsNotFound => '未找到提交…';

  @override
  String get repoNotFound => '未找到提交…';

  @override
  String get committed => '已提交';

  @override
  String get additions => '%s ++';

  @override
  String get deletions => '%s --';

  @override
  String get modifyRemoteUrl => 'Modify Remote URL';

  @override
  String get modify => 'Modify';

  @override
  String get remoteUrl => 'Remote URL';

  @override
  String get setRemoteUrl => 'Set Remote URL';

  @override
  String get launchInBrowser => 'Launch in Browser';

  @override
  String get auth => '认证';

  @override
  String get gitDirPathHint => '/storage/emulated/0/…';

  @override
  String get openFileExplorer => '浏览及编辑';

  @override
  String get syncSettings => '同步设置';

  @override
  String get enableApplicationObserver => 'App Sync Settings';

  @override
  String get appSyncDescription => 'Automatically syncs when your selected app is opened or closed';

  @override
  String get accessibilityServiceDisclosureTitle => '启用无障碍服务介绍';

  @override
  String get accessibilityServiceDisclosureMessage =>
      '为了增强您的体验，\nGitSync 使用 Android 的无障碍服务来检测应用的打开或关闭。\n\n这帮助我们提供定制功能，而不存储或共享任何数据。\n\n请在下一个屏幕上启用 GitSync';

  @override
  String get accessibilityServiceDescription =>
      '为了增强您的体验，GitSync 使用 Android 的无障碍服务来检测应用的打开或关闭。这帮助我们提供定制功能，而不存储或共享任何数据。\n\n要点：\n目的：我们仅使用此服务来改善您的应用体验。\n隐私：不存储或发送数据到其他地方。\n控制：您可以随时在设备设置中禁用这些权限。';

  @override
  String get search => '搜索';

  @override
  String get searchEllipsis => 'Search…';

  @override
  String get applicationNotSet => '选择应用';

  @override
  String get selectApplication => '选择应用';

  @override
  String get multipleApplicationSelected => '已选择 (%s)';

  @override
  String get saveApplication => '保存';

  @override
  String get syncOnAppClosed => '应用关闭时同步';

  @override
  String get syncOnAppOpened => '应用打开时同步';

  @override
  String get scheduledSyncSettings => '定时同步设置';

  @override
  String get scheduledSyncDescription => 'Automatically syncs periodically in the background';

  @override
  String get sync => '同步';

  @override
  String get dontSync => '不同步';

  @override
  String get iosDefaultSyncRate => '当 iOS 允许时';

  @override
  String get aboutEvery => '约每';

  @override
  String get enhancedScheduledSync => '增强定时同步';

  @override
  String get enhancedScheduledSyncMsg1 => '与基本同步不同，此功能使用高级后台更新来更频繁和可靠地提供新数据。';

  @override
  String get enhancedScheduledSyncMsg2 => '在后台同步您的仓库，频率可达每分钟一次，即使应用关闭时也可以！\n\n轻松的持续更新意味着您的仓库在您需要时总是准备就绪。';

  @override
  String get enhancedScheduledSyncNote => '注意：后台同步可能会受到省电模式和勿扰模式的影响。';

  @override
  String get quickSyncSettings => 'Quick Sync Settings';

  @override
  String get quickSyncDescription => 'Sync using customizable quick tiles, shortcuts, or widgets';

  @override
  String get tileSyncSettings => '磁贴同步设置';

  @override
  String get otherSyncSettings => '其他同步设置';

  @override
  String get useForTileSync => '用于磁贴同步';

  @override
  String get useForTileManualSync => '用于磁贴手动同步';

  @override
  String get useForShortcutSync => 'Use for Sync Shortcut';

  @override
  String get useForShortcutManualSync => 'Use for Manual Sync Shortcut';

  @override
  String get useForWidgetSync => 'Use for Sync Widget';

  @override
  String get useForWidgetManualSync => 'Use for Manual Sync Widget';

  @override
  String get selectYourGitProviderAndAuthenticate => '选择您的 Git 提供商并进行身份验证';

  @override
  String get oauthProviders => 'oAuth Providers';

  @override
  String get gitProtocols => 'Git Protocols';

  @override
  String get oauthNoAffiliation => '通过第三方进行身份验证；\n不表示关联或认可。';

  @override
  String get replacesExistingAuth => 'Replaces existing\ncontainer auth';

  @override
  String get oauth => 'oauth';

  @override
  String get copyFromContainer => 'Copy from Container';

  @override
  String get or => 'or';

  @override
  String get enterPAT => 'Enter Personal Access Token';

  @override
  String get usePAT => 'Use PAT';

  @override
  String get oauthAllRepos => 'OAuth (All Repos)';

  @override
  String get oauthScoped => 'OAuth (Scoped)';

  @override
  String get ensureTokenScope => '确保您的令牌包含\"repo\"范围以获得完整功能。';

  @override
  String get user => '用户';

  @override
  String get exampleUser => '张三12';

  @override
  String get token => '令牌';

  @override
  String get exampleToken => 'ghp_1234abcd5678efgh';

  @override
  String get login => '登录';

  @override
  String get pubKey => '公钥';

  @override
  String get privKey => '私钥';

  @override
  String get passphrase => 'Passphrase';

  @override
  String get privateKey => '私钥';

  @override
  String get sshPubKeyExample => 'ssh-ed25519 AABBCCDDEEFF112233445566';

  @override
  String get sshPrivKeyExample => '-----BEGIN OPENSSH PRIVATE KEY----- AABBCCDDEEFF112233445566';

  @override
  String get generateKeys => '生成密钥';

  @override
  String get confirmKeySaved => '确认公钥已保存';

  @override
  String get copiedText => '已复制至剪贴板！';

  @override
  String get confirmPrivKeyCopy => '确认私钥复制';

  @override
  String get confirmPrivKeyCopyMsg => '您确定要将私钥复制到剪贴板吗？\n\n任何拥有此密钥的人都可以控制您的账户。确保您仅在安全位置粘贴它，并在之后清除剪贴板。';

  @override
  String get understood => '明白了';

  @override
  String get importPrivateKey => '导入私钥';

  @override
  String get importPrivateKeyMsg => '在下方粘贴您的私钥以使用现有账户。\n\n确保您在安全环境中粘贴密钥，因为任何拥有此密钥的人都可以控制您的账户。';

  @override
  String get importKey => '导入';

  @override
  String get cloneRepo => '克隆远程仓库';

  @override
  String get clone => '克隆';

  @override
  String get chooseHowToClone => 'Choose how you want to clone the repository:';

  @override
  String get directCloningMsg => 'Direct Cloning: Clones the repository into the selected folder';

  @override
  String get nestedCloningMsg => 'Nested Cloning: Creates a new folder named after the repository within the selected folder';

  @override
  String get directClone => 'Direct Clone';

  @override
  String get nestedClone => 'Nested Clone';

  @override
  String get gitRepoUrlHint => 'https://git.abc/xyz.git';

  @override
  String get invalidRepositoryUrlTitle => '无效的仓库 URL！';

  @override
  String get invalidRepositoryUrlMessage => '无效的仓库 URL！';

  @override
  String get cloneAnyway => '仍然克隆';

  @override
  String get iHaveALocalRepository => '使用本地仓库';

  @override
  String get cloningRepository => '克隆仓库中…';

  @override
  String get cloneMessagePart1 => '请不要退出此屏幕';

  @override
  String get cloneMessagePart2 => '这需要一些时间将仓库克隆到本地，时间取决于您的仓库大小与网络速度\n';

  @override
  String get selectCloneDirectory => '选择要克隆到的文件夹';

  @override
  String get confirmCloneOverwriteTitle => '文件夹内存在文件';

  @override
  String get confirmCloneOverwriteMsg => '您选择的文件夹已存在其他文件。可以将其覆盖（删除）或者取消该操作。';

  @override
  String get confirmCloneOverwriteWarning => '此操作不可逆。';

  @override
  String get confirmCloneOverwriteAction => '覆盖';

  @override
  String get repoSearchLimits => 'Repository Search Limits';

  @override
  String get repoSearchLimitsDescription =>
      'Repository search only examines the first 100 repositories returned by the API, so it may sometimes omit the repository you expect. \n\nIf the repository you want does not appear in search results, please clone it directly using its HTTPS or SSH URL.';

  @override
  String get repositorySettings => '仓库设置';

  @override
  String get settings => '设置';

  @override
  String get signedCommitsLabel => '签署提交';

  @override
  String get signedCommitsDescription => '签署提交以验证您的身份';

  @override
  String get importCommitKey => '导入密钥';

  @override
  String get commitKeyImported => '密钥已导入';

  @override
  String get useSshKey => '使用 AUTH 密钥进行提交签署';

  @override
  String get syncMessageLabel => '同步消息';

  @override
  String get syncMessageDescription => '使用 %s 表示日期和时间';

  @override
  String get syncMessageTimeFormatLabel => '同步消息时间格式';

  @override
  String get syncMessageTimeFormatDescription => '使用标准日期时间格式语法';

  @override
  String get remoteLabel => '默认远程';

  @override
  String get defaultRemote => 'origin';

  @override
  String get authorNameLabel => '提交昵称';

  @override
  String get authorName => '张三12';

  @override
  String get authorEmailLabel => '提交邮箱';

  @override
  String get authorEmail => 'zhangsan12@example.com';

  @override
  String get gitIgnore => '.gitignore';

  @override
  String get gitIgnoreDescription => '列出仓库上要忽略的文件或文件夹';

  @override
  String get gitIgnoreHint => '.trash/\n./…';

  @override
  String get gitInfoExclude => '.git/info/exclude';

  @override
  String get gitInfoExcludeDescription => '列出在此设备上要忽略的文件或文件夹';

  @override
  String get gitInfoExcludeHint => '.trash/\n./…';

  @override
  String get disableSsl => '禁用 SSL';

  @override
  String get disableSslDescription => 'Disable secure connection for HTTP repositories';

  @override
  String get disableSslPromptTitle => '禁用 SSL？';

  @override
  String get disableSslPromptMsg => '您克隆的地址以 \"http\" 开头 （不安全）。您可以选择禁用 SSL 验证，但这会降低安全性。';

  @override
  String get optimisedSync => 'Optimised Sync';

  @override
  String get optimisedSyncDescription => 'Intelligently reduce overall sync operations';

  @override
  String get proceedAnyway => '照常进行吗？';

  @override
  String get moreOptions => '更多选项';

  @override
  String get untrackAll => 'Untrack All';

  @override
  String get globalSettings => '全局设置';

  @override
  String get language => '语言';

  @override
  String get browseEditDir => '浏览及编辑档案目录';

  @override
  String get enableLineWrap => 'Enable Line Wrap in Editors';

  @override
  String get excludeFromRecents => 'Exclude From Recents';

  @override
  String get backupRestoreTitle => '加密配置恢复';

  @override
  String get encryptedBackup => 'Encrypted Backup';

  @override
  String get encryptedRestore => 'Encrypted Restore';

  @override
  String get backup => '备份';

  @override
  String get restore => '恢复';

  @override
  String get selectBackupLocation => '选择保存备份的位置';

  @override
  String get backupFileTemplate => '备份_%s.gsbak';

  @override
  String get enterPassword => '输入密码';

  @override
  String get invalidPassword => '无效密码';

  @override
  String get community => '社区';

  @override
  String get guides => '指南';

  @override
  String get documentation => '指南和文档';

  @override
  String get viewDocumentation => '查看指南和文档';

  @override
  String get requestAFeature => '请求功能';

  @override
  String get contributeTitle => '支持我们的工作';

  @override
  String get improveTranslations => 'Improve Translations';

  @override
  String get joinTheDiscussion => '加入 Discord';

  @override
  String get noLogFilesFound => '未找到记录档！';

  @override
  String get guidedSetup => '引导设置';

  @override
  String get uiGuide => '界面指南';

  @override
  String get viewPrivacyPolicy => '隐私政策';

  @override
  String get viewEula => '使用条款 (EULA)';

  @override
  String get shareLogs => '分享日志';

  @override
  String get logsEmailSubjectTemplate => 'GitSync Logs (%s)';

  @override
  String get logsEmailRecipient => 'bugsviscouspotential@gmail.com';

  @override
  String get repositoryDefaults => 'Repository Defaults';

  @override
  String get miscellaneous => 'Miscellaneous';

  @override
  String get dangerZone => 'Danger Zone';

  @override
  String get file => '文件';

  @override
  String get folder => '文件夹';

  @override
  String get directory => '目录';

  @override
  String get confirmFileDirDeleteTitle => '确认删除 %s';

  @override
  String get confirmFileDirDeleteMsg => '您确定要删除 %s \"%s\" 及其内容吗？';

  @override
  String get deleteMultipleSuffix => '和另外 %s 项及其内容';

  @override
  String get deleteSingularSuffix => '及其内容';

  @override
  String get createAFile => '创建文件';

  @override
  String get fileName => '文件名';

  @override
  String get createADir => '创建文件夹';

  @override
  String get dirName => '文件夹名';

  @override
  String get renameFileDir => '重命名 %s';

  @override
  String get fileTooLarge => '文件大小超过 %s 行';

  @override
  String get readOnly => '只读';

  @override
  String get cut => 'Cut';

  @override
  String get copy => 'Copy';

  @override
  String get paste => 'Paste';

  @override
  String get experimental => '实验性';

  @override
  String get experimentalMsg => '使用风险自负';

  @override
  String get codeEditorLimits => 'Code Editor Limits';

  @override
  String get codeEditorLimitsDescription =>
      'The code editor provides basic, functional editing but hasn’t been exhaustively tested for edge cases or heavy use. \n\nIf you encounter bugs or want to suggest features, I welcome feedback! Please use the Bug Report or Feature Request options in Global Settings or below.';

  @override
  String get openFile => 'Open File';

  @override
  String get openFileDescription => 'Preview/edit file contents';

  @override
  String get viewGitLog => 'view git log';

  @override
  String get viewGitLogDescription => 'View the full git log history';

  @override
  String get ignoreUntrack => '.gitignore + Untrack';

  @override
  String get ignoreUntrackDescription => 'Add files to .gitignore and untrack';

  @override
  String get excludeUntrack => '.git/info/exclude + Untrack';

  @override
  String get excludeUntrackDescription => 'Add files to the local exclude file and untrack';

  @override
  String get ignoreOnly => 'Add to .gitignore Only';

  @override
  String get ignoreOnlyDescription => 'Only add files to .gitignore';

  @override
  String get excludeOnly => 'Add to .git/info/exclude Only';

  @override
  String get excludeOnlyDescription => 'Only add files to the local exclude file';

  @override
  String get untrack => 'Untrack file(s)';

  @override
  String get untrackDescription => 'Untrack specified file(s)';

  @override
  String get selected => 'selected';

  @override
  String get ignoreAndUntrack => 'Ignore & Untrack';

  @override
  String get open => 'Open';

  @override
  String get fileDiff => 'File Diff';

  @override
  String get openEditFile => 'Open/Edit File';

  @override
  String get filesChanged => 'file(s) changed';

  @override
  String get defaultContainerName => '别名';

  @override
  String get renameRepository => '重命名仓库';

  @override
  String get renameRepositoryMsg => '为仓库容器输入新别名';

  @override
  String get addMore => '添加更多';

  @override
  String get addRepository => '添加仓库';

  @override
  String get addRepositoryMsg => '为您的新仓库容器提供一个唯一别名。这将帮助您之后识别它。';

  @override
  String get confirmRepositoryDelete => '确认删除仓库';

  @override
  String get confirmRepositoryDeleteMsg => '您确定要删除仓库容器 \"%s\" 吗？';

  @override
  String get deleteRepoDirectoryCheckbox => '同时删除仓库的目录及其所有内容';

  @override
  String get confirmRepositoryDeleteTitle => '确认删除仓库';

  @override
  String get confirmRepositoryDeleteMessage => '您确定要删除仓库 \"%s\" 及其内容吗？';

  @override
  String get submodulesFoundTitle => 'Submodules Found';

  @override
  String get submodulesFoundMessage =>
      'The repository you added contains submodules. Would you like to automatically add them as separate repositories in the app?\n\nThis is a premium feature.';

  @override
  String get submodulesFoundAction => 'Add Submodules';

  @override
  String get confirmBranchCheckoutTitle => '切换分支？';

  @override
  String get confirmBranchCheckoutMsgPart1 => '您确定要切换到分支 ';

  @override
  String get confirmBranchCheckoutMsgPart2 => ' 吗？';

  @override
  String get unsavedChangesMayBeLost => '未保存的更改可能会丢失。';

  @override
  String get checkout => '切换';

  @override
  String get create => '创建';

  @override
  String get createBranch => '创建新分支';

  @override
  String get createBranchName => '分支名称';

  @override
  String get createBranchBasedOn => '基于';

  @override
  String get attemptAutoFix => '尝试自动修复？';

  @override
  String get troubleshooting => 'Troubleshooting';

  @override
  String get youreOffline => '您已离线。';

  @override
  String get someFeaturesMayNotWork => '某些功能可能无法正常工作。';

  @override
  String get ongoingMergeConflict => '存在合并冲突';

  @override
  String get enableAccessibilityService => '请在\"已安装的应用\"下启用 GitSync';

  @override
  String get networkUnavailable => '网络不可用！';

  @override
  String get networkUnavailableRetry => '网络不可用！\nGitSync 将在重新连接时重试';

  @override
  String get pullFailed => '拉取失败！请检查未提交的更改并重试。';

  @override
  String get reportABug => '报告错误';

  @override
  String get reportBug => '<GitSync 错误> 点击发送错误报告';

  @override
  String get unknownError => '未知错误';

  @override
  String get enableNotifications => '启用通知权限以查看更多信息。';

  @override
  String get errorOccurredTitle => '发生错误！';

  @override
  String get errorOccurredMessagePart1 => '如果这造成了任何问题，请使用下面的按钮快速创建错误报告。';

  @override
  String get errorOccurredMessagePart2 => '否则，您可以关闭并继续。';

  @override
  String get applicationError => '应用程序错误！';

  @override
  String get missingAuthorDetailsError => '缺少仓库作者详细信息。请在仓库设置中设置您的姓名和邮箱。';

  @override
  String get outOfMemory => '内存分配不足！';

  @override
  String get invalidRemote => '无效远程！在设置中修改此项';

  @override
  String get largeFile => '不支持大于 50MB 的单个文件！';

  @override
  String get cloneFailed => '克隆仓库失败！';

  @override
  String get inaccessibleDirectoryMessage => '无法访问目录！请选择不同位置。';

  @override
  String get autoRebaseFailedException => '远程比本地更超前，我们无法自动为您变基，因为这会导致非快进更新。';

  @override
  String get nonExistingException => '远程引用不存在。';

  @override
  String get rejectedNodeleteException => '远程引用更新被拒绝，因为远程端不支持/允许删除引用。';

  @override
  String get rejectedException => '远程引用更新被拒绝。';

  @override
  String get rejectionWithReasonException => '远程引用更新被拒绝，因为 %s。';

  @override
  String get remoteChangedException => '远程引用更新被拒绝，因为远程仓库上的旧对象 ID 与定义的预期旧对象不同。';

  @override
  String get mergingExceptionMessage => '合并中';

  @override
  String get fieldCannotBeEmpty => '字段不能为空';

  @override
  String get androidLimitedFilepathCharacters =>
      'This issue is due to Android file naming restrictions. Please rename the affected files on a different device and resync.\n\nUnsupported characters: \" * / : &lt; &gt; ? \\ |';

  @override
  String get emptyNameOrEmail =>
      'Your Git configuration is missing an author name or email address. Please update your settings to include your author name and email.';

  @override
  String get errorReadingZlibStream =>
      'This is a known issue with specific devices which can be fixed with the last legacy version of the app. Please download it for continued access, though some features may be limited';

  @override
  String get gitObsidianFoundTitle => 'Obsidian Git Warning';

  @override
  String get gitObsidianFoundMessage =>
      'This repository seems to contain an Obsidian vault with the Obsidian Git plugin enabled.\n\nPlease disable the plugin on this device to avoid conflicts! More details on the process can be found in the linked documentation.';

  @override
  String get gitObsidianFoundAction => 'View Documentation';

  @override
  String get githubIssueOauthTitle => '连接 GitHub 以自动发送报告';

  @override
  String get githubIssueOauthMsg => '您需要连接您的 GitHub 账户来报告错误并跟踪其进度。\n您可以随时在全局设置中重置此连接。';

  @override
  String get issueReportMessage => '日志自动包含在报告中';

  @override
  String get includeLogs => 'Include Log File(s)';

  @override
  String get issueReportTitleTitle => '标题';

  @override
  String get issueReportTitleDesc => '总结问题的几个词';

  @override
  String get issueReportDescTitle => '描述';

  @override
  String get issueReportDescDesc => '更详细地解释发生了什么';

  @override
  String get issueReportMinimalReproTitle => '重现步骤';

  @override
  String get issueReportMinimalReproDesc => '描述导致错误的步骤';

  @override
  String get includeLogFiles => 'Include Log File(s)';

  @override
  String get includeLogFilesDescription =>
      'Including log files with your bug report is strongly recommended as they can greatly speed up diagnosing the root cause. \nIf you choose to disable \"Include log file(s)\", please copy and paste the relevant log excerpts into your report so we can reproduce the issue. You can review logs before sending by using the eye icon to confirm there’s nothing sensitive. \n\nIncluding logs is optional, not mandatory.';

  @override
  String get report => '报告';

  @override
  String get issueReportSuccessTitle => '问题报告成功';

  @override
  String get issueReportSuccessMsg => '您的问题已报告。您可以使用下面的链接跟踪其进度并回复消息。\n\n7 天内无活动的问题将自动关闭。';

  @override
  String get trackIssue => '跟踪问题';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');
}
