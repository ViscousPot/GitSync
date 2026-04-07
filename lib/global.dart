import 'package:flutter/foundation.dart';
import 'package:GitSync/api/ai_chat_service.dart';
import 'package:GitSync/api/colour_provider.dart';
import 'package:GitSync/api/manager/premium_manager.dart';
import 'package:GitSync/l10n/app_localizations.dart';
import '../api/manager/repo_manager.dart';
import '../api/manager/settings_manager.dart';
import '../gitsync_service.dart';

// TODO: Must be false for release
const demo = false;

final repoManager = RepoManager();
final uiSettingsManager = SettingsManager();
final gitSyncService = GitsyncService();
final premiumManager = PremiumManager();
final colours = Colours();
final aiChatService = AiChatService();
late AppLocalizations t;

final ValueNotifier<bool> aiKeyConfigured = ValueNotifier(false);
final ValueNotifier<bool> aiFeaturesEnabled = ValueNotifier(true);
VoidCallback? switchToAiTab;
