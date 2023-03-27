import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import '../utils.dart';

class ScanCommand extends Command {
  @override
  final name = 'scan';

  @override
  final description = 'Scan and list all pictures.';

  @override
  final argParser = ArgParser()
    ..addOption(
      'directory',
      abbr: 'd',
      help: 'The directory to scan.',
    )
    ..addMultiOption(
      'include-prefix',
      abbr: 'i',
      help: 'The prefix of the picture url to include.',
      defaultsTo: ['http://', 'https://'],
    )
    ..addMultiOption(
      'exclude-prefix',
      abbr: 'x',
      help: 'The prefix of the picture url to exclude.',
      defaultsTo: [],
    )
    ..addMultiOption(
      'markdown-extensions',
      abbr: 'e',
      help: 'The file extensions to include.',
      defaultsTo: ['.md', '.markdown'],
    );

  bool isMarkdownFile(File file, List<String> extensions) {
    for (final extension in extensions) {
      if (file.path.endsWith(extension)) {
        return true;
      }
    }
    return false;
  }

  bool needToMigrate(
    String url,
    List<String> includePrefixes,
    List<String> excludePrefixes,
  ) {
    if (excludePrefixes.any((element) => url.startsWith(element))) {
      return false;
    }
    if (includePrefixes.any((element) => url.startsWith(element))) {
      return true;
    }
    return false;
  }

  @override
  Future<void> run() async {
    final directory = argResults!['directory'] as String;
    final includePrefixes = argResults!['include-prefix'] as List<String>;
    final excludePrefixes = argResults!['exclude-prefix'] as List<String>;
    final markdownExtensions =
        argResults!['markdown-extensions'] as List<String>;

    final dir = Directory(directory);

    if (!dir.existsSync()) {
      print('Directory not found: $directory');
      return;
    }

    final files = dir
        .listSync(recursive: true)
        .toList()
        .whereType<File>()
        .where((element) => isMarkdownFile(element, markdownExtensions));

    final result = <String>[];

    print('Scanning...');

    for (final file in files) {
      final content = file.readAsStringSync();
      final lines = content.split('\n');

      for (final line in lines) {
        if (line.startsWith('![')) {
          final url = line.split('](')[1].split(')')[0];
          if (needToMigrate(url, includePrefixes, excludePrefixes)) {
            result.add(url);
          }
        }
      }
    }

    final output = getMarkdownImageListPath(directory);

    final outputFile = File(output);
    if (outputFile.existsSync()) {
      outputFile.deleteSync();
    }
    if (!outputFile.existsSync()) {
      outputFile.createSync(recursive: true);
    }
    outputFile.writeAsStringSync(result.join('\n'));

    print('Done.');
    print('Result saved to: $output');
  }
}
