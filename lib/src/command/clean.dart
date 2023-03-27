import 'dart:io';

import 'package:args/command_runner.dart';

import '../utils.dart';

class CleanCommand extends Command {
  @override
  String get name => 'clean';

  @override
  String get description => 'Clean the cache of the CLI.';

  @override
  Future<void> run() async {
    final cacheDir = getCacheDir();
    final listDir = Directory('$cacheDir/list');
    final imagesDir = Directory('$cacheDir/images');

    if (listDir.existsSync()) {
      listDir.deleteSync(recursive: true);
      print('Cleaned $listDir.');
    }

    if (imagesDir.existsSync()) {
      imagesDir.deleteSync(recursive: true);
      print('Cleaned $imagesDir.');
    }

    print('Cleaned.');
  }
}
