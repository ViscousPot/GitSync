import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/global.dart';
import 'package:flutter/material.dart';

class Colours {
  // system = null
  // dark   = true
  // light  = false
  bool darkMode = true;

  Color get primaryLight => darkMode ? Color(0xFFFFFFFF) : Color(0xFF141414);
  Color get secondaryLight => darkMode ? Color(0xFFAAAAAA) : Color(0xFF1C1C1C);
  Color get tertiaryLight => darkMode ? Color(0xFF646464) : Color(0xFF2B2B2B);

  Color get primaryDark => darkMode ? Color(0xFF141414) : Color(0xFFFFFFFF);
  Color get secondaryDark => darkMode ? Color(0xFF1C1C1C) : Color(0xFFDDDDDD);
  Color get tertiaryDark => darkMode ? Color(0xFF2B2B2B) : Color(0xFFBBBBBB);

  Color get primaryPositive => darkMode ? Color(0xFF85F48E) : Color(0xFF3B8E59);
  Color get secondaryPositive => darkMode ? Color(0xFF4F7051) : Color(0xFFA7F3D0);
  Color get tertiaryPositive => darkMode ? Color(0xFFA7F3D0) : Color(0xFF3E7D45);

  Color get primaryNegative => darkMode ? Color(0xFFC22424) : Color(0xFFB21F1F);
  Color get secondaryNegative => darkMode ? Color(0xFF8A1B1B) : Color(0xFFC44D4D);
  Color get tertiaryNegative => darkMode ? Color(0xFFFDA4AF) : Color(0xFF8A1B1B);

  Color get primaryWarning => darkMode ? Color(0xFFFFC107) : Color(0xFF8A5B00);
  Color get secondaryWarning => darkMode ? Color(0xFFFFA000) : Color(0xFFFFE082);
  Color get tertiaryWarning => darkMode ? Color(0xFFFFE082) : Color(0xFFB06A00);

  Color get primaryInfo => darkMode ? Color(0xFF2196F3) : Color(0xFF1976D2);
  Color get secondaryInfo => darkMode ? Color(0xFF1976D2) : Color(0xFF90CAF9);
  Color get tertiaryInfo => darkMode ? Color(0xFF90CAF9) : Color(0xFF0A4B8D);

  // Premium page palette
  Color get premiumBg => darkMode ? Color(0xFF0A1F14) : Color(0xFFF0F9F1);
  Color get premiumSurface => darkMode ? Color(0xFF122A1C) : Color(0xFFDCEEDE);
  Color get premiumBorder => darkMode ? Color(0xFF1E4A2E) : Color(0xFFA5D6A7);
  Color get premiumAccent => darkMode ? Color(0xFFA7F3D0) : Color(0xFF2E7D32);
  Color get premiumTextSecondary => darkMode ? Color(0xFF8BAF9A) : Color(0xFF4E7C5B);

  // Showcase tooltip palette
  Color get showcaseBg => darkMode ? Color(0xFF111D2E) : Color(0xFFE8EDF4);
  Color get showcaseTitle => darkMode ? Color(0xFFFFFFFF) : Color(0xFF111D2E);
  Color get showcaseDesc => darkMode ? Color(0xFF94A3B8) : Color(0xFF475569);
  Color get showcaseBtnPrimary => darkMode ? Color(0xFF60A5FA) : Color(0xFF2563EB);
  Color get showcaseBtnSecondary => darkMode ? Color(0xFF1E3A5F) : Color(0xFFBFDBFE);
  Color get showcaseBtnText => darkMode ? Color(0xFF0A1628) : Color(0xFFFFFFFF);
  Color get showcaseBorder => darkMode ? Color(0xFF1E3A5F) : Color(0xFFBFDBFE);
  Color get showcaseFeatureIcon => darkMode ? Color(0xFF60A5FA) : Color(0xFF2563EB);

  Color get gitlabOrange => Color(0xFFFC6D26);
  Color get giteaGreen => Color(0xFF609926);

  Future<void> reloadTheme(BuildContext context) async {
    final newDarkMode = await repoManager.getBoolNullable(StorageKey.repoman_themeMode);
    darkMode = newDarkMode ?? MediaQuery.of(context).platformBrightness == Brightness.dark;
  }
}
