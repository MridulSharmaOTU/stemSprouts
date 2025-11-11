import 'dart:async';

import 'settings_persistence_interface.dart';

SettingsPersistence buildPersistence() => const _UnsupportedPersistence();

class _UnsupportedPersistence implements SettingsPersistence {
  const _UnsupportedPersistence();

  @override
  Future<String> load(String defaultContents) => Future<String>.error(
        const UnsupportedError(
          'Persistent storage is not available on this platform.',
        ),
      );

  @override
  Future<void> save(String contents) => Future<void>.error(
        const UnsupportedError(
          'Persistent storage is not available on this platform.',
        ),
      );
}
