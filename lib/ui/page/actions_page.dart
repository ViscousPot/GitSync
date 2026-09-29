import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/api/helper.dart';
import 'package:GitSync/api/manager/auth/git_provider_manager.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/constant/strings.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/type/action_run.dart';
import 'package:GitSync/type/git_provider.dart';
import 'package:GitSync/type/showcase_feature.dart';
import 'package:timeago/timeago.dart' as timeago;

class ActionsPage extends StatefulWidget {
  final GitProvider gitProvider;
  final String remoteWebUrl;
  final String accessToken;
  final bool githubAppOauth;

  const ActionsPage({super.key, required this.gitProvider, required this.remoteWebUrl, required this.accessToken, required this.githubAppOauth});

  @override
  State<ActionsPage> createState() => _ActionsPageState();
}

class _ActionsPageState extends State<ActionsPage> {
  final ScrollController _scrollController = ScrollController();
  final List<ActionRun> _runs = [];
  bool _loading = true;
  Function()? _loadNextPage;
  String _stateFilter = "all";
  int _fetchGeneration = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchActionRuns();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  (String, String) _parseOwnerRepo() {
    final segments = Uri.parse(widget.remoteWebUrl).pathSegments;
    return (segments[0], segments[1].replaceAll(RegExp(r'\.git$'), ''));
  }

