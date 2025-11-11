import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart' as path_provider;

const String _settingsAssetPath = 'lib/data/user-settings.json';
const String _settingsFileName = 'user-settings.json';
const String _fallbackDirName = 'stem_sprouts';

Future<Map<String, dynamic>> loadUserSettings() async {
  final String defaultsRaw = await rootBundle.loadString(_settingsAssetPath);
  final Map<String, dynamic> defaults =
      jsonDecode(defaultsRaw) as Map<String, dynamic>;

  try {
    final File file = await _settingsFile();
    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString(defaultsRaw);
      return defaults;
    }

    final String contents = await file.readAsString();
    return jsonDecode(contents) as Map<String, dynamic>;
  } on FormatException {
    final File file = await _settingsFile();
    await file.writeAsString(defaultsRaw);
    return defaults;
  } catch (err, stack) {
    debugPrint('Failed to load user settings: $err');
    debugPrint('$stack');
    return defaults;
  }
}

Future<bool> saveUserSettings(Map<String, dynamic> data) async {
  try {
    final File file = await _settingsFile();
    final String encoded = jsonEncode(data);
    await file.writeAsString(encoded);
    return true;
  } catch (err, stack) {
    debugPrint('Failed to save user settings: $err');
    debugPrint('$stack');
    return false;
  }
}

Future<File> _settingsFile() async {
  Directory directory;
  try {
    directory = await path_provider.getApplicationDocumentsDirectory();
  } on MissingPluginException {
    directory = await _fallbackDirectory();
  }

  final File file = File(p.join(directory.path, _settingsFileName));
  return file;
}

Future<Directory> _fallbackDirectory() async {
  final String? home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  if (home != null && home.isNotEmpty) {
    final Directory dir = Directory(p.join(home, '.$_fallbackDirName'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  final Directory tempDir =
      Directory(p.join(Directory.systemTemp.path, _fallbackDirName));
  if (!await tempDir.exists()) {
    await tempDir.create(recursive: true);
  }
  return tempDir;
}
