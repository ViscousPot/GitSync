// GENERATED MODE - LOG HIGHLIGHTER - DO NOT MODIFY BY HAND
import 'package:re_highlight/re_highlight.dart';

final langLog = Mode(
  name: 'SimpleLog',
  caseInsensitive: false,
  illegal: null,
  contains: <Mode>[
    Mode(className: 'logComment', begin: r'^.*\s.git\sfolder\sfound.*$', relevance: 10),
    Mode(className: 'logComment', begin: r'^.*\sGetting\slocal\sdirectory.*$', relevance: 10),
    Mode(className: 'logComment', begin: r'^.*\sGitStatus:\s.*$', relevance: 10),
    Mode(className: 'logComment', begin: r'^.*\RecentCommits:\s.*$', relevance: 10),

    Mode(className: 'logError', begin: r'.*\s\[E\]\s.*', relevance: 8),
    Mode(className: 'logError', begin: r'^(?!.*\s\[(I|W|E|D|V|T)\]\s).*$', relevance: 8),
    Mode(className: 'logDate', begin: r'^\d{4}-\d{2}-\d{2}', relevance: 5),
    Mode(className: 'logTime', begin: r'\s+\d{2}:\d{2}:\d{2}\.\d{3}', relevance: 5),
    Mode(className: 'logLevel', begin: r'\s\[(I|W|E|D|V|T)\]\s', relevance: 5),
    Mode(className: 'logComponent', begin: r'\b[A-Za-z][A-Za-z0-9_]*\b:', relevance: 5),

    Mode(className: 'logRoot', begin: r'.+', relevance: 0),
  ],
);
