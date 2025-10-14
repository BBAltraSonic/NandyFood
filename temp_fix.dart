// Temporary file to look at the exact content
import 'dart:io';

void main() {
  var lines = File('lib/core/utils/security/input_validator.dart').readAsLinesSync();
  print('Line 8 (index 7): "${lines[7]}"');
  print('Line 9 (index 8): "${lines[8]}"');
  print('Line 10 (index 9): "${lines[9]}"');
}