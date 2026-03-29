import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:GitSync/ui/component/markdown_config.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/api/helper.dart';
import 'package:GitSync/api/manager/auth/git_provider_manager.dart';
import 'package:GitSync/api/manager/git_manager.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/constant/strings.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/ui/component/ai_wand_field.dart';
import 'package:GitSync/api/ai_completion_service.dart';
import 'package:GitSync/type/git_provider.dart';
import 'package:GitSync/type/issue_template.dart';
import 'package:GitSync/ui/component/post_footer_indicator.dart';

class CreatePrPage extends StatefulWidget {
  final GitProvider gitProvider;
  final String remoteWebUrl;
  final String accessToken;
  final bool githubAppOauth;

  const CreatePrPage({super.key, required this.gitProvider, required this.remoteWebUrl, required this.accessToken, required this.githubAppOauth});

  @override
  State<CreatePrPage> createState() => _CreatePrPageState();
}

class _CreatePrPageState extends State<CreatePrPage> {
  List<String> _branches = [];
  List<IssueTemplate> _templates = [];
  IssueTemplate? _selectedTemplate;
  String? _defaultBranch;
  String? _baseBranch;
  String? _headBranch;
  bool _loadingBranches = true;
  bool _submitting = false;
  bool _writeMode = true;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  (String, String) _parseOwnerRepo() {
    final segments = Uri.parse(widget.remoteWebUrl).pathSegments;
    return (segments[0], segments[1].replaceAll(".git", ""));
  }

  GitProviderManager? get _manager => GitProviderManager.getGitProviderManager(widget.gitProvider, widget.githubAppOauth);

  Future<void> _fetchData() async {
    final (owner, repo) = _parseOwnerRepo();
    final manager = _manager;
    if (manager == null) {
      if (mounted) setState(() => _loadingBranches = false);
      return;
    }

    final results = await Future.wait([
      manager.getRepoBranches(widget.accessToken, owner, repo),
      GitManager.getBranchName(),
      manager.getPrTemplates(widget.accessToken, owner, repo),
    ]);
    if (!mounted) return;

    final (branches, defaultBranch) = results[0] as (List<String>, String?);
    final currentBranch = results[1] as String?;
    final templates = results[2] as List<IssueTemplate>;

    String? headBranch;
    if (currentBranch != null && currentBranch != 'main' && currentBranch != 'master' && branches.contains(currentBranch)) {
      headBranch = currentBranch;
    }

    // If there's exactly one template, auto-select it
    IssueTemplate? selectedTemplate;
    if (templates.length == 1) {
      selectedTemplate = templates.first;
      _bodyController.text = selectedTemplate.body ?? '';
    }

    setState(() {
      _branches = branches;
      _templates = templates;
      _selectedTemplate = selectedTemplate;
      _defaultBranch = defaultBranch;
      _baseBranch = defaultBranch;
      _headBranch = headBranch;
      _loadingBranches = false;
    });
  }

  void _selectTemplate(IssueTemplate? template) {
    _bodyController.text = template?.body ?? '';
    setState(() {
      _selectedTemplate = template;
      _writeMode = true;
    });
  }

  bool get _canSubmit {
    if (_titleController.text.trim().isEmpty) return false;
    if (_baseBranch == null || _headBranch == null) return false;
    if (_baseBranch == _headBranch) return false;
    return true;
  }

