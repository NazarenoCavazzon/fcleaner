import 'dart:io';
import 'dart:isolate';

import 'package:disk_usage/disk_usage.dart';
import 'package:os_cleaner/src/core/core.dart';
import 'package:os_cleaner/src/exceptions/exceptions.dart';
import 'package:os_cleaner/src/models/models.dart';
import 'package:os_cleaner/src/platforms/platforms.dart';

class MacOSAnalyzer implements PlatformAnalyzer {
  static final String _homeDir = Platform.environment['HOME'] ?? '';

  static Future<AnalysisResult> analyze() async {
    final results = await Future.wait([
      _getSystemInfo(),
      _scanInstalledApps(),
    ]);

    final systemInfo = results[0] as SystemInfo;
    final installedApps = results[1] as List<AppInfo>;

    final categories = await _getCategories(systemInfo);

    return AnalysisResult(
      categories: categories,
      analyzedAt: DateTime.now(),
      systemInfo: systemInfo,
      installedApps: installedApps,
    );
  }

  static Future<List<CleanupCategory>> _getCategories(
    SystemInfo systemInfo,
  ) async {
    final categoriesList = [
      _scanSystemEssentials,
      _scanMacOSSystemCaches,
      _scanSandboxedApps,
      _scanBrowsers,
      _scanCloudStorage,
      _scanOfficeApps,
      _scanDeveloperTools,
      _scanExtendedDevTools,
      _scanApplications,
      _scanVirtualization,
      _scanOrphanedData,
      if (systemInfo.isAppleSilicon) _scanAppleSilicon,
    ];

    return Future.wait(
      categoriesList.map((category) => Isolate.run(() => category.call())),
    );
  }

  static CleanupResult performCleanupSync({
    required AnalysisResult analysis,
    required List<String> categoryIds,
  }) {
    final startTime = DateTime.now();
    final errors = <String>[];
    var itemsCleaned = 0;
    var bytesFreed = 0;

    final itemsToDelete = analysis.getItemsToDelete(categoryIds);

    for (final item in itemsToDelete) {
      try {
        FileSystemService.delete(item.path);

        itemsCleaned++;
        bytesFreed += item.sizeBytes;
      } catch (e) {
        errors.add('Failed to clean ${item.name}: $e');
      }
    }

    final duration = DateTime.now().difference(startTime);

    return CleanupResult(
      success: errors.isEmpty,
      bytesFreed: bytesFreed,
      itemsCleaned: itemsCleaned,
      duration: duration,
      errors: errors,
    );
  }

  static Future<List<AppInfo>> _scanInstalledApps() async {
    final appPaths = <String>[];
    final appLocations = [
      '/Applications',
      '$_homeDir/Applications',
    ];

    for (final location in appLocations) {
      try {
        final dir = Directory(location);
        if (!dir.existsSync()) continue;

        for (final entity in dir.listSync(followLinks: false)) {
          if (entity.path.endsWith('.app')) {
            appPaths.add(entity.path);
          }
        }
      } catch (_) {}
    }

    final appInfos = await Future.wait(
      appPaths.map((path) => Isolate.run(() => _getAppInfo(path))),
    );

    final apps = appInfos.whereType<AppInfo>().toList()
      ..sort((a, b) => b.totalSize.compareTo(a.totalSize));

    return apps;
  }

  static Future<AppInfo?> _getAppInfo(String appPath) async {
    try {
      final plistPath = '$appPath/Contents/Info.plist';
      final plistFile = File(plistPath);

      if (!plistFile.existsSync()) {
        return null;
      }

      final plistContent = plistFile.readAsStringSync();

      final bundleId = _extractPlistValue(plistContent, 'CFBundleIdentifier');
      final name =
          _extractPlistValue(plistContent, 'CFBundleName') ??
          FileSystemService.getFileName(appPath).replaceAll('.app', '');

      if (bundleId == null || bundleId.isEmpty || name.isEmpty) {
        return null;
      }

      final results = await Future.wait([
        Isolate.run(() => _findRelatedFiles(bundleId)),
        Isolate.run(() => File(appPath).statSync().modified),
      ]);

      final relatedPaths = results[0] as List<String>? ?? [];
      final installDate = results[1] as DateTime?;

      final appSize = FileSystemService.calculateSize(appPath);
      var relatedSize = 0;
      for (final path in relatedPaths) {
        relatedSize += FileSystemService.calculateSize(path);
      }

      return AppInfo(
        name: name,
        bundleId: bundleId,
        appPath: appPath,
        totalSize: appSize + relatedSize,
        installDate: installDate,
        relatedPaths: relatedPaths,
      );
    } catch (_) {
      return null;
    }
  }

