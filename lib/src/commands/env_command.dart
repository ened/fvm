import 'package:io/io.dart';

import '../../exceptions.dart';
import '../services/flutter_tools.dart';
import '../services/project_service.dart';
import '../utils/console_utils.dart';
import '../utils/logger.dart';
import '../workflows/ensure_cache.workflow.dart';
import 'base_command.dart';

/// Configure different flutter version per environment
class EnvCommand extends BaseCommand {
  @override
  final name = 'env';
  @override
  final description = 'Switches between different project environments';

  @override
  final invocation = 'fvm env <environment_name>';

  /// Constructor
  EnvCommand();

  @override
  Future<int> run() async {
    String environment;

    if (argResults.rest.isEmpty) {
      environment = await projectEnvSeletor();
    }

    // Gets env from param if not yet selected
    environment ??= argResults.rest[0];

    final project = await ProjectService.findAncestor();

    // If project use check that is Flutter project
    if (project == null) {
      throw const FvmUsageException(
        'Cannot find any FVM config.',
      );
    }

    // Gets environment version
    final envs = project.config.environment;
    final envVersion = envs[environment] as String;

    // Check if env confi exists
    if (envVersion == null) {
      throw FvmUsageException('Environment: "$environment" is not configured');
    }

    // Makes sure that is a valid version
    final validVersion = await FlutterTools.inferValidVersion(envVersion);

    FvmLogger.spacer();

    FvmLogger.info(
      '''Switching to [$environment] environment, which uses [${validVersion.name}] Flutter sdk.''',
    );

    // Run install workflow
    await ensureCacheWorkflow(validVersion);

    // Pin version to project
    await ProjectService.pinVersion(project, validVersion);

    FvmLogger.fine(
      '''Now using [$environment] environment. Flutter version [${validVersion.name}].''',
    );

    FvmLogger.spacer();

    return ExitCode.success.code;
  }
}
