import 'dart:io';

import 'package:GitSync/constant/strings.dart';
import 'package:GitSync/global.dart';

enum DefaultEditor {
  INTERNAL,
  TEXTASTIC;

  static DefaultEditor fromValue(String? value) => values.firstWhere((editor) => editor.value == value, orElse: () => INTERNAL);

  String get value => switch (this) { INTERNAL => editorInternal, TEXTASTIC => editorTextastic };

  bool get isSupported => switch (this) { INTERNAL => true, TEXTASTIC => Platform.isIOS };

  String get label => switch (this) { INTERNAL => t.inAppEditor, TEXTASTIC => textasticName };

  static List<DefaultEditor> get supportedValues => values.where((editor) => editor.isSupported).toList();
}
