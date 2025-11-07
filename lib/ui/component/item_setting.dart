import 'dart:async';

import 'package:flutter/material.dart';
import '../../../api/helper.dart';
import '../../../constant/colors.dart';
import '../../../constant/dimens.dart';

class ItemSetting extends StatefulWidget {
  const ItemSetting({
    super.key,
    required this.title,
    required this.getFn,
    required this.setFn,
    this.description,
    this.hint,
    this.maxLines = 1,
    this.minLines = 1,
    this.isTextArea = false,
  });

  final String title;
  final String? description;
  final String? hint;
  final bool isTextArea;
  final int? maxLines;
  final int? minLines;
  final Future<String> Function() getFn;
  final void Function(String) setFn;

  @override
  State<ItemSetting> createState() => _ItemSetting();
}

class _ItemSetting extends State<ItemSetting> {
  final controller = TextEditingController();

  @override
  void initState() {
    initAsync(() async => controller.text = await widget.getFn());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: spaceMD),
          child: Text(
            widget.title.toUpperCase(),
            style: TextStyle(color: primaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
          ),
        ),
        widget.description == null
            ? SizedBox.shrink()
            : Padding(
                padding: EdgeInsets.symmetric(horizontal: spaceMD),
                child: Text(
                  widget.description ?? "",
                  style: TextStyle(color: secondaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                ),
              ),
        SizedBox(height: spaceSM),
        widget.isTextArea
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM),
                decoration: BoxDecoration(color: tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusMD)),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: double.maxFinite),
                    child: TextField(
                      contextMenuBuilder: globalContextMenuBuilder,
                      controller: controller,
                      maxLines: widget.maxLines != null && widget.maxLines! < 1 ? null : widget.maxLines,
                      minLines: widget.minLines != null && widget.minLines! < 1 ? 4 : widget.minLines,
                      style: TextStyle(
                        color: primaryLight,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                        decorationThickness: 0,
                        fontSize: textMD,
                      ),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(borderSide: BorderSide.none),
                        isCollapsed: true,
                        hintText: widget.hint,
                        contentPadding: const EdgeInsets.all(0),
                        isDense: true,
                      ),
                      onChanged: (value) => widget.setFn(value),
                    ),
                  ),
                ),
              )
            : TextField(
                controller: controller,
                contextMenuBuilder: globalContextMenuBuilder,
                // controller: TextEditingController()..text = ',
                maxLines: widget.maxLines != null && widget.maxLines! < 1 ? (widget.isTextArea ? null : 1) : widget.maxLines,
                minLines: widget.minLines != null && widget.minLines! < 1 ? (widget.isTextArea ? 4 : 1) : widget.minLines,
                style: TextStyle(
                  color: primaryLight,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                  decorationThickness: 0,
                  fontSize: textMD,
                ),
                decoration: InputDecoration(
                  fillColor: tertiaryDark,
                  filled: true,
                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(cornerRadiusMD), borderSide: BorderSide.none),
                  isCollapsed: true,
                  hintText: widget.hint,
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  contentPadding: const EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM),
                  isDense: true,
                ),
                onChanged: (value) => widget.setFn(value),
              ),
      ],
    );
  }
}
