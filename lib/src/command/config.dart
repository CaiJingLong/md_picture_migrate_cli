import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:md_picture_migrate_cli/src/utils.dart';

class Config {
  String? azureEndpoint;
  String? azureToken;
  String? azureUser;

  String? githubEndpoint;
  String? githubToken;
  String? githubUser;
  bool? useJsdelivr;

  String? type;

  Config();

  Config.fromJson(Map<String, dynamic> json)
      : azureEndpoint = json['azure-endpoint'],
        azureToken = json['azure-token'],
        githubEndpoint = json['github-endpoint'],
        githubToken = json['github-token'],
        githubUser = json['github-user'],
        azureUser = json['azure-user'],
        useJsdelivr = json['use-jsdelivr'] ?? true,
        type = json['type'];

  factory Config.fromCache() {
    final file = File(getConfigPath());
    if (file.existsSync()) {
      final content = file.readAsStringSync();
      final json = jsonDecode(content);
      return Config.fromJson(json);
    } else {
      final config = Config();
      config.save();
      return config;
    }
  }

  Map<String, dynamic> toJson() => {
        'azure-endpoint': azureEndpoint,
        'azure-token': azureToken,
        'azure-user': azureUser,
        'github-endpoint': githubEndpoint,
        'github-token': githubToken,
        'github-user': githubUser,
        'use-jsdelivr': useJsdelivr ?? true,
        'type': type,
      };

  void save() {
    final file = File(getConfigPath());
    final json = jsonEncode(toJson());
    file.writeAsStringSync(json);
  }
}

class ConfigCommand extends Command {
  @override
  final name = 'config';
  @override
  final description = 'Configure the Azure Git and Github settings.';

  late final _config = Config.fromCache();

  ConfigCommand() {
    argParser
      ..addFlag('list',
          help: 'List the current configuration.', defaultsTo: false)
      ..addOption('azure-endpoint',
          help:
              'The endpoint of the Azure Git url. Such as: https://dev.azure.com/user/images/_git/MirrorImages')
      ..addOption('azure-token',
          help:
              'The personal access token for authenticating with the Azure Git repository.')
      ..addOption('azure-user', help: 'The user for Auzre.')
      ..addOption('github-endpoint',
          help: 'The endpoint of the Github repository.')
      ..addOption('github-token',
          help:
              'The personal access token for authenticating with the Github repository.')
      ..addFlag('use-jsdelivr',
          help: 'Use jsdelivr to accelerate the image loading.',
          defaultsTo: true)
      ..addOption('github-user', help: 'The user for Github.')
      ..addOption('type',
          help: 'The type of the repository. (azure or github)');
  }

  @override
  void run() {
    final list = argResults!['list'] as bool;

    if (list) {
      print('The config file: ${getConfigPath()}');
      final map = _config.toJson();
      map.forEach((key, value) {
        print('$key: $value');
      });
      return;
    }

    // Update configuration with new values
    _config.azureEndpoint =
        argResults!['azure-endpoint'] as String? ?? _config.azureEndpoint;
    _config.azureToken =
        argResults!['azure-token'] as String? ?? _config.azureToken;
    _config.azureUser =
        argResults!['azure-user'] as String? ?? _config.azureUser;

    _config.githubEndpoint =
        argResults!['github-endpoint'] as String? ?? _config.githubEndpoint;
    _config.githubToken =
        argResults!['github-token'] as String? ?? _config.githubToken;

    // Write configuration to file in JSON format
    _config.save();
  }
}
