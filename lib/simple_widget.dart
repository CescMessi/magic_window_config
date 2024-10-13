import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:magic_window_config/configs.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class TextSwitch extends StatefulWidget {
  TextSwitch({
    Key? key,
    required this.title,
    required this.configs,
    required this.selectedAppPackageName,
    required this.xmlKey,
    // required this.embeddedValue,
    this.defaultValue = false,
    required this.onChanged,
  }) : super(key: key);

  final String title;
  Configs configs;
  final String selectedAppPackageName;
  final bool defaultValue;
  final String xmlKey;

  // final String embeddedValue;
  final Function onChanged;

  @override
  State<TextSwitch> createState() => _TextSwitchState();
}

class _TextSwitchState extends State<TextSwitch> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Switch(value: () {
          var currentValue = widget.configs
              .getCurrentValue(widget.selectedAppPackageName, widget.xmlKey);
          if (currentValue == "") {
            return widget.defaultValue;
          }
          return currentValue == 'true';
        }(), onChanged: (value) {
          widget.onChanged(widget.selectedAppPackageName, widget.xmlKey, value.toString());
        })
      ],
    );
  }
}

class LabeledInput extends StatefulWidget {
  LabeledInput(
      {Key? key,
      required this.title,
      required this.selectedAppPackageName,
      required this.xmlKey,
      required this.defaultText,
      required this.isNumber,
      required this.width,
      required this.onSubmitted})
      : super(key: key);

  final String title;
  final String selectedAppPackageName;
  final String xmlKey;
  final Function onSubmitted;
  final String defaultText;
  final bool isNumber;
  final double width;
  final TextEditingController controller = TextEditingController();

  @override
  State<LabeledInput> createState() => _LabeledInputState();
}

class _LabeledInputState extends State<LabeledInput> {
  @override
  Widget build(BuildContext context) {
    // widget.controller.text = widget.defaultText;
    widget.controller.value = TextEditingValue(
      text: widget.defaultText,
      selection: TextSelection.fromPosition(
        TextPosition(
          affinity: TextAffinity.downstream,
          offset: widget.defaultText.length
        )
      )
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Container(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          width: widget.width,
          child: TextField(
              controller: widget.controller,
              keyboardType: widget.isNumber
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : null,
              onChanged: (value) {
                widget.onSubmitted(
                    widget.selectedAppPackageName, widget.xmlKey, value.toString());
              },
              onSubmitted: (value) {
                widget.onSubmitted(
                    widget.selectedAppPackageName, widget.xmlKey, value.toString());
              }),
        ),
      ],
    );
  }
}

class MyColorWidget extends StatefulWidget {
  MyColorWidget(
      {Key? key,
      required this.title,
      required this.packageName,
      required this.xmlKey,
      required this.configs,
      required this.onSubmitted})
      : super(key: key);

  String title;
  String packageName;
  String xmlKey;
  Configs configs;
  final Function onSubmitted;

  @override
  _MyColorWidgetState createState() => _MyColorWidgetState();
}

class _MyColorWidgetState extends State<MyColorWidget> {
  Color? selectedColor;

