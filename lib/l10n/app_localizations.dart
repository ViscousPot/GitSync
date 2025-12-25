import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ru'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @learnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn More'**
  String get learnMore;

  /// No description provided for @loadingElipsis.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loadingElipsis;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @optionalLabel.
  ///
  /// In en, this message translates to:
  /// **'(optional)'**
  String get optionalLabel;

  /// No description provided for @ios.
  ///
  /// In en, this message translates to:
  /// **'iOS'**
  String get ios;

  /// No description provided for @android.
  ///
  /// In en, this message translates to:
  /// **'Android'**
  String get android;

  /// No description provided for @syncStarting.
  ///
  /// In en, this message translates to:
  /// **'Detecting changes…'**
  String get syncStarting;

  /// No description provided for @syncStartPull.
  ///
  /// In en, this message translates to:
  /// **'Syncing changes…'**
  String get syncStartPull;

  /// No description provided for @syncStartPush.
  ///
  /// In en, this message translates to:
  /// **'Syncing local changes…'**
  String get syncStartPush;

  /// No description provided for @syncNotRequired.
  ///
  /// In en, this message translates to:
  /// **'Sync not required!'**
  String get syncNotRequired;

  /// No description provided for @syncComplete.
  ///
  /// In en, this message translates to:
  /// **'Repository synced!'**
  String get syncComplete;

  /// No description provided for @syncInProgress.
  ///
  /// In en, this message translates to:
  /// **'Sync In Progress'**
  String get syncInProgress;

  /// No description provided for @syncScheduled.
  ///
  /// In en, this message translates to:
  /// **'Sync Scheduled'**
  String get syncScheduled;

  /// No description provided for @detectingChanges.
  ///
  /// In en, this message translates to:
  /// **'Detecting Changes…'**
  String get detectingChanges;

  /// No description provided for @thisActionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get thisActionCannotBeUndone;

  /// No description provided for @cloneProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'clone progress'**
  String get cloneProgressLabel;

  /// No description provided for @forcePushProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'force push progress'**
  String get forcePushProgressLabel;

  /// No description provided for @forcePullProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'force pull progress'**
  String get forcePullProgressLabel;

  /// No description provided for @moreSyncOptionsLabel.
  ///
  /// In en, this message translates to:
  /// **'more sync options'**
  String get moreSyncOptionsLabel;

  /// No description provided for @repositorySettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'repository settings'**
  String get repositorySettingsLabel;

  /// No description provided for @addBranchLabel.
  ///
  /// In en, this message translates to:
  /// **'add branch'**
  String get addBranchLabel;

  /// No description provided for @deselectDirLabel.
  ///
  /// In en, this message translates to:
  /// **'deselect directory'**
  String get deselectDirLabel;

  /// No description provided for @selectDirLabel.
  ///
  /// In en, this message translates to:
  /// **'select directory'**
  String get selectDirLabel;

  /// No description provided for @syncMessagesLabel.
  ///
  /// In en, this message translates to:
  /// **'disable/enable sync messages'**
  String get syncMessagesLabel;

  /// No description provided for @backLabel.
  ///
  /// In en, this message translates to:
  /// **'back'**
  String get backLabel;

  /// No description provided for @authDropdownLabel.
  ///
  /// In en, this message translates to:
  /// **'auth dropdown'**
  String get authDropdownLabel;

  /// No description provided for @premiumDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock Premium'**
  String get premiumDialogTitle;

  /// No description provided for @premiumDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'This feature is part of the premium experience.\nMake a one-time payment of %s to unlock it and enjoy more powerful tools.\n\nPremium Features:\n • Multi-repo support\n\nAlternatively, connect your GitHub account to check if you\'re an eligible GitHub Sponsor.'**
  String get premiumDialogMessage;

  /// No description provided for @premiumDialogButtonText.
  ///
  /// In en, this message translates to:
  /// **'Unlock for %s'**
  String get premiumDialogButtonText;

  /// No description provided for @premiumDialogGitHubButtonText.
  ///
  /// In en, this message translates to:
  /// **'Use GitHub Sponsors'**
  String get premiumDialogGitHubButtonText;

  /// No description provided for @restorePurchase.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchase'**
  String get restorePurchase;

  /// No description provided for @verifyGhSponsorTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify GitHub Sponsorship'**
  String get verifyGhSponsorTitle;

  /// No description provided for @verifyGhSponsorMsg.
  ///
  /// In en, this message translates to:
  /// **'If you are a GitHub Sponsor, you can access premium features for free. Authenticate with GitHub so we can verify your sponsor status.'**
  String get verifyGhSponsorMsg;

  /// No description provided for @verifyGhSponsorNote.
  ///
  /// In en, this message translates to:
  /// **'Note: new sponsorships may take up to 1 day to become available in the app.'**
  String get verifyGhSponsorNote;

  /// No description provided for @switchToClientMode.
  ///
  /// In en, this message translates to:
  /// **'Switch to Client Mode…'**
  String get switchToClientMode;

  /// No description provided for @switchToSyncMode.
  ///
  /// In en, this message translates to:
  /// **'Switch to Sync Mode…'**
  String get switchToSyncMode;

  /// No description provided for @clientMode.
  ///
  /// In en, this message translates to:
  /// **'Client Mode'**
  String get clientMode;

  /// No description provided for @clientModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Expanded Git UI\n(Advanced)'**
  String get clientModeDescription;

  /// No description provided for @syncMode.
  ///
  /// In en, this message translates to:
  /// **'Sync Mode'**
  String get syncMode;

  /// No description provided for @syncModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Automated syncing\n(Beginner-friendly)'**
  String get syncModeDescription;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Changes'**
  String get syncNow;

  /// No description provided for @syncAllChanges.
  ///
  /// In en, this message translates to:
  /// **'Sync All Changes'**
  String get syncAllChanges;

  /// No description provided for @stageAndCommit.
  ///
  /// In en, this message translates to:
  /// **'Stage & Commit'**
  String get stageAndCommit;

  /// No description provided for @downloadChanges.
  ///
  /// In en, this message translates to:
  /// **'Download Changes'**
  String get downloadChanges;

  /// No description provided for @uploadChanges.
  ///
  /// In en, this message translates to:
  /// **'Upload Changes'**
  String get uploadChanges;

  /// No description provided for @downloadAndOverwrite.
  ///
  /// In en, this message translates to:
  /// **'Download + Overwrite'**
  String get downloadAndOverwrite;

  /// No description provided for @uploadAndOverwrite.
  ///
  /// In en, this message translates to:
  /// **'Upload + Overwrite'**
  String get uploadAndOverwrite;

  /// No description provided for @fetchRemote.
  ///
  /// In en, this message translates to:
  /// **'Fetch %s'**
  String get fetchRemote;

  /// No description provided for @pullChanges.
  ///
  /// In en, this message translates to:
  /// **'Pull Changes'**
  String get pullChanges;

  /// No description provided for @pushChanges.
  ///
  /// In en, this message translates to:
  /// **'Push Changes'**
  String get pushChanges;

  /// No description provided for @updateSubmodules.
  ///
  /// In en, this message translates to:
  /// **'Update Submodules'**
  String get updateSubmodules;

  /// No description provided for @forcePush.
  ///
  /// In en, this message translates to:
  /// **'Force Push'**
  String get forcePush;

  /// No description provided for @forcePushing.
  ///
  /// In en, this message translates to:
  /// **'Force pushing…'**
  String get forcePushing;

  /// No description provided for @confirmForcePush.
  ///
  /// In en, this message translates to:
  /// **'Confirm Force Push'**
  String get confirmForcePush;

  /// No description provided for @confirmForcePushMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to force push these changes? Any ongoing merge conflicts will be aborted.'**
  String get confirmForcePushMsg;

  /// No description provided for @forcePull.
  ///
  /// In en, this message translates to:
  /// **'Force Pull'**
  String get forcePull;

  /// No description provided for @forcePulling.
  ///
  /// In en, this message translates to:
  /// **'Force pulling…'**
  String get forcePulling;

  /// No description provided for @confirmForcePull.
  ///
  /// In en, this message translates to:
  /// **'Confirm Force Pull'**
  String get confirmForcePull;

  /// No description provided for @confirmForcePullMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to force pull these changes? Any ongoing merge conflicts will be ignored.'**
  String get confirmForcePullMsg;

  /// No description provided for @localHistoryOverwriteWarning.
  ///
  /// In en, this message translates to:
  /// **'This action will overwrite the local history and cannot be undone.'**
  String get localHistoryOverwriteWarning;

  /// No description provided for @forcePushPullMessage.
  ///
  /// In en, this message translates to:
  /// **'Please do not close or exit the app until the process is complete.'**
  String get forcePushPullMessage;

  /// No description provided for @manualSync.
  ///
  /// In en, this message translates to:
  /// **'Manual Sync'**
  String get manualSync;

  /// No description provided for @manualSyncMsg.
  ///
  /// In en, this message translates to:
  /// **'Select the files you would like to sync'**
  String get manualSyncMsg;

  /// No description provided for @commit.
  ///
  /// In en, this message translates to:
  /// **'Commit'**
  String get commit;

  /// No description provided for @unstage.
  ///
  /// In en, this message translates to:
  /// **'Unstage'**
  String get unstage;

  /// No description provided for @stage.
  ///
  /// In en, this message translates to:
  /// **'Stage'**
  String get stage;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// No description provided for @noUncommittedChanges.
  ///
  /// In en, this message translates to:
  /// **'No uncommitted changes'**
  String get noUncommittedChanges;

  /// No description provided for @discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard Changes'**
  String get discardChanges;

  /// No description provided for @discardChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard Changes?'**
  String get discardChangesTitle;

  /// No description provided for @discardChangesMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to discard all changes to \"%s\"?'**
  String get discardChangesMsg;

  /// No description provided for @mergeConflictItemMessage.
  ///
  /// In en, this message translates to:
  /// **'There is a merge conflict! Tap to resolve'**
  String get mergeConflictItemMessage;

  /// No description provided for @mergeConflict.
  ///
  /// In en, this message translates to:
  /// **'Merge Conflict'**
  String get mergeConflict;

  /// No description provided for @mergeDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Use the editor to resolve the merge conflicts'**
  String get mergeDialogMessage;

  /// No description provided for @commitMessage.
  ///
  /// In en, this message translates to:
  /// **'Commit Message'**
  String get commitMessage;

  /// No description provided for @abortMerge.
  ///
  /// In en, this message translates to:
  /// **'Abort Merge'**
  String get abortMerge;

  /// No description provided for @keepChanges.
  ///
  /// In en, this message translates to:
  /// **'Keep Changes'**
  String get keepChanges;

  /// No description provided for @local.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get local;

  /// No description provided for @both.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get both;

  /// No description provided for @remote.
  ///
  /// In en, this message translates to:
  /// **'Remote'**
  String get remote;

  /// No description provided for @merge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get merge;

  /// No description provided for @merging.
  ///
  /// In en, this message translates to:
  /// **'Merging…'**
  String get merging;

  /// No description provided for @resolvingMerge.
  ///
  /// In en, this message translates to:
  /// **'Resolving merge…'**
  String get resolvingMerge;

  /// No description provided for @iosClearDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Is this a fresh install?'**
  String get iosClearDataTitle;

  /// No description provided for @iosClearDataMsg.
  ///
  /// In en, this message translates to:
  /// **'We detected that this might be a reinstallation, but it could also be a false alarm. On iOS, your Keychain isn’t cleared when you delete and reinstall the app, so some data may still be stored securely.\n\nIf this isn’t a fresh install, or you don’t want to reset, you can safely skip this step.'**
  String get iosClearDataMsg;

  /// No description provided for @clearDataConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm App Data Reset'**
  String get clearDataConfirmTitle;

  /// No description provided for @clearDataConfirmMsg.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all app data, including Keychain entries. Are you sure you want to proceed?'**
  String get clearDataConfirmMsg;

  /// No description provided for @iosClearDataAction.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get iosClearDataAction;

  /// No description provided for @legacyAppUserDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the New Version!'**
  String get legacyAppUserDialogTitle;

  /// No description provided for @legacyAppUserDialogMessagePart1.
  ///
  /// In en, this message translates to:
  /// **'We\'ve rebuilt the app from the ground up for better performance and future growth.'**
  String get legacyAppUserDialogMessagePart1;

  /// No description provided for @legacyAppUserDialogMessagePart2.
  ///
  /// In en, this message translates to:
  /// **'Regrettably, your old settings can\'t be carried over, so you\'ll need to set things up again.\n\nAll your favorite features are still here. Multi-repo support is now part of a small one-time upgrade that helps support ongoing development.'**
  String get legacyAppUserDialogMessagePart2;

  /// No description provided for @legacyAppUserDialogMessagePart3.
  ///
  /// In en, this message translates to:
  /// **'Thanks for sticking with us :)'**
  String get legacyAppUserDialogMessagePart3;

  /// No description provided for @setUp.
  ///
  /// In en, this message translates to:
  /// **'Set Up'**
  String get setUp;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcome;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'It looks like this is your first time here.\n\nWould you like to go through a quick setup to get started?'**
  String get welcomeMessage;

  /// No description provided for @welcomePositive.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go'**
  String get welcomePositive;

  /// No description provided for @welcomeNeutral.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get welcomeNeutral;

  /// No description provided for @welcomeNegative.
  ///
  /// In en, this message translates to:
  /// **'I\'m familiar'**
  String get welcomeNegative;

  /// No description provided for @notificationDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get notificationDialogTitle;

  /// No description provided for @notificationDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enable notification permissions for the best experience.\n\nThe app uses notifications for \n  • popup sync messages (optional)\n  • bug reports'**
  String get notificationDialogMessage;

  /// No description provided for @allFilesAccessDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable \"All Files Access\"'**
  String get allFilesAccessDialogTitle;

  /// No description provided for @allFilesAccessDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'You cannot use GitSync without granting \"All files access\" permissions! Please enable it for the best experience.\n\nThe app uses \"All files access\" for syncing your repository to the selected directory on the device. The app does not attempt to access any file outside the selected directory.'**
  String get allFilesAccessDialogMessage;

  /// No description provided for @almostThereDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Almost there!'**
  String get almostThereDialogTitle;

  /// No description provided for @almostThereDialogMessageAndroid.
  ///
  /// In en, this message translates to:
  /// **'Soon, we\'ll authenticate and clone your repo to your device, preparing it for syncing.\n\nOnce that\'s set, there are several ways to trigger a sync:\n\n  • From within the app\n  • From a Quick Tile\n  • Using App Sync\n  • Using a Custom Intent (advanced)'**
  String get almostThereDialogMessageAndroid;

  /// No description provided for @almostThereDialogMessageIos.
  ///
  /// In en, this message translates to:
  /// **'Soon, we\'ll authenticate and clone your repo to your device, preparing it for syncing.\n\nOnce that\'s set, there are several ways to trigger a sync:\n\n  • From within the app'**
  String get almostThereDialogMessageIos;

  /// No description provided for @authDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Authenticate with a Git Provider'**
  String get authDialogTitle;

  /// No description provided for @authDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Please authenticate with your chosen git provider and continue on to clone your repo!'**
  String get authDialogMessage;

  /// No description provided for @authorDetailsPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Author Details Required'**
  String get authorDetailsPromptTitle;

  /// No description provided for @authorDetailsPromptMessage.
  ///
  /// In en, this message translates to:
  /// **'Your author name or email are missing. Please update them in the repository settings before syncing.'**
  String get authorDetailsPromptMessage;

  /// No description provided for @authorDetailsShowcasePrompt.
  ///
  /// In en, this message translates to:
  /// **'Fill out your author details'**
  String get authorDetailsShowcasePrompt;

  /// No description provided for @goToSettings.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings'**
  String get goToSettings;

  /// No description provided for @enableAutosyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable App Sync'**
  String get enableAutosyncTitle;

  /// No description provided for @enableAutosyncMessage.
  ///
  /// In en, this message translates to:
  /// **'Keep your data up-to-date effortlessly. Turn on App Sync to automatically sync in the background whenever apps are opened or closed.'**
  String get enableAutosyncMessage;

  /// No description provided for @addMoreHint.
  ///
  /// In en, this message translates to:
  /// **'Click this button to add additional repositories to the app'**
  String get addMoreHint;

  /// No description provided for @globalSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'Click this button to access the global app settings'**
  String get globalSettingsHint;

  /// No description provided for @syncProgressHint.
  ///
  /// In en, this message translates to:
  /// **'Track the status of active sync operations here'**
  String get syncProgressHint;

  /// No description provided for @controlHint.
  ///
  /// In en, this message translates to:
  /// **'Use these controls to manually sync or manage repository actions'**
  String get controlHint;

  /// No description provided for @configHint.
  ///
  /// In en, this message translates to:
  /// **'Configure repository settings and initialize setup using this section'**
  String get configHint;

  /// No description provided for @autoSyncOptionsHint.
  ///
  /// In en, this message translates to:
  /// **'Enable background sync and ensure your data stays up-to-date automatically using these settings'**
  String get autoSyncOptionsHint;

  /// No description provided for @guidedSetupHint.
  ///
  /// In en, this message translates to:
  /// **'Click here to restart the setup or UI guide whenever you need a walkthrough or want to review the UI again'**
  String get guidedSetupHint;

  /// No description provided for @detachedHead.
  ///
  /// In en, this message translates to:
  /// **'Detached Head'**
  String get detachedHead;

  /// No description provided for @commitsNotFound.
  ///
  /// In en, this message translates to:
  /// **'No commits found…'**
  String get commitsNotFound;

  /// No description provided for @repoNotFound.
  ///
  /// In en, this message translates to:
  /// **'No repo found…'**
  String get repoNotFound;

  /// No description provided for @committed.
  ///
  /// In en, this message translates to:
  /// **'committed'**
  String get committed;

  /// No description provided for @additions.
  ///
  /// In en, this message translates to:
  /// **'%s ++'**
  String get additions;

  /// No description provided for @deletions.
  ///
  /// In en, this message translates to:
  /// **'%s --'**
  String get deletions;

  /// No description provided for @modifyRemoteUrl.
  ///
  /// In en, this message translates to:
  /// **'Modify Remote URL'**
  String get modifyRemoteUrl;

  /// No description provided for @modify.
  ///
  /// In en, this message translates to:
  /// **'Modify'**
  String get modify;

  /// No description provided for @remoteUrl.
  ///
  /// In en, this message translates to:
  /// **'Remote URL'**
  String get remoteUrl;

  /// No description provided for @setRemoteUrl.
  ///
  /// In en, this message translates to:
  /// **'Set Remote URL'**
  String get setRemoteUrl;

  /// No description provided for @launchInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Launch in Browser'**
  String get launchInBrowser;

  /// No description provided for @auth.
  ///
  /// In en, this message translates to:
  /// **'AUTH'**
  String get auth;

  /// No description provided for @gitDirPathHint.
  ///
  /// In en, this message translates to:
  /// **'/storage/emulated/0/…'**
  String get gitDirPathHint;

  /// No description provided for @openFileExplorer.
  ///
  /// In en, this message translates to:
  /// **'Browse & Edit'**
  String get openFileExplorer;

  /// No description provided for @syncSettings.
  ///
  /// In en, this message translates to:
  /// **'Sync Settings'**
  String get syncSettings;

  /// No description provided for @enableApplicationObserver.
  ///
  /// In en, this message translates to:
  /// **'App Sync Settings'**
  String get enableApplicationObserver;

  /// No description provided for @appSyncDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatically syncs when your selected app is opened or closed'**
  String get appSyncDescription;

  /// No description provided for @accessibilityServiceDisclosureTitle.
  ///
  /// In en, this message translates to:
  /// **'Accessibility Service Disclosure'**
  String get accessibilityServiceDisclosureTitle;

  /// No description provided for @accessibilityServiceDisclosureMessage.
  ///
  /// In en, this message translates to:
  /// **'To enhance your experience,\nGitSync uses Android\'s Accessibility Service to detect when apps are opened or closed.\n\nThis helps us provide tailored features without storing or sharing any data.\n\nᴘʟᴇᴀsᴇ ᴇɴᴀʙʟᴇ ɢɪᴛsʏɴᴄ ᴏɴ ᴛʜᴇ ɴᴇxᴛ sᴄʀᴇᴇɴ'**
  String get accessibilityServiceDisclosureMessage;

  /// No description provided for @accessibilityServiceDescription.
  ///
  /// In en, this message translates to:
  /// **'To enhance your experience, GitSync uses Android\'s Accessibility Service to detect when apps are opened or closed. This helps us provide tailored features without storing or sharing any data. \n\n Key Points: \n Purpose: We use this service solely to improve your app experience. \n Privacy: No data is stored or sent elsewhere. \n Control: You can disable these permissions at any time in your device settings.'**
  String get accessibilityServiceDescription;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Search…'**
  String get searchEllipsis;

  /// No description provided for @applicationNotSet.
  ///
  /// In en, this message translates to:
  /// **'Select App(s)'**
  String get applicationNotSet;

  /// No description provided for @selectApplication.
  ///
  /// In en, this message translates to:
  /// **'Select application(s)'**
  String get selectApplication;

  /// No description provided for @multipleApplicationSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected (%s)'**
  String get multipleApplicationSelected;

  /// No description provided for @saveApplication.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveApplication;

  /// No description provided for @syncOnAppClosed.
  ///
  /// In en, this message translates to:
  /// **'Sync on app(s) closed'**
  String get syncOnAppClosed;

  /// No description provided for @syncOnAppOpened.
  ///
  /// In en, this message translates to:
  /// **'Sync on app(s) opened'**
  String get syncOnAppOpened;

  /// No description provided for @scheduledSyncSettings.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Sync Settings'**
  String get scheduledSyncSettings;

  /// No description provided for @scheduledSyncDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatically syncs periodically in the background'**
  String get scheduledSyncDescription;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @dontSync.
  ///
  /// In en, this message translates to:
  /// **'Don\'t Sync'**
  String get dontSync;

  /// No description provided for @iosDefaultSyncRate.
  ///
  /// In en, this message translates to:
  /// **'when iOS allows'**
  String get iosDefaultSyncRate;

  /// No description provided for @aboutEvery.
  ///
  /// In en, this message translates to:
  /// **'~every'**
  String get aboutEvery;

  /// No description provided for @enhancedScheduledSync.
  ///
  /// In en, this message translates to:
  /// **'Enhanced Scheduled Sync'**
  String get enhancedScheduledSync;

  /// No description provided for @enhancedScheduledSyncMsg1.
  ///
  /// In en, this message translates to:
  /// **'Unlike the basic sync, this feature uses advanced background updates to deliver fresh data more frequently and reliably.'**
  String get enhancedScheduledSyncMsg1;

  /// No description provided for @enhancedScheduledSyncMsg2.
  ///
  /// In en, this message translates to:
  /// **'Sync your repositories in the background as often as a sync per minute, even when the app is closed!\n\nEffortless, continuous updates mean your repos are always ready when you are.'**
  String get enhancedScheduledSyncMsg2;

  /// No description provided for @enhancedScheduledSyncNote.
  ///
  /// In en, this message translates to:
  /// **'Note: Background syncing may be affected by battery saver and Do Not Disturb modes.'**
  String get enhancedScheduledSyncNote;

  /// No description provided for @quickSyncSettings.
  ///
  /// In en, this message translates to:
  /// **'Quick Sync Settings'**
  String get quickSyncSettings;

  /// No description provided for @quickSyncDescription.
  ///
  /// In en, this message translates to:
  /// **'Sync using customizable quick tiles, shortcuts, or widgets'**
  String get quickSyncDescription;

  /// No description provided for @tileSyncSettings.
  ///
  /// In en, this message translates to:
  /// **'Tile Sync Settings'**
  String get tileSyncSettings;

  /// No description provided for @otherSyncSettings.
  ///
  /// In en, this message translates to:
  /// **'Other Sync Settings'**
  String get otherSyncSettings;

  /// No description provided for @useForTileSync.
  ///
  /// In en, this message translates to:
  /// **'Use for Sync Tile '**
  String get useForTileSync;

  /// No description provided for @useForTileManualSync.
  ///
  /// In en, this message translates to:
  /// **'Use for Manual Sync Tile'**
  String get useForTileManualSync;

  /// No description provided for @useForShortcutSync.
  ///
  /// In en, this message translates to:
  /// **'Use for Sync Shortcut'**
  String get useForShortcutSync;

  /// No description provided for @useForShortcutManualSync.
  ///
  /// In en, this message translates to:
  /// **'Use for Manual Sync Shortcut'**
  String get useForShortcutManualSync;

  /// No description provided for @useForWidgetSync.
  ///
  /// In en, this message translates to:
  /// **'Use for Sync Widget'**
  String get useForWidgetSync;

  /// No description provided for @useForWidgetManualSync.
  ///
  /// In en, this message translates to:
  /// **'Use for Manual Sync Widget'**
  String get useForWidgetManualSync;

  /// No description provided for @selectYourGitProviderAndAuthenticate.
  ///
  /// In en, this message translates to:
  /// **'Select your git provider and authenticate'**
  String get selectYourGitProviderAndAuthenticate;

  /// No description provided for @oauthProviders.
  ///
  /// In en, this message translates to:
  /// **'oAuth Providers'**
  String get oauthProviders;

  /// No description provided for @gitProtocols.
  ///
  /// In en, this message translates to:
  /// **'Git Protocols'**
  String get gitProtocols;

  /// No description provided for @oauthNoAffiliation.
  ///
  /// In en, this message translates to:
  /// **'Authentication via third parties;\nno affiliation or endorsement implied.'**
  String get oauthNoAffiliation;

  /// No description provided for @replacesExistingAuth.
  ///
  /// In en, this message translates to:
  /// **'Replaces existing\ncontainer auth'**
  String get replacesExistingAuth;

  /// No description provided for @oauth.
  ///
  /// In en, this message translates to:
  /// **'OAuth'**
  String get oauth;

  /// No description provided for @copyFromContainer.
  ///
  /// In en, this message translates to:
  /// **'Copy from Container'**
  String get copyFromContainer;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @enterPAT.
  ///
  /// In en, this message translates to:
  /// **'Enter Personal Access Token'**
  String get enterPAT;

  /// No description provided for @usePAT.
  ///
  /// In en, this message translates to:
  /// **'Use PAT'**
  String get usePAT;

  /// No description provided for @oauthAllRepos.
  ///
  /// In en, this message translates to:
  /// **'OAuth (All Repos)'**
  String get oauthAllRepos;

  /// No description provided for @oauthScoped.
  ///
  /// In en, this message translates to:
  /// **'OAuth (Scoped)'**
  String get oauthScoped;

  /// No description provided for @ensureTokenScope.
  ///
  /// In en, this message translates to:
  /// **'Ensure your token includes the \"repo\" scope for full functionality.'**
  String get ensureTokenScope;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'user'**
  String get user;

  /// No description provided for @exampleUser.
  ///
  /// In en, this message translates to:
  /// **'JohnSmith12'**
  String get exampleUser;

  /// No description provided for @token.
  ///
  /// In en, this message translates to:
  /// **'token'**
  String get token;

  /// No description provided for @exampleToken.
  ///
  /// In en, this message translates to:
  /// **'ghp_1234abcd5678efgh'**
  String get exampleToken;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'login'**
  String get login;

  /// No description provided for @pubKey.
  ///
  /// In en, this message translates to:
  /// **'pub key'**
  String get pubKey;

  /// No description provided for @privKey.
  ///
  /// In en, this message translates to:
  /// **'priv key'**
  String get privKey;

  /// No description provided for @passphrase.
  ///
  /// In en, this message translates to:
  /// **'Passphrase'**
  String get passphrase;

  /// No description provided for @privateKey.
  ///
  /// In en, this message translates to:
  /// **'Private Key'**
  String get privateKey;

  /// No description provided for @sshPubKeyExample.
  ///
  /// In en, this message translates to:
  /// **'ssh-ed25519 AABBCCDDEEFF112233445566'**
  String get sshPubKeyExample;

  /// No description provided for @sshPrivKeyExample.
  ///
  /// In en, this message translates to:
  /// **'-----BEGIN OPENSSH PRIVATE KEY----- AABBCCDDEEFF112233445566'**
  String get sshPrivKeyExample;

  /// No description provided for @generateKeys.
  ///
  /// In en, this message translates to:
  /// **'generate keys'**
  String get generateKeys;

  /// No description provided for @confirmKeySaved.
  ///
  /// In en, this message translates to:
  /// **'confirm pub key saved'**
  String get confirmKeySaved;

  /// No description provided for @copiedText.
  ///
  /// In en, this message translates to:
  /// **'Copied text!'**
  String get copiedText;

  /// No description provided for @confirmPrivKeyCopy.
  ///
  /// In en, this message translates to:
  /// **'Confirm Private Key Copy'**
  String get confirmPrivKeyCopy;

  /// No description provided for @confirmPrivKeyCopyMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to copy your private key to the clipboard? \n\nAnyone with access to this key can control your account. Ensure you paste it only in secure locations and clear your clipboard afterward.'**
  String get confirmPrivKeyCopyMsg;

  /// No description provided for @understood.
  ///
  /// In en, this message translates to:
  /// **'Understood'**
  String get understood;

  /// No description provided for @importPrivateKey.
  ///
  /// In en, this message translates to:
  /// **'Import Private Key'**
  String get importPrivateKey;

  /// No description provided for @importPrivateKeyMsg.
  ///
  /// In en, this message translates to:
  /// **'Paste your private key below to use an existing account. \n\nMake sure you are pasting the key in a secure environment, as anyone with access to this key can control your account.'**
  String get importPrivateKeyMsg;

  /// No description provided for @importKey.
  ///
  /// In en, this message translates to:
  /// **'import'**
  String get importKey;

  /// No description provided for @cloneRepo.
  ///
  /// In en, this message translates to:
  /// **'Clone Remote Repository'**
  String get cloneRepo;

  /// No description provided for @clone.
  ///
  /// In en, this message translates to:
  /// **'clone'**
  String get clone;

  /// No description provided for @chooseHowToClone.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to clone the repository:'**
  String get chooseHowToClone;

  /// No description provided for @directCloningMsg.
  ///
  /// In en, this message translates to:
  /// **'Direct Cloning: Clones the repository into the selected folder'**
  String get directCloningMsg;

  /// No description provided for @nestedCloningMsg.
  ///
  /// In en, this message translates to:
  /// **'Nested Cloning: Creates a new folder named after the repository within the selected folder'**
  String get nestedCloningMsg;

  /// No description provided for @directClone.
  ///
  /// In en, this message translates to:
  /// **'Direct Clone'**
  String get directClone;

  /// No description provided for @nestedClone.
  ///
  /// In en, this message translates to:
  /// **'Nested Clone'**
  String get nestedClone;

  /// No description provided for @gitRepoUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://git.abc/xyz.git'**
  String get gitRepoUrlHint;

  /// No description provided for @invalidRepositoryUrlTitle.
  ///
  /// In en, this message translates to:
  /// **'Invalid repository URL!'**
  String get invalidRepositoryUrlTitle;

  /// No description provided for @invalidRepositoryUrlMessage.
  ///
  /// In en, this message translates to:
  /// **'Invalid repository URL!'**
  String get invalidRepositoryUrlMessage;

  /// No description provided for @cloneAnyway.
  ///
  /// In en, this message translates to:
  /// **'Clone anyway'**
  String get cloneAnyway;

  /// No description provided for @iHaveALocalRepository.
  ///
  /// In en, this message translates to:
  /// **'I have a local repository'**
  String get iHaveALocalRepository;

  /// No description provided for @cloningRepository.
  ///
  /// In en, this message translates to:
  /// **'Cloning repository…'**
  String get cloningRepository;

  /// No description provided for @cloneMessagePart1.
  ///
  /// In en, this message translates to:
  /// **'DON\'T EXIT THIS SCREEN'**
  String get cloneMessagePart1;

  /// No description provided for @cloneMessagePart2.
  ///
  /// In en, this message translates to:
  /// **'This may take a while depending on the size of your repo\n'**
  String get cloneMessagePart2;

  /// No description provided for @selectCloneDirectory.
  ///
  /// In en, this message translates to:
  /// **'Select a folder to clone into'**
  String get selectCloneDirectory;

  /// No description provided for @confirmCloneOverwriteTitle.
  ///
  /// In en, this message translates to:
  /// **'Folder Not Empty'**
  String get confirmCloneOverwriteTitle;

  /// No description provided for @confirmCloneOverwriteMsg.
  ///
  /// In en, this message translates to:
  /// **'The folder you selected already contains files. Cloning into it will overwrite its contents.'**
  String get confirmCloneOverwriteMsg;

  /// No description provided for @confirmCloneOverwriteWarning.
  ///
  /// In en, this message translates to:
  /// **'This action is irreversible.'**
  String get confirmCloneOverwriteWarning;

  /// No description provided for @confirmCloneOverwriteAction.
  ///
  /// In en, this message translates to:
  /// **'Overwrite'**
  String get confirmCloneOverwriteAction;

  /// No description provided for @repoSearchLimits.
  ///
  /// In en, this message translates to:
  /// **'Repository Search Limits'**
  String get repoSearchLimits;

  /// No description provided for @repoSearchLimitsDescription.
  ///
  /// In en, this message translates to:
  /// **'Repository search only examines the first 100 repositories returned by the API, so it may sometimes omit the repository you expect. \n\nIf the repository you want does not appear in search results, please clone it directly using its HTTPS or SSH URL.'**
  String get repoSearchLimitsDescription;

  /// No description provided for @repositorySettings.
  ///
  /// In en, this message translates to:
  /// **'Repository Settings'**
  String get repositorySettings;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @signedCommitsLabel.
  ///
  /// In en, this message translates to:
  /// **'Signed Commits'**
  String get signedCommitsLabel;

  /// No description provided for @signedCommitsDescription.
  ///
  /// In en, this message translates to:
  /// **'sign commits to verify your identity'**
  String get signedCommitsDescription;

  /// No description provided for @importCommitKey.
  ///
  /// In en, this message translates to:
  /// **'Import Key'**
  String get importCommitKey;

  /// No description provided for @commitKeyImported.
  ///
  /// In en, this message translates to:
  /// **'Key Imported'**
  String get commitKeyImported;

  /// No description provided for @useSshKey.
  ///
  /// In en, this message translates to:
  /// **'Use AUTH Key for Commit Signing'**
  String get useSshKey;

  /// No description provided for @syncMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Sync Message'**
  String get syncMessageLabel;

  /// No description provided for @syncMessageDescription.
  ///
  /// In en, this message translates to:
  /// **'use %s for the date and time'**
  String get syncMessageDescription;

  /// No description provided for @syncMessageTimeFormatLabel.
  ///
  /// In en, this message translates to:
  /// **'Sync Message Time Format'**
  String get syncMessageTimeFormatLabel;

  /// No description provided for @syncMessageTimeFormatDescription.
  ///
  /// In en, this message translates to:
  /// **'uses standard datetime formatting syntax'**
  String get syncMessageTimeFormatDescription;

  /// No description provided for @remoteLabel.
  ///
  /// In en, this message translates to:
  /// **'default remote'**
  String get remoteLabel;

  /// No description provided for @defaultRemote.
  ///
  /// In en, this message translates to:
  /// **'origin'**
  String get defaultRemote;

  /// No description provided for @authorNameLabel.
  ///
  /// In en, this message translates to:
  /// **'author name'**
  String get authorNameLabel;

  /// No description provided for @authorName.
  ///
  /// In en, this message translates to:
  /// **'JohnSmith12'**
  String get authorName;

  /// No description provided for @authorEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'author email'**
  String get authorEmailLabel;

  /// No description provided for @authorEmail.
  ///
  /// In en, this message translates to:
  /// **'john12@smith.com'**
  String get authorEmail;

  /// No description provided for @gitIgnore.
  ///
  /// In en, this message translates to:
  /// **'.gitignore'**
  String get gitIgnore;

  /// No description provided for @gitIgnoreDescription.
  ///
  /// In en, this message translates to:
  /// **'list files or folders to ignore on all devices'**
  String get gitIgnoreDescription;

  /// No description provided for @gitIgnoreHint.
  ///
  /// In en, this message translates to:
  /// **'.trash/\n./…'**
  String get gitIgnoreHint;

  /// No description provided for @gitInfoExclude.
  ///
  /// In en, this message translates to:
  /// **'.git/info/exclude'**
  String get gitInfoExclude;

  /// No description provided for @gitInfoExcludeDescription.
  ///
  /// In en, this message translates to:
  /// **'list files or folders to ignore on this device'**
  String get gitInfoExcludeDescription;

  /// No description provided for @gitInfoExcludeHint.
  ///
  /// In en, this message translates to:
  /// **'.trash/\n./…'**
  String get gitInfoExcludeHint;

  /// No description provided for @disableSsl.
  ///
  /// In en, this message translates to:
  /// **'Disable SSL'**
  String get disableSsl;

  /// No description provided for @disableSslDescription.
  ///
  /// In en, this message translates to:
  /// **'Disable secure connection for HTTP repositories'**
  String get disableSslDescription;

  /// No description provided for @disableSslPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Disable SSL?'**
  String get disableSslPromptTitle;

  /// No description provided for @disableSslPromptMsg.
  ///
  /// In en, this message translates to:
  /// **'The address you cloned starts with \"http\" (not secure). Disabling SSL will match the URL but reduce security.'**
  String get disableSslPromptMsg;

  /// No description provided for @optimisedSync.
  ///
  /// In en, this message translates to:
  /// **'Optimised Sync'**
  String get optimisedSync;

  /// No description provided for @optimisedSyncDescription.
  ///
  /// In en, this message translates to:
  /// **'Intelligently reduce overall sync operations'**
  String get optimisedSyncDescription;

  /// No description provided for @proceedAnyway.
  ///
  /// In en, this message translates to:
  /// **'Proceed anyway?'**
  String get proceedAnyway;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More Options'**
  String get moreOptions;

  /// No description provided for @untrackAll.
  ///
  /// In en, this message translates to:
  /// **'Untrack All'**
  String get untrackAll;

  /// No description provided for @globalSettings.
  ///
  /// In en, this message translates to:
  /// **'Global Settings'**
  String get globalSettings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @browseEditDir.
  ///
  /// In en, this message translates to:
  /// **'Browse & Edit Directory'**
  String get browseEditDir;

  /// No description provided for @enableLineWrap.
  ///
  /// In en, this message translates to:
  /// **'Enable Line Wrap in Editors'**
  String get enableLineWrap;

  /// No description provided for @excludeFromRecents.
  ///
  /// In en, this message translates to:
  /// **'Exclude From Recents'**
  String get excludeFromRecents;

  /// No description provided for @backupRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Encrypted Configuration Recovery'**
  String get backupRestoreTitle;

  /// No description provided for @encryptedBackup.
  ///
  /// In en, this message translates to:
  /// **'Encrypted Backup'**
  String get encryptedBackup;

  /// No description provided for @encryptedRestore.
  ///
  /// In en, this message translates to:
  /// **'Encrypted Restore'**
  String get encryptedRestore;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @selectBackupLocation.
  ///
  /// In en, this message translates to:
  /// **'Select location to save backup'**
  String get selectBackupLocation;

  /// No description provided for @backupFileTemplate.
  ///
  /// In en, this message translates to:
  /// **'backup_%s.gsbak'**
  String get backupFileTemplate;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter %s Password'**
  String get enterPassword;

  /// No description provided for @invalidPassword.
  ///
  /// In en, this message translates to:
  /// **'Invalid Password'**
  String get invalidPassword;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @guides.
  ///
  /// In en, this message translates to:
  /// **'Guides'**
  String get guides;

  /// No description provided for @documentation.
  ///
  /// In en, this message translates to:
  /// **'Guides & Wiki'**
  String get documentation;

  /// No description provided for @viewDocumentation.
  ///
  /// In en, this message translates to:
  /// **'View Guides & Wiki'**
  String get viewDocumentation;

  /// No description provided for @requestAFeature.
  ///
  /// In en, this message translates to:
  /// **'Request A Feature'**
  String get requestAFeature;

  /// No description provided for @contributeTitle.
  ///
  /// In en, this message translates to:
  /// **'Support Our Work'**
  String get contributeTitle;

  /// No description provided for @improveTranslations.
  ///
  /// In en, this message translates to:
  /// **'Improve Translations'**
  String get improveTranslations;

  /// No description provided for @joinTheDiscussion.
  ///
  /// In en, this message translates to:
  /// **'Join The Discord'**
  String get joinTheDiscussion;

  /// No description provided for @noLogFilesFound.
  ///
  /// In en, this message translates to:
  /// **'No log files found!'**
  String get noLogFilesFound;

  /// No description provided for @guidedSetup.
  ///
  /// In en, this message translates to:
  /// **'Guided Setup'**
  String get guidedSetup;

  /// No description provided for @uiGuide.
  ///
  /// In en, this message translates to:
  /// **'UI Guide'**
  String get uiGuide;

  /// No description provided for @viewPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get viewPrivacyPolicy;

  /// No description provided for @viewEula.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use (EULA)'**
  String get viewEula;

  /// No description provided for @shareLogs.
  ///
  /// In en, this message translates to:
  /// **'Share Logs'**
  String get shareLogs;

  /// No description provided for @logsEmailSubjectTemplate.
  ///
  /// In en, this message translates to:
  /// **'GitSync Logs (%s)'**
  String get logsEmailSubjectTemplate;

  /// No description provided for @logsEmailRecipient.
  ///
  /// In en, this message translates to:
  /// **'bugsviscouspotential@gmail.com'**
  String get logsEmailRecipient;

  /// No description provided for @repositoryDefaults.
  ///
  /// In en, this message translates to:
  /// **'Repository Defaults'**
  String get repositoryDefaults;

  /// No description provided for @miscellaneous.
  ///
  /// In en, this message translates to:
  /// **'Miscellaneous'**
  String get miscellaneous;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// No description provided for @file.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get file;

  /// No description provided for @folder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get folder;

  /// No description provided for @directory.
  ///
  /// In en, this message translates to:
  /// **'Directory'**
  String get directory;

  /// No description provided for @confirmFileDirDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm %s Deletion'**
  String get confirmFileDirDeleteTitle;

  /// No description provided for @confirmFileDirDeleteMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the %s \"%s\" %s?'**
  String get confirmFileDirDeleteMsg;

  /// No description provided for @deleteMultipleSuffix.
  ///
  /// In en, this message translates to:
  /// **'and %s more and their contents'**
  String get deleteMultipleSuffix;

  /// No description provided for @deleteSingularSuffix.
  ///
  /// In en, this message translates to:
  /// **'and it\'s contents'**
  String get deleteSingularSuffix;

  /// No description provided for @createAFile.
  ///
  /// In en, this message translates to:
  /// **'Create a File'**
  String get createAFile;

  /// No description provided for @fileName.
  ///
  /// In en, this message translates to:
  /// **'File Name'**
  String get fileName;

  /// No description provided for @createADir.
  ///
  /// In en, this message translates to:
  /// **'Create a Directory'**
  String get createADir;

  /// No description provided for @dirName.
  ///
  /// In en, this message translates to:
  /// **'Folder Name'**
  String get dirName;

  /// No description provided for @renameFileDir.
  ///
  /// In en, this message translates to:
  /// **'Rename %s'**
  String get renameFileDir;

  /// No description provided for @fileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File larger than %s lines'**
  String get fileTooLarge;

  /// No description provided for @readOnly.
  ///
  /// In en, this message translates to:
  /// **'Read-Only'**
  String get readOnly;

  /// No description provided for @cut.
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get cut;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @paste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// No description provided for @experimental.
  ///
  /// In en, this message translates to:
  /// **'Experimental'**
  String get experimental;

  /// No description provided for @experimentalMsg.
  ///
  /// In en, this message translates to:
  /// **'Use at your own risk'**
  String get experimentalMsg;

  /// No description provided for @codeEditorLimits.
  ///
  /// In en, this message translates to:
  /// **'Code Editor Limits'**
  String get codeEditorLimits;

  /// No description provided for @codeEditorLimitsDescription.
  ///
  /// In en, this message translates to:
  /// **'The code editor provides basic, functional editing but hasn’t been exhaustively tested for edge cases or heavy use. \n\nIf you encounter bugs or want to suggest features, I welcome feedback! Please use the Bug Report or Feature Request options in Global Settings or below.'**
  String get codeEditorLimitsDescription;

  /// No description provided for @openFile.
  ///
  /// In en, this message translates to:
  /// **'Open File'**
  String get openFile;

  /// No description provided for @openFileDescription.
  ///
  /// In en, this message translates to:
  /// **'Preview/edit file contents'**
  String get openFileDescription;

  /// No description provided for @viewGitLog.
  ///
  /// In en, this message translates to:
  /// **'view git log'**
  String get viewGitLog;

  /// No description provided for @viewGitLogDescription.
  ///
  /// In en, this message translates to:
  /// **'View the full git log history'**
  String get viewGitLogDescription;

  /// No description provided for @ignoreUntrack.
  ///
  /// In en, this message translates to:
  /// **'.gitignore + Untrack'**
  String get ignoreUntrack;

  /// No description provided for @ignoreUntrackDescription.
  ///
  /// In en, this message translates to:
  /// **'Add files to .gitignore and untrack'**
  String get ignoreUntrackDescription;

  /// No description provided for @excludeUntrack.
  ///
  /// In en, this message translates to:
  /// **'.git/info/exclude + Untrack'**
  String get excludeUntrack;

  /// No description provided for @excludeUntrackDescription.
  ///
  /// In en, this message translates to:
  /// **'Add files to the local exclude file and untrack'**
  String get excludeUntrackDescription;

  /// No description provided for @ignoreOnly.
  ///
  /// In en, this message translates to:
  /// **'Add to .gitignore Only'**
  String get ignoreOnly;

  /// No description provided for @ignoreOnlyDescription.
  ///
  /// In en, this message translates to:
  /// **'Only add files to .gitignore'**
  String get ignoreOnlyDescription;

  /// No description provided for @excludeOnly.
  ///
  /// In en, this message translates to:
  /// **'Add to .git/info/exclude Only'**
  String get excludeOnly;

  /// No description provided for @excludeOnlyDescription.
  ///
  /// In en, this message translates to:
  /// **'Only add files to the local exclude file'**
  String get excludeOnlyDescription;

  /// No description provided for @untrack.
  ///
  /// In en, this message translates to:
  /// **'Untrack file(s)'**
  String get untrack;

  /// No description provided for @untrackDescription.
  ///
  /// In en, this message translates to:
  /// **'Untrack specified file(s)'**
  String get untrackDescription;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get selected;

  /// No description provided for @ignoreAndUntrack.
  ///
  /// In en, this message translates to:
  /// **'Ignore & Untrack'**
  String get ignoreAndUntrack;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @fileDiff.
  ///
  /// In en, this message translates to:
  /// **'File Diff'**
  String get fileDiff;

  /// No description provided for @openEditFile.
  ///
  /// In en, this message translates to:
  /// **'Open/Edit File'**
  String get openEditFile;

  /// No description provided for @filesChanged.
  ///
  /// In en, this message translates to:
  /// **'file(s) changed'**
  String get filesChanged;

  /// No description provided for @defaultContainerName.
  ///
  /// In en, this message translates to:
  /// **'alias'**
  String get defaultContainerName;

  /// No description provided for @renameRepository.
  ///
  /// In en, this message translates to:
  /// **'Rename Container'**
  String get renameRepository;

  /// No description provided for @renameRepositoryMsg.
  ///
  /// In en, this message translates to:
  /// **'Enter a new alias for the repository container'**
  String get renameRepositoryMsg;

  /// No description provided for @addMore.
  ///
  /// In en, this message translates to:
  /// **'Add More'**
  String get addMore;

  /// No description provided for @addRepository.
  ///
  /// In en, this message translates to:
  /// **'Add Container'**
  String get addRepository;

  /// No description provided for @addRepositoryMsg.
  ///
  /// In en, this message translates to:
  /// **'Give your new repository container a unique alias. This will help you identify it later.'**
  String get addRepositoryMsg;

  /// No description provided for @confirmRepositoryDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Container Deletion'**
  String get confirmRepositoryDelete;

  /// No description provided for @confirmRepositoryDeleteMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the repository container \"%s\"?'**
  String get confirmRepositoryDeleteMsg;

  /// No description provided for @deleteRepoDirectoryCheckbox.
  ///
  /// In en, this message translates to:
  /// **'Also delete the repository’s directory and all its contents'**
  String get deleteRepoDirectoryCheckbox;

  /// No description provided for @confirmRepositoryDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Container Deletion'**
  String get confirmRepositoryDeleteTitle;

  /// No description provided for @confirmRepositoryDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the repository \"%s\" and it\'s contents?'**
  String get confirmRepositoryDeleteMessage;

  /// No description provided for @submodulesFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Submodules Found'**
  String get submodulesFoundTitle;

  /// No description provided for @submodulesFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'The repository you added contains submodules. Would you like to automatically add them as separate repositories in the app?\n\nThis is a premium feature.'**
  String get submodulesFoundMessage;

  /// No description provided for @submodulesFoundAction.
  ///
  /// In en, this message translates to:
  /// **'Add Submodules'**
  String get submodulesFoundAction;

  /// No description provided for @confirmBranchCheckoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Checkout Branch?'**
  String get confirmBranchCheckoutTitle;

  /// No description provided for @confirmBranchCheckoutMsgPart1.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to checkout the branch '**
  String get confirmBranchCheckoutMsgPart1;

  /// No description provided for @confirmBranchCheckoutMsgPart2.
  ///
  /// In en, this message translates to:
  /// **'?'**
  String get confirmBranchCheckoutMsgPart2;

  /// No description provided for @unsavedChangesMayBeLost.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes may be lost.'**
  String get unsavedChangesMayBeLost;

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @createBranch.
  ///
  /// In en, this message translates to:
  /// **'Create New Branch'**
  String get createBranch;

  /// No description provided for @createBranchName.
  ///
  /// In en, this message translates to:
  /// **'Branch Name'**
  String get createBranchName;

  /// No description provided for @createBranchBasedOn.
  ///
  /// In en, this message translates to:
  /// **'Based on'**
  String get createBranchBasedOn;

  /// No description provided for @attemptAutoFix.
  ///
  /// In en, this message translates to:
  /// **'Attempt Auto-Fix?'**
  String get attemptAutoFix;

  /// No description provided for @troubleshooting.
  ///
  /// In en, this message translates to:
  /// **'Troubleshooting'**
  String get troubleshooting;

  /// No description provided for @youreOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline.'**
  String get youreOffline;

  /// No description provided for @someFeaturesMayNotWork.
  ///
  /// In en, this message translates to:
  /// **'Some features may not work.'**
  String get someFeaturesMayNotWork;

  /// No description provided for @ongoingMergeConflict.
  ///
  /// In en, this message translates to:
  /// **'Ongoing merge conflict'**
  String get ongoingMergeConflict;

  /// No description provided for @enableAccessibilityService.
  ///
  /// In en, this message translates to:
  /// **'Please enable GitSync under \"Installed apps\"'**
  String get enableAccessibilityService;

  /// No description provided for @networkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Network unavailable!'**
  String get networkUnavailable;

  /// No description provided for @networkUnavailableRetry.
  ///
  /// In en, this message translates to:
  /// **'Network unavailable!\nGitSync will retry when reconnected'**
  String get networkUnavailableRetry;

  /// No description provided for @pullFailed.
  ///
  /// In en, this message translates to:
  /// **'Pull failed! Please check for uncommitted changes and try again.'**
  String get pullFailed;

  /// No description provided for @reportABug.
  ///
  /// In en, this message translates to:
  /// **'Report a Bug'**
  String get reportABug;

  /// No description provided for @reportBug.
  ///
  /// In en, this message translates to:
  /// **'<GitSync Error> Tap to send a bug report'**
  String get reportBug;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown Error'**
  String get unknownError;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications permission to see more.'**
  String get enableNotifications;

  /// No description provided for @errorOccurredTitle.
  ///
  /// In en, this message translates to:
  /// **'An Error Occurred!'**
  String get errorOccurredTitle;

  /// No description provided for @errorOccurredMessagePart1.
  ///
  /// In en, this message translates to:
  /// **'If this caused any issues, please create a bug report quickly using the button below.'**
  String get errorOccurredMessagePart1;

  /// No description provided for @errorOccurredMessagePart2.
  ///
  /// In en, this message translates to:
  /// **'Otherwise, you can long-press to copy to clipboard or dismiss and continue.'**
  String get errorOccurredMessagePart2;

  /// No description provided for @applicationError.
  ///
  /// In en, this message translates to:
  /// **'Application Error!'**
  String get applicationError;

  /// No description provided for @missingAuthorDetailsError.
  ///
  /// In en, this message translates to:
  /// **'Missing repository author details. Please set your name and email in the repository settings.'**
  String get missingAuthorDetailsError;

  /// No description provided for @outOfMemory.
  ///
  /// In en, this message translates to:
  /// **'Application ran out of memory!'**
  String get outOfMemory;

  /// No description provided for @invalidRemote.
  ///
  /// In en, this message translates to:
  /// **'Invalid remote! Modify this in settings'**
  String get invalidRemote;

  /// No description provided for @largeFile.
  ///
  /// In en, this message translates to:
  /// **'Singular files larger than 50MB not supported!'**
  String get largeFile;

  /// No description provided for @cloneFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to clone repository!'**
  String get cloneFailed;

  /// No description provided for @inaccessibleDirectoryMessage.
  ///
  /// In en, this message translates to:
  /// **'Inaccessible directory! Please select a different location.'**
  String get inaccessibleDirectoryMessage;

  /// No description provided for @autoRebaseFailedException.
  ///
  /// In en, this message translates to:
  /// **'Remote is further ahead than local and we could not automatically rebase for you, as it would cause non fast-forward update.'**
  String get autoRebaseFailedException;

  /// No description provided for @nonExistingException.
  ///
  /// In en, this message translates to:
  /// **'Remote ref didn\'t exist.'**
  String get nonExistingException;

  /// No description provided for @rejectedNodeleteException.
  ///
  /// In en, this message translates to:
  /// **'Remote ref update was rejected, because remote side doesn\'t support/allow deleting refs.'**
  String get rejectedNodeleteException;

  /// No description provided for @rejectedException.
  ///
  /// In en, this message translates to:
  /// **'Remote ref update was rejected.'**
  String get rejectedException;

  /// No description provided for @rejectionWithReasonException.
  ///
  /// In en, this message translates to:
  /// **'Remote ref update was rejected because %s.'**
  String get rejectionWithReasonException;

  /// No description provided for @remoteChangedException.
  ///
  /// In en, this message translates to:
  /// **'Remote ref update was rejected, because old object id on remote repository wasn\'t the same as defined expected old object.'**
  String get remoteChangedException;

  /// No description provided for @mergingExceptionMessage.
  ///
  /// In en, this message translates to:
  /// **'MERGING'**
  String get mergingExceptionMessage;

  /// No description provided for @fieldCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Field cannot be empty'**
  String get fieldCannotBeEmpty;

  /// No description provided for @androidLimitedFilepathCharacters.
  ///
  /// In en, this message translates to:
  /// **'This issue is due to Android file naming restrictions. Please rename the affected files on a different device and resync.\n\nUnsupported characters: \" * / : &lt; &gt; ? \\ |'**
  String get androidLimitedFilepathCharacters;

  /// No description provided for @emptyNameOrEmail.
  ///
  /// In en, this message translates to:
  /// **'Your Git configuration is missing an author name or email address. Please update your settings to include your author name and email.'**
  String get emptyNameOrEmail;

  /// No description provided for @errorReadingZlibStream.
  ///
  /// In en, this message translates to:
  /// **'This is a known issue with specific devices which can be fixed with the last legacy version of the app. Please download it for continued access, though some features may be limited'**
  String get errorReadingZlibStream;

  /// No description provided for @gitObsidianFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Obsidian Git Warning'**
  String get gitObsidianFoundTitle;

  /// No description provided for @gitObsidianFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'This repository seems to contain an Obsidian vault with the Obsidian Git plugin enabled.\n\nPlease disable the plugin on this device to avoid conflicts! More details on the process can be found in the linked documentation.'**
  String get gitObsidianFoundMessage;

  /// No description provided for @gitObsidianFoundAction.
  ///
  /// In en, this message translates to:
  /// **'View Documentation'**
  String get gitObsidianFoundAction;

  /// No description provided for @githubIssueOauthTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect GitHub to Report Automatically'**
  String get githubIssueOauthTitle;

  /// No description provided for @githubIssueOauthMsg.
  ///
  /// In en, this message translates to:
  /// **'You need to connect your GitHub account to report bugs and track their progress.\nYou can reset this connection anytime in Global Settings.'**
  String get githubIssueOauthMsg;

  /// No description provided for @issueReportMessage.
  ///
  /// In en, this message translates to:
  /// **'Logs automatically included with reports'**
  String get issueReportMessage;

  /// No description provided for @includeLogs.
  ///
  /// In en, this message translates to:
  /// **'Include Log File(s)'**
  String get includeLogs;

  /// No description provided for @issueReportTitleTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get issueReportTitleTitle;

  /// No description provided for @issueReportTitleDesc.
  ///
  /// In en, this message translates to:
  /// **'A few words summarizing the issue'**
  String get issueReportTitleDesc;

  /// No description provided for @issueReportDescTitle.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get issueReportDescTitle;

  /// No description provided for @issueReportDescDesc.
  ///
  /// In en, this message translates to:
  /// **'Explain what’s happening in more detail'**
  String get issueReportDescDesc;

  /// No description provided for @issueReportMinimalReproTitle.
  ///
  /// In en, this message translates to:
  /// **'Reproduction Steps'**
  String get issueReportMinimalReproTitle;

  /// No description provided for @issueReportMinimalReproDesc.
  ///
  /// In en, this message translates to:
  /// **'Describe the steps taken leading up to the error'**
  String get issueReportMinimalReproDesc;

  /// No description provided for @includeLogFiles.
  ///
  /// In en, this message translates to:
  /// **'Include Log File(s)'**
  String get includeLogFiles;

  /// No description provided for @includeLogFilesDescription.
  ///
  /// In en, this message translates to:
  /// **'Including log files with your bug report is strongly recommended as they can greatly speed up diagnosing the root cause. \nIf you choose to disable \"Include log file(s)\", please copy and paste the relevant log excerpts into your report so we can reproduce the issue. You can review logs before sending by using the eye icon to confirm there’s nothing sensitive. \n\nIncluding logs is optional, not mandatory.'**
  String get includeLogFilesDescription;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @issueReportSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Issue Reported Successfully'**
  String get issueReportSuccessTitle;

  /// No description provided for @issueReportSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Your issue has been reported. Bookmark this page to track progress and respond to messages. \n\nPlease avoid creating duplicate issues, as that makes resolution harder. \n\nIssues with no activity for 7 days are automatically closed.'**
  String get issueReportSuccessMsg;

  /// No description provided for @trackIssue.
  ///
  /// In en, this message translates to:
  /// **'Track Issue & Respond to Messages'**
  String get trackIssue;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en', 'es', 'fr', 'ru', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
