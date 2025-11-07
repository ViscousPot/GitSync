import 'dart:async';

import 'package:GitSync/api/manager/storage.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/api/accessibility_service_helper.dart';
import 'package:GitSync/api/helper.dart';
import 'package:GitSync/constant/strings.dart';
import '../../../constant/colors.dart';
import '../../../constant/dimens.dart';
import '../../../global.dart';
import '../../../ui/dialog/base_alert_dialog.dart';
import 'package:flutter/services.dart';

Future<void> showDialog(BuildContext parentContext, Set<String>? prevSelectedApplications) async {
  final List<String> selectedApplications = prevSelectedApplications?.toList() ?? [];
  final searchController = TextEditingController();
  final Map<String, Uint8List?> iconCache = {};
  final Map<String, String> labelCache = {};
  bool initialised = false;
  List<String> originalDeviceApplications = [];
  List<String>? deviceApplications;

  return await mat.showDialog(
    context: parentContext,
    builder: (BuildContext context) => BaseAlertDialog(
      title: Center(
        child: Text(
          t.selectApplication.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(color: primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
        ),
      ),
      content: StatefulBuilder(
        builder: (BuildContext context, setState) {
          initAsync(() async {
            if (initialised) return;

            initialised = true;
            originalDeviceApplications = await AccessibilityServiceHelper.getDeviceApplications();
            deviceApplications = [...originalDeviceApplications];
            setState(() {});
          });
          return SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  contextMenuBuilder: globalContextMenuBuilder,
                  controller: searchController,
                  maxLines: 1,
                  style: TextStyle(
                    color: primaryLight,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                    decorationThickness: 0,
                    fontSize: textMD,
                  ),
                  decoration: InputDecoration(
                    fillColor: tertiaryDark,
                    filled: true,
                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(cornerRadiusMD), borderSide: BorderSide.none),
                    isCollapsed: true,
                    label: Text(
                      t.search.toUpperCase(),
                      style: TextStyle(color: secondaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    contentPadding: const EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM),
                    isDense: true,
                  ),
                  onChanged: (searchText) {
                    debounce(selectApplicationSearchReference, 100, () async {
                      if (searchText.isEmpty) {
                        deviceApplications = [...originalDeviceApplications];
                      }

                      final List<String> filteredPackageNames = [];

                      for (var devicePackageName in originalDeviceApplications) {
                        Future<String> labelFuture;
                        if (labelCache.containsKey(devicePackageName)) {
                          labelFuture = Future.value(labelCache[devicePackageName]!);
                        } else {
                          labelFuture = AccessibilityServiceHelper.getApplicationLabel(devicePackageName).then((label) {
                            labelCache[devicePackageName] = label;
                            return label;
                          });
                        }
                        if ((await labelFuture).toLowerCase().contains(searchText.toLowerCase().trim())) {
                          filteredPackageNames.add(devicePackageName);
                        }
                      }

                      deviceApplications = [...filteredPackageNames];
                      setState(() {});
                    });
                  },
                ),
                SizedBox(height: spaceMD),
                deviceApplications == null
                    ? Padding(
                        padding: EdgeInsets.symmetric(vertical: spaceSM),
                        child: Center(child: CircularProgressIndicator(color: primaryLight)),
                      )
                    : SizedBox(
                        width: double.maxFinite,
                        height: MediaQuery.of(context).size.height / 3,
                        child: GridView.builder(
                          shrinkWrap: true,
                          itemCount: <String>{...selectedApplications, ...(deviceApplications!)}.toList().length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: spaceMD,
                            mainAxisSpacing: spaceMD,
                          ),
                          itemBuilder: (BuildContext context, int index) {
                            final packageName = <String>{...selectedApplications, ...deviceApplications!}.toList()[index];

                            Future<Uint8List?> iconFuture;
                            if (iconCache.containsKey(packageName)) {
                              iconFuture = Future.value(iconCache[packageName]!);
                            } else {
                              iconFuture = AccessibilityServiceHelper.getApplicationIcon(packageName).then((bytes) {
                                iconCache[packageName] = bytes;
                                return bytes;
                              });
                            }

                            Future<String> labelFuture;
                            if (labelCache.containsKey(packageName)) {
                              labelFuture = Future.value(labelCache[packageName]!);
                            } else {
                              labelFuture = AccessibilityServiceHelper.getApplicationLabel(packageName).then((label) {
                                labelCache[packageName] = label;
                                return label;
                              });
                            }

                            return Stack(
                              key: Key(packageName),
                              children: [
                                TextButton(
                                  onPressed: () {
                                    if (selectedApplications.contains(packageName)) {
                                      selectedApplications.remove(packageName);
                                    } else {
                                      selectedApplications.add(packageName);
                                    }
                                    setState(() {});
                                  },
                                  style: ButtonStyle(
                                    alignment: Alignment.centerLeft,
                                    backgroundColor: WidgetStatePropertyAll(tertiaryDark),
                                    padding: WidgetStatePropertyAll(EdgeInsets.all(spaceSM)),
                                    shape: WidgetStatePropertyAll(
                                      RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
                                    ),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          height: textXXL,
                                          width: textXXL,
                                          child: FutureBuilder(
                                            future: iconFuture,
                                            builder: (context, snapshot) => snapshot.data == null
                                                ? CircularProgressIndicator(color: tertiaryLight)
                                                : Image.memory(snapshot.data!, height: textXXL, width: textXXL, gaplessPlayback: true),
                                          ),
                                        ),
                                        SizedBox(height: spaceSM),
                                        FutureBuilder(
                                          future: labelFuture,
                                          builder: (context, snapshot) => Text(
                                            (snapshot.data ?? "").toUpperCase(),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(color: primaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (selectedApplications.contains(packageName))
                                  Positioned(
                                    top: spaceSM,
                                    right: spaceSM,
                                    child: FaIcon(FontAwesomeIcons.solidCircleCheck, color: primaryPositive, size: textXL),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
              ],
            ),
          );
        },
      ),
      actions: <Widget>[
        TextButton(
          child: Text(
            t.cancel.toUpperCase(),
            style: TextStyle(color: primaryLight, fontSize: textMD),
          ),
          onPressed: () {
            Navigator.of(context).canPop() ? Navigator.pop(context) : null;
          },
        ),
        TextButton(
          child: Text(
            t.saveApplication.toUpperCase(),
            style: TextStyle(color: primaryPositive, fontSize: textMD),
          ),
          onPressed: () async {
            uiSettingsManager.setStringList(StorageKey.setman_packageNames, selectedApplications);
            Navigator.of(context).canPop() ? Navigator.pop(context) : null;
          },
        ),
      ],
    ),
  );
}
