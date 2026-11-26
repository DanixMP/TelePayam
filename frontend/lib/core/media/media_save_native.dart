import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';

Future<String?> saveMediaBytes(Uint8List bytes, String suggestedName) async {
  suggestedName = suggestedName.replaceAll(
    RegExp(r'[\\/:*?"<>|\x00-\x1f]'),
    '_',
  );
  if (Platform.isAndroid || Platform.isIOS) {
    final root = await getApplicationDocumentsDirectory();
    final dir = await Directory(
      '${root.path}/Downloads',
    ).create(recursive: true);
    final file = File(
      '${dir.path}/${DateTime.now().microsecondsSinceEpoch}-$suggestedName',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
  final location = await getSaveLocation(suggestedName: suggestedName);
  if (location == null) return null;
  await File(location.path).writeAsBytes(bytes, flush: true);
  return location.path;
}
