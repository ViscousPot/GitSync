import 'dart:async';

import 'package:GitSync/api/helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/providers/riverpod_providers.dart';
import 'package:sprintf/sprintf.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../constant/dimens.dart';
import '../../../src/rust/api/git_manager.dart' as GitManagerRs;
import 'package:timeago/timeago.dart' as timeago;

import 'package:GitSync/type/git_provider.dart';
import 'package:GitSync/api/manager/git_manager.dart';
import '../dialog/diff_view.dart' as DiffViewDialog;
import '../dialog/create_branch_from_commit.dart' as CreateBranchFromCommitDialog;
import '../dialog/confirm_checkout_commit.dart' as ConfirmCheckoutCommitDialog;
import '../dialog/create_tag_on_commit.dart' as CreateTagOnCommitDialog;
import '../dialog/confirm_revert_commit.dart' as ConfirmRevertCommitDialog;
import '../dialog/amend_commit.dart' as AmendCommitDialog;
import '../dialog/confirm_undo_commit.dart' as ConfirmUndoCommitDialog;
import '../dialog/confirm_reset_to_commit.dart' as ConfirmResetToCommitDialog;
import '../dialog/confirm_cherry_pick.dart' as ConfirmCherryPickDialog;

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

class ItemCommit extends ConsumerStatefulWidget {
  const ItemCommit(
    this.commit,
    this.prevCommit,
    this.recentCommits, {
    this.gitProvider,
    this.remoteWebUrl,
    this.onRefresh,
    this.selectMode,
    this.selectedShas,
    this.onSelectModeRequested,
    super.key,
  });

  final GitManagerRs.Commit commit;
  final GitManagerRs.Commit? prevCommit;
  final List<GitManagerRs.Commit> recentCommits;
  final GitProvider? gitProvider;
  final String? remoteWebUrl;
  final Future<void> Function()? onRefresh;
  final ValueNotifier<bool>? selectMode;
  final ValueNotifier<Set<String>>? selectedShas;
  final VoidCallback? onSelectModeRequested;

  @override
  ConsumerState<ItemCommit> createState() => _ItemCommit();
}

