import 'dart:io';

import 'package:GitSync/api/helper.dart';
import 'package:GitSync/api/manager/git_manager.dart';
import 'package:GitSync/constant/colors.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/constant/values.dart';
import 'package:GitSync/ui/dialog/create_folder.dart' as CreateFolderDialog;
import 'package:GitSync/ui/dialog/create_file.dart' as CreateFileDialog;
import 'package:GitSync/ui/dialog/diff_view.dart' as DiffViewDialog;
import 'package:GitSync/ui/dialog/rename_file_folder.dart' as RenameFileFolderDialog;
import 'package:GitSync/ui/dialog/confirm_delete_file_folder.dart' as ConfirmDeleteFileFolderDialog;
import 'package:GitSync/ui/page/code_editor.dart';
import 'package:GitSync/ui/page/image_viewer.dart';
import 'package:collection/collection.dart';
import 'package:extended_text/extended_text.dart';
import 'package:file_manager/file_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../constant/strings.dart';
import 'package:path/path.dart' as p;

class FileExplorer extends StatefulWidget {
  const FileExplorer({super.key, required this.path});

  final String path;

  @override
  State<FileExplorer> createState() => _FileExplorer();
}

class _FileExplorer extends State<FileExplorer> with WidgetsBindingObserver {
  final FileManagerController controller = FileManagerController();
  final ValueNotifier<List<String>> selectedPathsNotifier = ValueNotifier([]);
  final ValueNotifier<List<String>> heldPathsNotifier = ValueNotifier([]);
  bool? copyingMoving = null;
  bool pasting = false;
  bool loadingMore = false;

  final moreOptionsDropdownKey = GlobalKey();
  List<((String, String), Function(List<String>))> get singleSelectOptions => [
    if (viewOrEditFile(context, selectedPathsNotifier.value[0], true))
      (
        ("open file", "Preview/edit file contents"),
        (List<String> selectedPaths) async {
          print("${selectedPathsNotifier.value[0]}");
          initAsync(() async {
            viewOrEditFile(context, selectedPathsNotifier.value[0]);
          });
        },
      ),
    (
      ("view git log", "View the full git log history"),
      (List<String> selectedPaths) async {
        final path = selectedPathsNotifier.value[0];
        final diff = await GitManager.getFileDiff(path.replaceAll("${widget.path}/", ""));
        if (diff == null) return;
        await DiffViewDialog.showDialog(context, diff, path.replaceAll("${widget.path}/", ""), null);

        print(diff.deletions);
        print(diff.insertions);
      },
    ),
  ];

  List<((String, String), Function(List<String>))> get ignoreAndUntrackOptions => [
    (
      (".gitignore + untrack", "Add files to .gitignore and untrack"),
      (List<String> selectedPaths) async {
        addToIgnore(selectedPaths, gitIgnorePath);
        await GitManager.untrackAll(selectedPaths);
      },
    ),
    (
      (".git/info/exclude + untrack", "Add files to the local exclude file and untrack"),
      (List<String> selectedPaths) async {
        addToIgnore(selectedPaths, gitInfoExcludePath);
        await GitManager.untrackAll(selectedPaths);
      },
    ),
    (
      ("add to .gitignore only", "Only add files to .gitignore"),
      (List<String> selectedPaths) async {
        addToIgnore(selectedPaths, gitIgnorePath);
      },
    ),
    (
      ("add to .git/info/exclude only", "Only add files to the local exclude file"),
      (List<String> selectedPaths) async {
        addToIgnore(selectedPaths, gitInfoExcludePath);
      },
    ),
    (
      ("untrack file(s)", "Untrack specified file(s)"),
      (List<String> selectedPaths) async {
        await GitManager.untrackAll(selectedPaths);
      },
    ),
  ];

