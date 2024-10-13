import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:root/root.dart';
import 'package:xml/xml.dart';
import 'package:fluttertoast/fluttertoast.dart';


dynamic _xmlValueParser(String attributeName, String xmlValue) {
  switch (attributeName) {
    case "activityRule":
    case "transitionRules":
    case "forcePortraitActivity":
      {
        List<String> result = xmlValue.split(',');
        result.remove("");
        return result;
      }

    case "splitLineColor":
    case "placeholder":
      {
        if (xmlValue == "") return ["", ""];
        return xmlValue.split(':');
      }

    case "splitPairRule":
      {
        List<String> splitPairs = xmlValue.split(',');
        List<List<String>> splitPairRule = [];
        for (var i = 0; i < splitPairs.length; i++) {
          var singleResult = splitPairs[i].split(':');
          if (singleResult[0] != "" && singleResult.last != "") {
            splitPairRule.add(singleResult);
          }
        }
        return splitPairRule;
      }

    case "flags":
      {
        Map<String, List<String>> flags = {};
        var subAttrs = xmlValue.split(';');
        for (var subAttr in subAttrs) {
          var splitList = subAttr.split(':');
          var subAttrName = splitList[0];
          var subActivities = splitList[1].split(',');
          flags[subAttrName] = subActivities;
        }
        return flags;
      }

    default:
      return xmlValue;
  }
}



class Configs {
  static XmlDocument? embeddedDocument;
  static XmlDocument? fixedDocument;
  static XmlDocument? customEmbeddedDocument;
  static XmlDocument? customFixedDocument;

  bool? readEmbeddedFileSuccess;
  bool? readFixedFileSuccess;
  bool? readCustomEmbeddedFileSuccess;
  bool? readCustomFixedFileSuccess;

  Map<String, Map<String, dynamic>> customConfig = {};

  Configs() {
    _readFile();
  }

  dynamic getCurrentValue(String packageName, String attributeName){
    // 优先从自定义配置中找
    if (customConfig[packageName] != null && customConfig[packageName]![attributeName] != null){
      return customConfig[packageName]![attributeName];
    } else {
      if (attributeName.startsWith('fixed')){
        attributeName = attributeName.split('.')[1];

        if (!readFixedFileSuccess!){
          return _xmlValueParser(attributeName, "");
        }
        var parseResult = fixedDocument!.findAllElements('package').where(
                (package) => package.getAttribute('name') == packageName);
        if (parseResult.isNotEmpty) {
          var parseLine = parseResult.last;
          var xmlValue = parseLine.getAttribute(attributeName) ?? "";
          return _xmlValueParser(attributeName, xmlValue);
        } else{
          return _xmlValueParser(attributeName, "");
        }
      } else {
        if (!readEmbeddedFileSuccess!){
          return _xmlValueParser(attributeName, "");
        }
        var parseResult = embeddedDocument!.findAllElements('package').where(
                (package) => package.getAttribute('name') == packageName);
        if (parseResult.isNotEmpty) {
          var parseLine = parseResult.last;
          var xmlValue = parseLine.getAttribute(attributeName) ?? "";
          return _xmlValueParser(attributeName, xmlValue);
        } else{
          return _xmlValueParser(attributeName, "");
        }
      }
    }
  }

  void setCustomValue(String packageName, String xmlKey, dynamic xmlParsedValue){
    if (customConfig[packageName] == null) {
      // 不存在这个app的自定义配置 将模块内的复制过来
      customConfig[packageName] = {};

      Iterable<XmlElement> fixedParseResult = fixedDocument!.findAllElements(
          'package').where(
              (package) => package.getAttribute('name') == packageName);

      Iterable<XmlElement> embeddedParseResult = embeddedDocument!
          .findAllElements('package').where(
              (package) => package.getAttribute('name') == packageName);

      if (embeddedParseResult.isNotEmpty){
        var embeddedAttrs = embeddedParseResult.last.attributes;
        for (var attribute in embeddedAttrs) {
          log('${attribute.name}: ${attribute.value}');
          if (attribute.name.toString() == "name") {
            continue;
          }
          customConfig[packageName]![attribute.name.toString()] =
              _xmlValueParser(attribute.name.toString(), attribute.value);
        }
      }

      if (fixedParseResult.isNotEmpty){
        var fixedAttrs = fixedParseResult.last.attributes;
        for (var attribute in fixedAttrs) {
          log('fixed.${attribute.name}: ${attribute.value}');
          if (attribute.name.toString() == "name") {
            continue;
          }
          customConfig[packageName]!['fixed.${attribute.name}'] =
              _xmlValueParser(attribute.name.toString(), attribute.value);
        }
      }
    }
    customConfig[packageName]![xmlKey] = xmlParsedValue;
  }

