import 'dart:ui';

import 'package:GitSync/api/helper.dart';
import 'package:GitSync/constant/colors.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/global.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BaseAlertDialog extends StatefulWidget {
  final bool scrollable;
  const BaseAlertDialog({
    super.key,
    this.scrollable = false,
    this.expandable = false,
    // forward all AlertDialog params
    this.icon,
    this.iconPadding,
    this.iconColor,
    this.title,
    this.titlePadding,
    this.titleTextStyle,
    this.content,
    this.contentBuilder,
    this.contentPadding,
    this.contentTextStyle,
    this.actions,
    this.actionsPadding,
    this.actionsAlignment,
    this.actionsOverflowAlignment,
    this.actionsOverflowDirection,
    this.actionsOverflowButtonSpacing,
    this.buttonPadding,
    this.backgroundColor,
    this.elevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.semanticLabel,
    this.insetPadding,
    this.clipBehavior,
    this.shape,
    this.alignment,
  });

  final bool expandable;
  final Widget? icon;
  final EdgeInsetsGeometry? iconPadding;
  final Color? iconColor;
  final Widget? title;
  final EdgeInsetsGeometry? titlePadding;
  final TextStyle? titleTextStyle;
  final Widget? content;
  final Widget Function(bool expanded)? contentBuilder;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? contentTextStyle;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? actionsPadding;
  final MainAxisAlignment? actionsAlignment;
  final OverflowBarAlignment? actionsOverflowAlignment;
  final VerticalDirection? actionsOverflowDirection;
  final double? actionsOverflowButtonSpacing;
  final EdgeInsetsGeometry? buttonPadding;
  final Color? backgroundColor;
  final double? elevation;
  final Color? shadowColor;
  final Color? surfaceTintColor;
  final String? semanticLabel;
  final EdgeInsets? insetPadding;
  final Clip? clipBehavior;
  final ShapeBorder? shape;
  final AlignmentGeometry? alignment;

  @override
  State<BaseAlertDialog> createState() => _BaseAlertDialogState();
}

class _BaseAlertDialogState extends State<BaseAlertDialog> {
  bool expanded = false;

  @override
  void initState() {
    initAsync(() async {
      expanded = widget.expandable && await uiSettingsManager.getClientModeEnabled();
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final titlePadding = widget.titlePadding ?? EdgeInsets.only(top: spaceSM * 2, left: spaceSM * 2, right: spaceSM * 2);

    return Stack(
      children: [
        widget.expandable
            ? Positioned.fill(
                child: IgnorePointer(
                  ignoring: true,
                  child: AnimatedBuilder(
                    animation: ModalRoute.of(context)!.animation!,
                    builder: (context, _) {
                      return Opacity(
                        opacity: ModalRoute.of(context)!.animation!.value,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black54],
                              stops: [0.0, 0.15], // harsher transition
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              )
            : SizedBox.shrink(),
        CustomAlertDialog(
          icon: widget.icon,
          iconPadding: widget.iconPadding,
          iconColor: widget.iconColor,
          titlePadding: EdgeInsets.zero,
          expanded: expanded,
          title: Stack(
            alignment: Alignment.centerLeft,
            clipBehavior: Clip.none,
            children: [
              Padding(padding: titlePadding, child: widget.title ?? SizedBox()),
              widget.expandable
                  ? Positioned(
                      top: spaceXXXS,
                      right: spaceXXXS,
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              expanded = !expanded;
                              setState(() {});
                            },

                            icon: FaIcon(expanded ? FontAwesomeIcons.downLeftAndUpRightToCenter : FontAwesomeIcons.upRightAndDownLeftFromCenter),
                            style: ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            color: primaryLight,
                            disabledColor: tertiaryLight,
                            iconSize: textMD,
                          ),
                          expanded
                              ? IconButton(
                                  onPressed: () {
                                    Navigator.of(context).canPop() ? Navigator.pop(context) : null;
                                  },

                                  icon: FaIcon(FontAwesomeIcons.xmark),
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  color: primaryLight,
                                  disabledColor: tertiaryLight,
                                  iconSize: textLG,
                                )
                              : SizedBox.shrink(),
                        ],
                      ),
                    )
                  : SizedBox.shrink(),
            ],
          ),
          content: widget.contentBuilder == null ? widget.content : widget.contentBuilder!(expanded),
          contentPadding:
              widget.contentPadding ??
              EdgeInsets.only(left: spaceSM * 2, right: spaceSM * 2, top: spaceSM, bottom: (widget.actions?.isEmpty ?? true) ? spaceLG : 0),
          actions: widget.actions,
          actionsAlignment: widget.actionsAlignment,
          actionsPadding: widget.contentPadding ?? EdgeInsets.only(right: spaceSM * 2, left: spaceSM * 2, bottom: spaceSM, top: spaceSM),
          insetPadding: widget.insetPadding ?? EdgeInsets.all(expanded ? 0 : spaceLG),
          backgroundColor: widget.backgroundColor ?? primaryDark,
          shape: widget.shape ?? RoundedRectangleBorder(borderRadius: expanded ? BorderRadius.zero : BorderRadius.all(cornerRadiusMD)),
          scrollable: widget.scrollable,
        ),
      ],
    );
  }
}

class CustomAlertDialog extends AlertDialog {
  const CustomAlertDialog({
    super.key,
    super.icon,
    super.iconPadding,
    super.iconColor,
    super.title,
    super.titlePadding,
    super.titleTextStyle,
    super.content,
    super.contentPadding,
    super.contentTextStyle,
    super.actions,
    super.actionsPadding,
    super.actionsAlignment,
    super.actionsOverflowAlignment,
    super.actionsOverflowDirection,
    super.actionsOverflowButtonSpacing,
    super.buttonPadding,
    super.backgroundColor,
    super.elevation,
    super.shadowColor,
    super.surfaceTintColor,
    super.semanticLabel,
    super.insetPadding,
    super.clipBehavior,
    super.shape,
    required this.expanded,
    super.alignment,
    super.scrollable = false,
  });

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    final ThemeData theme = Theme.of(context);

