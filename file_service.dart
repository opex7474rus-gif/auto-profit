import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class FileService {
  static Future<String> copyIntoApp(String sourcePath, String originalName) async {
    final dir = await getApplicationDocumentsDirectory();
    final media = Directory(p.join(dir.path, 'files'));
    if (!await media.exists()) await media.create(recursive:true);
    final safe = '${const Uuid().v4()}_${p.basename(originalName)}';
    return (await File(sourcePath).copy(p.join(media.path, safe))).path;
  }
}
