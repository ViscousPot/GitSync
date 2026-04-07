import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/global.dart';
import '../../../constant/dimens.dart';
import '../../../constant/strings.dart';
import '../dialog/confirm_branch_checkout.dart' as ConfirmBranchCheckoutDialog;
import '../dialog/confirm_delete_branch.dart' as ConfirmDeleteBranchDialog;
import '../dialog/rename_branch.dart' as RenameBranchDialog;

class BranchSelector extends StatefulWidget {
  const BranchSelector({
    super.key,
    required this.branchName,
    required this.branchNames,
    required this.hasConflicts,
    required this.onCheckoutBranch,
    required this.onRenameBranch,
    required this.onDeleteBranch,
    this.onCreateBranch,
    this.dropdownDecoration,
    this.showLabel = true,
  });

  final String? branchName;
  final Map<String, String> branchNames;
  final bool hasConflicts;
  final Future<void> Function(String branchName) onCheckoutBranch;
  final Future<void> Function(String oldName, String newName) onRenameBranch;
  final Future<void> Function(String branchName) onDeleteBranch;
  final VoidCallback? onCreateBranch;
  final BoxDecoration? dropdownDecoration;
  final bool showLabel;

  @override
  State<BranchSelector> createState() => _BranchSelectorState();
}

class _BranchSelectorState extends State<BranchSelector> {
  final GlobalKey _branchSelectorKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final hasBranch = widget.branchNames.containsKey(widget.branchName);
    final showActions = widget.branchNames.length > 1;

    return Hero(
      tag: hero_branch_row,
      child: Material(
        type: MaterialType.transparency,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: widget.dropdownDecoration,
                child: Stack(
                  children: [
                    GestureDetector(
                      key: _branchSelectorKey,
                      onTap: widget.hasConflicts
                          ? null
                          : () {
                              final otherBranches = Map.of(widget.branchNames)..remove(widget.branchName);
                              if (otherBranches.isEmpty) return;
                              final renderBox = _branchSelectorKey.currentContext!.findRenderObject() as RenderBox;
                              final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
                              final size = renderBox.size;
                              final position = RelativeRect.fromRect(
                                Rect.fromPoints(
                                  renderBox.localToGlobal(Offset(0, size.height), ancestor: overlay),
                                  renderBox.localToGlobal(size.bottomRight(Offset.zero), ancestor: overlay),
                                ),
                                Offset.zero & overlay.size,
                              );
                              showMenu<String>(
                                context: context,
                                position: position,
                                color: colours.secondaryDark,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM)),
                                constraints: BoxConstraints(maxHeight: 250, minWidth: size.width),
                                items: otherBranches.entries.map((entry) {
                                  final item = entry.key;
                                  final branchColor = entry.value == 'local'
                                      ? colours.tertiaryInfo
                                      : entry.value == 'remote'
                                      ? colours.tertiaryWarning
                                      : colours.primaryLight;
                                  return _RawPopupMenuEntry<String>(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceXS),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTap: () async {
                                                Navigator.of(context).pop();
                                                await ConfirmBranchCheckoutDialog.showDialog(context, item, () async {
                                                  await widget.onCheckoutBranch(item);
                                                });
                                              },
                                              child: Text(
                                                item.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: textSM,
                                                  color: branchColor,
                                                  fontWeight: FontWeight.bold,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (showActions) ...[
                                            SizedBox(width: spaceXS),
                                            GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTap: () {
                                                Navigator.of(context).pop();
                                                RenameBranchDialog.showDialog(context, item, (newName) async {
                                                  await widget.onRenameBranch(item, newName);
                                                });
                                              },
                                              child: Container(
                                                padding: EdgeInsets.all(spaceXXS),
                                                decoration: BoxDecoration(
                                                  color: colours.tertiaryDark,
                                                  borderRadius: BorderRadius.all(cornerRadiusSM),
                                                ),
                                                child: FaIcon(FontAwesomeIcons.pen, size: textXS, color: colours.primaryLight),
                                              ),
                                            ),
                                            SizedBox(width: spaceXXS),
                                            GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTap: () {
                                                Navigator.of(context).pop();
                                                ConfirmDeleteBranchDialog.showDialog(context, item, () async {
                                                  await widget.onDeleteBranch(item);
                                                });
                                              },
                                              child: Container(
                                                padding: EdgeInsets.all(spaceXXS),
                                                decoration: BoxDecoration(
                                                  color: colours.tertiaryDark,
                                                  borderRadius: BorderRadius.all(cornerRadiusSM),
                                                ),
                                                child: FaIcon(FontAwesomeIcons.solidTrashCan, size: textXS, color: colours.tertiaryNegative),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceXS),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                hasBranch
                                    ? (widget.branchName ?? '').toUpperCase()
                                    : widget.branchNames.isEmpty
                                        ? t.unbornBranch.toUpperCase()
                                        : t.detachedHead.toUpperCase(),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: textMD,
                                  fontWeight: FontWeight.bold,
                                  color: hasBranch
                                      ? (widget.hasConflicts
                                            ? colours.tertiaryLight
                                            : (widget.branchNames[widget.branchName] == 'local'
                                                  ? colours.tertiaryInfo
                                                  : widget.branchNames[widget.branchName] == 'remote'
                                                  ? colours.tertiaryWarning
                                                  : colours.primaryLight))
                                      : colours.secondaryLight,
                                ),
                              ),
                            ),
                            FaIcon(
                              FontAwesomeIcons.caretDown,
                              size: textSM,
                              color: !showActions
                                  ? Colors.transparent
                                  : widget.hasConflicts
                                  ? colours.tertiaryLight
                                  : colours.primaryLight,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (widget.showLabel)
                      Positioned(
                        top: -spaceXXXXS,
                        left: spaceXS,
                        child: Text(
                          t.currentBranch.toUpperCase(),
                          style: TextStyle(color: colours.tertiaryLight, fontSize: textXXS, fontWeight: FontWeight.w900),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: widget.onCreateBranch,
              style: ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceXS)),
                shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM), side: BorderSide.none)),
              ),
              constraints: BoxConstraints(),
              icon: FaIcon(
                FontAwesomeIcons.solidSquarePlus,
                color: widget.onCreateBranch != null ? colours.primaryLight : colours.secondaryLight,
                size: textXL,
                semanticLabel: t.addBranchLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RawPopupMenuEntry<T> extends PopupMenuEntry<T> {
  const _RawPopupMenuEntry({required this.child});

  final Widget child;

  @override
  double get height => 0;

  @override
  bool represents(T? value) => false;

  @override
  State<_RawPopupMenuEntry<T>> createState() => _RawPopupMenuEntryState<T>();
}

class _RawPopupMenuEntryState<T> extends State<_RawPopupMenuEntry<T>> {
  @override
  Widget build(BuildContext context) => widget.child;
}
