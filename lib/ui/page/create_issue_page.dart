import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:GitSync/ui/component/markdown_config.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/api/helper.dart';
import 'package:GitSync/api/issue_template_parser.dart';
import 'package:GitSync/api/manager/auth/git_provider_manager.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/constant/strings.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/providers/riverpod_providers.dart';
import 'package:GitSync/ui/component/ai_wand_field.dart';
import 'package:GitSync/api/ai_completion_service.dart';
import 'package:GitSync/type/git_provider.dart';
import 'package:GitSync/type/issue_template.dart';
import 'package:GitSync/ui/component/post_footer_indicator.dart';

class CreateIssuePage extends ConsumerStatefulWidget {
  final GitProvider gitProvider;
  final String remoteWebUrl;
  final String accessToken;
  final bool githubAppOauth;

  const CreateIssuePage({super.key, required this.gitProvider, required this.remoteWebUrl, required this.accessToken, required this.githubAppOauth});

  @override
  ConsumerState<CreateIssuePage> createState() => _CreateIssuePageState();
}

class _CreateIssuePageState extends ConsumerState<CreateIssuePage> {
  List<IssueTemplate> _templates = [];
  IssueTemplate? _selectedTemplate;
  bool _loadingTemplates = true;
  bool _submitting = false;
  bool _writeMode = true;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final Map<String, TextEditingController> _fieldControllers = {};
  final Map<String, dynamic> _fieldValues = {};

  @override
  void initState() {
    super.initState();
    _fetchTemplates();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    for (final c in _fieldControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  (String, String) _parseOwnerRepo() {
    final segments = Uri.parse(widget.remoteWebUrl).pathSegments;
    return (segments[0], segments[1].replaceAll(".git", ""));
  }

  GitProviderManager? get _manager => GitProviderManager.getGitProviderManager(widget.gitProvider, widget.githubAppOauth);

  Future<void> _fetchTemplates() async {
    final (owner, repo) = _parseOwnerRepo();
    final manager = _manager;
    if (manager == null) {
      if (mounted) setState(() => _loadingTemplates = false);
      return;
    }

    final templates = await manager.getIssueTemplates(widget.accessToken, owner, repo);
    if (!mounted) return;
    setState(() {
      _templates = templates;
      _loadingTemplates = false;
    });
  }

  void _selectTemplate(IssueTemplate? template) {
    for (final c in _fieldControllers.values) {
      c.dispose();
    }
    _fieldControllers.clear();
    _fieldValues.clear();

    if (template != null) {
      _titleController.text = template.title ?? '';
      _bodyController.text = template.body ?? '';
      for (final field in template.fields) {
        if (field.type == IssueTemplateFieldType.input || field.type == IssueTemplateFieldType.textarea) {
          _fieldControllers[field.id] = TextEditingController();
        } else if (field.type == IssueTemplateFieldType.dropdown) {
          _fieldValues[field.id] = null;
        } else if (field.type == IssueTemplateFieldType.checkboxes && field.checkboxes != null) {
          _fieldValues[field.id] = <int, bool>{for (int i = 0; i < field.checkboxes!.length; i++) i: false};
        }
      }
    } else {
      _titleController.clear();
      _bodyController.clear();
    }

    setState(() {
      _selectedTemplate = template;
      _writeMode = true;
    });
  }

  bool _hasUserContent() {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (_selectedTemplate == null) {
      return title.isNotEmpty || body.isNotEmpty;
    }
    return title != (_selectedTemplate?.title ?? '').trim() || body != (_selectedTemplate?.body ?? '').trim();
  }

  bool get _canSubmit {
    if (_titleController.text.trim().isEmpty) return false;
    final template = _selectedTemplate;
    if (template != null && template.fields.isNotEmpty) {
      for (final field in template.fields) {
        if (!field.required) continue;
        if (field.type == IssueTemplateFieldType.markdown) continue;
        if (field.type == IssueTemplateFieldType.input || field.type == IssueTemplateFieldType.textarea) {
          if ((_fieldControllers[field.id]?.text ?? '').trim().isEmpty) return false;
        } else if (field.type == IssueTemplateFieldType.dropdown) {
          if (_fieldValues[field.id] == null) return false;
        } else if (field.type == IssueTemplateFieldType.checkboxes) {
          if (field.checkboxes != null) {
            final checks = _fieldValues[field.id] as Map<int, bool>? ?? {};
            for (int i = 0; i < field.checkboxes!.length; i++) {
              if (field.checkboxes![i].required && checks[i] != true) return false;
            }
          }
        }
      }
    }
    return true;
  }

  Future<void> _submitIssue() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);

    final (owner, repo) = _parseOwnerRepo();
    final manager = _manager;
    if (manager == null) {
      setState(() => _submitting = false);
      return;
    }

    final title = _titleController.text.trim();
    String body;
    List<String>? labels;
    List<String>? assignees;

    final template = _selectedTemplate;
    if (template != null && template.fields.isNotEmpty) {
      final fieldValues = <String, dynamic>{};
      for (final field in template.fields) {
        if (field.type == IssueTemplateFieldType.input || field.type == IssueTemplateFieldType.textarea) {
          fieldValues[field.id] = _fieldControllers[field.id]?.text ?? '';
        } else {
          fieldValues[field.id] = _fieldValues[field.id];
        }
      }
      body = buildIssueBodyFromTemplate(template, fieldValues);
      labels = template.labels.isNotEmpty ? template.labels : null;
      assignees = template.assignees.isNotEmpty ? template.assignees : null;
    } else {
      body = _bodyController.text;
      labels = template?.labels.isNotEmpty == true ? template!.labels : null;
      assignees = template?.assignees.isNotEmpty == true ? template!.assignees : null;
    }

    final footer = ref.read(postFooterProvider).valueOrNull ?? '';
    if (footer.trim().isNotEmpty) body = '$body\n$footer';
    final result = await manager.createIssue(widget.accessToken, owner, repo, title, body, labels: labels, assignees: assignees);
    if (!mounted) return;

    if (result != null && result.isSuccess) {
      Fluttertoast.showToast(msg: t.createIssueSuccess, toastLength: Toast.LENGTH_SHORT, gravity: null);
      Navigator.of(context).pop(true);
    } else {
      setState(() => _submitting = false);
      final errorMsg = result?.error;
      Fluttertoast.showToast(
        msg: errorMsg != null ? "${t.createIssueFailed}: $errorMsg" : t.createIssueFailed,
        toastLength: Toast.LENGTH_LONG,
        gravity: null,
      );
    }
  }

