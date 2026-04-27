import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:GitSync/api/helper.dart';
import 'package:GitSync/api/manager/auth/git_provider_manager.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/constant/strings.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/type/git_provider.dart';
import 'package:GitSync/type/tag.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:GitSync/ui/dialog/diff_view.dart' as DiffViewDialog;

class TagsPage extends StatefulWidget {
  final GitProvider gitProvider;
  final String remoteWebUrl;
  final String accessToken;
  final bool githubAppOauth;

  const TagsPage({super.key, required this.gitProvider, required this.remoteWebUrl, required this.accessToken, required this.githubAppOauth});

  @override
  State<TagsPage> createState() => _TagsPageState();
}

class _TagsPageState extends State<TagsPage> {
  final ScrollController _scrollController = ScrollController();
  final List<Tag> _tags = [];
  bool _loading = true;
  Function()? _loadNextPage;
  int _fetchGeneration = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchTags();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  (String, String) _parseOwnerRepo() {
    final segments = Uri.parse(widget.remoteWebUrl).pathSegments;
    return (segments[0], segments[1].replaceAll(".git", ""));
  }

  void _fetchTags() {
    final generation = ++_fetchGeneration;
    setState(() {
      _tags.clear();
      _loading = true;
      _loadNextPage = null;
    });

    final (owner, repo) = _parseOwnerRepo();
    final manager = GitProviderManager.getGitProviderManager(widget.gitProvider, widget.githubAppOauth);
    if (manager == null) return;

    manager.getTags(
      widget.accessToken,
      owner,
      repo,
      (tags) {
        if (!mounted || generation != _fetchGeneration) return;
        setState(() {
          _tags.addAll(tags);
          _loading = false;
        });
      },
      (nextPage) {
        if (!mounted || generation != _fetchGeneration) return;
        setState(() {
          _loadNextPage = nextPage;
          _loading = false;
        });
        if (nextPage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || generation != _fetchGeneration) return;
            if (!_scrollController.hasClients) return;
            if (_scrollController.position.maxScrollExtent <= 0 && _loadNextPage != null) {
              final next = _loadNextPage;
              _loadNextPage = null;
              setState(() => _loading = true);
              next?.call();
            }
          });
        }
      },
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (_loadNextPage != null) {
        final next = _loadNextPage;
        _loadNextPage = null;
        setState(() => _loading = true);
        next?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colours.primaryDark,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: spaceXS, vertical: spaceXS),
              child: Row(
                children: [
                  getBackButton(context, () => Navigator.of(context).pop()),
                  SizedBox(width: spaceXS),
                  Text(
                    t.tags.toUpperCase(),
                    style: TextStyle(color: colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                color: colours.tertiaryDark,
                onRefresh: () async {
                  _fetchTags();
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: _tags.isEmpty && !_loading
                    ? LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: constraints.maxHeight,
                            child: Center(
                              child: Text(
                                t.tagsNotFound.toUpperCase(),
                                style: TextStyle(color: colours.secondaryLight, fontWeight: FontWeight.bold, fontSize: textLG),
                              ),
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: spaceMD),
                        itemCount: _tags.length + (_loading || _loadNextPage != null ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _tags.length) {
                            return Padding(
                              padding: EdgeInsets.all(spaceMD),
                              child: Center(
                                child: CircularProgressIndicator(color: colours.secondaryLight, strokeWidth: spaceXXXXS),
                              ),
                            );
                          }
                          return Padding(
                            padding: EdgeInsets.only(bottom: spaceXS),
                            child: _ItemTag(
                              tag: _tags[index],
                              gitProvider: widget.gitProvider,
                              remoteWebUrl: widget.remoteWebUrl,
                              accessToken: widget.accessToken,
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemTag extends StatelessWidget {
  final Tag tag;
  final GitProvider gitProvider;
  final String remoteWebUrl;
  final String accessToken;

  const _ItemTag({required this.tag, required this.gitProvider, required this.remoteWebUrl, required this.accessToken});

  String _archiveUrl(String ext) {
    final uri = Uri.parse(remoteWebUrl);
    final base = '${uri.scheme}://${uri.host}';
    final segments = uri.pathSegments;
    final owner = segments[0];
    final repo = segments[1].replaceAll('.git', '');
    final encodedTag = Uri.encodeComponent(tag.name);

    return switch (gitProvider) {
      GitProvider.GITLAB => '$base/$owner/$repo/-/archive/$encodedTag/$repo-$encodedTag.$ext',
      _ => '$base/$owner/$repo/archive/$encodedTag.$ext',
    };
  }

  String get _repoName {
    final segments = Uri.parse(remoteWebUrl).pathSegments;
    return segments[1].replaceAll('.git', '');
  }

  Map<String, String> get _authHeaders => switch (gitProvider) {
    GitProvider.GITLAB => {'Authorization': 'Bearer $accessToken'},
    _ => {'Authorization': 'token $accessToken'},
  };

  Future<void> _downloadArchive(String ext) async {
    final url = _archiveUrl(ext);
    final filename = '$_repoName-${tag.name}.$ext';

    Fluttertoast.showToast(msg: 'Downloading...', toastLength: Toast.LENGTH_SHORT, gravity: null);

    try {
      final response = await http.get(Uri.parse(url), headers: _authHeaders).timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        Fluttertoast.showToast(msg: 'Download failed', toastLength: Toast.LENGTH_LONG, gravity: null);
        return;
      }

      final result = await FilePicker.platform.saveFile(dialogTitle: 'Save archive', fileName: filename, bytes: response.bodyBytes);
      if (result == null) return;
      Fluttertoast.showToast(msg: 'Saved to $filename', toastLength: Toast.LENGTH_LONG, gravity: null);
    } catch (_) {
      Fluttertoast.showToast(msg: 'Download failed', toastLength: Toast.LENGTH_LONG, gravity: null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final relativeTime = timeago.format(tag.createdAt, locale: 'en').replaceFirstMapped(RegExp(r'^[A-Z]'), (match) => match.group(0)!.toLowerCase());

    return Container(
      padding: EdgeInsets.all(spaceSM),
      decoration: BoxDecoration(color: colours.secondaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: spaceXXXXS),
                      child: FaIcon(FontAwesomeIcons.tag, size: textMD, color: colours.tertiaryInfo),
                    ),
                    SizedBox(width: spaceXS),
                    Expanded(
                      child: Text(
                        tag.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colours.primaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: spaceXXS),
                Padding(
                  padding: EdgeInsets.only(left: textMD + spaceXS),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          DiffViewDialog.showDialog(context, [], (tag.sha, '${tag.sha}^'), tag.sha.substring(0, 7), null, null, [tag.name]);
                        },
                        child: Text(
                          tag.sha.length >= 7 ? tag.sha.substring(0, 7) : tag.sha,
                          style: TextStyle(color: colours.tertiaryLight, fontSize: textXS, fontFamily: 'monospace'),
                        ),
                      ),
                      Text(
                        ' $bullet ',
                        style: TextStyle(color: colours.tertiaryLight, fontSize: textXS),
                      ),
                      Text(
                        relativeTime,
                        style: TextStyle(color: colours.tertiaryLight, fontSize: textXS),
                      ),
                    ],
                  ),
                ),

                if (tag.message != null) ...[
                  SizedBox(height: spaceXXS),
                  Padding(
                    padding: EdgeInsets.only(left: textMD + spaceXS),
                    child: Text(
                      tag.message!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colours.secondaryLight, fontSize: textXS),
                    ),
                  ),
                ],

                SizedBox(height: spaceXXS),
                Padding(
                  padding: EdgeInsets.only(left: textMD + spaceXS),
                  child: Row(
                    children: [
                      _ArchiveChip(label: 'ZIP'),
                      SizedBox(width: spaceXXXS),
                      _ArchiveChip(label: 'TAR.GZ'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: _downloadArchive,
            color: colours.secondaryDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM)),
            icon: FaIcon(FontAwesomeIcons.download, size: textMD, color: colours.secondaryLight),
            padding: EdgeInsets.zero,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'zip',
                child: Text(
                  'ZIP',
                  style: TextStyle(color: colours.primaryLight, fontWeight: FontWeight.bold),
                ),
              ),
              PopupMenuItem(
                value: 'tar.gz',
                child: Text(
                  'TAR.GZ',
                  style: TextStyle(color: colours.primaryLight, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArchiveChip extends StatelessWidget {
  final String label;

  const _ArchiveChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: spaceXXS, vertical: spaceXXXXS),
      decoration: BoxDecoration(color: colours.tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusXS)),
      child: Text(
        label,
        style: TextStyle(color: colours.secondaryLight, fontSize: textXXS, fontWeight: FontWeight.bold),
      ),
    );
  }
}

Route createTagsPageRoute({
  required GitProvider gitProvider,
  required String remoteWebUrl,
  required String accessToken,
  required bool githubAppOauth,
}) {
  return PageRouteBuilder(
    settings: const RouteSettings(name: tags_page),
    pageBuilder: (context, animation, secondaryAnimation) =>
        TagsPage(gitProvider: gitProvider, remoteWebUrl: remoteWebUrl, accessToken: accessToken, githubAppOauth: githubAppOauth),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
