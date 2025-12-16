import 'dart:async';

import 'package:GitSync/api/manager/git_manager.dart';
import 'package:flutter/material.dart';
import 'package:GitSync/global.dart';
import 'package:sprintf/sprintf.dart';
import '../../../constant/colors.dart';
import '../../../constant/dimens.dart';
import '../../../src/rust/api/git_manager.dart' as GitManagerRs;
import 'package:timeago/timeago.dart' as timeago;

import '../dialog/diff_view.dart' as DiffViewDialog;

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
  const ItemCommit(this.commit, this.prevCommit, {super.key});

  final GitManagerRs.Commit commit;
  final GitManagerRs.Commit? prevCommit;

  @override
  State<ItemCommit> createState() => _ItemCommit();
}

class _ItemCommit extends State<ItemCommit> {
  late Timer _timer;
  late String _relativeCommitDate;

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

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) => Container(
        margin: orientation == Orientation.portrait ? EdgeInsets.only(top: spaceSM) : EdgeInsets.only(bottom: spaceSM),
        child: TextButton(
          onPressed: () async {
            print(widget.commit.reference);
            print(widget.prevCommit?.reference);

            final diff = await GitManager.getCommitDiff(widget.commit.reference, widget.prevCommit?.reference);

            DiffViewDialog.showDialog(context, diff, widget.commit.reference.substring(0, 7), (widget.commit, widget.prevCommit));
          },
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(
              widget.commit.unpushed
                  ? tertiaryInfo
                  : widget.commit.unpulled
                  ? tertiaryWarning
                  : tertiaryDark,
            ),
            padding: WidgetStatePropertyAll(EdgeInsets.zero),
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM), side: BorderSide.none)),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          clipBehavior: Clip.antiAlias,
          child: CustomPaint(
            painter: ChevronPainter(
              color: widget.commit.unpushed
                  ? secondaryInfo.withAlpha(70)
                  : widget.commit.unpulled
                  ? secondaryWarning.withAlpha(70)
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
                              color: widget.commit.unpulled || widget.commit.unpushed ? secondaryDark : primaryLight,
                              fontSize: textMD,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            "${demo ? "ViscousTests" : widget.commit.authorUsername} ${t.committed} $_relativeCommitDate",
                            style: TextStyle(
                              color: widget.commit.unpulled || widget.commit.unpushed ? tertiaryDark : secondaryLight,
                              fontSize: textSM,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: spaceXS),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: widget.commit.unpulled || widget.commit.unpushed ? tertiaryDark : secondaryLight,
                            borderRadius: BorderRadius.all(cornerRadiusXS),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: spaceXS, vertical: spaceXXXS),
                          child: Text(
                            (widget.commit.reference).substring(0, 7).toUpperCase(),
                            style: TextStyle(
                              color: widget.commit.unpulled || widget.commit.unpushed ? secondaryLight : tertiaryDark,
                              fontSize: textXS,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: spaceXXXS),
                        Row(
                          children: [
                            Text(
                              sprintf(t.additions, [widget.commit.additions]),
                              style: TextStyle(
                                color: widget.commit.unpulled || widget.commit.unpushed ? secondaryPositive : tertiaryPositive,
                                fontSize: textXS,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(width: spaceSM),
                            Text(
                              sprintf(t.deletions, [widget.commit.deletions]),
                              style: TextStyle(
                                color: widget.commit.unpulled || widget.commit.unpushed ? primaryNegative : tertiaryNegative,
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
    );
  }
}