  Future<void> _readFile() async {
    try {
      // 读取模块的平行视界配置
      String embeddedRulesFile =
          '/data/adb/modules/MIUI_MagicWindow+/common/source/embedded_rules_list.xml';
      String? embeddedFileContent =
          await Root.exec(cmd: "cat $embeddedRulesFile");

      if (embeddedFileContent!.startsWith(RegExp(r'^[\s\n]*<'))) {
        embeddedDocument = XmlDocument.parse(embeddedFileContent);
        readEmbeddedFileSuccess = true;
      } else {
        readEmbeddedFileSuccess = false;
      }
    } catch (e) {
      log(e.toString());
      readEmbeddedFileSuccess = false;
    }

    try {
      // 读取模块的信箱配置
      String fixedOrientationFile =
          '/data/adb/modules/MIUI_MagicWindow+/common/source/fixed_orientation_list.xml';
      String? fixedFileContent =
          await Root.exec(cmd: "cat $fixedOrientationFile");
      if (fixedFileContent!.startsWith(RegExp(r'^[\s\n]*<'))) {
        fixedDocument = XmlDocument.parse(fixedFileContent);
        readFixedFileSuccess = true;
      } else {
        readFixedFileSuccess = false;
      }
    } catch (e) {
      log(e.toString());
      readFixedFileSuccess = false;
    }

    try {
      // 读取自定义的平行视界配置
      String customEmbeddedRulesFile =
          '/data/adb/MIUI_MagicWindow+/config/embedded_rules_list.xml';

      // 如果文件不存在则创建
      String? customEmbeddedFileContent =
        await Root.exec(cmd: "cat $customEmbeddedRulesFile");

      if (customEmbeddedFileContent == "") {
        await Root.exec(
            cmd: "mkdir /data/adb/MIUI_MagicWindow+");
        await Root.exec(
            cmd: "mkdir /data/adb/MIUI_MagicWindow+/config/");
        await Root.exec(
            cmd: "touch $customEmbeddedRulesFile");
      }
      customEmbeddedFileContent =
        await Root.exec(cmd: "cat $customEmbeddedRulesFile");

      if (customEmbeddedFileContent == "" ||
          customEmbeddedFileContent!.startsWith(RegExp(r'^[\s\n]*<'))) {
        // 空配置或已有配置，补全xml
        customEmbeddedFileContent =
            "<package_config>\n$customEmbeddedFileContent\n</package_config>";
        customEmbeddedDocument = XmlDocument.parse(customEmbeddedFileContent);
        readCustomEmbeddedFileSuccess = true;

        var packageElements =
            customEmbeddedDocument!.findAllElements('package');
        log("载入自定义平行视界配置");
        for (var packageElement in packageElements) {
          var packageName = packageElement.getAttribute('name');
          log('Package: $packageName');
          if (customConfig[packageName] == null) {
            customConfig[packageName!] = {};
          }
          // 获取当前 package 元素的所有属性
          var attributes = packageElement.attributes;
          // 打印属性列表
          for (var attribute in attributes) {
            log('${attribute.name}: ${attribute.value}');
            if (attribute.name.toString() == "name"){
              continue;
            }
            customConfig[packageName]![attribute.name.toString()] =
                _xmlValueParser(attribute.name.toString(), attribute.value);
          }
        }
        log("自定义平行视界配置载入完成");
      } else {
        readCustomEmbeddedFileSuccess = false;
      }
    } catch (e) {
      log(e.toString());
      readEmbeddedFileSuccess = false;
    }

    try {
      // 读取自定义的信箱配置
      String customFixRulesFile =
          '/data/adb/MIUI_MagicWindow+/config/fixed_orientation_list.xml';

      // 如果文件不存在则创建
      String? customFixedFileContent =
        await Root.exec(cmd: "cat $customFixRulesFile");
      if (customFixedFileContent == "") {
        await Root.exec(
            cmd: "mkdir /data/adb/MIUI_MagicWindow+");
        await Root.exec(
            cmd: "mkdir /data/adb/MIUI_MagicWindow+/config/");
        await Root.exec(
            cmd: "touch $customFixRulesFile");
      }
      customFixedFileContent =
          await Root.exec(cmd: "cat $customFixRulesFile");

      if (customFixedFileContent == "" ||
          customFixedFileContent!.startsWith(RegExp(r'^[\s\n]*<'))) {
        // 空配置或已有配置，补全xml
        customFixedFileContent =
            "<package_config>\n$customFixedFileContent\n</package_config>";
        customFixedDocument = XmlDocument.parse(customFixedFileContent);
        readCustomFixedFileSuccess = true;

        var packageElements = customFixedDocument!.findAllElements('package');
        log("载入自定义信箱配置");
        for (var packageElement in packageElements) {
          var packageName = packageElement.getAttribute('name');
          log('Package: $packageName');
          if (customConfig[packageName] == null) {
            customConfig[packageName!] = {};
          }
          // 获取当前 package 元素的所有属性
          var attributes = packageElement.attributes;
          // 打印属性列表
          for (var attribute in attributes) {
            log('${attribute.name}: ${attribute.value}');
            if (attribute.name.toString() == "name"){
              continue;
            }
            customConfig[packageName]!['fixed.${attribute.name}'] =
                attribute.value;
          }
        }
        log("自定义信箱配置载入完成");
      } else {
        readCustomFixedFileSuccess = false;
      }
    } catch (e) {
      log(e.toString());
      readCustomFixedFileSuccess = false;
    }
  }

