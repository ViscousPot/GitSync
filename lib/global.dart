import 'package:flutter/material.dart';
import 'package:GitSync/api/ai_chat_service.dart';
import 'package:GitSync/api/colour_provider.dart';
import 'package:GitSync/api/manager/premium_manager.dart';
import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/l10n/app_localizations.dart';
import '../api/manager/repo_manager.dart';
import '../api/manager/settings_manager.dart';
import '../gitsync_service.dart';

// TODO: Must be false for release
const demo = false;

/// TODO: Must be false for store release
const isOssBuild = true;

final repoManager = RepoManager();
final uiSettingsManager = SettingsManager();
final gitSyncService = GitsyncService();
final premiumManager = PremiumManager();
final ValueNotifier<bool> themeDarkMode = ValueNotifier(true);
final aiChatService = AiChatService();

final ValueNotifier<bool> aiKeyConfigured = ValueNotifier(false);
VoidCallback? switchToAiTab;

Future<void> reloadTheme(BuildContext context) async {
  final newDarkMode = await repoManager.getBoolNullable(StorageKey.repoman_themeMode);
  themeDarkMode.value = newDarkMode ?? MediaQuery.of(context).platformBrightness == Brightness.dark;
}

extension ColoursContext on BuildContext {
  Colours get colours => (mounted ? Theme.of(this).extension<Colours>() : null) ?? Colours(darkMode: themeDarkMode.value);
}

extension L10nContext on BuildContext {
  AppLocalizations get t => AppLocalizations.of(this);
}
