import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:GitSync/ui/component/markdown_config.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/api/helper.dart';
import 'package:GitSync/api/manager/auth/git_provider_manager.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/constant/reactions.dart';
import 'package:GitSync/constant/strings.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/ui/component/ai_wand_field.dart';
import 'package:GitSync/api/ai_completion_service.dart';
import 'package:GitSync/type/git_provider.dart';
import 'package:GitSync/type/issue_detail.dart';
import 'package:GitSync/type/pr_detail.dart';
import 'package:GitSync/type/pull_request.dart';
import 'package:GitSync/ui/component/post_footer_indicator.dart';
import 'package:GitSync/ui/page/code_editor.dart';
import 'package:timeago/timeago.dart' as timeago;

class PrDetailPage extends StatefulWidget {
  final GitProvider gitProvider;
  final String remoteWebUrl;
  final String accessToken;
  final bool githubAppOauth;
  final int prNumber;
  final String prTitle;

  const PrDetailPage({
    super.key,
    required this.gitProvider,
    required this.remoteWebUrl,
    required this.accessToken,
    required this.githubAppOauth,
    required this.prNumber,
    required this.prTitle,
  });

  @override
  State<PrDetailPage> createState() => _PrDetailPageState();
}

class _PrDetailPageState extends State<PrDetailPage> with SingleTickerProviderStateMixin {
  PrDetail? _detail;
  bool _loading = true;
  bool _submittingComment = false;
  bool _writeMode = true;
  late TabController _tabController;
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Set<int> _expandedFiles = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchDetail();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  (String, String) _parseOwnerRepo() {
    final segments = Uri.parse(widget.remoteWebUrl).pathSegments;
    return (segments[0], segments[1].replaceAll(".git", ""));
  }

  GitProviderManager? get _manager => GitProviderManager.getGitProviderManager(widget.gitProvider, widget.githubAppOauth);

  Future<void> _fetchDetail() async {
    final (owner, repo) = _parseOwnerRepo();
    final manager = _manager;
    if (manager == null) return;

    final detail = await manager.getPrDetail(widget.accessToken, owner, repo, widget.prNumber);
    if (!mounted) return;
    setState(() {
      _detail = detail;
      _loading = false;
    });
  }

