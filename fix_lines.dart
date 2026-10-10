import 'dart:io';

void main() {
  final file = File('lib/features/pengguna/konsultasi/daftar_dokter_page.dart');
  final lines = file.readAsLinesSync();

  // Find line 378: "              ),"
  // Line 376 is: "                ),"
  // Line 377 is: "              ),"
  // Line 378 is: "              ),"
  // Line 379 is: "            ],"

  final out = <String>[];
  for (int i = 0; i < lines.length; i++) {
    // Check if line 377 and 378 are duplicates
    if (i > 365 && i < 385) {
      if (lines[i].trim() == '),' && lines[i - 1].trim() == '),') {
        // Skip duplicate
        print('Skipping duplicate closing paren at line ${i + 1}');
        continue;
      }
    }

    // Check line around 920-925
    if (i > 910 && i < 935) {
      if (lines[i].trim() == ')' && lines[i + 1].trim() == '),') {
        print('Skipping orphan ) at line ${i + 1}');
        continue;
      }
    }

    out.add(lines[i]);
  }

  file.writeAsStringSync(out.join('\n'));
  print('Done processing lines.');
}
