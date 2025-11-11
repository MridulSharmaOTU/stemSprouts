import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart' as path_provider;

class UserSettingsStore {
  const UserSettingsStore();

  static const String _settingsAssetPath = 'lib/data/user-settings.json';
  static const String _settingsFileName = 'user-settings.json';

  Future<Map<String, dynamic>> load() async {
    final defaultsRaw = await rootBundle.loadString(_settingsAssetPath);
    final defaults = jsonDecode(defaultsRaw) as Map<String, dynamic>;

    try {
      final file = await _settingsFile();
      if (!await file.exists()) {
        await file.create(recursive: true);
        await file.writeAsString(defaultsRaw);
        return defaults;
      }

      final contents = await file.readAsString();
      return jsonDecode(contents) as Map<String, dynamic>;
    } on FormatException {
      final file = await _settingsFile();
      await file.writeAsString(defaultsRaw);
      return defaults;
    }
  }

  Future<bool> save(Map<String, dynamic> data) async {
    try {
      final file = await _settingsFile();
      final encoded = jsonEncode(data);
      await file.writeAsString(encoded);
      return true;
    } catch (err, stack) {
      debugPrint('Failed to save user settings: $err');
      debugPrint('$stack');
      return false;
    }
  }

  Future<File> _settingsFile() async {
    final dir = await path_provider.getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _settingsFileName));
  }
}
