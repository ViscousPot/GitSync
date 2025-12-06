import 'package:GitSync/constant/strings.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum StorageKey<T> {
  // Repo Manager
  repoman_appLocale<String?>(name: "appLocale", defaultValue: null),
  repoman_hasGHSponsorPremium<bool>(name: "hasGHSponsorPremium", defaultValue: false),
  repoman_repoIndex<int>(name: "repoIndex", defaultValue: 0),
  repoman_tileSyncIndex<int>(name: "tileSyncIndex", defaultValue: 0),
  repoman_tileManualSyncIndex<int>(name: "tileManualSyncIndex", defaultValue: 0),
  repoman_shortcutSyncIndex<int>(name: "shortcutSyncIndex", defaultValue: 0),
  repoman_shortcutManualSyncIndex<int>(name: "shortcutManualSyncIndex", defaultValue: 0),
  repoman_widgetSyncIndex<int>(name: "widgetSyncIndex", defaultValue: 0),
  repoman_widgetManualSyncIndex<int>(name: "widgetManualSyncIndex", defaultValue: 0),
  repoman_onboardingStep<int>(name: "onboardingStep", defaultValue: 0),
  repoman_erroring<String?>(name: "erroring", defaultValue: null),
  repoman_ghSponsorToken<String?>(name: "ghSponsorToken", defaultValue: null),
  repoman_repoNames<List<String>>(name: "repoNames", defaultValue: <String>["main"]),
  repoman_locks<List<String>>(name: "locks", defaultValue: <String>[]),
  repoman_showGithubAppRedirectDisclosure<bool>(name: "showGithubAppRedirectDisclosure", defaultValue: true),
  repoman_reportIssueToken<String?>(name: "reportIssueToken", defaultValue: null),
  repoman_defaultClientModeEnabled<bool>(name: "defaultClientModeEnabled", defaultValue: false),
  repoman_defaultSyncMessage<String>(name: "defaultSyncMessage", defaultValue: defaultSyncMessage),
  repoman_defaultSyncMessageTimeFormat<String>(name: "defaultSyncMessageTimeFormat", defaultValue: defaultSyncMessageTimeFormat),
  repoman_defaultAuthorName<String>(name: "defaultAuthorName", defaultValue: ""),
  repoman_defaultAuthorEmail<String>(name: "defaultAuthorEmail", defaultValue: ""),
  repoman_defaultRemote<String>(name: "defaultRemote", defaultValue: "origin"),
  repoman_editorLineWrap<bool>(name: "editorLineWrap", defaultValue: false),

  // Settings Manager
  setman_authorName<String?>(name: "authorName", defaultValue: "", hasDefault: true),
  setman_authorEmail<String?>(name: "authorEmail", defaultValue: "", hasDefault: true),
  setman_syncMessage<String?>(name: "syncMessage", defaultValue: defaultSyncMessage, hasDefault: true),
  setman_syncMessageTimeFormat<String?>(name: "syncMessageTimeFormat", defaultValue: defaultSyncMessageTimeFormat, hasDefault: true),
  setman_remote<String?>(name: "remote", defaultValue: "origin", hasDefault: true),
  setman_syncMessageEnabled<bool>(name: "syncMessageEnabled", defaultValue: false),
  setman_gitDirPath<String>(name: "gitDirPath", defaultValue: ""),
  setman_gitProvider<String?>(name: "gitProvider", defaultValue: null),
  setman_gitAuthUsername<String>(name: "gitAuthUsername", defaultValue: ""),
  setman_gitAuthToken<String>(name: "gitAuthToken", defaultValue: ""),
  setman_gitSshKey<String>(name: "gitSshKey", defaultValue: ""),
  setman_gitSshPassphrase<String>(name: "gitSshPassphrase", defaultValue: ""),
  setman_applicationObserverExpanded<bool>(name: "applicationObserverExpanded", defaultValue: true),
  setman_scheduledSyncSettingsExpanded<bool>(name: "scheduledSyncSettingsExpanded", defaultValue: false),
  setman_schedule<String>(name: "schedule", defaultValue: "never|0"),
  setman_otherSyncSettingsExpanded<bool>(name: "otherSyncSettingsExpanded", defaultValue: false),
  setman_packageNames<List<String>>(name: "packageNames", defaultValue: []),
  setman_syncOnAppOpened<bool>(name: "syncOnAppOpened", defaultValue: false),
  setman_syncOnAppClosed<bool>(name: "syncOnAppClosed", defaultValue: false),
  setman_lastSyncMethod<String>(name: "lastSyncMethod", defaultValue: ""),
  setman_gitCommitSigningKey<String?>(name: "gitCommitSigningKey", defaultValue: null),
  setman_gitCommitSigningPassphrase<String?>(name: "gitCommitSigningPassphrase", defaultValue: null),
  setman_clientModeEnabled<bool?>(name: "clientModeEnabled", defaultValue: false, hasDefault: true),
  setman_optimisedSyncExperimental<bool>(name: "optimisedSyncExperimental", defaultValue: false),
  setman_githubScopedOauth<bool>(name: "githubScopedOauth", defaultValue: false),

  // Git Manager
  setman_lfsFilePaths<List<String>>(name: "lfsFilePaths", defaultValue: []),
  setman_recommendedAction<int?>(name: "recommendedAction", defaultValue: null),
  setman_recentCommits<List<String>>(name: "recentCommits", defaultValue: []),
  setman_conflicting<List<String>>(name: "conflicting", defaultValue: []),
  setman_uncommittedFilePaths<List<String>>(name: "uncommittedFilePaths", defaultValue: []),
  setman_stagedFilePaths<List<String>>(name: "stagedFilePaths", defaultValue: []),
  setman_branchName<String?>(name: "branchName", defaultValue: null),
  setman_branchNames<List<String>>(name: "branchNames", defaultValue: []),
  setman_disableSsl<bool>(name: "disableSsl", defaultValue: false),
  setman_submodulePaths<List<String>>(name: "submodulePaths", defaultValue: []);

  const StorageKey({required this.name, required this.defaultValue, this.hasDefault = false});
  final T defaultValue;
  final bool hasDefault;
  final String name;
}

