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

      final remoteImageUrl = await uploadPicture(url);
      file.writeAsStringSync(remoteImageUrl);
    }
  }

  Future<String> uploadPicture(String url);
}
