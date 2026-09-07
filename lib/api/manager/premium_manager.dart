import 'dart:async';
import 'dart:convert';
import 'package:GitSync/api/helper.dart';
import 'package:GitSync/api/logger.dart';
import 'package:GitSync/api/manager/settings_manager.dart';
import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/global.dart';
import 'package:flutter/foundation.dart';

enum GhSponsorCheck { sponsor, notSponsor, notLinked, tokenRejected, unreachable }

class PremiumManager {
  final ValueNotifier<bool?> hasPremiumNotifier = ValueNotifier(null);

  Future<void> init() async {
    await updateGitHubSponsorPremium();

    final isPremium = await _readPremiumStatus();
    hasPremiumNotifier.value = isPremium;
  }

  Future<bool> _readPremiumStatus() async {
    return
    // kDebugMode ||
    await repoManager.getBool(StorageKey.repoman_hasGHSponsorPremium);
  }

  Future<GhSponsorCheck> updateGitHubSponsorPremium() async {
    if (!await hasNetworkConnection()) {
      return GhSponsorCheck.unreachable;
    }

    final userToken = await repoManager.getStringNullable(StorageKey.repoman_ghSponsorToken);
    if (userToken == null) {
      await _setGhSponsorPremium(false);
      return GhSponsorCheck.notLinked;
    }

    final userRes = await httpGet(
      Uri.parse('https://api.github.com/user'),
      headers: {'Authorization': 'token $userToken', 'Accept': 'application/vnd.github.v3+json'},
    );

    if (userRes.statusCode == 401 || userRes.statusCode == 403) {
      await _setGhSponsorPremium(false);
      Logger.log("GitHub sponsor check rejected the stored token (${userRes.statusCode})");
      return GhSponsorCheck.tokenRejected;
    }

    if (userRes.statusCode != 200) {
      Logger.log("GitHub sponsor check could not read the account (${userRes.statusCode})");
      return GhSponsorCheck.unreachable;
    }

    final userNodeId = jsonDecode(userRes.body)['node_id'].toString();

    final fileRes = await httpGet(Uri.parse('https://raw.githubusercontent.com/ViscousPot/sponsors-gitsync/refs/heads/main/sponsors.txt'));

    if (userNodeId.isEmpty || fileRes.statusCode != 200) {
      Logger.log("GitHub sponsor check could not read the sponsor list (${fileRes.statusCode})");
      return GhSponsorCheck.unreachable;
    }

    final content = utf8.decode(fileRes.bodyBytes);
    final lines = LineSplitter.split(content).map((e) => e.trim()).toList();
    final isSponsor = lines.contains(userNodeId);

    await _setGhSponsorPremium(isSponsor);
    return isSponsor ? GhSponsorCheck.sponsor : GhSponsorCheck.notSponsor;
  }

  Future<void> _setGhSponsorPremium(bool value) async {
    await repoManager.setBool(StorageKey.repoman_hasGHSponsorPremium, value);
    hasPremiumNotifier.value = await _readPremiumStatus();
  }

  Future<bool> cullNonPremium() async {
    final repomanReponames = await repoManager.getStringList(StorageKey.repoman_repoNames);
    if (repomanReponames.length > 1) {
      List.generate(repomanReponames.length - 1, (index) async {
        final manager = await SettingsManager().reinit(repoIndex: 1 + index);
        await manager.clearAll();
      });
      await repoManager.setInt(StorageKey.repoman_repoIndex, 0);
      await repoManager.setStringList(StorageKey.repoman_repoNames, [repomanReponames[0]]);
      return true;
    }
    return false;
  }

  void dispose() async {
    hasPremiumNotifier.dispose();
  }
}