    final DialogThemeData dialogTheme = DialogTheme.of(context);
    final DialogThemeData defaults = theme.useMaterial3 ? _DialogDefaultsM3(context) : _DialogDefaultsM2(context);

    String? label = semanticLabel;
    switch (theme.platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        label ??= MaterialLocalizations.of(context).alertDialogLabel;
    }

    // The paddingScaleFactor is used to adjust the padding of Dialog's
    // children.
    const double fontSizeToScale = 14.0;
    final double effectiveTextScale = MediaQuery.textScalerOf(context).scale(fontSizeToScale) / fontSizeToScale;
    final double paddingScaleFactor = _scalePadding(effectiveTextScale);
    final TextDirection? textDirection = Directionality.maybeOf(context);

    Widget? iconWidget;
    Widget? titleWidget;
    Widget? contentWidget;
    Widget? actionsWidget;

    if (icon != null) {
      final bool belowIsTitle = title != null;
      final bool belowIsContent = !belowIsTitle && content != null;
      final EdgeInsets defaultIconPadding = EdgeInsets.only(
        left: 24.0,
        top: 24.0,
        right: 24.0,
        bottom: belowIsTitle
            ? 16.0
            : belowIsContent
            ? 0.0
            : 24.0,
      );
      final EdgeInsets effectiveIconPadding = iconPadding?.resolve(textDirection) ?? defaultIconPadding;
      iconWidget = Padding(
        padding: EdgeInsets.only(
          left: effectiveIconPadding.left * paddingScaleFactor,
          right: effectiveIconPadding.right * paddingScaleFactor,
          top: effectiveIconPadding.top * paddingScaleFactor,
          bottom: effectiveIconPadding.bottom,
        ),
        child: IconTheme(
          data: IconThemeData(color: iconColor ?? dialogTheme.iconColor ?? defaults.iconColor),
          child: icon!,
        ),
      );
    }

    if (title != null) {
      final EdgeInsets defaultTitlePadding = EdgeInsets.only(
        left: 24.0,
        top: icon == null ? 24.0 : 0.0,
        right: 24.0,
        bottom: content == null ? 20.0 : 0.0,
      );
      final EdgeInsets effectiveTitlePadding = titlePadding?.resolve(textDirection) ?? defaultTitlePadding;
      titleWidget = Padding(
        padding: EdgeInsets.only(
          left: effectiveTitlePadding.left * paddingScaleFactor,
          right: effectiveTitlePadding.right * paddingScaleFactor,
          top: icon == null ? effectiveTitlePadding.top * paddingScaleFactor : effectiveTitlePadding.top,
          bottom: effectiveTitlePadding.bottom,
        ),
        child: DefaultTextStyle(
          style: titleTextStyle ?? dialogTheme.titleTextStyle ?? defaults.titleTextStyle!,
          textAlign: icon == null ? TextAlign.start : TextAlign.center,
          child: Semantics(
            // For iOS platform, the focus always lands on the title.
            // Set nameRoute to false to avoid title being announce twice.
            namesRoute: label == null && theme.platform != TargetPlatform.iOS,
            container: true,
            child: title,
          ),
        ),
      );
    }

