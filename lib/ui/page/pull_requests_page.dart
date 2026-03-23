import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/api/helper.dart';
import 'package:GitSync/api/manager/auth/git_provider_manager.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/constant/strings.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/type/git_provider.dart';
import 'package:GitSync/type/issue.dart';
import 'package:GitSync/type/pull_request.dart';
import 'package:GitSync/ui/page/pr_detail_page.dart';
import 'package:GitSync/ui/page/create_pr_page.dart';
import 'package:timeago/timeago.dart' as timeago;

class PullRequestsPage extends StatefulWidget {
  final GitProvider gitProvider;
  final String remoteWebUrl;
  final String accessToken;
  final bool githubAppOauth;

  const PullRequestsPage({super.key, required this.gitProvider, required this.remoteWebUrl, required this.accessToken, required this.githubAppOauth});

  @override
  State<PullRequestsPage> createState() => _PullRequestsPageState();
}

class _PullRequestsPageState extends State<PullRequestsPage> {
  final ScrollController _scrollController = ScrollController();
  final List<PullRequest> _pullRequests = [];
  bool _loading = true;
  Function()? _loadNextPage;
  String _stateFilter = "open";
  int _fetchGeneration = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchPullRequests();
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

  void _fetchPullRequests() {
    final generation = ++_fetchGeneration;
    setState(() {
      _pullRequests.clear();
      _loading = true;
      _loadNextPage = null;
    });

    final (owner, repo) = _parseOwnerRepo();
    final manager = GitProviderManager.getGitProviderManager(widget.gitProvider, widget.githubAppOauth);
    if (manager == null) return;

    manager.getPullRequests(
      widget.accessToken,
      owner,
      repo,
      _stateFilter,
      null,
      null,
      null,
      (prs) {
        if (!mounted || generation != _fetchGeneration) return;
        setState(() {
          _pullRequests.addAll(prs);
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

  void _onStateFilterChanged(String state) {
    if (_stateFilter == state) return;
    _stateFilter = state;
    _fetchPullRequests();
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
                    t.pullRequests.toUpperCase(),
                    style: TextStyle(color: colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.of(context).push(
                        createCreatePrPageRoute(
                          gitProvider: widget.gitProvider,
                          remoteWebUrl: widget.remoteWebUrl,
                          accessToken: widget.accessToken,
                          githubAppOauth: widget.githubAppOauth,
                        ),
                      );
                      if (result == true && mounted) _fetchPullRequests();
                    },
                    child: Container(
                      padding: EdgeInsets.all(spaceXS),
                      child: FaIcon(FontAwesomeIcons.plus, size: textMD, color: colours.primaryLight),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: spaceMD),
              child: Row(
                children: [
                  _FilterChip(label: t.issueFilterOpen.toUpperCase(), selected: _stateFilter == "open", onTap: () => _onStateFilterChanged("open")),
                  SizedBox(width: spaceXS),
                  _FilterChip(
                    label: t.issueFilterClosed.toUpperCase(),
                    selected: _stateFilter == "closed",
                    onTap: () => _onStateFilterChanged("closed"),
                  ),
                  SizedBox(width: spaceXS),
                  _FilterChip(label: t.issueFilterAll.toUpperCase(), selected: _stateFilter == "all", onTap: () => _onStateFilterChanged("all")),
                ],
              ),
            ),

            SizedBox(height: spaceSM),

            Expanded(
              child: _pullRequests.isEmpty && !_loading
                  ? Center(
                      child: Text(
                        t.pullRequestsNotFound.toUpperCase(),
                        style: TextStyle(color: colours.secondaryLight, fontWeight: FontWeight.bold, fontSize: textLG),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(horizontal: spaceMD),
                      itemCount: _pullRequests.length + (_loading || _loadNextPage != null ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _pullRequests.length) {
                          return Padding(
                            padding: EdgeInsets.all(spaceMD),
                            child: Center(
                              child: CircularProgressIndicator(color: colours.secondaryLight, strokeWidth: spaceXXXXS),
                            ),
                          );
                        }
                        final pr = _pullRequests[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: spaceXS),
                          child: _ItemPullRequest(
                            pr: pr,
                            onTap: () {
                              Navigator.of(context).push(
                                createPrDetailPageRoute(
                                  gitProvider: widget.gitProvider,
                                  remoteWebUrl: widget.remoteWebUrl,
                                  accessToken: widget.accessToken,
                                  githubAppOauth: widget.githubAppOauth,
                                  prNumber: pr.number,
                                  prTitle: pr.title,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceXXS),
          decoration: BoxDecoration(
            color: selected ? colours.showcaseBg : colours.tertiaryDark,
            borderRadius: BorderRadius.all(cornerRadiusSM),
            border: Border.all(color: selected ? colours.showcaseBorder : Colors.transparent, width: spaceXXXXS),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: selected ? colours.showcaseFeatureIcon : colours.secondaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _ItemPullRequest extends StatelessWidget {
  final PullRequest pr;
  final VoidCallback? onTap;

  const _ItemPullRequest({required this.pr, this.onTap});

  @override
  Widget build(BuildContext context) {
    final relativeTime = timeago.format(pr.createdAt, locale: 'en').replaceFirstMapped(RegExp(r'^[A-Z]'), (match) => match.group(0)!.toLowerCase());

    final (IconData icon, Color color) = switch (pr.state) {
      PrState.open => (FontAwesomeIcons.codePullRequest, colours.tertiaryPositive),
      PrState.merged => (FontAwesomeIcons.codeMerge, colours.secondaryInfo),
      PrState.closed => (FontAwesomeIcons.codePullRequest, colours.tertiaryNegative),
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(spaceSM),
        decoration: BoxDecoration(color: colours.secondaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: spaceXXXXS),
                  child: FaIcon(icon, size: textMD, color: color),
                ),
                SizedBox(width: spaceXS),
                Expanded(
                  child: Text(
                    pr.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colours.primaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
                  ),
                ),
                if (pr.checkStatus != CheckStatus.none) ...[
                  SizedBox(width: spaceXS),
                  Padding(
                    padding: EdgeInsets.only(top: spaceXXXXS),
                    child: FaIcon(
                      pr.checkStatus == CheckStatus.success
                          ? FontAwesomeIcons.solidCircleCheck
                          : pr.checkStatus == CheckStatus.failure
                          ? FontAwesomeIcons.solidCircleXmark
                          : FontAwesomeIcons.solidClock,
                      size: textSM,
                      color: pr.checkStatus == CheckStatus.success
                          ? colours.tertiaryPositive
                          : pr.checkStatus == CheckStatus.failure
                          ? colours.tertiaryNegative
                          : colours.tertiaryWarning,
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: spaceXXS),

            Padding(
              padding: EdgeInsets.only(left: textMD + spaceXS),
              child: Row(
                children: [
                  Text(
                    '#${pr.number}',
                    style: TextStyle(color: colours.tertiaryLight, fontSize: textXS),
                  ),
                  Text(
                    ' $bullet ',
                    style: TextStyle(color: colours.tertiaryLight, fontSize: textXS),
                  ),
                  Flexible(
                    child: Text(
                      pr.authorUsername,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colours.secondaryLight, fontSize: textXS),
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
                  if (pr.linkedIssueCount > 0) ...[
                    Text(
                      ' $bullet ',
                      style: TextStyle(color: colours.tertiaryLight, fontSize: textXS),
                    ),
                    FaIcon(FontAwesomeIcons.solidCircleDot, size: textXS, color: colours.tertiaryLight),
                    SizedBox(width: spaceXXXXS),
                    Text(
                      '${pr.linkedIssueCount}',
                      style: TextStyle(color: colours.tertiaryLight, fontSize: textXS),
                    ),
                  ],
                  if (pr.commentCount > 0) ...[
                    Text(
                      ' $bullet ',
                      style: TextStyle(color: colours.tertiaryLight, fontSize: textXS),
                    ),
                    FaIcon(FontAwesomeIcons.solidMessage, size: textXS, color: colours.tertiaryLight),
                    SizedBox(width: spaceXXXXS),
                    Text(
                      '${pr.commentCount}',
                      style: TextStyle(color: colours.tertiaryLight, fontSize: textXS),
                    ),
                  ],
                ],
              ),
            ),

            if (pr.labels.isNotEmpty) ...[
              SizedBox(height: spaceXXS),
              Padding(
                padding: EdgeInsets.only(left: textMD + spaceXS),
                child: Wrap(
                  spacing: spaceXXXS,
                  runSpacing: spaceXXXS,
                  children: pr.labels.map((label) => _LabelChip(label: label)).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LabelChip extends StatelessWidget {
  final IssueLabel label;

  const _LabelChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final bgColor = label.color != null ? _parseHexColor(label.color!) : colours.tertiaryDark;
    final textColor = bgColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: spaceXXS, vertical: spaceXXXXS),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.all(cornerRadiusXS)),
      child: Text(
        label.name,
        style: TextStyle(color: textColor, fontSize: textXXS, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _parseHexColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    }
    return colours.tertiaryDark;
  }
}

Route createPullRequestsPageRoute({
  required GitProvider gitProvider,
  required String remoteWebUrl,
  required String accessToken,
  required bool githubAppOauth,
}) {
  return PageRouteBuilder(
    settings: const RouteSettings(name: pull_requests_page),
    pageBuilder: (context, animation, secondaryAnimation) =>
        PullRequestsPage(gitProvider: gitProvider, remoteWebUrl: remoteWebUrl, accessToken: accessToken, githubAppOauth: githubAppOauth),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
