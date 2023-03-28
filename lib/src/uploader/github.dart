import 'package:md_picture_migrate_cli/src/uploader/uploader.dart';

import '../command/config.dart';

class GithubUploader extends Uploader {
  final Config config;

  GithubUploader(this.config);

  @override
  Future<String> uploadPicture(String url) {
    throw UnimplementedError();
  }
}