  static String? _extractPlistValue(String plistContent, String key) {
    final keyPattern = '<key>$key</key>';
    final keyIndex = plistContent.indexOf(keyPattern);
    if (keyIndex == -1) return null;

    final afterKey = plistContent.substring(keyIndex + keyPattern.length);
    final stringMatch = RegExp('<string>(.*?)</string>').firstMatch(afterKey);

    return stringMatch?.group(1)?.trim();
  }

  static Future<List<String>> _findRelatedFiles(String bundleId) async {
    final relatedPaths = <String>[];

    final searchLocations = [
      '$_homeDir/Library/Preferences',
      '$_homeDir/Library/Application Support',
      '$_homeDir/Library/Caches',
      '$_homeDir/Library/Logs',
      '$_homeDir/Library/WebKit',
      '$_homeDir/Library/HTTPStorages',
      '$_homeDir/Library/Cookies',
      '$_homeDir/Library/Saved Application State',
      '$_homeDir/Library/Containers',
      '$_homeDir/Library/Group Containers',
      '$_homeDir/Library/LaunchAgents',
      '$_homeDir/Library/Application Scripts',
      '$_homeDir/Library/Preferences/ByHost',
      '$_homeDir/Library/Internet Plug-Ins',
      '$_homeDir/Library/Services',
      '$_homeDir/Library/QuickLook',
      '$_homeDir/Library/Screen Savers',
      '$_homeDir/Library/Spotlight',
      '$_homeDir/Library/Mail/V*',
    ];

    for (final location in searchLocations) {
      try {
        final pattern = '$location/$bundleId*';
        final files = FileSystemService.findFiles(pattern);
        relatedPaths.addAll(files);
      } catch (_) {}
    }

    final plistPattern = '$_homeDir/Library/Preferences/$bundleId.plist';
    if (FileSystemService.exists(plistPattern)) {
      relatedPaths.add(plistPattern);
    }

    return relatedPaths.toSet().toList();
  }

