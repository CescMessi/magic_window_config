# 小米平板 完美横屏计划自定义配置编辑器

使用 Flutter 编写的，小米平板完美横屏计划自定义配置编辑器。

## 适用范围

使用本app需要满足以下几个条件：
1. 已安装 Magisk 模块「[完美横屏计划](https://hyper-magic-window.sothx.com)」，
且安装的版本可以使用[自定义规则](https://hyper-magic-window.sothx.com/custom-config.html)（1.13.05+ 版本），
「[不重启系统应用配置](https://github.com/sothx/mipad-magic-window/releases/tag/1.24.02)」的功能需要1.24.02+ 版本。
2. Android系统版本为12+。由于 Android 11 的自定义配置文件与Android 12以上的文件不同，且本app并未对其做特殊处理，
因此Android 11无法使用本app进行自定义配置的编辑。
3. 授予本app root权限。由于需要修改自定义配置文件和重载配置需要root权限，因此app打开时会请求root权限。
4. 充分了解完美横屏计划自定义配置的规则及选项含义，部分配置项仅在特定设备和澎湃系统上可以使用，使用时请自行分辨可用选项，
同时应确保自己有能力处理因配置错误导致的各种设备问题，本app不对此负责。

## App 原理
基于完美横屏计划的自定义规则配置的原理，首先读取模块内置的规则和已存在的自定义规则，在app界面中显示。当修改了选项后，
会将修改后的配置与自定义规则配置合并。保存时，将原自定义配置文件添加`.bak`后缀备份后，将新的自定义配置文件保存至指定位置。
仅保存时，需要重启后才能生效，若模块版本支持，也可使用「保存并立即应用配置」，app将执行模块内的配置重载脚本，
可以在不重启系统的情况下立即生效自定义规则。

## 使用
### 直接下载已编译的安装包
前往项目的[Release页面](https://github.com/CescMessi/magic_window_config/releases/latest)，下载apk文件，在平板上安装使用。

### 自行编译项目使用
推荐有能力的朋友自行编译apk安装，更加安全放心。

1. 配置好 Flutter 环境，本项目使用版本Flutter: 3.3.10，Android SDK version 31.0.0。
2. 配置好 Android 签名证书，将`key.properties`放置在`android`目录下。
3. 进入项目根目录，运行`flutter pub get`安装依赖，完成后运行`flutter build apk`编译apk文件，
文件将在`build/app/outputs/flutter-apk/app-release.apk`生成。

## 致谢
[完美横屏计划](https://github.com/sothx/mipad-magic-window)

