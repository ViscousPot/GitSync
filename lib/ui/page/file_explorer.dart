import 'dart:io';
import 'dart:math' as math;

import 'package:GitSync/api/helper.dart';
import 'package:GitSync/constant/colors.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/constant/values.dart';
import 'package:GitSync/ui/dialog/create_folder.dart' as CreateFolderDialog;
import 'package:GitSync/ui/dialog/create_file.dart' as CreateFileDialog;
import 'package:GitSync/ui/dialog/rename_file_folder.dart' as RenameFileFolderDialog;
import 'package:GitSync/ui/dialog/confirm_delete_file_folder.dart' as ConfirmDeleteFileFolderDialog;
import 'package:GitSync/ui/page/code_editor.dart';
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
      setState(() {});
    }
  }

  String getPathLeadingText() => widget.path.replaceFirst(RegExp(r'/[^/]+$'), '/');

  @override
  Widget build(BuildContext context) {
    print(controller.getPathNotifier);
    print(widget.path);

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
            builder: (context, currentPath, child) =>
                getBackButton(context, () {
                  selectedPathsNotifier.value.isNotEmpty
                      ? selectedPathsNotifier.value = []
                      : (controller.getCurrentPath.replaceFirst(RegExp(r'/$'), '') == widget.path.replaceFirst(RegExp(r'/$'), '')
                            ? (Navigator.of(context).canPop() ? Navigator.pop(context) : null)
                            : controller.goToParentDirectory());
                }) ??
                SizedBox.shrink(),
          ),
          title: ValueListenableBuilder(
            valueListenable: controller.getPathNotifier,
            builder: (context, currentPath, child) => Text(
              currentPath.replaceFirst(getPathLeadingText(), ""),
              style: TextStyle(fontSize: textLG, color: primaryLight, fontWeight: FontWeight.bold),
            ),
          ),
          actions: [
            ValueListenableBuilder(
              valueListenable: selectedPathsNotifier,
              builder: (context, selectedPaths, child) => Row(
                children: selectedPaths.isNotEmpty
                    ? [
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
                                controller.setCurrentPath = "${controller.getCurrentPath.replaceFirst(RegExp(r'/$'), '')}/";
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
                        if (selectedPaths.length <= 1)
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
                              // selectedPaths.remove(path);
                              return;
                            }
                            if (selectedPaths.isNotEmpty) {
                              selectedPathsNotifier.value = [...selectedPathsNotifier.value, path];
                              // selectedPaths.add(path);
                              return;
                            }
                            if (longPressTriggered) return;

                            if (FileManager.isDirectory(entities[index])) {
                              controller.openDirectory(entities[index]);
                            } else {
                              try {
                                File(entities[index].path).readAsStringSync();
                                await Navigator.of(context).push(createCodeEditorRoute(entities[index].path));
                              } catch (e) {
                                print(e);
                                Fluttertoast.showToast(msg: "Editing unavailable", toastLength: Toast.LENGTH_LONG, gravity: null);
                              }
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
                                                    : FontAwesomeIcons.file)
                                              : FontAwesomeIcons.folder)
                                        : (isFile
                                              ? (extensionToLanguageMap.keys.contains(p.extension(entities[index].path).replaceFirst('.', ''))
                                                    ? FontAwesomeIcons.solidFileLines
                                                    : FontAwesomeIcons.solidFile)
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
    settings: const RouteSettings(name: settings_main),
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
