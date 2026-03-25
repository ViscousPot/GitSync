import 'package:GitSync/global.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import '../../../constant/dimens.dart';
import '../../../ui/dialog/info_dialog.dart' as InfoDialog;

class PostFooterIndicator extends StatelessWidget {
  const PostFooterIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: uiSettingsManager.getPostFooter(),
      builder: (context, snapshot) {
        final footer = snapshot.data?.trim() ?? '';
        if (footer.isEmpty) return SizedBox.shrink();
        return GestureDetector(
          onTap: () => InfoDialog.showDialog(context, t.postFooterLabel, t.postFooterDialogInfo),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceXXS),
            child: MarkdownBody(
              data: footer,
              extensionSet: md.ExtensionSet.gitHubFlavored,
              shrinkWrap: true,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(color: colours.tertiaryLight, fontSize: textXXS),
                a: TextStyle(color: colours.tertiaryLight, fontSize: textXXS, decoration: TextDecoration.underline),
              ),
            ),
          ),
        );
      },
    );
  }
}
