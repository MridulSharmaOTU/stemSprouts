import 'user_settings_store_io.dart'
    if (dart.library.html) 'user_settings_store_web.dart' as _store_impl;

class UserSettingsStore {
  const UserSettingsStore();

  Future<Map<String, dynamic>> load() {
    return _store_impl.loadUserSettings();
  }

  Future<bool> save(Map<String, dynamic> data) {
    return _store_impl.saveUserSettings(data);
  }
}