  void addToIgnore(List<String> selectedPaths, [String path = gitIgnorePath]) {
    final ignoreFullPath = '${widget.path}/$path';
    final file = File(ignoreFullPath);
    final parentDir = file.parent;
    if (!parentDir.existsSync()) {
      parentDir.createSync(recursive: true);
    }
    if (!file.existsSync()) file.createSync();
    final lines = file.readAsLinesSync();
    for (final filePath in selectedPaths) {
      if (!lines.contains(filePath)) {
        file.writeAsStringSync("\n$filePath\n", mode: FileMode.append);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller.setCurrentPath = widget.path;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      final destinationPath = controller.getCurrentPath;
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        controller.setCurrentPath = destinationPath;
      });
    }
  }

  String getPathLeadingText() => widget.path.replaceFirst(RegExp(r'/[^/]+$'), '/');

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (selectedPathsNotifier.value.isNotEmpty) {
          selectedPathsNotifier.value = [];
          return false;
        }
        if (controller.getCurrentPath.replaceFirst(RegExp(r'/$'), '') == widget.path.replaceFirst(RegExp(r'/$'), '')) {
          return true;
        } else {
          controller.goToParentDirectory();
          return false;
        }
      },
      child: Scaffold(
        backgroundColor: secondaryDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: secondaryDark,
            systemNavigationBarColor: secondaryDark,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarIconBrightness: Brightness.light,
          ),
          leading: ValueListenableBuilder(
            valueListenable: controller.getPathNotifier,
            builder: (context, currentPath, child) => getBackButton(context, () {
              if (selectedPathsNotifier.value.isNotEmpty) {
                selectedPathsNotifier.value = [];
              } else {
                if (controller.getCurrentPath.replaceFirst(RegExp(r'/$'), '') == widget.path.replaceFirst(RegExp(r'/$'), '')) {
                  if (heldPathsNotifier.value.isNotEmpty) {
                    heldPathsNotifier.value = [];
                  } else {
                    (Navigator.of(context).canPop() ? Navigator.pop(context) : null);
                  }
                } else {
                  controller.goToParentDirectory();
                }
              }
            }),
          ),
          title: ValueListenableBuilder(
            valueListenable: controller.getPathNotifier,
            builder: (context, currentPath, child) => ValueListenableBuilder(
              valueListenable: heldPathsNotifier,
              builder: (context, heldPaths, child) => heldPaths.isNotEmpty
                  ? Text(
                      "(${heldPaths.length}) file${heldPaths.length > 1 ? "s" : ""} selected",
                      style: TextStyle(fontSize: textLG, color: primaryLight, fontWeight: FontWeight.bold),
                    )
                  : ExtendedText(
                      currentPath.replaceFirst(getPathLeadingText(), ""),
                      maxLines: 1,
                      textAlign: TextAlign.left,
                      softWrap: false,
                      overflowWidget: TextOverflowWidget(
                        position: TextOverflowPosition.start,
                        child: Text(
                          "…",
                          style: TextStyle(fontSize: textLG, color: primaryLight, fontWeight: FontWeight.bold),
                        ),
                      ),
                      style: TextStyle(fontSize: textLG, color: primaryLight, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          actions: [
            ValueListenableBuilder(
              valueListenable: heldPathsNotifier,
              builder: (context, heldPaths, child) => ValueListenableBuilder(
                valueListenable: selectedPathsNotifier,
                builder: (context, selectedPaths, child) => Row(
                  children: selectedPaths.isNotEmpty
                      ? [
                          Stack(
                            children: [
                              IconButton(
                                onPressed: () async {
                                  GestureDetector? detector;

                                  void searchForGestureDetector(BuildContext? element) {
                                    element?.visitChildElements((element) {
                                      if (element.widget is GestureDetector) {
                                        detector = element.widget as GestureDetector;
                                        return;
                                      } else {
                                        searchForGestureDetector(element);
                                      }

                                      return;
                                    });
                                  }

                                  searchForGestureDetector(moreOptionsDropdownKey.currentContext);

                                  if (detector?.onTap != null) detector?.onTap!();
                                },
                                style: ButtonStyle(
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  padding: WidgetStatePropertyAll(EdgeInsets.all(spaceXXS)),
                                ),
                                icon: loadingMore
                                    ? SizedBox.square(
                                        dimension: textLG,
                                        child: CircularProgressIndicator(color: primaryLight),
                                      )
                                    : FaIcon(FontAwesomeIcons.ellipsisVertical, color: primaryLight, size: textLG),
                              ),
                              Positioned(
                                top: spaceLG * 1.5,
                                child: DropdownButton(
                                  key: moreOptionsDropdownKey,
                                  borderRadius: BorderRadius.all(cornerRadiusSM),
                                  selectedItemBuilder: (context) => List.generate(1, (_) => SizedBox.shrink()),
                                  icon: SizedBox.shrink(),
                                  underline: const SizedBox.shrink(),
                                  menuWidth: MediaQuery.of(context).size.width / 1.5,
                                  dropdownColor: secondaryDark,
                                  padding: EdgeInsets.zero,
                                  alignment: Alignment.bottomCenter,
                                  onChanged: (value) {},
                                  items: [if (selectedPaths.length == 1) ...singleSelectOptions, "ignoreAndUntrack", ...ignoreAndUntrackOptions].map((
                                    option,
                                  ) {
                                    if (option is String) {
                                      switch (option) {
                                        case "ignoreAndUntrack":
                                          return DropdownMenuItem(
                                            value: null,
                                            onTap: () {},
                                            enabled: false,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                // Text("", style: TextStyle(fontSize: textSM)),
                                                Container(
                                                  margin: EdgeInsets.symmetric(horizontal: spaceMD),
                                                  color: tertiaryDark,
                                                  height: 2,
                                                  width: double.infinity,
                                                ),
                                                SizedBox(height: spaceXXXS),
                                                Text(
                                                  "Ignore & Untrack".toUpperCase(),
                                                  style: TextStyle(color: tertiaryInfo, fontSize: textSM, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          );
                                      }
                                    }
                                    if (option is ((String, String), dynamic Function(List<String>))) {
                                      return DropdownMenuItem(
                                        onTap: () async {
                                          loadingMore = true;
                                          setState(() {});
                                          await option.$2(selectedPaths.map((path) => path.replaceFirst("${widget.path}/", "")).toList());
                                          loadingMore = false;
                                          setState(() {});
                                          selectedPathsNotifier.value = [];
                                        },
                                        value: option.$1.$1,
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(vertical: spaceXXS),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  option.$1.$1.toUpperCase(),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: textSM,
                                                    color: primaryLight,
                                                    fontWeight: FontWeight.bold,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: spaceXS),
                                              Flexible(
                                                child: Text(
                                                  option.$1.$2,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: textXS,
                                                    color: secondaryLight,
                                                    fontWeight: FontWeight.bold,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }

                                    return DropdownMenuItem(child: SizedBox.shrink());
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: spaceXXS),
                          if (selectedPaths.length <= 1) ...[
                            IconButton(
                              onPressed: () async {
                                final oldPath = selectedPaths[0];
                                final entity = FileSystemEntity.typeSync(oldPath);
                                if (entity == FileSystemEntityType.notFound) {
                                  throw Exception('Path does not exist.');
                                }

                                RenameFileFolderDialog.showDialog(context, p.basename(oldPath), entity == FileSystemEntityType.directory, (
                                  fileName,
                                ) async {
                                  final dir = p.dirname(oldPath);
                                  final newPath = p.join(dir, fileName);

                                  try {
                                    if (entity == FileSystemEntityType.directory) {
                                      await Directory(oldPath).rename(newPath);
                                    } else {
                                      await File(oldPath).rename(newPath);
                                    }
                                  } catch (e) {
                                    Fluttertoast.showToast(msg: "Failed to rename file/directory: $e", toastLength: Toast.LENGTH_LONG, gravity: null);
                                  }
                                  selectedPathsNotifier.value = [];
                                  controller.setCurrentPath = "${controller.getCurrentPath.replaceFirst(RegExp(r'/$'), '')}/";
                                });
                              },
                              style: ButtonStyle(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: WidgetStatePropertyAll(EdgeInsets.all(spaceXXS)),
                              ),
                              icon: FaIcon(FontAwesomeIcons.pen, color: tertiaryInfo, size: textLG),
                            ),
                            SizedBox(width: spaceXXS),
                          ],
                          IconButton(
                            onPressed: () async {
                              ConfirmDeleteFileFolderDialog.showDialog(context, selectedPaths, () async {
                                for (var path in selectedPaths) {
                                  final entity = FileSystemEntity.typeSync(path);
                                  if (entity == FileSystemEntityType.notFound) {
                                    throw Exception('Path does not exist.');
                                  }

                                  try {
                                    if (entity == FileSystemEntityType.directory) {
                                      await Directory(path).delete();
                                    } else {
                                      await File(path).delete();
                                    }
                                  } catch (e) {
                                    Fluttertoast.showToast(msg: "Failed to delete file/directory: $e", toastLength: Toast.LENGTH_LONG, gravity: null);
                                  }

                                  selectedPathsNotifier.value = [];
                                  final destinationPath = controller.getCurrentPath;
                                  setState(() {});
                                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                                    controller.setCurrentPath = destinationPath;
                                  });
                                }
                              });
                            },
                            style: ButtonStyle(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: WidgetStatePropertyAll(EdgeInsets.all(spaceXXS)),
                            ),
                            icon: FaIcon(FontAwesomeIcons.trash, color: tertiaryNegative, size: textLG),
                          ),
                          SizedBox(width: spaceXXS),
                          IconButton(
                            onPressed: () async {
                              heldPathsNotifier.value = selectedPaths;
                              selectedPathsNotifier.value = [];
                              copyingMoving = true;
                            },
                            style: ButtonStyle(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: WidgetStatePropertyAll(EdgeInsets.all(spaceXXS)),
                            ),
                            icon: FaIcon(FontAwesomeIcons.solidCopy, color: tertiaryInfo, size: textLG),
                          ),
                          SizedBox(width: spaceXXS),
                          IconButton(
                            onPressed: () async {
                              heldPathsNotifier.value = selectedPaths;
                              copyingMoving = false;
                              selectedPathsNotifier.value = [];
                            },
                            style: ButtonStyle(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: WidgetStatePropertyAll(EdgeInsets.all(spaceXXS)),
                            ),
                            icon: FaIcon(FontAwesomeIcons.scissors, color: tertiaryInfo, size: textLG),
                          ),
                          SizedBox(width: spaceMD),
                        ]
                      : heldPaths.isNotEmpty
                      ? [
                          IconButton(
                            onPressed: pasting
                                ? null
                                : () async {
                                    final destinationPath = controller.getCurrentPath;
                                    for (String filePath in heldPathsNotifier.value) {
                                      File sourceFile = File(filePath);
                                      String fileName = sourceFile.uri.pathSegments.last;
                                      File destinationFile = File('$destinationPath/$fileName');

                                      pasting = true;
                                      setState(() {});
                                      try {
                                        if (copyingMoving == false) {
                                          // Move the file
                                          await sourceFile.rename(destinationFile.path);
                                          print('Moved: ${sourceFile.path} to ${destinationFile.path}');
                                        } else {
                                          // Copy the file
                                          await sourceFile.copy(destinationFile.path);
                                          print('Copied: ${sourceFile.path} to ${destinationFile.path}');
                                        }
                                      } catch (e) {
                                        print('Error: $e');
                                      }
                                      pasting = false;
                                      setState(() {});
                                    }

                                    heldPathsNotifier.value = [];
                                    setState(() {});

                                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                                      controller.setCurrentPath = destinationPath;
                                    });

                                    // print(heldPathsNotifier.value);
                                    // print(copyingMoving);
                                    // print(controller.getCurrentPath);
                                  },
                            style: ButtonStyle(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: WidgetStatePropertyAll(EdgeInsets.all(spaceXXS)),
                            ),
                            icon: pasting
                                ? SizedBox.square(
                                    dimension: textLG,
                                    child: CircularProgressIndicator(color: tertiaryInfo),
                                  )
                                : FaIcon(FontAwesomeIcons.solidPaste, color: tertiaryInfo, size: textLG),
                          ),
                          SizedBox(width: spaceXXS),
                          IconButton(
                            onPressed: () {
                              heldPathsNotifier.value = [];
                            },
                            icon: FaIcon(FontAwesomeIcons.solidCircleXmark, color: primaryLight, size: textLG),
                          ),
                          SizedBox(width: spaceMD),
                        ]
                      : [
                          IconButton(
                            onPressed: () async {
                              CreateFolderDialog.showDialog(context, (folderName) async {
                                try {
                                  await Directory("${controller.getCurrentPath.replaceFirst(RegExp(r'/$'), '')}/$folderName").create();
                                } catch (e) {
                                  Fluttertoast.showToast(msg: "Failed to create directory: $e", toastLength: Toast.LENGTH_LONG, gravity: null);
                                }
                                await Directory("${controller.getCurrentPath.replaceFirst(RegExp(r'/$'), '')}/$folderName").create();
                                controller.setCurrentPath = "${controller.getCurrentPath.replaceFirst(RegExp(r'/$'), '')}/$folderName";
                              });
                            },
                            style: ButtonStyle(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: WidgetStatePropertyAll(EdgeInsets.all(spaceXXS)),
                            ),
                            icon: FaIcon(FontAwesomeIcons.folderPlus, color: primaryLight, size: textLG),
                          ),
                          SizedBox(width: spaceXXS),
                          IconButton(
                            onPressed: () async {
                              CreateFileDialog.showDialog(context, (fileName) async {
                                try {
                                  await File("${controller.getCurrentPath.replaceFirst(RegExp(r'/$'), '')}/$fileName").create();
                                } catch (e) {
                                  Fluttertoast.showToast(msg: "Failed to create file: $e", toastLength: Toast.LENGTH_LONG, gravity: null);
                                }
                                controller.setCurrentPath = "${controller.getCurrentPath.replaceFirst(RegExp(r'/$'), '')}/";
                              });
                            },
                            style: ButtonStyle(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: WidgetStatePropertyAll(EdgeInsets.all(spaceXXS)),
                            ),
                            icon: FaIcon(FontAwesomeIcons.fileCirclePlus, color: primaryLight, size: textLG),
                          ),
                          SizedBox(width: spaceMD),
                        ],
                ),
              ),
            ),
          ],
        ),
        body: FileManager(
          controller: controller,
          hideHiddenEntity: false,
          loadingScreen: Center(child: CircularProgressIndicator(color: primaryLight)),
          builder: (context, snapshot) {
            final List<FileSystemEntity> entities = snapshot;

            return ValueListenableBuilder(
              valueListenable: selectedPathsNotifier,
              builder: (context, selectedPaths, child) => Padding(
                padding: EdgeInsets.symmetric(horizontal: spaceMD),
                child: ListView.builder(
                  itemCount: entities.length,
                  itemBuilder: (context, index) {
                    final isHidden = FileManager.basename(entities[index]) == "" || FileManager.basename(entities[index]).startsWith('.');
                    final isFile = FileManager.isFile(entities[index]);
                    final path = entities[index].path;
                    bool longPressTriggered = false;

                    return Padding(
                      padding: EdgeInsets.only(bottom: spaceSM),
                      child: Material(
                        color: selectedPaths.contains(path) ? tertiaryLight : tertiaryDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM), side: BorderSide.none),
                        child: InkWell(
                          onTap: () async {
                            if (selectedPaths.contains(path)) {
                              selectedPathsNotifier.value = selectedPathsNotifier.value.where((p) => p != path).toList();
                              return;
                            }
                            if (selectedPaths.isNotEmpty) {
                              selectedPathsNotifier.value = [...selectedPathsNotifier.value, path];
                              return;
                            }
                            if (longPressTriggered) return;

                            if (FileManager.isDirectory(entities[index])) {
                              controller.openDirectory(entities[index]);
                            } else {
                              viewOrEditFile(context, path);
                            }
                          },
                          onLongPress: () {
                            longPressTriggered = true;
                            if (selectedPaths.contains(path)) {
                              selectedPathsNotifier.value = selectedPathsNotifier.value.where((p) => p != path).toList();
                            } else {
                              selectedPathsNotifier.value = [...selectedPathsNotifier.value, path];
                            }
                          },
                          onHighlightChanged: (value) {
                            if (!value) longPressTriggered = false;
                          },
                          borderRadius: BorderRadius.all(cornerRadiusSM),
                          child: Padding(
                            padding: EdgeInsets.all(spaceSM),
                            child: Row(
                              children: [
                                Container(
                                  width: textMD,
                                  margin: EdgeInsets.all(spaceXS),
                                  child: FaIcon(
                                    isHidden
                                        ? (isFile
                                              ? (extensionToLanguageMap.keys.contains(p.extension(entities[index].path).replaceFirst('.', ''))
                                                    ? FontAwesomeIcons.fileLines
                                                    : (imageExtensions.any((item) => entities[index].path.endsWith(item))
                                                          ? FontAwesomeIcons.fileImage
                                                          : FontAwesomeIcons.file))
                                              : FontAwesomeIcons.folder)
                                        : (isFile
                                              ? (extensionToLanguageMap.keys.contains(p.extension(entities[index].path).replaceFirst('.', ''))
                                                    ? FontAwesomeIcons.solidFileLines
                                                    : (imageExtensions.any((item) => entities[index].path.endsWith(item))
                                                          ? FontAwesomeIcons.solidFileImage
                                                          : FontAwesomeIcons.solidFile))
                                              : FontAwesomeIcons.solidFolder),
                                    color: isFile
                                        ? (selectedPaths.contains(path) ? primaryLight : secondaryLight)
                                        : (selectedPaths.contains(path) ? tertiaryInfo : primaryInfo),
                                    size: textMD,
                                  ),
                                ),
                                SizedBox(width: spaceSM),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        FileManager.basename(entities[index]),
                                        style: TextStyle(color: primaryLight, fontSize: textMD, overflow: TextOverflow.ellipsis),
                                      ),
                                      FutureBuilder<FileStat>(
                                        future: entities[index].stat(),
                                        builder: (context, snapshot) => Text(
                                          snapshot.hasData
                                              ? (entities[index] is File
                                                    ? formatBytes(snapshot.data!.size)
                                                    : "${snapshot.data!.modified}".substring(0, 10))
                                              : "",
                                          style: TextStyle(color: (selectedPaths.contains(path) ? primaryLight : secondaryLight), fontSize: textSM),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

Route createFileExplorerRoute(String path) {
  return PageRouteBuilder(
    settings: const RouteSettings(name: file_explorer),
    pageBuilder: (context, animation, secondaryAnimation) => FileExplorer(path: path),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      const curve = Curves.ease;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}
