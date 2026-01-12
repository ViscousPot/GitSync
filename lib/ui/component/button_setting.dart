import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/global.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ButtonSetting extends StatefulWidget {
  const ButtonSetting({
    required this.text,
    required this.icon,
    required this.onPressed,
    this.sub = false,
    this.loads = false,
    this.textColor,
    this.iconColor,
    this.buttonColor,
    this.initiallyExpanded = false,
    this.subButtons,
    super.key,
  });

  final bool sub;
  final bool loads;
  final bool initiallyExpanded;
  final String text;
  final IconData icon;
  final Color? textColor;
  final Color? iconColor;
  final Color? buttonColor;
  final List<Widget>? subButtons;
  final Future<void> Function()? onPressed;

  @override
  State<ButtonSetting> createState() => _ButtonSettingState();
}

class _ButtonSettingState extends State<ButtonSetting> {
  bool expanded = false;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    expanded = widget.initiallyExpanded;
  }

  void onPressed() async {
    if (mounted) setState(() => loading = true);
    if (widget.onPressed != null) await widget.onPressed!();
    if (mounted) setState(() => loading = false);
  }

  Widget getIcon() => widget.loads && loading
      ? SizedBox.square(
          dimension: textXL,
          child: CircularProgressIndicator(padding: EdgeInsets.all(spaceXXXXS), color: widget.iconColor ?? colours.primaryLight),
        )
      : FaIcon(widget.icon, color: widget.iconColor ?? colours.primaryLight, size: textXL);

  @override
  Widget build(BuildContext context) {
    return widget.subButtons == null || widget.subButtons!.isEmpty
        ? TextButton.icon(
            onPressed: widget.onPressed != null ? onPressed : null,
            style: ButtonStyle(
              alignment: Alignment.centerLeft,
              backgroundColor: WidgetStatePropertyAll(widget.buttonColor ?? colours.tertiaryDark),
              padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceMD)),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: widget.sub ? BorderRadius.zero : BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
              ),
            ),
            icon: getIcon(),
            label: Padding(
              padding: EdgeInsets.only(left: spaceXS),
              child: Text(
                widget.text.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: widget.textColor ?? colours.primaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
              ),
            ),
          )
        : Container(
            width: double.infinity,
            decoration: BoxDecoration(borderRadius: BorderRadius.all(cornerRadiusMD), color: widget.buttonColor ?? colours.tertiaryDark),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextButton.icon(
                      onPressed: widget.onPressed != null ? onPressed : null,
                      style: ButtonStyle(
                        alignment: Alignment.centerLeft,
                        backgroundColor: WidgetStatePropertyAll(widget.buttonColor ?? colours.tertiaryDark),
                        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceMD)),
                        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none)),
                      ),
                      icon: getIcon(),
                      label: Padding(
                        padding: EdgeInsets.only(left: spaceXS),
                        child: Text(
                          widget.text.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: widget.textColor ?? colours.primaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration: Duration(milliseconds: 200),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: expanded ? widget.subButtons! : []),
                    ),
                  ],
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: IconButton(
                    onPressed: () => setState(() {
                      expanded = !expanded;
                    }),
                    style: ButtonStyle(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: WidgetStatePropertyAll(widget.buttonColor ?? colours.tertiaryDark),
                      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceMD)),
                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none)),
                    ),
                    icon: FaIcon(
                      expanded ? FontAwesomeIcons.caretUp : FontAwesomeIcons.caretDown,
                      color: widget.iconColor ?? colours.primaryLight,
                      size: textLG,
                    ),
                  ),
                ),
              ],
            ),
          );
  }
}
