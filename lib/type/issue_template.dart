enum IssueTemplateFieldType { input, textarea, dropdown, checkboxes, markdown }

class IssueTemplateCheckbox {
  final String label;
  final bool required;

  const IssueTemplateCheckbox({required this.label, required this.required});
}

class IssueTemplateField {
  final IssueTemplateFieldType type;
  final String id;
  final String label;
  final String? description;
  final String? placeholder;
  final bool required;
  final String? value;
  final List<String>? options;
  final List<IssueTemplateCheckbox>? checkboxes;
  final String? render;

  const IssueTemplateField({
    required this.type,
    required this.id,
    required this.label,
    this.description,
    this.placeholder,
    this.required = false,
    this.value,
    this.options,
    this.checkboxes,
    this.render,
  });
}

class IssueTemplate {
  final String name;
  final String description;
  final String? title;
  final List<String> labels;
  final List<String> assignees;
  final String? body;
  final List<IssueTemplateField> fields;

  const IssueTemplate({
    required this.name,
    required this.description,
    this.title,
    this.labels = const [],
    this.assignees = const [],
    this.body,
    this.fields = const [],
  });
}

class CreateIssueResult {
  final int number;
  final String? htmlUrl;
  final String? error;

  const CreateIssueResult({required this.number, this.htmlUrl}) : error = null;
  const CreateIssueResult.failure(this.error) : number = -1, htmlUrl = null;

  bool get isSuccess => error == null;
}
