import 'dart:convert';
import 'package:GitSync/api/helper.dart';
import 'package:GitSync/api/logger.dart';

import '../../manager/auth/github_manager.dart';
import '../../../constant/secrets.dart';

class GithubAppManager extends GithubManager {
  GithubAppManager();

  @override
  get clientId => gitHubAppClientId;
  @override
  get clientSecret => gitHubAppClientSecret;
  @override
  bool get supportsTokenRefresh => true;

  Future<List<Map<String, dynamic>>> getGitHubAppInstallations(String accessToken) async {
    try {
      final response = await httpGet(
        Uri.parse("https://api.github.com/user/installations"),
        headers: {"Accept": "application/vnd.github.v3+json", "Authorization": "token $accessToken"},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        return List<Map<String, dynamic>>.from(jsonResponse['installations'] ?? []).where((item) => item["client_id"] == gitHubAppClientId).toList();
      }
      return [];
    } catch (e, st) {
      Logger.logError(LogType.Global, e, st);
      return [];
    }
  }
}
