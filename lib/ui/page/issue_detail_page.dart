import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/api/helper.dart';
import 'package:GitSync/api/manager/auth/git_provider_manager.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/constant/reactions.dart';
import 'package:GitSync/constant/strings.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/type/git_provider.dart';
import 'package:GitSync/type/issue_detail.dart';
import 'package:timeago/timeago.dart' as timeago;

class IssueDetailPage extends StatefulWidget {
  final GitProvider gitProvider;
  final String remoteWebUrl;
  final String accessToken;
  final bool githubAppOauth;
  final int issueNumber;
  final String issueTitle;

  const IssueDetailPage({
    super.key,
    required this.gitProvider,
    required this.remoteWebUrl,
    required this.accessToken,
    required this.githubAppOauth,
    required this.issueNumber,
    required this.issueTitle,
  });

  @override
  State<IssueDetailPage> createState() => _IssueDetailPageState();
}

class _IssueDetailPageState extends State<IssueDetailPage> {
  IssueDetail? _detail;
  bool _loading = true;
  bool _togglingState = false;
  bool _submittingComment = false;
  bool _writeMode = true;
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  @override
  void dispose() {
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

    final detail = await manager.getIssueDetail(widget.accessToken, owner, repo, widget.issueNumber);
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

    final comment = await manager.addIssueComment(widget.accessToken, owner, repo, widget.issueNumber, body);
    if (!mounted) return;

    if (comment != null) {
      setState(() {
        _detail = _detail?.copyWith(comments: [..._detail!.comments, comment]);
        _commentController.clear();
        _submittingComment = false;
        _writeMode = true;
      });
      Fluttertoast.showToast(msg: t.issueCommentAdded, toastLength: Toast.LENGTH_SHORT, gravity: null);
      // Scroll to bottom after frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: animMedium, curve: Curves.easeOut);
        }
      });
    } else {
      setState(() => _submittingComment = false);
      Fluttertoast.showToast(msg: t.issueCommentFailed, toastLength: Toast.LENGTH_LONG, gravity: null);
    }
  }

  Future<void> _toggleIssueState() async {
    final detail = _detail;
    if (detail == null) return;

    setState(() => _togglingState = true);
    final (owner, repo) = _parseOwnerRepo();
    final manager = _manager;
    if (manager == null) return;

    final success = await manager.updateIssueState(widget.accessToken, owner, repo, widget.issueNumber, detail.id, detail.isOpen);
    if (!mounted) return;

    if (success) {
      setState(() {
        _detail = detail.copyWith(isOpen: !detail.isOpen);
        _togglingState = false;
      });
      Fluttertoast.showToast(msg: t.issueStateUpdated, toastLength: Toast.LENGTH_SHORT, gravity: null);
    } else {
      setState(() => _togglingState = false);
      Fluttertoast.showToast(msg: t.issueStateUpdateFailed, toastLength: Toast.LENGTH_LONG, gravity: null);
    }
  }

  Future<void> _toggleReaction(String targetId, String reaction, bool isComment, bool hasReacted) async {
    final (owner, repo) = _parseOwnerRepo();
    final manager = _manager;
    if (manager == null) return;

    bool success;
    if (hasReacted) {
      success = await manager.removeReaction(widget.accessToken, owner, repo, widget.issueNumber, targetId, reaction, isComment);
    } else {
      success = await manager.addReaction(widget.accessToken, owner, repo, widget.issueNumber, targetId, reaction, isComment);
    }

    if (!mounted) return;
    if (success) {
      await _fetchDetail();
    } else {
      Fluttertoast.showToast(msg: t.issueReactionFailed, toastLength: Toast.LENGTH_SHORT, gravity: null);
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

  MarkdownStyleSheet get _markdownStyle => MarkdownStyleSheet(
    p: TextStyle(color: colours.primaryLight, fontSize: textSM),
    h1: TextStyle(color: colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
    h2: TextStyle(color: colours.primaryLight, fontSize: textLG, fontWeight: FontWeight.bold),
    h3: TextStyle(color: colours.primaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
    code: TextStyle(color: colours.tertiaryInfo, fontSize: textXS, fontFamily: 'RobotoMono', backgroundColor: colours.tertiaryDark),
    codeblockDecoration: BoxDecoration(color: colours.tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusXS)),
    codeblockPadding: EdgeInsets.all(spaceXS),
    listBullet: TextStyle(color: colours.primaryLight, fontSize: textSM),
    a: TextStyle(color: colours.tertiaryInfo, decoration: TextDecoration.underline),
    blockquoteDecoration: BoxDecoration(
      color: colours.tertiaryDark,
      border: Border(
        left: BorderSide(color: colours.tertiaryInfo, width: spaceXXXXS),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colours.primaryDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: spaceXS, vertical: spaceXS),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  getBackButton(context, () => Navigator.of(context).pop(_detail?.isOpen)),
                  SizedBox(width: spaceXS),
                  if (_detail != null) ...[
                    Padding(
                      padding: EdgeInsets.only(top: spaceXXXS),
                      child: FaIcon(
                        _detail!.isOpen ? FontAwesomeIcons.solidCircleDot : FontAwesomeIcons.solidCircleCheck,
                        size: textMD,
                        color: _detail!.isOpen ? colours.tertiaryPositive : colours.primaryNegative,
                      ),
                    ),
                    SizedBox(width: spaceXS),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _detail?.title ?? widget.issueTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colours.primaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
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
                                timeago
                                    .format(_detail!.createdAt, locale: 'en')
                                    .replaceFirstMapped(RegExp(r'^[A-Z]'), (match) => match.group(0)!.toLowerCase()),
                                style: TextStyle(color: colours.tertiaryLight, fontSize: textXS),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(color: colours.secondaryLight, strokeWidth: spaceXXXXS),
                    )
                  : _detail == null
                  ? Center(
                      child: Text(
                        t.issuesNotFound.toUpperCase(),
                        style: TextStyle(color: colours.secondaryLight, fontWeight: FontWeight.bold, fontSize: textLG),
                      ),
                    )
                  : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final detail = _detail!;

    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: spaceMD),
      children: [
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

        // Description section
        Text(
          t.issueDescription.toUpperCase(),
          style: TextStyle(color: colours.secondaryLight, fontSize: textXXS, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: spaceXXS),
        if (detail.body.isEmpty)
          Text(
            t.issueNoDescription,
            style: TextStyle(color: colours.tertiaryLight, fontSize: textSM, fontStyle: FontStyle.italic),
          )
        else
          MarkdownBody(data: detail.body, styleSheet: _markdownStyle, shrinkWrap: true),

        // Issue reactions
        if (detail.reactions.isNotEmpty) ...[SizedBox(height: spaceSM), _buildReactions(detail.reactions, detail.id, false)],

        if (detail.canComment) ...[
          SizedBox(height: spaceXXS),
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => _showAddReactionSheet(detail.id, false),
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
          ),
        ],

        SizedBox(height: spaceLG),

        // Comments section
        Text(
          '${t.issueComments.toUpperCase()} (${detail.comments.length})',
          style: TextStyle(color: colours.secondaryLight, fontSize: textXXS, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: spaceXS),

        if (detail.comments.isEmpty)
          Text(
            t.issueNoComments,
            style: TextStyle(color: colours.tertiaryLight, fontSize: textSM, fontStyle: FontStyle.italic),
          )
        else
          ...detail.comments.map((comment) => _buildCommentCard(comment)),

        SizedBox(height: spaceMD),

        // Comment input
        if (detail.canComment) ...[_buildCommentInput(), SizedBox(height: spaceSM)],

        // Close/Reopen button
        if (detail.canWrite) ...[
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _togglingState ? null : _toggleIssueState,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: spaceSM),
                decoration: BoxDecoration(
                  color: _togglingState
                      ? colours.tertiaryDark
                      : detail.isOpen
                      ? colours.primaryNegative.withValues(alpha: 0.15)
                      : colours.tertiaryPositive.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.all(cornerRadiusSM),
                  border: Border.all(
                    color: _togglingState
                        ? Colors.transparent
                        : detail.isOpen
                        ? colours.primaryNegative.withValues(alpha: 0.3)
                        : colours.tertiaryPositive.withValues(alpha: 0.3),
                    width: spaceXXXXS,
                  ),
                ),
                child: _togglingState
                    ? Center(
                        child: SizedBox(
                          height: textMD,
                          width: textMD,
                          child: CircularProgressIndicator(color: colours.secondaryLight, strokeWidth: spaceXXXXS),
                        ),
                      )
                    : Text(
                        detail.isOpen ? t.issueCloseIssue : t.issueReopenIssue,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: detail.isOpen ? colours.primaryNegative : colours.tertiaryPositive,
                          fontSize: textMD,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],

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

  Widget _buildCommentCard(IssueComment comment) {
    final relativeTime = timeago
        .format(comment.createdAt, locale: 'en')
        .replaceFirstMapped(RegExp(r'^[A-Z]'), (match) => match.group(0)!.toLowerCase());

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
            MarkdownBody(data: comment.body, styleSheet: _markdownStyle, shrinkWrap: true),
            if (comment.reactions.isNotEmpty) ...[SizedBox(height: spaceXS), _buildReactions(comment.reactions, comment.id, true)],
            if (_detail?.canComment == true) ...[
              SizedBox(height: spaceXXS),
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => _showAddReactionSheet(comment.id, true),
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
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      decoration: BoxDecoration(color: colours.secondaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
      child: Column(
        children: [
          // Write/Preview toggle
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
                  : MarkdownBody(data: _commentController.text, styleSheet: _markdownStyle, shrinkWrap: true),
            ),

          // Submit button
          Padding(
            padding: EdgeInsets.all(spaceSM),
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

  Color _parseHexColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    }
    return colours.tertiaryDark;
  }
}

Route createIssueDetailPageRoute({
  required GitProvider gitProvider,
  required String remoteWebUrl,
  required String accessToken,
  required bool githubAppOauth,
  required int issueNumber,
  required String issueTitle,
}) {
  return PageRouteBuilder(
    settings: const RouteSettings(name: issue_detail_page),
    pageBuilder: (context, animation, secondaryAnimation) => IssueDetailPage(
      gitProvider: gitProvider,
      remoteWebUrl: remoteWebUrl,
      accessToken: accessToken,
      githubAppOauth: githubAppOauth,
      issueNumber: issueNumber,
      issueTitle: issueTitle,
    ),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
