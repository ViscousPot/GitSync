import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/api/manager/auth/git_provider_manager.dart';
import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/constant/strings.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/src/rust/api/git_manager.dart' as GitManagerRs;
import 'package:GitSync/type/git_provider.dart';
import 'package:GitSync/type/showcase_feature.dart';
import 'package:GitSync/ui/component/branch_selector.dart';
import 'package:GitSync/ui/component/commit_select_action_bar.dart';
import 'package:GitSync/ui/component/item_commit.dart';
import 'package:GitSync/ui/component/item_merge_conflict.dart';
import 'package:GitSync/providers/riverpod_providers.dart';
import 'package:GitSync/ui/component/provider_builder.dart';
import 'package:GitSync/ui/component/showcase_feature_button.dart';

class ExpandedCommits extends ConsumerStatefulWidget {
  const ExpandedCommits({
    super.key,
    required this.gitProvider,
    this.remoteWebUrl,
    required this.onBranchChanged,
    required this.onCreateBranch,
    required this.onRenameBranch,
    required this.onDeleteBranch,
    required this.onReloadAll,
    required this.isClientMode,
    this.initialScrollOffset = 0,
    this.pendingFeature,
    this.pendingFeatureIsAdd = false,
    this.isAuthenticated = false,
  });

  final GitProvider? gitProvider;
  final String? remoteWebUrl;
  final bool isClientMode;
  final Future<void> Function(String) onBranchChanged;
  final VoidCallback? onCreateBranch;
  final Future<void> Function(String oldName, String newName) onRenameBranch;
  final Future<void> Function(String branchName) onDeleteBranch;
  final Future<void> Function() onReloadAll;
  final double initialScrollOffset;
  final ShowcaseFeature? pendingFeature;
  final bool pendingFeatureIsAdd;
  final bool isAuthenticated;

  @override
  ConsumerState<ExpandedCommits> createState() => _ExpandedCommitsState();
}

class _ExpandedCommitsState extends ConsumerState<ExpandedCommits> {
  late final ScrollController _scrollController = ScrollController(initialScrollOffset: widget.initialScrollOffset);
  final ValueNotifier<List<ShowcaseFeature>> _pinnedFeatures = ValueNotifier(ShowcaseFeature.defaultPinned);
  final ValueNotifier<Map<ShowcaseFeature, int?>> _featureCounts = ValueNotifier({});
  bool _featureCountsLoading = false;
  final ValueNotifier<bool> _selectMode = ValueNotifier(false);
  final ValueNotifier<Set<String>> _selectedShas = ValueNotifier({});

