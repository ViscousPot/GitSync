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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  final List<Issue> _issues = [];
  bool _loading = true;
  Function()? _loadNextPage;
  String _stateFilter = "open";
  int _fetchGeneration = 0;
  IssueSortOption _sortOption = IssueSortOption.newest;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _labelsController = TextEditingController();
  final TextEditingController _assigneeController = TextEditingController();
  final FocusNode _authorFocusNode = FocusNode();
  final FocusNode _labelsFocusNode = FocusNode();
  final FocusNode _assigneeFocusNode = FocusNode();
  Timer? _debounceTimer;

  String? _milestoneFilter;
  String? _projectFilter;
  List<Milestone>? _milestones;
  List<GitProject>? _projects;
  List<String>? _repoLabels;
  List<String>? _repoCollaborators;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchIssues();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _authorController.dispose();
    _labelsController.dispose();
    _assigneeController.dispose();
    _authorFocusNode.dispose();
    _labelsFocusNode.dispose();
    _assigneeFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  (String, String) _parseOwnerRepo() {
    final segments = Uri.parse(widget.remoteWebUrl).pathSegments;
    return (segments[0], segments[1].replaceAll(".git", ""));
  }

  bool get _hasActiveFilters =>
      _authorController.text.isNotEmpty ||
      _labelsController.text.isNotEmpty ||
      _assigneeController.text.isNotEmpty ||
      _milestoneFilter != null ||
      _projectFilter != null;

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
      _searchController.text.isEmpty ? null : _searchController.text,
      _sortOption.name,
      _milestoneFilter,
      _projectFilter,
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

  Future<void> _ensureLabels() async {
    if (_repoLabels != null) return;
    final (owner, repo) = _parseOwnerRepo();
    final manager = GitProviderManager.getGitProviderManager(widget.gitProvider, widget.githubAppOauth);
    if (manager == null) return;
    final labels = await manager.getLabels(widget.accessToken, owner, repo);
    if (mounted) setState(() => _repoLabels = labels);
  }

  Future<void> _ensureCollaborators() async {
    if (_repoCollaborators != null) return;
    final (owner, repo) = _parseOwnerRepo();
    final manager = GitProviderManager.getGitProviderManager(widget.gitProvider, widget.githubAppOauth);
    if (manager == null) return;
    final collaborators = await manager.getCollaborators(widget.accessToken, owner, repo);
    if (mounted) setState(() => _repoCollaborators = collaborators);
  }

  Future<void> _ensureMilestones() async {
    if (_milestones != null) return;
    final (owner, repo) = _parseOwnerRepo();
    final manager = GitProviderManager.getGitProviderManager(widget.gitProvider, widget.githubAppOauth);
    if (manager == null) return;
    final milestones = await manager.getMilestones(widget.accessToken, owner, repo);
    if (mounted) setState(() => _milestones = milestones);
  }

  Future<void> _ensureProjects() async {
    if (_projects != null) return;
    final (owner, repo) = _parseOwnerRepo();
    final manager = GitProviderManager.getGitProviderManager(widget.gitProvider, widget.githubAppOauth);
    if (manager == null) return;
    final projects = await manager.getProjects(widget.accessToken, owner, repo);
    if (mounted) setState(() => _projects = projects);
  }

  void _showSortMenu() {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset(button.size.width, 0), ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<IssueSortOption>(
      context: context,
      position: position,
      color: colours.secondaryDark,
      items: [
        PopupMenuItem(
          value: IssueSortOption.newest,
          child: Text(
            t.sortNewest,
            style: TextStyle(color: _sortOption == IssueSortOption.newest ? colours.showcaseFeatureIcon : colours.primaryLight),
          ),
        ),
        PopupMenuItem(
          value: IssueSortOption.oldest,
          child: Text(
            t.sortOldest,
            style: TextStyle(color: _sortOption == IssueSortOption.oldest ? colours.showcaseFeatureIcon : colours.primaryLight),
          ),
        ),
        PopupMenuItem(
          value: IssueSortOption.mostCommented,
          child: Text(
            t.sortMostCommented,
            style: TextStyle(color: _sortOption == IssueSortOption.mostCommented ? colours.showcaseFeatureIcon : colours.primaryLight),
          ),
        ),
        PopupMenuItem(
          value: IssueSortOption.recentlyUpdated,
          child: Text(
            t.sortRecentlyUpdated,
            style: TextStyle(color: _sortOption == IssueSortOption.recentlyUpdated ? colours.showcaseFeatureIcon : colours.primaryLight),
          ),
        ),
      ],
    ).then((value) {
      if (value != null && value != _sortOption) {
        setState(() => _sortOption = value);
        _fetchIssues();
      }
    });
  }

  void _showMilestoneSheet() async {
    await _ensureMilestones();
    if (!mounted) return;

    final milestones = _milestones ?? [];
    showModalBottomSheet(
      context: context,
      backgroundColor: colours.secondaryDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: cornerRadiusMD)),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(spaceMD),
                child: Text(
                  t.filterMilestone.toUpperCase(),
                  style: TextStyle(color: colours.primaryLight, fontWeight: FontWeight.bold, fontSize: textMD),
                ),
              ),
              if (milestones.isEmpty)
                Padding(
                  padding: EdgeInsets.all(spaceMD),
                  child: Text(
                    t.filterMilestonesEmpty,
                    style: TextStyle(color: colours.secondaryLight, fontSize: textSM),
                  ),
                )
              else ...[
                _buildSheetOption(t.filterNone, _milestoneFilter == null, () {
                  setState(() => _milestoneFilter = null);
                  Navigator.pop(context);
                }),
                ...milestones.map(
                  (m) => _buildSheetOption(m.title, _milestoneFilter == m.title, () {
                    setState(() => _milestoneFilter = m.title);
                    Navigator.pop(context);
                  }),
                ),
              ],
              SizedBox(height: spaceSM),
            ],
          ),
        );
      },
    );
  }

  void _showProjectSheet() async {
    await _ensureProjects();
    if (!mounted) return;

    final projects = _projects ?? [];
    showModalBottomSheet(
      context: context,
      backgroundColor: colours.secondaryDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: cornerRadiusMD)),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(spaceMD),
                child: Text(
                  t.filterProject.toUpperCase(),
                  style: TextStyle(color: colours.primaryLight, fontWeight: FontWeight.bold, fontSize: textMD),
                ),
              ),
              if (projects.isEmpty)
                Padding(
                  padding: EdgeInsets.all(spaceMD),
                  child: Text(
                    t.filterProjectsEmpty,
                    style: TextStyle(color: colours.secondaryLight, fontSize: textSM),
                  ),
                )
              else ...[
                _buildSheetOption(t.filterNone, _projectFilter == null, () {
                  setState(() => _projectFilter = null);
                  Navigator.pop(context);
                }),
                ...projects.map(
                  (p) => _buildSheetOption(p.title, _projectFilter == p.title, () {
                    setState(() => _projectFilter = p.title);
                    Navigator.pop(context);
                  }),
                ),
              ],
              SizedBox(height: spaceSM),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSheetOption(String title, bool selected, VoidCallback onTap) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(color: selected ? colours.showcaseFeatureIcon : colours.primaryLight, fontSize: textSM),
      ),
      trailing: selected ? FaIcon(FontAwesomeIcons.check, size: textSM, color: colours.showcaseFeatureIcon) : null,
      onTap: onTap,
    );
  }

  Widget _buildAutocompleteField(
    TextEditingController controller,
    FocusNode focusNode,
    String label,
    Future<void> Function() ensureData,
    List<String>? options,
  ) {
    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: (textEditingValue) async {
        await ensureData();
        final text = textEditingValue.text.toLowerCase();
        if (text.isEmpty || options == null) return options ?? [];
        return options.where((o) => o.toLowerCase().contains(text)).toList();
      },
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        return TextField(
          contextMenuBuilder: globalContextMenuBuilder,
          controller: textEditingController,
          focusNode: focusNode,
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
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            color: colours.tertiaryDark,
            borderRadius: BorderRadius.all(cornerRadiusSM),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 200, maxWidth: 300),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(
                      option,
                      style: TextStyle(color: colours.primaryLight, fontSize: textSM),
                    ),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectorField(String label, String? value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM),
        decoration: BoxDecoration(color: colours.tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: colours.secondaryLight, fontSize: textXS, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: spaceXXXS),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? t.filterNone,
                    style: TextStyle(
                      color: value != null ? colours.primaryLight : colours.tertiaryLight,
                      fontWeight: FontWeight.bold,
                      fontSize: textMD,
                    ),
                  ),
                ),
                FaIcon(FontAwesomeIcons.chevronDown, size: textXS, color: colours.secondaryLight),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDrawer() {
    return Drawer(
      backgroundColor: colours.primaryDark,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(spaceMD),
              child: Row(
                children: [
                  Text(
                    t.filterSidebar.toUpperCase(),
                    style: TextStyle(color: colours.primaryLight, fontSize: textLG, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: FaIcon(FontAwesomeIcons.xmark, size: textMD, color: colours.primaryLight),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: spaceMD),
                children: [
                  _buildAutocompleteField(
                    _authorController,
                    _authorFocusNode,
                    t.filterAuthor.toUpperCase(),
                    _ensureCollaborators,
                    _repoCollaborators,
                  ),
                  SizedBox(height: spaceSM),
                  _buildAutocompleteField(_labelsController, _labelsFocusNode, t.filterLabels.toUpperCase(), _ensureLabels, _repoLabels),
                  SizedBox(height: spaceSM),
                  _buildAutocompleteField(
                    _assigneeController,
                    _assigneeFocusNode,
                    t.filterAssignee.toUpperCase(),
                    _ensureCollaborators,
                    _repoCollaborators,
                  ),
                  SizedBox(height: spaceSM),
                  _buildSelectorField(t.filterMilestone.toUpperCase(), _milestoneFilter, _showMilestoneSheet),
                  SizedBox(height: spaceSM),
                  _buildSelectorField(t.filterProject.toUpperCase(), _projectFilter, _showProjectSheet),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: colours.primaryDark,
      endDrawer: _buildFilterDrawer(),
      onEndDrawerChanged: (isOpened) {
        if (!isOpened) _fetchIssues();
      },
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(left: spaceXS, right: spaceXS, top: spaceXS),
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
                    onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                    child: Container(
                      padding: EdgeInsets.all(spaceXS),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          FaIcon(FontAwesomeIcons.filter, size: textMD, color: colours.primaryLight),
                          if (_hasActiveFilters)
                            Positioned(
                              right: -spaceXXXS,
                              top: -spaceXXXS,
                              child: Container(
                                width: spaceXS,
                                height: spaceXS,
                                decoration: BoxDecoration(color: colours.showcaseFeatureIcon, shape: BoxShape.circle),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
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
              padding: EdgeInsets.only(left: spaceMD, right: spaceMD, bottom: spaceXS),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      contextMenuBuilder: globalContextMenuBuilder,
                      controller: _searchController,
                      maxLines: 1,
                      style: TextStyle(color: colours.primaryLight, decoration: TextDecoration.none, decorationThickness: 0, fontSize: textSM),
                      decoration: InputDecoration(
                        fillColor: colours.secondaryDark,
                        filled: true,
                        border: const OutlineInputBorder(borderRadius: BorderRadius.all(cornerRadiusSM), borderSide: BorderSide.none),
                        isCollapsed: true,
                        hintText: t.searchEllipsis,
                        hintStyle: TextStyle(color: colours.tertiaryLight, fontSize: textSM),
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(left: spaceSM, right: spaceXS),
                          child: FaIcon(FontAwesomeIcons.magnifyingGlass, size: textXS, color: colours.tertiaryLight),
                        ),
                        prefixIconConstraints: BoxConstraints(minHeight: 0, minWidth: 0),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  _onFilterChanged();
                                },
                                child: Padding(
                                  padding: EdgeInsets.only(right: spaceSM),
                                  child: FaIcon(FontAwesomeIcons.xmark, size: textXS, color: colours.tertiaryLight),
                                ),
                              )
                            : null,
                        suffixIconConstraints: BoxConstraints(minHeight: 0, minWidth: 0),
                        contentPadding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceXS),
                        isDense: true,
                      ),
                      onChanged: (_) => _onFilterChanged(),
                    ),
                  ),
                  SizedBox(width: spaceXS),
                  GestureDetector(
                    onTap: _showSortMenu,
                    child: Container(
                      padding: EdgeInsets.all(spaceXS),
                      child: FaIcon(
                        FontAwesomeIcons.arrowDownWideShort,
                        size: textMD,
                        color: _sortOption != IssueSortOption.newest ? colours.showcaseFeatureIcon : colours.primaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: spaceXS),

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
              child: RefreshIndicator(
                color: colours.tertiaryDark,
                onRefresh: () async {
                  _fetchIssues();
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: _issues.isEmpty && !_loading
                    ? LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: constraints.maxHeight,
                            child: Center(
                              child: Text(
                                t.issuesNotFound.toUpperCase(),
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
