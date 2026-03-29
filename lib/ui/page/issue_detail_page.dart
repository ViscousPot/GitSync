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
import 'package:GitSync/ui/component/post_footer_indicator.dart';
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
  bool _editingTitle = false;
  bool _editingBody = false;
  bool _bodyWriteMode = true;
  bool _submittingEdit = false;
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _titleEditController = TextEditingController();
  final TextEditingController _bodyEditController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _titleEditController.dispose();
    _bodyEditController.dispose();
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

    final bodyWithFooter = await uiSettingsManager.applyPostFooter(body);
    final comment = await manager.addIssueComment(widget.accessToken, owner, repo, widget.issueNumber, bodyWithFooter);
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

  Future<void> _updateIssue({String? title, String? body}) async {
    setState(() => _submittingEdit = true);
    final (owner, repo) = _parseOwnerRepo();
    final manager = _manager;
    if (manager == null) return;

    final success = await manager.updateIssue(widget.accessToken, owner, repo, widget.issueNumber, title: title, body: body);
    if (!mounted) return;

    if (success) {
      setState(() {
        _detail = _detail?.copyWith(title: title, body: body);
        _editingTitle = false;
        _editingBody = false;
        _submittingEdit = false;
      });
      Fluttertoast.showToast(msg: t.issueEditSuccess, toastLength: Toast.LENGTH_SHORT, gravity: null);
    } else {
      setState(() => _submittingEdit = false);
      Fluttertoast.showToast(msg: t.issueEditFailed, toastLength: Toast.LENGTH_LONG, gravity: null);
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

  MarkdownConfig get _markdownConfig => buildMarkdownConfig();
  MarkdownGenerator get _markdownGenerator => buildMarkdownGenerator();

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
                        if (_editingTitle)
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  contextMenuBuilder: globalContextMenuBuilder,
                                  controller: _titleEditController,
                                  autofocus: true,
                                  maxLines: 2,
                                  style: TextStyle(
                                    color: colours.primaryLight,
                                    fontSize: textMD,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.none,
                                    decorationThickness: 0,
                                  ),
                                  decoration: InputDecoration(
                                    fillColor: colours.secondaryDark,
                                    filled: true,
                                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(cornerRadiusSM), borderSide: BorderSide.none),
                                    isCollapsed: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: spaceXS, vertical: spaceXXS),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              SizedBox(width: spaceXXXS),
                              GestureDetector(
                                onTap: _submittingEdit
                                    ? null
                                    : () {
                                        final newTitle = _titleEditController.text.trim();
                                        if (newTitle.isNotEmpty && newTitle != _detail?.title) {
                                          _updateIssue(title: newTitle);
                                        } else {
                                          setState(() => _editingTitle = false);
                                        }
                                      },
                                child: _submittingEdit
                                    ? SizedBox(
                                        height: textMD,
                                        width: textMD,
                                        child: CircularProgressIndicator(color: colours.secondaryLight, strokeWidth: spaceXXXXS),
                                      )
                                    : FaIcon(FontAwesomeIcons.check, size: textMD, color: colours.tertiaryPositive),
                              ),
                              SizedBox(width: spaceXXS),
                              GestureDetector(
                                onTap: () => setState(() => _editingTitle = false),
                                child: FaIcon(FontAwesomeIcons.xmark, size: textMD, color: colours.tertiaryLight),
                              ),
                            ],
                          )
                        else
                          GestureDetector(
                            onTap: _detail?.canWrite == true
                                ? () {
                                    _titleEditController.text = _detail?.title ?? '';
                                    setState(() => _editingTitle = true);
                                  }
                                : null,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flexible(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Text(
                                      _detail?.title ?? widget.issueTitle,
                                      style: TextStyle(color: colours.primaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                if (_detail?.canWrite == true) ...[
                                  SizedBox(width: spaceXXS),
                                  Padding(
                                    padding: EdgeInsets.only(top: spaceXXXXS),
                                    child: FaIcon(FontAwesomeIcons.solidPenToSquare, size: textXS, color: colours.tertiaryLight),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        if (_detail != null && !_editingTitle) ...[
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
        Row(
          children: [
            Text(
              t.issueDescription.toUpperCase(),
              style: TextStyle(color: colours.secondaryLight, fontSize: textXXS, fontWeight: FontWeight.bold),
            ),
            if (detail.canWrite && !_editingBody) ...[
              SizedBox(width: spaceXXS),
              GestureDetector(
                onTap: () {
                  _bodyEditController.text = detail.body;
                  setState(() {
                    _editingBody = true;
                    _bodyWriteMode = true;
                  });
                },
                child: FaIcon(FontAwesomeIcons.solidPenToSquare, size: textXXS, color: colours.tertiaryLight),
              ),
            ],
          ],
        ),
        SizedBox(height: spaceXXS),
        if (_editingBody)
          _buildBodyEditor()
        else if (detail.body.isEmpty)
          Text(
            t.issueNoDescription,
            style: TextStyle(color: colours.tertiaryLight, fontSize: textSM, fontStyle: FontStyle.italic),
          )
        else
          MarkdownBlock(data: detail.body, config: _markdownConfig, generator: _markdownGenerator),

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
            MarkdownBlock(data: comment.body, config: _markdownConfig, generator: _markdownGenerator),
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
              child: AiWandField(
                multiline: true,
                onPressed: () async {
                  final detail = _detail;
                  if (detail == null) return;
                  final labels = detail.labels.map((l) => l.name).join(', ');
                  final state = detail.isOpen ? 'open' : 'closed';
                  final recentComments = detail.comments.length > 5 ? detail.comments.sublist(detail.comments.length - 5) : detail.comments;
                  final commentText = recentComments.map((c) => '@${c.authorUsername}: ${c.body}').join('\n');
                  final prompt = 'Issue: ${detail.title} [$state]\nLabels: $labels\n\nBody:\n${detail.body}\n\nRecent comments:\n$commentText';
                  final result = await aiComplete(
                    systemPrompt: "Draft a helpful comment for this GitHub issue. Be concise and relevant to the discussion.",
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

          // Submit button
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

  Widget _buildBodyEditor() {
    return Container(
      decoration: BoxDecoration(color: colours.secondaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(spaceSM, spaceSM, spaceSM, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _bodyWriteMode = true),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceXXS),
                    decoration: BoxDecoration(
                      color: _bodyWriteMode ? colours.tertiaryDark : Colors.transparent,
                      borderRadius: BorderRadius.all(cornerRadiusXS),
                    ),
                    child: Text(
                      t.issueWrite.toUpperCase(),
                      style: TextStyle(
                        color: _bodyWriteMode ? colours.primaryLight : colours.tertiaryLight,
                        fontSize: textXS,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: spaceXXS),
                GestureDetector(
                  onTap: () => setState(() => _bodyWriteMode = false),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceXXS),
                    decoration: BoxDecoration(
                      color: !_bodyWriteMode ? colours.tertiaryDark : Colors.transparent,
                      borderRadius: BorderRadius.all(cornerRadiusXS),
                    ),
                    child: Text(
                      t.issuePreview.toUpperCase(),
                      style: TextStyle(
                        color: !_bodyWriteMode ? colours.primaryLight : colours.tertiaryLight,
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
          if (_bodyWriteMode)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: spaceSM),
              child: AiWandField(
                multiline: true,
                enabled: _bodyEditController.text.trim() != (_detail?.body ?? '').trim(),
                onPressed: () async {
                  final detail = _detail;
                  if (detail == null) return;
                  final labels = detail.labels.map((l) => l.name).join(', ');
                  final prompt = 'Title: ${detail.title}\nLabels: $labels\n\nCurrent body:\n${_bodyEditController.text}';
                  final result = await aiComplete(
                    systemPrompt: "Improve this issue description. Maintain the original intent, enhance clarity. Use markdown. Output only the improved body.",
                    userPrompt: prompt,
                  );
                  if (result != null) {
                    _bodyEditController.text = result.trim();
                    setState(() {});
                  }
                },
                child: TextField(
                  contextMenuBuilder: globalContextMenuBuilder,
                  controller: _bodyEditController,
                  maxLines: 10,
                  minLines: 5,
                  style: TextStyle(color: colours.primaryLight, fontSize: textSM, decoration: TextDecoration.none, decorationThickness: 0),
                  decoration: InputDecoration(
                    fillColor: colours.tertiaryDark,
                    filled: true,
                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(cornerRadiusSM), borderSide: BorderSide.none),
                    isCollapsed: true,
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
              child: _bodyEditController.text.isEmpty
                  ? Text(
                      t.issueNoDescription,
                      style: TextStyle(color: colours.tertiaryLight, fontSize: textSM, fontStyle: FontStyle.italic),
                    )
                  : MarkdownBlock(data: _bodyEditController.text, config: _markdownConfig, generator: _markdownGenerator),
            ),
          Padding(
            padding: EdgeInsets.all(spaceSM),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _editingBody = false),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceXS),
                    child: Text(
                      t.cancel.toUpperCase(),
                      style: TextStyle(color: colours.tertiaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(width: spaceXXS),
                GestureDetector(
                  onTap: _submittingEdit ? null : () => _updateIssue(body: _bodyEditController.text),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceXS),
                    decoration: BoxDecoration(
                      color: _submittingEdit ? colours.tertiaryDark : colours.tertiaryInfo.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.all(cornerRadiusSM),
                    ),
                    child: _submittingEdit
                        ? SizedBox(
                            height: textMD,
                            width: textMD,
                            child: CircularProgressIndicator(color: colours.secondaryLight, strokeWidth: spaceXXXXS),
                          )
                        : Text(
                            t.done.toUpperCase(),
                            style: TextStyle(color: colours.tertiaryInfo, fontSize: textSM, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
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