  @override
  void initState() {
    super.initState();
    _loadPinnedFeatures();
    _fetchFeatureCounts();

    if (widget.pendingFeature != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final animation = ModalRoute.of(context)?.animation;
        if (animation == null || animation.isCompleted) {
          _triggerPendingFeature();
        } else {
          void listener(AnimationStatus status) {
            if (status == AnimationStatus.completed) {
              animation.removeStatusListener(listener);
              _triggerPendingFeature();
            }
          }

          animation.addStatusListener(listener);
        }
      });
    }
  }

  void _triggerPendingFeature() {
    if (!mounted) return;
    if (widget.pendingFeatureIsAdd) {
      resolveFeatureOnAdd(
        context: context,
        feature: widget.pendingFeature!,
        gitProvider: widget.gitProvider,
        remoteWebUrl: widget.remoteWebUrl,
      )?.call();
    } else {
      resolveFeatureOnPressed(
        context: context,
        feature: widget.pendingFeature!,
        gitProvider: widget.gitProvider,
        remoteWebUrl: widget.remoteWebUrl,
      )();
    }
  }

  Future<void> _loadPinnedFeatures() async {
    final keys = await uiSettingsManager.getStringList(StorageKey.setman_pinnedShowcaseFeatures);
    _pinnedFeatures.value = ShowcaseFeature.fromStorageKeys(keys);
  }

  Future<void> _fetchFeatureCounts() async {
    if (widget.remoteWebUrl == null || widget.gitProvider == null) return;
    if (!widget.gitProvider!.isOAuthProvider || !widget.isAuthenticated) return;
    setState(() => _featureCountsLoading = true);
    final githubAppOauth = await uiSettingsManager.getBool(StorageKey.setman_githubScopedOauth);
    final accessToken = (await uiSettingsManager.getGitHttpAuthCredentials()).$2;
    if (accessToken.isEmpty) {
      if (mounted) setState(() => _featureCountsLoading = false);
      return;
    }
    final manager = GitProviderManager.getGitProviderManager(widget.gitProvider!, githubAppOauth);
    if (manager == null) {
      if (mounted) setState(() => _featureCountsLoading = false);
      return;
    }
    final segments = Uri.parse(widget.remoteWebUrl!).pathSegments;
    final owner = segments[0];
    final repo = segments[1].replaceAll(".git", "");
    final counts = await manager.getFeatureCounts(accessToken, owner, repo);
    if (mounted) {
      _featureCounts.value = counts;
      setState(() => _featureCountsLoading = false);
    }
  }

  void _handlePinToggle(ShowcaseFeature feature) {
    final updated = togglePin(_pinnedFeatures.value, feature);
    if (updated == null) return;
    _pinnedFeatures.value = updated;
    uiSettingsManager.setStringList(StorageKey.setman_pinnedShowcaseFeatures, ShowcaseFeature.toStorageKeys(updated));
  }

  List<GitManagerRs.Commit> _buildItems(List<GitManagerRs.Commit> commits, List<(String, GitManagerRs.ConflictType)> conflicting) {
    return [
      ...(conflicting.isEmpty
          ? <GitManagerRs.Commit>[]
          : [
              GitManagerRs.Commit(
                timestamp: 0,
                authorUsername: "",
                authorEmail: "",
                reference: mergeConflictReference,
                commitMessage: "",
                additions: 0,
                deletions: 0,
                unpulled: false,
                unpushed: false,
                tags: [],
              ),
            ]),
      ...commits,
    ];
  }

  void _exitSelectMode() {
    _selectMode.value = false;
    _selectedShas.value = {};
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pinnedFeatures.dispose();
    _featureCounts.dispose();
    _selectMode.dispose();
    _selectedShas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOAuthProvider = widget.gitProvider?.isOAuthProvider ?? false;
    final screenHeight = MediaQuery.of(context).size.height;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (_selectMode.value) {
            _exitSelectMode();
          } else {
            Navigator.of(context).pop(_scrollController.hasClients ? _scrollController.offset : null);
          }
        }
      },
      child: Scaffold(
        backgroundColor: colours.primaryDark,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(spaceMD),
            child: ProviderBuilder<List<GitManagerRs.Commit>>(
              provider: recentCommitsProvider,
              builder: (context, commitsAsync) => ProviderBuilder<List<(String, GitManagerRs.ConflictType)>>(
                provider: conflictingFilesProvider,
                builder: (context, conflictingAsync) => ProviderBuilder<Map<String, String>>(
                  provider: branchNamesProvider,
                  builder: (context, branchNamesAsync) {
                    final branchNamesValue = branchNamesAsync.valueOrNull ?? {};
                    final conflictingValue = conflictingAsync.valueOrNull ?? [];
                    final commitsValue = commitsAsync.valueOrNull ?? [];
                    final items = _buildItems(commitsValue, conflictingValue);

                    return Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(color: colours.secondaryDark, borderRadius: BorderRadius.all(cornerRadiusMD)),
                          padding: EdgeInsets.only(left: spaceSM, bottom: spaceXS, right: spaceSM, top: spaceXS),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Hero(
                                tag: hero_commits_list,
                                child: SizedBox(
                                  height: screenHeight * 0.35,
                                  width: double.infinity,
                                  child: ShaderMask(
                                    shaderCallback: (Rect rect) {
                                      return LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [Colors.black, Colors.transparent, Colors.transparent, Colors.transparent],
                                        stops: [0.0, 0.1, 0.9, 1.0],
                                      ).createShader(rect);
                                    },
                                    blendMode: BlendMode.dstOut,
                                    child: items.isEmpty
                                        ? Center(
                                            child: Text(
                                              t.commitsNotFound.toUpperCase(),
                                              style: TextStyle(color: colours.secondaryLight, fontWeight: FontWeight.bold, fontSize: textLG),
                                            ),
                                          )
                                        : ListView.builder(
                                            controller: _scrollController,
                                            reverse: true,
                                            itemCount: items.length,
                                            itemBuilder: (BuildContext context, int index) {
                                              final reference = items[index].reference;

                                              if (reference == mergeConflictReference) {
                                                return ItemMergeConflict(
                                                  key: Key(reference),
                                                  conflictingValue,
                                                  () async => await widget.onReloadAll(),
                                                  widget.isClientMode,
                                                );
                                              }

                                              return ItemCommit(
                                                key: Key(reference),
                                                items[index],
                                                index < items.length - 1 ? items[index + 1] : null,
                                                commitsValue,
                                                gitProvider: widget.gitProvider,
                                                remoteWebUrl: widget.remoteWebUrl,
                                                onRefresh: () => widget.onReloadAll(),
                                                selectMode: _selectMode,
                                                selectedShas: _selectedShas,
                                                onSelectModeRequested: () {
                                                  _selectMode.value = true;
                                                  _selectedShas.value = {items[index].reference};
                                                },
                                              );
                                            },
                                          ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: -(spaceXS),
                                left: -(spaceSM - spaceXXXXS),
                                child: Stack(
                                  children: [
                                    Hero(
                                      tag: hero_expand_contract,
                                      child: IconButton(
                                        padding: EdgeInsets.all(spaceMD),
                                        style: ButtonStyle(
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          shape: WidgetStatePropertyAll(
                                            RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM).copyWith(topLeft: cornerRadiusMD)),
                                          ),
                                          backgroundColor: WidgetStatePropertyAll(colours.secondaryDark.withOpacity(0.5)),
                                        ),
                                        constraints: BoxConstraints(),
                                        onPressed: () => Navigator.of(context).pop(_scrollController.hasClients ? _scrollController.offset : null),
                                        icon: FaIcon(FontAwesomeIcons.downLeftAndUpRightToCenter, size: textMD, color: colours.primaryLight),
                                      ),
                                    ),
                                    CommitSelectActionBar(
                                      selectMode: _selectMode,
                                      selectedShas: _selectedShas,
                                      commits: commitsValue,
                                      onReloadAll: widget.onReloadAll,
                                      onExitSelectMode: _exitSelectMode,
                                      borderRadius: BorderRadius.all(cornerRadiusSM).copyWith(topLeft: cornerRadiusMD),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: -spaceMD,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Text(
                                    t.recentCommits.toUpperCase(),
                                    style: TextStyle(color: colours.tertiaryLight, fontSize: textXXS, fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: spaceMD),
                        ProviderBuilder<String?>(
                          provider: branchNameProvider,
                          builder: (context, branchNameAsync) {
                            final branchNameValue = branchNameAsync.valueOrNull;
                            final hasBranch = branchNamesValue.containsKey(branchNameValue);
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  decoration: BoxDecoration(color: colours.secondaryDark, borderRadius: BorderRadius.all(cornerRadiusMD)),
                                  padding: EdgeInsets.only(left: spaceSM, bottom: spaceXS, right: spaceSM, top: spaceXS),
                                  child: Column(
                                    children: [
                                      ProviderBuilder<bool>(
                                        provider: conflictingFilesProvider.select((v) => v.whenData((d) => d.isNotEmpty)),
                                        builder: (context, hasConflictsAsync) => BranchSelector(
                                          branchName: branchNameValue,
                                          branchNames: branchNamesValue,
                                          hasConflicts: hasConflictsAsync.valueOrNull ?? false,
                                          showLabel: false,
                                          dropdownDecoration: BoxDecoration(
                                            color: colours.tertiaryDark,
                                            borderRadius: BorderRadius.all(cornerRadiusSM),
                                          ),
                                          onCheckoutBranch: (item) async => await widget.onBranchChanged(item),
                                          onRenameBranch: (oldName, newName) async => await widget.onRenameBranch(oldName, newName),
                                          onDeleteBranch: (item) async => await widget.onDeleteBranch(item),
                                          onCreateBranch: hasBranch ? () => widget.onCreateBranch?.call() : null,
                                        ),
                                      ),
                                      // SizedBox(height: spaceXS),
                                      // Row(
                                      //   children: [
                                      //     Expanded(
                                      //       child: TextButton.icon(
                                      //         onPressed: () {},
                                      //         icon: FaIcon(FontAwesomeIcons.arrowsRotate, color: colours.primaryLight, size: textMD),
                                      //         label: Text(
                                      //           'UPDATE FROM MAIN',
                                      //           maxLines: 1,
                                      //           overflow: TextOverflow.ellipsis,
                                      //           style: TextStyle(color: colours.primaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                                      //         ),
                                      //         style: TextButton.styleFrom(
                                      //           backgroundColor: colours.tertiaryDark,
                                      //           padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceXS),
                                      //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM), side: BorderSide.none),
                                      //         ),
                                      //       ),
                                      //     ),
                                      //     SizedBox(width: spaceXS),
                                      //     Expanded(
                                      //       child: TextButton.icon(
                                      //         onPressed: () {},
                                      //         icon: FaIcon(FontAwesomeIcons.codeCompare, color: colours.primaryLight, size: textMD),
                                      //         label: Text(
                                      //           'COMPARE TO BRANCH',
                                      //           maxLines: 1,
                                      //           overflow: TextOverflow.ellipsis,
                                      //           style: TextStyle(color: colours.primaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                                      //         ),
                                      //         style: TextButton.styleFrom(
                                      //           backgroundColor: colours.tertiaryDark,
                                      //           padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceXS),
                                      //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM), side: BorderSide.none),
                                      //         ),
                                      //       ),
                                      //     ),
                                      //   ],
                                      // ),
                                      // Row(
                                      //   children: [
                                      //     Expanded(
                                      //       child: TextButton.icon(
                                      //         onPressed: () {},
                                      //         icon: FaIcon(FontAwesomeIcons.codeMerge, color: colours.primaryLight, size: textMD),
                                      //         label: Text(
                                      //           'MERGE INTO BRANCH',
                                      //           maxLines: 1,
                                      //           overflow: TextOverflow.ellipsis,
                                      //           style: TextStyle(color: colours.primaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                                      //         ),
                                      //         style: TextButton.styleFrom(
                                      //           backgroundColor: colours.tertiaryDark,
                                      //           padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceXS),
                                      //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM), side: BorderSide.none),
                                      //         ),
                                      //       ),
                                      //     ),
                                      //     SizedBox(width: spaceXS),
                                      //     Expanded(
                                      //       child: TextButton.icon(
                                      //         onPressed: () {},
                                      //         icon: FaIcon(FontAwesomeIcons.layerGroup, color: colours.primaryLight, size: textMD),
                                      //         label: Text(
                                      //           'SQUASH & MERGE',
                                      //           maxLines: 1,
                                      //           overflow: TextOverflow.ellipsis,
                                      //           style: TextStyle(color: colours.primaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                                      //         ),
                                      //         style: TextButton.styleFrom(
                                      //           backgroundColor: colours.tertiaryDark,
                                      //           padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceXS),
                                      //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM), side: BorderSide.none),
                                      //         ),
                                      //       ),
                                      //     ),
                                      //   ],
                                      // ),
                                      // Row(
                                      //   children: [
                                      //     Expanded(
                                      //       child: TextButton.icon(
                                      //         onPressed: () {},
                                      //         icon: FaIcon(FontAwesomeIcons.diagramNext, color: colours.primaryLight, size: textMD),
                                      //         label: Text(
                                      //           'REBASE',
                                      //           maxLines: 1,
                                      //           overflow: TextOverflow.ellipsis,
                                      //           style: TextStyle(color: colours.primaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                                      //         ),
                                      //         style: TextButton.styleFrom(
                                      //           backgroundColor: colours.tertiaryDark,
                                      //           padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceXS),
                                      //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM), side: BorderSide.none),
                                      //         ),
                                      //       ),
                                      //     ),
                                      //   ],
                                      // ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: -spaceXS,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Text(
                                      t.branchManagement.toUpperCase(),
                                      style: TextStyle(color: colours.tertiaryLight, fontSize: textXXS, fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        SizedBox(height: spaceMD),
                        if (isOAuthProvider && widget.isAuthenticated && widget.remoteWebUrl != null) ...[
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                decoration: BoxDecoration(color: colours.secondaryDark, borderRadius: BorderRadius.all(cornerRadiusMD)),
                                padding: EdgeInsets.only(left: spaceSM, bottom: spaceXS, right: spaceSM, top: spaceXS),
                                child: ValueListenableBuilder<Map<ShowcaseFeature, int?>>(
                                  valueListenable: _featureCounts,
                                  builder: (context, featureCounts, _) => ValueListenableBuilder<List<ShowcaseFeature>>(
                                    valueListenable: _pinnedFeatures,
                                    builder: (context, pinned, _) {
                                      final features = ShowcaseFeature.availableFor(widget.gitProvider);
                                      final rows = <Widget>[];
                                      for (var i = 0; i < features.length; i += 2) {
                                        final first = features[i];
                                        final second = i + 1 < features.length ? features[i + 1] : null;
                                        rows.add(
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Hero(
                                                  tag: heroShowcaseFeature(first.storageKey),
                                                  child: ShowcaseFeatureButton(
                                                    feature: first,
                                                    gitProvider: widget.gitProvider,
                                                    isPinned: pinned.contains(first),
                                                    count: featureCounts[first],
                                                    countLoading: _featureCountsLoading,
                                                    onPinToggle: () => _handlePinToggle(first),
                                                    onAdd: resolveFeatureOnAdd(
                                                      context: context,
                                                      feature: first,
                                                      gitProvider: widget.gitProvider,
                                                      remoteWebUrl: widget.remoteWebUrl,
                                                    ),
                                                    onPressed: resolveFeatureOnPressed(
                                                      context: context,
                                                      feature: first,
                                                      gitProvider: widget.gitProvider,
                                                      remoteWebUrl: widget.remoteWebUrl,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              if (second != null) ...[
                                                SizedBox(width: spaceXS),
                                                Expanded(
                                                  child: Hero(
                                                    tag: heroShowcaseFeature(second.storageKey),
                                                    child: ShowcaseFeatureButton(
                                                      feature: second,
                                                      gitProvider: widget.gitProvider,
                                                      isPinned: pinned.contains(second),
                                                      count: featureCounts[second],
                                                      countLoading: _featureCountsLoading,
                                                      onPinToggle: () => _handlePinToggle(second),
                                                      onAdd: resolveFeatureOnAdd(
                                                        context: context,
                                                        feature: second,
                                                        gitProvider: widget.gitProvider,
                                                        remoteWebUrl: widget.remoteWebUrl,
                                                      ),
                                                      onPressed: resolveFeatureOnPressed(
                                                        context: context,
                                                        feature: second,
                                                        gitProvider: widget.gitProvider,
                                                        remoteWebUrl: widget.remoteWebUrl,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        );
                                      }
                                      return Column(spacing: spaceXS, children: rows);
                                    },
                                  ),
                                ),
                              ),
                              Positioned(
                                top: -spaceXS,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Text(
                                    t.providerTools.toUpperCase(),
                                    style: TextStyle(color: colours.tertiaryLight, fontSize: textXXS, fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Route createExpandedCommitsRoute({
  required GitProvider? gitProvider,
  String? remoteWebUrl,
  required Future<void> Function(String) onBranchChanged,
  required VoidCallback? onCreateBranch,
  required Future<void> Function(String oldName, String newName) onRenameBranch,
  required Future<void> Function(String branchName) onDeleteBranch,
  required Future<void> Function() onReloadAll,
  required bool isClientMode,
  double initialScrollOffset = 0,
  ShowcaseFeature? pendingFeature,
  bool pendingFeatureIsAdd = false,
  bool isAuthenticated = false,
}) {
  return PageRouteBuilder(
    settings: const RouteSettings(name: expanded_commits),
    pageBuilder: (context, animation, secondaryAnimation) => ExpandedCommits(
      gitProvider: gitProvider,
      remoteWebUrl: remoteWebUrl,
      onBranchChanged: onBranchChanged,
      onCreateBranch: onCreateBranch,
      isClientMode: isClientMode,
      onRenameBranch: onRenameBranch,
      onDeleteBranch: onDeleteBranch,
      onReloadAll: onReloadAll,
      initialScrollOffset: initialScrollOffset,
      pendingFeature: pendingFeature,
      pendingFeatureIsAdd: pendingFeatureIsAdd,
      isAuthenticated: isAuthenticated,
    ),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