  static ProcessResult _run(String command, List<String> args) {
    try {
      return Process.runSync(command, args);
    } catch (e, stackTrace) {
      throw CleanupException(
        'Failed to run command: $command ${args.join(" ")}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<SystemInfo> _getSystemInfo() async {
    try {
      final results = await Isolate.run(
        () => [
          _getOSVersion(),
          _getArchitecture(),
        ],
      );

      final diskInfo = await _getDiskInfo();

      return SystemInfo(
        osVersion: results[0],
        architecture: results[1],
        homeDirectory: Platform.environment['HOME'] ?? '',
        totalDiskSpace: diskInfo['total'] ?? 0,
        freeDiskSpace: diskInfo['free'] ?? 0,
      );
    } catch (e, stackTrace) {
      throw AnalyzerException(
        'Failed to get system info',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  static String _getOSVersion() {
    try {
      final result = Process.runSync('sw_vers', ['-productVersion']);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
      return 'Unknown';
    } catch (_) {
      return 'Unknown';
    }
  }

  static String _getArchitecture() {
    try {
      final result = Process.runSync('uname', ['-m']);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
      return 'Unknown';
    } catch (_) {
      return 'Unknown';
    }
  }

  static Future<Map<String, int>> _getDiskInfo() async {
    try {
      final results = await Future.wait([
        DiskUsage.totalSpace(),
        DiskUsage.freeSpace(),
      ]);

      return {'total': results[0] ?? 0, 'free': results[1] ?? 0};
    } catch (_) {
      return {'total': 0, 'free': 0};
    }
  }

  static CleanupCategory _scanSystemEssentials() {
    final items = <CleanupItem>[];

    final paths = [
      '$_homeDir/Library/Caches/*',
      '$_homeDir/Library/Logs/*',
      '$_homeDir/.Trash/*',
      '$_homeDir/Library/Application Support/CrashReporter/*',
      '$_homeDir/Library/DiagnosticReports/*',
      '$_homeDir/Library/Caches/com.apple.QuickLook.thumbnailcache',
      '$_homeDir/Library/Caches/Quick Look/*',
      '$_homeDir/Library/Caches/com.apple.iconservices*',
      '$_homeDir/Library/Caches/CloudKit/*',
      '$_homeDir/Downloads/*.download',
      '$_homeDir/Downloads/*.crdownload',
      '$_homeDir/Downloads/*.part',
    ];

    for (final pattern in paths) {
      items.addAll(_scanPattern(pattern));
    }

    return CleanupCategory(
      id: 'system_essentials',
      name: 'System Essentials',
      description: 'User app cache, logs, trash, and incomplete downloads',
      items: items,
    );
  }

  static CleanupCategory _scanMacOSSystemCaches() {
    final items = <CleanupItem>[];

    final paths = [
      '$_homeDir/Library/Saved Application State/*',
      '$_homeDir/Library/Caches/com.apple.spotlight',
      '$_homeDir/Library/Caches/com.apple.FontRegistry',
      '$_homeDir/Library/Caches/com.apple.ATS',
      '$_homeDir/Library/Caches/com.apple.photoanalysisd',
      '$_homeDir/Library/Caches/com.apple.akd',
      '$_homeDir/Library/Caches/com.apple.Safari/Webpage Previews/*',
      '$_homeDir/Library/Application Support/CloudDocs/session/db/*',
    ];

    for (final pattern in paths) {
      items.addAll(_scanPattern(pattern));
    }

    return CleanupCategory(
      id: 'macos_system_caches',
      name: 'macOS System Caches',
      description: 'Spotlight, fonts, photo analysis, and Safari caches',
      items: items,
    );
  }

  static CleanupCategory _scanSandboxedApps() {
    final items = <CleanupItem>[];

    final paths = [
      '$_homeDir/Library/Containers/com.apple.wallpaper.agent/Data/Library/Caches/*',
      '$_homeDir/Library/Containers/com.apple.mediaanalysisd/Data/Library/Caches/*',
      '$_homeDir/Library/Containers/com.apple.AppStore/Data/Library/Caches/*',
      '$_homeDir/Library/Containers/*/Data/Library/Caches/*',
    ];

    for (final pattern in paths) {
      items.addAll(_scanPattern(pattern));
    }

    return CleanupCategory(
      id: 'sandboxed_apps',
      name: 'Sandboxed Apps',
      description: 'Caches from sandboxed applications',
      items: items,
    );
  }

  static CleanupCategory _scanBrowsers() {
    final items = <CleanupItem>[];

    final paths = [
      '$_homeDir/Library/Caches/com.apple.Safari/*',
      '$_homeDir/Library/Caches/Google/Chrome/*',
      '$_homeDir/Library/Application Support/Google/Chrome/*/Application Cache/*',
      '$_homeDir/Library/Application Support/Google/Chrome/*/GPUCache/*',
      '$_homeDir/Library/Caches/Chromium/*',
      '$_homeDir/Library/Caches/com.microsoft.edgemac/*',
      '$_homeDir/Library/Caches/company.thebrowser.Browser/*',
      '$_homeDir/Library/Caches/BraveSoftware/Brave-Browser/*',
      '$_homeDir/Library/Caches/Firefox/*',
      '$_homeDir/Library/Caches/com.operasoftware.Opera/*',
      '$_homeDir/Library/Caches/com.vivaldi.Vivaldi/*',
      '$_homeDir/Library/Application Support/Firefox/Profiles/*/cache2/*',
    ];

    for (final pattern in paths) {
      items.addAll(_scanPattern(pattern));
    }

    return CleanupCategory(
      id: 'browsers',
      name: 'Browsers',
      description:
          'Safari, Chrome, Firefox, Arc, Brave, Edge, and Opera caches',
      items: items,
    );
  }

  static CleanupCategory _scanCloudStorage() {
    final items = <CleanupItem>[];

    final paths = [
      '$_homeDir/Library/Caches/com.dropbox.*',
      '$_homeDir/Library/Caches/com.getdropbox.dropbox',
      '$_homeDir/Library/Caches/com.google.GoogleDrive',
      '$_homeDir/Library/Caches/com.baidu.netdisk',
      '$_homeDir/Library/Caches/com.alibaba.teambitiondisk',
      '$_homeDir/Library/Caches/com.box.desktop',
      '$_homeDir/Library/Caches/com.microsoft.OneDrive',
    ];

    for (final pattern in paths) {
      items.addAll(_scanPattern(pattern));
    }

    return CleanupCategory(
      id: 'cloud_storage',
      name: 'Cloud Storage',
      description:
          'Dropbox, Google Drive, OneDrive, and other cloud service caches',
      items: items,
    );
  }

  static CleanupCategory _scanOfficeApps() {
    final items = <CleanupItem>[];

    final paths = [
      '$_homeDir/Library/Caches/com.microsoft.Word',
      '$_homeDir/Library/Caches/com.microsoft.Excel',
      '$_homeDir/Library/Caches/com.microsoft.Powerpoint',
      '$_homeDir/Library/Caches/com.microsoft.Outlook/*',
      '$_homeDir/Library/Caches/com.apple.iWork.*',
      '$_homeDir/Library/Caches/com.kingsoft.wpsoffice.mac',
      '$_homeDir/Library/Caches/org.mozilla.thunderbird/*',
      '$_homeDir/Library/Caches/com.apple.mail/*',
    ];

    for (final pattern in paths) {
      items.addAll(_scanPattern(pattern));
    }

    return CleanupCategory(
      id: 'office_apps',
      name: 'Office Applications',
      description: 'Microsoft Office, iWork, Mail, and Thunderbird caches',
      items: items,
    );
  }

  static CleanupCategory _scanDeveloperTools() {
    final items = <CleanupItem>[];

    final paths = [
      '$_homeDir/.npm/_cacache/*',
      '$_homeDir/.npm/_logs/*',
      '$_homeDir/.yarn/cache/*',
      '$_homeDir/.bun/install/cache/*',
      '$_homeDir/.cache/pip/*',
      '$_homeDir/Library/Caches/pip/*',
      '$_homeDir/.pyenv/cache/*',
      '$_homeDir/Library/Caches/go-build/*',
      '$_homeDir/go/pkg/mod/cache/*',
      '$_homeDir/.cargo/registry/cache/*',
      '$_homeDir/.kube/cache/*',
      '$_homeDir/.local/share/containers/storage/tmp/*',
      '$_homeDir/.aws/cli/cache/*',
      '$_homeDir/.config/gcloud/logs/*',
      '$_homeDir/.azure/logs/*',
      '$_homeDir/Library/Caches/Homebrew/*',
      '$_homeDir/.gitconfig.lock',
    ];

    for (final pattern in paths) {
      items.addAll(_scanPattern(pattern));
    }

    return CleanupCategory(
      id: 'developer_tools',
      name: 'Developer Tools',
      description: 'npm, yarn, pip, Go, Rust, Docker, and Homebrew caches',
      items: items,
    );
  }

  static CleanupCategory _scanExtendedDevTools() {
    final items = <CleanupItem>[];

    final paths = [
      '$_homeDir/.pnpm-store/*',
      '$_homeDir/.local/share/pnpm/store/*',
      '$_homeDir/.cache/typescript/*',
      '$_homeDir/.cache/electron/*',
      '$_homeDir/.cache/node-gyp/*',
      '$_homeDir/.node-gyp/*',
      '$_homeDir/.turbo/*',
      '$_homeDir/.next/*',
      '$_homeDir/.vite/*',
      '$_homeDir/.cache/vite/*',
      '$_homeDir/.cache/webpack/*',
      '$_homeDir/.parcel-cache/*',
      '$_homeDir/Library/Caches/Google/AndroidStudio*/*',
      '$_homeDir/Library/Caches/com.unity3d.*/*',
      '$_homeDir/Library/Caches/com.jetbrains.toolbox/*',
      '$_homeDir/Library/Caches/com.postmanlabs.mac/*',
      '$_homeDir/Library/Caches/com.konghq.insomnia/*',
      '$_homeDir/Library/Caches/com.tinyapp.TablePlus/*',
      '$_homeDir/Library/Caches/com.mongodb.compass/*',
      '$_homeDir/Library/Caches/com.figma.Desktop/*',
      '$_homeDir/Library/Caches/com.github.GitHubDesktop/*',
      '$_homeDir/Library/Caches/com.microsoft.VSCode/*',
      '$_homeDir/Library/Caches/com.sublimetext.*/*',
      '$_homeDir/.cache/poetry/*',
      '$_homeDir/.cache/uv/*',
      '$_homeDir/.cache/ruff/*',
      '$_homeDir/.cache/mypy/*',
      '$_homeDir/.pytest_cache/*',
      '$_homeDir/.jupyter/runtime/*',
      '$_homeDir/.cache/torch/*',
      '$_homeDir/.cache/tensorflow/*',
      '$_homeDir/.conda/pkgs/*',
      '$_homeDir/anaconda3/pkgs/*',
      '$_homeDir/.cache/wandb/*',
      '$_homeDir/.cargo/git/*',
      '$_homeDir/.rustup/toolchains/*/share/doc/*',
      '$_homeDir/.rustup/downloads/*',
      '$_homeDir/.gradle/caches/*',
      '$_homeDir/.m2/repository/*',
      '$_homeDir/.sbt/*',
      '$_homeDir/.docker/buildx/cache/*',
      '$_homeDir/.cache/terraform/*',
      '$_homeDir/Library/Caches/com.getpaw.Paw/*',
      '$_homeDir/Library/Caches/com.charlesproxy.charles/*',
      '$_homeDir/Library/Caches/com.proxyman.NSProxy/*',
      '$_homeDir/.grafana/cache/*',
      '$_homeDir/.prometheus/data/wal/*',
      '$_homeDir/.jenkins/workspace/*/target/*',
      '$_homeDir/.cache/gitlab-runner/*',
      '$_homeDir/.github/cache/*',
      '$_homeDir/.circleci/cache/*',
      '$_homeDir/.oh-my-zsh/cache/*',
      '$_homeDir/.config/fish/fish_history.bak*',
      '$_homeDir/.bash_history.bak*',
      '$_homeDir/.zsh_history.bak*',
      '$_homeDir/.sonar/*',
      '$_homeDir/.cache/eslint/*',
      '$_homeDir/.cache/prettier/*',
      '$_homeDir/Library/Caches/CocoaPods/*',
      '$_homeDir/.bundle/cache/*',
      '$_homeDir/.composer/cache/*',
      '$_homeDir/.nuget/packages/*',
      '$_homeDir/.ivy2/cache/*',
      '$_homeDir/.pub-cache/*',
      '$_homeDir/.cache/curl/*',
      '$_homeDir/.cache/wget/*',
      '$_homeDir/Library/Caches/curl/*',
      '$_homeDir/Library/Caches/wget/*',
      '$_homeDir/.cache/pre-commit/*',
      '$_homeDir/.gitconfig.bak*',
      '$_homeDir/.cache/flutter/*',
      '$_homeDir/.gradle/daemon/*',
      '$_homeDir/.android/build-cache/*',
      '$_homeDir/.android/cache/*',
      '$_homeDir/Library/Developer/Xcode/iOS DeviceSupport/*/Symbols/System/Library/Caches/*',
      '$_homeDir/Library/Developer/Xcode/UserData/IB Support/*',
      '$_homeDir/.cache/swift-package-manager/*',
      '$_homeDir/.cache/bazel/*',
      '$_homeDir/.cache/zig/*',
      '$_homeDir/Library/Caches/deno/*',
      '$_homeDir/Library/Caches/com.sequel-ace.sequel-ace/*',
      '$_homeDir/Library/Caches/com.eggerapps.Sequel-Pro/*',
      '$_homeDir/Library/Caches/redis-desktop-manager/*',
      '$_homeDir/Library/Caches/com.navicat.*',
      '$_homeDir/Library/Caches/com.dbeaver.*',
      '$_homeDir/Library/Caches/com.redis.RedisInsight',
      '$_homeDir/Library/Caches/SentryCrash/*',
      '$_homeDir/Library/Caches/KSCrash/*',
      '$_homeDir/Library/Caches/com.crashlytics.data/*',
    ];

    for (final pattern in paths) {
      items.addAll(_scanPattern(pattern));
    }

    return CleanupCategory(
      id: 'extended_dev_tools',
      name: 'Extended Developer Tools',
      description:
          'Xcode, Android Studio, VS Code, JetBrains, Python, and more',
      items: items,
    );
  }

  static CleanupCategory _scanApplications() {
    final items = <CleanupItem>[];

    final paths = [
      '$_homeDir/Library/Developer/Xcode/DerivedData/*',
      '$_homeDir/Library/Developer/CoreSimulator/Caches/*',
      '$_homeDir/Library/Developer/CoreSimulator/Devices/*/data/tmp/*',
      '$_homeDir/Library/Caches/com.apple.dt.Xcode/*',
      '$_homeDir/Library/Developer/Xcode/iOS Device Logs/*',
      '$_homeDir/Library/Developer/Xcode/watchOS Device Logs/*',
      '$_homeDir/Library/Developer/Xcode/Products/*',
      '$_homeDir/Library/Application Support/Code/logs/*',
      '$_homeDir/Library/Application Support/Code/Cache/*',
      '$_homeDir/Library/Application Support/Code/CachedExtensions/*',
      '$_homeDir/Library/Application Support/Code/CachedData/*',
      '$_homeDir/Library/Logs/IntelliJIdea*/*',
      '$_homeDir/Library/Logs/PhpStorm*/*',
      '$_homeDir/Library/Logs/PyCharm*/*',
      '$_homeDir/Library/Logs/WebStorm*/*',
      '$_homeDir/Library/Logs/GoLand*/*',
      '$_homeDir/Library/Logs/CLion*/*',
      '$_homeDir/Library/Logs/DataGrip*/*',
      '$_homeDir/Library/Caches/JetBrains/*',
      '$_homeDir/Library/Application Support/discord/Cache/*',
      '$_homeDir/Library/Application Support/Slack/Cache/*',
      '$_homeDir/Library/Caches/us.zoom.xos/*',
      '$_homeDir/Library/Caches/com.tencent.xinWeChat/*',
      '$_homeDir/Library/Caches/ru.keepcoder.Telegram/*',
      '$_homeDir/Library/Caches/com.openai.chat/*',
      '$_homeDir/Library/Caches/com.anthropic.claudefordesktop/*',
      '$_homeDir/Library/Logs/Claude/*',
      '$_homeDir/Library/Caches/com.microsoft.teams2/*',
      '$_homeDir/Library/Caches/net.whatsapp.WhatsApp/*',
      '$_homeDir/Library/Caches/com.skype.skype/*',
      '$_homeDir/Library/Caches/dd.work.exclusive4aliding/*',
      '$_homeDir/Library/Caches/com.alibaba.AliLang.osx/*',
      '$_homeDir/Library/Application Support/iDingTalk/log/*',
      '$_homeDir/Library/Application Support/iDingTalk/holmeslogs/*',
      '$_homeDir/Library/Caches/com.tencent.meeting/*',
      '$_homeDir/Library/Caches/com.tencent.WeWorkMac/*',
      '$_homeDir/Library/Caches/com.feishu.*/*',
      '$_homeDir/Library/Caches/com.bohemiancoding.sketch3/*',
      '$_homeDir/Library/Application Support/com.bohemiancoding.sketch3/cache/*',
      '$_homeDir/Library/Caches/net.telestream.screenflow10/*',
      '$_homeDir/Library/Caches/Adobe/*',
      '$_homeDir/Library/Caches/com.adobe.*/*',
      '$_homeDir/Library/Application Support/Adobe/Common/Media Cache Files/*',
      '$_homeDir/Library/Application Support/Adobe/Common/Peak Files/*',
      '$_homeDir/Library/Caches/com.apple.FinalCut/*',
      '$_homeDir/Library/Application Support/Final Cut Pro/*/Render Files/*',
      '$_homeDir/Library/Application Support/Motion/*/Render Files/*',
      '$_homeDir/Library/Caches/com.blackmagic-design.DaVinciResolve/*',
      '$_homeDir/Library/Caches/com.adobe.PremierePro.*/*',
      '$_homeDir/Library/Caches/org.blenderfoundation.blender/*',
      '$_homeDir/Library/Caches/com.maxon.cinema4d/*',
      '$_homeDir/Library/Caches/com.autodesk.*/*',
      '$_homeDir/Library/Caches/com.sketchup.*/*',
      '$_homeDir/Library/Caches/com.raycast.macos/*',
      '$_homeDir/Library/Caches/com.tw93.MiaoYan/*',
      '$_homeDir/Library/Caches/com.filo.client/*',
      '$_homeDir/Library/Caches/com.flomoapp.mac/*',
      '$_homeDir/Library/Caches/com.spotify.client/*',
      '$_homeDir/Library/Caches/com.apple.Music',
      '$_homeDir/Library/Caches/com.apple.podcasts',
      '$_homeDir/Library/Caches/com.apple.TV/*',
      '$_homeDir/Library/Caches/tv.plex.player.desktop',
      '$_homeDir/Library/Caches/com.netease.163music',
      '$_homeDir/Library/Caches/com.tencent.QQMusic/*',
      '$_homeDir/Library/Caches/com.kugou.mac/*',
      '$_homeDir/Library/Caches/com.kuwo.mac/*',
      '$_homeDir/Library/Caches/com.colliderli.iina',
      '$_homeDir/Library/Caches/org.videolan.vlc',
      '$_homeDir/Library/Caches/io.mpv',
      '$_homeDir/Library/Caches/com.iqiyi.player',
      '$_homeDir/Library/Caches/com.tencent.tenvideo',
      '$_homeDir/Library/Caches/tv.danmaku.bili/*',
      '$_homeDir/Library/Caches/com.douyu.*/*',
      '$_homeDir/Library/Caches/com.huya.*/*',
      '$_homeDir/Library/Caches/net.xmac.aria2gui',
      '$_homeDir/Library/Caches/org.m0k.transmission',
      '$_homeDir/Library/Caches/com.qbittorrent.qBittorrent',
      '$_homeDir/Library/Caches/com.downie.Downie-*',
      '$_homeDir/Library/Caches/com.folx.*/*',
      '$_homeDir/Library/Caches/com.charlessoft.pacifist/*',
      '$_homeDir/Library/Caches/com.valvesoftware.steam/*',
      '$_homeDir/Library/Application Support/Steam/appcache/*',
      '$_homeDir/Library/Application Support/Steam/htmlcache/*',
      '$_homeDir/Library/Caches/com.epicgames.EpicGamesLauncher/*',
      '$_homeDir/Library/Caches/com.blizzard.Battle.net/*',
      '$_homeDir/Library/Application Support/Battle.net/Cache/*',
      '$_homeDir/Library/Caches/com.ea.*/*',
      '$_homeDir/Library/Caches/com.gog.galaxy/*',
      '$_homeDir/Library/Caches/com.riotgames.*/*',
      '$_homeDir/Library/Caches/com.youdao.YoudaoDict',
      '$_homeDir/Library/Caches/com.eudic.*',
      '$_homeDir/Library/Caches/com.bob-build.Bob',
      '$_homeDir/Library/Caches/com.cleanshot.*',
      '$_homeDir/Library/Caches/com.reincubate.camo',
      '$_homeDir/Library/Caches/com.xnipapp.xnip',
      '$_homeDir/Library/Caches/com.readdle.smartemail-Mac',
      '$_homeDir/Library/Caches/com.airmail.*',
      '$_homeDir/Library/Caches/com.todoist.mac.Todoist',
      '$_homeDir/Library/Caches/com.any.do.*',
      '$_homeDir/Library/Caches/com.runjuu.Input-Source-Pro/*',
      '$_homeDir/Library/Caches/macos-wakatime.WakaTime/*',
      '$_homeDir/Library/Caches/notion.id/*',
      '$_homeDir/Library/Caches/md.obsidian/*',
      '$_homeDir/Library/Caches/com.logseq.*/*',
      '$_homeDir/Library/Caches/com.bear-writer.*/*',
      '$_homeDir/Library/Caches/com.evernote.*/*',
      '$_homeDir/Library/Caches/com.yinxiang.*/*',
      '$_homeDir/Library/Caches/com.runningwithcrayons.Alfred/*',
      '$_homeDir/Library/Caches/cx.c3.theunarchiver/*',
      '$_homeDir/Library/Caches/com.teamviewer.*/*',
      '$_homeDir/Library/Caches/com.anydesk.*/*',
      '$_homeDir/Library/Caches/com.todesk.*/*',
      '$_homeDir/Library/Caches/com.sunlogin.*/*',
      '$_homeDir/.zcompdump*',
      '$_homeDir/.lesshst',
      '$_homeDir/.viminfo.tmp',
      '$_homeDir/.wget-hsts',
    ];

    for (final pattern in paths) {
      items.addAll(_scanPattern(pattern));
    }

    return CleanupCategory(
      id: 'applications',
      name: 'Applications',
      description:
          'Xcode, Discord, Slack, Spotify, Steam, and other app caches',
      items: items,
    );
  }

  static CleanupCategory _scanVirtualization() {
    final items = <CleanupItem>[];

    final paths = [
      '$_homeDir/Library/Caches/com.vmware.fusion',
      '$_homeDir/Library/Caches/com.parallels.*',
      '$_homeDir/VirtualBox VMs/.cache',
      '$_homeDir/.vagrant.d/tmp/*',
    ];

    for (final pattern in paths) {
      items.addAll(_scanPattern(pattern));
    }

    return CleanupCategory(
      id: 'virtualization',
      name: 'Virtualization Tools',
      description: 'VMware Fusion, Parallels, VirtualBox, and Vagrant caches',
      items: items,
    );
  }

  static CleanupCategory _scanOrphanedData() {
    final items = <CleanupItem>[];

    final orphanPaths = [
      '$_homeDir/Library/Caches/com.*',
      '$_homeDir/Library/Caches/org.*',
      '$_homeDir/Library/Caches/net.*',
      '$_homeDir/Library/Caches/io.*',
      '$_homeDir/Library/Logs/com.*',
      '$_homeDir/Library/Logs/org.*',
      '$_homeDir/Library/Logs/net.*',
      '$_homeDir/Library/Logs/io.*',
      '$_homeDir/Library/Saved Application State/*.savedState',
      '$_homeDir/Library/WebKit/com.*',
      '$_homeDir/Library/WebKit/org.*',
      '$_homeDir/Library/WebKit/net.*',
      '$_homeDir/Library/WebKit/io.*',
      '$_homeDir/Library/Cookies/*.binarycookies',
    ];

    final installedBundleIds = _getInstalledBundleIds();

    for (final pattern in orphanPaths) {
      final files = FileSystemService.findFiles(pattern);

      for (final file in files) {
        if (file.contains('/Containers/')) {
          continue;
        }

        final fileName = FileSystemService.getFileName(file);
        var bundleId = fileName.replaceAll('.savedState', '');

        if (fileName.endsWith('.binarycookies')) {
          bundleId = fileName.replaceAll('.binarycookies', '');
        }

        if (!installedBundleIds.contains(bundleId) &&
            !_isSystemBundle(bundleId)) {
          final lastModified = FileSystemService.getLastModified(file);
          if (lastModified != null) {
            final daysSinceModified = DateTime.now()
                .difference(lastModified)
                .inDays;
            if (daysSinceModified > MacOSConstants.orphanDataAgeDays) {
              final size = FileSystemService.calculateSize(file);
              if (size > 0) {
                items.add(
                  CleanupItem(
                    path: file,
                    name: fileName,
                    sizeBytes: size,
                    lastModified: lastModified,
                    isWhitelisted: false,
                  ),
                );
              }
            }
          }
        }
      }
    }

    return CleanupCategory(
      id: 'orphaned_data',
      name: 'Orphaned App Data',
      description: 'Data from uninstalled apps (inactive for 60+ days)',
      items: items,
    );
  }

  static CleanupCategory _scanAppleSilicon() {
    final items = <CleanupItem>[];

    final paths = [
      '$_homeDir/Library/Caches/com.apple.rosetta.update',
      '$_homeDir/Library/Caches/com.apple.amp.mediasevicesd',
    ];

    for (final pattern in paths) {
      items.addAll(_scanPattern(pattern));
    }

    return CleanupCategory(
      id: 'apple_silicon',
      name: 'Apple Silicon Optimizations',
      description: 'Rosetta 2 and Apple Silicon-specific caches',
      items: items,
    );
  }

  static List<CleanupItem> _scanPattern(String pattern) {
    final items = <CleanupItem>[];

    try {
      final files = FileSystemService.findFiles(pattern);

      for (final file in files) {
        // TODO: Add whitelist service
        // if (_whitelistService.isWhitelisted(file)) {
        //   continue;
        // }

        final size = FileSystemService.calculateSize(file);
        if (size == 0) continue;

        final lastModified =
            FileSystemService.getLastModified(file) ?? DateTime.now();

        items.add(
          CleanupItem(
            path: file,
            name: FileSystemService.getFileName(file),
            sizeBytes: size,
            lastModified: lastModified,
            isWhitelisted: false,
          ),
        );
      }
    } catch (_) {}

    return items;
  }

  static Set<String> _getInstalledBundleIds() {
    final bundleIds = <String>{};
    final appLocations = [
      '/Applications',
      '$_homeDir/Applications',
      '/System/Applications',
      '/System/Library/CoreServices/Applications',
      '/Users/Shared/Applications',
      '/Applications/Utilities',
    ];

    final homebrewPaths = [
      '/opt/homebrew/Caskroom',
      '/usr/local/Caskroom',
      '/opt/homebrew/Cellar',
      '/usr/local/Cellar',
    ];

    for (final location in appLocations) {
      try {
        final dir = Directory(location);
        if (!dir.existsSync()) continue;

        for (final entity in dir.listSync(followLinks: false)) {
          if (entity.path.endsWith('.app')) {
            final plistPath = '${entity.path}/Contents/Info.plist';
            final plistFile = File(plistPath);

            if (plistFile.existsSync()) {
              try {
                final result = _run(
                  'defaults',
                  ['read', plistPath, 'CFBundleIdentifier'],
                );

                if (result.exitCode == 0) {
                  final bundleId = result.stdout.toString().trim();
                  if (bundleId.isNotEmpty) {
                    bundleIds.add(bundleId);
                  }
                }
              } catch (_) {}
            }
          }
        }
      } catch (_) {}
    }

    for (final path in homebrewPaths) {
      try {
        final dir = Directory(path);
        if (!dir.existsSync()) continue;

        for (final entity in dir.listSync(followLinks: false)) {
          if (entity.path.endsWith('.app')) {
            final plistPath = '${entity.path}/Contents/Info.plist';
            final plistFile = File(plistPath);

            if (plistFile.existsSync()) {
              try {
                final result = _run(
                  'defaults',
                  ['read', plistPath, 'CFBundleIdentifier'],
                );

                if (result.exitCode == 0) {
                  final bundleId = result.stdout.toString().trim();
                  if (bundleId.isNotEmpty) {
                    bundleIds.add(bundleId);
                  }
                }
              } catch (_) {}
            }
          }
        }
      } catch (_) {}
    }

    try {
      final result = _run(
        'mdfind',
        ["kMDItemKind == 'Application'"],
      );

      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final lines = output.split('\n');
        for (final line in lines) {
          if (line.trim().isEmpty || !line.endsWith('.app')) continue;
          final plistPath = '${line.trim()}/Contents/Info.plist';
          final plistFile = File(plistPath);

          if (plistFile.existsSync()) {
            try {
              final bundleResult = _run(
                'defaults',
                ['read', plistPath, 'CFBundleIdentifier'],
              );

              if (bundleResult.exitCode == 0) {
                final bundleId = bundleResult.stdout.toString().trim();
                if (bundleId.isNotEmpty) {
                  bundleIds.add(bundleId);
                }
              }
            } catch (_) {}
          }
        }
      }
    } catch (_) {}

    try {
      final result = _run(
        'osascript',
        [
          '-e',
          'tell application "System Events" to get bundle identifier \nof every application process',
        ],
      );

      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final bundleIdsStr = output
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty);
        bundleIds.addAll(bundleIdsStr);
      }
    } catch (_) {}

    try {
      final launchAgentsPaths = [
        '$_homeDir/Library/LaunchAgents',
        '/Library/LaunchAgents',
        '/Library/LaunchDaemons',
      ];

      for (final path in launchAgentsPaths) {
        final dir = Directory(path);
        if (!dir.existsSync()) continue;

        for (final entity in dir.listSync(followLinks: false)) {
          if (entity.path.endsWith('.plist')) {
            final fileName = FileSystemService.getFileName(entity.path);
            final bundleId = fileName.replaceAll('.plist', '');
            bundleIds.add(bundleId);
          }
        }
      }
    } catch (_) {}

    return bundleIds;
  }

  static bool _isSystemBundle(String bundleId) {
    const systemPrefixes = [
      'com.apple.',
      'com.microsoft.',
      'com.google.',
      'com.adobe.',
      'org.mozilla.',
      'com.jetbrains.',
      'com.docker.',
    ];

    const systemBundles = [
      'loginwindow',
      'dock',
      'systempreferences',
      'finder',
      'safari',
    ];

    if (systemBundles.contains(bundleId)) {
      return true;
    }

    return systemPrefixes.any((prefix) => bundleId.startsWith(prefix));
  }
}
