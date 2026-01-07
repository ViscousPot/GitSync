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
  Color get tertiaryPositive => darkMode ? Color(0xFFA7F3D0) : Color(0xFF4F7051);

  Color get primaryNegative => darkMode ? Color(0xFFC22424) : Color(0xFF9C2B2B);
  Color get secondaryNegative => darkMode ? Color(0xFF8A1B1B) : Color(0xFFFDA4AF);
  Color get tertiaryNegative => darkMode ? Color(0xFFFDA4AF) : Color(0xFF8A1B1B);

  Color get primaryWarning => darkMode ? Color(0xFFFFC107) : Color(0xFF8A5B00);
  Color get secondaryWarning => darkMode ? Color(0xFFFFA000) : Color(0xFFFFE082);
  Color get tertiaryWarning => darkMode ? Color(0xFFFFE082) : Color(0xFFB06A00);

  Color get primaryInfo => darkMode ? Color(0xFF2196F3) : Color(0xFF1976D2);
  Color get secondaryInfo => darkMode ? Color(0xFF1976D2) : Color(0xFF90CAF9);
  Color get tertiaryInfo => darkMode ? Color(0xFF90CAF9) : Color(0xFF0B57A1);

  Color get gitlabOrange => Color(0xFFFC6D26);
  Color get giteaGreen => Color(0xFF609926);

  Future<void> reloadTheme(BuildContext context) async {
    final newDarkMode = await repoManager.getBoolNullable(StorageKey.repoman_themeMode);
    darkMode = newDarkMode ?? MediaQuery.of(context).platformBrightness == Brightness.dark;
  }
}
