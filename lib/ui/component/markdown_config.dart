import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as m;
import 'package:markdown_widget/markdown_widget.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/global.dart';
import 'html_markdown.dart';

class _H1 extends H1Config {
  const _H1({required TextStyle style}) : super(style: style);
  @override
  HeadingDivider? get divider => null;
}

class _H2 extends H2Config {
  const _H2({required TextStyle style}) : super(style: style);
  @override
  HeadingDivider? get divider => null;
}

class _H3 extends H3Config {
  const _H3({required TextStyle style}) : super(style: style);
  @override
  HeadingDivider? get divider => null;
}

MarkdownConfig buildMarkdownConfig() => MarkdownConfig(
  configs: [
    PConfig(
      textStyle: TextStyle(color: colours.primaryLight, fontSize: textSM),
    ),
    _H1(
      style: TextStyle(color: colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
    ),
    _H2(
      style: TextStyle(color: colours.primaryLight, fontSize: textLG, fontWeight: FontWeight.bold),
    ),
    _H3(
      style: TextStyle(color: colours.primaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
    ),
    H4Config(
      style: TextStyle(color: colours.primaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
    ),
    H5Config(
      style: TextStyle(color: colours.primaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
    ),
    H6Config(
      style: TextStyle(color: colours.primaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
    ),
    CodeConfig(
      style: TextStyle(color: colours.tertiaryInfo, fontSize: textXS, fontFamily: 'RobotoMono', backgroundColor: colours.tertiaryDark),
    ),
    PreConfig(
      textStyle: TextStyle(color: colours.tertiaryInfo, fontSize: textXS, fontFamily: 'RobotoMono'),
      styleNotMatched: TextStyle(color: colours.tertiaryInfo, fontSize: textXS, fontFamily: 'RobotoMono'),
      decoration: BoxDecoration(color: colours.tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusXS)),
      padding: EdgeInsets.all(spaceXS),
      theme: {},
    ),
    LinkConfig(
      style: TextStyle(color: colours.tertiaryInfo, decoration: TextDecoration.underline),
    ),
    BlockquoteConfig(sideColor: colours.tertiaryInfo, sideWith: spaceXXXXS, textColor: colours.primaryLight),
    TableConfig(
      border: TableBorder.all(color: colours.tertiaryDark),
      headerStyle: TextStyle(color: colours.primaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
      bodyStyle: TextStyle(color: colours.primaryLight, fontSize: textSM),
    ),
    HrConfig(color: colours.tertiaryDark),
    ListConfig(
      marker: (isOrdered, depth, index) {
        return Text(
          isOrdered ? '${index + 1}.' : '•',
          style: TextStyle(color: colours.primaryLight, fontSize: textSM),
        );
      },
    ),
  ],
);

MarkdownConfig buildFooterMarkdownConfig() => MarkdownConfig(
  configs: [
    PConfig(
      textStyle: TextStyle(color: colours.tertiaryLight, fontSize: textXXS),
    ),
    LinkConfig(
      style: TextStyle(color: colours.tertiaryLight, fontSize: textXXS, decoration: TextDecoration.underline),
      onTap: (_) {},
    ),
  ],
);

SpanNode? _htmlTextGenerator(m.Node node, MarkdownConfig config, WidgetVisitor visitor) {
  if (node is m.Text) {
    final text = node.textContent.replaceAll(visitor.splitRegExp ?? WidgetVisitor.defaultSplitRegExp, '');
    if (!text.contains(htmlRep)) return null;
    final nodes = parseHtml(node, visitor: visitor, parentStyle: config.p.textStyle);
    if (nodes.length == 1) return nodes.first;
    if (nodes.isNotEmpty) {
      final parent = ConcreteElementNode(style: config.p.textStyle);
      for (final n in nodes) {
        parent.accept(n);
      }
      return parent;
    }
  }
  return null;
}

MarkdownGenerator buildMarkdownGenerator() => MarkdownGenerator(
  textGenerator: _htmlTextGenerator,
  blockSyntaxList: [DetailsBlockSyntax()],
  generators: [SpanNodeGeneratorWithTag(tag: 'details', generator: (e, config, visitor) => DetailsNode(e, config))],
);
