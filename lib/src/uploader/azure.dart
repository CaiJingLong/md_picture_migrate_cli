import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:md_picture_migrate_cli/src/uploader/uploader.dart';
import 'package:md_picture_migrate_cli/src/utils.dart';

import '../command/config.dart';

class AzureUploader extends Uploader {
  final Config config;

  AzureUploader(this.config)
      : assert(config.azureEndpoint != null),
        assert(config.azureUser != null),
        assert(config.azureToken != null);

  String get endpoint => config.azureEndpoint!;
  String get token => config.azureToken!;
  String get username => config.azureUser!;

  late final _Converter converter = _Converter(endpoint);

  final dio = Dio();

  String get organization => converter.organization;
  String get project => converter.project;
  String get repository => converter.repository;

  Uri get api => Uri.parse(
        'https://dev.azure.com/$organization/$project/_apis/git/repositories/$repository',
      );

  Uri makeUri(String path, Map<String, String> params) {
    final uri = Uri.parse(
      'https://dev.azure.com/$organization/$project/_apis/git/repositories/$repository/$path',
    );

    params['api-version'] = '7.0';

    return uri.replace(queryParameters: params);
  }

  Future<String> getLastOldId() async {
    if (newId != null) {
      return newId!;
    }

    final uri = makeUri('refs', {
      '\$top': '1',
      'filterContains': 'main',
    });

    final response = await dio.getUri(uri);

    final Map map = await response.data;
    return map['value'][0]['objectId'];
  }

  String? newId;

  Future<String> _upload(
    String username,
    String srcUrl,
    File file,
    String ext,
  ) async {
    final uploadCacheFile = File(getImageRemoteCachedPath(srcUrl));

    if (uploadCacheFile.existsSync()) {
      return uploadCacheFile.readAsStringSync().trim();
    }

    final oldId = await getLastOldId();

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';

    final uri = makeUri('pushes', {});

    final basicToken = base64Encode(utf8.encode('$organization:$token'));

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
      uri,
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

    final imageUrl = makeUri('items', {
      'path': '/$fileName',
      'versionDescriptor[versionOptions]': '0',
      'versionDescriptor[versionType]': '0',
      'versionDescriptor[version]': 'main',
      'resolveLfs': 'true',
      '\$format': 'octetStream',
    });

    return imageUrl.toString();
  }

  @override
  Future<String> uploadPicture(String srcUrl, File file) {
    final ext = file.path.split('.').last;
    return _upload(username, srcUrl, file, ext);
  }
}

class _Converter {
  final String endpoint;

  _Converter(this.endpoint);

  late final uri = Uri.parse(endpoint);

  String get organization => uri.pathSegments[0];

  String get project => uri.pathSegments[1];

  String get repository => uri.pathSegments[3];
}
