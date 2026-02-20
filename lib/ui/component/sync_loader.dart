import 'dart:async';

import 'package:GitSync/api/helper.dart';
import 'package:GitSync/api/logger.dart';
import 'package:GitSync/api/manager/git_manager.dart';
import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/src/rust/api/git_manager.dart' as GitManagerRs;
import 'package:GitSync/ui/component/custom_showcase.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';

class SyncLoader extends StatefulWidget {
  const SyncLoader({super.key, required this.syncProgressKey, required this.reload});

  final VoidCallback reload;
  final GlobalKey<State<StatefulWidget>> syncProgressKey;

  @override
  State<SyncLoader> createState() => _SyncLoaderState();
}

class _SyncLoaderState extends State<SyncLoader> with TickerProviderStateMixin {
  double opacity = 0.0;
  String? previousLocked;
  String? locked;
  bool get isLocked => locked != null;
  bool erroring = false;
  bool showCheck = false;

  Timer? hideCheckTimer;
  Timer? lockedTimer;

  late final AnimationController _arrowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));

  late final Animation<double> _arrowAnimation = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
    TweenSequenceItem(tween: ConstantTween(0.0), weight: 20),
    TweenSequenceItem(tween: Tween(begin: 0.0, end: -1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 40),
  ]).animate(_arrowController);

  double get _arrowOpacity => 1.0 - _arrowAnimation.value.abs();

  @override
  void initState() {
    showCheck = false;
    opacity = 0.0;

    if (isLocked) _arrowController.repeat();

    initAsync(() async {
      try {
        locked = await GitManager.isLocked(waitForUnlock: false);
      } catch (e) {
        locked = null;
      }
      erroring = (await repoManager.getStringNullable(StorageKey.repoman_erroring))?.isNotEmpty == true;
      setState(() {});
      lockedTimer = Timer.periodic(const Duration(milliseconds: 200), (_) async {
        final newErroring = (await repoManager.getStringNullable(StorageKey.repoman_erroring))?.isNotEmpty == true;
        String? newLocked;
        try {
          newLocked = await GitManager.isLocked(waitForUnlock: false);
        } catch (e) {}

        if (newErroring != erroring) {
          erroring = newErroring;
          setState(() {});
        }

        if (newLocked != locked) {
          locked = newLocked;
          setState(() {});
        }
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    _arrowController.dispose();
    hideCheckTimer?.cancel();
    lockedTimer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (previousLocked != null && locked == null) {
      Future.delayed(Duration(milliseconds: 10), () {
        widget.reload();
      });
      showCheck = true;
      Future.delayed(Duration(milliseconds: 10), () {
        opacity = 1.0;
        setState(() {});
      });
      hideCheckTimer?.cancel();
      hideCheckTimer = Timer(Duration(seconds: 2), () {
        showCheck = false;
        opacity = 0.0;
        setState(() {});
      });
    } else if (isLocked) {
      showCheck = false;
      hideCheckTimer?.cancel();
    }

    if (isLocked && !_arrowController.isAnimating) {
      _arrowController.repeat();
    } else if (!isLocked && _arrowController.isAnimating) {
      _arrowController.stop();
    }

    print("//// locked $locked");
    previousLocked = locked;

    return GestureDetector(
      onLongPress: () async {
        try {
          await GitManagerRs.clearStaleLocks(queueDir: (await getApplicationSupportDirectory()).path, force: true);
        } catch (e) {}
        gitSyncService.isScheduled = false;
        gitSyncService.isSyncing = false;
        locked = null;
        setState(() {});
      },
      onTap: () async {
        if ((await repoManager.getStringNullable(StorageKey.repoman_erroring))?.isNotEmpty == true) {
          await Logger.dismissError(context);
        } else {
          await openLogViewer(context);
        }
        setState(() {});
      },
      child: Stack(
        children: [
          if (["Commit", "PushToRepo", "ForcePush", "UploadAndOverwrite", "UploadChanges"].contains(locked))
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: spaceMD + spaceXS,
                height: spaceMD + spaceXS,
                child: ClipOval(
                  child: OverflowBox(
                    maxWidth: (spaceMD + spaceXS),
                    maxHeight: (spaceMD + spaceXS),
                    child: AnimatedBuilder(
                      animation: _arrowController,
                      builder: (context, _) {
                        return Transform.translate(
                          offset: Offset(0, _arrowAnimation.value * (spaceMD + spaceXS)),
                          child: SizedBox(
                            width: spaceMD + spaceXS,
                            height: spaceMD + spaceXS,
                            child: Stack(
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.circleUp,
                                  size: spaceMD + spaceXS,
                                  color: colours.primaryLight.withValues(alpha: _arrowOpacity),
                                ),
                                IgnorePointer(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: colours.primaryDark, width: 6, strokeAlign: BorderSide.strokeAlignCenter),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          if (["FetchRemote", "PullFromRepo", "ForcePull", "DownloadAndOverwrite", "DownloadChanges"].contains(locked))
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: spaceMD + spaceXS,
                height: spaceMD + spaceXS,
                child: ClipOval(
                  child: OverflowBox(
                    maxWidth: (spaceMD + spaceXS),
                    maxHeight: (spaceMD + spaceXS),
                    child: AnimatedBuilder(
                      animation: _arrowController,
                      builder: (context, _) {
                        return Transform.translate(
                          offset: Offset(0, -_arrowAnimation.value * (spaceMD + spaceXS)),
                          child: SizedBox(
                            width: spaceMD + spaceXS,
                            height: spaceMD + spaceXS,
                            child: Stack(
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.circleDown,
                                  size: spaceMD + spaceXS,
                                  color: colours.primaryLight.withValues(alpha: _arrowOpacity),
                                ),
                                IgnorePointer(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: colours.primaryDark, width: 6, strokeAlign: BorderSide.strokeAlignCenter),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          Align(
            alignment: Alignment.center,
            child: CustomShowcase(
              globalKey: widget.syncProgressKey,
              cornerRadius: cornerRadiusMax,
              richContent: ShowcaseTooltipContent(
                title: t.showcaseSyncProgressTitle,
                subtitle: t.showcaseSyncProgressSubtitle,
                featureRows: [
                  ShowcaseFeatureRow(icon: FontAwesomeIcons.solidCircleDown, text: t.showcaseSyncProgressFeatureWatch),
                  ShowcaseFeatureRow(icon: FontAwesomeIcons.solidCircleCheck, text: t.showcaseSyncProgressFeatureConfirm),
                  ShowcaseFeatureRow(icon: FontAwesomeIcons.bug, text: t.showcaseSyncProgressFeatureErrors),
                ],
              ),
              child: Container(
                width: spaceMD + spaceXS,
                height: spaceMD + spaceXS,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colours.tertiaryDark, width: 4),
                ),
              ),
            ),
          ),
          if (isLocked)
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: spaceMD + spaceXS,
                height: spaceMD + spaceXS,
                child: CircularProgressIndicator(
                  color: colours.primaryLight,
                  padding: EdgeInsets.zero,
                  strokeAlign: BorderSide.strokeAlignInside,
                  strokeWidth: 4.2,
                ),
              ),
            ),
          AnimatedOpacity(
            opacity: erroring ? 1 : 0,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            child: Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: spaceMD + spaceXS,
                height: spaceMD + spaceXS,
                child: FaIcon(FontAwesomeIcons.circleExclamation, color: colours.tertiaryNegative, size: spaceMD + spaceXS),
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: isLocked ? 0 : opacity,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            child: Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: spaceMD + spaceXS,
                height: spaceMD + spaceXS,
                child: FaIcon(FontAwesomeIcons.solidCircleCheck, color: colours.primaryPositive, size: spaceMD + spaceXS),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
