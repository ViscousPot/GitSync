import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:GitSync/ui/component/markdown_config.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:GitSync/api/helper.dart';
import 'package:GitSync/api/manager/auth/git_provider_manager.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/constant/strings.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/type/git_provider.dart';
import 'package:GitSync/type/release.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:GitSync/ui/dialog/diff_view.dart' as DiffViewDialog;

class ReleasesPage extends StatefulWidget {
  final GitProvider gitProvider;
  final String remoteWebUrl;
  final String accessToken;
  final bool githubAppOauth;

  const ReleasesPage({super.key, required this.gitProvider, required this.remoteWebUrl, required this.accessToken, required this.githubAppOauth});

  @override
  State<ReleasesPage> createState() => _ReleasesPageState();
}

class _ReleasesPageState extends State<ReleasesPage> {
  final ScrollController _scrollController = ScrollController();
  final List<Release> _releases = [];
  bool _loading = true;
  Function()? _loadNextPage;
  int _fetchGeneration = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchReleases();
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

  void _fetchReleases() {
    final generation = ++_fetchGeneration;
    setState(() {
      _releases.clear();
      _loading = true;
      _loadNextPage = null;
    });

    final (owner, repo) = _parseOwnerRepo();
    final manager = GitProviderManager.getGitProviderManager(widget.gitProvider, widget.githubAppOauth);
    if (manager == null) return;

    manager.getReleases(
      widget.accessToken,
      owner,
      repo,
      (releases) {
        if (!mounted || generation != _fetchGeneration) return;
        setState(() {
          _releases.addAll(releases);
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
                    t.releases.toUpperCase(),
                    style: TextStyle(color: colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: colours.tertiaryDark,
                onRefresh: () async {
                  _fetchReleases();
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: _releases.isEmpty && !_loading
                    ? LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: constraints.maxHeight,
                            child: Center(
                              child: Text(
                                t.releasesNotFound.toUpperCase(),
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
                        itemCount: _releases.length + (_loading || _loadNextPage != null ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _releases.length) {
                            return Padding(
                              padding: EdgeInsets.all(spaceMD),
                              child: Center(
                                child: CircularProgressIndicator(color: colours.secondaryLight, strokeWidth: spaceXXXXS),
                              ),
                            );
                          }
                          return Padding(
                            padding: EdgeInsets.only(bottom: spaceXS),
                            child: _ItemRelease(release: _releases[index], gitProvider: widget.gitProvider, accessToken: widget.accessToken),
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

class _ItemRelease extends StatefulWidget {
  final Release release;
  final GitProvider gitProvider;
  final String accessToken;

  const _ItemRelease({required this.release, required this.gitProvider, required this.accessToken});

  @override
  State<_ItemRelease> createState() => _ItemReleaseState();
}

class _ItemReleaseState extends State<_ItemRelease> with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _chevronController;
  late final Animation<double> _chevronTurns;

  @override
  void initState() {
    super.initState();
    _chevronController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _chevronTurns = Tween<double>(begin: 0.0, end: 0.5).animate(CurvedAnimation(parent: _chevronController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _chevronController.dispose();
    super.dispose();
  }

  Map<String, String> get _authHeaders => switch (widget.gitProvider) {
    GitProvider.GITLAB => {'Authorization': 'Bearer ${widget.accessToken}'},
    _ => {'Authorization': 'token ${widget.accessToken}'},
  };

  Future<void> _downloadAsset(ReleaseAsset asset) async {
    Fluttertoast.showToast(msg: 'Downloading...', toastLength: Toast.LENGTH_SHORT, gravity: null);

    try {
      final response = await http.get(Uri.parse(asset.downloadUrl), headers: _authHeaders).timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        Fluttertoast.showToast(msg: 'Download failed', toastLength: Toast.LENGTH_LONG, gravity: null);
        return;
      }

      final result = await FilePicker.platform.saveFile(dialogTitle: 'Save asset', fileName: asset.name, bytes: response.bodyBytes);
      if (result == null) return;
      Fluttertoast.showToast(msg: 'Saved to ${asset.name}', toastLength: Toast.LENGTH_LONG, gravity: null);
    } catch (_) {
      Fluttertoast.showToast(msg: 'Download failed', toastLength: Toast.LENGTH_LONG, gravity: null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final release = widget.release;
    final title = release.name.isNotEmpty ? release.name : release.tagName;
    final relativeTime = timeago
        .format(release.createdAt, locale: 'en')
        .replaceFirstMapped(RegExp(r'^[A-Z]'), (match) => match.group(0)!.toLowerCase());

    return GestureDetector(
      onTap: () {
        setState(() => _expanded = !_expanded);
        if (_expanded) {
          _chevronController.forward();
        } else {
          _chevronController.reverse();
        }
      },
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.topCenter,
        child: Container(
          padding: EdgeInsets.all(spaceSM),
          decoration: BoxDecoration(color: colours.secondaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: spaceXXXXS),
                    child: FaIcon(FontAwesomeIcons.rocket, size: textMD, color: colours.tertiaryInfo),
                  ),
                  SizedBox(width: spaceXS),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colours.primaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(width: spaceXXS),
                  RotationTransition(
                    turns: _chevronTurns,
                    child: FaIcon(FontAwesomeIcons.chevronDown, size: textXS, color: colours.tertiaryLight),
                  ),
                ],
              ),

              SizedBox(height: spaceXXS),

              // Tag + author + time
              Padding(
                padding: EdgeInsets.only(left: textMD + spaceXS),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: spaceXXS, vertical: spaceXXXXS),
                      decoration: BoxDecoration(color: colours.tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusXS)),
                      child: Text(
                        release.tagName,
                        style: TextStyle(color: colours.secondaryLight, fontSize: textXXS, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (release.authorUsername.isNotEmpty) ...[
                      Text(
                        ' $bullet ',
                        style: TextStyle(color: colours.tertiaryLight, fontSize: textXS),
                      ),
                      Flexible(
                        child: Text(
                          release.authorUsername,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colours.tertiaryLight, fontSize: textXS),
                        ),
                      ),
                    ],
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

              // Badge chips
              if (release.isPrerelease || release.isDraft) ...[
                SizedBox(height: spaceXXS),
                Padding(
                  padding: EdgeInsets.only(left: textMD + spaceXS),
                  child: Row(
                    children: [
                      if (release.isPrerelease)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: spaceXXS, vertical: spaceXXXXS),
                          decoration: BoxDecoration(
                            color: colours.tertiaryWarning.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.all(cornerRadiusXS),
                          ),
                          child: Text(
                            t.preRelease,
                            style: TextStyle(color: colours.tertiaryWarning, fontSize: textXXS, fontWeight: FontWeight.bold),
                          ),
                        ),
                      if (release.isPrerelease && release.isDraft) SizedBox(width: spaceXXXS),
                      if (release.isDraft)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: spaceXXS, vertical: spaceXXXXS),
                          decoration: BoxDecoration(color: colours.tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusXS)),
                          child: Text(
                            t.draft,
                            style: TextStyle(color: colours.secondaryLight, fontSize: textXXS, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
              ],

              // Expanded content
              if (_expanded) ...[
                SizedBox(height: spaceSM),

                // Description (markdown)
                if (release.description.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(left: textMD + spaceXS),
                    child: MarkdownBlock(data: release.description, config: buildMarkdownConfig(), generator: buildMarkdownGenerator()),
                  ),

                // Commit SHA
                if (release.commitSha != null && release.commitSha!.isNotEmpty) ...[
                  SizedBox(height: spaceXS),
                  Padding(
                    padding: EdgeInsets.only(left: textMD + spaceXS),
                    child: GestureDetector(
                      onTap: () {
                        final sha = release.commitSha!;
                        DiffViewDialog.showDialog(context, [], (sha, '${sha}^'), sha.length >= 7 ? sha.substring(0, 7) : sha, null, null);
                      },
                      child: Row(
                        children: [
                          FaIcon(FontAwesomeIcons.codeBranch, size: textXS, color: colours.tertiaryLight),
                          SizedBox(width: spaceXXXS),
                          Text(
                            release.commitSha!.length >= 7 ? release.commitSha!.substring(0, 7) : release.commitSha!,
                            style: TextStyle(color: colours.tertiaryLight, fontSize: textXS, fontFamily: 'RobotoMono'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Assets section
                SizedBox(height: spaceXS),
                Padding(
                  padding: EdgeInsets.only(left: textMD + spaceXS),
                  child: Text(
                    t.releaseAssets.toUpperCase(),
                    style: TextStyle(color: colours.secondaryLight, fontSize: textXXS, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: spaceXXXS),
                if (release.assets.isEmpty)
                  Padding(
                    padding: EdgeInsets.only(left: textMD + spaceXS),
                    child: Text(
                      t.noAssets,
                      style: TextStyle(color: colours.tertiaryLight, fontSize: textXS),
                    ),
                  )
                else
                  ...release.assets.map(
                    (asset) => Padding(
                      padding: EdgeInsets.only(left: textMD + spaceXS, bottom: spaceXXXS),
                      child: GestureDetector(
                        onTap: () => _downloadAsset(asset),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: spaceXS, vertical: spaceXXS),
                          decoration: BoxDecoration(color: colours.tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusXS)),
                          child: Row(
                            children: [
                              FaIcon(FontAwesomeIcons.download, size: textXXS, color: colours.tertiaryInfo),
                              SizedBox(width: spaceXXS),
                              Expanded(
                                child: Text(
                                  asset.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: colours.primaryLight, fontSize: textXS),
                                ),
                              ),
                              if (asset.size != null) ...[
                                SizedBox(width: spaceXXS),
                                Text(
                                  formatBytes(asset.size),
                                  style: TextStyle(color: colours.tertiaryLight, fontSize: textXXS),
                                ),
                              ],
                              if (asset.downloadCount != null) ...[
                                SizedBox(width: spaceXXS),
                                FaIcon(FontAwesomeIcons.arrowDown, size: textXXS, color: colours.tertiaryLight),
                                SizedBox(width: spaceXXXXS),
                                Text(
                                  '${asset.downloadCount}',
                                  style: TextStyle(color: colours.tertiaryLight, fontSize: textXXS),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Route createReleasesPageRoute({
  required GitProvider gitProvider,
  required String remoteWebUrl,
  required String accessToken,
  required bool githubAppOauth,
}) {
  return PageRouteBuilder(
    settings: const RouteSettings(name: releases_page),
    pageBuilder: (context, animation, secondaryAnimation) =>
        ReleasesPage(gitProvider: gitProvider, remoteWebUrl: remoteWebUrl, accessToken: accessToken, githubAppOauth: githubAppOauth),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
