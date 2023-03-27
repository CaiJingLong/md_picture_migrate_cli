import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:md_picture_migrate_cli/src/utils.dart';

class AzureUploader {
  final String endpoint;

  final String token;

  AzureUploader(this.endpoint, this.token);

  late final _Converter converter = _Converter(endpoint);

  final dio = Dio()
    ..options.headers = {
      'Content-Type': 'application/json-patch+json',
    };

  String? _projectId;
  String? _repositoryId;

  String get organization => converter.organization;
  String get project => _projectId ?? converter.project;
  String get repository => _repositoryId ?? converter.repository;

  bool _init = false;

  Future<void> refreshIds() async {
    if (_init) {
      return;
    }
    final api =
        'https://dev.azure.com/$organization/$project/_apis/git/repositories/$repository?api-version=7.0';

    return dio.getUri(Uri.parse(api)).then((response) {
      final Map map = response.data;
      _projectId = map['project']['id'];
      _repositoryId = map['id'];
      _init = true;
    });
  }

  Future<String> getLastOldId() async {
    if (newId != null) {
      return newId!;
    }

    final org = organization;
    final project = this.project;
    final repository = this.repository;

    final api =
        'https://dev.azure.com/$org/$project/_apis/git/repositories/$repository/commits?api-version=7.0';

    final response = await dio.getUri(Uri.parse(api));

    final Map map = await response.data;
    return map['value'][0]['commitId'];
  }

  String? newId;

  Future<void> upload(
      String user, String email, String srcUrl, File file, String ext) async {
    await refreshIds();

    final uploadCacheFile = File(getImageCachedPath(srcUrl) + '.upload');

    if (uploadCacheFile.existsSync()) {
      return;
    }

    final org = organization;
    final project = this.project;
    final repository = this.repository;

    final oldId = await getLastOldId();

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';

    final api =
        'https://dev.azure.com/$org/$project/_apis/git/repositories/$repository/pushes?api-version=5.0';

    final basicToken = base64Encode(utf8.encode('$user:$token'));

    final headers = <String, String>{'Authorization': 'basic $basicToken'};

    final contentBase64 = base64Encode(file.readAsBytesSync());

    final requestMap = {
      'refUpdates': [
        {
          'name': 'refs/heads/main',
          'oldObjectId': oldId,
        }
      ],
      'commits': [
        {
          'comment': 'Migrate image from $srcUrl',
          'changes': [
            {
              'changeType': 'add',
              'item': {'path': '/$fileName'},
              'newContent': {
                'content': contentBase64,
                'contentType': 'base64encoded',
              }
            }
          ]
        }
      ],
    };

    final response = await dio.postUri(
      Uri.parse(api),
      data: json.encode(requestMap),
      options: Options(
        headers: headers,
        followRedirects: true,
      ),
    );
    if (response.statusCode != 201) {
      throw Exception('The status of response is not 201');
    }

    final Map map = response.data;

    newId = map['refUpdates'][0]['newObjectId'];

    final rawUrl =
        'https://dev.azure.com/$org/$project/_apis/git/repositories/$repository/items?path=/$fileName&api-version=7.0';

    if (!uploadCacheFile.existsSync()) {
      uploadCacheFile.createSync(recursive: true);
    }

    uploadCacheFile.writeAsStringSync(rawUrl);

    print('uploaded $srcUrl to $rawUrl');
  }
}

class _Converter {
  /// https://dev.azure.com/user/images/_git/MirrorImages
  final String endpoint;

  _Converter(this.endpoint);

  late final uri = Uri.parse(endpoint);

  String get organization => uri.pathSegments[0];

  String get project => uri.pathSegments[1];

  String get repository => uri.pathSegments[3];
}
