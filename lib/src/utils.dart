import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart' as crypto;

String sha256Text(String input) {
  var data = utf8.encode(input);
  var hash = crypto.sha256.convert(data);
  return hash.toString();
}

String getCacheDir() {
  final env = Platform.environment;

  String cachePath;

  if (env.containsKey('XDG_CACHE_HOME')) {
    cachePath = env['XDG_CACHE_HOME']!;
  } else {
    cachePath = '${env['HOME']}/.cache';
  }

  return '$cachePath/md_picture_migrate_cli';
}

String getConfigPath() {
  final cacheDir = getCacheDir();
  final configPath = '$cacheDir/config.json';
  return configPath;
}

String readlink(String src) {
  final file = File(src);
  if (file.existsSync()) {
    return file.resolveSymbolicLinksSync();
  }
  return src;
}

String getMarkdownImageListPath(String markdownPath) {
  markdownPath = readlink(markdownPath);
  final cacheDir = getCacheDir();
  final cachePath = '$cacheDir/list/${sha256Text(markdownPath)}';
  return cachePath;
}

String getImageCachedPath(String srcUrl) {
  final cacheDir = getCacheDir();
  final imageDir = '$cacheDir/images';
  if (!Directory(imageDir).existsSync()) {
    Directory(imageDir).createSync(recursive: true);
  }

  final sha = sha256Text(srcUrl);
  final subPath = sha.substring(0, 8);

  final cachePath = '$imageDir/$subPath/$sha';
  return cachePath;
}

String getImageRemoteCachedPath(String srcUrl) {
  final cacheFile = getImageCachedPath(srcUrl);
  final cachePath = '$cacheFile.upload';
  return cachePath;
}
