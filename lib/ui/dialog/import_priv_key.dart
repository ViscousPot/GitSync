import 'package:GitSync/api/helper.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import '../../../constant/colors.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';
import 'package:GitSync/global.dart';

Future<void> showDialog(BuildContext context, Function((String, String) sshCredentials) callback) {
  final keyController = TextEditingController();
  final passphraseController = TextEditingController();

  return mat.showDialog(
    context: context,
    builder: (BuildContext context) => BaseAlertDialog(
      title: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Text(
          t.importPrivateKey,
          style: TextStyle(color: primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
        ),
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            Text(
              t.importPrivateKeyMsg,
              style: const TextStyle(color: primaryLight, fontWeight: FontWeight.bold, fontSize: textSM),
            ),
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
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM),
                        decoration: BoxDecoration(color: secondaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
                        height: textMD * 1.5 + (spaceSM * 2),
                        child: SingleChildScrollView(
                          child: TextField(
                            contextMenuBuilder: globalContextMenuBuilder,
                            controller: keyController,
                            maxLines: null,
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
                              border: const OutlineInputBorder(borderSide: BorderSide.none),
                              hintText: t.sshPrivKeyExample,
                              hintStyle: TextStyle(
                                fontSize: textSM,
                                fontWeight: FontWeight.bold,
                                overflow: TextOverflow.ellipsis,
                                color: tertiaryLight,
                              ),
                              isCollapsed: true,
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              isDense: true,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(
            t.cancel.toUpperCase(),
            style: TextStyle(color: primaryLight, fontSize: textMD),
          ),
          onPressed: () {
            Navigator.of(context).canPop() ? Navigator.pop(context) : null;
          },
        ),
        TextButton(
          child: Text(
            t.importKey.toUpperCase(),
            style: TextStyle(color: primaryPositive, fontSize: textMD),
          ),
          onPressed: () async {
            callback((passphraseController.text, keyController.text));
            Navigator.of(context).canPop() ? Navigator.pop(context) : null;
          },
        ),
      ],
    ),
  );
}
