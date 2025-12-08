import 'package:GitSync/ui/component/group_sync_settings.dart';
import 'package:flutter/material.dart';
import '../../../api/helper.dart';
import '../../../constant/colors.dart';
import '../../../constant/dimens.dart';
import '../../../constant/strings.dart';
import '../../../global.dart';

class SyncSettingsMain extends StatefulWidget {
  const SyncSettingsMain({super.key});

  @override
  State<SyncSettingsMain> createState() => _SyncSettingsMain();
}

class _SyncSettingsMain extends State<SyncSettingsMain> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final _controller = ScrollController();
  bool atTop = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.addListener(() {
      atTop = _controller.offset <= 0;
      setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: getBackButton(context, () => Navigator.of(context).canPop() ? Navigator.pop(context) : null),
        centerTitle: true,
        title: Text(
          t.syncSettings.toUpperCase(),
          style: TextStyle(color: primaryLight, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: spaceMD),
        child: SingleChildScrollView(
          controller: _controller,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[GroupSyncSettings()],
          ),
        ),
      ),
    );
  }
}

Route createSyncSettingsMainRoute() {
  return PageRouteBuilder(
    settings: const RouteSettings(name: sync_settings_main),
    pageBuilder: (context, animation, secondaryAnimation) => SyncSettingsMain(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      const curve = Curves.ease;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}
