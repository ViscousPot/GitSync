import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/l10n/app_localizations.dart';

Future<void> showDialog(BuildContext context, Future<void> Function(String locale) callback) {
  final localesOrder = ["en", "zh", "zh_Hant", "es", "ru", "fr", "de"];
  final localesMap = {
    for (var locale in [
      ...localesOrder,
      ...AppLocalizations.supportedLocales.map((locale) => locale.languageCode).where((code) => !localesOrder.contains(code)),
    ])
      locale: LocaleNamesLocalizationsDelegate.nativeLocaleNames[locale],
  };

  return mat.showDialog(
    context: context,
    builder: (BuildContext context) => BaseAlertDialog(
      backgroundColor: colours.secondaryDark,
      title: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.language, color: colours.primaryLight, size: textLG),
            SizedBox(width: spaceSM),
            Text(
              t.language.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(color: colours.primaryLight, fontSize: textLG, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: spaceLG),
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            ...localesMap.entries.map(
              (locale) => Column(
                children: [
                  SizedBox(height: spaceSM),
                  TextButton.icon(
                    onPressed: () async {
                      await callback(locale.key);
                    },
                    iconAlignment: IconAlignment.end,
                    style: ButtonStyle(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceLG, vertical: spaceMD)),
                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none)),
                      backgroundColor: WidgetStatePropertyAll(colours.tertiaryDark),
                    ),
                    label: SizedBox(
                      width: double.infinity,
                      child: Text(
                        locale.value!,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFeatures: [FontFeature.enable('smcp')], color: colours.primaryLight, fontSize: textLG),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
