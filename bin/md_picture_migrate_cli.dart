import 'package:args/command_runner.dart';
import 'package:md_picture_migrate_cli/md_picture_migrate_cli.dart';

Future<void> main(List<String> arguments) async {
  final CommandRunner runner = CommandRunner(
    'md_picture_migrate_cli',
    'A command-line tool for migrating pictures in markdown files.',
  );

  runner.addCommand(ScanCommand());
  runner.addCommand(MigrateCommand());
  runner.addCommand(CleanCommand());
  runner.addCommand(ConfigCommand());

  await runner.run(arguments);
}