  Future<void> saveCustomConfig() async {
    var embeddedRulesXmlStr = StringBuffer();
    var fixRulesXmlStr = StringBuffer();

    customConfig.forEach((packageName, config) {
      var embeddedAttrs = StringBuffer();
      var fixAttrs = StringBuffer();

      config.forEach((attributeName, attributeValue) {
        // 处理 fixed 开头的属性
        if (attributeName.startsWith('fixed.')) {
          var fixedAttrName = attributeName.replaceFirst('fixed.', '');
          var xmlValue = _convertToXmlValue(fixedAttrName, attributeValue);
          if (xmlValue.isNotEmpty){
            fixAttrs.write(' $fixedAttrName="$xmlValue"');
          }

        } else {
          var xmlValue = _convertToXmlValue(attributeName, attributeValue);
          if (xmlValue.isNotEmpty) {
            embeddedAttrs.write(' $attributeName="$xmlValue"');
          }
        }
      });

      // 如果存在 embedded 属性，生成 embedded 规则 XML
      if (embeddedAttrs.isNotEmpty) {
        embeddedRulesXmlStr.write('<package name="$packageName"${embeddedAttrs.toString()} />\n');
      }

      // 如果存在 fix 属性，生成 fix 规则 XML
      if (fixAttrs.isNotEmpty) {
        fixRulesXmlStr.write('<package name="$packageName"${fixAttrs.toString()} />\n');
      }
    });

    // 输出生成的 XML 字符串
    log("Embedded Rules XML:");
    log(embeddedRulesXmlStr.toString());

    log("Fix Rules XML:");
    log(fixRulesXmlStr.toString());
    // 需要覆盖的文件路径
    String embeddedRulesPath = '/data/adb/MIUI_MagicWindow+/config/embedded_rules_list.xml';
    String fixRulesPath = '/data/adb/MIUI_MagicWindow+/config/fixed_orientation_list.xml';

    // 备份文件路径
    String embeddedBackupPath = '/data/adb/MIUI_MagicWindow+/config/embedded_rules_list.xml.bak';
    String fixBackupPath = '/data/adb/MIUI_MagicWindow+/config/fixed_orientation_list.xml.bak';

    // 创建目录的命令
    await Root.exec(cmd: 'mkdir -p /data/adb/MIUI_MagicWindow+/config');

    // 备份现有的文件
    await Root.exec(cmd: 'cp $embeddedRulesPath $embeddedBackupPath || true');
    await Root.exec(cmd: 'cp $fixRulesPath $fixBackupPath || true');

    // 写入新的 XML 内容到文件
    await Root.exec(cmd: 'echo \'$embeddedRulesXmlStr\' > $embeddedRulesPath');
    await Root.exec(cmd: 'echo \'$fixRulesXmlStr\' > $fixRulesPath');

  }

// 处理字典值到 XML 的转换逻辑
  String _convertToXmlValue(String attributeName, dynamic attributeValue) {
    switch (attributeName) {
      case "activityRule":
      case "transitionRules":
      case "forcePortraitActivity":
        return (attributeValue as List<String>).join(',');

      case "splitLineColor":
      case "placeholder":
        return (attributeValue as List<String>).join(':');

      case "splitPairRule":
        return (attributeValue as List<List<String>>)
            .map((pair) => pair.join(':'))
            .join(',');

      case "flags":
        return (attributeValue as Map<String, List<String>>)
            .entries
            .map((entry) => '${entry.key}:${entry.value.join(',')}')
            .join(';');

      default:
        return attributeValue.toString();
    }
  }

  Future<void> updateRule() async {
    // 直接更新当前配置
    String? updateResult = await Root.exec(cmd: '/data/adb/MIUI_MagicWindow+/config/update_rule.sh');
    log(updateResult!);
    for (var singleLine in updateResult.split('\n')){
      if (singleLine.isNotEmpty){
        Fluttertoast.showToast(
            msg: singleLine,
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            fontSize: 16.0
        );
      }
    }
  }

  void clearCustomConfig(){
    customConfig = {};
  }

  void removePackageConfig(String packageName){
    var result = customConfig.remove(packageName);
    String showText = '已移除$packageName的配置$result';
    Fluttertoast.showToast(
        msg: showText,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        fontSize: 16.0
    );
  }

  void resetCustomConfig(){
    clearCustomConfig();
    _readFile();
  }

}
