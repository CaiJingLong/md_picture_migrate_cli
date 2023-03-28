import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:md_picture_migrate_cli/src/uploader/uploader.dart';

import '../command/config.dart';

class GithubUploader extends Uploader {
  final Config config;

  GithubUploader(this.config)
      : assert(config.githubEndpoint != null),
        assert(config.githubToken != null),
        assert(config.githubUser != null);

  late final _Converter converter = _Converter(config.githubEndpoint!);

  String get username => converter.username;
  String get repo => converter.repo;
  String get token => config.githubToken!;

  final dio = Dio();

  @override
  Future<String> uploadPicture(String srcImageUrl, File file) async {
    final imageContent = base64Encode(file.readAsBytesSync());
    final username = config.githubUser!;
    final repo = converter.repo;
    final branch = 'main';

    final name = getImageName(srcImageUrl);

    final url = Uri.parse(
      'https://api.github.com/repos/$username/$repo/contents/$name',
    );
    final data = {
      'message': 'upload by md-picture-migrate',
      'content': imageContent,
      'branch': branch,
      'path': name,
    };

    final body = await dio.postUri(url, data: data);

    final map = body.data as Map;

    if (config.useJsdelivr == true) {
      return 'https://cdn.jsdelivr.net/gh/$username/$repo@main/$name';
    }

    return map['content']['download_url'] as String;
  }
}

class _Converter {
  // https://github.com/username/repo.git
  final String endpoint;

  _Converter(this.endpoint);

  Uri get uri => Uri.parse(endpoint);

  String get username => uri.pathSegments[0];

  String get repo => uri.pathSegments[1];
}
