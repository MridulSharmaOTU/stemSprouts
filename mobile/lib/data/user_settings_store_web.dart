import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const String _settingsAssetPath = 'lib/data/user-settings.json';
const String _storageKey = 'stem_sprouts.user_settings';

Future<Map<String, dynamic>> loadUserSettings() async {
  final String defaultsRaw = await rootBundle.loadString(_settingsAssetPath);
  final Map<String, dynamic> defaults =
      jsonDecode(defaultsRaw) as Map<String, dynamic>;

  final String? stored = html.window.localStorage[_storageKey];
  if (stored == null) {
    html.window.localStorage[_storageKey] = defaultsRaw;
    return defaults;
  }

  try {
    return jsonDecode(stored) as Map<String, dynamic>;
  } on FormatException {
    html.window.localStorage[_storageKey] = defaultsRaw;
    return defaults;
  } catch (err, stack) {
    debugPrint('Failed to parse stored user settings: $err');
    debugPrint('$stack');
    html.window.localStorage[_storageKey] = defaultsRaw;
    return defaults;
  }
}

Future<bool> saveUserSettings(Map<String, dynamic> data) async {
  try {
    final String encoded = jsonEncode(data);
    html.window.localStorage[_storageKey] = encoded;
    return true;
  } catch (err, stack) {
    debugPrint('Failed to save user settings: $err');
    debugPrint('$stack');
    return false;
  }
}
