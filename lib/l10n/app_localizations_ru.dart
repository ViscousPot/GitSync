// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get dismiss => 'Закрыть';

  @override
  String get skip => 'Пропустить';

  @override
  String get done => 'Готово';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get ok => 'ОК';

  @override
  String get select => 'Выбрать';

  @override
  String get cancel => 'Отмена';

  @override
  String get learnMore => 'Узнать больше';

  @override
  String get loadingElipsis => 'Загрузка…';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get finish => 'Finish';

  @override
  String get rename => 'Переименовать';

  @override
  String get add => 'Добавить';

  @override
  String get delete => 'Удалить';

  @override
  String get optionalLabel => '(optional)';

  @override
  String get ios => 'iOS';

  @override
  String get android => 'Android';

  @override
  String get syncStarting => 'Обнаружение изменений…';

  @override
  String get syncStartPull => 'Синхронизация изменений…';

  @override
  String get syncStartPush => 'Синхронизация локальных изменений…';

  @override
  String get syncNotRequired => 'Синхронизация не требуется!';

  @override
  String get syncComplete => 'Репозиторий синхронизирован!';

  @override
  String get syncInProgress => 'Sync In Progress';

  @override
  String get syncScheduled => 'Sync Scheduled';

  @override
  String get detectingChanges => 'Detecting Changes…';

  @override
  String get thisActionCannotBeUndone => 'Это действие нельзя отменить.';

  @override
  String get cloneProgressLabel => 'прогресс клонирования';

  @override
  String get forcePushProgressLabel => 'прогресс принудительной отправки';

  @override
  String get forcePullProgressLabel => 'прогресс принудительного получения';

  @override
  String get moreSyncOptionsLabel => 'дополнительные параметры синхронизации';

  @override
  String get repositorySettingsLabel => 'настройки репозитория';

  @override
  String get addBranchLabel => 'добавить ветку';

  @override
  String get deselectDirLabel => 'снять выделение с папки';

  @override
  String get selectDirLabel => 'выбрать папку';

  @override
  String get syncMessagesLabel => 'отключить/включить сообщения синхронизации';

  @override
  String get backLabel => 'назад';

  @override
  String get authDropdownLabel => 'меню авторизации';

  @override
  String get premiumDialogTitle => 'Разблокировать Премиум';

  @override
  String get premiumDialogMessage =>
      'Эта функция является частью премиум-опыта.\nСделайте разовый платеж %s, чтобы разблокировать её и наслаждаться более мощными инструментами.\n\nПремиум-функции:\n • Поддержка нескольких репозиториев\n\nВ качестве альтернативы подключите свою учетную запись GitHub, чтобы проверить, являетесь ли вы спонсором GitHub.';

  @override
  String get premiumDialogButtonText => 'Разблокировать за %s';

  @override
  String get premiumDialogGitHubButtonText => 'Использовать GitHub Sponsors';

  @override
  String get restorePurchase => 'Восстановить покупку';

  @override
  String get verifyGhSponsorTitle => 'Подтвердить спонсорство GitHub';

  @override
  String get verifyGhSponsorMsg =>
      'Если вы являетесь спонсором GitHub, вы можете получить доступ к премиум-функциям бесплатно. Авторизуйтесь через GitHub, чтобы мы могли проверить ваш статус спонсора.';

  @override
  String get verifyGhSponsorNote => 'Примечание: новые спонсорства могут стать доступными в приложении в течение 1 дня.';

  @override
  String get switchToClientMode => 'Switch to Client Mode…';

  @override
  String get switchToSyncMode => 'Switch to Sync Mode…';

  @override
  String get clientMode => 'Client Mode';

  @override
  String get clientModeDescription => 'Expanded Git UI\n(Advanced)';

  @override
  String get syncMode => 'Sync Mode';

  @override
  String get syncModeDescription => 'Automated syncing\n(Beginner-friendly)';

  @override
  String get syncNow => 'Синхронизировать изменения';

  @override
  String get syncAllChanges => 'Sync All Changes';

  @override
  String get stageAndCommit => 'Stage & Commit';

  @override
  String get downloadChanges => 'Download Changes';

  @override
  String get uploadChanges => 'Upload Changes';

  @override
  String get downloadAndOverwrite => 'Download + Overwrite';

  @override
  String get uploadAndOverwrite => 'Upload + Overwrite';

  @override
  String get fetchRemote => 'Fetch %s';

  @override
  String get pullChanges => 'Получить изменения';

  @override
  String get pushChanges => 'Отправить изменения';

  @override
  String get updateSubmodules => 'Update Submodules';

  @override
  String get forcePush => 'Принудительная отправка';

  @override
  String get forcePushing => 'Принудительная отправка…';

  @override
  String get confirmForcePush => 'Подтвердить принудительную отправку';

  @override
  String get confirmForcePushMsg => 'Вы уверены, что хотите принудительно отправить эти изменения? Все текущие конфликты слияния будут прерваны.';

  @override
  String get forcePull => 'Принудительное получение';

  @override
  String get forcePulling => 'Принудительное получение…';

  @override
  String get confirmForcePull => 'Подтвердить принудительное получение';

  @override
  String get confirmForcePullMsg =>
      'Вы уверены, что хотите принудительно получить эти изменения? Все текущие конфликты слияния будут проигнорированы.';

  @override
  String get localHistoryOverwriteWarning => 'Это действие перезапишет локальную историю и не может быть отменено.';

  @override
  String get forcePushPullMessage => 'Пожалуйста, не закрывайте и не выходите из приложения до завершения процесса.';

  @override
  String get manualSync => 'Ручная синхронизация';

  @override
  String get manualSyncMsg => 'Выберите файлы, которые вы хотите синхронизировать';

  @override
  String get commit => 'Commit';

  @override
  String get unstage => 'Unstage';

  @override
  String get stage => 'Stage';

  @override
  String get selectAll => 'Выбрать все';

  @override
  String get deselectAll => 'Снять выделение со всех';

  @override
  String get noUncommittedChanges => 'Нет незафиксированных изменений';

  @override
  String get discardChanges => 'Отменить изменения';

  @override
  String get discardChangesTitle => 'Отменить изменения?';

  @override
  String get discardChangesMsg => 'Вы уверены, что хотите отменить все изменения в \"%s\"?';

  @override
  String get mergeConflictItemMessage => 'Есть конфликт слияния! Нажмите для разрешения';

  @override
  String get mergeConflict => 'Конфликт слияния';

  @override
  String get mergeDialogMessage => 'Используйте редактор для разрешения конфликтов слияния';

  @override
  String get commitMessage => 'Сообщение коммита';

  @override
  String get abortMerge => 'Прервать слияние';

  @override
  String get keepChanges => 'Сохранить изменения';

  @override
  String get local => 'Локальные';

  @override
  String get both => 'Оба';

  @override
  String get remote => 'Удаленные';

  @override
  String get merge => 'Слияние';

  @override
  String get merging => 'Слияние…';

  @override
  String get resolvingMerge => 'Разрешение слияния…';

  @override
  String get iosClearDataTitle => 'Is this a fresh install?';

  @override
  String get iosClearDataMsg =>
      'We detected that this might be a reinstallation, but it could also be a false alarm. On iOS, your Keychain isn’t cleared when you delete and reinstall the app, so some data may still be stored securely.\n\nIf this isn’t a fresh install, or you don’t want to reset, you can safely skip this step.';

  @override
  String get clearDataConfirmTitle => 'Confirm App Data Reset';

  @override
  String get clearDataConfirmMsg => 'This will permanently delete all app data, including Keychain entries. Are you sure you want to proceed?';

  @override
  String get iosClearDataAction => 'Clear All Data';

  @override
  String get legacyAppUserDialogTitle => 'Добро пожаловать в новую версию!';

  @override
  String get legacyAppUserDialogMessagePart1 => 'Мы полностью перестроили приложение для лучшей производительности и будущего роста.';

  @override
  String get legacyAppUserDialogMessagePart2 =>
      'К сожалению, ваши старые настройки не могут быть перенесены, поэтому вам нужно будет настроить все заново.\n\nВсе ваши любимые функции по-прежнему здесь. Поддержка нескольких репозиториев теперь является частью небольшого разового обновления, которое помогает поддерживать дальнейшую разработку.';

  @override
  String get legacyAppUserDialogMessagePart3 => 'Спасибо, что остаетесь с нами :)';

  @override
  String get setUp => 'Настроить';

  @override
  String get welcome => 'Добро пожаловать!';

  @override
  String get welcomeMessage => 'Похоже, вы здесь впервые.\n\nХотели бы вы пройти быструю настройку для начала работы?';

  @override
  String get welcomePositive => 'Поехали';

  @override
  String get welcomeNeutral => 'Пропустить';

  @override
  String get welcomeNegative => 'Я знаком';

  @override
  String get notificationDialogTitle => 'Включить уведомления';

  @override
  String get notificationDialogMessage =>
      'Пожалуйста, включите разрешения на уведомления для лучшего опыта.\n\nПриложение использует уведомления для:\n  • всплывающих сообщений синхронизации (опционально)\n  • отчетов об ошибках';

  @override
  String get allFilesAccessDialogTitle => 'Включить \"Доступ ко всем файлам\"';

  @override
  String get allFilesAccessDialogMessage =>
      'Вы не можете использовать GitSync без предоставления разрешений \"Доступ ко всем файлам\"! Пожалуйста, включите их для лучшего опыта.\n\nПриложение использует \"Доступ ко всем файлам\" для синхронизации вашего репозитория в выбранную папку на устройстве. Приложение не пытается получить доступ к файлам за пределами выбранной папки.';

  @override
  String get almostThereDialogTitle => 'Почти готово!';

  @override
  String get almostThereDialogMessageAndroid =>
      'Скоро мы авторизуемся и клонируем ваш репозиторий на ваше устройство, подготовив его к синхронизации.\n\nПосле настройки есть несколько способов запустить синхронизацию:\n\n  • Из приложения\n  • Из быстрой плитки\n  • Используя автосинхронизацию\n  • Используя пользовательский Intent (для продвинутых)';

  @override
  String get almostThereDialogMessageIos =>
      'Скоро мы авторизуемся и клонируем ваш репозиторий на ваше устройство, подготовив его к синхронизации.\n\nПосле настройки есть несколько способов запустить синхронизацию:\n\n  • Из приложения';

  @override
  String get authDialogTitle => 'Авторизация у провайдера Git';

  @override
  String get authDialogMessage => 'Пожалуйста, авторизуйтесь у выбранного провайдера git и продолжите клонирование вашего репозитория!';

  @override
  String get authorDetailsPromptTitle => 'Требуются данные автора';

  @override
  String get authorDetailsPromptMessage => 'Отсутствует имя автора или email. Пожалуйста, обновите их в настройках репозитория перед синхронизацией.';

  @override
  String get authorDetailsShowcasePrompt => 'Fill out your author details';

  @override
  String get goToSettings => 'Перейти в настройки';

  @override
  String get enableAutosyncTitle => 'Enable App Sync';

  @override
  String get enableAutosyncMessage =>
      'Keep your data up-to-date effortlessly. Turn on App Sync to automatically sync in the background whenever apps are opened or closed.';

  @override
  String get addMoreHint => 'Нажмите эту кнопку, чтобы добавить дополнительные репозитории в приложение';

  @override
  String get globalSettingsHint => 'Нажмите эту кнопку для доступа к глобальным настройкам приложения';

  @override
  String get syncProgressHint => 'Отслеживайте статус активных операций синхронизации здесь';

  @override
  String get controlHint => 'Используйте эти элементы управления для ручной синхронизации или управления действиями репозитория';

  @override
  String get configHint => 'Настройте параметры репозитория и инициализируйте настройку, используя этот раздел';

  @override
  String get autoSyncOptionsHint =>
      'Включите фоновую синхронизацию и убедитесь, что ваши данные остаются актуальными автоматически, используя эти настройки';

  @override
  String get guidedSetupHint =>
      'Нажмите здесь, чтобы перезапустить настройку или руководство по интерфейсу, когда вам нужен пошаговый обзор или вы хотите повторно изучить интерфейс';

  @override
  String get detachedHead => 'Отсоединенная HEAD';

  @override
  String get commitsNotFound => 'Коммиты не найдены…';

  @override
  String get repoNotFound => 'Коммиты не найдены…';

  @override
  String get committed => 'зафиксировано';

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
  String get auth => 'АВТОРИЗАЦИЯ';

  @override
  String get gitDirPathHint => '/storage/emulated/0/…';

  @override
  String get openFileExplorer => 'Browse & Edit';

  @override
  String get syncSettings => 'Sync Settings';

  @override
  String get enableApplicationObserver => 'App Sync Settings';

  @override
  String get appSyncDescription => 'Automatically syncs when your selected app is opened or closed';

  @override
  String get accessibilityServiceDisclosureTitle => 'Раскрытие информации о службе специальных возможностей';

  @override
  String get accessibilityServiceDisclosureMessage =>
      'Для улучшения вашего опыта\nGitSync использует службу специальных возможностей Android для обнаружения открытия или закрытия приложений.\n\nЭто помогает нам предоставить персонализированные функции без сохранения или передачи данных.\n\nᴘᴏᴊᴀʟᴜʏsᴛᴀ ᴠᴋʟᴊuᴄʜɪᴛᴇ ɢɪᴛsʏɴᴄ ɴᴀ sʟᴇᴅᴜʏsᴄʜᴇᴍ ᴇᴋʀᴀɴᴇ';

  @override
  String get accessibilityServiceDescription =>
      'Для улучшения вашего опыта GitSync использует службу специальных возможностей Android для обнаружения открытия или закрытия приложений. Это помогает нам предоставить персонализированные функции без сохранения или передачи данных.\n\nКлючевые моменты:\nЦель: Мы используем эту службу исключительно для улучшения вашего опыта работы с приложением.\nКонфиденциальность: Никакие данные не сохраняются и не отправляются в другие места.\nКонтроль: Вы можете отключить эти разрешения в любое время в настройках устройства.';

  @override
  String get search => 'Поиск';

  @override
  String get searchEllipsis => 'Search…';

  @override
  String get applicationNotSet => 'Выбрать приложение(я)';

  @override
  String get selectApplication => 'Выбрать приложение(я)';

  @override
  String get multipleApplicationSelected => 'Выбрано (%s)';

  @override
  String get saveApplication => 'Сохранить';

  @override
  String get syncOnAppClosed => 'Синхронизация при закрытии приложения(й)';

  @override
  String get syncOnAppOpened => 'Синхронизация при открытии приложения(й)';

  @override
  String get scheduledSyncSettings => 'Настройки запланированной синхронизации';

  @override
  String get scheduledSyncDescription => 'Automatically syncs periodically in the background';

  @override
  String get sync => 'Синхронизация';

  @override
  String get dontSync => 'Не синхронизировать';

  @override
  String get iosDefaultSyncRate => 'когда iOS позволяет';

  @override
  String get aboutEvery => '~каждые';

  @override
  String get enhancedScheduledSync => 'Расширенная запланированная синхронизация';

  @override
  String get enhancedScheduledSyncMsg1 =>
      'В отличие от базовой синхронизации, эта функция использует расширенные фоновые обновления для более частой и надежной доставки свежих данных.';

  @override
  String get enhancedScheduledSyncMsg2 =>
      'Синхронизируйте ваши репозитории в фоне так часто, как раз в минуту, даже когда приложение закрыто!\n\nБез усилий, непрерывные обновления означают, что ваши репозитории всегда готовы, когда вы готовы.';

  @override
  String get enhancedScheduledSyncNote => 'Примечание: Фоновая синхронизация может быть затронута режимами энергосбережения и \"Не беспокоить\".';

  @override
  String get quickSyncSettings => 'Quick Sync Settings';

  @override
  String get quickSyncDescription => 'Sync using customizable quick tiles, shortcuts, or widgets';

  @override
  String get tileSyncSettings => 'Настройки синхронизации плитки';

  @override
  String get otherSyncSettings => 'Другие настройки синхронизации';

  @override
  String get useForTileSync => 'Использовать для синхронизации плитки';

  @override
  String get useForTileManualSync => 'Использовать для ручной синхронизации плитки';

  @override
  String get useForShortcutSync => 'Use for Sync Shortcut';

  @override
  String get useForShortcutManualSync => 'Use for Manual Sync Shortcut';

  @override
  String get useForWidgetSync => 'Use for Sync Widget';

  @override
  String get useForWidgetManualSync => 'Use for Manual Sync Widget';

  @override
  String get selectYourGitProviderAndAuthenticate => 'Выберите вашего провайдера git и авторизуйтесь';

  @override
  String get oauthProviders => 'oAuth Providers';

  @override
  String get gitProtocols => 'Git Protocols';

  @override
  String get oauthNoAffiliation => 'Авторизация через третьи стороны;\nникакой принадлежности или одобрения не подразумевается.';

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
  String get ensureTokenScope => 'Убедитесь, что ваш токен включает область \"repo\" для полной функциональности.';

  @override
  String get user => 'пользователь';

  @override
  String get exampleUser => 'IvanPetrov12';

  @override
  String get token => 'токен';

  @override
  String get exampleToken => 'ghp_1234abcd5678efgh';

  @override
  String get login => 'войти';

  @override
  String get pubKey => 'публичный ключ';

  @override
  String get privKey => 'приватный ключ';

  @override
  String get passphrase => 'Passphrase';

  @override
  String get privateKey => 'Приватный ключ';

  @override
  String get sshPubKeyExample => 'ssh-ed25519 AABBCCDDEEFF112233445566';

  @override
  String get sshPrivKeyExample => '-----BEGIN OPENSSH PRIVATE KEY----- AABBCCDDEEFF112233445566';

  @override
  String get generateKeys => 'сгенерировать ключи';

  @override
  String get confirmKeySaved => 'подтвердить сохранение публичного ключа';

  @override
  String get copiedText => 'Текст скопирован!';

  @override
  String get confirmPrivKeyCopy => 'Подтвердить копирование приватного ключа';

  @override
  String get confirmPrivKeyCopyMsg =>
      'Вы уверены, что хотите скопировать ваш приватный ключ в буфер обмена?\n\nЛюбой, кто имеет доступ к этому ключу, может управлять вашей учетной записью. Убедитесь, что вставляете его только в безопасных местах и очищаете буфер обмена после этого.';

  @override
  String get understood => 'Понял';

  @override
  String get importPrivateKey => 'Импорт приватного ключа';

  @override
  String get importPrivateKeyMsg =>
      'Вставьте ваш приватный ключ ниже, чтобы использовать существующую учетную запись.\n\nУбедитесь, что вставляете ключ в безопасной среде, поскольку любой, кто имеет доступ к этому ключу, может управлять вашей учетной записью.';

  @override
  String get importKey => 'импорт';

  @override
  String get cloneRepo => 'Клонировать удаленный репозиторий';

  @override
  String get clone => 'клонировать';

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
  String get invalidRepositoryUrlTitle => 'Неверный URL репозитория!';

  @override
  String get invalidRepositoryUrlMessage => 'Неверный URL репозитория!';

  @override
  String get cloneAnyway => 'Клонировать в любом случае';

  @override
  String get iHaveALocalRepository => 'У меня есть локальный репозиторий';

  @override
  String get cloningRepository => 'Клонирование репозитория…';

  @override
  String get cloneMessagePart1 => 'НЕ ВЫХОДИТЕ С ЭТОГО ЭКРАНА';

  @override
  String get cloneMessagePart2 => 'Это может занять некоторое время в зависимости от размера вашего репозитория\n';

  @override
  String get selectCloneDirectory => 'Выберите папку для клонирования';

  @override
  String get confirmCloneOverwriteTitle => 'Папка не пуста';

  @override
  String get confirmCloneOverwriteMsg => 'Выбранная вами папка уже содержит файлы. Клонирование в неё перезапишет её содержимое.';

  @override
  String get confirmCloneOverwriteWarning => 'Это действие необратимо.';

  @override
  String get confirmCloneOverwriteAction => 'Перезаписать';

  @override
  String get repoSearchLimits => 'Repository Search Limits';

  @override
  String get repoSearchLimitsDescription =>
      'Repository search only examines the first 100 repositories returned by the API, so it may sometimes omit the repository you expect. \n\nIf the repository you want does not appear in search results, please clone it directly using its HTTPS or SSH URL.';

  @override
  String get repositorySettings => 'Repository Settings';

  @override
  String get settings => 'Настройки';

  @override
  String get signedCommitsLabel => 'Signed Commits';

  @override
  String get signedCommitsDescription => 'sign commits to verify your identity';

  @override
  String get importCommitKey => 'Import Key';

  @override
  String get commitKeyImported => 'Key Imported';

  @override
  String get useSshKey => 'Use AUTH Key for Commit Signing';

  @override
  String get syncMessageLabel => 'Сообщение синхронизации';

  @override
  String get syncMessageDescription => 'используйте %s для даты и времени';

  @override
  String get syncMessageTimeFormatLabel => 'Формат времени сообщения синхронизации';

  @override
  String get syncMessageTimeFormatDescription => 'Использует стандартный синтаксис форматирования даты и времени';

  @override
  String get remoteLabel => 'удаленный репозиторий по умолчанию';

  @override
  String get defaultRemote => 'origin';

  @override
  String get authorNameLabel => 'имя автора';

  @override
  String get authorName => 'IvanPetrov12';

  @override
  String get authorEmailLabel => 'email автора';

  @override
  String get authorEmail => 'ivan12@petrov.com';

  @override
  String get gitIgnore => '.gitignore';

  @override
  String get gitIgnoreDescription => 'список файлов или папок для игнорирования на всех устройствах';

  @override
  String get gitIgnoreHint => '.trash/\n./…';

  @override
  String get gitInfoExclude => '.git/info/exclude';

  @override
  String get gitInfoExcludeDescription => 'список файлов или папок для игнорирования на этом устройстве';

  @override
  String get gitInfoExcludeHint => '.trash/\n./…';

  @override
  String get disableSsl => 'Отключить SSL';

  @override
  String get disableSslDescription => 'Disable secure connection for HTTP repositories';

  @override
  String get disableSslPromptTitle => 'Disable SSL?';

  @override
  String get disableSslPromptMsg => 'The address you cloned starts with \"http\" (not secure). Disabling SSL will match the URL but reduce security.';

  @override
  String get optimisedSync => 'Optimised Sync';

  @override
  String get optimisedSyncDescription => 'Intelligently reduce overall sync operations';

  @override
  String get proceedAnyway => 'Proceed anyway?';

  @override
  String get moreOptions => 'Дополнительные параметры';

  @override
  String get untrackAll => 'Untrack All';

  @override
  String get globalSettings => 'Глобальные настройки';

  @override
  String get language => 'Язык';

  @override
  String get browseEditDir => 'Browse & Edit Directory';

  @override
  String get enableLineWrap => 'Enable Line Wrap in Editors';

  @override
  String get excludeFromRecents => 'Exclude From Recents';

  @override
  String get backupRestoreTitle => 'Восстановление зашифрованной конфигурации';

  @override
  String get encryptedBackup => 'Encrypted Backup';

  @override
  String get encryptedRestore => 'Encrypted Restore';

  @override
  String get backup => 'Резервная копия';

  @override
  String get restore => 'Восстановить';

  @override
  String get selectBackupLocation => 'Select location to save backup';

  @override
  String get backupFileTemplate => 'backup_%s.gsbak';

  @override
  String get enterPassword => 'Введите пароль';

  @override
  String get invalidPassword => 'Неверный пароль';

  @override
  String get community => 'Community';

  @override
  String get guides => 'Guides';

  @override
  String get documentation => 'Руководства и Wiki';

  @override
  String get viewDocumentation => 'Просмотреть руководства и Wiki';

  @override
  String get requestAFeature => 'Запросить функцию';

  @override
  String get contributeTitle => 'Поддержите нашу работу';

  @override
  String get improveTranslations => 'Improve Translations';

  @override
  String get joinTheDiscussion => 'Присоединиться к Discord';

  @override
  String get noLogFilesFound => 'No log files found!';

  @override
  String get guidedSetup => 'Пошаговая настройка';

  @override
  String get uiGuide => 'Руководство по интерфейсу';

  @override
  String get viewPrivacyPolicy => 'Политика конфиденциальности';

  @override
  String get viewEula => 'Условия использования (EULA)';

  @override
  String get shareLogs => 'Поделиться логами';

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
  String get file => 'File';

  @override
  String get folder => 'Folder';

  @override
  String get directory => 'Directory';

  @override
  String get confirmFileDirDeleteTitle => 'Confirm %s Deletion';

  @override
  String get confirmFileDirDeleteMsg => 'Are you sure you want to delete the %s \"%s\" %s?';

  @override
  String get deleteMultipleSuffix => 'and %s more and their contents';

  @override
  String get deleteSingularSuffix => 'and it\'s contents';

  @override
  String get createAFile => 'Create a File';

  @override
  String get fileName => 'File Name';

  @override
  String get createADir => 'Create a Directory';

  @override
  String get dirName => 'Folder Name';

  @override
  String get renameFileDir => 'Rename %s';

  @override
  String get fileTooLarge => 'File larger than %s lines';

  @override
  String get readOnly => 'Read-Only';

  @override
  String get cut => 'Cut';

  @override
  String get copy => 'Copy';

  @override
  String get paste => 'Paste';

  @override
  String get experimental => 'Experimental';

  @override
  String get experimentalMsg => 'Use at your own risk';

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
  String get defaultContainerName => 'псевдоним';

  @override
  String get renameRepository => 'Переименовать репозиторий';

  @override
  String get renameRepositoryMsg => 'Введите новый псевдоним для контейнера репозитория';

  @override
  String get addMore => 'Добавить еще';

  @override
  String get addRepository => 'Добавить репозиторий';

  @override
  String get addRepositoryMsg => 'Дайте новому контейнеру репозитория уникальный псевдоним. Это поможет вам идентифицировать его позже.';

  @override
  String get confirmRepositoryDelete => 'Подтвердить удаление репозитория';

  @override
  String get confirmRepositoryDeleteMsg => 'Вы уверены, что хотите удалить контейнер репозитория \"%s\"?';

  @override
  String get deleteRepoDirectoryCheckbox => 'Также удалить папку репозитория и все её содержимое';

  @override
  String get confirmRepositoryDeleteTitle => 'Подтвердить удаление репозитория';

  @override
  String get confirmRepositoryDeleteMessage => 'Вы уверены, что хотите удалить репозиторий \"%s\" и его содержимое?';

  @override
  String get submodulesFoundTitle => 'Submodules Found';

  @override
  String get submodulesFoundMessage =>
      'The repository you added contains submodules. Would you like to automatically add them as separate repositories in the app?\n\nThis is a premium feature.';

  @override
  String get submodulesFoundAction => 'Add Submodules';

  @override
  String get confirmBranchCheckoutTitle => 'Переключиться на ветку?';

  @override
  String get confirmBranchCheckoutMsgPart1 => 'Вы уверены, что хотите переключиться на ветку ';

  @override
  String get confirmBranchCheckoutMsgPart2 => '?';

  @override
  String get unsavedChangesMayBeLost => 'Несохраненные изменения могут быть потеряны.';

  @override
  String get checkout => 'Переключиться';

  @override
  String get create => 'Создать';

  @override
  String get createBranch => 'Создать новую ветку';

  @override
  String get createBranchName => 'Имя ветки';

  @override
  String get createBranchBasedOn => 'На основе';

  @override
  String get attemptAutoFix => 'Попытаться автоисправление?';

  @override
  String get troubleshooting => 'Troubleshooting';

  @override
  String get youreOffline => 'Вы офлайн.';

  @override
  String get someFeaturesMayNotWork => 'Некоторые функции могут не работать.';

  @override
  String get ongoingMergeConflict => 'Текущий конфликт слияния';

  @override
  String get enableAccessibilityService => 'Пожалуйста, включите GitSync в разделе \"Установленные приложения\"';

  @override
  String get networkUnavailable => 'Сеть недоступна!';

  @override
  String get networkUnavailableRetry => 'Сеть недоступна!\nGitSync повторит попытку при подключении';

  @override
  String get pullFailed => 'Получение не удалось! Пожалуйста, проверьте незафиксированные изменения и попробуйте снова.';

  @override
  String get reportABug => 'Сообщить об ошибке';

  @override
  String get reportBug => '<Ошибка GitSync> Нажмите, чтобы отправить отчет об ошибке';

  @override
  String get unknownError => 'Неизвестная ошибка';

  @override
  String get enableNotifications => 'Включите разрешение на уведомления для подробностей.';

  @override
  String get errorOccurredTitle => 'Произошла ошибка!';

  @override
  String get errorOccurredMessagePart1 => 'Если это вызвало проблемы, пожалуйста, быстро создайте отчет об ошибке, используя кнопку ниже.';

  @override
  String get errorOccurredMessagePart2 => 'В противном случае вы можете закрыть и продолжить.';

  @override
  String get applicationError => 'Ошибка приложения!';

  @override
  String get missingAuthorDetailsError => 'Отсутствуют данные автора репозитория. Пожалуйста, установите ваше имя и email в настройках репозитория.';

  @override
  String get outOfMemory => 'В приложении закончилась память!';

  @override
  String get invalidRemote => 'Неверный удаленный репозиторий! Измените это в настройках';

  @override
  String get largeFile => 'Отдельные файлы размером более 50 МБ не поддерживаются!';

  @override
  String get cloneFailed => 'Не удалось клонировать репозиторий!';

  @override
  String get inaccessibleDirectoryMessage => 'Недоступная папка! Пожалуйста, выберите другое расположение.';

  @override
  String get autoRebaseFailedException =>
      'Удаленный репозиторий находится дальше локального, и мы не смогли автоматически перебазировать для вас, так как это вызвало бы обновление не fast-forward.';

  @override
  String get nonExistingException => 'Удаленная ссылка не существовала.';

  @override
  String get rejectedNodeleteException =>
      'Обновление удаленной ссылки было отклонено, потому что удаленная сторона не поддерживает/не разрешает удаление ссылок.';

  @override
  String get rejectedException => 'Обновление удаленной ссылки было отклонено.';

  @override
  String get rejectionWithReasonException => 'Обновление удаленной ссылки было отклонено, потому что %s.';

  @override
  String get remoteChangedException =>
      'Обновление удаленной ссылки было отклонено, потому что старый идентификатор объекта на удаленном репозитории не был таким же, как определенный ожидаемый старый объект.';

  @override
  String get mergingExceptionMessage => 'СЛИЯНИЕ';

  @override
  String get fieldCannotBeEmpty => 'Поле не может быть пустым';

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
  String get githubIssueOauthTitle => 'Подключить GitHub для автоматических отчетов';

  @override
  String get githubIssueOauthMsg =>
      'Вам нужно подключить вашу учетную запись GitHub для сообщения об ошибках и отслеживания их прогресса.\nВы можете сбросить это подключение в любое время в глобальных настройках.';

  @override
  String get issueReportMessage => 'Логи автоматически включаются в отчеты';

  @override
  String get includeLogs => 'Include Log File(s)';

  @override
  String get issueReportTitleTitle => 'Заголовок';

  @override
  String get issueReportTitleDesc => 'Несколько слов, резюмирующих проблему';

  @override
  String get issueReportDescTitle => 'Описание';

  @override
  String get issueReportDescDesc => 'Объясните, что происходит, более подробно';

  @override
  String get issueReportMinimalReproTitle => 'Шаги воспроизведения';

  @override
  String get issueReportMinimalReproDesc => 'Опишите шаги, приводящие к ошибке';

  @override
  String get includeLogFiles => 'Include Log File(s)';

  @override
  String get includeLogFilesDescription =>
      'Including log files with your bug report is strongly recommended as they can greatly speed up diagnosing the root cause. \nIf you choose to disable \"Include log file(s)\", please copy and paste the relevant log excerpts into your report so we can reproduce the issue. You can review logs before sending by using the eye icon to confirm there’s nothing sensitive. \n\nIncluding logs is optional, not mandatory.';

  @override
  String get report => 'Сообщить';

  @override
  String get issueReportSuccessTitle => 'Проблема успешно зарегистрирована';

  @override
  String get issueReportSuccessMsg =>
      'Ваша проблема была зарегистрирована. Вы можете отслеживать её прогресс и отвечать на сообщения, используя ссылку ниже.\n\nПроблемы без активности в течение 7 дней автоматически закрываются.';

  @override
  String get trackIssue => 'Отслеживать проблему';
}