  MarkdownConfig get _markdownConfig => buildMarkdownConfig();
  MarkdownGenerator get _markdownGenerator => buildMarkdownGenerator();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colours.primaryDark,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(left: spaceXS, top: spaceXS, right: spaceXS),
              child: Row(
                children: [
                  getBackButton(context, () => Navigator.of(context).pop()),
                  SizedBox(width: spaceXS),
                  Text(
                    t.createIssue.toUpperCase(),
                    style: TextStyle(color: colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            if (_loadingTemplates)
              Padding(
                padding: EdgeInsets.all(spaceSM),
                child: Center(
                  child: CircularProgressIndicator(color: colours.secondaryLight, strokeWidth: spaceXXXXS),
                ),
              )
            else if (_templates.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: spaceMD),
                child: SizedBox(
                  height: spaceLG + spaceXS,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _TemplateChip(
                        label: t.createIssueBlankIssue.toUpperCase(),
                        selected: _selectedTemplate == null,
                        onTap: () => _selectTemplate(null),
                      ),
                      ...List.generate(_templates.length, (i) {
                        return Padding(
                          padding: EdgeInsets.only(left: spaceXS),
                          child: _TemplateChip(
                            label: _templates[i].name.toUpperCase(),
                            selected: _selectedTemplate == _templates[i],
                            onTap: () => _selectTemplate(_templates[i]),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            if (_loadingTemplates || _templates.isNotEmpty) SizedBox(height: spaceMD + spaceXXS),
            Expanded(child: _buildForm()),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    final template = _selectedTemplate;
    final useTemplateFields = template != null && template.fields.isNotEmpty;

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: spaceMD),
      children: [
        // Title field
        AiWandField(
          enabled: _hasUserContent(),
          onPressed: () async {
            final buffer = StringBuffer('Current title: ${_titleController.text}\nCurrent body:\n${_bodyController.text}\n');
            if (_selectedTemplate != null) {
              buffer.writeln('\nTemplate: ${_selectedTemplate!.name}');
              if (_selectedTemplate!.fields.isNotEmpty) {
                buffer.writeln('Sections:');
                for (final field in _selectedTemplate!.fields) {
                  buffer.writeln('- ${field.label}${field.description != null ? ": ${field.description}" : ""}');
                }
              }
            }
            final result = await aiComplete(
              systemPrompt:
                  "Enhance this issue title and description. The first line is the title (under 70 chars), then a blank line, then the markdown description. Follow the template structure if provided. Maintain the user's original intent.",
              userPrompt: buffer.toString(),
            );
            if (result != null) {
              final lines = result.trim().split('\n');
              _titleController.text = lines.first.trim();
              final bodyStart = lines.indexWhere((l) => l.trim().isNotEmpty, 1);
              if (bodyStart != -1) {
                _bodyController.text = lines.sublist(bodyStart).join('\n').trim();
              }
              setState(() {});
            }
          },
          child: TextField(
            contextMenuBuilder: globalContextMenuBuilder,
            controller: _titleController,
            maxLines: 1,
            style: TextStyle(
              color: colours.primaryLight,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
              decorationThickness: 0,
              fontSize: textMD,
            ),
            decoration: InputDecoration(
              fillColor: colours.secondaryDark,
              filled: true,
              border: const OutlineInputBorder(borderRadius: BorderRadius.all(cornerRadiusSM), borderSide: BorderSide.none),
              isCollapsed: true,
              label: Text(
                t.createIssueTitle.toUpperCase(),
                style: TextStyle(color: colours.secondaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
              ),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              hintText: t.createIssueTitleHint,
              hintStyle: TextStyle(color: colours.tertiaryLight, fontSize: textMD, fontWeight: FontWeight.normal),
              contentPadding: const EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM),
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),

        SizedBox(height: spaceMD),

        if (useTemplateFields) ..._buildTemplateFields(template) else _buildDefaultBody(),

        SizedBox(height: spaceMD),

        // Submit button
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: _submitting || !_canSubmit ? null : _submitIssue,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: spaceSM),
              decoration: BoxDecoration(
                color: _submitting || !_canSubmit ? colours.tertiaryDark : colours.tertiaryInfo.withValues(alpha: 0.15),
                borderRadius: BorderRadius.all(cornerRadiusSM),
              ),
              child: _submitting
                  ? Center(
                      child: SizedBox(
                        height: textMD,
                        width: textMD,
                        child: CircularProgressIndicator(color: colours.secondaryLight, strokeWidth: spaceXXXXS),
                      ),
                    )
                  : Text(
                      t.createIssueSubmit.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _canSubmit ? colours.tertiaryInfo : colours.tertiaryLight,
                        fontSize: textMD,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),

        SizedBox(height: spaceLG),
      ],
    );
  }

  Widget _buildDefaultBody() {
    return Container(
      decoration: BoxDecoration(color: colours.secondaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
      child: Column(
        children: [
          // Write/Preview toggle
          Padding(
            padding: EdgeInsets.fromLTRB(spaceSM, spaceSM, spaceSM, 0),
            child: Row(
              children: [
                _WritePreviewTab(label: t.issueWrite.toUpperCase(), selected: _writeMode, onTap: () => setState(() => _writeMode = true)),
                SizedBox(width: spaceXXS),
                _WritePreviewTab(label: t.issuePreview.toUpperCase(), selected: !_writeMode, onTap: () => setState(() => _writeMode = false)),
              ],
            ),
          ),
          SizedBox(height: spaceXXS),

          if (_writeMode)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: spaceSM),
              child: TextField(
                contextMenuBuilder: globalContextMenuBuilder,
                controller: _bodyController,
                maxLines: 10,
                minLines: 5,
                style: TextStyle(color: colours.primaryLight, fontSize: textSM, decoration: TextDecoration.none, decorationThickness: 0),
                decoration: InputDecoration(
                  fillColor: colours.tertiaryDark,
                  filled: true,
                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(cornerRadiusSM), borderSide: BorderSide.none),
                  isCollapsed: true,
                  hintText: t.createIssueBodyHint,
                  hintStyle: TextStyle(color: colours.tertiaryLight, fontSize: textSM),
                  contentPadding: EdgeInsets.all(spaceSM),
                ),
                onChanged: (_) => setState(() {}),
              ),
            )
          else
            Container(
              width: double.infinity,
              constraints: BoxConstraints(minHeight: spaceLG * 3),
              padding: EdgeInsets.all(spaceSM),
              margin: EdgeInsets.symmetric(horizontal: spaceSM),
              decoration: BoxDecoration(color: colours.tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
              child: _bodyController.text.isEmpty
                  ? Text(
                      t.createIssueBodyHint,
                      style: TextStyle(color: colours.tertiaryLight, fontSize: textSM, fontStyle: FontStyle.italic),
                    )
                  : MarkdownBlock(data: _bodyController.text, config: _markdownConfig, generator: _markdownGenerator),
            ),

          PostFooterIndicator(),
          SizedBox(height: spaceSM),
        ],
      ),
    );
  }

  List<Widget> _buildTemplateFields(IssueTemplate template) {
    final widgets = <Widget>[];
    for (final field in template.fields) {
      switch (field.type) {
        case IssueTemplateFieldType.markdown:
          widgets.add(
            Padding(
              padding: EdgeInsets.only(bottom: spaceMD),
              child: MarkdownBlock(data: field.value ?? '', config: _markdownConfig, generator: _markdownGenerator),
            ),
          );
        case IssueTemplateFieldType.input:
          widgets.add(_buildInputField(field));
        case IssueTemplateFieldType.textarea:
          widgets.add(_buildTextareaField(field));
        case IssueTemplateFieldType.dropdown:
          widgets.add(_buildDropdownField(field));
        case IssueTemplateFieldType.checkboxes:
          widgets.add(_buildCheckboxesField(field));
      }
    }
    return widgets;
  }

  Widget _buildInputField(IssueTemplateField field) {
    _fieldControllers.putIfAbsent(field.id, () => TextEditingController());
    return Padding(
      padding: EdgeInsets.only(bottom: spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                field.label.toUpperCase(),
                style: TextStyle(color: colours.secondaryLight, fontSize: textXS, fontWeight: FontWeight.bold),
              ),
              if (field.required) ...[
                SizedBox(width: spaceXXXS),
                Text(
                  '*',
                  style: TextStyle(color: colours.primaryNegative, fontSize: textXS, fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
          if (field.description != null) ...[
            SizedBox(height: spaceXXXXS),
            Text(
              field.description!,
              style: TextStyle(color: colours.tertiaryLight, fontSize: textXXS),
            ),
          ],
          SizedBox(height: spaceXXS),
          TextField(
            contextMenuBuilder: globalContextMenuBuilder,
            controller: _fieldControllers[field.id],
            maxLines: 1,
            style: TextStyle(color: colours.primaryLight, decoration: TextDecoration.none, decorationThickness: 0, fontSize: textSM),
            decoration: InputDecoration(
              fillColor: colours.secondaryDark,
              filled: true,
              border: const OutlineInputBorder(borderRadius: BorderRadius.all(cornerRadiusSM), borderSide: BorderSide.none),
              isCollapsed: true,
              hintText: field.placeholder,
              hintStyle: TextStyle(color: colours.tertiaryLight, fontSize: textSM),
              contentPadding: const EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM),
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildTextareaField(IssueTemplateField field) {
    _fieldControllers.putIfAbsent(field.id, () => TextEditingController());
    return Padding(
      padding: EdgeInsets.only(bottom: spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                field.label.toUpperCase(),
                style: TextStyle(color: colours.secondaryLight, fontSize: textXS, fontWeight: FontWeight.bold),
              ),
              if (field.required) ...[
                SizedBox(width: spaceXXXS),
                Text(
                  '*',
                  style: TextStyle(color: colours.primaryNegative, fontSize: textXS, fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
          if (field.description != null) ...[
            SizedBox(height: spaceXXXXS),
            Text(
              field.description!,
              style: TextStyle(color: colours.tertiaryLight, fontSize: textXXS),
            ),
          ],
          SizedBox(height: spaceXXS),
          TextField(
            contextMenuBuilder: globalContextMenuBuilder,
            controller: _fieldControllers[field.id],
            maxLines: 8,
            minLines: 3,
            style: TextStyle(color: colours.primaryLight, fontSize: textSM, decoration: TextDecoration.none, decorationThickness: 0),
            decoration: InputDecoration(
              fillColor: colours.secondaryDark,
              filled: true,
              border: const OutlineInputBorder(borderRadius: BorderRadius.all(cornerRadiusSM), borderSide: BorderSide.none),
              isCollapsed: true,
              hintText: field.placeholder,
              hintStyle: TextStyle(color: colours.tertiaryLight, fontSize: textSM),
              contentPadding: EdgeInsets.all(spaceSM),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(IssueTemplateField field) {
    final selected = _fieldValues[field.id] as String?;
    return Padding(
      padding: EdgeInsets.only(bottom: spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                field.label.toUpperCase(),
                style: TextStyle(color: colours.secondaryLight, fontSize: textXS, fontWeight: FontWeight.bold),
              ),
              if (field.required) ...[
                SizedBox(width: spaceXXXS),
                Text(
                  '*',
                  style: TextStyle(color: colours.primaryNegative, fontSize: textXS, fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
          if (field.description != null) ...[
            SizedBox(height: spaceXXXXS),
            Text(
              field.description!,
              style: TextStyle(color: colours.tertiaryLight, fontSize: textXXS),
            ),
          ],
          SizedBox(height: spaceXXS),
          GestureDetector(
            onTap: () => _showDropdownSheet(field),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM),
              decoration: BoxDecoration(color: colours.secondaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selected ?? t.createIssueSelectTemplate,
                      style: TextStyle(color: selected != null ? colours.primaryLight : colours.tertiaryLight, fontSize: textSM),
                    ),
                  ),
                  FaIcon(FontAwesomeIcons.chevronDown, size: textXS, color: colours.tertiaryLight),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDropdownSheet(IssueTemplateField field) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colours.secondaryDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: EdgeInsets.all(spaceMD),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.label.toUpperCase(),
              style: TextStyle(color: colours.secondaryLight, fontSize: textXS, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: spaceSM),
            ...field.options!.map(
              (option) => GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _fieldValues[field.id] = option);
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: spaceSM, horizontal: spaceSM),
                  margin: EdgeInsets.only(bottom: spaceXXXS),
                  decoration: BoxDecoration(
                    color: _fieldValues[field.id] == option ? colours.showcaseBg : colours.tertiaryDark,
                    borderRadius: BorderRadius.all(cornerRadiusSM),
                    border: Border.all(color: _fieldValues[field.id] == option ? colours.showcaseBorder : Colors.transparent, width: spaceXXXXS),
                  ),
                  child: Text(
                    option,
                    style: TextStyle(color: colours.primaryLight, fontSize: textSM),
                  ),
                ),
              ),
            ),
            SizedBox(height: spaceSM),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxesField(IssueTemplateField field) {
    final checks = _fieldValues[field.id] as Map<int, bool>? ?? {};
    return Padding(
      padding: EdgeInsets.only(bottom: spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                field.label.toUpperCase(),
                style: TextStyle(color: colours.secondaryLight, fontSize: textXS, fontWeight: FontWeight.bold),
              ),
              if (field.required) ...[
                SizedBox(width: spaceXXXS),
                Text(
                  '*',
                  style: TextStyle(color: colours.primaryNegative, fontSize: textXS, fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
          if (field.description != null) ...[
            SizedBox(height: spaceXXXXS),
            Text(
              field.description!,
              style: TextStyle(color: colours.tertiaryLight, fontSize: textXXS),
            ),
          ],
          SizedBox(height: spaceXXS),
          ...List.generate(field.checkboxes!.length, (i) {
            final cb = field.checkboxes![i];
            final checked = checks[i] ?? false;
            return GestureDetector(
              onTap: () {
                setState(() {
                  final map = Map<int, bool>.from(checks);
                  map[i] = !checked;
                  _fieldValues[field.id] = map;
                });
              },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: spaceXXXS),
                child: Row(
                  children: [
                    FaIcon(
                      checked ? FontAwesomeIcons.solidSquareCheck : FontAwesomeIcons.square,
                      size: textMD,
                      color: checked ? colours.tertiaryPositive : colours.tertiaryLight,
                    ),
                    SizedBox(width: spaceXS),
                    Expanded(
                      child: Text(
                        cb.label,
                        style: TextStyle(color: colours.primaryLight, fontSize: textSM),
                      ),
                    ),
                    if (cb.required)
                      Text(
                        '*',
                        style: TextStyle(color: colours.primaryNegative, fontSize: textXS, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TemplateChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TemplateChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceXXS),
        decoration: BoxDecoration(
          color: selected ? colours.showcaseBg : colours.tertiaryDark,
          borderRadius: BorderRadius.all(cornerRadiusSM),
          border: Border.all(color: selected ? colours.showcaseBorder : Colors.transparent, width: spaceXXXXS),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: selected ? colours.showcaseFeatureIcon : colours.secondaryLight, fontSize: textXS, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _WritePreviewTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _WritePreviewTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceXXS),
        decoration: BoxDecoration(color: selected ? colours.tertiaryDark : Colors.transparent, borderRadius: BorderRadius.all(cornerRadiusXS)),
        child: Text(
          label,
          style: TextStyle(color: selected ? colours.primaryLight : colours.tertiaryLight, fontSize: textXS, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

Route createCreateIssuePageRoute({
  required GitProvider gitProvider,
  required String remoteWebUrl,
  required String accessToken,
  required bool githubAppOauth,
}) {
  return PageRouteBuilder(
    settings: const RouteSettings(name: create_issue_page),
    pageBuilder: (context, animation, secondaryAnimation) =>
        CreateIssuePage(gitProvider: gitProvider, remoteWebUrl: remoteWebUrl, accessToken: accessToken, githubAppOauth: githubAppOauth),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
