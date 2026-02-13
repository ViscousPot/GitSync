import 'package:GitSync/api/helper.dart';
import 'package:flutter/material.dart';
import '../../constant/dimens.dart';
import '../../global.dart';

class HttpsAuthForm extends StatefulWidget {
  final Future<void> Function(String username, String token) onAuthenticated;

  const HttpsAuthForm({super.key, required this.onAuthenticated});

  @override
  State<HttpsAuthForm> createState() => _HttpsAuthFormState();
}

class _HttpsAuthFormState extends State<HttpsAuthForm> {
  final httpsUsernameController = TextEditingController();
  final httpsTokenController = TextEditingController();

  bool get canLogin => httpsUsernameController.text.isNotEmpty && httpsTokenController.text.isNotEmpty;

  @override
  void dispose() {
    httpsUsernameController.dispose();
    httpsTokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: spaceLG),
        Text(
          t.ensureTokenScope,
          textAlign: TextAlign.center,
          style: TextStyle(color: colours.secondaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
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
                    style: TextStyle(color: colours.primaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: spaceMD),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: spaceSM),
                  child: Text(
                    t.token.toUpperCase(),
                    style: TextStyle(color: colours.primaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
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
                      hintText: t.exampleUser,
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
                      hintText: t.exampleToken,
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
                    onChanged: (_) {
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: spaceMD),
        TextButton(
          onPressed: canLogin
              ? () async {
                  await widget.onAuthenticated(httpsUsernameController.text.trim(), httpsTokenController.text.trim());
                }
              : null,
          style: ButtonStyle(
            alignment: Alignment.center,
            backgroundColor: WidgetStatePropertyAll(canLogin ? colours.secondaryPositive : colours.secondaryPositive),
            padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM)),
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none)),
          ),
          child: Text(
            t.login.toUpperCase(),
            style: TextStyle(
              color: canLogin ? colours.primaryPositive : colours.primaryPositive.withAlpha(70),
              fontSize: textSM,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