    if (content != null) {
      final EdgeInsets defaultContentPadding = EdgeInsets.only(left: 24.0, top: theme.useMaterial3 ? 16.0 : 20.0, right: 24.0, bottom: 24.0);
      final EdgeInsets effectiveContentPadding = contentPadding?.resolve(textDirection) ?? defaultContentPadding;
      contentWidget = Padding(
        padding: EdgeInsets.only(
          left: effectiveContentPadding.left * paddingScaleFactor,
          right: effectiveContentPadding.right * paddingScaleFactor,
          top: title == null && icon == null ? effectiveContentPadding.top * paddingScaleFactor : effectiveContentPadding.top,
          bottom: effectiveContentPadding.bottom,
        ),
        child: DefaultTextStyle(
          style: contentTextStyle ?? dialogTheme.contentTextStyle ?? defaults.contentTextStyle!,
          child: Semantics(container: true, explicitChildNodes: true, child: content),
        ),
      );
    }

    if (actions != null) {
      final double spacing = (buttonPadding?.horizontal ?? 16) / 2;
      actionsWidget = Padding(
        padding:
            actionsPadding ??
            dialogTheme.actionsPadding ??
            (theme.useMaterial3 ? defaults.actionsPadding! : defaults.actionsPadding!.add(EdgeInsets.all(spacing))),
        child: OverflowBar(
          alignment: actionsAlignment ?? MainAxisAlignment.end,
          spacing: spacing,
          overflowAlignment: actionsOverflowAlignment ?? OverflowBarAlignment.end,
          overflowDirection: actionsOverflowDirection ?? VerticalDirection.down,
          overflowSpacing: actionsOverflowButtonSpacing ?? 0,
          children: actions!,
        ),
      );
    }

    List<Widget> columnChildren;
    if (scrollable) {
      columnChildren = <Widget>[
        if (title != null || content != null)
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (icon != null) iconWidget!,
                  if (title != null) titleWidget!,
                  if (content != null) Flexible(child: contentWidget!),
                ],
              ),
            ),
          ),
        if (actions != null) actionsWidget!,
      ];
    } else {
      columnChildren = <Widget>[
        if (icon != null) iconWidget!,
        if (title != null) titleWidget!,
        if (content != null) Flexible(child: contentWidget!),
        if (actions != null) actionsWidget!,
      ];
    }

    Widget dialogChild = IntrinsicWidth(
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: columnChildren),
    );

    if (label != null) {
      dialogChild = Semantics(scopesRoute: true, explicitChildNodes: true, namesRoute: true, label: label, child: dialogChild);
    }

    return Dialog(
      backgroundColor: backgroundColor,
      elevation: elevation,
      shadowColor: shadowColor,
      surfaceTintColor: surfaceTintColor,
      insetPadding: insetPadding,
      clipBehavior: clipBehavior,
      shape: shape,
      alignment: alignment,
      child: AnimatedSize(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: SizedBox(height: expanded ? MediaQuery.of(context).size.height : null, child: dialogChild),
      ),
    );
  }
}

double _scalePadding(double textScaleFactor) {
  final double clampedTextScaleFactor = clampDouble(textScaleFactor, 1.0, 2.0);
  // The final padding scale factor is clamped between 1/3 and 1. For example,
  // a non-scaled padding of 24 will produce a padding between 24 and 8.
  return lerpDouble(1.0, 1.0 / 3.0, clampedTextScaleFactor - 1.0)!;
}

class _DialogDefaultsM3 extends DialogThemeData {
  _DialogDefaultsM3(this.context)
    : super(
        alignment: Alignment.center,
        elevation: 6.0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(28.0))),
        clipBehavior: Clip.none,
      );

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;
  late final TextTheme _textTheme = Theme.of(context).textTheme;

  @override
  Color? get iconColor => _colors.secondary;

  @override
  Color? get backgroundColor => _colors.surfaceContainerHigh;

  @override
  Color? get shadowColor => Colors.transparent;

  @override
  Color? get surfaceTintColor => Colors.transparent;

  @override
  TextStyle? get titleTextStyle => _textTheme.headlineSmall;

  @override
  TextStyle? get contentTextStyle => _textTheme.bodyMedium;

  @override
  EdgeInsetsGeometry? get actionsPadding => const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0);
}

// Hand coded defaults based on Material Design 2.
class _DialogDefaultsM2 extends DialogThemeData {
  _DialogDefaultsM2(this.context)
    : super(
        alignment: Alignment.center,
        elevation: 24.0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4.0))),
        clipBehavior: Clip.none,
      );

  final BuildContext context;
  late final ThemeData theme = Theme.of(context);
  late final TextTheme textTheme = theme.textTheme;
  late final IconThemeData iconTheme = theme.iconTheme;

  @override
  Color? get iconColor => iconTheme.color;

  @override
  Color? get backgroundColor => theme.brightness == Brightness.dark ? Colors.grey[800]! : Colors.white;

  @override
  Color? get shadowColor => theme.shadowColor;

  @override
  TextStyle? get titleTextStyle => textTheme.titleLarge;

  @override
  TextStyle? get contentTextStyle => textTheme.titleMedium;

  @override
  EdgeInsetsGeometry? get actionsPadding => EdgeInsets.zero;
}
