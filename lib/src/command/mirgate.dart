import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:md_picture_migrate_cli/src/command/config.dart';
import 'package:md_picture_migrate_cli/src/uploader/azure.dart';
import 'package:md_picture_migrate_cli/src/uploader/github.dart';

import '../uploader/uploader.dart';
import '../utils.dart';

class MigrateCommand extends Command {
  @override
  final name = 'migrate';

  @override
  final description = 'Migrate the database to the latest version.';

  @override
  final argParser = ArgParser()
    ..addOption(
      'directory',
      abbr: 'd',
      help: 'The directory to migrate.',
    )
    ..addFlag(
      'download',
      help: 'Download the pictures.',
      defaultsTo: true,
    )
    ..addFlag(
      'upload',
      abbr: 'u',
      help: 'Upload the pictures to the server.',
      defaultsTo: true,
    )
    ..addFlag(
      'replace',
      abbr: 'r',
      help: 'Replace the pictures in the markdown files.',
      defaultsTo: true,
    );

  late final config = Config.fromCache();

  @override
  Future<void> run() async {
    final directory = argResults!['directory'] as String;
    final download = argResults!['download'] as bool;
    final upload = argResults!['upload'] as bool;
    final replace = argResults!['replace'] as bool;

    final imageListFile = getMarkdownImageListPath(directory);

    if (!File(imageListFile).existsSync()) {
      print('No image list file found for $directory.');
      print('Please run scan command first.');
      return;
    }

    var srcUrls = <String>[];

    if (File(imageListFile).existsSync()) {
      final lines = File(imageListFile).readAsLinesSync();
      if (lines.isNotEmpty) {
        srcUrls.addAll(lines);
      }
    }

    srcUrls = srcUrls.where((element) => element.isNotEmpty).toList();

    if (download) {
      await downloadPictures(srcUrls);
    }

    if (upload) {
      final uploader = makeUploader();
      await uploader.upload(srcUrls);
    }

    if (replace) {
      await replacePictures(directory, srcUrls);
    }
  }

  final dio = Dio();

  Future<File?> downloadPicture(String srcUrl) async {
    final fileName = getImageCachedPath(srcUrl);
    final file = File(fileName);
    if (!file.existsSync()) {
      try {
        final uri = Uri.parse(srcUrl);
        final headers = <String, String>{
          'Referer': uri.origin,
          'Host': uri.host,
          'user-agent': 'curl/7.79.1',
          'accept': '*/*',
        };
        await dio.downloadUri(
          uri,
          fileName,
          options: Options(
            headers: headers,
          ),
        );
        print('Downloaded $srcUrl. target file: $fileName');
      } catch (e) {
        print('Failed to download $srcUrl. target file: $fileName');
        print('Error: $e');
        return null;
      }
    }
    return file;
  }

  Future<void> downloadPictures(List<String> srcUrls) async {
    final futures = <Future<File?>>[];

    for (final srcUrl in srcUrls) {
      futures.add(downloadPicture(srcUrl));
    }

    final files = await Future.wait(futures);

    final failedFiles = files.where((element) => element == null).toList();

    if (failedFiles.isNotEmpty) {
      print('Failed to download ${failedFiles.length} files.');
      print('Please check the error messages above and retry.');
      throw Exception('Failed to download ${failedFiles.length} files.');
    }
  }

  String checkConfigParam(String key, String? value) {
    if (value == null || value.isEmpty) {
      throw Exception('Please configure the $key first.');
    }
    return value;
  }

  Uploader makeUploader() {
    final type = config.type;
    switch (type) {
      case 'azure':
        return AzureUploader(config);
      case 'github':
        return GithubUploader(config);
    }
    throw Exception('Unknown uploader type: $type');
  }

  Future<void> replacePictures(String directory, List<String> srcUrls) async {
    final dir = Directory(directory);
    final files = dir.listSync(recursive: true);

    for (final file in files) {
      if (file is File) {
        try {
          final content = file.readAsStringSync();
          var newContent = content;
          for (final srcUrl in srcUrls) {
            final newUrl = File(getImageRemoteCachedPath(srcUrl))
                .readAsStringSync()
                .trim();
            newContent = newContent.replaceAll(srcUrl, newUrl);
          }
          file.writeAsStringSync(newContent);

          print('Replaced $file');
        } catch (e) {
          print('Failed to replace $file');
          print('Error: $e');
        }
      }
    }
  }
}