  Future<void> _submitComment() async {
    final body = _commentController.text.trim();
    if (body.isEmpty) return;

    setState(() => _submittingComment = true);
    final (owner, repo) = _parseOwnerRepo();
    final manager = _manager;
    if (manager == null) return;

    final bodyWithFooter = await uiSettingsManager.applyPostFooter(body);
    final comment = await manager.addIssueComment(widget.accessToken, owner, repo, widget.prNumber, bodyWithFooter);
    if (!mounted) return;

    if (comment != null) {
      setState(() {
        final newItem = PrTimelineItem(type: PrTimelineItemType.comment, comment: comment, createdAt: comment.createdAt);
        _detail = _detail?.copyWith(timelineItems: [..._detail!.timelineItems, newItem]);
        _commentController.clear();
        _submittingComment = false;
        _writeMode = true;
      });
      Fluttertoast.showToast(msg: t.prCommentAdded, toastLength: Toast.LENGTH_SHORT, gravity: null);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: animMedium, curve: Curves.easeOut);
        }
      });
    } else {
      setState(() => _submittingComment = false);
      Fluttertoast.showToast(msg: t.prCommentFailed, toastLength: Toast.LENGTH_LONG, gravity: null);
    }
  }

  Future<void> _toggleReaction(String targetId, String reaction, bool isComment, bool hasReacted) async {
    final (owner, repo) = _parseOwnerRepo();
    final manager = _manager;
    if (manager == null) return;

    bool success;
    if (hasReacted) {
      success = await manager.removeReaction(widget.accessToken, owner, repo, widget.prNumber, targetId, reaction, isComment);
    } else {
      success = await manager.addReaction(widget.accessToken, owner, repo, widget.prNumber, targetId, reaction, isComment);
    }

    if (!mounted) return;
    if (success) {
      await _fetchDetail();
    } else {
      Fluttertoast.showToast(msg: t.prReactionFailed, toastLength: Toast.LENGTH_SHORT, gravity: null);
    }
  }

  void _showAddReactionSheet(String targetId, bool isComment) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colours.secondaryDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: EdgeInsets.all(spaceMD),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.issueAddReaction.toUpperCase(),
              style: TextStyle(color: colours.secondaryLight, fontSize: textXS, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: spaceSM),
            Wrap(
              spacing: spaceSM,
              runSpacing: spaceSM,
              children: standardReactions.entries.map((entry) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _toggleReaction(targetId, entry.key, isComment, false);
                  },
                  child: Container(
                    padding: EdgeInsets.all(spaceXS),
                    decoration: BoxDecoration(color: colours.tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
                    child: Text(entry.value, style: TextStyle(fontSize: textXL)),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: spaceSM),
          ],
        ),
      ),
    );
  }

  MarkdownConfig get _markdownConfig => buildMarkdownConfig();
  MarkdownGenerator get _markdownGenerator => buildMarkdownGenerator();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colours.primaryDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_loading)
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: colours.secondaryLight, strokeWidth: spaceXXXXS),
                ),
              )
            else if (_detail == null)
              Expanded(
                child: Center(
                  child: Text(
                    t.prNotFound.toUpperCase(),
                    style: TextStyle(color: colours.secondaryLight, fontWeight: FontWeight.bold, fontSize: textLG),
                  ),
                ),
              )
            else ...[
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildConversationTab(), _buildCommitsTab(), _buildChecksTab(), _buildFilesTab()],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final (FaIconData icon, Color color) = _detail != null
        ? switch (_detail!.state) {
            PrState.open => (FontAwesomeIcons.codePullRequest, colours.tertiaryPositive),
            PrState.merged => (FontAwesomeIcons.codeMerge, colours.secondaryInfo),
            PrState.closed => (FontAwesomeIcons.codePullRequest, colours.tertiaryNegative),
          }
        : (FontAwesomeIcons.codePullRequest, colours.secondaryLight);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spaceXS, vertical: spaceXS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              getBackButton(context, () => Navigator.of(context).pop()),
              SizedBox(width: spaceXS),
              if (_detail != null) ...[
                Padding(
                  padding: EdgeInsets.only(top: spaceXXXS),
                  child: FaIcon(icon, size: textMD, color: color),
                ),
                SizedBox(width: spaceXS),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        _detail?.title ?? widget.prTitle,
                        style: TextStyle(color: colours.primaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (_detail != null) ...[
                      SizedBox(height: spaceXXXXS),
                      Row(
                        children: [
                          Text(
                            '#${_detail!.number}',
                            style: TextStyle(color: colours.tertiaryLight, fontSize: textXS),
                          ),
                          Text(
                            ' $bullet ',
                            style: TextStyle(color: colours.tertiaryLight, fontSize: textXS),
                          ),
                          Flexible(
                            child: Text(
                              _detail!.authorUsername,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: colours.secondaryLight, fontSize: textXS),
                            ),
                          ),
                          Text(
                            ' $bullet ',
                            style: TextStyle(color: colours.tertiaryLight, fontSize: textXS),
                          ),
                          Text(
                            timeago.format(_detail!.createdAt, locale: 'en').replaceFirstMapped(RegExp(r'^[A-Z]'), (m) => m.group(0)!.toLowerCase()),
                            style: TextStyle(color: colours.tertiaryLight, fontSize: textXS),
                          ),
                        ],
                      ),
                      SizedBox(height: spaceXXXS),
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: spaceXXS, vertical: spaceXXXXS),
                              decoration: BoxDecoration(color: colours.tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusXS)),
                              child: Text(
                                '${_parseOwnerRepo().$1}:${_detail!.baseBranch}',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: colours.tertiaryInfo, fontSize: textXXS, fontFamily: 'RobotoMono'),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: spaceXXXS),
                            child: FaIcon(FontAwesomeIcons.arrowLeft, size: textXXS, color: colours.tertiaryLight),
                          ),
                          Flexible(
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: spaceXXS, vertical: spaceXXXXS),
                              decoration: BoxDecoration(color: colours.tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusXS)),
                              child: Text(
                                '${_detail!.headRepoOwner}:${_detail!.headBranch}',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: colours.tertiaryInfo, fontSize: textXXS, fontFamily: 'RobotoMono'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final detail = _detail!;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colours.tertiaryDark, width: spaceXXXXS),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: colours.primaryLight,
        unselectedLabelColor: colours.secondaryLight,
        indicatorColor: colours.tertiaryInfo,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: TextStyle(fontSize: textXS, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontSize: textXS, fontWeight: FontWeight.bold),
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(FontAwesomeIcons.solidComments, size: textXS),
                SizedBox(width: spaceXXS),
                Text(t.prConversation.toUpperCase()),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(FontAwesomeIcons.codeBranch, size: textXS),
                SizedBox(width: spaceXXS),
                Text('${t.prCommits.toUpperCase()} (${detail.commits.length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(
                  detail.overallCheckStatus == CheckStatus.success ? FontAwesomeIcons.clipboardCheck : FontAwesomeIcons.clipboardQuestion,
                  size: textXS,
                ),
                SizedBox(width: spaceXXS),
                Text('${t.prChecks.toUpperCase()} (${detail.checkRuns.length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(FontAwesomeIcons.solidFileLines, size: textXS),
                SizedBox(width: spaceXXS),
                Text('${t.prFilesChanged.toUpperCase()} (${detail.changedFileCount})'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── CONVERSATION TAB ────────────────────────────────────────────

  Widget _buildConversationTab() {
    final detail = _detail!;
    final comments = detail.timelineItems.where((i) => i.type == PrTimelineItemType.comment).length;

    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: spaceMD),
      children: [
        SizedBox(height: spaceXS),

        // Labels
        if (detail.labels.isNotEmpty) ...[
          Wrap(
            spacing: spaceXXXS,
            runSpacing: spaceXXXS,
            children: detail.labels.map((label) {
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
            }).toList(),
          ),
          SizedBox(height: spaceSM),
        ],

        // Description
        Text(
          t.prDescription.toUpperCase(),
          style: TextStyle(color: colours.secondaryLight, fontSize: textXXS, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: spaceXXS),
        if (detail.body.isEmpty)
          Text(
            t.prNoDescription,
            style: TextStyle(color: colours.tertiaryLight, fontSize: textSM, fontStyle: FontStyle.italic),
          )
        else
          MarkdownBlock(data: detail.body, config: _markdownConfig, generator: _markdownGenerator),

        // PR body reactions
        if (detail.reactions.isNotEmpty) ...[SizedBox(height: spaceSM), _buildReactions(detail.reactions, detail.id, false)],
        if (detail.canComment) ...[SizedBox(height: spaceXXS), _buildAddReactionButton(detail.id, false)],

        SizedBox(height: spaceLG),

        // Activity
        Text(
          '${t.prActivity.toUpperCase()} ($comments)',
          style: TextStyle(color: colours.secondaryLight, fontSize: textXXS, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: spaceXS),

        if (detail.timelineItems.isEmpty)
          Text(
            t.prNoActivity,
            style: TextStyle(color: colours.tertiaryLight, fontSize: textSM, fontStyle: FontStyle.italic),
          )
        else
          ...detail.timelineItems.map((item) {
            if (item.type == PrTimelineItemType.comment && item.comment != null) {
              return _buildCommentCard(item.comment!);
            } else if (item.type == PrTimelineItemType.commit && item.commit != null) {
              return _buildTimelineCommit(item.commit!);
            } else if (item.type == PrTimelineItemType.crossReference && item.crossReference != null) {
              return _buildTimelineCrossReference(item.crossReference!);
            } else if (item.type == PrTimelineItemType.forcePush && item.forcePush != null) {
              return _buildTimelineForcePush(item.forcePush!);
            }
            return const SizedBox.shrink();
          }),

        // Checks summary stamp
        if (detail.checkRuns.isNotEmpty) ...[SizedBox(height: spaceSM), _buildChecksSummaryStamp()],

        // Reviews summary
        if (detail.reviews.isNotEmpty) ...[SizedBox(height: spaceSM), _buildReviewsSummary()],

        SizedBox(height: spaceMD),

        // Comment input
        if (detail.canComment) ...[_buildCommentInput(), SizedBox(height: spaceSM)],

        if (!detail.canComment) ...[
          Container(
            padding: EdgeInsets.all(spaceSM),
            decoration: BoxDecoration(color: colours.tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(FontAwesomeIcons.lock, size: textXS, color: colours.tertiaryLight),
                SizedBox(width: spaceXS),
                Text(
                  t.issueWriteDisabled,
                  style: TextStyle(color: colours.tertiaryLight, fontSize: textSM),
                ),
              ],
            ),
          ),
        ],

        SizedBox(height: spaceLG),
      ],
    );
  }

  Widget _buildTimelineCommit(PrCommit commit) {
    final relativeTime = timeago.format(commit.createdAt, locale: 'en').replaceFirstMapped(RegExp(r'^[A-Z]'), (m) => m.group(0)!.toLowerCase());
    return Padding(
      padding: EdgeInsets.only(bottom: spaceXS),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceXS),
        decoration: BoxDecoration(color: colours.tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
        child: Row(
          children: [
            FaIcon(FontAwesomeIcons.codeBranch, size: textXS, color: colours.tertiaryLight),
            SizedBox(width: spaceXS),
            Text(
              commit.shortSha,
              style: TextStyle(color: colours.tertiaryInfo, fontSize: textXS, fontFamily: 'RobotoMono'),
            ),
            SizedBox(width: spaceXS),
            Expanded(
              child: Text(
                commit.message.split('\n').first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colours.primaryLight, fontSize: textXS),
              ),
            ),
            SizedBox(width: spaceXS),
            Text(
              relativeTime,
              style: TextStyle(color: colours.tertiaryLight, fontSize: textXXS),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCrossReference(PrCrossReference ref) {
    final relativeTime = timeago.format(ref.createdAt, locale: 'en').replaceFirstMapped(RegExp(r'^[A-Z]'), (m) => m.group(0)!.toLowerCase());
    final isPr = ref.sourceType == "PullRequest";
    final icon = isPr ? FontAwesomeIcons.codePullRequest : FontAwesomeIcons.solidCircleDot;
    final mentionText = isPr ? t.prMentionedInPr : t.prMentionedInIssue;
    final refLabel = ref.isCrossRepository && ref.sourceRepoName != null ? '${ref.sourceRepoName}#${ref.sourceNumber}' : '#${ref.sourceNumber}';

    return Padding(
      padding: EdgeInsets.only(bottom: spaceXS),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceXS),
        decoration: BoxDecoration(color: colours.tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
        child: Row(
          children: [
            FaIcon(icon, size: textXS, color: colours.tertiaryLight),
            SizedBox(width: spaceXS),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: ref.actorUsername,
                      style: TextStyle(color: colours.primaryLight, fontSize: textXS, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: ' $mentionText ',
                      style: TextStyle(color: colours.tertiaryLight, fontSize: textXS),
                    ),
                    TextSpan(
                      text: refLabel,
                      style: TextStyle(color: colours.tertiaryInfo, fontSize: textXS, fontWeight: FontWeight.bold),
                    ),
                    if (ref.sourceTitle.isNotEmpty)
                      TextSpan(
                        text: ' ${ref.sourceTitle}',
                        style: TextStyle(color: colours.primaryLight, fontSize: textXS),
                      ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: spaceXS),
            Text(
              relativeTime,
              style: TextStyle(color: colours.tertiaryLight, fontSize: textXXS),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineForcePush(PrForcePush fp) {
    final relativeTime = timeago.format(fp.createdAt, locale: 'en').replaceFirstMapped(RegExp(r'^[A-Z]'), (m) => m.group(0)!.toLowerCase());

    return Padding(
      padding: EdgeInsets.only(bottom: spaceXS),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceXS),
        decoration: BoxDecoration(color: colours.tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
        child: Row(
          children: [
            FaIcon(FontAwesomeIcons.bolt, size: textXS, color: colours.tertiaryLight),
            SizedBox(width: spaceXS),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: fp.actorUsername,
                      style: TextStyle(color: colours.primaryLight, fontSize: textXS, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: ' force-pushed from ',
                      style: TextStyle(color: colours.tertiaryLight, fontSize: textXS),
                    ),
                    TextSpan(
                      text: fp.beforeSha,
                      style: TextStyle(color: colours.tertiaryInfo, fontSize: textXS, fontFamily: 'RobotoMono'),
                    ),
                    TextSpan(
                      text: ' to ',
                      style: TextStyle(color: colours.tertiaryLight, fontSize: textXS),
                    ),
                    TextSpan(
                      text: fp.afterSha,
                      style: TextStyle(color: colours.tertiaryInfo, fontSize: textXS, fontFamily: 'RobotoMono'),
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: spaceXS),
            Text(
              relativeTime,
              style: TextStyle(color: colours.tertiaryLight, fontSize: textXXS),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecksSummaryStamp() {
    final detail = _detail!;
    final (FaIconData icon, Color color, String text) = switch (detail.overallCheckStatus) {
      CheckStatus.success => (FontAwesomeIcons.solidCircleCheck, colours.tertiaryPositive, t.prAllChecksPassed),
      CheckStatus.failure => (
        FontAwesomeIcons.solidCircleXmark,
        colours.tertiaryNegative,
        t.prChecksFailed(detail.checkRuns.where((c) => c.conclusion == "failure").length),
      ),
      CheckStatus.pending => (FontAwesomeIcons.solidClock, colours.tertiaryWarning, t.prChecksPending),
      CheckStatus.none => (FontAwesomeIcons.circleMinus, colours.tertiaryLight, t.prChecksNotFound),
    };

    return Container(
      padding: EdgeInsets.all(spaceSM),
      decoration: BoxDecoration(color: colours.tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
      child: Row(
        children: [
          FaIcon(icon, size: textSM, color: color),
          SizedBox(width: spaceXS),
          Text(
            text,
            style: TextStyle(color: color, fontSize: textSM, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSummary() {
    // Deduplicate reviews: show latest per author
    final Map<String, PrReview> latestReviews = {};
    for (final review in _detail!.reviews) {
      if (review.state == PrReviewState.pending || review.state == PrReviewState.commented) continue;
      latestReviews[review.authorUsername] = review;
    }
    if (latestReviews.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: spaceXXS,
      runSpacing: spaceXXS,
      children: latestReviews.values.map((review) {
        final (Color bgColor, Color borderColor, Color textColor, String label) = switch (review.state) {
          PrReviewState.approved => (
            colours.tertiaryPositive.withValues(alpha: 0.15),
            colours.tertiaryPositive.withValues(alpha: 0.3),
            colours.tertiaryPositive,
            t.prApproved,
          ),
          PrReviewState.changesRequested => (
            colours.tertiaryNegative.withValues(alpha: 0.15),
            colours.tertiaryNegative.withValues(alpha: 0.3),
            colours.tertiaryNegative,
            t.prChangesRequested,
          ),
          _ => (colours.tertiaryDark, Colors.transparent, colours.secondaryLight, t.prCommented),
        };

        return Container(
          padding: EdgeInsets.symmetric(horizontal: spaceXS, vertical: spaceXXXS),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.all(cornerRadiusSM),
            border: Border.all(color: borderColor, width: spaceXXXXS),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                review.authorUsername,
                style: TextStyle(color: textColor, fontSize: textXS, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: spaceXXXS),
              Text(
                label,
                style: TextStyle(color: textColor, fontSize: textXXS),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCommentCard(IssueComment comment) {
    final relativeTime = timeago.format(comment.createdAt, locale: 'en').replaceFirstMapped(RegExp(r'^[A-Z]'), (m) => m.group(0)!.toLowerCase());

    return Padding(
      padding: EdgeInsets.only(bottom: spaceXS),
      child: Container(
        padding: EdgeInsets.all(spaceSM),
        decoration: BoxDecoration(color: colours.secondaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    comment.authorUsername,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colours.primaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
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
            SizedBox(height: spaceXXS),
            MarkdownBlock(data: comment.body, config: _markdownConfig, generator: _markdownGenerator),
            if (comment.reactions.isNotEmpty) ...[SizedBox(height: spaceXS), _buildReactions(comment.reactions, comment.id, true)],
            if (_detail?.canComment == true) ...[SizedBox(height: spaceXXS), _buildAddReactionButton(comment.id, true)],
          ],
        ),
      ),
    );
  }

  Widget _buildReactions(List<IssueReaction> reactions, String targetId, bool isComment) {
    return Wrap(
      spacing: spaceXXXS,
      runSpacing: spaceXXXS,
      children: reactions.map((reaction) {
        final emoji = standardReactions[reaction.content] ?? reaction.content;
        return GestureDetector(
          onTap: _detail?.canComment == true ? () => _toggleReaction(targetId, reaction.content, isComment, reaction.viewerHasReacted) : null,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: spaceXXS, vertical: spaceXXXXS),
            decoration: BoxDecoration(
              color: reaction.viewerHasReacted ? colours.showcaseBg : colours.tertiaryDark,
              borderRadius: BorderRadius.all(cornerRadiusXS),
              border: Border.all(color: reaction.viewerHasReacted ? colours.showcaseBorder : Colors.transparent, width: spaceXXXXS),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: TextStyle(fontSize: textXS)),
                SizedBox(width: spaceXXXXS),
                Text(
                  '${reaction.count}',
                  style: TextStyle(color: colours.primaryLight, fontSize: textXXS),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAddReactionButton(String targetId, bool isComment) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => _showAddReactionSheet(targetId, isComment),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: spaceXS, vertical: spaceXXXS),
          decoration: BoxDecoration(color: colours.tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(FontAwesomeIcons.faceSmile, size: textXS, color: colours.tertiaryLight),
              SizedBox(width: spaceXXXS),
              Text(
                '+',
                style: TextStyle(color: colours.tertiaryLight, fontSize: textXS, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      decoration: BoxDecoration(color: colours.secondaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(spaceSM, spaceSM, spaceSM, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _writeMode = true),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceXXS),
                    decoration: BoxDecoration(
                      color: _writeMode ? colours.tertiaryDark : Colors.transparent,
                      borderRadius: BorderRadius.all(cornerRadiusXS),
                    ),
                    child: Text(
                      t.issueWrite.toUpperCase(),
                      style: TextStyle(
                        color: _writeMode ? colours.primaryLight : colours.tertiaryLight,
                        fontSize: textXS,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: spaceXXS),
                GestureDetector(
                  onTap: () => setState(() => _writeMode = false),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceXXS),
                    decoration: BoxDecoration(
                      color: !_writeMode ? colours.tertiaryDark : Colors.transparent,
                      borderRadius: BorderRadius.all(cornerRadiusXS),
                    ),
                    child: Text(
                      t.issuePreview.toUpperCase(),
                      style: TextStyle(
                        color: !_writeMode ? colours.primaryLight : colours.tertiaryLight,
                        fontSize: textXS,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: spaceXXS),
          if (_writeMode)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: spaceSM),
              child: AiWandField(
                multiline: true,
                onPressed: () async {
                  final detail = _detail;
                  if (detail == null) return;
                  final labels = detail.labels.map((l) => l.name).join(', ');
                  final files = detail.changedFiles.map((f) => f.filename).join(', ');
                  final recentComments = detail.timelineItems
                      .where((t) => t.type == PrTimelineItemType.comment && t.comment != null)
                      .toList();
                  final lastComments = recentComments.length > 5 ? recentComments.sublist(recentComments.length - 5) : recentComments;
                  final commentText = lastComments.map((t) => '@${t.comment!.authorUsername}: ${t.comment!.body}').join('\n');
                  final patchText = StringBuffer();
                  for (final f in detail.changedFiles) {
                    if (patchText.length > 3000) break;
                    patchText.writeln(f.filename);
                    if (f.patch != null) {
                      final remaining = 3000 - patchText.length;
                      patchText.writeln(f.patch!.length > remaining ? f.patch!.substring(0, remaining) : f.patch);
                    }
                  }
                  final prompt = 'PR: ${detail.title} [${detail.state.name}]\n'
                      '${detail.headBranch} → ${detail.baseBranch}\n'
                      '+${detail.additions}/-${detail.deletions} across ${detail.changedFileCount} files\n'
                      'Labels: $labels\n\n'
                      'Changed files:\n$patchText\n\n'
                      'Body:\n${detail.body}\n\n'
                      'Recent comments:\n$commentText';
                  final result = await aiComplete(
                    systemPrompt: "Draft a helpful comment for this pull request. Be concise and relevant.",
                    userPrompt: prompt,
                  );
                  if (result != null) _commentController.text = result.trim();
                },
                child: TextField(
                  contextMenuBuilder: globalContextMenuBuilder,
                  controller: _commentController,
                  maxLines: 5,
                  minLines: 3,
                  style: TextStyle(color: colours.primaryLight, fontSize: textSM, decoration: TextDecoration.none, decorationThickness: 0),
                  decoration: InputDecoration(
                    fillColor: colours.tertiaryDark,
                    filled: true,
                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(cornerRadiusSM), borderSide: BorderSide.none),
                    isCollapsed: true,
                    hintText: t.issueAddComment,
                    hintStyle: TextStyle(color: colours.tertiaryLight, fontSize: textSM),
                    contentPadding: EdgeInsets.all(spaceSM),
                  ),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              constraints: BoxConstraints(minHeight: spaceLG * 2),
              padding: EdgeInsets.all(spaceSM),
              margin: EdgeInsets.symmetric(horizontal: spaceSM),
              decoration: BoxDecoration(color: colours.tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
              child: _commentController.text.isEmpty
                  ? Text(
                      t.issueAddComment,
                      style: TextStyle(color: colours.tertiaryLight, fontSize: textSM, fontStyle: FontStyle.italic),
                    )
                  : MarkdownBlock(data: _commentController.text, config: _markdownConfig, generator: _markdownGenerator),
            ),
          PostFooterIndicator(),
          Padding(
            padding: EdgeInsets.all(spaceSM).copyWith(top: 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _submittingComment ? null : _submitComment,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceXS),
                  decoration: BoxDecoration(
                    color: _submittingComment ? colours.tertiaryDark : colours.tertiaryInfo.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.all(cornerRadiusSM),
                  ),
                  child: _submittingComment
                      ? SizedBox(
                          height: textMD,
                          width: textMD,
                          child: CircularProgressIndicator(color: colours.secondaryLight, strokeWidth: spaceXXXXS),
                        )
                      : Text(
                          "Comment".toUpperCase(),
                          style: TextStyle(color: colours.tertiaryInfo, fontSize: textSM, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── COMMITS TAB ─────────────────────────────────────────────────

  Widget _buildCommitsTab() {
    final detail = _detail!;

    if (detail.commits.isEmpty) {
      return Center(
        child: Text(
          t.prCommitsNotFound.toUpperCase(),
          style: TextStyle(color: colours.secondaryLight, fontWeight: FontWeight.bold, fontSize: textLG),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceXS),
      itemCount: detail.commits.length,
      itemBuilder: (context, index) {
        final commit = detail.commits[index];
        final relativeTime = timeago.format(commit.createdAt, locale: 'en').replaceFirstMapped(RegExp(r'^[A-Z]'), (m) => m.group(0)!.toLowerCase());

        return Padding(
          padding: EdgeInsets.only(bottom: spaceXS),
          child: Container(
            padding: EdgeInsets.all(spaceSM),
            decoration: BoxDecoration(color: colours.secondaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      commit.shortSha,
                      style: TextStyle(color: colours.tertiaryInfo, fontSize: textXS, fontFamily: 'RobotoMono'),
                    ),
                    Text(
                      ' $bullet ',
                      style: TextStyle(color: colours.tertiaryLight, fontSize: textXS),
                    ),
                    Flexible(
                      child: Text(
                        commit.authorUsername,
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
                  ],
                ),
                SizedBox(height: spaceXXS),
                Text(
                  commit.message.trim(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colours.primaryLight, fontSize: textSM),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── CHECKS TAB ──────────────────────────────────────────────────

  Widget _buildChecksTab() {
    final detail = _detail!;

    if (detail.checkRuns.isEmpty) {
      return Center(
        child: Text(
          t.prChecksNotFound.toUpperCase(),
          style: TextStyle(color: colours.secondaryLight, fontWeight: FontWeight.bold, fontSize: textLG),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceXS),
      children: [
        // Overall status banner
        _buildChecksSummaryStamp(),
        SizedBox(height: spaceSM),

        // Individual check runs
        ...detail.checkRuns.map((check) {
          final (FaIconData icon, Color color) = switch (check.conclusion) {
            "success" => (FontAwesomeIcons.solidCircleCheck, colours.tertiaryPositive),
            "failure" => (FontAwesomeIcons.solidCircleXmark, colours.tertiaryNegative),
            "cancelled" || "skipped" => (FontAwesomeIcons.circleMinus, colours.tertiaryLight),
            _ =>
              check.status == CheckRunStatus.inProgress
                  ? (FontAwesomeIcons.solidCircle, colours.tertiaryWarning)
                  : (FontAwesomeIcons.solidClock, colours.tertiaryLight),
          };

          String? durationStr;
          if (check.startedAt != null && check.completedAt != null) {
            final duration = check.completedAt!.difference(check.startedAt!);
            if (duration.inMinutes > 0) {
              durationStr = '${duration.inMinutes}m ${duration.inSeconds % 60}s';
            } else {
              durationStr = '${duration.inSeconds}s';
            }
          }

          return Padding(
            padding: EdgeInsets.only(bottom: spaceXS),
            child: Container(
              padding: EdgeInsets.all(spaceSM),
              decoration: BoxDecoration(color: colours.secondaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
              child: Row(
                children: [
                  FaIcon(icon, size: textSM, color: color),
                  SizedBox(width: spaceXS),
                  Expanded(
                    child: Text(
                      check.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colours.primaryLight, fontSize: textSM),
                    ),
                  ),
                  if (durationStr != null)
                    Text(
                      durationStr,
                      style: TextStyle(color: colours.tertiaryLight, fontSize: textXS),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ─── FILES CHANGED TAB ───────────────────────────────────────────

  String _convertPatchToMarkerFormat(String patch) {
    final lines = patch.split('\n');
    final buffer = StringBuffer();
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.startsWith('@@')) {
        if (i > 0) buffer.write('\n');
        buffer.write(line);
      } else if (line.startsWith('+')) {
        buffer.write('\n+++++insertion+++++');
        buffer.write(line.substring(1));
      } else if (line.startsWith('-')) {
        buffer.write('\n-----deletion-----');
        buffer.write(line.substring(1));
      } else if (line.startsWith(' ')) {
        buffer.write('\n');
        buffer.write(line.substring(1));
      } else if (line.isEmpty && i == lines.length - 1) {
        // skip trailing empty line
      } else {
        buffer.write('\n');
        buffer.write(line);
      }
    }
    return buffer.toString();
  }

  Widget _buildFilesTab() {
    final detail = _detail!;

    if (detail.changedFiles.isEmpty) {
      return Center(
        child: Text(
          t.prFilesChangedNotFound.toUpperCase(),
          style: TextStyle(color: colours.secondaryLight, fontWeight: FontWeight.bold, fontSize: textLG),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceXS),
      children: [
        // Summary bar
        Container(
          padding: EdgeInsets.all(spaceSM),
          decoration: BoxDecoration(color: colours.secondaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
          child: Row(
            children: [
              Text(
                '${detail.changedFileCount} ${t.prFilesChanged.toLowerCase()}',
                style: TextStyle(color: colours.primaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '+${detail.additions}',
                style: TextStyle(color: colours.tertiaryPositive, fontSize: textSM, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: spaceXS),
              Text(
                '-${detail.deletions}',
                style: TextStyle(color: colours.tertiaryNegative, fontSize: textSM, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        SizedBox(height: spaceSM),

        // File list with expandable diffs
        ...detail.changedFiles.asMap().entries.map((entry) {
          final index = entry.key;
          final file = entry.value;
          final expanded = _expandedFiles.contains(index);
          final hasPatch = file.patch != null && file.patch!.isNotEmpty;

          final (FaIconData icon, Color color) = switch (file.status) {
            "added" => (FontAwesomeIcons.plus, colours.tertiaryPositive),
            "removed" => (FontAwesomeIcons.minus, colours.tertiaryNegative),
            "renamed" => (FontAwesomeIcons.arrowRight, colours.tertiaryWarning),
            _ => (FontAwesomeIcons.pen, colours.tertiaryInfo),
          };

          return Padding(
            padding: EdgeInsets.only(bottom: spaceXS),
            child: Container(
              decoration: BoxDecoration(color: colours.secondaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: hasPatch
                        ? () => setState(() {
                            if (expanded) {
                              _expandedFiles.remove(index);
                            } else {
                              _expandedFiles.add(index);
                            }
                          })
                        : null,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceXS),
                      child: Row(
                        children: [
                          FaIcon(icon, size: textXS, color: color),
                          SizedBox(width: spaceXS),
                          Expanded(
                            child: Text(
                              file.filename,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: colours.primaryLight, fontSize: textSM),
                            ),
                          ),
                          if (file.additions > 0)
                            Padding(
                              padding: EdgeInsets.only(left: spaceXS),
                              child: Text(
                                '+${file.additions}',
                                style: TextStyle(color: colours.tertiaryPositive, fontSize: textXS),
                              ),
                            ),
                          if (file.deletions > 0)
                            Padding(
                              padding: EdgeInsets.only(left: spaceXXXS),
                              child: Text(
                                '-${file.deletions}',
                                style: TextStyle(color: colours.tertiaryNegative, fontSize: textXS),
                              ),
                            ),
                          if (hasPatch) ...[
                            SizedBox(width: spaceXS),
                            FaIcon(expanded ? FontAwesomeIcons.chevronUp : FontAwesomeIcons.chevronDown, size: textXS, color: colours.tertiaryLight),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (expanded && hasPatch)
                    SizedBox(
                      height: (file.patch!.split('\n').length * 20.0).clamp(100.0, 400.0),
                      width: double.infinity,
                      child: Padding(
                        padding: EdgeInsets.only(left: spaceSM, bottom: spaceSM),
                        child: Editor(type: EditorType.DIFF, text: _convertPatchToMarkerFormat(file.patch!)),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
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

Route createPrDetailPageRoute({
  required GitProvider gitProvider,
  required String remoteWebUrl,
  required String accessToken,
  required bool githubAppOauth,
  required int prNumber,
  required String prTitle,
}) {
  return PageRouteBuilder(
    settings: const RouteSettings(name: pr_detail_page),
    pageBuilder: (context, animation, secondaryAnimation) => PrDetailPage(
      gitProvider: gitProvider,
      remoteWebUrl: remoteWebUrl,
      accessToken: accessToken,
      githubAppOauth: githubAppOauth,
      prNumber: prNumber,
      prTitle: prTitle,
    ),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
