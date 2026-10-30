import 'dart:io';

// Keep the application UI on shadcn even when a dependency re-exports Material.
void main() {
  final forbidden = RegExp(
    r'''(?:import|export)\s+['"]package:flutter/(?:material|cupertino)\.dart|\b(?:MaterialApp|CupertinoApp|Icons|CupertinoIcons)\b''',
  );
  var failed = false;
  for (final directory in ['lib', 'test']) {
    for (final file in Directory(directory).listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (forbidden.hasMatch(lines[i])) {
          stderr.writeln('${file.path}:${i + 1}: use shadcn UI components');
          failed = true;
        }
      }
    }
  }
  if (failed) exitCode = 1;
}
