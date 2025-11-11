import 'dart:html' as html;

import 'settings_persistence_interface.dart';

class WebSettingsPersistence implements SettingsPersistence {
  WebSettingsPersistence();

  static const _storageKey = 'stem_sprouts_user_settings';

  @override
  Future<String> load(String defaultContents) async {
    final stored = html.window.localStorage[_storageKey];
    if (stored == null || stored.isEmpty) {
      html.window.localStorage[_storageKey] = defaultContents;
      return defaultContents;
    }
    return stored;
  }

  @override
  Future<void> save(String contents) async {
    html.window.localStorage[_storageKey] = contents;
  }
}

SettingsPersistence buildPersistence() => WebSettingsPersistence();
