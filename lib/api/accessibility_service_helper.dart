import 'dart:io';

import 'package:GitSync/gitsync_service.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/api/manager/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../ui/dialog/manual_sync.dart' as ManualSyncDialog;

class AccessibilityServiceHelper {
  static const MethodChannel _channel = MethodChannel('accessibility_service_helper');

  static init(BuildContext context, void Function(void Function() fn) setState) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onIntentAction') {
        String action = call.arguments;
        switch (action) {
          case GitsyncService.MANUAL_SYNC:
            {
              await repoManager.setInt(StorageKey.repoman_repoIndex, await repoManager.getInt(StorageKey.repoman_tileManualSyncIndex));
              await uiSettingsManager.reinit();
              setState(() {});
              await ManualSyncDialog.showDialog(context, () async {});
            }
        }
      }
    });
  }

  static Future<bool> hasLegacySettings() async {
    return await _channel.invokeMethod('hasLegacySettings');
  }

  static Future<bool> isAccessibilityServiceEnabled() async {
    if (Platform.isIOS) return false;
    final bool isEnabled = await _channel.invokeMethod('isAccessibilityServiceEnabled') ?? false;
    return isEnabled;
  }

  static Future<void> openAccessibilitySettings() async {
    if (Platform.isIOS) return;
    await _channel.invokeMethod('openAccessibilitySettings');
  }

  static Future<bool> isExcludedFromRecents() async {
    if (Platform.isIOS) return false;
    return await _channel.invokeMethod('isExcludedFromRecents') ?? false;
  }

  static Future<void> excludeFromRecents(bool exclude) async {
    if (Platform.isIOS) return;
    if (exclude) {
      await _channel.invokeMethod('enableExcludeFromRecents');
    } else {
      await _channel.invokeMethod('disableExcludeFromRecents');
    }
  }

  static Future<List<String>> getDeviceApplications() async =>
      ((await _channel.invokeMethod('getDeviceApplications') ?? []) as List).map((item) => item.toString()).toSet().toList();
  static Future<String> getApplicationLabel(String packageName) async => await _channel.invokeMethod('getApplicationLabel', packageName);
  static Future<Uint8List?> getApplicationIcon(String packageName) async => await _channel.invokeMethod<Uint8List>('getApplicationIcon', packageName);
}
