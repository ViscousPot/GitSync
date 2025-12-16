import 'dart:async';

import 'package:GitSync/api/helper.dart';
import 'package:GitSync/api/logger.dart';
import 'package:GitSync/api/manager/git_manager.dart';
import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/constant/colors.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/ui/component/custom_showcase.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SyncLoader extends StatefulWidget {
  const SyncLoader({super.key, required this.syncProgressKey, required this.reload});

  final VoidCallback reload;
  final GlobalKey<State<StatefulWidget>> syncProgressKey;

  @override
  State<SyncLoader> createState() => _SyncLoaderState();
}

class _SyncLoaderState extends State<SyncLoader> {
  double opacity = 0.0;
  bool? previousLocked;
  bool locked = false;
  bool erroring = false;
  bool showCheck = false;

  Timer? hideCheckTimer;
  Timer? lockedTimer;

  @override
  void initState() {
    showCheck = false;
    opacity = 0.0;

    initAsync(() async {
      locked = await GitManager.isLocked(false);
      erroring = (await repoManager.getStringNullable(StorageKey.repoman_erroring))?.isNotEmpty == true;
      setState(() {});
      lockedTimer = Timer.periodic(const Duration(milliseconds: 200), (_) async {
        final newErroring = (await repoManager.getStringNullable(StorageKey.repoman_erroring))?.isNotEmpty == true;
        final newLocked = await GitManager.isLocked(false);

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
    hideCheckTimer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (previousLocked == true && locked == false) {
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
    } else if (locked == true) {
      showCheck = false;
      hideCheckTimer?.cancel();
    }

    previousLocked = locked;

    return GestureDetector(
      onLongPress: () async {
        final locks = await repoManager.getStringList(StorageKey.repoman_locks);
        final index = await repoManager.getInt(StorageKey.repoman_repoIndex);
        await repoManager.setStringList(StorageKey.repoman_locks, locks.where((lock) => lock != index.toString()).toList());
        gitSyncService.isScheduled = false;
        gitSyncService.isSyncing = false;
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
          Align(
            alignment: Alignment.center,
            child: CustomShowcase(
              globalKey: widget.syncProgressKey,
              description: t.syncProgressHint,
              cornerRadius: cornerRadiusMax,
              child: Container(
                width: spaceMD + spaceXS,
                height: spaceMD + spaceXS,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: tertiaryDark, width: 4),
                ),
              ),
            ),
          ),

          if (locked)
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: spaceMD + spaceXS,
                height: spaceMD + spaceXS,
                child: CircularProgressIndicator(
                  color: primaryLight,
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
                child: FaIcon(FontAwesomeIcons.circleExclamation, color: tertiaryNegative, size: spaceMD + spaceXS),
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: locked ? 0 : opacity,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            child: Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: spaceMD + spaceXS,
                height: spaceMD + spaceXS,
                child: FaIcon(FontAwesomeIcons.solidCircleCheck, color: primaryPositive, size: spaceMD + spaceXS),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
