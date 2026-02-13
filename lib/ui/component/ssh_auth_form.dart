import 'package:GitSync/api/helper.dart';
import 'package:GitSync/api/logger.dart';
import 'package:GitSync/api/manager/git_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constant/dimens.dart';
import '../../global.dart';
import '../dialog/confirm_priv_key_copy.dart' as ConfirmPrivKeyCopyDialog;
import '../dialog/import_priv_key.dart' as ImportPrivKeyDialog;

class SshAuthForm extends StatefulWidget {
  final Future<void> Function(String passphrase, String privateKey) onAuthenticated;
  final BuildContext parentContext;

  const SshAuthForm({super.key, required this.onAuthenticated, required this.parentContext});

  @override
  State<SshAuthForm> createState() => _SshAuthFormState();
}

class _SshAuthFormState extends State<SshAuthForm> {
  final passphraseController = TextEditingController();
  (String, String)? keyPair;
  bool pubKeyCopied = false;
  bool privKeyCopied = false;

  @override
  void dispose() {
    passphraseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    style: TextStyle(color: colours.primaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: spaceMD),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: spaceSM),
                  child: Text(
                    t.privKey.toUpperCase(),
                    style: TextStyle(color: colours.primaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: spaceMD),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: spaceSM),
                  child: Text(
                    t.pubKey.toUpperCase(),
                    style: TextStyle(color: colours.primaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
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
                      color: colours.primaryLight,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                      decorationThickness: 0,
                      fontSize: textMD,
                    ),
                    decoration: InputDecoration(
                      fillColor: colours.secondaryDark,
                      filled: true,
                      border: const OutlineInputBorder(borderRadius: BorderRadius.all(cornerRadiusSM), borderSide: BorderSide.none),
                      hintText: t.optionalLabel.toUpperCase(),
                      hintStyle: TextStyle(
                        fontSize: textSM,
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis,
                        color: colours.tertiaryLight,
                      ),
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
                            ConfirmPrivKeyCopyDialog.showDialog(widget.parentContext, () {
                              Clipboard.setData(ClipboardData(text: keyPair!.$1));
                              privKeyCopied = true;
                              setState(() {});
                            });
                          },
                    style: ButtonStyle(
                      alignment: Alignment.center,
                      backgroundColor: WidgetStatePropertyAll(colours.secondaryDark),
                      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM)),
                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM), side: BorderSide.none)),
                    ),
                    iconAlignment: IconAlignment.end,
                    icon: FaIcon(
                      privKeyCopied ? FontAwesomeIcons.clipboardCheck : FontAwesomeIcons.solidCopy,
                      color: keyPair == null ? colours.tertiaryLight : (privKeyCopied ? colours.primaryPositive : colours.primaryLight),
                      size: textMD,
                    ),
                    label: Text(
                      keyPair == null ? t.sshPrivKeyExample : keyPair!.$1,
                      maxLines: 1,
                      style: TextStyle(
                        color: keyPair == null ? colours.tertiaryLight : colours.primaryLight,
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
                      backgroundColor: WidgetStatePropertyAll(colours.secondaryDark),
                      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM)),
                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM), side: BorderSide.none)),
                    ),
                    iconAlignment: IconAlignment.end,
                    icon: FaIcon(
                      pubKeyCopied ? FontAwesomeIcons.clipboardCheck : FontAwesomeIcons.solidCopy,
                      color: keyPair == null ? colours.tertiaryLight : (pubKeyCopied ? colours.primaryPositive : colours.primaryLight),
                      size: textMD,
                    ),
                    label: Text(
                      keyPair == null ? t.sshPubKeyExample : keyPair!.$2,
                      maxLines: 1,
                      style: TextStyle(
                        color: keyPair == null ? colours.tertiaryLight : colours.primaryLight,
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
        SizedBox(height: spaceMD),
        SizedBox(
          width: double.infinity,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: keyPair == null
                      ? () async {
                          keyPair = await runGitOperation(
                            LogType.GenerateKeyPair,
                            (event) => event == null || event["result"] == null ? null : (event["result"][0], event["result"][1]),
                            {"passphrase": passphraseController.text},
                          );
                          if (mounted) setState(() {});
                        }
                      : (pubKeyCopied
                            ? () async {
                                await widget.onAuthenticated(passphraseController.text, keyPair!.$1);
                              }
                            : null),
                  style: ButtonStyle(
                    alignment: Alignment.center,
                    backgroundColor: WidgetStatePropertyAll(colours.secondaryPositive),
                    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM)),
                    shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none)),
                  ),
                  child: Text(
                    (keyPair == null ? t.generateKeys : t.confirmKeySaved).toUpperCase(),
                    style: TextStyle(
                      color: (keyPair != null && !pubKeyCopied) ? colours.primaryPositive.withAlpha(70) : colours.primaryPositive,
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
                            widget.onAuthenticated(sshCredentials.$1, sshCredentials.$2);
                          });
                        },
                        style: ButtonStyle(
                          alignment: Alignment.center,
                          backgroundColor: WidgetStatePropertyAll(colours.secondaryPositive),
                          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM)),
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
                          ),
                        ),
                        icon: FaIcon(FontAwesomeIcons.key, color: colours.primaryPositive, size: textSM),
                      ),
                    )
                  : SizedBox.shrink(),
            ],
          ),
        ),
      ],
    );
  }
}
