import 'package:flutter/material.dart';
import '../../../constant/colors.dart';
import '../../../constant/dimens.dart';
import '../dialog/merge_conflict.dart' as MergeConflictDialog;
import 'package:GitSync/global.dart';

class ItemMergeConflict extends StatefulWidget {
  const ItemMergeConflict(this.conflictingPaths, this.conflictCallback, {super.key});

  final Function() conflictCallback;
  final List<String> conflictingPaths;

  @override
  State<ItemMergeConflict> createState() => _ItemMergeConflict();
}

class _ItemMergeConflict extends State<ItemMergeConflict> {
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
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: spaceSM),
      child: TextButton(
        onPressed: () {
          MergeConflictDialog.showDialog(context, widget.conflictingPaths).then((_) => widget.conflictCallback()).then((_) => setState(() {}));
        },
        style: ButtonStyle(
          alignment: Alignment.centerLeft,
          backgroundColor: WidgetStatePropertyAll(tertiaryNegative),
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
              style: TextStyle(color: primaryDark, fontSize: textMD, overflow: TextOverflow.ellipsis, fontWeight: FontWeight.bold),
            ),
            Text(t.mergeConflictItemMessage, style: TextStyle(color: secondaryDark, fontSize: textSM, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}