  void _fetchActionRuns() {
    final generation = ++_fetchGeneration;
    setState(() {
      _runs.clear();
      _loading = true;
      _loadNextPage = null;
    });

    final (owner, repo) = _parseOwnerRepo();
    final manager = GitProviderManager.getGitProviderManager(widget.gitProvider, widget.githubAppOauth);
    if (manager == null) return;

    manager.getActionRuns(
      widget.accessToken,
      owner,
      repo,
      _stateFilter,
      (runs) {
        if (!mounted || generation != _fetchGeneration) return;
        setState(() {
          _runs.addAll(runs);
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
    _fetchActionRuns();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colours.primaryDark,
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
                    ShowcaseFeature.actions.labelForProvider(context, widget.gitProvider).toUpperCase(),
                    style: TextStyle(color: context.colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  getOpenInBrowserButton(widget.gitProvider.actionsUrl(widget.remoteWebUrl)),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: spaceMD),
              child: Row(
                children: [
                  _FilterChip(
                    label: context.t.actionFilterAll.toUpperCase(),
                    selected: _stateFilter == "all",
                    onTap: () => _onStateFilterChanged("all"),
                  ),
                  SizedBox(width: spaceXS),
                  _FilterChip(
                    label: context.t.actionFilterSuccess.toUpperCase(),
                    selected: _stateFilter == "success",
                    onTap: () => _onStateFilterChanged("success"),
                  ),
                  SizedBox(width: spaceXS),
                  _FilterChip(
                    label: context.t.actionFilterFailed.toUpperCase(),
                    selected: _stateFilter == "failed",
                    onTap: () => _onStateFilterChanged("failed"),
                  ),
                ],
              ),
            ),

            SizedBox(height: spaceSM),

            Expanded(
              child: RefreshIndicator(
                color: context.colours.tertiaryDark,
                onRefresh: () async {
                  _fetchActionRuns();
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: _runs.isEmpty && !_loading
                    ? LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: constraints.maxHeight,
                            child: Center(
                              child: Text(
                                context.t.actionsNotFound.toUpperCase(),
                                style: TextStyle(color: context.colours.secondaryLight, fontWeight: FontWeight.bold, fontSize: textLG),
                              ),
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: spaceMD),
                        itemCount: _runs.length + (_loading || _loadNextPage != null ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _runs.length) {
                            return Padding(
                              padding: EdgeInsets.all(spaceMD),
                              child: Center(
                                child: CircularProgressIndicator(color: context.colours.secondaryLight, strokeWidth: spaceXXXXS),
                              ),
                            );
                          }
                          return Padding(
                            padding: EdgeInsets.only(bottom: spaceXS),
                            child: _ItemActionRun(run: _runs[index]),
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
            color: selected ? context.colours.showcaseBg : context.colours.tertiaryDark,
            borderRadius: BorderRadius.all(cornerRadiusSM),
            border: Border.all(color: selected ? context.colours.showcaseBorder : Colors.transparent, width: spaceXXXXS),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? context.colours.showcaseFeatureIcon : context.colours.secondaryLight,
              fontSize: textSM,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

String _formatDuration(Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes % 60;
  final seconds = d.inSeconds % 60;
  if (hours > 0) return '${hours}h ${minutes}m';
  if (minutes > 0) return '${minutes}m ${seconds}s';
  return '${seconds}s';
}

(FaIconData, Color) _statusIconAndColor(BuildContext context, ActionRunStatus status) {
  return switch (status) {
    ActionRunStatus.success => (FontAwesomeIcons.solidCircleCheck, context.colours.tertiaryPositive),
    ActionRunStatus.failure => (FontAwesomeIcons.solidCircleXmark, context.colours.primaryNegative),
    ActionRunStatus.pending => (FontAwesomeIcons.solidClock, context.colours.tertiaryWarning),
    ActionRunStatus.inProgress => (FontAwesomeIcons.solidCirclePlay, context.colours.tertiaryInfo),
    ActionRunStatus.cancelled => (FontAwesomeIcons.solidCircleStop, context.colours.secondaryLight),
    ActionRunStatus.skipped => (FontAwesomeIcons.circleMinus, context.colours.secondaryLight),
  };
}

class _ItemActionRun extends StatelessWidget {
  final ActionRun run;

  const _ItemActionRun({required this.run});

  @override
  Widget build(BuildContext context) {
    final relativeTime = timeago.format(run.createdAt, locale: 'en').replaceFirstMapped(RegExp(r'^[A-Z]'), (match) => match.group(0)!.toLowerCase());
    final (icon, color) = _statusIconAndColor(context, run.status);

    return Container(
      padding: EdgeInsets.all(spaceSM),
      decoration: BoxDecoration(color: context.colours.secondaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Status icon + workflow name
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
                  run.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.colours.primaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          SizedBox(height: spaceXXS),

          // Row 2: #number, author, relative time, duration
          Padding(
            padding: EdgeInsets.only(left: textMD + spaceXS),
            child: Row(
              children: [
                Text(
                  '#${run.number}',
                  style: TextStyle(color: context.colours.tertiaryLight, fontSize: textXS),
                ),
                Text(
                  ' $bullet ',
                  style: TextStyle(color: context.colours.tertiaryLight, fontSize: textXS),
                ),
                Flexible(
                  child: Text(
                    run.authorUsername,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.colours.secondaryLight, fontSize: textXS),
                  ),
                ),
                Text(
                  ' $bullet ',
                  style: TextStyle(color: context.colours.tertiaryLight, fontSize: textXS),
                ),
                Text(
                  relativeTime,
                  style: TextStyle(color: context.colours.tertiaryLight, fontSize: textXS),
                ),
                if (run.duration != null) ...[
                  Text(
                    ' $bullet ',
                    style: TextStyle(color: context.colours.tertiaryLight, fontSize: textXS),
                  ),
                  Text(
                    _formatDuration(run.duration!),
                    style: TextStyle(color: context.colours.tertiaryLight, fontSize: textXS),
                  ),
                ],
              ],
            ),
          ),

          // Row 3: Branch and PR chips
          if (run.branch != null || run.prNumber != null) ...[
            SizedBox(height: spaceXXS),
            Padding(
              padding: EdgeInsets.only(left: textMD + spaceXS),
              child: Wrap(
                spacing: spaceXXXS,
                runSpacing: spaceXXXS,
                children: [
                  if (run.branch != null)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: spaceXXS, vertical: spaceXXXXS),
                      decoration: BoxDecoration(color: context.colours.tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusXS)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FaIcon(FontAwesomeIcons.codeBranch, size: textXXS, color: context.colours.tertiaryLight),
                          SizedBox(width: spaceXXXXS),
                          Text(
                            run.branch!,
                            style: TextStyle(color: context.colours.tertiaryLight, fontSize: textXXS, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  if (run.prNumber != null)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: spaceXXS, vertical: spaceXXXXS),
                      decoration: BoxDecoration(color: context.colours.tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusXS)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FaIcon(FontAwesomeIcons.codePullRequest, size: textXXS, color: context.colours.tertiaryLight),
                          SizedBox(width: spaceXXXXS),
                          Text(
                            '#${run.prNumber}',
                            style: TextStyle(color: context.colours.tertiaryLight, fontSize: textXXS, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Route createActionsPageRoute({
  required GitProvider gitProvider,
  required String remoteWebUrl,
  required String accessToken,
  required bool githubAppOauth,
}) {
  return PageRouteBuilder(
    settings: const RouteSettings(name: actions_page),
    pageBuilder: (context, animation, secondaryAnimation) =>
        ActionsPage(gitProvider: gitProvider, remoteWebUrl: remoteWebUrl, accessToken: accessToken, githubAppOauth: githubAppOauth),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
