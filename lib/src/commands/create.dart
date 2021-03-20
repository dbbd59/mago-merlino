import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:patchai_flutter_modules_cli/src/template/template.dart';
import 'package:path/path.dart' as path;

final RegExp _identifierRegExp = RegExp('[a-z_][a-z0-9_]*');

typedef GeneratorBuilder = Future<MasonGenerator> Function(MasonBundle);

class Create extends Command<int> {
  Create({
    Logger logger,
    GeneratorBuilder generator,
  })  : _logger = logger ?? Logger(),
        _generator = generator ?? MasonGenerator.fromBundle {
    argParser.addOption(
      'project-name',
      help: 'The project name for this new Flutter project. '
          'This must be a valid dart package name.',
    );
  }

  final Logger _logger;
  final Future<MasonGenerator> Function(MasonBundle) _generator;

  @override
  String get description =>
      'Creates a new flutter module project in the specified directory.';

  @override
  String get summary => '$invocation\n$description';

  @override
  String get name => 'create';

  @override
  String get invocation => 'mago_merlino create <output directory>';

  @visibleForTesting
  ArgResults argResultOverrides;

  ArgResults get _argResults => argResultOverrides ?? argResults;

  @override
  Future<int> run() async {
    final outputDirectory = _outputDirectory;
    final projectName = _projectName;
    final generateDone = _logger.progress('Bootstrapping');
    final templateBundle = await generateTemplate();
    final generator = await _generator(templateBundle);
    final fileCount = await generator.generate(
      DirectoryGeneratorTarget(outputDirectory, _logger),
      vars: {'project_name': projectName},
    );

    generateDone('Bootstrapping complete');
    _logSummary(fileCount);

    return ExitCode.success.code;
  }

  void _logSummary(int fileCount) {
    _logger
      ..info(
        '${lightGreen.wrap('✓')} '
        'Generated $fileCount file(s):',
      )
      ..flush(_logger.success)
      ..info('\n')
      ..alert('Created a new Flutter module');
  }

  String get _projectName {
    final projectName = _argResults['project-name'] ??
        path.basename(path.normalize(_outputDirectory.absolute.path));
    _validateProjectName(projectName);
    return projectName;
  }

  void _validateProjectName(String name) {
    final isValidProjectName = _isValidPackageName(name);
    if (!isValidProjectName) {
      throw UsageException(
        '"$name" is not a valid package name.\n\n'
        'See https://dart.dev/tools/pub/pubspec#name for more information.',
        usage,
      );
    }
  }

  bool _isValidPackageName(String name) {
    final match = _identifierRegExp.matchAsPrefix(name);
    return match != null && match.end == name.length;
  }

  Directory get _outputDirectory {
    final rest = _argResults.rest;
    _validateOutputDirectoryArg(rest);
    return Directory(rest.first);
  }

  void _validateOutputDirectoryArg(List<String> args) {
    if (args.isEmpty) {
      throw UsageException(
        'No option specified for the output directory.',
        usage,
      );
    }

    if (args.length > 1) {
      throw UsageException('Multiple output directories specified.', usage);
    }
  }
}