import 'dart:io';

import '../utils.dart';

abstract class Uploader {
  Future<void> upload(List<String> urls) async {
    for (final url in urls) {
      final remoteFilePath = getImageRemoteCachedPath(url);
      final file = File(remoteFilePath);
      if (file.existsSync()) {
        continue;
      }

      final imageCacheFile = File(getImageCachedPath(url));

      final remoteImageUrl = await uploadPicture(url, imageCacheFile);
      file.writeAsStringSync(remoteImageUrl);
    }
  }

  String getExtension(String url) {
    if (url.contains('.')) {
      return url.split('.').last;
    } else {
      return 'png';
    }
  }

  String getImageName(String url) {
    final ext = getExtension(url);
    final ms = DateTime.now().millisecondsSinceEpoch;
    return '$ms.$ext';
  }

  Future<String> uploadPicture(String srcUrl, File file);
}
