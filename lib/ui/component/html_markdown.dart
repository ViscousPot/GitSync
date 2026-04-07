import 'package:GitSync/constant/dimens.dart';
import 'package:html/dom.dart' as h;
import 'package:markdown/markdown.dart' as m;
import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:html/dom_parsing.dart';
import 'package:markdown_widget/markdown_widget.dart';

void htmlToMarkdown(h.Node? node, int deep, List<m.Node> mNodes) {
  if (node == null) return;
  if (node is h.Text) {
    mNodes.add(m.Text(node.text));
  } else if (node is h.Element) {
    final tag = node.localName;
    List<m.Node> children = [];
    node.children.forEach((e) {
      htmlToMarkdown(e, deep + 1, children);
    });
    m.Element element;
    if (tag == MarkdownTag.img.name || tag == 'video') {
      element = HtmlElement(tag!, children, node.text);
      element.attributes.addAll(node.attributes.cast());
    } else {
      element = HtmlElement(tag!, children, node.text);
      element.attributes.addAll(node.attributes.cast());
    }
    mNodes.add(element);
  }
}

final RegExp tableRep = RegExp(r'<table[^>]*>', multiLine: true, caseSensitive: true);

final RegExp htmlRep = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true);

List<SpanNode> parseHtml(m.Text node, {ValueCallback<dynamic>? onError, WidgetVisitor? visitor, TextStyle? parentStyle}) {
  try {
    final text = node.textContent.replaceAll(visitor?.splitRegExp ?? WidgetVisitor.defaultSplitRegExp, '');
    if (!text.contains(htmlRep)) return [TextNode(text: node.text)];
    h.DocumentFragment document = parseFragment(text);
    return HtmlToSpanVisitor(visitor: visitor, parentStyle: parentStyle).toVisit(document.nodes.toList());
  } catch (e) {
    onError?.call(e);
    return [TextNode(text: node.text)];
  }
}

class HtmlElement extends m.Element {
  final String textContent;

  HtmlElement(String tag, List<m.Node>? children, this.textContent) : super(tag, children);
}

class HtmlToSpanVisitor extends TreeVisitor {
  final List<SpanNode> _spans = [];
  final List<SpanNode> _spansStack = [];
  final WidgetVisitor visitor;
  final TextStyle parentStyle;

  HtmlToSpanVisitor({WidgetVisitor? visitor, TextStyle? parentStyle})
    : this.visitor = visitor ?? WidgetVisitor(),
      this.parentStyle = parentStyle ?? TextStyle();

  List<SpanNode> toVisit(List<h.Node> nodes) {
    _spans.clear();
    for (final node in nodes) {
      final emptyNode = ConcreteElementNode(style: parentStyle);
      _spans.add(emptyNode);
      _spansStack.add(emptyNode);
      visit(node);
      _spansStack.removeLast();
    }
    final result = List.of(_spans);
    _spans.clear();
    _spansStack.clear();
    return result;
  }

  @override
  void visitText(h.Text node) {
    final last = _spansStack.last;
    if (last is ElementNode) {
      final textNode = TextNode(text: node.text);
      last.accept(textNode);
    }
  }

  @override
  void visitElement(h.Element node) {
    final localName = node.localName ?? '';
    final mdElement = m.Element(localName, []);
    mdElement.attributes.addAll(node.attributes.cast());
    SpanNode spanNode = visitor.getNodeByElement(mdElement, visitor.config);
    if (spanNode is! ElementNode) {
      final n = ConcreteElementNode(tag: localName, style: parentStyle);
      n.accept(spanNode);
      spanNode = n;
    }
    final last = _spansStack.last;
    if (last is ElementNode) {
      last.accept(spanNode);
    }
    _spansStack.add(spanNode);
    for (var child in node.nodes.toList(growable: false)) {
      visit(child);
    }
    _spansStack.removeLast();
  }
}

class DetailsBlockSyntax extends m.BlockSyntax {
  static final _startPattern = RegExp(r'^\s{0,3}<details[\s>]', caseSensitive: false);
  static final _endPattern = RegExp(r'</details\s*>', caseSensitive: false);

  @override
  RegExp get pattern => _startPattern;

  @override
  bool canEndBlock(m.BlockParser parser) => true;

  @override
  m.Node parse(m.BlockParser parser) {
    final lines = <String>[];
    while (!parser.isDone) {
      lines.add(parser.current.content);
      final isEnd = _endPattern.hasMatch(parser.current.content);
      parser.advance();
      if (isEnd) break;
    }
    final content = lines.join('\n');
    final element = m.Element('details', [m.Text(content)]);
    return element;
  }
}

class DetailsNode extends SpanNode {
  final m.Element element;
  final MarkdownConfig config;

  DetailsNode(this.element, this.config);

  @override
  InlineSpan build() {
    final rawHtml = element.textContent;
    final doc = parseFragment(rawHtml);
    final detailsEl = doc.querySelector('details');
    String summaryText = 'Details';
    String bodyContent = '';
    if (detailsEl != null) {
      final summaryEl = detailsEl.querySelector('summary');
      if (summaryEl != null) {
        summaryText = summaryEl.text.trim();
        summaryEl.remove();
      }
      bodyContent = detailsEl.innerHtml.trim();
    }
    return WidgetSpan(
      child: _DetailsWidget(summary: summaryText, bodyContent: bodyContent, config: config),
    );
  }
}

class _DetailsWidget extends StatefulWidget {
  final String summary;
  final String bodyContent;
  final MarkdownConfig config;

  const _DetailsWidget({required this.summary, required this.bodyContent, required this.config});

  @override
  State<_DetailsWidget> createState() => _DetailsWidgetState();
}

class _DetailsWidgetState extends State<_DetailsWidget> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final textStyle = widget.config.p.textStyle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -spaceSM,
                top: 0,
                bottom: 0,
                child: Icon(_expanded ? Icons.arrow_drop_down : Icons.arrow_right, color: textStyle.color, size: textMD),
              ),
              Text(widget.summary, style: textStyle.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        if (_expanded && widget.bodyContent.isNotEmpty) MarkdownBlock(data: widget.bodyContent, config: widget.config, selectable: false),
      ],
    );
  }
}
