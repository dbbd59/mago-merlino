import 'dart:io';

import 'package:patchai_flutter_modules_cli/src/core/runner.dart';

void main(List<String> args) async {
  await _flushThenExit(await Runner().run(args));
}

Future _flushThenExit(int status) {
  return Future.wait<void>([stdout.close(), stderr.close()])
      .then<void>((_) => exit(status));
}