import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:root/root.dart';
import 'package:xml/xml.dart';
import 'package:fluttertoast/fluttertoast.dart';

// 获取模块名称，检查Hyper_MagicWindow是否存在，不存在则使用MIUI_MagicWindow+
Future<String> getModuleName() async {
  try {
    // 首先尝试检查Hyper_MagicWindow模块是否存在
    String? checkResult = await Root.exec(cmd: "test -d /data/adb/modules/Hyper_MagicWindow && echo 'exists' || echo 'not_exists'");
    if (checkResult?.trim() == 'exists') {
      return 'Hyper_MagicWindow';
    }
  } catch (e) {
    log('检查Hyper_MagicWindow模块时出错: $e');
  }
  
  // 如果Hyper_MagicWindow不存在，返回默认的MIUI_MagicWindow+
  return 'MIUI_MagicWindow+';
}

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
  static XmlDocument? embeddedSettingDocument;
  static XmlDocument? customEmbeddedSettingDocument;

  bool? readEmbeddedFileSuccess;
  bool? readFixedFileSuccess;
  bool? readCustomEmbeddedFileSuccess;
  bool? readCustomFixedFileSuccess;
  bool? readEmbeddedSettingFileSuccess;
  bool? readCustomEmbeddedSettingFileSuccess;

  Map<String, Map<String, dynamic>> customConfig = {};
  String moduleName = 'MIUI_MagicWindow+';
  bool isInitialized = false;
  late final Future<void> _initializationFuture;

  Configs() {
    _initializationFuture = _startInitialization();
  }

  Future<void> _startInitialization() async {
    await _initModuleName();
    await _readFile();
    isInitialized = true;
  }

  Future<void> waitForInitialization() async {
    await _initializationFuture;
  }

  Future<void> _initModuleName() async {
    moduleName = await getModuleName();
    log('module name: $moduleName');
  }

  dynamic getCurrentValue(String packageName, String attributeName){
    // 优先从自定义配置中找
    if (customConfig[packageName] != null && customConfig[packageName]![attributeName] != null){
      return customConfig[packageName]![attributeName];
    } else {
      if (attributeName.startsWith('fixed')){
        attributeName = attributeName.split('.')[1];

        if (readFixedFileSuccess != true){
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
      } else if (attributeName.startsWith('setting.')){
        attributeName = attributeName.split('.')[1];

        if (readEmbeddedSettingFileSuccess != true){
          return _xmlValueParser(attributeName, "");
        }
        var parseResult = embeddedSettingDocument!.findAllElements('setting').where(
                (setting) => setting.getAttribute('name') == packageName);
        if (parseResult.isNotEmpty) {
          var parseLine = parseResult.last;
          var xmlValue = parseLine.getAttribute(attributeName) ?? "";
          return _xmlValueParser(attributeName, xmlValue);
        } else{
          return _xmlValueParser(attributeName, "");
        }
      } else {
        if (readEmbeddedFileSuccess != true){
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

  bool modelHasEmbeddedConfig(String packageName){
    var parseResult = embeddedDocument!.findAllElements('package').where(
            (package) => package.getAttribute('name') == packageName);
    return parseResult.isNotEmpty;
  }

  bool modelHasFixedConfig(String packageName){
    var parseResult = fixedDocument!.findAllElements('package').where(
            (package) => package.getAttribute('name') == packageName);
    return parseResult.isNotEmpty;
  }

  bool modelHasEmbeddedSettingConfig(String packageName){
    if (readEmbeddedSettingFileSuccess == null || !readEmbeddedSettingFileSuccess!){
      return false;
    }
    var parseResult = embeddedSettingDocument!.findAllElements('setting').where(
            (setting) => setting.getAttribute('name') == packageName);
    return parseResult.isNotEmpty;
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
          '/data/adb/modules/$moduleName/common/source/embedded_rules_list.xml';
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
          '/data/adb/modules/$moduleName/common/source/fixed_orientation_list.xml';
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
          '/data/adb/$moduleName/config/embedded_rules_list.xml';

      // 如果文件不存在则创建
      String? customEmbeddedFileContent =
        await Root.exec(cmd: "cat $customEmbeddedRulesFile");

      if (customEmbeddedFileContent == "") {
        await Root.exec(
            cmd: "mkdir /data/adb/$moduleName");
        await Root.exec(
            cmd: "mkdir /data/adb/$moduleName/config/");
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
          '/data/adb/$moduleName/config/fixed_orientation_list.xml';

      // 如果文件不存在则创建
      String? customFixedFileContent =
        await Root.exec(cmd: "cat $customFixRulesFile");
      if (customFixedFileContent == "") {
        await Root.exec(
            cmd: "mkdir /data/adb/$moduleName");
        await Root.exec(
            cmd: "mkdir /data/adb/$moduleName/config/");
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

    try {
      String embeddedSettingFile =
          '/data/adb/modules/$moduleName/common/source/embedded_setting_config.xml';
      String? embeddedSettingFileContent =
          await Root.exec(cmd: "cat $embeddedSettingFile");

      if (embeddedSettingFileContent!.startsWith(RegExp(r'^[\s\n]*<'))) {
        embeddedSettingDocument = XmlDocument.parse(embeddedSettingFileContent);
        readEmbeddedSettingFileSuccess = true;
      } else {
        readEmbeddedSettingFileSuccess = false;
      }
    } catch (e) {
      log(e.toString());
      readEmbeddedSettingFileSuccess = false;
    }

    try {
      // 读取自定义的embedded_setting配置
      String customEmbeddedSettingFile =
          '/data/adb/$moduleName/config/embedded_setting_config.xml';

      // 如果文件不存在则创建
      String? customEmbeddedSettingFileContent =
        await Root.exec(cmd: "cat $customEmbeddedSettingFile");
      if (customEmbeddedSettingFileContent == "") {
        await Root.exec(
            cmd: "mkdir /data/adb/$moduleName");
        await Root.exec(
            cmd: "mkdir /data/adb/$moduleName/config/");
        await Root.exec(
            cmd: "touch $customEmbeddedSettingFile");
      }
      customEmbeddedSettingFileContent =
          await Root.exec(cmd: "cat $customEmbeddedSettingFile");

      if (customEmbeddedSettingFileContent == "" ||
          customEmbeddedSettingFileContent!.startsWith(RegExp(r'^[\s\n]*<'))) {
        // 空配置或已有配置，补全xml
        customEmbeddedSettingFileContent =
            "<setting_rule>\n$customEmbeddedSettingFileContent\n</setting_rule>";
        customEmbeddedSettingDocument = XmlDocument.parse(customEmbeddedSettingFileContent);
        readCustomEmbeddedSettingFileSuccess = true;

        var settingElements = customEmbeddedSettingDocument!.findAllElements('setting');
        log("载入自定义embedded_setting配置");
        for (var settingElement in settingElements) {
          var settingName = settingElement.getAttribute('name');
          log('Setting: $settingName');
          if (customConfig[settingName] == null) {
            customConfig[settingName!] = {};
          }
          var attributes = settingElement.attributes;
          for (var attribute in attributes) {
            log('setting.${attribute.name}: ${attribute.value}');
            if (attribute.name.toString() == "name"){
              continue;
            }
            customConfig[settingName]!['setting.${attribute.name}'] =
                attribute.value;
          }
        }
        log("自定义embedded_setting配置载入完成");
      } else {
        readCustomEmbeddedSettingFileSuccess = false;
      }
    } catch (e) {
      log(e.toString());
      readCustomEmbeddedSettingFileSuccess = false;
    }
  }

  Future<void> saveCustomConfig() async {
    var embeddedRulesXmlStr = StringBuffer();
    var fixRulesXmlStr = StringBuffer();
    var embeddedSettingXmlStr = StringBuffer();

    customConfig.forEach((packageName, config) {
      var embeddedAttrs = StringBuffer();
      var fixAttrs = StringBuffer();
      var settingAttrs = StringBuffer();

      config.forEach((attributeName, attributeValue) {
        if (attributeName.startsWith('fixed.')) {
          var fixedAttrName = attributeName.replaceFirst('fixed.', '');
          var xmlValue = _convertToXmlValue(fixedAttrName, attributeValue);
          if (xmlValue.isNotEmpty){
            fixAttrs.write(' $fixedAttrName="$xmlValue"');
          }
        } else if (attributeName.startsWith('setting.')) {
          var settingAttrName = attributeName.replaceFirst('setting.', '');
          var xmlValue = _convertToXmlValue(settingAttrName, attributeValue);
          if (xmlValue.isNotEmpty){
            settingAttrs.write(' $settingAttrName="$xmlValue"');
          }
        } else {
          var xmlValue = _convertToXmlValue(attributeName, attributeValue);
          if (xmlValue.isNotEmpty) {
            embeddedAttrs.write(' $attributeName="$xmlValue"');
          }
        }
      });

      if (embeddedAttrs.isNotEmpty) {
        embeddedRulesXmlStr.write('<package name="$packageName"${embeddedAttrs.toString()} />\n');
      }

      if (fixAttrs.isNotEmpty) {
        fixRulesXmlStr.write('<package name="$packageName"${fixAttrs.toString()} />\n');
      }

      if (settingAttrs.isNotEmpty) {
        embeddedSettingXmlStr.write('<setting name="$packageName"${settingAttrs.toString()} />\n');
      }
    });

    log("Embedded Rules XML:");
    log(embeddedRulesXmlStr.toString());

    log("Fix Rules XML:");
    log(fixRulesXmlStr.toString());

    log("Embedded Setting XML:");
    log(embeddedSettingXmlStr.toString());

    String embeddedRulesPath = '/data/adb/$moduleName/config/embedded_rules_list.xml';
    String fixRulesPath = '/data/adb/$moduleName/config/fixed_orientation_list.xml';
    String embeddedSettingPath = '/data/adb/$moduleName/config/embedded_setting_config.xml';

    String embeddedBackupPath = '/data/adb/$moduleName/config/embedded_rules_list.xml.bak';
    String fixBackupPath = '/data/adb/$moduleName/config/fixed_orientation_list.xml.bak';
    String embeddedSettingBackupPath = '/data/adb/$moduleName/config/embedded_setting_config.xml.bak';

    await Root.exec(cmd: 'mkdir -p /data/adb/$moduleName/config');

    await Root.exec(cmd: 'cp $embeddedRulesPath $embeddedBackupPath || true');
    await Root.exec(cmd: 'cp $fixRulesPath $fixBackupPath || true');
    await Root.exec(cmd: 'cp $embeddedSettingPath $embeddedSettingBackupPath || true');

    await Root.exec(cmd: 'echo \'$embeddedRulesXmlStr\' > $embeddedRulesPath');
    await Root.exec(cmd: 'echo \'$fixRulesXmlStr\' > $fixRulesPath');
    await Root.exec(cmd: 'echo \'$embeddedSettingXmlStr\' > $embeddedSettingPath');
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
    String? updateResult = await Root.exec(cmd: '/data/adb/$moduleName/config/update_rule.sh');
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
