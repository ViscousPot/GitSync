import 'dart:async';

import 'package:GitSync/api/helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/global.dart';
import 'package:sprintf/sprintf.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../constant/dimens.dart';
import '../../../src/rust/api/git_manager.dart' as GitManagerRs;
import 'package:timeago/timeago.dart' as timeago;

import 'package:GitSync/type/git_provider.dart';
import 'package:GitSync/api/manager/git_manager.dart';
import '../dialog/diff_view.dart' as DiffViewDialog;
import '../dialog/create_branch_from_commit.dart' as CreateBranchFromCommitDialog;

class ChevronPainter extends CustomPainter {
  final Color color;
  final double stripeWidth;
  final bool facingDown;

  ChevronPainter({required this.color, this.stripeWidth = 20, this.facingDown = true});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();

    double stripeHeight = stripeWidth;
    for (double y = 0; y < size.height + stripeHeight; y += stripeHeight) {
      path.reset();

      if (facingDown) {
        path.moveTo(0, y - (stripeHeight / 2));
        path.lineTo(size.width / 2, y + stripeHeight - (stripeHeight / 2));
        path.lineTo(size.width, y - (stripeHeight / 2));
        path.lineTo(size.width, (y + stripeHeight / 2) - (stripeHeight / 2));
        path.lineTo(size.width / 2, (y + stripeHeight * 1.5) - (stripeHeight / 2));
        path.lineTo(0, (y + stripeHeight / 2) - (stripeHeight / 2));
      } else {
        path.moveTo(0, y + stripeHeight);
        path.lineTo(size.width / 2, y);
        path.lineTo(size.width, y + stripeHeight);
        path.lineTo(size.width, y + stripeHeight / 2);
        path.lineTo(size.width / 2, y - stripeHeight / 2);
        path.lineTo(0, y + stripeHeight / 2);
      }

      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ItemCommit extends StatefulWidget {
  const ItemCommit(
    this.commit,
    this.prevCommit,
    this.recentCommits, {
    this.gitProvider,
    this.remoteWebUrl,
    this.onRefresh,
    super.key,
  });

  final GitManagerRs.Commit commit;
  final GitManagerRs.Commit? prevCommit;
  final List<GitManagerRs.Commit> recentCommits;
  final GitProvider? gitProvider;
  final String? remoteWebUrl;
  final Future<void> Function()? onRefresh;

  @override
  State<ItemCommit> createState() => _ItemCommit();
}

class _ItemCommit extends State<ItemCommit> {
  late Timer _timer;
  late String _relativeCommitDate;
  bool _menuOpen = false;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) => _updateTime());
  }

  void _updateTime() {
    setState(() {
      _relativeCommitDate = timeago
          .format(DateTime.fromMillisecondsSinceEpoch(widget.commit.timestamp * 1000), locale: 'en')
          .replaceFirstMapped(RegExp(r'^[A-Z]'), (match) => match.group(0)!.toLowerCase());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _showCommitContextMenu(BuildContext context, Offset position) async {
    setState(() => _menuOpen = true);
    final titleStyle = TextStyle(color: colours.primaryLight, fontSize: textSM, fontWeight: FontWeight.bold);
    final descStyle = TextStyle(color: colours.tertiaryLight, fontSize: textXS);
    PopupMenuItem<String> item(String value, String title, String desc) {
      return PopupMenuItem(
        value: value,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: titleStyle),
            Text(desc, style: descStyle),
          ],
        ),
      );
    }

    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      color: colours.secondaryDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM)),
      items: [
        item('copy-sha', 'COPY SHA', 'Copy the full commit hash to clipboard'),
        if (widget.commit.tags.isNotEmpty) item('copy-tag', 'COPY TAG', 'Copy the tag name to clipboard'),
        if (widget.gitProvider?.isOAuthProvider == true && widget.remoteWebUrl != null)
          item('view', 'VIEW ON ${widget.gitProvider!.name.toUpperCase()}', 'Open this commit in your browser'),
        item('create-branch', 'CREATE BRANCH FROM COMMIT', 'Create a new branch from this commit'),
      ],
    );
    if (mounted) setState(() => _menuOpen = false);
    switch (result) {
      case 'copy-sha':
        await Clipboard.setData(ClipboardData(text: widget.commit.reference));
      case 'copy-tag':
        await Clipboard.setData(ClipboardData(text: widget.commit.tags.join(', ')));
      case 'view':
        final url = widget.gitProvider!.commitUrl(widget.remoteWebUrl!, widget.commit.reference);
        if (url != null) await launchUrl(Uri.parse(url));
      case 'create-branch':
        if (mounted) {
          await CreateBranchFromCommitDialog.showDialog(
            context,
            widget.commit.reference,
            (branchName) async {
              await GitManager.createBranchFromCommit(branchName, widget.commit.reference);
              await widget.onRefresh?.call();
            },
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BetterOrientationBuilder(
      builder: (context, orientation) => Container(
        margin: orientation == Orientation.portrait ? EdgeInsets.only(top: spaceSM) : EdgeInsets.only(bottom: spaceSM),
        child: GestureDetector(
          onLongPressStart: (details) {
            _showCommitContextMenu(context, details.globalPosition);
          },
          child: TextButton(
            onPressed: () async {
              print(widget.commit.reference);
              print(widget.prevCommit?.reference);

              DiffViewDialog.showDialog(
                context,
                widget.recentCommits,
                (widget.commit.reference, widget.prevCommit?.reference),
                widget.commit.reference.substring(0, 7),
                (widget.commit, widget.prevCommit),
                null,
                widget.commit.tags,
              );
            },
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(
                widget.commit.unpushed
                    ? colours.tertiaryInfo
                    : widget.commit.unpulled
                    ? colours.tertiaryWarning
                    : colours.tertiaryDark,
              ),
              padding: WidgetStatePropertyAll(EdgeInsets.zero),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(cornerRadiusSM),
                  side: _menuOpen ? BorderSide(color: colours.primaryLight, width: spaceXXXXS) : BorderSide.none,
                ),
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            clipBehavior: Clip.antiAlias,
            child: CustomPaint(
              painter: ChevronPainter(
                color: widget.commit.unpushed
                    ? colours.secondaryInfo.withAlpha(70)
                    : widget.commit.unpulled
                    ? colours.secondaryWarning.withAlpha(70)
                    : Colors.transparent,
                stripeWidth: 20,
                facingDown: !widget.commit.unpushed,
              ),
              child: Padding(
                padding: EdgeInsets.all(spaceSM),
                child: IntrinsicHeight(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Text(
                              widget.commit.commitMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: widget.commit.unpulled || widget.commit.unpushed ? colours.secondaryDark : colours.primaryLight,
                                fontSize: textMD,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "${demo ? "ViscousTests" : widget.commit.authorUsername} ${t.committed} $_relativeCommitDate",
                              style: TextStyle(
                                color: widget.commit.unpulled || widget.commit.unpushed ? colours.tertiaryDark : colours.secondaryLight,
                                fontSize: textSM,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: spaceXS),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.centerLeft,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(right: widget.commit.tags.isEmpty ? 0 : widget.commit.tags.length.clamp(0, 4) * spaceSM),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: widget.commit.unpulled || widget.commit.unpushed ? colours.tertiaryDark : colours.secondaryLight,
                                    borderRadius: BorderRadius.all(cornerRadiusXS),
                                    boxShadow: [BoxShadow(color: colours.tertiaryDark, blurRadius: 10, offset: Offset(0, 2))],
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: spaceXS, vertical: spaceXXXS),
                                  child: Text(
                                    (widget.commit.reference).substring(0, 7).toUpperCase(),
                                    style: TextStyle(
                                      color: widget.commit.unpulled || widget.commit.unpushed ? colours.secondaryLight : colours.tertiaryDark,
                                      fontSize: textXS,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              for (int i = widget.commit.tags.length.clamp(0, 4) - 1; i >= 0; i--)
                                Positioned(
                                  right: i * spaceSM,
                                  child: Opacity(
                                    opacity: (1.0 - (i * 0.3)).clamp(0.0, 1.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: widget.commit.unpulled || widget.commit.unpushed ? colours.tertiaryDark : colours.secondaryLight,
                                        borderRadius: BorderRadius.all(cornerRadiusXS),
                                        border: Border.all(
                                          color: widget.commit.unpulled || widget.commit.unpushed ? colours.secondaryLight : colours.tertiaryDark,
                                          width: 1,
                                        ),
                                        boxShadow: [BoxShadow(color: colours.tertiaryDark, blurRadius: 10, offset: Offset(0, 2))],
                                      ),
                                      padding: EdgeInsets.symmetric(horizontal: spaceXS, vertical: spaceXXXS),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          FaIcon(
                                            FontAwesomeIcons.tag,
                                            size: textXXS,
                                            color: widget.commit.unpulled || widget.commit.unpushed ? colours.secondaryLight : colours.tertiaryDark,
                                          ),
                                          SizedBox(width: spaceXXXXS),
                                          Text(
                                            widget.commit.tags[i].toUpperCase(),
                                            style: TextStyle(
                                              color: widget.commit.unpulled || widget.commit.unpushed ? colours.secondaryLight : colours.tertiaryDark,
                                              fontSize: textXS,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: spaceXXXS),
                          Row(
                            children: [
                              Text(
                                sprintf(t.additions, [widget.commit.additions]),
                                style: TextStyle(
                                  color: widget.commit.unpulled || widget.commit.unpushed ? colours.secondaryPositive : colours.tertiaryPositive,
                                  fontSize: textXS,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(width: spaceSM),
                              Text(
                                sprintf(t.deletions, [widget.commit.deletions]),
                                style: TextStyle(
                                  color: widget.commit.unpulled || widget.commit.unpushed ? colours.primaryNegative : colours.tertiaryNegative,
                                  fontSize: textXS,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