  Future<void> _submitPr() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);

    final (owner, repo) = _parseOwnerRepo();
    final manager = _manager;
    if (manager == null) {
      setState(() => _submitting = false);
      return;
    }

    final bodyWithFooter = await uiSettingsManager.applyPostFooter(_bodyController.text);
    final result = await manager.createPullRequest(
      widget.accessToken,
      owner,
      repo,
      _titleController.text.trim(),
      bodyWithFooter,
      _headBranch!,
      _baseBranch!,
    );
    if (!mounted) return;

    if (result != null && result.isSuccess) {
      Fluttertoast.showToast(msg: t.createPrSuccess, toastLength: Toast.LENGTH_SHORT, gravity: null);
      Navigator.of(context).pop(true);
    } else {
      setState(() => _submitting = false);
      final errorMsg = result?.error;
      Fluttertoast.showToast(
        msg: errorMsg != null ? "${t.createPrFailed}: $errorMsg" : t.createPrFailed,
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
              padding: EdgeInsets.symmetric(horizontal: spaceXS, vertical: spaceXS),
              child: Row(
                children: [
                  getBackButton(context, () => Navigator.of(context).pop()),
                  SizedBox(width: spaceXS),
                  Expanded(
                    child: Text(
                      t.createPr.toUpperCase(),
                      style: TextStyle(color: colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (!_loadingBranches && _templates.length > 1)
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
            if (!_loadingBranches && _templates.length > 1) SizedBox(height: spaceXS),
            SizedBox(height: spaceXS),
            Expanded(
              child: _loadingBranches
                  ? Center(child: CircularProgressIndicator(color: colours.secondaryLight, strokeWidth: spaceXXXXS))
                  : _buildForm(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: spaceMD),
      children: [
        // Branch selectors
        Row(
          children: [
            Expanded(child: _buildBranchSelector(t.createPrBaseBranch.toUpperCase(), _baseBranch, (b) => setState(() => _baseBranch = b))),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: spaceXS),
              child: FaIcon(FontAwesomeIcons.arrowLeft, size: textXS, color: colours.tertiaryLight),
            ),
            Expanded(child: _buildBranchSelector(t.createPrHeadBranch.toUpperCase(), _headBranch, (b) => setState(() => _headBranch = b))),
          ],
        ),

        SizedBox(height: spaceMD),

        // Title field
        AiWandField(
          onPressed: () async {
            final diff = (_baseBranch != null && _headBranch != null)
                ? await GitManager.getCommitDiff(_baseBranch!, _headBranch!)
                : null;
            final buffer = StringBuffer('Branch: $_headBranch → $_baseBranch\n');
            if (diff != null) {
              buffer.writeln('+${diff.insertions}/-${diff.deletions}');
              buffer.writeln('\nChanged files:');
              buffer.write(formatDiffParts(diff.diffParts));
            }
            if (_selectedTemplate?.body?.isNotEmpty == true) {
              buffer.writeln('\nTemplate:\n${_selectedTemplate!.body}');
            }
            final result = await aiComplete(
              systemPrompt: "Generate a pull request title and description. The first line is the title (under 70 chars), then a blank line, then the markdown description. Include a summary section and what changed.",
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
            style: TextStyle(color: colours.primaryLight, fontWeight: FontWeight.bold, decoration: TextDecoration.none, decorationThickness: 0, fontSize: textMD),
            decoration: InputDecoration(
              fillColor: colours.secondaryDark,
              filled: true,
              border: const OutlineInputBorder(borderRadius: BorderRadius.all(cornerRadiusSM), borderSide: BorderSide.none),
              isCollapsed: true,
              label: Text(t.createPrTitle.toUpperCase(), style: TextStyle(color: colours.secondaryLight, fontSize: textSM, fontWeight: FontWeight.bold)),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              hintText: t.createPrTitleHint,
              hintStyle: TextStyle(color: colours.tertiaryLight, fontSize: textMD, fontWeight: FontWeight.normal),
              contentPadding: const EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM),
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),

        SizedBox(height: spaceMD),

        // Body with write/preview
        Container(
          decoration: BoxDecoration(color: colours.secondaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
          child: Column(
            children: [
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
                      hintText: t.createPrBodyHint,
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
                      ? Text(t.createPrBodyHint, style: TextStyle(color: colours.tertiaryLight, fontSize: textSM, fontStyle: FontStyle.italic))
                      : MarkdownBlock(data: _bodyController.text, config: _markdownConfig, generator: _markdownGenerator),
                ),
              PostFooterIndicator(),
              SizedBox(height: spaceSM),
            ],
          ),
        ),

        SizedBox(height: spaceMD),

        // Submit button
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: _submitting || !_canSubmit ? null : _submitPr,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: spaceSM),
              decoration: BoxDecoration(
                color: _submitting || !_canSubmit ? colours.tertiaryDark : colours.tertiaryInfo.withValues(alpha: 0.15),
                borderRadius: BorderRadius.all(cornerRadiusSM),
              ),
              child: _submitting
                  ? Center(child: SizedBox(height: textMD, width: textMD, child: CircularProgressIndicator(color: colours.secondaryLight, strokeWidth: spaceXXXXS)))
                  : Text(
                      t.createPrSubmit.toUpperCase(),
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

  Widget _buildBranchSelector(String label, String? selected, void Function(String) onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colours.secondaryLight, fontSize: textXXS, fontWeight: FontWeight.bold)),
        SizedBox(height: spaceXXXS),
        GestureDetector(
          onTap: () => _showBranchSheet(label, selected, onSelect),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceXS),
            decoration: BoxDecoration(color: colours.secondaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selected ?? t.createPrSelectBranch,
                    style: TextStyle(
                      color: selected != null ? colours.primaryLight : colours.tertiaryLight,
                      fontSize: textSM,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                FaIcon(FontAwesomeIcons.chevronDown, size: textXXS, color: colours.tertiaryLight),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showBranchSheet(String label, String? current, void Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colours.secondaryDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: EdgeInsets.all(spaceMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: colours.secondaryLight, fontSize: textXS, fontWeight: FontWeight.bold)),
              SizedBox(height: spaceSM),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _branches.length,
                  itemBuilder: (context, index) {
                    final branch = _branches[index];
                    final isSelected = branch == current;
                    final isDefault = branch == _defaultBranch;
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        onSelect(branch);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: spaceSM, horizontal: spaceSM),
                        margin: EdgeInsets.only(bottom: spaceXXXS),
                        decoration: BoxDecoration(
                          color: isSelected ? colours.showcaseBg : colours.tertiaryDark,
                          borderRadius: BorderRadius.all(cornerRadiusSM),
                          border: Border.all(color: isSelected ? colours.showcaseBorder : Colors.transparent, width: spaceXXXXS),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(branch, style: TextStyle(color: colours.primaryLight, fontSize: textSM), overflow: TextOverflow.ellipsis),
                            ),
                            if (isDefault)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: spaceXXS, vertical: spaceXXXXS),
                                decoration: BoxDecoration(color: colours.tertiaryInfo.withValues(alpha: 0.15), borderRadius: BorderRadius.all(cornerRadiusXS)),
                                child: Text('default', style: TextStyle(color: colours.tertiaryInfo, fontSize: textXXS)),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
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
        decoration: BoxDecoration(
          color: selected ? colours.tertiaryDark : Colors.transparent,
          borderRadius: BorderRadius.all(cornerRadiusXS),
        ),
        child: Text(
          label,
          style: TextStyle(color: selected ? colours.primaryLight : colours.tertiaryLight, fontSize: textXS, fontWeight: FontWeight.bold),
        ),
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

Route createCreatePrPageRoute({
  required GitProvider gitProvider,
  required String remoteWebUrl,
  required String accessToken,
  required bool githubAppOauth,
}) {
  return PageRouteBuilder(
    settings: const RouteSettings(name: create_pr_page),
    pageBuilder: (context, animation, secondaryAnimation) =>
        CreatePrPage(gitProvider: gitProvider, remoteWebUrl: remoteWebUrl, accessToken: accessToken, githubAppOauth: githubAppOauth),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
