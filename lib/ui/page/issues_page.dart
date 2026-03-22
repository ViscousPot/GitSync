import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/api/helper.dart';
import 'package:GitSync/api/manager/auth/git_provider_manager.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/constant/strings.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/type/git_provider.dart';
import 'package:GitSync/type/issue.dart';
import 'package:GitSync/ui/page/issue_detail_page.dart';
import 'package:GitSync/ui/page/create_issue_page.dart';
import 'package:timeago/timeago.dart' as timeago;

class IssuesPage extends StatefulWidget {
  final GitProvider gitProvider;
  final String remoteWebUrl;
  final String accessToken;
  final bool githubAppOauth;

  const IssuesPage({super.key, required this.gitProvider, required this.remoteWebUrl, required this.accessToken, required this.githubAppOauth});

  @override
  State<IssuesPage> createState() => _IssuesPageState();
}

class _IssuesPageState extends State<IssuesPage> {
  final ScrollController _scrollController = ScrollController();
  final List<Issue> _issues = [];
  bool _loading = true;
  Function()? _loadNextPage;
  String _stateFilter = "open";
  bool _showFilters = false;
  int _fetchGeneration = 0;

  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _labelsController = TextEditingController();
  final TextEditingController _assigneeController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchIssues();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _authorController.dispose();
    _labelsController.dispose();
    _assigneeController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  (String, String) _parseOwnerRepo() {
    final segments = Uri.parse(widget.remoteWebUrl).pathSegments;
    return (segments[0], segments[1].replaceAll(".git", ""));
  }

