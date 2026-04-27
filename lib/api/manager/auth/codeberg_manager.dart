import '../../manager/auth/gitea_manager.dart';
import '../../../constant/secrets.dart';

class CodebergManager extends GiteaManager {
  @override
  String get domain => "codeberg.org";

  @override
  get clientId => codebergClientId;
}
