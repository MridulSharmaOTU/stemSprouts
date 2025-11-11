import 'dart:io';

import 'package:flutter/foundation.dart';

import 'settings_persistence_interface.dart';

class FileSettingsPersistence implements SettingsPersistence {
  FileSettingsPersistence();

  File? _cachedFile;

  @override
  Future<String> load(String defaultContents) async {
    final file = await _ensureFile(defaultContents);
    try {
      return await file.readAsString();
    } on FileSystemException {
      await file.writeAsString(defaultContents);
      return defaultContents;
    }
  }

  @override
  Future<void> save(String contents) async {
    final file = await _ensureFile(contents);
    await file.writeAsString(contents);
  }

  Future<File> _ensureFile(String defaultContents) async {
    if (_cachedFile != null) {
      return _cachedFile!;
    }

    final candidates = <Directory>[
      Directory('${Directory.current.path}/lib/data'),
      Directory('${Directory.systemTemp.path}/stem_sprouts/settings'),
    ];

    Object? lastError;
    for (final directory in candidates) {
      try {
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        final file = File('${directory.path}/user-settings.json');
        if (!await file.exists()) {
          await file.writeAsString(defaultContents);
        }
        _cachedFile = file;
        return file;
      } catch (err, stack) {
        lastError = err;
        debugPrint('Settings storage path not writable (${directory.path}): $err');
        debugPrint('$stack');
      }
    }

    throw FileSystemException(
      'Unable to prepare settings file for persistence.',
      candidates.isNotEmpty ? candidates.last.path : '',
      lastError is OSError ? lastError as OSError : null,
    );
  }
}

SettingsPersistence buildPersistence() => FileSettingsPersistence();