  void _fetchIssues() {
    final generation = ++_fetchGeneration;
    setState(() {
      _issues.clear();
      _loading = true;
      _loadNextPage = null;
    });

    final (owner, repo) = _parseOwnerRepo();
    final manager = GitProviderManager.getGitProviderManager(widget.gitProvider, widget.githubAppOauth);
    if (manager == null) return;

    manager.getIssues(
      widget.accessToken,
      owner,
      repo,
      _stateFilter,
      _authorController.text.isEmpty ? null : _authorController.text,
      _labelsController.text.isEmpty ? null : _labelsController.text,
      _assigneeController.text.isEmpty ? null : _assigneeController.text,
      (issues) {
        if (!mounted || generation != _fetchGeneration) return;
        setState(() {
          _issues.addAll(issues);
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
    _fetchIssues();
  }

  void _onFilterChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _fetchIssues();
    });
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
                    t.issues.toUpperCase(),
                    style: TextStyle(color: colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.of(context).push(
                        createCreateIssuePageRoute(
                          gitProvider: widget.gitProvider,
                          remoteWebUrl: widget.remoteWebUrl,
                          accessToken: widget.accessToken,
                          githubAppOauth: widget.githubAppOauth,
                        ),
                      );
                      if (result == true && mounted) _fetchIssues();
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


            if (_showFilters)
              Padding(
                padding: EdgeInsets.fromLTRB(spaceMD, spaceSM, spaceMD, 0),
                child: Column(
                  children: [
                    _buildFilterField(_authorController, t.filterAuthor.toUpperCase()),
                    SizedBox(height: spaceXS),
                    _buildFilterField(_labelsController, t.filterLabels.toUpperCase()),
                    SizedBox(height: spaceXS),
                    _buildFilterField(_assigneeController, t.filterAssignee.toUpperCase()),
                  ],
                ),
              ),

            SizedBox(height: spaceSM),


            Expanded(
              child: _issues.isEmpty && !_loading
                  ? Center(
                      child: Text(
                        t.issuesNotFound.toUpperCase(),
                        style: TextStyle(color: colours.secondaryLight, fontWeight: FontWeight.bold, fontSize: textLG),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(horizontal: spaceMD),
                      itemCount: _issues.length + (_loading || _loadNextPage != null ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _issues.length) {
                          return Padding(
                            padding: EdgeInsets.all(spaceMD),
                            child: Center(
                              child: CircularProgressIndicator(color: colours.secondaryLight, strokeWidth: spaceXXXXS),
                            ),
                          );
                        }
                        return Padding(
                          padding: EdgeInsets.only(bottom: spaceXS),
                          child: _ItemIssue(
                            issue: _issues[index],
                            onTap: () async {
                              final result = await Navigator.of(context).push(
                                createIssueDetailPageRoute(
                                  gitProvider: widget.gitProvider,
                                  remoteWebUrl: widget.remoteWebUrl,
                                  accessToken: widget.accessToken,
                                  githubAppOauth: widget.githubAppOauth,
                                  issueNumber: _issues[index].number,
                                  issueTitle: _issues[index].title,
                                ),
                              );
                              // If the issue state was changed, update the list item
                              if (result is bool && mounted) {
                                setState(() {
                                  final old = _issues[index];
                                  _issues[index] = Issue(
                                    title: old.title,
                                    number: old.number,
                                    isOpen: result,
                                    authorUsername: old.authorUsername,
                                    createdAt: old.createdAt,
                                    commentCount: old.commentCount,
                                    linkedPrCount: old.linkedPrCount,
                                    labels: old.labels,
                                  );
                                });
                              }
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

  Widget _buildFilterField(TextEditingController controller, String label) {
    return TextField(
      contextMenuBuilder: globalContextMenuBuilder,
      controller: controller,
      maxLines: 1,
      style: TextStyle(
        color: colours.primaryLight,
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.none,
        decorationThickness: 0,
        fontSize: textMD,
      ),
      decoration: InputDecoration(
        fillColor: colours.tertiaryDark,
        filled: true,
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(cornerRadiusSM), borderSide: BorderSide.none),
        isCollapsed: true,
        label: Text(
          label,
          style: TextStyle(color: colours.secondaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM),
        isDense: true,
      ),
      onChanged: (_) => _onFilterChanged(),
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

class _ItemIssue extends StatelessWidget {
  final Issue issue;
  final VoidCallback? onTap;

  const _ItemIssue({required this.issue, this.onTap});

  @override
  Widget build(BuildContext context) {
    final relativeTime = timeago
        .format(issue.createdAt, locale: 'en')
        .replaceFirstMapped(RegExp(r'^[A-Z]'), (match) => match.group(0)!.toLowerCase());

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
                  child: FaIcon(
                    issue.isOpen ? FontAwesomeIcons.solidCircleDot : FontAwesomeIcons.solidCircleCheck,
                    size: textMD,
                    color: issue.isOpen ? colours.tertiaryPositive : colours.primaryNegative,
                  ),
                ),
                SizedBox(width: spaceXS),
                Expanded(
                  child: Text(
                    issue.title,
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
                  Text(
                    '#${issue.number}',
                    style: TextStyle(color: colours.tertiaryLight, fontSize: textXS),
                  ),
                  Text(
                    ' $bullet ',
                    style: TextStyle(color: colours.tertiaryLight, fontSize: textXS),
                  ),
                  Flexible(
                    child: Text(
                      issue.authorUsername,
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
                  if (issue.linkedPrCount > 0) ...[
                    Text(
                      ' $bullet ',
                      style: TextStyle(color: colours.tertiaryLight, fontSize: textXS),
                    ),
                    FaIcon(FontAwesomeIcons.codePullRequest, size: textXS, color: colours.tertiaryLight),
                    SizedBox(width: spaceXXXXS),
                    Text(
                      '${issue.linkedPrCount}',
                      style: TextStyle(color: colours.tertiaryLight, fontSize: textXS),
                    ),
                  ],
                  if (issue.commentCount > 0) ...[
                    Text(
                      ' $bullet ',
                      style: TextStyle(color: colours.tertiaryLight, fontSize: textXS),
                    ),
                    FaIcon(FontAwesomeIcons.solidMessage, size: textXS, color: colours.tertiaryLight),
                    SizedBox(width: spaceXXXXS),
                    Text(
                      '${issue.commentCount}',
                      style: TextStyle(color: colours.tertiaryLight, fontSize: textXS),
                    ),
                  ],
                ],
              ),
            ),

            if (issue.labels.isNotEmpty) ...[
              SizedBox(height: spaceXXS),
              Padding(
                padding: EdgeInsets.only(left: textMD + spaceXS),
                child: Wrap(
                  spacing: spaceXXXS,
                  runSpacing: spaceXXXS,
                  children: issue.labels.map((label) => _LabelChip(label: label)).toList(),
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

Route createIssuesPageRoute({
  required GitProvider gitProvider,
  required String remoteWebUrl,
  required String accessToken,
  required bool githubAppOauth,
}) {
  return PageRouteBuilder(
    settings: const RouteSettings(name: issues_page),
    pageBuilder: (context, animation, secondaryAnimation) =>
        IssuesPage(gitProvider: gitProvider, remoteWebUrl: remoteWebUrl, accessToken: accessToken, githubAppOauth: githubAppOauth),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
