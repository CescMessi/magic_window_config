import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:root/root.dart';
import 'package:xml/xml.dart' as xml;
import 'package:fluttertoast/fluttertoast.dart';

import 'activities_widget.dart';
import 'platform_channel.dart';
import 'simple_widget.dart';
import 'configs.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '完美横屏计划自定义配置工具',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData.dark(),
      home: AppViewer(),
    );
  }
}

class AppViewer extends StatefulWidget {
  @override
  _AppViewerState createState() => _AppViewerState();
}

class _AppViewerState extends State<AppViewer> {
  int _index = -1;
  List? _apps;
  final ValueNotifier<String> _selectedAppPackageNameNotifier =
  ValueNotifier<String>('');
  bool _rootStatus = false;
  xml.XmlDocument? embeddedRules;

  Map<String, Map<String, dynamic>> _customConfig = {};

  String _currentPackageName = "";

  Key _activityRuleKey = UniqueKey();
  Key _placeholderKey0 = UniqueKey();
  Key _placeholderKey1 = UniqueKey();
  Key _transitionRulesKey = UniqueKey();

  Configs? config;

  @override
  void initState() {
    super.initState();
    config = Configs();
    _loadApps();
  }

  Future<void> _loadApps() async {
    _readFile();
    List? apps;
    try {
      apps = await DeviceApps.getInstalledApplications(
        onlyAppsWithLaunchIntent: true,
        includeSystemApps: true,
        includeAppIcons: true,
      );
      apps.sort((left, right) =>
          PinyinHelper.getPinyin(left.appName)
              .compareTo(PinyinHelper.getPinyin(right.appName)));
      initRootRequest();
    } catch (e) {
      print('Failed to get apps: $e');
    }

    if (!mounted) return;

    setState(() {
      _apps = apps;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('完美横屏计划自定义配置工具'),
        actions: [
          PopupMenuButton(
              onSelected: (String value) {
                switch (value) {
                  case "0":
                    {
                      print(config!.customConfig);
                      config!.saveCustomConfig().then((value) =>
                        Fluttertoast.showToast(
                            msg: '已保存，重启后生效',
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.CENTER,
                            timeInSecForIosWeb: 1,
                            fontSize: 16.0
                        ));
                    }
                    break;

                  case "1":
                    {
                      print(config!.customConfig);
                      config!.saveCustomConfig().then((value) => config?.updateRule());
                    }
                    break;

                  case "2":
                    {
                      setState(() {
                        config!.resetCustomConfig();
                      });
                    }
                    break;

                  case "3":
                    {
                      setState(() {
                        config!.clearCustomConfig();
                      });
                    }
                    break;
                  case "4":
                    {
                      setState(() {
                        config!.removePackageConfig(_currentPackageName);
                      });
                    }
                    break;

                  default:
                    {
                      print("Invalid choice");
                    }
                    break;
                }
              },
              itemBuilder: (BuildContext context) =>
              <PopupMenuItem<String>>[
                const PopupMenuItem(value: "0", child: Text("保存")),
                const PopupMenuItem(value: "1", child: Text("保存并立即应用配置")),
                const PopupMenuItem(
                  value: "2",
                  child: Text("重置为修改前自定义配置")),
                const PopupMenuItem(
                    value: "3",
                    child: Text("清空所有自定义配置")),
                const PopupMenuItem(
                    value: "4",
                    child: Text("清空当前页应用自定义配置"))
              ]),

        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: _buildAppList(),
          ),
          VerticalDivider(), // Add a vertical divider
          Expanded(
            flex: 7,
            child: ValueListenableBuilder<String>(
              valueListenable: _selectedAppPackageNameNotifier,
              builder: (context, selectedAppPackageName, _) {
                return _buildSelectedApp(selectedAppPackageName);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppList() {
    if (_apps == null || embeddedRules == null) {
      return Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: _apps!.length,
      itemBuilder: (context, index) {
        final app = _apps![index];
        return ListTile(
          leading: Image.memory(
            app.icon,
            width: 48,
            height: 48,
            gaplessPlayback: true,
          ),
          title: Text(app.appName),
          subtitle: Text(app.packageName),
          selected: _index == index,
          onTap: () {
            if (_currentPackageName != app.packageName) {
              _selectedAppPackageNameNotifier.value = app.packageName;
              setState(() {
                _index = index;
                _currentPackageName = app.packageName;
                _placeholderKey0 = UniqueKey();
              });
            }
          },
        );
      },
    );
  }

  Widget _buildSelectedApp(String selectedAppPackageName) {
    List<String> allActivities = ['*'];
    AndroidMethods.getActivities(selectedAppPackageName).then((activities) {
      print(activities);
      allActivities.addAll(activities);
    });

    if (selectedAppPackageName.isEmpty) {
      return const Center(
          child: Text("选择一个应用",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)));
    }

    return Builder(builder: (context) {

      List<Widget> splitRules = [];
      List<List<String>> currentSplitRules = config!.getCurrentValue(selectedAppPackageName, 'splitPairRule');
      int splitRulesNum = currentSplitRules.length;
      for (var i=0;i<splitRulesNum;i++){
        Widget singleSplitRule = PairActivity(
            title: "左右分隔的activity [splitPairRule][$i]",
            packageName: selectedAppPackageName,
            configs: config!,
            xmlKey: 'splitPairRule',
            pairIndex: i,
            allActivities: allActivities,
            onSubmit: (packageName, xmlKey, value) {
              setState(() {
                config!.setCustomValue(
                    packageName, xmlKey, value);
              });
            }
        );

        Widget deleteRule = Container(
          alignment: Alignment.centerRight,
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                currentSplitRules.removeAt(i);
                config!.setCustomValue(selectedAppPackageName, 'splitPairRule', currentSplitRules);
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.delete),
                Text('删除该条')
              ],
            ),

          ),
        );

        splitRules.add(singleSplitRule);
        splitRules.add(deleteRule);
      }
      Widget addIcon = ElevatedButton(
          onPressed: (){
            setState(() {
              currentSplitRules.add(['','']);
              config!.setCustomValue(selectedAppPackageName, 'splitPairRule', currentSplitRules);
            });
          },
          child: const Text('添加左右分隔规则')
      );
      splitRules.add(addIcon);

      var configStatus = "";
      if (config!.customConfig.containsKey(selectedAppPackageName)){
        configStatus = "自定义配置：🔵";
      } else {
        configStatus = "自定义配置：⚪";
      }
      if (config!.modelHasEmbeddedConfig(selectedAppPackageName)){
        configStatus += "  模块内置平行视界：🔵";
      } else {
        configStatus += "  模块内置平行视界：⚪";
      }
      if (config!.modelHasFixedConfig(selectedAppPackageName)){
        configStatus += "  模块内置信箱模式：🔵";
      } else {
        configStatus += "  模块内置信箱模式：⚪";
      }

      return Container(
        padding: EdgeInsets.all(30),
        child: ListView(
          children: [
            Text(
              selectedAppPackageName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5,),
            Text(
              configStatus
            ),
            const Divider(
              height: 10,
            ),
            MagicSimpleArea(
              configs: config!,
              packageName: selectedAppPackageName,
              onChanged: (packageName, xmlKey, value) {
                setState(() {
                  config!.setCustomValue(packageName, xmlKey, value);
                });
              },
            ),
            const Divider(
              height: 20,
            ),
            FixedSimpleArea(
                configs: config!,
                packageName: selectedAppPackageName,
                onChanged: (packageName, xmlKey, value) {
                  setState(() {
                    config!.setCustomValue(
                        packageName, xmlKey, value.toString());
                  });
                }),
            const Divider(
              height: 20,
            ),
            MultiSelectActivity(
              title: '全屏Activity [activityRule]',
              packageName: selectedAppPackageName,
              xmlKey: 'activityRule',
              configs: config!,
              allActivities: allActivities,
              onSubmit: (packageName, xmlKey, value) {
                setState(() {
                  config!.setCustomValue(packageName, xmlKey, value);
                });
              },
            ),
            const Divider(
              height: 20,
            ),
            MultiSelectActivity(
              title: '相互覆盖Activity [transitionRules]',
              packageName: selectedAppPackageName,
              xmlKey: 'transitionRules',
              configs: config!,
              allActivities: allActivities,
              onSubmit: (packageName, xmlKey, value) {
                setState(() {
                  config!.setCustomValue(packageName, xmlKey, value);
                });
              },
            ),

            const Divider(
              height: 20,
            ),
            PairActivity(
              title: "占位Activity [placeholder]",
              packageName: selectedAppPackageName,
              xmlKey: "placeholder",
              pairIndex: -1,
              configs: config!,
              allActivities: allActivities,
              onSubmit: (packageName, xmlKey, value) {
                setState(() {
                  config!.setCustomValue(packageName, xmlKey, value);
                });
              },
            ),

            const Divider(
              height: 20,
            ),

          ] + splitRules,
        ),
      );
    });
  }

  Future<void> initRootRequest() async {
    // bool rootStatus = await RootAccess.requestRootAccess;
    // setState(() {
    //   _rootStatus = rootStatus;
    // });

    bool? result = await Root.isRooted();
    setState(() {
      _rootStatus = result!;
    });
  }

  Future<void> _readFile() async {
    try {
      String embeddedRulesFile =
          '/data/adb/modules/MIUI_MagicWindow+/common/source/embedded_rules_list.xml';
      String? fileContent = await Root.exec(cmd: "cat " + embeddedRulesFile);

      if (fileContent!.startsWith('<')) {
        xml.XmlDocument document = xml.XmlDocument.parse(fileContent);

        setState(() {
          embeddedRules = document;
        });
        var test = embeddedRules!.findAllElements('package').where(
                (package) =>
            package.getAttribute('name') == "com.wxkj.relx.relx");
        print(test.elementAt(0).toString());
      }
    } catch (e) {
      log(e.toString());
    }
  }
}
