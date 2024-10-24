import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> getFilePath(String fileName) async {
  Directory directory = await getApplicationDocumentsDirectory();
  return '${directory.path}/$fileName';
}

Future<File> getFile(String fileName) async {
  String path = await getFilePath(fileName);
  return File(path);
}

Future<Map<String, dynamic>> readJson(String fileName) async {
  try {
    File file = await getFile(fileName);
    String contents = await file.readAsString();
    return jsonDecode(contents);
  } catch (e) {
    return {};
  }
}

Future<void> writeJson(String fileName, Map<String, dynamic> data) async {
  File file = await getFile(fileName);
  String jsonString = jsonEncode(data);
  await file.writeAsString(jsonString);
}
