import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import '../../../constant/dimens.dart';
import '../../../ui/dialog/base_alert_dialog.dart';
import 'package:GitSync/global.dart';

class CreateRepoResult {
  final bool createLocal;
  final bool createRemote;
  final String? repoName;
  final bool isPrivate;
  final bool initMainBranch;

  const CreateRepoResult({required this.createLocal, required this.createRemote, this.repoName, this.isPrivate = true, this.initMainBranch = true});
}

Future<CreateRepoResult?> showDialog(
  BuildContext context, {
  required bool hasOAuth,
  required String? providerName,
  required bool repoAlreadyExists,
  required String defaultRepoName,
}) async {
  return mat.showDialog<CreateRepoResult>(
    context: context,
    builder: (BuildContext context) {
      // Mode A: No OAuth, no existing repo — simple confirm/cancel
      if (!hasOAuth && !repoAlreadyExists) {
        return BaseAlertDialog(
          title: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Text(
              context.t.createNewRepository,
              style: TextStyle(color: context.colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                SizedBox(height: spaceMD),
                Text(
                  context.t.noGitRepoFoundMsg,
                  style: TextStyle(color: context.colours.primaryLight, fontSize: textMD),
                ),
                SizedBox(height: spaceMD),
                Text(
                  context.t.remoteSetupLaterMsg.toUpperCase(),
                  style: TextStyle(color: context.colours.tertiaryInfo, fontSize: textXS, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                context.t.cancel.toUpperCase(),
                style: TextStyle(color: context.colours.primaryLight, fontSize: textMD),
              ),
              onPressed: () {
                Navigator.of(context).canPop() ? Navigator.pop(context) : null;
              },
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).canPop() ? Navigator.pop(context, CreateRepoResult(createLocal: true, createRemote: false)) : null;
              },
              child: Text(
                context.t.create.toUpperCase(),
                style: TextStyle(color: context.colours.primaryPositive, fontSize: textMD),
              ),
            ),
          ],
        );
      }

      // Mode B (OAuth + no repo) or Mode C (OAuth + existing repo without remote)
      return _OAuthCreateRepoDialog(repoAlreadyExists: repoAlreadyExists, providerName: providerName, defaultRepoName: defaultRepoName);
    },
  );
}

class _OAuthCreateRepoDialog extends StatefulWidget {
  final bool repoAlreadyExists;
  final String? providerName;
  final String defaultRepoName;

  const _OAuthCreateRepoDialog({required this.repoAlreadyExists, required this.providerName, required this.defaultRepoName});

  @override
  State<_OAuthCreateRepoDialog> createState() => _OAuthCreateRepoDialogState();
}

class _OAuthCreateRepoDialogState extends State<_OAuthCreateRepoDialog> {
  late final TextEditingController _nameController;
  bool _isPrivate = true;
  bool _initMainBranch = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.defaultRepoName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repoNameEmpty = _nameController.text.trim().isEmpty;

    return BaseAlertDialog(
      title: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Text(
          widget.repoAlreadyExists ? context.t.createRemoteRepo : context.t.createNewRepository,
          style: TextStyle(color: context.colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
        ),
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            SizedBox(height: spaceSM),
            Text(
              widget.repoAlreadyExists ? context.t.noRemoteDetectedMsg : context.t.noGitRepoFoundMsg,
              style: TextStyle(color: context.colours.primaryLight, fontSize: textMD),
            ),
            SizedBox(height: spaceMD),
            Text(
              context.t.repoName.toUpperCase(),
              style: TextStyle(color: context.colours.tertiaryLight, fontSize: textXS, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: spaceXS),
            TextField(
              controller: _nameController,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: context.colours.primaryLight, fontSize: textMD),
              decoration: InputDecoration(
                hintText: context.t.repoName,
                hintStyle: TextStyle(color: context.colours.tertiaryLight, fontSize: textMD),
                filled: true,
                fillColor: context.colours.secondaryDark,
                contentPadding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(cornerRadiusMD),
                  borderSide: BorderSide(color: context.colours.tertiaryDark),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(cornerRadiusMD),
                  borderSide: BorderSide(color: context.colours.tertiaryDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(cornerRadiusMD),
                  borderSide: BorderSide(color: context.colours.tertiaryInfo),
                ),
              ),
            ),
            SizedBox(height: spaceMD),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isPrivate = true),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: spaceSM),
                      decoration: BoxDecoration(
                        color: _isPrivate ? context.colours.tertiaryDark : context.colours.secondaryDark,
                        borderRadius: BorderRadius.horizontal(left: cornerRadiusMD),
                        border: Border.all(color: _isPrivate ? context.colours.tertiaryInfo : context.colours.tertiaryDark),
                      ),
                      child: Text(
                        context.t.repoPrivate.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _isPrivate ? context.colours.primaryLight : context.colours.tertiaryLight,
                          fontSize: textSM,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isPrivate = false),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: spaceSM),
                      decoration: BoxDecoration(
                        color: !_isPrivate ? context.colours.tertiaryDark : context.colours.secondaryDark,
                        borderRadius: BorderRadius.horizontal(right: cornerRadiusMD),
                        border: Border.all(color: !_isPrivate ? context.colours.tertiaryInfo : context.colours.tertiaryDark),
                      ),
                      child: Text(
                        context.t.repoPublic.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: !_isPrivate ? context.colours.primaryLight : context.colours.tertiaryLight,
                          fontSize: textSM,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spaceMD),
            GestureDetector(
              onTap: () => setState(() => _initMainBranch = !_initMainBranch),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _initMainBranch,
                      onChanged: (v) => setState(() => _initMainBranch = v ?? true),
                      activeColor: context.colours.tertiaryInfo,
                      checkColor: context.colours.primaryLight,
                      side: BorderSide(color: context.colours.tertiaryLight),
                    ),
                  ),
                  SizedBox(width: spaceXS),
                  Text(
                    context.t.initMainBranch,
                    style: TextStyle(color: context.colours.primaryLight, fontSize: textSM),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(
            widget.repoAlreadyExists ? context.t.cancel.toUpperCase() : context.t.createLocalOnly.toUpperCase(),
            style: TextStyle(color: context.colours.primaryLight, fontSize: textMD),
          ),
          onPressed: () {
            if (widget.repoAlreadyExists) {
              Navigator.of(context).canPop() ? Navigator.pop(context) : null;
            } else {
              Navigator.of(context).canPop() ? Navigator.pop(context, CreateRepoResult(createLocal: true, createRemote: false)) : null;
            }
          },
        ),
        TextButton(
          onPressed: repoNameEmpty
              ? null
              : () {
                  Navigator.of(context).canPop()
                      ? Navigator.pop(
                          context,
                          CreateRepoResult(
                            createLocal: !widget.repoAlreadyExists,
                            createRemote: true,
                            repoName: _nameController.text.trim(),
                            isPrivate: _isPrivate,
                            initMainBranch: _initMainBranch,
                          ),
                        )
                      : null;
                },
          child: Text(
            context.t.createAndLinkRemote.toUpperCase(),
            style: TextStyle(color: repoNameEmpty ? context.colours.tertiaryLight : context.colours.primaryPositive, fontSize: textMD),
          ),
        ),
      ],
    );
  }
}
