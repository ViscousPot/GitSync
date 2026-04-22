import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sprintf/sprintf.dart';
import 'package:GitSync/api/manager/git_manager.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/providers/riverpod_providers.dart';
import 'package:GitSync/src/rust/api/git_manager.dart' as GitManagerRs;
import 'package:GitSync/ui/dialog/confirm_multi_cherry_pick.dart' as ConfirmMultiCherryPickDialog;
import 'package:GitSync/ui/dialog/confirm_squash_commits.dart' as ConfirmSquashCommitsDialog;

class CommitSelectActionBar extends ConsumerStatefulWidget {
  const CommitSelectActionBar({
    super.key,
    required this.selectMode,
    required this.selectedShas,
    required this.commits,
    required this.onReloadAll,
    required this.onExitSelectMode,
    required this.borderRadius,
  });

  final ValueNotifier<bool> selectMode;
  final ValueNotifier<Set<String>> selectedShas;
  final List<GitManagerRs.Commit> commits;
  final Future<void> Function() onReloadAll;
  final VoidCallback onExitSelectMode;
  final BorderRadius borderRadius;

  static bool canSquash(List<GitManagerRs.Commit> commits, Set<String> selectedShas) {
    if (selectedShas.length < 2) return false;
    if (commits.isEmpty || !selectedShas.contains(commits.first.reference)) return false;
    for (int i = 0; i < selectedShas.length; i++) {
      if (i >= commits.length || !selectedShas.contains(commits[i].reference)) return false;
    }
    return true;
  }

  @override
  ConsumerState<CommitSelectActionBar> createState() => _CommitSelectActionBarState();
}

class _CommitSelectActionBarState extends ConsumerState<CommitSelectActionBar> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  late final List<Animation<double>> _itemAnimations;
  bool _wasSelectMode = false;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: animMedium, vsync: this);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && mounted) {
        setState(() => _visible = false);
      }
    });
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Interval(0.0, 0.5, curve: Curves.easeOut),
      reverseCurve: Interval(0.0, 1.0, curve: Curves.easeIn),
    );
    _itemAnimations = List.generate(3, (i) {
      final start = 0.2 + i * 0.2;
      final end = (start + 0.4).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOut),
        reverseCurve: Interval(0.0, 0.5, curve: Curves.easeIn),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkSelectMode(bool inSelectMode) {
    if (inSelectMode && !_wasSelectMode) {
      _visible = true;
      _controller.forward(from: 0);
    } else if (!inSelectMode && _wasSelectMode) {
      _controller.reverse();
    }
    _wasSelectMode = inSelectMode;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.selectMode,
      builder: (context, inSelectMode, _) {
        _checkSelectMode(inSelectMode);
        if (!_visible) return SizedBox.shrink();
        return ValueListenableBuilder<Set<String>>(
          valueListenable: widget.selectedShas,
          builder: (context, shas, _) {
            final squashEnabled = CommitSelectActionBar.canSquash(widget.commits, shas);
            final cherryPickEnabled = shas.isNotEmpty;

            return ClipRRect(
              borderRadius: widget.borderRadius,
              child: SizeTransition(
                sizeFactor: _expandAnimation,
                axis: Axis.horizontal,
                axisAlignment: -1,
                child: Container(
                  decoration: BoxDecoration(color: colours.secondaryDark.withOpacity(0.5)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        padding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceSM),
                        style: ButtonStyle(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: widget.borderRadius)),
                          backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                        ),
                        constraints: BoxConstraints(),
                        onPressed: widget.onExitSelectMode,
                        icon: FaIcon(FontAwesomeIcons.xmark, size: textMD, color: colours.primaryLight),
                      ),
                      SizedBox(width: spaceXS),
                      FadeTransition(
                        opacity: _itemAnimations[0],
                        child: SlideTransition(
                          position: _itemAnimations[0].drive(Tween(begin: Offset(-0.5, 0), end: Offset.zero)),
                          child: Text(
                            sprintf(t.selectedCount, [shas.length]).toUpperCase(),
                            style: TextStyle(color: colours.primaryLight, fontSize: textXS, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      SizedBox(width: spaceXS),
                      FadeTransition(
                        opacity: _itemAnimations[1],
                        child: SlideTransition(
                          position: _itemAnimations[1].drive(Tween(begin: Offset(-0.5, 0), end: Offset.zero)),
                          child: TextButton.icon(
                            onPressed: cherryPickEnabled
                                ? () async {
                                    final currentBranch = ref.read(branchNameProvider).valueOrNull;
                                    final localBranchNames = ref.read(branchNamesProvider).valueOrNull?.keys.toList() ?? [];
                                    final selectedCommits = widget.commits.where((c) => shas.contains(c.reference)).toList().reversed.toList();
                                    if (context.mounted) {
                                      await ConfirmMultiCherryPickDialog.showDialog(context, selectedCommits, currentBranch, localBranchNames, (
                                        targetBranch,
                                      ) async {
                                        for (final commit in selectedCommits) {
                                          await GitManager.cherryPickCommit(commit.reference, targetBranch);
                                        }
                                        await widget.onReloadAll();
                                        widget.onExitSelectMode();
                                      });
                                    }
                                  }
                                : null,
                            icon: FaIcon(
                              FontAwesomeIcons.codeBranch,
                              size: textXS,
                              color: cherryPickEnabled ? colours.primaryInfo : colours.tertiaryDark,
                            ),
                            label: Text(
                              t.cherryPick.toUpperCase(),
                              style: TextStyle(
                                color: cherryPickEnabled ? colours.primaryInfo : colours.tertiaryDark,
                                fontSize: textXS,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: spaceXS, vertical: spaceXXXS),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM)),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: spaceXXXS),
                      FadeTransition(
                        opacity: _itemAnimations[2],
                        child: SlideTransition(
                          position: _itemAnimations[2].drive(Tween(begin: Offset(-0.5, 0), end: Offset.zero)),
                          child: TextButton.icon(
                            onPressed: squashEnabled
                                ? () async {
                                    final selectedCommits = widget.commits.where((c) => shas.contains(c.reference)).toList();
                                    final oldestCommit = selectedCommits.last;
                                    final combinedMessage = selectedCommits.reversed.map((c) => c.commitMessage).join('\n\n');
                                    if (context.mounted) {
                                      await ConfirmSquashCommitsDialog.showDialog(context, selectedCommits, combinedMessage, (squashMessage) async {
                                        await GitManager.squashCommits(oldestCommit.reference, squashMessage);
                                        await widget.onReloadAll();
                                        widget.onExitSelectMode();
                                      });
                                    }
                                  }
                                : null,
                            icon: FaIcon(
                              FontAwesomeIcons.layerGroup,
                              size: textXS,
                              color: squashEnabled ? colours.tertiaryWarning : colours.tertiaryDark,
                            ),
                            label: Text(
                              t.squash.toUpperCase(),
                              style: TextStyle(
                                color: squashEnabled ? colours.tertiaryWarning : colours.tertiaryDark,
                                fontSize: textXS,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: spaceXS, vertical: spaceXXXS),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