Type getType<T>() => T;

class Storage<T extends StorageKey> {
  final FlutterSecureStorage storage;
  final String Function(String) keyTransformer;

  static String defaultKeyTransformer(key) => key;

  Storage({String? name, this.keyTransformer = defaultKeyTransformer})
    : storage = FlutterSecureStorage(
        aOptions: AndroidOptions(sharedPreferencesName: name, resetOnError: true),
        iOptions: IOSOptions(accountName: name),
      );

  String getKeyName(StorageKey key) => keyTransformer(key.name.toString());

  Future<bool> getBool(StorageKey<bool> key, [bool defaulting = false]) async => _get<bool>(key, defaulting);
  Future<bool?> getBoolNullable(StorageKey<bool?> key, [bool defaulting = false]) async => _get<bool?>(key, defaulting);
  Future<String> getString(StorageKey<String> key, [bool defaulting = false]) async => _get<String>(key, defaulting);
  Future<String?> getStringNullable(StorageKey<String?> key, [bool defaulting = false]) async => _get<String?>(key, defaulting);
  Future<int> getInt(StorageKey<int> key, [bool defaulting = false]) async => _get<int>(key, defaulting);
  Future<int?> getIntNullable(StorageKey<int?> key, [bool defaulting = false]) async => _get<int?>(key, defaulting);
  Future<List<String>> getStringList(StorageKey<List<String>> key, [bool defaulting = false]) async => _get<List<String>>(key, defaulting);

  Future<void> setBool(StorageKey<bool> key, bool value) async => _set<bool>(key, value);
  Future<void> setBoolNullable(StorageKey<bool?> key, bool? value) async => _set<bool?>(key, value);
  Future<void> setString(StorageKey<String> key, String value) async => _set<String>(key, value);
  Future<void> setStringNullable(StorageKey<String?> key, String? value) async => _set<String?>(key, value);
  Future<void> setInt(StorageKey<int> key, int value) async => _set<int>(key, value);
  Future<void> setIntNullable(StorageKey<int?> key, int? value) async => _set<int?>(key, value);
  Future<void> setStringList(StorageKey<List<String>> key, List<String> value) async => _set<List<String>>(key, value);

  Future<N> _get<N>(StorageKey<N> key, [bool defaulting = false]) async {
    String? value = await storage.read(key: getKeyName(key));
    N defaultValue = key.defaultValue;

    if (key.hasDefault && !defaulting) throw StateError('Key <${key.name}> requires defaulting=true when hasDefault is set.');

    if (N == getType<String?>() || N == getType<String>()) {
      if (null is N) {
        return (value == "null" ? null : value) as N;
      }

      return (value ?? defaultValue) as N;
    }

    if (N == getType<int?>() || N == getType<int>()) {
      final finalValue = (value == null ? null : int.tryParse(value));

      if (null is N) {
        return finalValue as N;
      }

      return (finalValue ?? defaultValue) as N;
    }

    if (N == getType<bool?>() || N == getType<bool>()) {
      final finalValue = (value == null ? null : value == "true");

      if (null is N) {
        return finalValue as N;
      }

      return (finalValue ?? defaultValue) as N;
    }

    if (N == getType<List<String>?>() || N == getType<List<String>>()) {
      final finalValue = (value?.isEmpty == true ? null : value)?.split(",");

      if (null is N) {
        return finalValue as N;
      }

      return (finalValue ?? defaultValue) as N;
    }

    throw Exception("Key <${key.name.toString()}> datatype <$N> unsupported!");
  }

  Future<void> _set<N>(StorageKey<N> key, N value) async {
    if (N == getType<int?>() || N == getType<int>()) {
      await storage.write(key: getKeyName(key), value: value.toString());
      return;
    }

    if (N == getType<String?>() || N == getType<String>()) {
      await storage.write(key: getKeyName(key), value: value as String?);
      return;
    }

    if (N == getType<bool?>() || N == getType<bool>()) {
      await storage.write(key: getKeyName(key), value: value.toString());
      return;
    }

    if (N == getType<List<String>?>() || N == getType<List<String>>()) {
      await storage.write(key: getKeyName(key), value: value == null ? "" : (value as List<String>).join(","));
      return;
    }

    throw Exception("Key <${key.name.toString()}> datatype <$N> unsupported!");
  }

  Future<Map<String, String>> getAll() async {
    return await storage.readAll();
  }

  Future<void> setAll(Map<String, dynamic> value) async {
    for (var pair in value.entries) {
      await storage.write(key: pair.key, value: pair.value);
    }
  }
}
