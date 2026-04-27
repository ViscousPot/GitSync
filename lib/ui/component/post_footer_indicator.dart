import 'package:GitSync/global.dart';
import 'package:GitSync/providers/riverpod_providers.dart';
import 'package:GitSync/ui/component/provider_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_widget/markdown_widget.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/info_dialog.dart' as InfoDialog;
import 'markdown_config.dart';

class PostFooterIndicator extends StatelessWidget {
  const PostFooterIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderBuilder<String>(
      provider: postFooterProvider,
      builder: (context, valueAsync) {
        final footer = valueAsync.valueOrNull?.trim() ?? '';
        if (footer.isEmpty) return SizedBox.shrink();
        return GestureDetector(
          onTap: () => InfoDialog.showDialog(context, t.postFooterLabel, t.postFooterDialogInfo),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: MarkdownBlock(data: footer, config: buildFooterMarkdownConfig(), generator: buildMarkdownGenerator(), selectable: false),
            ),
          ),
        );
      },
    );
  }
}
