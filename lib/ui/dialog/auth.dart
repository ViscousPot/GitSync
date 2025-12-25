import 'package:GitSync/api/helper.dart';
import 'package:GitSync/api/manager/auth/github_app_manager.dart';
import 'package:GitSync/api/manager/auth/github_manager.dart';
import 'package:GitSync/api/manager/settings_manager.dart';
import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/constant/strings.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/api/manager/git_manager.dart';
import 'package:sprintf/sprintf.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../api/manager/auth/git_provider_manager.dart';
import '../../../constant/colors.dart';
import '../../../constant/dimens.dart';
import '../../../global.dart';
import '../../../type/git_provider.dart';
import '../../../ui/dialog/base_alert_dialog.dart';
import 'import_priv_key.dart' as ImportPrivKeyDialog;
import 'confirm_priv_key_copy.dart' as ConfirmPrivKeyCopyDialog;

final GlobalKey authDialogKey = GlobalKey();

Future<void> showDialog(BuildContext parentContext, Function() callback) async {
  List<String> repoNames = [...await repoManager.getStringList(StorageKey.repoman_repoNames)];
  await repoNames.removeAt(await repoManager.getInt(StorageKey.repoman_repoIndex));
  GitProvider selectedGitProvider = await uiSettingsManager.getGitProvider();

  final httpsUsernameController = TextEditingController();
  final httpsTokenController = TextEditingController();
  final passphraseController = TextEditingController();

  (String, String)? keyPair;
  bool pubKeyCopied = false;
  bool privKeyCopied = false;

  bool getHttpsCanLogin() {
    return !(httpsUsernameController.text.isEmpty || httpsTokenController.text.isEmpty);
  }

  Future<void> finish(BuildContext context, GitProvider selectedGitProvider) async {
    await repoManager.setOnboardingStep(3);
    await uiSettingsManager.setStringNullable(StorageKey.setman_gitProvider, selectedGitProvider.name);
    Navigator.of(context).canPop() ? Navigator.pop(context) : null;
    callback();
  }

  Future<void> setHttpAuth(BuildContext context, (String, String, String) authCredentials, GitProvider selectedGitProvider) async {
    await uiSettingsManager.setGitHttpAuthCredentials(authCredentials.$1, authCredentials.$2, authCredentials.$3);
    await finish(context, selectedGitProvider);
  }

  Future<void> setSshAuth(BuildContext context, (String, String) sshCredentials, GitProvider selectedGitProvider) async {
    uiSettingsManager.setGitSshAuthCredentials(sshCredentials.$1, sshCredentials.$2);
    await finish(context, selectedGitProvider);
  }

  Widget buildActions(BuildContext context, void Function(void Function()) setState) {
    switch (selectedGitProvider) {
      case GitProvider.GITHUB:
        return Column(
          children: [
            TextButton.icon(
              onPressed: () async {
                uiSettingsManager.setBool(StorageKey.setman_githubScopedOauth, false);

                final gitProviderManager = GithubManager();

                final result = await gitProviderManager.launchOAuthFlow();

                if (result == null) return;

                await setHttpAuth(context, result, selectedGitProvider);
              },
              style: ButtonStyle(
                alignment: Alignment.center,
                backgroundColor: WidgetStatePropertyAll(primaryPositive),
                padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM)),
                shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none)),
              ),
              icon: FaIcon(FontAwesomeIcons.squareArrowUpRight, color: secondaryDark, size: textLG),
              label: Text(
                t.oauthAllRepos.toUpperCase(),
                style: TextStyle(color: secondaryDark, fontSize: textSM, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: spaceSM),
            TextButton.icon(
              onPressed: () async {
                uiSettingsManager.setBool(StorageKey.setman_githubScopedOauth, true);

                final gitProviderManager = GithubAppManager();

                final result = await gitProviderManager.launchOAuthFlow();

                if (result == null) return;

                final token = await gitProviderManager.getToken(result.$3, (_, _, _) async {});
                if (token == null) return;

                final githubAppInstallations = await gitProviderManager.getGitHubAppInstallations(token);
                if (githubAppInstallations.isEmpty) {
                  await launchUrl(Uri.parse(githubAppsLink));
                } else {
                  await launchUrl(Uri.parse(sprintf(githubInstallationsLink, [githubAppInstallations[0]["id"]])));
                }

                await setHttpAuth(context, result, selectedGitProvider);
              },
              style: ButtonStyle(
                alignment: Alignment.center,
                backgroundColor: WidgetStatePropertyAll(primaryPositive),
                padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM)),
                shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none)),
              ),
              icon: FaIcon(FontAwesomeIcons.squareArrowUpRight, color: secondaryDark, size: textLG),
              label: Text(
                t.oauthScoped.toUpperCase(),
                style: TextStyle(color: secondaryDark, fontSize: textSM, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      case GitProvider.GITEA:
      case GitProvider.GITLAB:
        return TextButton.icon(
          onPressed: () async {
            final gitProviderManager = GitProviderManager.getGitProviderManager(selectedGitProvider, false);
            if (gitProviderManager == null) return;

            final result = await gitProviderManager.launchOAuthFlow();

            if (result == null) return;

            await setHttpAuth(context, result, selectedGitProvider);
          },
          style: ButtonStyle(
            alignment: Alignment.center,
            backgroundColor: WidgetStatePropertyAll(primaryPositive),
            padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM)),
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none)),
          ),
          icon: FaIcon(FontAwesomeIcons.squareArrowUpRight, color: secondaryDark, size: textLG),
          label: Text(
            t.oauth.toUpperCase(),
            style: TextStyle(color: secondaryDark, fontSize: textSM, fontWeight: FontWeight.bold),
          ),
        );
      case GitProvider.HTTPS:
        return TextButton(
          onPressed: getHttpsCanLogin()
              ? () async {
                  await setHttpAuth(context, (httpsUsernameController.text.trim(), "", httpsTokenController.text.trim()), selectedGitProvider);
                }
              : null,
          style: ButtonStyle(
            alignment: Alignment.center,
            backgroundColor: WidgetStatePropertyAll(getHttpsCanLogin() ? primaryPositive : secondaryPositive),
            padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM)),
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none)),
          ),
          child: Text(
            t.login.toUpperCase(),
            style: TextStyle(color: getHttpsCanLogin() ? secondaryDark : tertiaryDark, fontSize: textSM, fontWeight: FontWeight.bold),
          ),
        );
      case GitProvider.SSH:
        return SizedBox(
          width: double.infinity,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: keyPair == null
                      ? () async {
                          keyPair = await GitManager.generateKeyPair(passphraseController.text);
                          setState(() {});
                        }
                      : (pubKeyCopied
                            ? () async {
                                setSshAuth(parentContext, (passphraseController.text, keyPair!.$1), selectedGitProvider);
                              }
                            : null),
                  style: ButtonStyle(
                    alignment: Alignment.center,
                    backgroundColor: WidgetStatePropertyAll((keyPair != null && !pubKeyCopied) ? secondaryPositive : primaryPositive),
                    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM)),
                    shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none)),
                  ),
                  child: Text(
                    (keyPair == null ? t.generateKeys : t.confirmKeySaved).toUpperCase(),
                    style: TextStyle(
                      color: (keyPair != null && !pubKeyCopied) ? tertiaryDark : secondaryDark,
                      fontSize: textSM,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              keyPair == null
                  ? Positioned(
                      right: 0,
                      child: IconButton(
                        onPressed: () async {
                          ImportPrivKeyDialog.showDialog(context, ((String, String) sshCredentials) {
                            setSshAuth(context, sshCredentials, selectedGitProvider);
                          });
                        },
                        style: ButtonStyle(
                          alignment: Alignment.center,
                          backgroundColor: WidgetStatePropertyAll(primaryPositive),
                          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM)),
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
                          ),
                        ),
                        icon: FaIcon(FontAwesomeIcons.key, color: secondaryDark, size: textSM),
                      ),
                    )
                  : SizedBox.shrink(),
            ],
          ),
        );
    }
  }

  Widget buildContent(void Function(void Function()) setState) {
    switch (selectedGitProvider) {
      case GitProvider.GITHUB:
      case GitProvider.GITEA:
      case GitProvider.GITLAB:
        return Padding(
          padding: EdgeInsets.only(top: spaceMD, left: spaceMD, right: spaceMD),
          child: Text(
            t.oauthNoAffiliation,
            textAlign: TextAlign.center,
            style: const TextStyle(color: secondaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
          ),
        );
      case GitProvider.HTTPS:
        return Column(
          children: [
            SizedBox(height: spaceLG),
            Text(
              t.ensureTokenScope,
              textAlign: TextAlign.center,
              style: const TextStyle(color: secondaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
            ),
            SizedBox(height: spaceLG),
            Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: spaceSM),
                      child: Text(
                        t.user.toUpperCase(),
                        style: TextStyle(color: primaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(height: spaceMD),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: spaceSM),
                      child: Text(
                        t.token.toUpperCase(),
                        style: TextStyle(color: primaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: spaceMD),
                Expanded(
                  child: Column(
                    children: [
                      TextField(
                        contextMenuBuilder: globalContextMenuBuilder,
                        controller: httpsUsernameController,
                        maxLines: 1,
                        enableSuggestions: false,
                        autocorrect: false,
                        style: TextStyle(
                          color: primaryLight,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                          decorationThickness: 0,
                          fontSize: textMD,
                        ),
                        decoration: InputDecoration(
                          fillColor: secondaryDark,
                          filled: true,
                          border: const OutlineInputBorder(borderRadius: BorderRadius.all(cornerRadiusSM), borderSide: BorderSide.none),
                          hintText: t.exampleUser,
                          hintStyle: TextStyle(fontSize: textSM, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis, color: tertiaryLight),
                          isCollapsed: true,
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          contentPadding: const EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM),
                          isDense: true,
                        ),
                        onChanged: (_) {
                          setState(() {});
                        },
                      ),
                      SizedBox(height: spaceMD),
                      TextField(
                        contextMenuBuilder: globalContextMenuBuilder,
                        controller: httpsTokenController,
                        maxLines: 1,
                        obscureText: true,
                        enableSuggestions: false,
                        autocorrect: false,
                        style: TextStyle(
                          color: primaryLight,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                          decorationThickness: 0,
                          fontSize: textMD,
                        ),
                        decoration: InputDecoration(
                          fillColor: secondaryDark,
                          filled: true,
                          border: const OutlineInputBorder(borderRadius: BorderRadius.all(cornerRadiusSM), borderSide: BorderSide.none),
                          hintText: t.exampleToken,
                          hintStyle: TextStyle(fontSize: textSM, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis, color: tertiaryLight),
                          isCollapsed: true,
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          contentPadding: const EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM),
                          isDense: true,
                        ),
                        onChanged: (_) {
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      case GitProvider.SSH:
        return Column(
          children: [
            SizedBox(height: spaceLG),
            Row(
              children: [
                Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: spaceSM),
                      child: Text(
                        t.passphrase.toUpperCase(),
                        style: TextStyle(color: primaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(height: spaceMD),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: spaceSM),
                      child: Text(
                        t.privKey.toUpperCase(),
                        style: TextStyle(color: primaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(height: spaceMD),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: spaceSM),
                      child: Text(
                        t.pubKey.toUpperCase(),
                        style: TextStyle(color: primaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: spaceMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        contextMenuBuilder: globalContextMenuBuilder,
                        controller: passphraseController,
                        maxLines: 1,
                        obscureText: true,
                        enableSuggestions: false,
                        autocorrect: false,
                        style: TextStyle(
                          color: primaryLight,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                          decorationThickness: 0,
                          fontSize: textMD,
                        ),
                        decoration: InputDecoration(
                          fillColor: secondaryDark,
                          filled: true,
                          border: const OutlineInputBorder(borderRadius: BorderRadius.all(cornerRadiusSM), borderSide: BorderSide.none),
                          hintText: t.optionalLabel.toUpperCase(),
                          hintStyle: TextStyle(fontSize: textSM, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis, color: tertiaryLight),
                          isCollapsed: true,
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          contentPadding: const EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM),
                          isDense: true,
                        ),
                      ),
                      SizedBox(height: spaceSM),
                      TextButton.icon(
                        onPressed: keyPair == null
                            ? null
                            : () async {
                                ConfirmPrivKeyCopyDialog.showDialog(parentContext, () {
                                  Clipboard.setData(ClipboardData(text: keyPair!.$1));
                                  privKeyCopied = true;
                                  setState(() {});
                                });
                              },
                        style: ButtonStyle(
                          alignment: Alignment.center,
                          backgroundColor: WidgetStatePropertyAll(secondaryDark),
                          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM)),
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM), side: BorderSide.none),
                          ),
                        ),
                        iconAlignment: IconAlignment.end,
                        icon: FaIcon(
                          privKeyCopied ? FontAwesomeIcons.clipboardCheck : FontAwesomeIcons.solidCopy,
                          color: keyPair == null ? tertiaryLight : (privKeyCopied ? primaryPositive : primaryLight),
                          size: textMD,
                        ),
                        label: Text(
                          keyPair == null ? t.sshPrivKeyExample : keyPair!.$1,
                          maxLines: 1,
                          style: TextStyle(
                            color: keyPair == null ? tertiaryLight : primaryLight,
                            fontSize: textSM,
                            fontWeight: FontWeight.bold,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      SizedBox(height: spaceSM),
                      TextButton.icon(
                        onPressed: keyPair == null
                            ? null
                            : () async {
                                Clipboard.setData(ClipboardData(text: keyPair!.$2));
                                pubKeyCopied = true;
                                setState(() {});
                              },
                        style: ButtonStyle(
                          alignment: Alignment.center,
                          backgroundColor: WidgetStatePropertyAll(secondaryDark),
                          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM)),
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM), side: BorderSide.none),
                          ),
                        ),
                        iconAlignment: IconAlignment.end,
                        icon: FaIcon(
                          pubKeyCopied ? FontAwesomeIcons.clipboardCheck : FontAwesomeIcons.solidCopy,
                          color: keyPair == null ? tertiaryLight : (pubKeyCopied ? primaryPositive : primaryLight),
                          size: textMD,
                        ),
                        label: Text(
                          keyPair == null ? t.sshPubKeyExample : keyPair!.$2,
                          maxLines: 1,
                          style: TextStyle(
                            color: keyPair == null ? tertiaryLight : primaryLight,
                            fontSize: textSM,
                            fontWeight: FontWeight.bold,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }

  return await mat.showDialog(
    context: parentContext,
    builder: (BuildContext context) => StatefulBuilder(
      builder: (context, setState) => BaseAlertDialog(
        key: authDialogKey,
        titlePadding: EdgeInsets.only(left: 0, top: 0, right: 24.0, bottom: 0),
        title: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Stack(
            children: [
              Positioned.fill(
                top: 24,
                // bottom: 0,
                child: Text(
                  t.auth.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                decoration: BoxDecoration(color: tertiaryLight, borderRadius: BorderRadius.all(cornerRadiusSM)),
                padding: EdgeInsets.symmetric(horizontal: spaceXXS, vertical: spaceXXXS),
                margin: EdgeInsets.only(top: spaceSM, left: spaceSM, bottom: 24 - spaceSM),
                child: Text(
                  t.replacesExistingAuth.toUpperCase(),
                  style: TextStyle(color: primaryDark, fontSize: textXXS, fontWeight: FontWeight.w900, height: 1),
                ),
              ),
            ],
          ),
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Text(
                t.selectYourGitProviderAndAuthenticate,
                textAlign: TextAlign.center,
                style: const TextStyle(color: secondaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
              ),
              SizedBox(height: spaceMD),
              Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.all(cornerRadiusMD), color: secondaryDark),
                child: DropdownButton(
                  borderRadius: BorderRadius.all(cornerRadiusMD),
                  isExpanded: true,
                  padding: const EdgeInsets.only(left: spaceSM),
                  icon: Padding(
                    padding: EdgeInsets.only(right: spaceMD),
                    child: FaIcon(FontAwesomeIcons.caretDown, color: secondaryLight, size: textMD, semanticLabel: t.authDropdownLabel),
                  ),
                  value: selectedGitProvider.name,
                  style: const TextStyle(backgroundColor: secondaryDark, color: tertiaryLight, fontWeight: FontWeight.bold, fontSize: textMD),
                  underline: const SizedBox.shrink(),
                  dropdownColor: secondaryDark,
                  onChanged: (value) {
                    if (value == null) return;

                    selectedGitProvider = GitProvider.values.firstWhere((provider) => provider.name == value);
                    setState(() {});
                  },
                  items:
                      [
                        if (demo || repoNames.length >= 1) "copyFromContainer",
                        if (demo || repoNames.length >= 1) "orSeparator",
                        ...GitProviderManager.GitProviderIconsMap.keys.toList().sublist(0, GitProviderManager.GitProviderIconsMap.keys.length - 2),
                        "protocolSeparator",
                        ...GitProviderManager.GitProviderIconsMap.keys.toList().sublist(GitProviderManager.GitProviderIconsMap.keys.length - 2),
                      ].map((e) {
                        if (e is GitProvider)
                          return DropdownMenuItem(
                            value: e.name.toUpperCase(),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    GitProviderManager.GitProviderIconsMap[e]!,
                                    SizedBox(width: spaceSM),
                                    Text(
                                      e.name.toUpperCase(),
                                      style: TextStyle(fontSize: textSM, color: primaryLight),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        switch (e) {
                          case "copyFromContainer":
                            {
                              return DropdownMenuItem(
                                value: null,
                                onTap: () {},
                                enabled: false,
                                child: Container(
                                  decoration: BoxDecoration(borderRadius: BorderRadius.all(cornerRadiusSM), color: primaryDark),
                                  child: DropdownButton(
                                    borderRadius: BorderRadius.all(cornerRadiusMD),
                                    isExpanded: true,
                                    padding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceXS),
                                    isDense: true,
                                    icon: Padding(
                                      padding: EdgeInsets.only(right: spaceMD),
                                      child: FaIcon(
                                        FontAwesomeIcons.caretDown,
                                        color: secondaryLight,
                                        size: textMD,
                                        semanticLabel: t.authDropdownLabel,
                                      ),
                                    ),
                                    value: null,
                                    // value: selectedGitProvider.name,
                                    style: const TextStyle(color: tertiaryLight, fontWeight: FontWeight.bold, fontSize: textMD),
                                    hint: SizedBox(
                                      width: double.infinity,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          FaIcon(FontAwesomeIcons.solidCopy, color: tertiaryInfo, size: textMD),
                                          SizedBox(width: spaceSM),
                                          Text(
                                            t.copyFromContainer.toUpperCase(),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(color: tertiaryInfo, fontSize: textSM, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    underline: const SizedBox.shrink(),
                                    dropdownColor: primaryDark,
                                    onChanged: (value) {},
                                    items: repoNames
                                        .map(
                                          (repo) => DropdownMenuItem(
                                            value: repo,
                                            onTap: () async {
                                              final tempSettingsManager = SettingsManager();
                                              await tempSettingsManager.reinit(repoIndex: repoNames.indexOf(repo));

                                              final gitProvider = await tempSettingsManager.getGitProvider();
                                              final sshAuthCreds = await tempSettingsManager.getGitSshAuthCredentials();
                                              final httpAuthCreds = await tempSettingsManager.getGitHttpAuthCredentials();
                                              final githubScopedOauth = await tempSettingsManager.getBool(StorageKey.setman_githubScopedOauth);
                                              final httpAuthorEmail = await tempSettingsManager.getAuthorEmail();
                                              await uiSettingsManager.reinit();

                                              if (gitProvider == GitProvider.SSH) {
                                                await setSshAuth(context, (sshAuthCreds.$1, sshAuthCreds.$2), gitProvider);
                                              } else {
                                                await uiSettingsManager.setBool(StorageKey.setman_githubScopedOauth, githubScopedOauth);
                                                await setHttpAuth(context, (httpAuthCreds.$1, httpAuthorEmail, httpAuthCreds.$2), gitProvider);
                                              }
                                            },
                                            enabled: true,
                                            child: Text(
                                              repo.toUpperCase(),
                                              style: TextStyle(color: primaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              );
                            }
                          case "orSeparator":
                            {
                              return DropdownMenuItem(
                                value: null,
                                onTap: () {},
                                enabled: false,
                                child: Center(
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        margin: EdgeInsets.symmetric(horizontal: spaceMD),
                                        color: tertiaryDark,
                                        clipBehavior: Clip.none,
                                        height: 2,
                                        width: double.infinity,
                                      ),
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        bottom: -(textMD + spaceSM + spaceSM) / 2,
                                        child: Center(
                                          child: Container(
                                            color: secondaryDark,
                                            padding: EdgeInsets.all(spaceSM),
                                            child: Text(
                                              t.or.toUpperCase(),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: primaryPositive,
                                                backgroundColor: secondaryDark,
                                                fontSize: textMD,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          case "protocolSeparator":
                            {
                              return DropdownMenuItem(
                                value: null,
                                onTap: () {},
                                enabled: false,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      t.oauthProviders.toUpperCase(),
                                      style: TextStyle(color: primaryPositive, fontSize: textSM, fontWeight: FontWeight.bold),
                                    ),
                                    Container(
                                      margin: EdgeInsets.symmetric(horizontal: spaceMD),
                                      color: tertiaryDark,
                                      height: 2,
                                      width: double.infinity,
                                    ),
                                    Text(
                                      t.gitProtocols.toUpperCase(),
                                      style: TextStyle(color: secondaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              );
                            }
                        }
                        return DropdownMenuItem(
                          value: null,
                          onTap: () {},
                          enabled: false,
                          child: Center(
                            child: Container(
                              margin: EdgeInsets.symmetric(horizontal: spaceMD),
                              color: tertiaryDark,
                              height: 2,
                              width: double.infinity,
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
              buildContent(setState),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(vertical: spaceMD),
            child: buildActions(context, setState),
          ),
        ],
      ),
    ),
  );
}