  void onColorSelected(Color color) {
    setState(() {
      selectedColor = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(widget.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ColorBox(
                  color: HexColor.fromHex(
                      widget.configs.getCurrentValue(
                          widget.packageName, widget.xmlKey)[0],
                      Colors.white),
                  title: "亮色模式分割线颜色",
                  colorIndex: 0,
                  packageName: widget.packageName,
                  configs: widget.configs,
                  onSubmitted: widget.onSubmitted,
                  onPressed: () => _pickColor(Colors.red)),
              const SizedBox(
                width: 20,
              ),
              ColorBox(
                  color: HexColor.fromHex(
                      widget.configs.getCurrentValue(
                          widget.packageName, widget.xmlKey)[1],
                      Colors.black),
                  title: "暗色模式分割线颜色",
                  colorIndex: 1,
                  packageName: widget.packageName,
                  configs: widget.configs,
                  onSubmitted: widget.onSubmitted,
                  onPressed: () => _pickColor(Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  void _pickColor(Color initialColor) {}
}

class ColorBox extends StatefulWidget {
  final Color color;
  final VoidCallback onPressed;
  final String title;
  final int colorIndex;
  final String packageName;
  Configs configs;
  final Function onSubmitted;

  ColorBox({
    required this.color,
    required this.onPressed,
    required this.title,
    required this.colorIndex,
    required this.packageName,
    required this.onSubmitted,
    required this.configs
  });

  @override
  State<StatefulWidget> createState() => _ColorBoxState();
}

class _ColorBoxState extends State<ColorBox> {
  TextEditingController textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
        color: widget.color,
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              textController.text = widget.color.toHex(leadingHashSign: false);
              return AlertDialog(
                title: Text(widget.title),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ColorPicker(
                      pickerColor: widget.color,
                      onColorChanged: (newColor) {
                      },
                      colorPickerWidth: 300,
                      pickerAreaHeightPercent: 0.7,
                      enableAlpha: false,
                      displayThumbColor: true,
                      paletteType: PaletteType.hsvWithHue,
                      labelTypes: const [],
                      pickerAreaBorderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(2),
                          topRight: Radius.circular(2)),
                      hexInputController: textController,
                      portraitOnly: true,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: TextField(
                        controller: textController,
                        autofocus: false,
                        maxLength: 6,
                        inputFormatters: [
                          UpperCaseTextFormatter(),
                          FilteringTextInputFormatter.allow(
                              RegExp(kValidHexPattern))
                        ],
                      ),
                    )
                  ],
                ),
                actions: <Widget>[
                  MaterialButton(
                    child: const Text('取消'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  MaterialButton(
                    child: const Text('确认'),
                    onPressed: () {
                      var splitColor = widget.configs.getCurrentValue(widget.packageName, 'splitLineColor');
                      if (splitColor[0]=="") splitColor[0] = "#FFFFFF";
                      if (splitColor[1]=="") splitColor[1] = "#000000";
                      splitColor[widget.colorIndex] = "#${textController.text}";
                      widget.onSubmitted(widget.packageName, 'splitLineColor', splitColor);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        });
  }
}

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString, Color defaultColor) {
    if (hexString == "") {
      return defaultColor;
    }
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      // '${alpha.toRadixString(16).padLeft(2, '0').toUpperCase()}'
      '${red.toRadixString(16).padLeft(2, '0').toUpperCase()}'
      '${green.toRadixString(16).padLeft(2, '0').toUpperCase()}'
      '${blue.toRadixString(16).padLeft(2, '0').toUpperCase()}';
}

class MagicSimpleArea extends StatefulWidget {
  MagicSimpleArea(
      {Key? key,
      required this.configs,
      required this.packageName,
      required this.onChanged})
      : super(key: key);

  Configs configs;
  final String packageName;
  final Function onChanged;

  @override
  State<MagicSimpleArea> createState() => _MagicSimpleAreaState();
}

class _MagicSimpleAreaState extends State<MagicSimpleArea> {
  var switchKeys = [
    "clearTop",
    "relaunch",
    "disableSensor",
    "isShowDivider",
    "supportFullSize",
    "supportCameraPreview",
  ];
  var switchTitles = [
    "右侧多实例 [clearTop]",
    "调整窗口重加载 [relaunch]",
    "禁用传感器 [disableSensor]",
    "支持左右调节 [isShowDivider]",
    "支持拉伸至全屏 [supportFullSize]",
    "支持拍照预览 [supportCameraPreview]",
  ];

  var labeledInputKeys = ["splitRatio", "scaleMode", "fullRule"];
  var labeledInputTitles = [
    "分割比例 [splitRatio]",
    "应用缩放配置 [scaleMode]",
    "全屏规则 [fullRule]"
  ];

  @override
  Widget build(BuildContext context) {
    List<Widget> textSwitchList = [];
    for (int i = 0; i < switchKeys.length; i++) {
      textSwitchList.add(TextSwitch(
          title: switchTitles[i],
          configs: widget.configs,
          selectedAppPackageName: widget.packageName,
          xmlKey: switchKeys[i],
          onChanged: widget.onChanged));
    }

    List<Widget> labeledInputList = [];
    for (int i = 0; i < labeledInputKeys.length; i++) {
      labeledInputList.add(LabeledInput(
        title: labeledInputTitles[i],
        defaultText: widget.configs
            .getCurrentValue(widget.packageName, labeledInputKeys[i]),
        isNumber: labeledInputKeys[i]!='fullRule',
        width: 120,
        onSubmitted: widget.onChanged,
        selectedAppPackageName: widget.packageName,
        xmlKey: labeledInputKeys[i],
      ));
    }

    var colorSelect = MyColorWidget(
      title: "分割线颜色 [splitLineColor]",
      packageName: widget.packageName,
      xmlKey: "splitLineColor",
      configs: widget.configs,
      onSubmitted: widget.onChanged,
    );

    return Column(
      children: [
        const Text("平行视界开关配置",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 10.0,
          runSpacing: 1.0,
          alignment: WrapAlignment.start,
          children: textSwitchList + labeledInputList + [colorSelect],
        ),
      ],
    );
  }
}

class FixedSimpleArea extends MagicSimpleArea {
  FixedSimpleArea(
      {super.key,
      required super.configs,
      required super.packageName,
      required super.onChanged});

  @override
  State<FixedSimpleArea> createState() => _FixedSimpleAreaState();
}

class _FixedSimpleAreaState extends State<FixedSimpleArea> {
  var switchKeys = [
    "fixed.disable",
    "fixed.isScale",
    "fixed.relaunch",
    "fixed.allPortrait",
    "fixed.skipCompatMode",
    "fixed.allowEmbInPortrait",
    "fixed.transparentBar",
    "fixed.isShowDivider",
  ];
  var switchTitles = [
    "禁用内置信箱模式 [disable]",
    "16:9缩放 [isScale]",
    "调整窗口重加载 [relaunch]",
    "强制以竖屏 [allPortrait]",
    "跳过兼容模式 [skipCompatMode]",
    "允许两边区域空白 [allowEmbInPortrait]",
    "透明状态栏 [transparentBar]",
    "支持左右调节 [isShowDivider]",
  ];

  @override
  Widget build(BuildContext context) {
    List<Widget> textSwitchList = [];
    for (int i = 0; i < switchKeys.length; i++) {
      textSwitchList.add(TextSwitch(
          title: switchTitles[i],
          configs: widget.configs,
          selectedAppPackageName: widget.packageName,
          xmlKey: switchKeys[i],
          onChanged: widget.onChanged));
    }

    return Column(
      children: [
        const Text("信箱模式开关配置",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 10.0,
          runSpacing: 1.0,
          alignment: WrapAlignment.start,
          children: textSwitchList,
        ),
      ],
    );
  }
}
