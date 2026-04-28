import 'package:GitSync/api/logger.dart';
import 'package:GitSync/api/manager/git_manager.dart';
import 'package:flutter/material.dart';
import 'package:GitSync/src/rust/api/git_manager.dart' as GitManagerRs;
import '../../../constant/dimens.dart';
import '../dialog/merge_conflict.dart' as MergeConflictDialog;
import 'package:GitSync/global.dart';

class ItemMergeConflict extends StatefulWidget {
  const ItemMergeConflict(this.conflictingPaths, this.conflictCallback, this.clientModeEnabled, {super.key});

  final Function() conflictCallback;
  final List<(String, GitManagerRs.ConflictType)> conflictingPaths;
  final bool clientModeEnabled;

  @override
  State<ItemMergeConflict> createState() => _ItemMergeConflict();
}

class _ItemMergeConflict extends State<ItemMergeConflict> {
  bool isAborting = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: spaceSM),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                MergeConflictDialog.showDialog(context, widget.conflictingPaths).then((_) => widget.conflictCallback()).then((_) => setState(() {}));
              },
              style: ButtonStyle(
                alignment: Alignment.centerLeft,
                backgroundColor: WidgetStatePropertyAll(colours.tertiaryNegative),
                padding: WidgetStatePropertyAll(EdgeInsets.all(spaceSM)),
                shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM), side: BorderSide.none)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(
                    t.mergeConflict.toUpperCase(),
                    style: TextStyle(color: colours.primaryDark, fontSize: textMD, overflow: TextOverflow.ellipsis, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    t.mergeConflictItemMessage,
                    style: TextStyle(color: colours.secondaryDark, fontSize: textSM, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: spaceXXXS,
            top: spaceXXXS,
            bottom: spaceXXXS,
            child: TextButton(
              onPressed: () async {
                if (isAborting) return;

                isAborting = true;
                setState(() {});

                await runGitOperation(LogType.AbortMerge, (event) => event);
                widget.conflictCallback();
              },
              style: ButtonStyle(
                alignment: Alignment.center,
                visualDensity: VisualDensity.compact,
                backgroundColor: WidgetStatePropertyAll(colours.secondaryNegative),
                padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceSM)),
                shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM), side: BorderSide.none)),
              ),
              child: isAborting
                  ? SizedBox.square(
                      dimension: spaceMD,
                      child: CircularProgressIndicator(color: colours.tertiaryNegative),
                    )
                  : Text(
                      ((widget.clientModeEnabled ? t.abortMerge : t.resolveLater).split(" ").join("\n")).toUpperCase(),
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: colours.tertiaryNegative,
                        fontSize: textSM,
                        overflow: TextOverflow.ellipsis,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
