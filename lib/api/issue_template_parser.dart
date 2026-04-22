import 'package:yaml/yaml.dart';
import 'package:GitSync/type/issue_template.dart';

IssueTemplate parseYamlTemplate(String content, String fileName) {
  final doc = loadYaml(content) as YamlMap;

  final name = doc['name']?.toString() ?? fileName;
  final description = doc['description']?.toString() ?? '';
  final title = doc['title']?.toString();

  final labels = <String>[];
  if (doc['labels'] is YamlList) {
    for (final l in doc['labels'] as YamlList) {
      labels.add(l.toString());
    }
  }

  final assignees = <String>[];
  if (doc['assignees'] is YamlList) {
    for (final a in doc['assignees'] as YamlList) {
      assignees.add(a.toString());
    }
  }

  final fields = <IssueTemplateField>[];
  if (doc['body'] is YamlList) {
    for (final item in doc['body'] as YamlList) {
      if (item is! YamlMap) continue;
      final field = _parseField(item);
      if (field != null) fields.add(field);
    }
  }

  return IssueTemplate(name: name, description: description, title: title, labels: labels, assignees: assignees, fields: fields);
}

IssueTemplateField? _parseField(YamlMap item) {
  final typeStr = item['type']?.toString();
  if (typeStr == null) return null;

  final type = switch (typeStr) {
    'input' => IssueTemplateFieldType.input,
    'textarea' => IssueTemplateFieldType.textarea,
    'dropdown' => IssueTemplateFieldType.dropdown,
    'checkboxes' => IssueTemplateFieldType.checkboxes,
    'markdown' => IssueTemplateFieldType.markdown,
    _ => null,
  };
  if (type == null) return null;

  final attrs = item['attributes'] is YamlMap ? item['attributes'] as YamlMap : YamlMap();
  final validations = item['validations'] is YamlMap ? item['validations'] as YamlMap : YamlMap();

  final id = item['id']?.toString() ?? attrs['label']?.toString() ?? typeStr;
  final label = attrs['label']?.toString() ?? '';
  final description = attrs['description']?.toString();
  final placeholder = attrs['placeholder']?.toString();
  final value = attrs['value']?.toString();
  final render = attrs['render']?.toString();
  final required = validations['required'] == true;

  List<String>? options;
  if (attrs['options'] is YamlList) {
    options = (attrs['options'] as YamlList).map((o) => o.toString()).toList();
  }

  List<IssueTemplateCheckbox>? checkboxes;
  if (attrs['options'] is YamlList && type == IssueTemplateFieldType.checkboxes) {
    checkboxes = <IssueTemplateCheckbox>[];
    for (final opt in attrs['options'] as YamlList) {
      if (opt is YamlMap) {
        checkboxes.add(IssueTemplateCheckbox(label: opt['label']?.toString() ?? '', required: opt['required'] == true));
      } else {
        checkboxes.add(IssueTemplateCheckbox(label: opt.toString(), required: false));
      }
    }
    options = null;
  }

  return IssueTemplateField(
    type: type,
    id: id,
    label: label,
    description: description,
    placeholder: placeholder,
    required: required,
    value: value,
    options: options,
    checkboxes: checkboxes,
    render: render,
  );
}

IssueTemplate parseMarkdownTemplate(String content, String fileName) {
  String name = fileName.replaceAll(RegExp(r'\.(md|markdown)$', caseSensitive: false), '');
  String description = '';
  String? title;
  List<String> labels = [];
  List<String> assignees = [];
  String body = content;

  final frontMatterMatch = RegExp(r'^---\s*\n([\s\S]*?)\n---\s*\n([\s\S]*)$').firstMatch(content);
  if (frontMatterMatch != null) {
    final yamlPart = frontMatterMatch.group(1)!;
    body = frontMatterMatch.group(2)!.trim();

    try {
      final doc = loadYaml(yamlPart);
      if (doc is YamlMap) {
        name = doc['name']?.toString() ?? name;
        description = doc['about']?.toString() ?? doc['description']?.toString() ?? '';
        title = doc['title']?.toString();
        if (doc['labels'] is YamlList) {
          labels = (doc['labels'] as YamlList).map((l) => l.toString()).toList();
        } else if (doc['labels'] is String) {
          labels = (doc['labels'] as String).split(',').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
        }
        if (doc['assignees'] is YamlList) {
          assignees = (doc['assignees'] as YamlList).map((a) => a.toString()).toList();
        }
      }
    } catch (_) {}
  }

  return IssueTemplate(name: name, description: description, title: title, labels: labels, assignees: assignees, body: body);
}

String buildIssueBodyFromTemplate(IssueTemplate template, Map<String, dynamic> fieldValues) {
  final buffer = StringBuffer();

  for (final field in template.fields) {
    if (field.type == IssueTemplateFieldType.markdown) continue;

    final value = fieldValues[field.id];
    buffer.writeln('### ${field.label}');
    buffer.writeln();

    switch (field.type) {
      case IssueTemplateFieldType.input:
      case IssueTemplateFieldType.dropdown:
        buffer.writeln(value?.toString() ?? '');
        break;
      case IssueTemplateFieldType.textarea:
        final text = value?.toString() ?? '';
        if (field.render != null && text.isNotEmpty) {
          buffer.writeln('```${field.render}');
          buffer.writeln(text);
          buffer.writeln('```');
        } else {
          buffer.writeln(text);
        }
        break;
      case IssueTemplateFieldType.checkboxes:
        if (value is Map<int, bool> && field.checkboxes != null) {
          for (int i = 0; i < field.checkboxes!.length; i++) {
            final checked = value[i] ?? false;
            buffer.writeln('- [${checked ? 'x' : ' '}] ${field.checkboxes![i].label}');
          }
        }
        break;
      case IssueTemplateFieldType.markdown:
        break;
    }
    buffer.writeln();
  }

  return buffer.toString().trimRight();
}
