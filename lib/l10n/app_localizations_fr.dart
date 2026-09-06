// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get dismiss => 'Ignorer';

  @override
  String get dontShowAgain => 'Ne plus afficher';

  @override
  String get skip => 'Passer';

  @override
  String get done => 'Terminé';

  @override
  String get confirm => 'Confirmer';

  @override
  String get ok => 'OK';

  @override
  String get select => 'Sélectionner';

  @override
  String get cancel => 'Annuler';

  @override
  String get learnMore => 'En savoir plus';

  @override
  String get loadingElipsis => 'Chargement…';

  @override
  String get previous => 'Précédent';

  @override
  String get next => 'Suivant';

  @override
  String get finish => 'Terminer';

  @override
  String get rename => 'Renommer';

  @override
  String get renameDescription => 'Renommer le fichier ou dossier sélectionné';

  @override
  String get selectAllDescription => 'Sélectionner tous les fichiers et dossiers visibles';

  @override
  String get deselectAllDescription => 'Désélectionner tous les fichiers et dossiers sélectionnés';

  @override
  String get add => 'Ajouter';

  @override
  String get delete => 'Supprimer';

  @override
  String get optionalLabel => '(facultatif)';

  @override
  String get ios => 'iOS';

  @override
  String get android => 'Android';

  @override
  String get syncStarting => 'Détection des modifications…';

  @override
  String get syncStartPull => 'Sync des modifications…';

  @override
  String get syncStartPush => 'Sync des modifications locales…';

  @override
  String get syncNotRequired => 'Sync non requise !';

  @override
  String get syncComplete => 'Dépôt synchronisé !';

  @override
  String get syncInProgress => 'Sync en cours';

  @override
  String get syncScheduled => 'Sync planifiée';

  @override
  String get detectingChanges => 'Détection des modifications…';

  @override
  String get thisActionCannotBeUndone => 'Cette action ne peut pas être annulée.';

  @override
  String get cloneProgressLabel => 'progression du clonage';

  @override
  String get forcePushProgressLabel => 'progression du push forcé';

  @override
  String get forcePullProgressLabel => 'progression du pull forcé';

  @override
  String get moreSyncOptionsLabel => 'plus d\'options de sync';

  @override
  String get repositorySettingsLabel => 'paramètres du dépôt';

  @override
  String get addBranchLabel => 'ajouter une branche';

  @override
  String get deselectDirLabel => 'désélectionner le répertoire';

  @override
  String get selectDirLabel => 'sélectionner le répertoire';

  @override
  String get syncMessagesLabel => 'désactiver/activer les messages de sync';

  @override
  String get backLabel => 'retour';

  @override
  String get authDropdownLabel => 'menu déroulant d\'authentification';

  @override
  String get premiumDialogTitle => 'Débloquer Premium';

  @override
  String get restorePurchase => 'Restaurer l\'achat';

  @override
  String get premiumStoreOnlyBanner => 'Version boutique uniquement — Disponible sur l\'App Store ou le Play Store';

  @override
  String get premiumMultiRepoTitle => 'Gérer plusieurs dépôts';

  @override
  String get premiumMultiRepoSubtitle => 'Une seule app. Tous vos dépôts.\nChacun avec ses propres identifiants et paramètres.';

  @override
  String get premiumUnlimitedContainers => 'Conteneurs illimités';

  @override
  String get premiumIndependentAuth => 'Auth indépendante par dépôt';

  @override
  String get premiumAutoAddSubmodules => 'Ajout auto des sous-modules';

  @override
  String get premiumEnhancedSyncSubtitle => 'Synchronisation automatique en arrière-plan sur iOS.\nJusqu\'à une fois par minute.';

  @override
  String get premiumSyncPerMinute => 'Synchro jusqu\'à chaque minute';

  @override
  String get premiumServerTriggered => 'Notifications push du serveur';

  @override
  String get premiumWorksAppClosed => 'Fonctionne même quand l\'app est fermée';

  @override
  String get premiumReliableDelivery => 'Distribution fiable et ponctuelle';

  @override
  String get premiumGitLfsTitle => 'Git LFS';

  @override
  String get premiumGitLfsSubtitle =>
      'Prise en charge complète de Git Large File Storage.\nSynchronisez les dépôts avec des fichiers binaires volumineux sans effort.';

  @override
  String get premiumFullLfsSupport => 'Prise en charge complète de Git LFS';

  @override
  String get premiumTrackLargeFiles => 'Suivre les fichiers binaires volumineux';

  @override
  String get premiumAutoLfsPullPush => 'Pull/push LFS automatique';

  @override
  String get premiumGitFiltersTitle => 'Filtres Git';

  @override
  String get premiumGitFiltersSubtitle => 'Prise en charge des filtres git dont git-lfs,\ngit-crypt, et d\'autres à venir.';

  @override
  String get premiumGitLfsFilter => 'Filtre git-lfs';

  @override
  String get premiumGitCryptFilter => 'Filtre git-crypt';

  @override
  String get premiumMoreFiltersSoon => 'Plus de filtres à venir';

  @override
  String get premiumGitHooksTitle => 'Git Hooks';

  @override
  String get premiumGitHooksSubtitle => 'Exécutez les hooks pre-commit automatiquement\navant chaque synchronisation.';

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
  String get switchToClientMode => 'Passer en mode client…';

  @override
  String get switchToSyncMode => 'Passer en mode sync…';

  @override
  String get defaultTo => 'Par défaut';

  @override
  String get clientMode => 'Mode client';

  @override
  String get clientModeDescription => 'Interface Git étendue\n(Avancé)';

  @override
  String get syncMode => 'Mode sync';

  @override
  String get syncModeDescription => 'Synchronisation automatique\n(Débutant)';

  @override
  String get syncNow => 'Sync les modifications';

  @override
  String get syncAllChanges => 'Sync toutes les modifications';

  @override
  String get stageAndCommit => 'Préparer et valider';

  @override
  String get downloadChanges => 'Télécharger les modifications';

  @override
  String get uploadChanges => 'Téléverser les modifications';

  @override
  String get downloadAndOverwrite => 'Télécharger + Écraser';

  @override
  String get uploadAndOverwrite => 'Téléverser + Écraser';

  @override
  String get fetchRemote => 'Récupérer %s';

  @override
  String get pullChanges => 'Récupérer les modifications';

  @override
  String get pushChanges => 'Envoyer les modifications';

  @override
  String get updateSubmodules => 'MAJ sous-modules';

  @override
  String get forcePush => 'Push forcé';

  @override
  String get forcePushing => 'Push forcé…';

  @override
  String get confirmForcePush => 'Confirmer le push forcé';

  @override
  String get confirmForcePushMsg =>
      'Voulez-vous vraiment forcer l\'envoi de ces modifications ? Tous les conflits de fusion en cours seront abandonnés.';

  @override
  String get forcePull => 'Pull forcé';

  @override
  String get forcePulling => 'Pull forcé…';

  @override
  String get confirmForcePull => 'Confirmer le pull forcé';

  @override
  String get confirmForcePullMsg =>
      'Voulez-vous vraiment forcer la récupération de ces modifications ? Tous les conflits de fusion en cours seront ignorés.';

  @override
  String get localHistoryOverwriteWarning => 'Cette action écrasera l\'historique local et ne pourra pas être annulée.';

  @override
  String get forcePushPullMessage => 'Veuillez ne pas fermer ou quitter l\'application tant que le processus n\'est pas terminé.';

  @override
  String get manualSync => 'Synchronisation manuelle';

  @override
  String get manualSyncMsg => 'Sélectionnez les fichiers que vous souhaitez synchroniser';

  @override
  String get commit => 'Valider';

  @override
  String get unstage => 'Désindexer';

  @override
  String get stage => 'Indexer';

  @override
  String get selectAll => 'Tout sélectionner';

  @override
  String get deselectAll => 'Tout désélectionner';

  @override
  String get noUncommittedChanges => 'Aucune modification non validée';

  @override
  String get discardChanges => 'Ignorer les modifications';

  @override
  String get discardChangesTitle => 'Ignorer les modifications ?';

  @override
  String get discardChangesMsg => 'Voulez-vous vraiment ignorer toutes les modifications apportées à \"%s\"?';

  @override
  String get mergeConflictItemMessage => 'Il y a un conflit de fusion ! Appuyez pour résoudre';

  @override
  String get mergeConflict => 'Conflit de fusion';

  @override
  String get mergeDialogMessage => 'Utilisez l\'éditeur pour résoudre les conflits de fusion';

  @override
  String get commitMessage => 'Message de commit';

  @override
  String get abortMerge => 'Abandonner la fusion';

  @override
  String get resolveLater => 'Résoudre plus tard';

  @override
  String get keepChanges => 'Conserver les modifications';

  @override
  String get current => 'Actuel';

  @override
  String get both => 'Les deux';

  @override
  String get remote => 'Distant';

  @override
  String get incoming => 'Entrant';

  @override
  String get merge => 'Fusionner';

  @override
  String get resolve => 'Résoudre';

  @override
  String get merging => 'Fusion en cours…';

  @override
  String get resolving => 'Résolution…';

  @override
  String get clearSelection => 'Effacer la sélection';

  @override
  String get keepSelected => 'Garder la sélection';

  @override
  String get resolveAll => 'Tout résoudre';

  @override
  String get allCurrent => 'Tout actuel';

  @override
  String get allIncoming => 'Tout entrant';

  @override
  String get iosClearDataTitle => 'Est-ce une nouvelle installation ?';

  @override
  String get iosClearDataMsg =>
      'Nous avons détecté qu\'il pourrait s\'agir d\'une réinstallation, mais il pourrait aussi s\'agir d\'une fausse alerte. Sur iOS, votre Trousseau n\'est pas effacé lorsque vous supprimez et réinstallez l\'application, donc certaines données peuvent encore être stockées en toute sécurité.\n\nSi ce n\'est pas une nouvelle installation, ou si vous ne souhaitez pas réinitialiser, vous pouvez ignorer cette étape en toute sécurité.';

  @override
  String get clearDataConfirmTitle => 'Confirmer la réinitialisation des données de l\'application';

  @override
  String get clearDataConfirmMsg =>
      'Cela supprimera définitivement toutes les données de l\'application, y compris les entrées du Trousseau. Êtes-vous sûr de vouloir continuer ?';

  @override
  String get iosClearDataAction => 'Tout effacer';

  @override
  String get legacyAppUserDialogTitle => 'Bienvenue dans la nouvelle version !';

  @override
  String get legacyAppUserDialogMessagePart1 =>
      'Nous avons reconstruit l\'application à partir de zéro pour de meilleures performances et une croissance future.';

  @override
  String get legacyAppUserDialogMessagePart2 =>
      'Malheureusement, vos anciens paramètres ne peuvent pas être transférés, vous devrez donc tout reconfigurer.\n\nToutes vos fonctionnalités préférées sont toujours là. La prise en charge de plusieurs dépôts fait désormais partie d\'une petite mise à niveau unique qui contribue à soutenir le développement continu.';

  @override
  String get legacyAppUserDialogMessagePart3 => 'Merci de votre fidélité :)';

  @override
  String get setUp => 'Configurer';

  @override
  String get welcomeSetupPrompt => 'Souhaitez-vous faire une configuration rapide pour commencer ?';

  @override
  String get welcomePositive => 'Allons-y';

  @override
  String get welcomeNegative => 'Je connais déjà';

  @override
  String get notificationDialogTitle => 'Activer les notifications';

  @override
  String get allFilesAccessDialogTitle => 'Activer \"Accès à tous les fichiers\"';

  @override
  String get authorDetailsPromptTitle => 'Détails de l\'auteur requis';

  @override
  String get authorDetailsPromptMessage =>
      'Votre nom ou e-mail d\'auteur est manquant. Veuillez les mettre à jour dans les paramètres du dépôt avant de synchroniser.';

  @override
  String get authorDetailsShowcasePrompt => 'Renseignez vos détails d\'auteur';

  @override
  String get goToSettings => 'Aller aux paramètres';

  @override
  String get onboardingSyncSettingsTitle => 'Paramètres de synchro';

  @override
  String get onboardingSyncSettingsSubtitle => 'Choisissez comment synchroniser vos dépôts.';

  @override
  String get onboardingAppSyncFeatureOpen => 'Déclencher la synchro à l\'ouverture de l\'app';

  @override
  String get onboardingAppSyncFeatureClose => 'Déclencher la synchro à la fermeture de l\'app';

  @override
  String get onboardingAppSyncFeatureSelect => 'Sélectionner les apps à surveiller';

  @override
  String get onboardingScheduledSyncFeatureFreq => 'Définir la fréquence de synchro';

  @override
  String get onboardingScheduledSyncFeatureCustom => 'Choisir des intervalles personnalisés sur Android';

  @override
  String get onboardingScheduledSyncFeatureBg => 'Fonctionne en arrière-plan';

  @override
  String get onboardingQuickSyncFeatureTile => 'Synchro via la vignette de réglages rapides';

  @override
  String get onboardingQuickSyncFeatureShortcut => 'Synchro via les raccourcis de l\'app';

  @override
  String get onboardingQuickSyncFeatureWidget => 'Synchro via le widget d\'écran d\'accueil';

  @override
  String get onboardingOtherSyncFeatureAndroid => 'Intents Android';

  @override
  String get onboardingOtherSyncFeatureIos => 'Intents iOS';

  @override
  String get onboardingOtherSyncDescription => 'Explore additional sync methods for your platform';

  @override
  String get onboardingTapToConfigure => 'Tap to configure';

  @override
  String get showcaseGlobalSettingsTitle => 'Paramètres globaux';

  @override
  String get showcaseGlobalSettingsSubtitle => 'Vos préférences et outils à l\'échelle de l\'app.';

  @override
  String get showcaseGlobalSettingsFeatureTheme => 'Ajuster le thème, la langue et les options d\'affichage';

  @override
  String get showcaseGlobalSettingsFeatureBackup => 'Sauvegarder ou restaurer votre configuration';

  @override
  String get showcaseGlobalSettingsFeatureSetup => 'Relancer la configuration guidée ou la visite';

  @override
  String get showcaseSyncProgressTitle => 'Statut de la synchro';

  @override
  String get showcaseSyncProgressSubtitle => 'Voyez ce qui se passe en un coup d\'œil.';

  @override
  String get showcaseSyncProgressFeatureWatch => 'Suivez les opérations de synchro en temps réel';

  @override
  String get showcaseSyncProgressFeatureConfirm => 'Confirme quand une synchro réussit';

  @override
  String get showcaseSyncProgressFeatureErrors => 'Tapez pour voir les erreurs ou ouvrir le journal';

  @override
  String get showcaseAddMoreTitle => 'Vos conteneurs';

  @override
  String get showcaseAddMoreSubtitle => 'Gérez plusieurs dépôts en un seul endroit.';

  @override
  String get showcaseAddMoreFeatureSwitch => 'Basculez instantanément entre les conteneurs';

  @override
  String get showcaseAddMoreFeatureManage => 'Renommez ou supprimez les conteneurs selon vos besoins';

  @override
  String get showcaseAddMoreFeaturePremium => 'Ajoutez plus de conteneurs avec Premium';

  @override
  String get showcaseControlTitle => 'Contrôles de synchro';

  @override
  String get showcaseControlSubtitle => 'Vos outils de synchronisation et de validation.';

  @override
  String get showcaseControlFeatureSync => 'Déclencher une synchro manuelle d\'une tape';

  @override
  String get showcaseControlFeatureHistory => 'Voir l\'historique des validations récentes';

  @override
  String get showcaseControlFeatureConflicts => 'Résoudre les conflits de fusion';

  @override
  String get showcaseControlFeatureMore => 'Accéder au push forcé, pull forcé, etc.';

  @override
  String get showcaseAutoSyncTitle => 'Synchro automatique';

  @override
  String get showcaseAutoSyncSubtitle => 'Gardez vos dépôts synchronisés automatiquement.';

  @override
  String get showcaseAutoSyncFeatureApp => 'Synchroniser quand des apps sélectionnées s\'ouvrent ou se ferment';

  @override
  String get showcaseAutoSyncFeatureSchedule => 'Planifier des synchronisations périodiques en arrière-plan';

  @override
  String get showcaseAutoSyncFeatureQuick => 'Synchroniser via les vignettes rapides, raccourcis ou widgets';

  @override
  String get showcaseAutoSyncFeaturePremium => 'Débloquez des vitesses de synchro améliorées avec Premium';

  @override
  String get showcaseSetupGuideTitle => 'Configuration et guide';

  @override
  String get showcaseSetupGuideSubtitle => 'Revisitez le guide à tout moment.';

  @override
  String get showcaseSetupGuideFeatureSetup => 'Relancer la configuration guidée';

  @override
  String get showcaseSetupGuideFeatureTour => 'Faire une visite rapide des points forts de l\'interface';

  @override
  String get showcaseRepoTitle => 'Votre dépôt';

  @override
  String get showcaseRepoSubtitle => 'Votre centre de commande pour gérer ce dépôt.';

  @override
  String get showcaseRepoFeatureAuth => 'Authentifiez-vous avec votre fournisseur git';

  @override
  String get showcaseRepoFeatureDir => 'Changez ou sélectionnez votre dossier local';

  @override
  String get showcaseRepoFeatureBrowse => 'Parcourez et éditez les fichiers directement';

  @override
  String get showcaseRepoFeatureRemote => 'Voir ou modifier l\'URL du dépôt distant';

  @override
  String get onboardingClientMode => 'Mode Client';

  @override
  String get onboardingClientModeDescription => 'Tout ce que vous attendez d\'un client git';

  @override
  String get onboardingClientFeatureBranch => 'Gestion des branches';

  @override
  String get onboardingClientFeatureCommit => 'Validation et push manuels';

  @override
  String get onboardingClientFeatureDiff => 'Visualisateur de différences';

  @override
  String get onboardingSyncMode => 'Mode Synchronisation';

  @override
  String get onboardingSyncModeDescription => 'Synchronisation automatique des fichiers en arrière-plan';

  @override
  String get onboardingSyncFeatureAutoCommit => 'Validation et push automatiques';

  @override
  String get onboardingSyncFeatureBackground => 'Fonctionnement en arrière-plan';

  @override
  String get onboardingSyncFeatureConflict => 'Résolution facile des conflits';

  @override
  String get onboardingFileExplorer => 'Explorateur de fichiers';

  @override
  String get onboardingBrowseFeatureHidden => 'Voir les fichiers cachés';

  @override
  String get onboardingBrowseFeatureLog => 'Voir le journal git';

  @override
  String get onboardingBrowseFeatureIgnore => 'Désindexer et ignorer des fichiers';

  @override
  String get onboardingCodeEditor => 'Éditeur de code';

  @override
  String get onboardingEditFeatureSyntax => 'Coloration syntaxique';

  @override
  String get onboardingEditFeatureAutosave => 'Sauvegarde automatique';

  @override
  String get onboardingEditFeatureExperimental => 'Fonctionnalité expérimentale';

  @override
  String get onboardingNotificationDescription => 'Les notifications vous informent de :';

  @override
  String get onboardingNotificationFeatureSync => 'Mises à jour du statut de synchro';

  @override
  String get onboardingNotificationFeatureConflict => 'Alertes de conflit de fusion';

  @override
  String get onboardingNotificationFeatureBug => 'Signalements de bugs';

  @override
  String get onboardingNotificationDefault => 'Toutes les notifications sont désactivées par défaut.';

  @override
  String get onboardingFileAccessDescription => 'L\'accès aux fichiers est nécessaire pour :';

  @override
  String get onboardingFileAccessFeatureSync => 'Synchroniser votre dépôt';

  @override
  String get onboardingFileAccessFeatureReadWrite => 'Lire et écrire des fichiers';

  @override
  String get onboardingFileAccessFeatureDirectory => 'Accéder à votre dossier sélectionné';

  @override
  String get onboardingPremiumFeatures => 'Fonctionnalités Premium';

  @override
  String get onboardingWelcomeTitle => 'Synchronisation sans effort';

  @override
  String get onboardingWelcomeDescWorks => 'Fonctionne\n';

  @override
  String get onboardingWelcomeDescBackground => 'en arrière-plan,\n';

  @override
  String get onboardingWelcomeDescYourWork => 'votre travail\n';

  @override
  String get onboardingWelcomeDescFocus => 'toujours au premier plan';

  @override
  String get onboardingChooseYourFocus => 'Choisissez votre objectif';

  @override
  String get onboardingChangeLaterInSettings => 'Vous pourrez modifier cela plus tard dans les paramètres';

  @override
  String get onboardingBrowseEditTitle => 'Parcourir et éditer';

  @override
  String get onboardingBrowseEditSubtitle => 'Outils intégrés pour vos fichiers';

  @override
  String get onboardingAlmostThereTitle => 'Plus qu\'un pas !';

  @override
  String get onboardingAlmostThereSubtitle => 'Voici la suite :';

  @override
  String get onboardingStepAuthenticate => 'Authentifiez-vous avec votre fournisseur Git';

  @override
  String get onboardingStepClone => 'Clonez un dépôt sur votre appareil';

  @override
  String get onboardingStepSyncSettings => 'Configurez vos paramètres de synchronisation';

  @override
  String get onboardingStepWiki => 'Consultez le wiki si besoin d\'aide';

  @override
  String get onboardingStepAllSet => 'Et vous serez fin prêt !';

  @override
  String get onboardingAuthTitle => 'Authentification';

  @override
  String get onboardingAuthSubtitle => 'Authentifiez-vous avec votre fournisseur git';

  @override
  String get onboardingLaunchWiki => 'Lancer le wiki';

  @override
  String get onboardingHowYouFoundUsTitle => 'Comment avez-vous découvert GitSync ?';

  @override
  String get onboardingHowYouFoundUsSubtitle => 'Aidez-nous à comprendre d\'où viennent nos utilisateurs (sélectionnez tout ce qui s\'applique)';

  @override
  String get sourceReddit => 'Reddit';

  @override
  String get sourceYoutube => 'YouTube';

  @override
  String get sourceDiscord => 'Discord';

  @override
  String get sourceMedium => 'Medium';

  @override
  String get sourceGoogle => 'Google Search';

  @override
  String get sourceGithubFdroid => 'GitHub / F-Droid';

  @override
  String get sourceStore => 'Play Store / App Store';

  @override
  String get sourceWordOfMouth => 'Bouche-à-oreille';

  @override
  String get sourceAdvertisements => 'Publicités';

  @override
  String get sourceObsidian => 'Plugin Git Obsidian';

  @override
  String get sourceAiSearch => 'Recherche IA (ChatGPT, Claude, Grok)';

  @override
  String get sourceOther => 'Autre';

  @override
  String get sourceOtherHint => 'Dites-nous où';

  @override
  String get currentBranch => 'Branche actuelle';

  @override
  String get detachedHead => 'Tête détachée';

  @override
  String get unbornBranch => 'Branche à naître';

  @override
  String get commitsNotFound => 'Aucun commit trouvé…';

  @override
  String get repoNotFound => 'Aucun dépôt trouvé…';

  @override
  String get committed => 'validé';

  @override
  String get additions => '%s ++';

  @override
  String get deletions => '%s --';

  @override
  String get modifyRemoteUrl => 'Modifier l\'URL distante';

  @override
  String get modify => 'Modifier';

  @override
  String get remoteUrl => 'URL du dépôt distant';

  @override
  String get setRemoteUrl => 'Définir l\'URL distante';

  @override
  String get launchInBrowser => 'Ouvrir dans le navigateur';

  @override
  String get auth => 'AUTH';

  @override
  String get openFileExplorer => 'Parcourir & Modifier';

  @override
  String get syncSettings => 'Paramètres de sync';

  @override
  String get enableApplicationObserver => 'Paramètres de synchronisation de l\'appli';

  @override
  String get appSyncDescription => 'Synchronisation automatique quand l\'app sélectionnée est ouverte ou fermée';

  @override
  String get appSyncIosDescription => 'Synchronisation automatique quand GitSync est ouvert ou fermé';

  @override
  String get iosAppSyncDocsLinkText => 'Synchroniser lors de l\'ouverture/fermeture d\'autres applications';

  @override
  String get accessibilityServiceDisclosureTitle => 'Avis de service d\'accessibilité';

  @override
  String get accessibilityServiceDisclosureMessage =>
      'Pour améliorer votre expérience,\nGitSync utilise le service d\'accessibilité d\'Android pour détecter quand les applications sont ouvertes ou fermées.\n\nCela nous aide à fournir des fonctionnalités personnalisées sans stocker ni partager de données.\n\nᴠᴇᴜɪʟʟᴇᴢ ᴀᴄᴛɪᴠᴇʀ ɢɪᴛsʏɴᴄ sᴜʀ ʟᴀ ᴘʀᴏᴄʜᴀɪɴᴇ Éᴄʀᴀɴ';

  @override
  String get search => 'Rechercher';

  @override
  String get searchEllipsis => 'Rechercher…';

  @override
  String get applicationNotSet => 'Choisir app(s)';

  @override
  String get selectApplication => 'Sélectionner l\'application(s)';

  @override
  String get multipleApplicationSelected => 'Sélectionné (%s)';

  @override
  String get saveApplication => 'Enregistrer';

  @override
  String get syncOnAppClosed => 'Synchroniser à la fermeture des applications';

  @override
  String get syncOnAppOpened => 'Synchroniser à l\'ouverture des applications';

  @override
  String get iosSyncOnAppClosed => 'Synchroniser à la fermeture de GitSync';

  @override
  String get iosSyncOnAppOpened => 'Synchroniser à l\'ouverture de GitSync';

  @override
  String get scheduledSyncSettings => 'Paramètres de sync planifiée';

  @override
  String get scheduledSyncDescription => 'Synchronise automatiquement en arrière-plan';

  @override
  String get tabHome => 'Accueil';

  @override
  String get iosDefaultSyncRate => 'quand iOS le permet';

  @override
  String get every => 'tous les';

  @override
  String get scheduledSync => 'Synchro planifiée';

  @override
  String get custom => 'Personnalisé';

  @override
  String get interval15min => '15 min';

  @override
  String get interval30min => '30 min';

  @override
  String get interval1hour => '1 h';

  @override
  String get interval6hours => '6 h';

  @override
  String get interval12hours => '12 h';

  @override
  String get interval1day => '1 jour';

  @override
  String get interval1week => '1 semaine';

  @override
  String get minutes => 'minute(s)';

  @override
  String get hours => 'heure(s)';

  @override
  String get days => 'jour(s)';

  @override
  String get weeks => 'semaine(s)';

  @override
  String get enhancedScheduledSync => 'Synchronisation planifiée améliorée';

  @override
  String get quickSyncSettings => 'Paramètres de synchro rapide';

  @override
  String get quickSyncDescription => 'Synchroniser via des vignettes, raccourcis ou widgets personnalisables';

  @override
  String get otherSyncSettings => 'Autres paramètres de sync';

  @override
  String get useForTileSync => 'Utiliser pour la synchronisation de vignette';

  @override
  String get useForTileManualSync => 'Utiliser pour la synchronisation manuelle de vignette';

  @override
  String get useForShortcutSync => 'Utiliser pour le raccourci de synchro';

  @override
  String get useForShortcutManualSync => 'Utiliser pour le raccourci de synchro manuelle';

  @override
  String get useForWidgetSync => 'Utiliser pour le widget de synchro';

  @override
  String get useForWidgetManualSync => 'Utiliser pour le widget de synchro manuelle';

  @override
  String get remoteAuthMismatchTitle => 'L\'authentification ne fonctionnera pas avec ce dépôt distant';

  @override
  String get remoteAuthMismatchUsesSsh => 'Ce dépôt distant utilise SSH — tapez pour changer';

  @override
  String get remoteAuthMismatchUsesHttps => 'Ce dépôt distant utilise HTTPS ou OAuth — tapez pour changer';

  @override
  String get selectYourGitProviderAndAuthenticate => 'Sélectionnez votre fournisseur Git et authentifiez-vous';

  @override
  String get oauthProviders => 'Fournisseurs oAuth';

  @override
  String get gitProtocols => 'Protocoles Git';

  @override
  String get oauthNoAffiliation => 'Authentification via des tiers ;\naucune affiliation ou approbation implicite.';

  @override
  String get replacesExistingAuth => 'Remplace l\'authentification\nexistante du conteneur';

  @override
  String get oauth => 'OAuth';

  @override
  String get copyFromContainer => 'Copier du conteneur';

  @override
  String get or => 'ou';

  @override
  String get enterPAT => 'Saisir un Personal Access Token';

  @override
  String get usePAT => 'Utiliser PAT';

  @override
  String get oauthAllRepos => 'OAuth (Tous les dépôts)';

  @override
  String get oauthScoped => 'OAuth (Limité)';

  @override
  String get ensureTokenScope => 'Assurez-vous que votre jeton inclut la portée \"repo\" pour une fonctionnalité complète.';

  @override
  String get user => 'utilisateur';

  @override
  String get exampleUser => 'JeanDupont12';

  @override
  String get token => 'jeton';

  @override
  String get exampleToken => 'ghp_1234abcd5678efgh';

  @override
  String get login => 'connexion';

  @override
  String get pubKey => 'clé publique';

  @override
  String get privKey => 'clé privée';

  @override
  String get passphrase => 'Phrase de passe';

  @override
  String get privateKey => 'Clé privée';

  @override
  String get sshPubKeyExample => 'ssh-ed25519 AABBCCDDEEFF112233445566';

  @override
  String get sshPrivKeyExample => '-----BEGIN OPENSSH PRIVATE KEY----- AABBCCDDEEFF112233445566';

  @override
  String get generateKeys => 'générer des clés';

  @override
  String get confirmKeySaved => 'confirmer que la clé publique a été enregistrée';

  @override
  String get copiedText => 'Texte copié !';

  @override
  String get confirmPrivKeyCopy => 'Confirmer la copie de la clé privée';

  @override
  String get confirmPrivKeyCopyMsg =>
      'Êtes-vous sûr de vouloir copier votre clé privée dans le presse-papiers ?\n\nToute personne ayant accès à cette clé peut contrôler votre compte. Assurez-vous de la coller uniquement dans des emplacements sécurisés et de vider votre presse-papiers par la suite.';

  @override
  String get understood => 'Compris';

  @override
  String get importPrivateKey => 'Importer la clé privée';

  @override
  String get importPrivateKeyMsg =>
      'Collez votre clé privée ci-dessous pour utiliser un compte existant.\n\nAssurez-vous de coller la clé dans un environnement sécurisé, car toute personne ayant accès à cette clé peut contrôler votre compte.';

  @override
  String get importKey => 'importer';

  @override
  String get cloneRepo => 'Cloner le dépôt distant';

  @override
  String get clone => 'cloner';

  @override
  String get chooseHowToClone => 'Choisissez comment cloner le dépôt :';

  @override
  String get directCloningMsg => 'Clonage direct : Clone le dépôt dans le dossier sélectionné';

  @override
  String get nestedCloningMsg => 'Clonage imbriqué : Crée un dossier nommé d\'après le dépôt dans le dossier sélectionné';

  @override
  String get directClone => 'Clone direct';

  @override
  String get nestedClone => 'Clone imbriqué';

  @override
  String get gitRepoUrlHint => 'https://git.abc/xyz.git';

  @override
  String get invalidRepositoryUrlTitle => 'URL de dépôt invalide !';

  @override
  String get invalidRepositoryUrlMessage => 'URL de dépôt invalide !';

  @override
  String get cloneAnyway => 'Cloner quand même';

  @override
  String get iHaveALocalRepository => 'J\'ai un dépôt local';

  @override
  String get cloningRepository => 'Clonage du dépôt…';

  @override
  String get cloneMessagePart1 => 'NE QUITTEZ PAS CET ÉCRAN';

  @override
  String get cloneMessagePart2 => 'Cela peut prendre un certain temps en fonction de la taille de votre dépôt\n';

  @override
  String get selectCloneDirectory => 'Sélectionnez un dossier pour cloner dedans';

  @override
  String get confirmCloneOverwriteTitle => 'Dossier non vide';

  @override
  String get confirmCloneOverwriteMsg => 'Le dossier que vous avez sélectionné contient déjà des fichiers. Le cloner dedans écrasera son contenu.';

  @override
  String get confirmCloneOverwriteWarning => 'Cette action est irréversible.';

  @override
  String get confirmCloneOverwriteAction => 'Écraser';

  @override
  String get repoSearchLimits => 'Limites de recherche';

  @override
  String get repoSearchLimitsDescription =>
      'La recherche examine uniquement les 100 premiers dépôts. Si le dépôt attendu n\'apparaît pas, clonez-le directement via son URL HTTPS ou SSH.';

  @override
  String get advancedOptions => 'Options avancées';

  @override
  String get shallowClone => 'Clone superficiel (Profondeur)';

  @override
  String get bareClone => 'Clone nu';

  @override
  String get cloneDepthPlaceholder => 'complet';

  @override
  String get repositorySettings => 'Paramètres du dépôt';

  @override
  String get settings => 'Paramètres';

  @override
  String get signedCommitsLabel => 'Commits signés';

  @override
  String get signedCommitsDescription => 'signer les commits pour vérifier votre identité';

  @override
  String get importCommitKey => 'Importer la clé';

  @override
  String get commitKeyImported => 'Clé importée';

  @override
  String get useSshKey => 'Utiliser la clé AUTH pour la signature des commits';

  @override
  String get syncMessageLabel => 'Message de sync';

  @override
  String get defaultSyncMessageLabel => 'Message de synchronisation par défaut';

  @override
  String get syncMessageDescription => 'utiliser %s pour la date et l\'heure';

  @override
  String get syncMessageTimeFormatLabel => 'Format de l\'heure du message de synchronisation';

  @override
  String get defaultSyncMessageTimeFormatLabel => 'Format horaire du message de synchronisation';

  @override
  String get syncMessageTimeFormatDescription => 'utilise la syntaxe standard de formatage de date et d\'heure';

  @override
  String get remoteLabel => 'distant par défaut';

  @override
  String get defaultRemote => 'origin';

  @override
  String get authorNameLabel => 'nom de l\'auteur';

  @override
  String get defaultAuthorNameLabel => 'nom d\'auteur par défaut';

  @override
  String get authorNameDescription => 'utilisé pour vous identifier dans l\'historique des validations';

  @override
  String get authorName => 'JeanDupont12';

  @override
  String get authorEmailLabel => 'e-mail de l\'auteur';

  @override
  String get defaultAuthorEmailLabel => 'email d\'auteur par défaut';

  @override
  String get authorEmailDescription => 'attaché à vos validations pour l\'attribution';

  @override
  String get authorEmail => 'jean12@dupont.com';

  @override
  String get postFooterLabel => 'pied de page';

  @override
  String get postFooterDescription => 'ajouté aux issues, commentaires et pull requests que vous créez';

  @override
  String get postFooterDialogInfo =>
      'Ce texte est automatiquement ajouté à la fin des issues, commentaires et pull requests que vous créez. Vous pouvez le modifier ou le supprimer dans les paramètres de votre dépôt.\n\nLa valeur par défaut des nouveaux dépôts peut être définie dans les paramètres globaux, sous Valeurs par défaut des dépôts.';

  @override
  String get gitIgnore => '.gitignore';

  @override
  String get gitIgnoreDescription => 'liste des fichiers ou dossiers à ignorer sur tous les appareils';

  @override
  String get gitIgnoreHint => '.trash/\n./…';

  @override
  String get gitInfoExclude => '.git/info/exclude';

  @override
  String get gitInfoExcludeDescription => 'liste des fichiers ou dossiers à ignorer sur cet appareil';

  @override
  String get gitInfoExcludeHint => '.trash/\n./…';

  @override
  String get disableSsl => 'Désactiver le SSL';

  @override
  String get disableSslDescription => 'Désactiver la connexion sécurisée pour les dépôts HTTP';

  @override
  String get disableSslPromptTitle => 'Désactiver le SSL ?';

  @override
  String get disableSslPromptMsg =>
      'L\'adresse que vous avez clonée commence par \"http\" (non sécurisé). La désactivation du SSL correspondra à l\'URL mais réduira la sécurité.';

  @override
  String get optimisedSync => 'Synchro optimisée';

  @override
  String get optimisedSyncDescription => 'Réduire intelligemment les opérations de synchronisation';

  @override
  String get proceedAnyway => 'Continuer quand même ?';

  @override
  String get moreOptions => 'Plus d\'options';

  @override
  String get untrackAll => 'Tout désindexer';

  @override
  String get globalSettings => 'Paramètres globaux';

  @override
  String get darkMode => 'Mode\nsombre';

  @override
  String get lightMode => 'Mode\nclair';

  @override
  String get system => 'Système';

  @override
  String get language => 'Langue';

  @override
  String get browseEditDir => 'Parcourir & Modifier le répertoire';

  @override
  String get enableLineWrap => 'Activer le retour à la ligne dans les éditeurs';

  @override
  String get excludeFromRecents => 'Exclure des récents';

  @override
  String get backupRestoreTitle => 'Récupération de configuration chiffrée';

  @override
  String get encryptedBackup => 'Sauvegarde chiffrée';

  @override
  String get encryptedRestore => 'Restauration chiffrée';

  @override
  String get backup => 'Sauvegarde';

  @override
  String get restore => 'Restaurer';

  @override
  String get selectBackupLocation => 'Sélectionnez l\'emplacement pour enregistrer la sauvegarde';

  @override
  String get backupFileTemplate => 'backup_%s.gsbak';

  @override
  String get enterPassword => 'Entrez le mot de passe %s';

  @override
  String get invalidPassword => 'Mot de passe invalide';

  @override
  String get community => 'Communauté';

  @override
  String get guides => 'Guides';

  @override
  String get documentation => 'Guides et Wiki';

  @override
  String get viewDocumentation => 'Afficher les guides et le wiki';

  @override
  String get requestAFeature => 'Demander une fonctionnalité';

  @override
  String get contributeTitle => 'Soutenez notre travail';

  @override
  String get improveTranslations => 'Améliorer les traductions';

  @override
  String get joinTheDiscussion => 'Rejoindre le Discord';

  @override
  String get noLogFilesFound => 'Aucun fichier journal trouvé !';

  @override
  String get guidedSetup => 'Configuration guidée';

  @override
  String get uiGuide => 'Guide de l\'interface utilisateur';

  @override
  String get viewPrivacyPolicy => 'Confidentialité';

  @override
  String get viewEula => 'Conditions d\'utilisation (CLUF)';

  @override
  String get shareLogs => 'Partager les journaux';

  @override
  String get logsEmailSubjectTemplate => 'Journaux GitSync (%s)';

  @override
  String get logsEmailRecipient => 'bugsviscouspotential@gmail.com';

  @override
  String get repositoryDefaults => 'Valeurs par défaut du dépôt';

  @override
  String get miscellaneous => 'Divers';

  @override
  String get dangerZone => 'Zone dangereuse';

  @override
  String get file => 'Fichier';

  @override
  String get folder => 'Dossier';

  @override
  String get directory => 'Répertoire';

  @override
  String get confirmFileDirDeleteMsg => 'Êtes-vous sûr de vouloir supprimer le %s \"%s\" %s?';

  @override
  String get deleteMultipleSuffix => 'et %s de plus et leur contenu';

  @override
  String get deleteSingularSuffix => 'et son contenu';

  @override
  String get createAFile => 'Créer un fichier';

  @override
  String get fileName => 'Nom du fichier';

  @override
  String get createADir => 'Créer un répertoire';

  @override
  String get dirName => 'Nom du dossier';

  @override
  String get renameFileDir => 'Renommer %s';

  @override
  String get fileTooLarge => 'Fichier de plus de %s lignes';

  @override
  String get readOnly => 'Lecture seule';

  @override
  String get cut => 'Couper';

  @override
  String get copy => 'Copier';

  @override
  String get paste => 'Coller';

  @override
  String get experimental => 'Expérimental';

  @override
  String get experimentalMsg => 'Utilisez à vos risques et périls';

  @override
  String get codeEditorLimits => 'Limites de l\'éditeur';

  @override
  String get codeEditorLimitsDescription =>
      'L\'éditeur offre une édition basique. Si vous rencontrez des bugs, merci de signaler via les options de signalement.';

  @override
  String get openFile => 'Ouvrir le fichier';

  @override
  String get openFileDescription => 'Prévisualiser/éditer le contenu';

  @override
  String get viewGitLog => 'voir le journal git';

  @override
  String get viewGitLogDescription => 'Voir l\'historique complet du journal git';

  @override
  String get openInTextastic => 'Open in Textastic';

  @override
  String get openInTextasticDescription => 'Open file in Textastic app';

  @override
  String get ignoreUntrack => '.gitignore + Désindexer';

  @override
  String get ignoreUntrackDescription => 'Ajouter au .gitignore et désindexer';

  @override
  String get excludeUntrack => '.git/info/exclude + Désindexer';

  @override
  String get excludeUntrackDescription => 'Ajouter au fichier d\'exclusion local et désindexer';

  @override
  String get ignoreOnly => 'Ajouter seulement à .gitignore';

  @override
  String get ignoreOnlyDescription => 'Ajouter uniquement au .gitignore';

  @override
  String get excludeOnly => 'Ajouter seulement à .git/info/exclude';

  @override
  String get excludeOnlyDescription => 'Ajouter uniquement au fichier d\'exclusion local';

  @override
  String get untrack => 'Désindexer le(s) fichier(s)';

  @override
  String get untrackDescription => 'Désindexer le(s) fichier(s) spécifié(s)';

  @override
  String get selected => 'sélectionné';

  @override
  String get ignoreAndUntrack => 'Ignorer et désindexer';

  @override
  String get open => 'Ouvrir';

  @override
  String get fileDiff => 'Diff du fichier';

  @override
  String get openEditFile => 'Ouvrir/Éditer le fichier';

  @override
  String get filesChanged => 'fichier(s) modifié(s)';

  @override
  String get commits => 'validations';

  @override
  String get defaultContainerName => 'alias';

  @override
  String get renameRepository => 'Renommer le conteneur';

  @override
  String get renameRepositoryMsg => 'Entrez un nouvel alias pour le conteneur du dépôt';

  @override
  String get addMore => 'Ajouter plus';

  @override
  String get addRepository => 'Ajouter un conteneur';

  @override
  String get addRepositoryMsg => 'Donnez un alias unique à votre nouveau conteneur de dépôt. Cela vous aidera à l\'identifier plus tard.';

  @override
  String get confirmRepositoryDelete => 'Confirmer la suppression du conteneur';

  @override
  String get confirmRepositoryDeleteMsg => 'Voulez-vous vraiment supprimer le conteneur de dépôt \"%s\" ?';

  @override
  String get deleteRepoDirectoryCheckbox => 'Supprimer également le répertoire du dépôt et tout son contenu';

  @override
  String get confirmRepositoryDeleteTitle => 'Confirmer la suppression du conteneur';

  @override
  String get confirmRepositoryDeleteMessage => 'Voulez-vous vraiment supprimer le dépôt \"%s\" et son contenu ?';

  @override
  String get submodulesFoundTitle => 'Sous-modules trouvés';

  @override
  String get submodulesFoundMessage =>
      'Le dépôt que vous avez ajouté contient des sous-modules. Souhaitez-vous les ajouter automatiquement en tant que dépôts séparés dans l\'application ?\n\nCeci est une fonctionnalité premium.';

  @override
  String get submodulesFoundAction => 'Ajouter les sous-modules';

  @override
  String get addRemote => 'Ajouter un dépôt distant';

  @override
  String get deleteRemote => 'Supprimer le dépôt distant';

  @override
  String get renameRemote => 'Renommer le dépôt distant';

  @override
  String get remoteName => 'Nom du dépôt distant';

  @override
  String get confirmDeleteRemote => 'Voulez-vous vraiment supprimer le dépôt distant « %s » ?';

  @override
  String get orEnterManually => 'ou saisir manuellement';

  @override
  String get createOnProvider => 'Créer sur %s';

  @override
  String get confirmBranchCheckoutTitle => 'Changer de branche ?';

  @override
  String get confirmBranchCheckoutMsgPart1 => 'Voulez-vous vraiment changer pour la branche ';

  @override
  String get confirmBranchCheckoutMsgPart2 => ' ?';

  @override
  String get unsavedChangesMayBeLost => 'Les modifications non enregistrées peuvent être perdues.';

  @override
  String get checkout => 'Changer';

  @override
  String get create => 'Créer';

  @override
  String get createBranch => 'Créer une nouvelle branche';

  @override
  String get createBranchName => 'Nom de la branche';

  @override
  String get createBranchBasedOn => 'Basé sur';

  @override
  String get renameBranch => 'Renommer la branche';

  @override
  String get deleteBranch => 'Supprimer la branche ?';

  @override
  String get confirmDeleteBranchMsg => 'Voulez-vous vraiment supprimer la branche « %s » ?';

  @override
  String get menuAmendCommit => 'Amender la validation';

  @override
  String get menuAmendCommitDesc => 'Modifier le message ou le contenu de la dernière validation';

  @override
  String get menuUndoCommit => 'Annuler la validation';

  @override
  String get menuUndoCommitDesc => 'Annuler cette validation mais garder les modifications indexées';

  @override
  String get menuResetToCommit => 'Réinitialiser à la validation';

  @override
  String get menuResetToCommitDesc => 'Supprimer toutes les validations après celle-ci';

  @override
  String get menuCheckoutCommit => 'Extraire la validation';

  @override
  String get menuCheckoutCommitDesc => 'Extraire cette validation (HEAD détaché)';

  @override
  String get menuRevertCommit => 'Revert les modifications';

  @override
  String get menuRevertCommitDesc => 'Créer une nouvelle validation qui annule ces modifications';

  @override
  String get menuCreateBranch => 'Créer une branche';

  @override
  String get menuCreateBranchDesc => 'Créer une nouvelle branche à partir de cette validation';

  @override
  String get menuCreateTag => 'Créer une étiquette';

  @override
  String get menuCreateTagDesc => 'Créer une étiquette sur cette validation';

  @override
  String get menuCherryPick => 'Cherry Pick la validation';

  @override
  String get menuCherryPickDesc => 'Appliquer cette validation sur la branche courante';

  @override
  String get menuSelectCommits => 'Sélectionner des validations';

  @override
  String get menuSelectCommitsDesc => 'Sélectionner plusieurs validations pour des opérations par lots';

  @override
  String get menuCopySha => 'Copier SHA';

  @override
  String get menuCopyShaDesc => 'Copier le hash complet de la validation dans le presse-papiers';

  @override
  String get menuCopyTag => 'Copier l\'étiquette';

  @override
  String get menuCopyTagDesc => 'Copier le nom de l\'étiquette dans le presse-papiers';

  @override
  String get menuViewOnProvider => 'Voir sur %s';

  @override
  String get menuViewOnProviderDesc => 'Ouvrir cette validation dans votre navigateur';

  @override
  String get createBranchFromCommit => 'Créer une branche depuis la validation';

  @override
  String get createBranchFromCommitMsg => 'Créer une nouvelle branche à partir de la validation %s.';

  @override
  String get checkoutCommit => 'Extraire la validation';

  @override
  String get checkoutCommitMsg => 'Cela vous placera dans un état HEAD détaché à la validation';

  @override
  String get checkoutCommitDetachedWarning => 'Vous ne serez sur aucune branche. Créez une nouvelle branche pour conserver vos modifications.';

  @override
  String get createTagOnCommit => 'Créer une étiquette';

  @override
  String get createTagOnCommitMsg => 'Créer une étiquette sur la validation %s.';

  @override
  String get tagName => 'Nom de l\'étiquette';

  @override
  String get revertCommit => 'Revert la validation';

  @override
  String get revertCommitMsg => 'Revert les modifications introduites par la validation';

  @override
  String get revertCommitWarning => 'Cela créera une nouvelle validation qui annule les modifications.';

  @override
  String get revert => 'Revert';

  @override
  String get amendCommit => 'Amender la validation';

  @override
  String get amendCommitMsg => 'Modifier le message de la validation';

  @override
  String get amendCommitWarning => 'Cela réécrira la validation. Un push forcé peut être nécessaire si cette validation a déjà été poussée.';

  @override
  String get amend => 'Amender';

  @override
  String get undoCommit => 'Annuler la validation';

  @override
  String get undoCommitMsg => 'Annuler la validation';

  @override
  String get undoCommitWarning => 'La validation sera supprimée mais vos modifications resteront indexées.';

  @override
  String get undo => 'Annuler';

  @override
  String get resetToCommit => 'Réinitialiser à la validation';

  @override
  String get resetToCommitMsg => 'Réinitialiser à la validation';

  @override
  String get resetToCommitWarning =>
      'Toutes les validations après celle-ci seront définitivement perdues et les modifications du répertoire de travail seront supprimées. Cette action est irréversible.';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get cherryPickCommit => 'Cherry Pick la validation';

  @override
  String get cherryPickCommitMsg => 'Appliquer les modifications de la validation';

  @override
  String get cherryPickCommitWarning => 'Cela peut produire des conflits de fusion si les modifications chevauchent la branche cible.';

  @override
  String get cherryPickTargetBranch => 'Branche cible';

  @override
  String get cherryPick => 'Cherry Pick';

  @override
  String get cherryPickCommits => 'Cherry Pick des validations';

  @override
  String get cherryPickCommitsMsg => 'Appliquer les modifications de %s validations sur';

  @override
  String get cherryPickCommitsWarning =>
      'Les validations seront appliquées dans l\'ordre chronologique. Des conflits peuvent survenir à chaque étape.';

  @override
  String get squashCommits => 'Squash des validations';

  @override
  String get squashCommitsMsg => 'Combiner %s validations en une seule';

  @override
  String get squashCommitsWarning =>
      'Cela réécrit l\'historique des validations. Si ces validations ont déjà été poussées, un push forcé sera nécessaire.';

  @override
  String get squash => 'Squash';

  @override
  String get squashCommitMessage => 'Message de squash';

  @override
  String get selectCommits => 'Sélectionner des validations';

  @override
  String get selectedCount => '%s sélectionné(s)';

  @override
  String get squashRequiresConsecutive => 'Le squash nécessite des validations consécutives à partir de la dernière validation';

  @override
  String get issues => 'Issues';

  @override
  String get issueFilterOpen => 'Ouvertes';

  @override
  String get issueFilterClosed => 'Fermées';

  @override
  String get issueFilterAll => 'Toutes';

  @override
  String get issuesNotFound => 'Aucune issue trouvée…';

  @override
  String get filterAuthor => 'Auteur';

  @override
  String get filterLabels => 'Étiquettes';

  @override
  String get filterAssignee => 'Assigné';

  @override
  String get filterMilestone => 'Jalon';

  @override
  String get filterProject => 'Projet';

  @override
  String get filterNone => 'Aucun';

  @override
  String get filterMilestonesEmpty => 'Aucun jalon trouvé';

  @override
  String get filterProjectsEmpty => 'Aucun projet trouvé';

  @override
  String get sortNewest => 'Plus récentes';

  @override
  String get sortOldest => 'Plus anciennes';

  @override
  String get sortMostCommented => 'Plus commentées';

  @override
  String get sortRecentlyUpdated => 'Récemment mises à jour';

  @override
  String get filterSidebar => 'Filtres';

  @override
  String get filterReviewer => 'Relecteur';

  @override
  String get pullRequests => 'Pull Requests';

  @override
  String get pullRequestsNotFound => 'Aucune pull request trouvée…';

  @override
  String get tags => 'Étiquettes';

  @override
  String get tagsNotFound => 'Aucune étiquette trouvée…';

  @override
  String get releases => 'Releases';

  @override
  String get releasesNotFound => 'Aucune release trouvée…';

  @override
  String get preRelease => 'PRÉ-RELEASE';

  @override
  String get draft => 'BROUILLON';

  @override
  String get releaseAssets => 'Ressources';

  @override
  String get noAssets => 'Aucune ressource';

  @override
  String get actions => 'Actions';

  @override
  String get actionsNotFound => 'Aucune action trouvée…';

  @override
  String get actionFilterAll => 'Toutes';

  @override
  String get actionFilterSuccess => 'Succès';

  @override
  String get actionFilterFailed => 'Échec';

  @override
  String get attemptAutoFix => 'Correction auto ?';

  @override
  String get troubleshooting => 'Dépannage';

  @override
  String get youreOffline => 'Vous êtes hors ligne.';

  @override
  String get someFeaturesMayNotWork => 'Certaines fonctionnalités peuvent ne pas fonctionner.';

  @override
  String get unsupportedGitAttributes => 'Ce dépôt utilise des filtres git, disponibles uniquement dans les versions boutique.';

  @override
  String get tapToOpenPlayStore => 'Tapez pour mettre à jour.';

  @override
  String get ongoingMergeConflict => 'Conflit de fusion en cours';

  @override
  String get networkStallRetry => 'Connexion lente — nouvelle tentative';

  @override
  String get networkUnavailableRetry => 'Réseau indisponible !\nGitSync réessaiera lors de la reconnexion';

  @override
  String get networkStallManual => 'Connexion lente — veuillez réessayer';

  @override
  String get networkUnavailableManual => 'Réseau indisponible — veuillez réessayer';

  @override
  String get networkRetryComplete => 'Opération en file d\'attente terminée';

  @override
  String get failedToResolveAddressMessage => 'Impossible d\'atteindre le serveur. Vérifiez votre connexion internet ou l\'URL du dépôt.';

  @override
  String get pullFailed => 'Échec du pull ! Veuillez vérifier les modifications non validées et réessayer.';

  @override
  String get reportABug => 'Signaler un bug';

  @override
  String get errorOccurredTitle => 'Une erreur s\'est produite !';

  @override
  String get errorOccurredMessagePart1 =>
      'Si cela a causé des problèmes, veuillez créer rapidement un rapport de bug en utilisant le bouton ci-dessous.';

  @override
  String get errorOccurredMessagePart2 => 'Sinon, vous pouvez ignorer et continuer.';

  @override
  String get cloneFailed => 'Échec du clonage du dépôt !';

  @override
  String get mergingExceptionMessage => 'FUSION EN COURS';

  @override
  String get fieldCannotBeEmpty => 'Le champ ne peut pas être vide';

  @override
  String get androidLimitedFilepathCharacters =>
      'Ce problème est dû aux restrictions de nommage Android. Veuillez renommer les fichiers concernés sur un autre appareil et resynchroniser.\n\nCaractères non supportés : \" * / : < > ? \\ |';

  @override
  String get emptyNameOrEmail => 'Votre configuration Git est incomplète : nom d\'auteur ou email manquant.';

  @override
  String get errorReadingZlibStream => 'Un problème connu sur certains appareils, résolu avec la dernière version legacy de l\'application.';

  @override
  String get gitObsidianFoundTitle => 'Avertissement Obsidian Git';

  @override
  String get gitObsidianFoundMessage =>
      'Ce dépôt semble contenir un coffre Obsidian avec le plugin Obsidian Git activé.\n\nVeuillez désactiver le plugin sur cet appareil pour éviter des conflits !';

  @override
  String get gitObsidianFoundAction => 'Voir la documentation';

  @override
  String get githubIssueOauthTitle => 'Connectez GitHub pour signaler automatiquement';

  @override
  String get githubIssueOauthMsg =>
      'Vous devez connecter votre compte GitHub pour signaler les bugs et suivre leur progression.\nVous pouvez réinitialiser cette connexion à tout moment dans les paramètres globaux.';

  @override
  String get includeLogs => 'Inclure le(s) fichier(s) journal';

  @override
  String get issueReportTitleTitle => 'Titre';

  @override
  String get issueReportTitleDesc => 'Quelques mots résumant le problème';

  @override
  String get issueReportDescTitle => 'Description';

  @override
  String get issueReportDescDesc => 'Expliquez plus en détail ce qui se passe';

  @override
  String get issueReportMinimalReproTitle => 'Étapes de reproduction';

  @override
  String get issueReportMinimalReproDesc => 'Décrivez les étapes menant à l\'erreur';

  @override
  String get includeLogFiles => 'Inclure le(s) fichier(s) journal';

  @override
  String get includeLogFilesDescription =>
      'Inclure les fichiers journaux est vivement recommandé.\n\nSi vous désactivez cette option, veuillez copier les extraits pertinents dans votre rapport.\n\nL\'inclusion des journaux est facultative.';

  @override
  String get report => 'Signaler';

  @override
  String get issueReportSuccessTitle => 'Problème signalé avec succès';

  @override
  String get issueReportSuccessMsg =>
      'Votre problème a été signalé. Marquez cette page pour suivre la progression et répondre aux messages.\n\nVeuillez éviter de créer des problèmes en double, car cela rend la résolution plus difficile.\n\nLes problèmes sans activité pendant 7 jours sont automatiquement fermés.';

  @override
  String get trackIssue => 'Suivre le problème et répondre aux messages';

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
  String get createNewRepository => 'Créer un nouveau dépôt';

  @override
  String get noGitRepoFoundMsg => 'Aucun dépôt git trouvé dans le dossier sélectionné. Voulez-vous en créer un nouveau ici ?';

  @override
  String get remoteSetupLaterMsg => 'Cela crée un dépôt local.\nAuthentifiez-vous et ajoutez un dépôt distant pour activer la synchronisation.';

  @override
  String get localOnlyNoRemote => 'Local uniquement — ajoutez un dépôt distant pour synchroniser';

  @override
  String get noRemoteConfigured => 'Aucun dépôt distant configuré';

  @override
  String get createRemoteRepo => 'Créer un dépôt distant';

  @override
  String get repoName => 'Nom du dépôt';

  @override
  String get repoPublic => 'Public';

  @override
  String get repoPrivate => 'Privé';

  @override
  String get creatingRemoteRepo => 'Création du dépôt distant…';

  @override
  String get remoteRepoCreated => 'Dépôt distant créé et lié comme origin';

  @override
  String get remoteRepoCreateFailed => 'Échec de la création du dépôt distant';

  @override
  String get noRemoteDetectedMsg => 'Ce dépôt n\'a pas de dépôt distant configuré. Souhaitez-vous en créer un ?';

  @override
  String get createAndLinkRemote => 'Créer et lier un dépôt distant';

  @override
  String get createLocalOnly => 'Local uniquement';

  @override
  String get initMainBranch => 'Initialiser la branche main';

  @override
  String get continueLabel => 'Continuer';

  @override
  String get githubScopedLoginTitle => 'Étape 1 : Connexion à GitHub';

  @override
  String get githubScopedLoginMsg =>
      'Vous serez redirigé vers GitHub pour vous connecter.\n\nConnectez-vous avec le compte qui a accès à vos dépôts, puis autorisez GitSync.';

  @override
  String get githubScopedRepoTitle => 'Étape 2 : Sélectionner des dépôts';

  @override
  String get githubScopedRepoMsg =>
      'Choisissez les dépôts auxquels GitSync peut accéder.\n\nUne fois terminé, fermez le navigateur pour revenir à l\'app.';

  @override
  String get issueDescription => 'Description';

  @override
  String get issueNoDescription => 'Aucune description fournie';

  @override
  String get issueComments => 'Commentaires';

  @override
  String get issueNoComments => 'Aucun commentaire pour l\'instant';

  @override
  String get issueAddComment => 'Ajouter un commentaire…';

  @override
  String get issueSubmitComment => 'Envoyer';

  @override
  String get issueCloseIssue => 'Fermer l\'issue';

  @override
  String get issueReopenIssue => 'Rouvrir l\'issue';

  @override
  String get issueAddReaction => 'Ajouter une réaction';

  @override
  String get issueWriteDisabled => 'Vous n\'avez pas les droits d\'écriture';

  @override
  String get issueStateUpdated => 'État de l\'issue mis à jour';

  @override
  String get issueCommentAdded => 'Commentaire ajouté';

  @override
  String get issueCommentFailed => 'Échec de l\'ajout du commentaire';

  @override
  String get issueStateUpdateFailed => 'Échec de la mise à jour de l\'état';

  @override
  String get issueReactionFailed => 'Échec de la mise à jour de la réaction';

  @override
  String get issuePreview => 'Aperçu';

  @override
  String get issueWrite => 'Écrire';

  @override
  String get issueEditSuccess => 'Issue mise à jour';

  @override
  String get issueEditFailed => 'Échec de la mise à jour de l\'issue';

  @override
  String get createIssue => 'Créer une issue';

  @override
  String get createIssueTitle => 'Titre';

  @override
  String get createIssueTitleHint => 'Titre de l\'issue';

  @override
  String get createIssueBody => 'Description';

  @override
  String get createIssueBodyHint => 'Décrivez l\'issue…';

  @override
  String get createIssueSubmit => 'Envoyer l\'issue';

  @override
  String get createIssueSuccess => 'Issue créée avec succès';

  @override
  String get createIssueFailed => 'Échec de la création de l\'issue';

  @override
  String get createIssueBlankIssue => 'Issue vierge';

  @override
  String get createIssueSelectTemplate => 'Choisir un modèle';

  @override
  String get createIssueRequired => 'Requis';

  @override
  String get createPr => 'Créer une pull request';

  @override
  String get createPrTitle => 'Titre';

  @override
  String get createPrTitleHint => 'Titre de la pull request';

  @override
  String get createPrBody => 'Description';

  @override
  String get createPrBodyHint => 'Décrivez vos modifications…';

  @override
  String get createPrSubmit => 'Créer la pull request';

  @override
  String get createPrSuccess => 'Pull request créée';

  @override
  String get createPrFailed => 'Échec de la création de la pull request';

  @override
  String get createPrBaseBranch => 'Base';

  @override
  String get createPrHeadBranch => 'Comparer';

  @override
  String get createPrSelectBranch => 'Sélectionner une branche';

  @override
  String get prDescription => 'Description';

  @override
  String get prNoDescription => 'Aucune description fournie';

  @override
  String get prActivity => 'Activité';

  @override
  String get prNoActivity => 'Aucune activité pour l\'instant';

  @override
  String get prCommits => 'Validations';

  @override
  String get prCommitsNotFound => 'Aucune validation trouvée';

  @override
  String get prChecks => 'Vérifications';

  @override
  String get prChecksNotFound => 'Aucune vérification trouvée';

  @override
  String get prAllChecksPassed => 'Toutes les vérifications réussies';

  @override
  String prChecksFailed(Object count) {
    return '$count vérification(s) échouée(s)';
  }

  @override
  String get prChecksPending => 'Vérifications en attente';

  @override
  String get prFilesChanged => 'Fichiers modifiés';

  @override
  String get prFilesChangedNotFound => 'Aucun fichier modifié trouvé';

  @override
  String get prConversation => 'Conversation';

  @override
  String get prApproved => 'Approuvée';

  @override
  String get prChangesRequested => 'Modifications demandées';

  @override
  String get prCommented => 'Commenté';

  @override
  String get prNotFound => 'Pull request introuvable';

  @override
  String get prCommentAdded => 'Commentaire ajouté';

  @override
  String get prCommentFailed => 'Échec de l\'ajout du commentaire';

  @override
  String get prReactionFailed => 'Échec de la mise à jour de la réaction';

  @override
  String get prMentionedInPr => 'mentionné dans la pull request';

  @override
  String get prMentionedInIssue => 'mentionné dans l\'issue';

  @override
  String prForcePushed(Object after, Object before) {
    return 'force-push de $before vers $after';
  }

  @override
  String get recentCommits => 'Validations récentes';

  @override
  String get branchManagement => 'Gestion des branches';

  @override
  String get providerTools => 'Outils du fournisseur';

  @override
  String get tabChat => 'Discussion';

  @override
  String get tabFiles => 'Fichiers';

  @override
  String get chatComingSoon => 'Fonctionnalités de chat à venir';

  @override
  String get chatComingSoonSubtitle => 'Interagissez avec vos fichiers via Claude Code';

  @override
  String get noRepoSetup => 'Configurez d\'abord un dépôt';

  @override
  String get enableAiFeatures => 'Activer les fonctionnalités IA';

  @override
  String get hideAiFeatures => 'Masquer les fonctionnalités IA';

  @override
  String get hideAiFeaturesConfirmTitle => 'Masquer les fonctionnalités IA ?';

  @override
  String get hideAiFeaturesConfirmMsg =>
      'Cela supprimera l\'onglet IA et tous les boutons IA dans l\'application. Vous pouvez réactiver les fonctionnalités IA à tout moment depuis les paramètres globaux.';

  @override
  String get aiSetupTitle => 'Configurer l\'IA';

  @override
  String get aiSetupMsg => 'Configurez un fournisseur d\'IA pour utiliser cette fonctionnalité. Aller dans les paramètres IA ?';
}
