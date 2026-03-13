import 'dart:io';

void main() {
  final dir = Directory('lib');
  final regex = RegExp(r'\.withOpacity\((.*?)\)');
  
  for (final file in dir.listSync(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      final content = file.readAsStringSync();
      if (content.contains('.withOpacity(')) {
        final newContent = content.replaceAllMapped(regex, (match) {
          return '.withValues(alpha: ${match.group(1)})';
        });
        file.writeAsStringSync(newContent);
        // debugPrint('Fixed ${file.path}');
      }
    }
  }
}
