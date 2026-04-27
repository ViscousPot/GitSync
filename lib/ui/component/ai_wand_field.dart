import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/providers/riverpod_providers.dart';
import 'package:GitSync/ui/dialog/base_alert_dialog.dart';

class AiWandField extends ConsumerStatefulWidget {
  final Widget child;
  final Future<void> Function()? onPressed;
  final bool multiline;
  final bool enabled;

  const AiWandField({super.key, required this.child, this.onPressed, this.multiline = false, this.enabled = true});

  @override
  ConsumerState<AiWandField> createState() => _AiWandFieldState();
}

class _AiWandFieldState extends ConsumerState<AiWandField> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(aiFeaturesEnabledProvider).valueOrNull ?? true;
    if (!enabled) return widget.child;
    return Stack(
      children: [
        widget.child,
        Positioned(
          right: 0,
          top: 0,
          bottom: widget.multiline ? null : 0,
          child: IconButton(
            padding: widget.multiline ? EdgeInsets.all(spaceSM) : EdgeInsets.symmetric(horizontal: spaceSM),
            style: ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM))),
            ),
            constraints: BoxConstraints(),
            onPressed: (!widget.enabled || _loading)
                ? null
                : () async {
                    if (!ref.read(aiKeyConfiguredProvider)) {
                      final navigate = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => BaseAlertDialog(
                          title: Text(
                            t.aiSetupTitle,
                            style: TextStyle(color: colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
                          ),
                          content: Text(
                            t.aiSetupMsg,
                            style: TextStyle(color: colours.primaryLight, fontSize: textSM),
                          ),
                          actions: [
                            TextButton(
                              child: Text(
                                t.cancel.toUpperCase(),
                                style: TextStyle(color: colours.primaryLight, fontSize: textMD),
                              ),
                              onPressed: () => Navigator.pop(dialogContext, false),
                            ),
                            TextButton(
                              child: Text(
                                t.ok.toUpperCase(),
                                style: TextStyle(color: colours.tertiaryPositive, fontSize: textMD),
                              ),
                              onPressed: () => Navigator.pop(dialogContext, true),
                            ),
                          ],
                        ),
                      );
                      if (navigate == true) {
                        switchToAiTab?.call();
                      }
                      return;
                    }
                    if (widget.onPressed == null) return;
                    setState(() => _loading = true);
                    try {
                      await widget.onPressed!();
                    } catch (_) {
                      if (mounted) {
                        Fluttertoast.showToast(msg: "AI suggestion failed", toastLength: Toast.LENGTH_SHORT);
                      }
                    } finally {
                      if (mounted) setState(() => _loading = false);
                    }
                  },
            icon: _loading
                ? SizedBox(
                    width: textMD,
                    height: textMD,
                    child: CircularProgressIndicator(strokeWidth: 2, color: colours.tertiaryPositive),
                  )
                : FaIcon(FontAwesomeIcons.wandMagicSparkles, size: textMD, color: widget.enabled ? colours.tertiaryPositive : colours.tertiaryDark),
          ),
        ),
      ],
    );
  }
}
