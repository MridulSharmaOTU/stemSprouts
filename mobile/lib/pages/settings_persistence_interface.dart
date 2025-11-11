import 'dart:async';

abstract class SettingsPersistence {
  Future<String> load(String defaultContents);
  Future<void> save(String contents);
}
