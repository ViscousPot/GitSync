// GENERATED MODE - LOG HIGHLIGHTER - DO NOT MODIFY BY HAND
import 'package:re_highlight/re_highlight.dart';

final langDiff = Mode(
  name: 'SimpleDiff',
  caseInsensitive: false,
  illegal: null,
  contains: <Mode>[
    Mode(
      className: 'diffHunkHeader',
      relevance: 10,
      match: "(?:^@@ +-\\d+,\\d+ +\\+\\d+,\\d+ +@@|^\\*\\*\\* +\\d+,\\d+ +\\*\\*\\*\\*\$|^--- +\\d+,\\d+ +----\$).*\$",
    ),
    Mode(className: "eof", relevance: 10, match: "^END OF FILE\$"),

    Mode(
      scope: 'diffHide',
      begin: r"(\+{5}insertion\+{5}|-{5}deletion-{5})",
      end: "\$",
      contains: [
        Mode(scope: 'addition', match: r"(?<=\+{5}insertion\+{5}).*?(?=-{5}deletion-{5}|$)", relevance: 10),
        Mode(scope: 'deletion', match: r"(?<=-{5}deletion-{5}).*?(?=\+{5}insertion\+{5}|$)", relevance: 10),
      ],
      relevance: 10,
    ),

    Mode(className: 'diffRoot', begin: r'.+', relevance: 0),
  ],
);