class _ItemCommit extends ConsumerState<ItemCommit> with SingleTickerProviderStateMixin {
  late Timer _timer;
  late String _relativeCommitDate;
  bool _menuOpen = false;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) => _updateTime());
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
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
    _pulseController.dispose();
    super.dispose();
  }

  void _showCommitContextMenu(BuildContext context, Offset position) async {
    setState(() => _menuOpen = true);
    final titleStyle = TextStyle(color: context.colours.primaryLight, fontSize: textSM, fontWeight: FontWeight.bold);
    final descStyle = TextStyle(color: context.colours.tertiaryLight, fontSize: textXS);
    PopupMenuItem<String> item(String value, String title, String desc, {bool enabled = true}) {
      return PopupMenuItem(
        value: value,
        enabled: enabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: titleStyle.copyWith(color: !enabled ? context.colours.tertiaryDark : null)),
            Text(desc, style: descStyle.copyWith(color: !enabled ? context.colours.tertiaryDark : null)),
          ],
        ),
      );
    }

    PopupMenuDivider separator() => PopupMenuDivider(height: spaceSM, color: context.colours.tertiaryDark);

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final localPosition = overlay.globalToLocal(position);
    final menuPosition = RelativeRect.fromRect(localPosition & const Size(0, 0), Offset.zero & overlay.size);

    final result = await showMenu<String>(
      context: context,
      position: menuPosition,
      color: context.colours.secondaryDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM)),
      items: [
        item('select', context.t.menuSelectCommits.toUpperCase(), context.t.menuSelectCommitsDesc),
        if (widget.recentCommits.isNotEmpty && widget.commit.reference == widget.recentCommits.first.reference) ...[
          item('amend-commit', context.t.menuAmendCommit.toUpperCase(), context.t.menuAmendCommitDesc),
          if (widget.commit.unpushed) item('undo-commit', context.t.menuUndoCommit.toUpperCase(), context.t.menuUndoCommitDesc),
        ],
        separator(),
        item('reset-commit', context.t.menuResetToCommit.toUpperCase(), context.t.menuResetToCommitDesc),
        item('checkout', context.t.menuCheckoutCommit.toUpperCase(), context.t.menuCheckoutCommitDesc),
        // item('reorder-commit', 'REORDER COMMIT', 'Move this commit to a different position in history'),
        item('revert', context.t.menuRevertCommit.toUpperCase(), context.t.menuRevertCommitDesc),
        separator(),
        item('create-branch', context.t.menuCreateBranch.toUpperCase(), context.t.menuCreateBranchDesc),
        item('create-tag', context.t.menuCreateTag.toUpperCase(), context.t.menuCreateTagDesc),
        item('cherry-pick', context.t.menuCherryPick.toUpperCase(), context.t.menuCherryPickDesc),
        separator(),
        item('copy-sha', context.t.menuCopySha.toUpperCase(), context.t.menuCopyShaDesc),
        item('copy-tag', context.t.menuCopyTag.toUpperCase(), context.t.menuCopyTagDesc, enabled: widget.commit.tags.isNotEmpty),
        item(
          'view',
          sprintf(context.t.menuViewOnProvider, [widget.gitProvider!.name]).toUpperCase(),
          context.t.menuViewOnProviderDesc,
          enabled: widget.gitProvider?.isOAuthProvider == true && widget.remoteWebUrl != null && !widget.commit.unpushed,
        ),
      ],
    );
    if (mounted) setState(() => _menuOpen = false);
    switch (result) {
      case 'amend-commit':
        if (mounted) {
          await AmendCommitDialog.showDialog(
            context,
            widget.commit.reference,
            widget.commit.commitMessage,
            widget.commit.authorUsername,
            widget.commit.authorEmail,
            (newMessage, newAuthorName, newAuthorEmail) async {
              await GitManager.amendCommit(newMessage, authorName: newAuthorName, authorEmail: newAuthorEmail);
              await widget.onRefresh?.call();
            },
          );
        }
      case 'undo-commit':
        if (mounted) {
          await ConfirmUndoCommitDialog.showDialog(context, widget.commit.reference, widget.commit.commitMessage, () async {
            await GitManager.undoCommit();
            await widget.onRefresh?.call();
          });
        }
      case 'reset-commit':
        if (mounted) {
          await ConfirmResetToCommitDialog.showDialog(context, widget.commit.reference, widget.commit.commitMessage, () async {
            await GitManager.resetToCommit(widget.commit.reference);
            await widget.onRefresh?.call();
          });
        }
      case 'cherry-pick':
        if (mounted) {
          final currentBranch = ref.read(branchNameProvider).valueOrNull;
          final localBranchNames = ref.read(branchNamesProvider).valueOrNull?.keys.toList() ?? [];
          if (mounted) {
            await ConfirmCherryPickDialog.showDialog(context, widget.commit.reference, widget.commit.commitMessage, currentBranch, localBranchNames, (
              targetBranch,
            ) async {
              await GitManager.cherryPickCommit(widget.commit.reference, targetBranch);
              await widget.onRefresh?.call();
            });
          }
        }
      case 'checkout':
        if (mounted) {
          await ConfirmCheckoutCommitDialog.showDialog(context, widget.commit.reference, widget.commit.commitMessage, () async {
            await GitManager.checkoutCommit(widget.commit.reference);
            await widget.onRefresh?.call();
          });
        }
      case 'revert':
        if (mounted) {
          await ConfirmRevertCommitDialog.showDialog(context, widget.commit.reference, widget.commit.commitMessage, () async {
            await GitManager.revertCommit(widget.commit.reference);
            await widget.onRefresh?.call();
          });
        }
      case 'create-tag':
        if (mounted) {
          await CreateTagOnCommitDialog.showDialog(context, widget.commit.reference, (tagName) async {
            await GitManager.createTag(tagName, widget.commit.reference);
            await widget.onRefresh?.call();
          });
        }
      case 'create-branch':
        if (mounted) {
          await CreateBranchFromCommitDialog.showDialog(context, widget.commit.reference, (branchName) async {
            await GitManager.createBranchFromCommit(branchName, widget.commit.reference);
            await widget.onRefresh?.call();
          });
        }
      case 'copy-sha':
        await Clipboard.setData(ClipboardData(text: widget.commit.reference));
      case 'copy-tag':
        await Clipboard.setData(ClipboardData(text: widget.commit.tags.join(', ')));
      case 'view':
        final url = widget.gitProvider!.commitUrl(widget.remoteWebUrl!, widget.commit.reference);
        if (url != null) await launchUrl(Uri.parse(url));
      case 'select':
        widget.onSelectModeRequested?.call();
    }
  }

  void _toggleSelection() {
    final shas = widget.selectedShas!;
    final sha = widget.commit.reference;
    if (shas.value.contains(sha)) {
      shas.value = {...shas.value}..remove(sha);
    } else {
      shas.value = {...shas.value, sha};
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectMode = widget.selectMode;
    final selectedShas = widget.selectedShas;

    Widget buildCommit({required bool inSelectMode, required bool isSelected}) {
      return BetterOrientationBuilder(
        builder: (context, orientation) => Container(
          margin: orientation == Orientation.portrait ? EdgeInsets.only(top: spaceSM) : EdgeInsets.only(bottom: spaceSM),
          child: GestureDetector(
            onLongPressStart: inSelectMode ? (_) => _toggleSelection() : (details) => _showCommitContextMenu(context, details.globalPosition),
            child: TextButton(
              onPressed: () async {
                if (inSelectMode) {
                  _toggleSelection();
                  return;
                }
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
                      ? context.colours.tertiaryInfo
                      : widget.commit.unpulled
                      ? context.colours.tertiaryWarning
                      : context.colours.tertiaryDark,
                ),
                padding: WidgetStatePropertyAll(EdgeInsets.zero),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(cornerRadiusSM),
                    side: isSelected
                        ? BorderSide(color: context.colours.primaryInfo, width: spaceXXXXS * 2)
                        : _menuOpen
                        ? BorderSide(color: context.colours.primaryLight, width: spaceXXXXS)
                        : inSelectMode
                        ? BorderSide(color: context.colours.tertiaryLight.withAlpha(50), width: spaceXXXXS)
                        : BorderSide.none,
                  ),
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              clipBehavior: Clip.antiAlias,
              child: CustomPaint(
                painter: ChevronPainter(
                  color: widget.commit.unpushed
                      ? context.colours.secondaryInfo.withAlpha(70)
                      : widget.commit.unpulled
                      ? context.colours.secondaryWarning.withAlpha(70)
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
                                  color: widget.commit.unpulled || widget.commit.unpushed ? context.colours.secondaryDark : context.colours.primaryLight,
                                  fontSize: textMD,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                "${demo ? "ViscousTests" : widget.commit.authorUsername} ${context.t.committed} $_relativeCommitDate",
                                style: TextStyle(
                                  color: widget.commit.unpulled || widget.commit.unpushed ? context.colours.tertiaryDark : context.colours.secondaryLight,
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
                              alignment: Alignment.centerRight,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(right: widget.commit.tags.isEmpty ? 0 : widget.commit.tags.length.clamp(0, 4) * spaceSM),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: widget.commit.unpulled || widget.commit.unpushed ? context.colours.tertiaryDark : context.colours.secondaryLight,
                                      borderRadius: BorderRadius.all(cornerRadiusXS),
                                      boxShadow: [BoxShadow(color: context.colours.tertiaryDark, blurRadius: 10, offset: Offset(0, 2))],
                                    ),
                                    padding: EdgeInsets.symmetric(horizontal: spaceXS, vertical: spaceXXXS),
                                    child: Text(
                                      (widget.commit.reference).substring(0, 7).toUpperCase(),
                                      style: TextStyle(
                                        color: widget.commit.unpulled || widget.commit.unpushed ? context.colours.secondaryLight : context.colours.tertiaryDark,
                                        fontSize: textXS,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                for (int i = widget.commit.tags.length.clamp(0, 4) - 1; i >= 0; i--)
                                  Padding(
                                    padding: EdgeInsets.only(right: i * spaceSM),
                                    child: Opacity(
                                      opacity: (1.0 - (i * 0.3)).clamp(0.0, 1.0),
                                      child: Container(
                                        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.4),
                                        decoration: BoxDecoration(
                                          color: widget.commit.unpulled || widget.commit.unpushed ? context.colours.tertiaryDark : context.colours.secondaryLight,
                                          borderRadius: BorderRadius.all(cornerRadiusXS),
                                          border: Border.all(
                                            color: widget.commit.unpulled || widget.commit.unpushed ? context.colours.secondaryLight : context.colours.tertiaryDark,
                                            width: 1,
                                          ),
                                          boxShadow: [BoxShadow(color: context.colours.tertiaryDark, blurRadius: 10, offset: Offset(0, 2))],
                                        ),
                                        padding: EdgeInsets.symmetric(horizontal: spaceXS, vertical: spaceXXXS),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            FaIcon(
                                              FontAwesomeIcons.tag,
                                              size: textXXS,
                                              color: widget.commit.unpulled || widget.commit.unpushed ? context.colours.secondaryLight : context.colours.tertiaryDark,
                                            ),
                                            SizedBox(width: spaceXXXXS),
                                            Flexible(
                                              child: Text(
                                                widget.commit.tags[i].toUpperCase(),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: widget.commit.unpulled || widget.commit.unpushed
                                                      ? context.colours.secondaryLight
                                                      : context.colours.tertiaryDark,
                                                  fontSize: textXS,
                                                  fontWeight: FontWeight.bold,
                                                ),
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
                            AnimatedSwitcher(
                              duration: animFast,
                              layoutBuilder: (currentChild, previousChildren) => Stack(
                                alignment: Alignment.centerLeft,
                                children: [...previousChildren, if (currentChild != null) currentChild],
                              ),
                              child: widget.commit.additions == -1 && widget.commit.deletions == -1
                                  ? SizedBox(
                                      key: const ValueKey('diff-pending'),
                                      height: textXS * 1.5,
                                      child: Row(
                                        children: [
                                          FadeTransition(
                                            opacity: _pulseController,
                                            child: Container(
                                              width: textSM * 3,
                                              height: textXS * 0.9,
                                              decoration: BoxDecoration(
                                                color: context.colours.secondaryLight.withValues(alpha: 0.5),
                                                borderRadius: BorderRadius.all(cornerRadiusXS),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: spaceSM),
                                          FadeTransition(
                                            opacity: _pulseController,
                                            child: Container(
                                              width: textSM * 3,
                                              height: textXS * 0.9,
                                              decoration: BoxDecoration(
                                                color: context.colours.secondaryLight.withValues(alpha: 0.5),
                                                borderRadius: BorderRadius.all(cornerRadiusXS),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : SizedBox(
                                      key: const ValueKey('diff-loaded'),
                                      height: textXS * 1.5,
                                      child: Row(
                                        children: [
                                          Text(
                                            sprintf(context.t.additions, [widget.commit.additions]),
                                            style: TextStyle(
                                              color: widget.commit.unpulled || widget.commit.unpushed ? context.colours.secondaryPositive : context.colours.tertiaryPositive,
                                              fontSize: textXS,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          SizedBox(width: spaceSM),
                                          Text(
                                            sprintf(context.t.deletions, [widget.commit.deletions]),
                                            style: TextStyle(
                                              color: widget.commit.unpulled || widget.commit.unpushed ? context.colours.primaryNegative : context.colours.tertiaryNegative,
                                              fontSize: textXS,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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

    if (selectMode != null && selectedShas != null) {
      return ValueListenableBuilder<bool>(
        valueListenable: selectMode,
        builder: (context, inSelectMode, _) {
          if (!inSelectMode) return buildCommit(inSelectMode: false, isSelected: false);
          return ValueListenableBuilder<Set<String>>(
            valueListenable: selectedShas,
            builder: (context, shas, _) => buildCommit(inSelectMode: true, isSelected: shas.contains(widget.commit.reference)),
          );
        },
      );
    }
    return buildCommit(inSelectMode: false, isSelected: false);
  }
}
