final _schemePattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.\-]*://');
final _schemeUrlPattern = RegExp(r'[a-zA-Z][a-zA-Z0-9+.\-]*://[^\s"' r"'" r'<>\\)\]}]+');
final _scpUrlPattern = RegExp(r'[A-Za-z0-9._\-]+@[A-Za-z0-9.\-]+:[A-Za-z0-9._\-]+/[^\s"' r"'" r'<>\\)\]}]+');

String censorRemote(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return trimmed;

  final scheme = _schemePattern.firstMatch(trimmed)?.group(0) ?? '';
  var rest = trimmed.substring(scheme.length);

  var suffix = '';
  if (rest.toLowerCase().endsWith('.git')) {
    suffix = rest.substring(rest.length - 4);
    rest = rest.substring(0, rest.length - 4);
  }

  final masked = rest.split('').map((character) => character == '/' ? '/' : '*').join();
  return '$scheme$masked$suffix';
}

String censorRemotesIn(String text) {
  var result = text.replaceAllMapped(_schemeUrlPattern, (match) => _censorMatch(match.group(0)!));
  result = result.replaceAllMapped(_scpUrlPattern, (match) => _censorMatch(match.group(0)!));
  return result;
}

String _censorMatch(String candidate) {
  var url = candidate;
  var trailing = '';
  while (url.isNotEmpty && !url.toLowerCase().endsWith('.git') && '.,;:!?'.contains(url[url.length - 1])) {
    trailing = '${url[url.length - 1]}$trailing';
    url = url.substring(0, url.length - 1);
  }

  if (!_looksLikeRepoUrl(url)) return candidate;
  return '${censorRemote(url)}$trailing';
}

bool _looksLikeRepoUrl(String url) {
  final scheme = _schemePattern.firstMatch(url)?.group(0);
  if (scheme == null) return true;

  final rest = url.substring(scheme.length);
  if (rest.toLowerCase().endsWith('.git')) return true;

  final slash = rest.indexOf('/');
  if (slash < 0) return false;

  final host = rest.substring(0, slash).split('@').last;
  if (host.toLowerCase().startsWith('api.')) return false;

  final segments = rest.substring(slash + 1).split('/').where((segment) => segment.isNotEmpty).toList();
  return segments.length == 2;
}
