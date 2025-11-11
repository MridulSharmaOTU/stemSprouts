import 'settings_persistence_interface.dart';
import 'settings_persistence_stub.dart'
    if (dart.library.html) 'settings_persistence_web.dart'
    if (dart.library.io) 'settings_persistence_io.dart';

export 'settings_persistence_interface.dart';

SettingsPersistence createSettingsPersistence() => buildPersistence();
