import 'package:flutter/material.dart';
import 'package:magic_window_config/configs.dart';
import 'package:dropdown_search/dropdown_search.dart';

class MultiSelectActivity extends StatefulWidget {
  final String title;
  final String packageName;
  final String xmlKey;
  Configs configs;
  final List<String> allActivities;
  final Function onSubmit;

  MultiSelectActivity({
    Key? key,
    required this.title,
    required this.packageName,
    required this.configs,
    required this.xmlKey,
    required this.allActivities,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<MultiSelectActivity> createState() => _MultiSelectActivityState();
}

class _MultiSelectActivityState extends State<MultiSelectActivity> {
  Key searchKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(widget.title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(
              width: 10,
            ),
            TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      var inputValue = "";
                      return AlertDialog(
                        title: const Text('输入一个Activity'),
                        content: TextField(
                          onChanged: (value) {
                            inputValue = value;
                          },
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
                              List<String> currentValue = widget.configs
                                  .getCurrentValue(
                                      widget.packageName, widget.xmlKey);
                              currentValue.add(inputValue);
                              widget.onSubmit(widget.packageName, widget.xmlKey,
                                  currentValue);
                              searchKey = UniqueKey();
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Text("手动添加一个Activity"))
          ],
        ),
        const SizedBox(
          height: 10,
        ),
        DropdownSearch<String>.multiSelection(
          key: searchKey,
          items: widget.allActivities,
          clearButtonProps: const ClearButtonProps(isVisible: true),
          popupProps: PopupPropsMultiSelection.menu(
            showSearchBox: true,
            showSelectedItems: true,
            disabledItemFn: (String s) => s.startsWith('I'),
            emptyBuilder: (context, query) {
              return Center(child: Text("未找到活动 $query"));
            },
          ),
          onChanged: (data) {
            widget.onSubmit(widget.packageName, widget.xmlKey, data);
          },
          selectedItems:
              widget.configs.getCurrentValue(widget.packageName, widget.xmlKey),
        )
      ],
    );
  }
}

class PairActivity extends StatefulWidget {
  final String title;
  final String packageName;
  final String xmlKey;
  final int pairIndex;
  Configs configs;
  final List<String> allActivities;
  final Function onSubmit;

  PairActivity({
    Key? key,
    required this.title,
    required this.packageName,
    required this.configs,
    required this.xmlKey,
    required this.pairIndex,
    required this.allActivities,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<PairActivity> createState() => _PairActivityState();
}

class _PairActivityState extends State<PairActivity> {
  Key _placeholderKey0 = UniqueKey();
  Key _placeholderKey1 = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(widget.title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(
              width: 10,
            ),
            TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      var inputValue = "";
                      return AlertDialog(
                        title: const Text('输入一对Activity，使用英文冒号分割'),
                        content: TextField(
                          onChanged: (value) {
                            inputValue = value;
                          },
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
                              List currentValue = widget.configs.getCurrentValue(widget.packageName, widget.xmlKey);
                              if (widget.pairIndex>=0){
                                currentValue[widget.pairIndex] = inputValue.split(':');
                              } else {
                                currentValue = inputValue.split(':');
                              }
                              widget.onSubmit(widget.packageName, widget.xmlKey,
                                  currentValue);
                              _placeholderKey0 = UniqueKey();
                              _placeholderKey1 = UniqueKey();
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Text("手动修改一对Activity"))
          ],
        ),
        const SizedBox(
          height: 10,
        ),
        Column(
          children: [
            DropdownSearch<String>(
              key: _placeholderKey0,
              clearButtonProps: const ClearButtonProps(isVisible: true),
              popupProps: const PopupProps.menu(
                showSearchBox: true,
                showSelectedItems: true,
              ),
              items: widget.allActivities,
              dropdownDecoratorProps: const DropDownDecoratorProps(
                dropdownSearchDecoration:
                    InputDecoration(labelText: "左侧Activity"),
              ),
              onChanged: (data) {
                List currentValue = widget.configs.getCurrentValue(widget.packageName, widget.xmlKey);
                if (widget.pairIndex>=0){
                  currentValue[widget.pairIndex][0] = data!;
                } else {
                  currentValue[0] = data!;
                }

                widget.onSubmit(widget.packageName, widget.xmlKey, currentValue);
              },
              selectedItem: widget.pairIndex >= 0
                  ? widget.configs.getCurrentValue(
                      widget.packageName, widget.xmlKey)[widget.pairIndex][0]
                  : widget.configs
                      .getCurrentValue(widget.packageName, widget.xmlKey)[0],
            ),
            DropdownSearch<String>(
              key: _placeholderKey1,
              clearButtonProps: const ClearButtonProps(isVisible: true),
              popupProps: const PopupProps.menu(
                showSearchBox: true,
                showSelectedItems: true,
              ),
              items: widget.allActivities,
              dropdownDecoratorProps: const DropDownDecoratorProps(
                dropdownSearchDecoration:
                    InputDecoration(labelText: "右侧Activity"),
              ),
              onChanged: (data) {
                List currentValue = widget.configs.getCurrentValue(widget.packageName, widget.xmlKey);
                if (widget.pairIndex>=0){
                  currentValue[widget.pairIndex][1] = data!;
                } else {
                  currentValue[1] = data!;
                }

                widget.onSubmit(widget.packageName, widget.xmlKey, currentValue);
              },
              selectedItem: widget.pairIndex >= 0
                  ? widget.configs.getCurrentValue(
                  widget.packageName, widget.xmlKey)[widget.pairIndex][1]
                  : widget.configs
                  .getCurrentValue(widget.packageName, widget.xmlKey)[1],
            ),
          ],
        )
      ],
    );
  }
}
