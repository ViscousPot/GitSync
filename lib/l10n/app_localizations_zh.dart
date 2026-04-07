// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get dismiss => '忽略';

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
  String get previous => '上一步';

  @override
  String get next => '下一步';

  @override
  String get finish => '结束';

  @override
  String get rename => '重命名';

  @override
  String get renameDescription => '重命名选中的文件或文件夹';

  @override
  String get selectAllDescription => '选择所有可见的文件和文件夹';

  @override
  String get deselectAllDescription => '取消选择所有已选中的文件和文件夹';

  @override
  String get add => '添加';

  @override
  String get delete => '删除';

  @override
  String get optionalLabel => '（可选）';

  @override
  String get ios => 'iOS';

  @override
  String get android => '安卓';

  @override
  String get syncStarting => '正在检测更改…';

  @override
  String get syncStartPull => '正在同步更改…';

  @override
  String get syncStartPush => '正在同步本地更改…';

  @override
  String get syncNotRequired => '无需同步！';

  @override
  String get syncComplete => '仓库已同步！';

  @override
  String get syncInProgress => '同步进行中';

  @override
  String get syncScheduled => '同步已计划';

  @override
  String get detectingChanges => '正在检测更改…';

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
  String get restorePurchase => '恢复购买';

  @override
  String get verifyGhSponsorTitle => '验证 GitHub 赞助身份';

  @override
  String get verifyGhSponsorMsg => '如果你是 GitHub 赞助者，可以免费使用高级功能。请使用 GitHub 登录以验证你的赞助状态。';

  @override
  String get verifyGhSponsorNote => '注意：新的赞助关系可能需要最多 1 天才能在应用中生效。';

  @override
  String get premiumStoreOnlyBanner => '仅限商店版本 — 请前往 App Store 或 Play Store 获取';

  @override
  String get premiumMultiRepoTitle => '管理多个仓库';

  @override
  String get premiumMultiRepoSubtitle => '一个应用，管理所有仓库。\n每个仓库拥有独立的凭证和设置。';

  @override
  String get premiumUnlimitedContainers => '无限仓库';

  @override
  String get premiumIndependentAuth => '每个仓库独立认证';

  @override
  String get premiumAutoAddSubmodules => '自动添加子模块';

  @override
  String get premiumEnhancedSyncSubtitle => 'iOS 后台自动同步。\n最快可每分钟一次。';

  @override
  String get premiumSyncPerMinute => '最快每分钟同步一次';

  @override
  String get premiumServerTriggered => '服务器推送通知';

  @override
  String get premiumWorksAppClosed => '即使应用关闭也能运行';

  @override
  String get premiumReliableDelivery => '可靠、准时的同步';

  @override
  String get premiumGitLfsTitle => 'Git LFS';

  @override
  String get premiumGitLfsSubtitle => '完整支持 Git 大文件存储。\n轻松同步包含大二进制文件的仓库。';

  @override
  String get premiumFullLfsSupport => '完整的 Git LFS 支持';

  @override
  String get premiumTrackLargeFiles => '追踪大二进制文件';

  @override
  String get premiumAutoLfsPullPush => '自动 LFS 拉取/推送';

  @override
  String get premiumGitFiltersTitle => 'Git 过滤器';

  @override
  String get premiumGitFiltersSubtitle => '支持 git 过滤器，包括 git-lfs、\ngit-crypt 等，更多功能即将推出。';

  @override
  String get premiumGitLfsFilter => 'git-lfs 过滤器';

  @override
  String get premiumGitCryptFilter => 'git-crypt 过滤器';

  @override
  String get premiumMoreFiltersSoon => '更多过滤器即将推出';

  @override
  String get premiumGitHooksTitle => 'Git 钩子';

  @override
  String get premiumGitHooksSubtitle => '每次同步前自动运行预提交钩子。';

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
  String get switchToClientMode => '切换到客户端模式…';

  @override
  String get switchToSyncMode => '切换到同步模式…';

  @override
  String get defaultTo => 'Default to';

  @override
  String get clientMode => '客户端模式';

  @override
  String get clientModeDescription => '扩展 Git 界面\n（高级）';

  @override
  String get syncMode => '同步模式';

  @override
  String get syncModeDescription => '自动同步\n（适合新手）';

  @override
  String get syncNow => '立即同步';

  @override
  String get syncAllChanges => '同步所有更改';

  @override
  String get stageAndCommit => '暂存并提交';

  @override
  String get downloadChanges => '下载更改';

  @override
  String get uploadChanges => '上传更改';

  @override
  String get downloadAndOverwrite => '下载并覆盖';

  @override
  String get uploadAndOverwrite => '上传并覆盖';

  @override
  String get fetchRemote => '获取 %s';

  @override
  String get pullChanges => '拉取更改';

  @override
  String get pushChanges => '推送更改';

  @override
  String get updateSubmodules => '更新子模块';

  @override
  String get forcePush => '强制推送';

  @override
  String get forcePushing => '正在强制推送…';

  @override
  String get confirmForcePush => '确认强制推送';

  @override
  String get confirmForcePushMsg => '确定要强制推送这些更改吗？所有正在进行的合并冲突都将被中止。';

  @override
  String get forcePull => '强制拉取';

  @override
  String get forcePulling => '正在强制拉取…';

  @override
  String get confirmForcePull => '确认强制拉取';

  @override
  String get confirmForcePullMsg => '确定要强制拉取这些更改吗？所有正在进行的合并冲突都将被忽略。';

  @override
  String get localHistoryOverwriteWarning => '此操作将覆盖本地历史记录，且无法撤销。';

  @override
  String get forcePushPullMessage => '请等待进程完成后再关闭或退出应用。';

  @override
  String get manualSync => '手动同步';

  @override
  String get manualSyncMsg => '选择你要同步的文件';

  @override
  String get commit => '提交';

  @override
  String get unstage => '取消暂存';

  @override
  String get stage => '暂存';

  @override
  String get selectAll => '全选';

  @override
  String get deselectAll => '取消全选';

  @override
  String get noUncommittedChanges => '没有未提交的更改';

  @override
  String get discardChanges => '放弃更改';

  @override
  String get discardChangesTitle => '放弃更改？';

  @override
  String get discardChangesMsg => '确定要放弃对 \"%s\" 的所有更改吗？';

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
  String get resolveLater => 'Resolve Later';

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
  String get resolve => 'Resolve';

  @override
  String get merging => '正在合并…';

  @override
  String get resolving => 'Resolving…';

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
  String get iosClearDataTitle => '这是全新安装吗？';

  @override
  String get iosClearDataMsg => '我们检测到这可能是重新安装，但也可能是误报。在 iOS 上，删除并重新安装应用时，你的钥匙串数据不会被清除，因此某些数据可能仍然安全存储。\n\n如果这不是全新安装，或者你不想重置，可以安全地跳过此步骤。';

  @override
  String get clearDataConfirmTitle => '确认重置应用数据';

  @override
  String get clearDataConfirmMsg => '这将永久删除所有应用数据，包括钥匙串条目。确定要继续吗？';

  @override
  String get iosClearDataAction => '清除所有数据';

  @override
  String get legacyAppUserDialogTitle => '欢迎使用新版本！';

  @override
  String get legacyAppUserDialogMessagePart1 => '我们从头开始重建了应用，以获得更好的性能和未来的扩展性。';

  @override
  String get legacyAppUserDialogMessagePart2 => '遗憾的是，你的旧设置无法迁移，因此你需要重新进行设置。\n\n所有你喜欢的功能都还在。多仓库支持现在是一项一次性的小额升级功能，有助于支持持续开发。';

  @override
  String get legacyAppUserDialogMessagePart3 => '感谢你的坚持使用 :)';

  @override
  String get setUp => '设置';

  @override
  String get welcomeSetupPrompt => '你想快速设置一下开始使用吗？';

  @override
  String get welcomePositive => '开始吧';

  @override
  String get welcomeNegative => '我很熟悉';

  @override
  String get notificationDialogTitle => '启用通知';

  @override
  String get allFilesAccessDialogTitle => '启用\"所有文件访问权限\"';

  @override
  String get authorDetailsPromptTitle => '需要作者信息';

  @override
  String get authorDetailsPromptMessage => '你的作者名称或邮箱缺失。请在同步前在仓库设置中更新它们。';

  @override
  String get authorDetailsShowcasePrompt => '填写你的作者信息';

  @override
  String get goToSettings => '前往设置';

  @override
  String get onboardingSyncSettingsTitle => '同步设置';

  @override
  String get onboardingSyncSettingsSubtitle => '选择如何保持你的仓库同步。';

  @override
  String get onboardingAppSyncFeatureOpen => '应用打开时触发同步';

  @override
  String get onboardingAppSyncFeatureClose => '应用关闭时触发同步';

  @override
  String get onboardingAppSyncFeatureSelect => '选择要监控的应用';

  @override
  String get onboardingScheduledSyncFeatureFreq => '设置你喜欢的同步频率';

  @override
  String get onboardingScheduledSyncFeatureCustom => '在安卓上选择自定义间隔';

  @override
  String get onboardingScheduledSyncFeatureBg => '在后台运行';

  @override
  String get onboardingQuickSyncFeatureTile => '通过快速设置磁贴同步';

  @override
  String get onboardingQuickSyncFeatureShortcut => '通过应用快捷方式同步';

  @override
  String get onboardingQuickSyncFeatureWidget => '通过主屏幕小部件同步';

  @override
  String get onboardingOtherSyncFeatureAndroid => '安卓意图';

  @override
  String get onboardingOtherSyncFeatureIos => 'iOS 意图';

  @override
  String get onboardingOtherSyncDescription => '探索适合你平台的其他同步方式';

  @override
  String get onboardingTapToConfigure => '点击配置';

  @override
  String get showcaseGlobalSettingsTitle => '全局设置';

  @override
  String get showcaseGlobalSettingsSubtitle => '你的应用级偏好设置和工具。';

  @override
  String get showcaseGlobalSettingsFeatureTheme => '调整主题、语言和显示选项';

  @override
  String get showcaseGlobalSettingsFeatureBackup => '备份或恢复你的配置';

  @override
  String get showcaseGlobalSettingsFeatureSetup => '重新启动引导设置或界面导览';

  @override
  String get showcaseSyncProgressTitle => '同步状态';

  @override
  String get showcaseSyncProgressSubtitle => '一目了然地查看正在进行的操作。';

  @override
  String get showcaseSyncProgressFeatureWatch => '实时观看活跃的同步操作';

  @override
  String get showcaseSyncProgressFeatureConfirm => '同步成功完成时确认';

  @override
  String get showcaseSyncProgressFeatureErrors => '点击查看错误或打开日志查看器';

  @override
  String get showcaseAddMoreTitle => '你的仓库';

  @override
  String get showcaseAddMoreSubtitle => '在一个地方管理多个仓库。';

  @override
  String get showcaseAddMoreFeatureSwitch => '即时切换仓库仓库';

  @override
  String get showcaseAddMoreFeatureManage => '根据需要重命名或删除仓库';

  @override
  String get showcaseAddMoreFeaturePremium => '通过高级版添加更多仓库';

  @override
  String get showcaseControlTitle => '同步控制';

  @override
  String get showcaseControlSubtitle => '你的手动同步和提交工具。';

  @override
  String get showcaseControlFeatureSync => '一键触发手动同步';

  @override
  String get showcaseControlFeatureHistory => '查看最近的提交历史';

  @override
  String get showcaseControlFeatureConflicts => '出现合并冲突时解决它们';

  @override
  String get showcaseControlFeatureMore => '访问强制推送、强制拉取等功能';

  @override
  String get showcaseAutoSyncTitle => '自动同步';

  @override
  String get showcaseAutoSyncSubtitle => '自动保持你的仓库同步。';

  @override
  String get showcaseAutoSyncFeatureApp => '选定的应用打开或关闭时同步';

  @override
  String get showcaseAutoSyncFeatureSchedule => '计划定期后台同步';

  @override
  String get showcaseAutoSyncFeatureQuick => '通过快速磁贴、快捷方式或小部件同步';

  @override
  String get showcaseAutoSyncFeaturePremium => '通过高级版解锁增强同步频率';

  @override
  String get showcaseSetupGuideTitle => '设置与指南';

  @override
  String get showcaseSetupGuideSubtitle => '随时重新查看引导流程。';

  @override
  String get showcaseSetupGuideFeatureSetup => '从头重新运行引导设置';

  @override
  String get showcaseSetupGuideFeatureTour => '快速浏览界面亮点';

  @override
  String get showcaseRepoTitle => '你的仓库';

  @override
  String get showcaseRepoSubtitle => '管理此仓库的指挥中心。';

  @override
  String get showcaseRepoFeatureAuth => '与你的 Git 提供商认证';

  @override
  String get showcaseRepoFeatureDir => '切换或选择你的本地目录';

  @override
  String get showcaseRepoFeatureBrowse => '直接浏览和编辑文件';

  @override
  String get showcaseRepoFeatureRemote => '查看或更改远程 URL';

  @override
  String get onboardingClientMode => 'Client Mode';

  @override
  String get onboardingClientModeDescription => 'Everything you would expect from a git client';

  @override
  String get onboardingClientFeatureBranch => 'Branch management';

  @override
  String get onboardingClientFeatureCommit => 'Manual commit & push';

  @override
  String get onboardingClientFeatureDiff => 'Diff viewer';

  @override
  String get onboardingSyncMode => 'Sync Mode';

  @override
  String get onboardingSyncModeDescription => 'Automated file syncing in the background';

  @override
  String get onboardingSyncFeatureAutoCommit => 'Auto commit & push';

  @override
  String get onboardingSyncFeatureBackground => 'Background operation';

  @override
  String get onboardingSyncFeatureConflict => 'Easy conflict resolution';

  @override
  String get onboardingFileExplorer => 'File Explorer';

  @override
  String get onboardingBrowseFeatureHidden => 'View hidden files';

  @override
  String get onboardingBrowseFeatureLog => 'View git log';

  @override
  String get onboardingBrowseFeatureIgnore => 'Untrack and ignore files';

  @override
  String get onboardingCodeEditor => 'Code Editor';

  @override
  String get onboardingEditFeatureSyntax => 'Syntax highlighting';

  @override
  String get onboardingEditFeatureAutosave => 'Auto-saving';

  @override
  String get onboardingEditFeatureExperimental => 'Experimental feature';

  @override
  String get onboardingNotificationDescription => 'Notifications keep you informed about:';

  @override
  String get onboardingNotificationFeatureSync => 'Sync status updates';

  @override
  String get onboardingNotificationFeatureConflict => 'Merge conflict alerts';

  @override
  String get onboardingNotificationFeatureBug => 'Bug report notifications';

  @override
  String get onboardingNotificationDefault => 'All notifications are off by default.';

  @override
  String get onboardingFileAccessDescription => 'File access is required for:';

  @override
  String get onboardingFileAccessFeatureSync => 'Syncing your repository';

  @override
  String get onboardingFileAccessFeatureReadWrite => 'Reading and writing files';

  @override
  String get onboardingFileAccessFeatureDirectory => 'Accessing your selected directory';

  @override
  String get onboardingPremiumFeatures => 'Premium Features';

  @override
  String get onboardingWelcomeTitle => 'Effortless File Syncing';

  @override
  String get onboardingWelcomeDescWorks => 'Works\n';

  @override
  String get onboardingWelcomeDescBackground => 'in the background,\n';

  @override
  String get onboardingWelcomeDescYourWork => 'your work\n';

  @override
  String get onboardingWelcomeDescFocus => 'always in focus';

  @override
  String get onboardingChooseYourFocus => 'Choose your focus';

  @override
  String get onboardingChangeLaterInSettings => 'You can change this later in settings';

  @override
  String get onboardingBrowseEditTitle => 'Browse & Edit';

  @override
  String get onboardingBrowseEditSubtitle => 'Built-in tools for your files';

  @override
  String get onboardingAlmostThereTitle => 'Almost there!';

  @override
  String get onboardingAlmostThereSubtitle => 'Here\'s what\'s next:';

  @override
  String get onboardingStepAuthenticate => 'Authenticate with your Git provider';

  @override
  String get onboardingStepClone => 'Clone a repository to your device';

  @override
  String get onboardingStepSyncSettings => 'Configure your sync settings';

  @override
  String get onboardingStepWiki => 'Check the wiki if you need help';

  @override
  String get onboardingStepAllSet => 'Then you\'ll be all set!';

  @override
  String get onboardingAuthTitle => 'Authenticate';

  @override
  String get onboardingAuthSubtitle => 'Authenticate with your preferred git provider';

  @override
  String get onboardingLaunchWiki => 'Launch the wiki';

  @override
  String get currentBranch => '当前分支';

  @override
  String get detachedHead => '分离头指针';

  @override
  String get unbornBranch => 'Unborn Branch';

  @override
  String get commitsNotFound => '未找到提交…';

  @override
  String get repoNotFound => '未找到仓库…';

  @override
  String get committed => '已提交';

  @override
  String get additions => '%s ++';

  @override
  String get deletions => '%s --';

  @override
  String get modifyRemoteUrl => '修改远程 URL';

  @override
  String get modify => '修改';

  @override
  String get remoteUrl => '远程 URL';

  @override
  String get setRemoteUrl => '设置远程 URL';

  @override
  String get launchInBrowser => '在浏览器中打开';

  @override
  String get auth => '认证';

  @override
  String get openFileExplorer => '浏览与编辑';

  @override
  String get syncSettings => '同步设置';

  @override
  String get enableApplicationObserver => '应用同步设置';

  @override
  String get appSyncDescription => '选定的应用打开或关闭时自动同步';

  @override
  String get appSyncIosDescription => 'Automatically syncs when GitSync is opened or closed';

  @override
  String get iosAppSyncDocsLinkText => '其他应用打开/关闭时同步';

  @override
  String get accessibilityServiceDisclosureTitle => '无障碍服务声明';

  @override
  String get accessibilityServiceDisclosureMessage => '为了提升你的体验，\nGitSync 使用安卓的无障碍服务来检测应用何时打开或关闭。\n\n这有助于我们提供定制功能，而不会存储或共享任何数据。\n\n请在下一页启用 GitSync';

  @override
  String get search => '搜索';

  @override
  String get searchEllipsis => '搜索…';

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
  String get iosSyncOnAppClosed => 'GitSync关闭时同步';

  @override
  String get iosSyncOnAppOpened => 'GitSync打开时同步';

  @override
  String get scheduledSyncSettings => '计划同步设置';

  @override
  String get scheduledSyncDescription => '定期在后台自动同步';

  @override
  String get tabHome => 'Home';

  @override
  String get iosDefaultSyncRate => '当 iOS 允许时';

  @override
  String get every => 'every';

  @override
  String get scheduledSync => '计划同步';

  @override
  String get custom => '自定义';

  @override
  String get interval15min => '15 分钟';

  @override
  String get interval30min => '30 分钟';

  @override
  String get interval1hour => '1 小时';

  @override
  String get interval6hours => '6 小时';

  @override
  String get interval12hours => '12 小时';

  @override
  String get interval1day => '1 天';

  @override
  String get interval1week => '1 周';

  @override
  String get minutes => '分钟';

  @override
  String get hours => '小时';

  @override
  String get days => '天';

  @override
  String get weeks => '周';

  @override
  String get enhancedScheduledSync => '增强计划同步';

  @override
  String get quickSyncSettings => '快速同步设置';

  @override
  String get quickSyncDescription => '使用可自定义的快速磁贴、快捷方式或小部件进行同步';

  @override
  String get otherSyncSettings => '其他同步设置';

  @override
  String get useForTileSync => '用于同步磁贴';

  @override
  String get useForTileManualSync => '用于手动同步磁贴';

  @override
  String get useForShortcutSync => '用于同步快捷方式';

  @override
  String get useForShortcutManualSync => '用于手动同步快捷方式';

  @override
  String get useForWidgetSync => '用于同步小部件';

  @override
  String get useForWidgetManualSync => '用于手动同步小部件';

  @override
  String get selectYourGitProviderAndAuthenticate => '选择你的 Git 提供商并进行认证';

  @override
  String get oauthProviders => 'OAuth 提供商';

  @override
  String get gitProtocols => 'Git 协议';

  @override
  String get oauthNoAffiliation => '通过第三方认证；\n不代表任何关联或认可。';

  @override
  String get replacesExistingAuth => '替换现有\n仓库认证';

  @override
  String get oauth => 'OAuth';

  @override
  String get copyFromContainer => '从仓库复制';

  @override
  String get or => '或';

  @override
  String get enterPAT => '输入个人访问令牌';

  @override
  String get usePAT => '使用 PAT';

  @override
  String get oauthAllRepos => 'OAuth（所有仓库）';

  @override
  String get oauthScoped => 'OAuth（限定范围）';

  @override
  String get ensureTokenScope => '确保你的令牌包含 \"repo\" 范围以获得完整功能。';

  @override
  String get user => '用户';

  @override
  String get exampleUser => '张三123';

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
  String get passphrase => '密码短语';

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
  String get copiedText => '已复制文本！';

  @override
  String get confirmPrivKeyCopy => '确认复制私钥';

  @override
  String get confirmPrivKeyCopyMsg => '确定要将私钥复制到剪贴板吗？\n\n任何获得此密钥的人都可以控制你的账户。请确保只在安全位置粘贴，并在之后清除剪贴板。';

  @override
  String get understood => '明白了';

  @override
  String get importPrivateKey => '导入私钥';

  @override
  String get importPrivateKeyMsg => '在下方粘贴你的私钥以使用现有账户。\n\n请确保在安全环境中粘贴密钥，因为任何获得此密钥的人都可以控制你的账户。';

  @override
  String get importKey => '导入';

  @override
  String get cloneRepo => '克隆远程仓库';

  @override
  String get clone => '克隆';

  @override
  String get chooseHowToClone => '选择你想要克隆仓库的方式：';

  @override
  String get directCloningMsg => '直接克隆：将仓库克隆到选定的文件夹中';

  @override
  String get nestedCloningMsg => '嵌套克隆：在选定的文件夹内创建一个以仓库命名的新文件夹';

  @override
  String get directClone => '直接克隆';

  @override
  String get nestedClone => '嵌套克隆';

  @override
  String get gitRepoUrlHint => 'https://git.abc/xyz.git';

  @override
  String get invalidRepositoryUrlTitle => '无效的仓库 URL！';

  @override
  String get invalidRepositoryUrlMessage => '无效的仓库 URL！';

  @override
  String get cloneAnyway => '仍然克隆';

  @override
  String get iHaveALocalRepository => '我有一个本地仓库';

  @override
  String get cloningRepository => '正在克隆仓库…';

  @override
  String get cloneMessagePart1 => '不要退出此界面';

  @override
  String get cloneMessagePart2 => '根据仓库大小，这可能需要一些时间\n';

  @override
  String get selectCloneDirectory => '选择要克隆到的文件夹';

  @override
  String get confirmCloneOverwriteTitle => '文件夹不为空';

  @override
  String get confirmCloneOverwriteMsg => '你选择的文件夹已包含文件。克隆到其中将覆盖其内容。';

  @override
  String get confirmCloneOverwriteWarning => '此操作不可逆。';

  @override
  String get confirmCloneOverwriteAction => '覆盖';

  @override
  String get repoSearchLimits => '仓库搜索限制';

  @override
  String get repoSearchLimitsDescription => '仓库搜索仅检查 API 返回的前 100 个仓库，因此有时可能会遗漏你期望的仓库。\n\n如果想要的仓库没有出现在搜索结果中，请直接使用其 HTTPS 或 SSH URL 克隆。';

  @override
  String get advancedOptions => 'Advanced Options';

  @override
  String get shallowClone => 'Shallow Clone (Depth)';

  @override
  String get bareClone => 'Bare Clone';

  @override
  String get cloneDepthPlaceholder => 'full';

  @override
  String get repositorySettings => '仓库设置';

  @override
  String get settings => '设置';

  @override
  String get signedCommitsLabel => '签名提交';

  @override
  String get signedCommitsDescription => '签名提交以验证你的身份';

  @override
  String get importCommitKey => '导入密钥';

  @override
  String get commitKeyImported => '密钥已导入';

  @override
  String get useSshKey => '使用认证密钥进行提交签名';

  @override
  String get syncMessageLabel => '同步信息';

  @override
  String get defaultSyncMessageLabel => 'Default Sync Message';

  @override
  String get syncMessageDescription => '使用 %s 表示日期和时间';

  @override
  String get syncMessageTimeFormatLabel => '同步信息时间格式';

  @override
  String get defaultSyncMessageTimeFormatLabel => 'Default Sync Message Time Format';

  @override
  String get syncMessageTimeFormatDescription => '使用标准日期时间格式语法';

  @override
  String get remoteLabel => '默认远程';

  @override
  String get defaultRemote => 'origin';

  @override
  String get authorNameLabel => '作者名称';

  @override
  String get defaultAuthorNameLabel => 'default author name';

  @override
  String get authorNameDescription => '用于在提交历史中标识你';

  @override
  String get authorName => '张三123';

  @override
  String get authorEmailLabel => '作者邮箱';

  @override
  String get defaultAuthorEmailLabel => 'default author email';

  @override
  String get authorEmailDescription => '附加到你的提交以表明作者身份';

  @override
  String get authorEmail => 'zhangsan@example.com';

  @override
  String get postFooterLabel => 'post footer';

  @override
  String get postFooterDescription => 'appended to issues, comments, and pull requests you create';

  @override
  String get postFooterDialogInfo =>
      'This text is automatically appended to the end of issues, comments, and pull requests you create. You can change or remove it in your repository settings.\n\nThe default for new repositories can be set in Global Settings under Repository Defaults.';

  @override
  String get gitIgnore => '.gitignore';

  @override
  String get gitIgnoreDescription => '列出要在所有设备上忽略的文件或文件夹';

  @override
  String get gitIgnoreHint => '.trash/\n./…';

  @override
  String get gitInfoExclude => '.git/info/exclude';

  @override
  String get gitInfoExcludeDescription => '列出要在此设备上忽略的文件或文件夹';

  @override
  String get gitInfoExcludeHint => '.trash/\n./…';

  @override
  String get disableSsl => '禁用 SSL';

  @override
  String get disableSslDescription => '为 HTTP 仓库禁用安全连接';

  @override
  String get disableSslPromptTitle => '禁用 SSL？';

  @override
  String get disableSslPromptMsg => '你克隆的地址以 \"http\" 开头（不安全）。禁用 SSL 将匹配 URL 但会降低安全性。';

  @override
  String get optimisedSync => '优化同步';

  @override
  String get optimisedSyncDescription => '智能减少总体同步操作';

  @override
  String get proceedAnyway => '仍然继续？';

  @override
  String get moreOptions => '更多选项';

  @override
  String get untrackAll => '取消追踪所有';

  @override
  String get globalSettings => '全局设置';

  @override
  String get darkMode => '深色\n模式';

  @override
  String get lightMode => '浅色\n模式';

  @override
  String get system => '系统';

  @override
  String get language => '语言';

  @override
  String get browseEditDir => '浏览与编辑目录';

  @override
  String get enableLineWrap => '在编辑器中启用自动换行';

  @override
  String get excludeFromRecents => '从最近使用中排除';

  @override
  String get backupRestoreTitle => '加密配置恢复';

  @override
  String get encryptedBackup => '加密备份';

  @override
  String get encryptedRestore => '加密恢复';

  @override
  String get backup => '备份';

  @override
  String get restore => '恢复';

  @override
  String get selectBackupLocation => '选择备份保存位置';

  @override
  String get backupFileTemplate => 'backup_%s.gsbak';

  @override
  String get enterPassword => '输入 %s 密码';

  @override
  String get invalidPassword => '密码无效';

  @override
  String get community => '社区';

  @override
  String get guides => '指南';

  @override
  String get documentation => '指南与维基';

  @override
  String get viewDocumentation => '查看指南与维基';

  @override
  String get requestAFeature => '请求功能';

  @override
  String get contributeTitle => '支持我们的工作';

  @override
  String get improveTranslations => '改进翻译';

  @override
  String get joinTheDiscussion => '加入 Discord';

  @override
  String get noLogFilesFound => '未找到日志文件！';

  @override
  String get guidedSetup => '引导设置';

  @override
  String get uiGuide => '界面指南';

  @override
  String get viewPrivacyPolicy => '隐私政策';

  @override
  String get viewEula => '使用条款（EULA）';

  @override
  String get shareLogs => '分享日志';

  @override
  String get logsEmailSubjectTemplate => 'GitSync 日志 (%s)';

  @override
  String get logsEmailRecipient => 'bugsviscouspotential@gmail.com';

  @override
  String get repositoryDefaults => '仓库默认值';

  @override
  String get miscellaneous => '其他';

  @override
  String get dangerZone => '危险区域';

  @override
  String get file => '文件';

  @override
  String get folder => '文件夹';

  @override
  String get directory => '目录';

  @override
  String get confirmFileDirDeleteMsg => '确定要删除 %s \"%s\" %s吗？';

  @override
  String get deleteMultipleSuffix => '以及另外 %s 个项目及其内容';

  @override
  String get deleteSingularSuffix => '及其内容';

  @override
  String get createAFile => '创建文件';

  @override
  String get fileName => '文件名';

  @override
  String get createADir => '创建目录';

  @override
  String get dirName => '文件夹名称';

  @override
  String get renameFileDir => '重命名 %s';

  @override
  String get fileTooLarge => '文件超过 %s 行';

  @override
  String get readOnly => '只读';

  @override
  String get cut => '剪切';

  @override
  String get copy => '复制';

  @override
  String get paste => '粘贴';

  @override
  String get experimental => '实验性';

  @override
  String get experimentalMsg => '使用风险自负';

  @override
  String get codeEditorLimits => '代码编辑器限制';

  @override
  String get codeEditorLimitsDescription => '代码编辑器提供基本、实用的编辑功能，但尚未针对极端情况或重度使用进行全面测试。\n\n如果你遇到错误或想建议功能，欢迎反馈！请使用全局设置中的错误报告或功能请求选项，或在下方操作。';

  @override
  String get openFile => '打开文件';

  @override
  String get openFileDescription => '预览/编辑文件内容';

  @override
  String get viewGitLog => '查看 git 日志';

  @override
  String get viewGitLogDescription => '查看完整的 git 日志历史';

  @override
  String get ignoreUntrack => '.gitignore + 取消追踪';

  @override
  String get ignoreUntrackDescription => '将文件添加到 .gitignore 并取消追踪';

  @override
  String get excludeUntrack => '.git/info/exclude + 取消追踪';

  @override
  String get excludeUntrackDescription => '将文件添加到本地排除文件并取消追踪';

  @override
  String get ignoreOnly => '仅添加到 .gitignore';

  @override
  String get ignoreOnlyDescription => '仅将文件添加到 .gitignore';

  @override
  String get excludeOnly => '仅添加到 .git/info/exclude';

  @override
  String get excludeOnlyDescription => '仅将文件添加到本地排除文件';

  @override
  String get untrack => '取消追踪文件';

  @override
  String get untrackDescription => '取消追踪指定文件';

  @override
  String get selected => '已选择';

  @override
  String get ignoreAndUntrack => '忽略并取消追踪';

  @override
  String get open => '打开';

  @override
  String get fileDiff => '文件差异';

  @override
  String get openEditFile => '打开/编辑文件';

  @override
  String get filesChanged => '个文件已更改';

  @override
  String get commits => '提交';

  @override
  String get defaultContainerName => '别名';

  @override
  String get renameRepository => '重命名仓库';

  @override
  String get renameRepositoryMsg => '输入仓库仓库的新别名';

  @override
  String get addMore => '添加更多';

  @override
  String get addRepository => '添加仓库';

  @override
  String get addRepositoryMsg => '为你的新仓库仓库起一个独特的别名。这将帮助你以后识别它。';

  @override
  String get confirmRepositoryDelete => '确认删除仓库';

  @override
  String get confirmRepositoryDeleteMsg => '确定要删除仓库仓库 \"%s\" 吗？';

  @override
  String get deleteRepoDirectoryCheckbox => '同时删除仓库目录及其所有内容';

  @override
  String get confirmRepositoryDeleteTitle => '确认删除仓库';

  @override
  String get confirmRepositoryDeleteMessage => '确定要删除仓库 \"%s\" 及其内容吗？';

  @override
  String get submodulesFoundTitle => '发现子模块';

  @override
  String get submodulesFoundMessage => '你添加的仓库包含子模块。你想自动将它们作为单独的仓库添加到应用中吗？\n\n这是高级版功能。';

  @override
  String get submodulesFoundAction => '添加子模块';

  @override
  String get addRemote => '添加远程';

  @override
  String get deleteRemote => '删除远程';

  @override
  String get renameRemote => '重命名远程';

  @override
  String get remoteName => '远程名称';

  @override
  String get confirmDeleteRemote => '确定要删除远程 \"%s\" 吗？';

  @override
  String get orEnterManually => 'or enter manually';

  @override
  String get createOnProvider => 'Create on %s';

  @override
  String get confirmBranchCheckoutTitle => '检出分支？';

  @override
  String get confirmBranchCheckoutMsgPart1 => '确定要检出分支 ';

  @override
  String get confirmBranchCheckoutMsgPart2 => ' 吗？';

  @override
  String get unsavedChangesMayBeLost => '未保存的更改可能会丢失。';

  @override
  String get checkout => '检出';

  @override
  String get create => '创建';

  @override
  String get createBranch => '创建新分支';

  @override
  String get createBranchName => '分支名称';

  @override
  String get createBranchBasedOn => '基于';

  @override
  String get renameBranch => 'Rename Branch';

  @override
  String get deleteBranch => 'Delete Branch?';

  @override
  String get confirmDeleteBranchMsg => 'Are you sure you want to delete the branch \"%s\"?';

  @override
  String get menuAmendCommit => 'Amend Commit';

  @override
  String get menuAmendCommitDesc => 'Modify the most recent commit message or contents';

  @override
  String get menuUndoCommit => 'Undo Commit';

  @override
  String get menuUndoCommitDesc => 'Undo this commit but keep the changes staged';

  @override
  String get menuResetToCommit => 'Reset to Commit';

  @override
  String get menuResetToCommitDesc => 'Discard all commits after this one';

  @override
  String get menuCheckoutCommit => 'Checkout Commit';

  @override
  String get menuCheckoutCommitDesc => 'Check out this commit (detached HEAD)';

  @override
  String get menuRevertCommit => 'Revert Commit Changes';

  @override
  String get menuRevertCommitDesc => 'Create a new commit that undoes these changes';

  @override
  String get menuCreateBranch => 'Create Branch from Commit';

  @override
  String get menuCreateBranchDesc => 'Create a new branch from this commit';

  @override
  String get menuCreateTag => 'Create Tag';

  @override
  String get menuCreateTagDesc => 'Create a tag on this commit';

  @override
  String get menuCherryPick => 'Cherry Pick Commit';

  @override
  String get menuCherryPickDesc => 'Apply this commit onto the current branch';

  @override
  String get menuSelectCommits => 'Select Commits';

  @override
  String get menuSelectCommitsDesc => 'Select multiple commits for batch operations';

  @override
  String get menuCopySha => 'Copy SHA';

  @override
  String get menuCopyShaDesc => 'Copy the full commit hash to clipboard';

  @override
  String get menuCopyTag => 'Copy Tag';

  @override
  String get menuCopyTagDesc => 'Copy the tag name to clipboard';

  @override
  String get menuViewOnProvider => 'View on %s';

  @override
  String get menuViewOnProviderDesc => 'Open this commit in your browser';

  @override
  String get createBranchFromCommit => 'Create Branch from Commit';

  @override
  String get createBranchFromCommitMsg => 'Create a new branch starting at commit %s.';

  @override
  String get checkoutCommit => 'Checkout Commit';

  @override
  String get checkoutCommitMsg => 'This will put you in a detached HEAD state at commit';

  @override
  String get checkoutCommitDetachedWarning => 'You will not be on any branch. Create a new branch to keep your changes.';

  @override
  String get createTagOnCommit => 'Create Tag';

  @override
  String get createTagOnCommitMsg => 'Create a tag on commit %s.';

  @override
  String get tagName => 'Tag Name';

  @override
  String get revertCommit => 'Revert Commit';

  @override
  String get revertCommitMsg => 'Revert the changes introduced by commit';

  @override
  String get revertCommitWarning => 'This will create a new commit that undoes the changes.';

  @override
  String get revert => 'Revert';

  @override
  String get amendCommit => 'Amend Commit';

  @override
  String get amendCommitMsg => 'Edit the message for commit';

  @override
  String get amendCommitWarning => 'This will rewrite the commit. A force push may be required if this commit has already been pushed.';

  @override
  String get amend => 'Amend';

  @override
  String get undoCommit => 'Undo Commit';

  @override
  String get undoCommitMsg => 'Undo commit';

  @override
  String get undoCommitWarning => 'The commit will be removed but your changes will remain staged.';

  @override
  String get undo => 'Undo';

  @override
  String get resetToCommit => 'Reset to Commit';

  @override
  String get resetToCommitMsg => 'Reset to commit';

  @override
  String get resetToCommitWarning =>
      'All commits after this one will be permanently lost and working directory changes will be discarded. This cannot be undone.';

  @override
  String get reset => 'Reset';

  @override
  String get cherryPickCommit => 'Cherry Pick Commit';

  @override
  String get cherryPickCommitMsg => 'Apply the changes from commit';

  @override
  String get cherryPickCommitWarning => 'This may produce merge conflicts if the changes overlap with the target branch.';

  @override
  String get cherryPickTargetBranch => 'Target Branch';

  @override
  String get cherryPick => 'Cherry Pick';

  @override
  String get cherryPickCommits => 'Cherry Pick Commits';

  @override
  String get cherryPickCommitsMsg => 'Apply changes from %s commits onto';

  @override
  String get cherryPickCommitsWarning => 'Commits will be applied in chronological order. Conflicts may occur at each step.';

  @override
  String get squashCommits => 'Squash Commits';

  @override
  String get squashCommitsMsg => 'Combine %s commits into a single commit';

  @override
  String get squashCommitsWarning => 'This rewrites commit history. If these commits have been pushed, a force push will be required.';

  @override
  String get squash => 'Squash';

  @override
  String get squashCommitMessage => 'Squash Message';

  @override
  String get selectCommits => 'Select Commits';

  @override
  String get selectedCount => '%s selected';

  @override
  String get squashRequiresConsecutive => 'Squash requires consecutive commits from the latest commit';

  @override
  String get issues => 'Issues';

  @override
  String get issueFilterOpen => 'Open';

  @override
  String get issueFilterClosed => 'Closed';

  @override
  String get issueFilterAll => 'All';

  @override
  String get issuesNotFound => 'No issues found…';

  @override
  String get filterAuthor => 'Author';

  @override
  String get filterLabels => 'Labels';

  @override
  String get filterAssignee => 'Assignee';

  @override
  String get filterMilestone => 'Milestone';

  @override
  String get filterProject => 'Project';

  @override
  String get filterNone => 'None';

  @override
  String get filterMilestonesEmpty => 'No milestones found';

  @override
  String get filterProjectsEmpty => 'No projects found';

  @override
  String get sortNewest => 'Newest';

  @override
  String get sortOldest => 'Oldest';

  @override
  String get sortMostCommented => 'Most commented';

  @override
  String get sortRecentlyUpdated => 'Recently updated';

  @override
  String get filterSidebar => 'Filters';

  @override
  String get filterReviewer => 'Reviewer';

  @override
  String get pullRequests => 'Pull Requests';

  @override
  String get pullRequestsNotFound => 'No pull requests found…';

  @override
  String get tags => 'Tags';

  @override
  String get tagsNotFound => 'No tags found…';

  @override
  String get releases => 'Releases';

  @override
  String get releasesNotFound => 'No releases found…';

  @override
  String get preRelease => 'PRE-RELEASE';

  @override
  String get draft => 'DRAFT';

  @override
  String get releaseAssets => 'Assets';

  @override
  String get noAssets => 'No assets';

  @override
  String get actions => 'Actions';

  @override
  String get actionsNotFound => 'No actions found…';

  @override
  String get actionFilterAll => 'All';

  @override
  String get actionFilterSuccess => 'Success';

  @override
  String get actionFilterFailed => 'Failed';

  @override
  String get attemptAutoFix => '尝试自动修复？';

  @override
  String get troubleshooting => '故障排除';

  @override
  String get youreOffline => '你处于离线状态。';

  @override
  String get someFeaturesMayNotWork => '某些功能可能无法使用。';

  @override
  String get unsupportedGitAttributes => '此仓库使用了仅商店版本支持的 Git 功能。';

  @override
  String get tapToOpenPlayStore => '点击更新。';

  @override
  String get ongoingMergeConflict => '正在进行合并冲突';

  @override
  String get networkStallRetry => '网络较差 — 稍后将重试';

  @override
  String get networkUnavailableRetry => '网络不可用！\nGitSync 将在重新连接后重试';

  @override
  String get failedToResolveAddressMessage => '无法连接到服务器。请检查你的网络连接或验证仓库 URL 是否正确。';

  @override
  String get pullFailed => '拉取失败！请检查是否有未提交的更改，然后重试。';

  @override
  String get reportABug => '报告错误';

  @override
  String get errorOccurredTitle => '发生错误！';

  @override
  String get errorOccurredMessagePart1 => '如果这造成了任何问题，请使用下面的按钮快速创建错误报告。';

  @override
  String get errorOccurredMessagePart2 => '否则，你可以长按复制到剪贴板或忽略并继续。';

  @override
  String get cloneFailed => '克隆仓库失败！';

  @override
  String get mergingExceptionMessage => '合并中';

  @override
  String get fieldCannotBeEmpty => '字段不能为空';

  @override
  String get androidLimitedFilepathCharacters => '此问题是由于安卓文件命名限制造成的。请在其他设备上重命名受影响的文件，然后重新同步。\n\n不支持的字符：\" * / : < > ? \\ |';

  @override
  String get emptyNameOrEmail => '你的 Git 配置缺少作者名称或邮箱地址。请更新设置以包含你的作者名称和邮箱。';

  @override
  String get errorReadingZlibStream => '这是特定设备的已知问题，可以通过使用最后一个旧版应用来修复。请下载它以继续使用，尽管某些功能可能受限';

  @override
  String get gitObsidianFoundTitle => 'Obsidian Git 警告';

  @override
  String get gitObsidianFoundMessage => '此仓库似乎包含启用了 Obsidian Git 插件的 Obsidian 仓库。\n\n请在此设备上禁用该插件以避免冲突！有关该过程的更多详细信息可以在链接的文档中找到。';

  @override
  String get gitObsidianFoundAction => '查看文档';

  @override
  String get githubIssueOauthTitle => '连接 GitHub 以自动报告';

  @override
  String get githubIssueOauthMsg => '你需要连接 GitHub 账户才能报告错误并跟踪其进度。\n你可以随时在全局设置中重置此连接。';

  @override
  String get includeLogs => '包含日志文件';

  @override
  String get issueReportTitleTitle => '标题';

  @override
  String get issueReportTitleDesc => '用几个词概括问题';

  @override
  String get issueReportDescTitle => '描述';

  @override
  String get issueReportDescDesc => '更详细地解释发生了什么';

  @override
  String get issueReportMinimalReproTitle => '复现步骤';

  @override
  String get issueReportMinimalReproDesc => '描述导致错误的操作步骤';

  @override
  String get includeLogFiles => '包含日志文件';

  @override
  String get includeLogFilesDescription =>
      '强烈建议在错误报告中包含日志文件，因为它们可以大大加快诊断根本原因的速度。\n如果你选择禁用\"包含日志文件\"，请将相关日志摘录复制并粘贴到你的报告中，以便我们复现问题。你可以使用眼睛图标在发送前查看日志，确认没有敏感信息。\n\n包含日志是可选的，不是强制的。';

  @override
  String get report => '报告';

  @override
  String get issueReportSuccessTitle => '问题报告成功';

  @override
  String get issueReportSuccessMsg => '你的问题已报告。收藏此页面以跟踪进度和回复消息。\n\n请避免创建重复问题，因为这会使解决变得更加困难。\n\n7 天无活动的问题将自动关闭。';

  @override
  String get trackIssue => '跟踪问题并回复消息';

  @override
  String get createNewRepository => '创建新仓库';

  @override
  String get noGitRepoFoundMsg => '在选定的文件夹中未找到 git 仓库。你想在这里创建一个新的吗？';

  @override
  String get remoteSetupLaterMsg => '你可以稍后设置远程以与服务器同步。';

  @override
  String get localOnlyNoRemote => '仅本地 — 添加远程以同步';

  @override
  String get noRemoteConfigured => '未配置远程';

  @override
  String get createRemoteRepo => 'Create Remote Repository';

  @override
  String get repoName => 'Repository Name';

  @override
  String get repoPublic => 'Public';

  @override
  String get repoPrivate => 'Private';

  @override
  String get creatingRemoteRepo => 'Creating remote repository...';

  @override
  String get remoteRepoCreated => 'Remote repository created and linked as origin';

  @override
  String get remoteRepoCreateFailed => 'Failed to create remote repository';

  @override
  String get noRemoteDetectedMsg => 'This repository has no remote configured. Would you like to create one?';

  @override
  String get createAndLinkRemote => 'Create & Link Remote';

  @override
  String get createLocalOnly => 'Local Only';

  @override
  String get initMainBranch => 'Initialize main branch';

  @override
  String get continueLabel => 'Continue';

  @override
  String get githubScopedLoginTitle => 'Step 1: Sign In to GitHub';

  @override
  String get githubScopedLoginMsg =>
      'You\'ll be redirected to GitHub to sign in.\n\nLog in with the account that has access to your repositories, then authorize GitSync.';

  @override
  String get githubScopedRepoTitle => 'Step 2: Select Repositories';

  @override
  String get githubScopedRepoMsg => 'Choose which repositories GitSync can access.\n\nWhen finished, close the browser to return to the app.';

  @override
  String get issueDescription => 'Description';

  @override
  String get issueNoDescription => 'No description provided';

  @override
  String get issueComments => 'Comments';

  @override
  String get issueNoComments => 'No comments yet';

  @override
  String get issueAddComment => 'Add a comment…';

  @override
  String get issueSubmitComment => 'Submit';

  @override
  String get issueCloseIssue => 'Close Issue';

  @override
  String get issueReopenIssue => 'Reopen Issue';

  @override
  String get issueAddReaction => 'Add Reaction';

  @override
  String get issueWriteDisabled => 'You do not have write access';

  @override
  String get issueStateUpdated => 'Issue state updated';

  @override
  String get issueCommentAdded => 'Comment added';

  @override
  String get issueCommentFailed => 'Failed to add comment';

  @override
  String get issueStateUpdateFailed => 'Failed to update issue state';

  @override
  String get issueReactionFailed => 'Failed to update reaction';

  @override
  String get issuePreview => 'Preview';

  @override
  String get issueWrite => 'Write';

  @override
  String get issueEditSuccess => 'Issue updated';

  @override
  String get issueEditFailed => 'Failed to update issue';

  @override
  String get createIssue => 'Create Issue';

  @override
  String get createIssueTitle => 'Title';

  @override
  String get createIssueTitleHint => 'Issue title';

  @override
  String get createIssueBody => 'Description';

  @override
  String get createIssueBodyHint => 'Describe the issue…';

  @override
  String get createIssueSubmit => 'Submit Issue';

  @override
  String get createIssueSuccess => 'Issue created successfully';

  @override
  String get createIssueFailed => 'Failed to create issue';

  @override
  String get createIssueBlankIssue => 'Blank Issue';

  @override
  String get createIssueSelectTemplate => 'Choose a template';

  @override
  String get createIssueRequired => 'Required';

  @override
  String get createPr => 'Create Pull Request';

  @override
  String get createPrTitle => 'Title';

  @override
  String get createPrTitleHint => 'Pull request title';

  @override
  String get createPrBody => 'Description';

  @override
  String get createPrBodyHint => 'Describe your changes…';

  @override
  String get createPrSubmit => 'Create Pull Request';

  @override
  String get createPrSuccess => 'Pull request created';

  @override
  String get createPrFailed => 'Failed to create pull request';

  @override
  String get createPrBaseBranch => 'Base';

  @override
  String get createPrHeadBranch => 'Compare';

  @override
  String get createPrSelectBranch => 'Select branch';

  @override
  String get prDescription => 'Description';

  @override
  String get prNoDescription => 'No description provided';

  @override
  String get prActivity => 'Activity';

  @override
  String get prNoActivity => 'No activity yet';

  @override
  String get prCommits => 'Commits';

  @override
  String get prCommitsNotFound => 'No commits found';

  @override
  String get prChecks => 'Checks';

  @override
  String get prChecksNotFound => 'No checks found';

  @override
  String get prAllChecksPassed => 'All checks passed';

  @override
  String prChecksFailed(Object count) {
    return '$count check(s) failed';
  }

  @override
  String get prChecksPending => 'Checks pending';

  @override
  String get prFilesChanged => 'Files Changed';

  @override
  String get prFilesChangedNotFound => 'No changed files found';

  @override
  String get prConversation => 'Conversation';

  @override
  String get prApproved => 'Approved';

  @override
  String get prChangesRequested => 'Changes Requested';

  @override
  String get prCommented => 'Commented';

  @override
  String get prNotFound => 'Pull request not found';

  @override
  String get prCommentAdded => 'Comment added';

  @override
  String get prCommentFailed => 'Failed to add comment';

  @override
  String get prReactionFailed => 'Failed to update reaction';

  @override
  String get prMentionedInPr => 'mentioned this in pull request';

  @override
  String get prMentionedInIssue => 'mentioned this in issue';

  @override
  String prForcePushed(Object after, Object before) {
    return 'force-pushed from $before to $after';
  }

  @override
  String get recentCommits => 'Recent Commits';

  @override
  String get branchManagement => 'Branch Management';

  @override
  String get providerTools => 'Provider Tools';

  @override
  String get tabChat => 'Chat';

  @override
  String get tabFiles => 'Files';

  @override
  String get chatComingSoon => 'Chat features coming soon';

  @override
  String get chatComingSoonSubtitle => 'Interact with your files using Claude Code';

  @override
  String get noRepoSetup => 'Set up a repository first';

  @override
  String get enableAiFeatures => 'Enable AI Features';

  @override
  String get hideAiFeatures => 'Hide AI Features';

  @override
  String get hideAiFeaturesConfirmTitle => 'Hide AI Features?';

  @override
  String get hideAiFeaturesConfirmMsg =>
      'This will remove the AI tab and all AI buttons throughout the app. You can re-enable AI features anytime from Global Settings.';

  @override
  String get aiSetupTitle => 'Set Up AI';

  @override
  String get aiSetupMsg => 'Configure an AI provider to use this feature. Go to AI settings?';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get iosAppSyncDocsLinkText => '其他應用程式開啟/關閉時同步';
}
