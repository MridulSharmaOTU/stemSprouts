// ===============================================================
// File: lib/pages/settings_page.dart
//
// - Minimal settings screen with two editable preferences that compile on day 1.
// - Local in-widget state only; later replaced by a repository/service layer.
// - Mirrors spacing/copy tokens used elsewhere for consistency.
//
// Notes
// - Keep this file small so multiple contributors can add items without conflicts.
// - Button triggers a snackbar for visible feedback during early demos.
// ===============================================================

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _dailyReminder = false; // demo default; wire to storage later
  int _grade = 3; // demo default; 1..12 typical range
  bool _saving = false;
  Map<String, dynamic> _userSettings = const {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<File> _getSettingsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/user-settings.json');
  }

  Future<Map<String, dynamic>> _loadDefaultSettings() async {
    try {
      final jsonString =
          await rootBundle.loadString('lib/data/user-settings.json');
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (err, stack) {
      debugPrint('Failed to load bundled user settings: $err');
      debugPrint('$stack');
      return const {};
    }
  }

  Future<void> _loadSettings() async {
    Map<String, dynamic>? data;
    try {
      final file = await _getSettingsFile();
      if (await file.exists()) {
        final contents = await file.readAsString();
        data = jsonDecode(contents) as Map<String, dynamic>;
      }
    } catch (err, stack) {
      debugPrint('Failed to load stored user settings: $err');
      debugPrint('$stack');
    }

    data ??= await _loadDefaultSettings();

    if (!mounted) {
      return;
    }

    final bool? notifications = data['notifications'] as bool?;
    final num? grade = data['grade'] as num?;

    setState(() {
      _userSettings = Map<String, dynamic>.from(data!);
      if (notifications != null) {
        _dailyReminder = notifications;
      }
      if (grade != null) {
        final int parsedGrade = grade.round().clamp(1, 12).toInt();
        _grade = parsedGrade;
      }
    });
  }

  Future<void> _saveSettings() async {
    setState(() {
      _saving = true;
    });

    try {
      final file = await _getSettingsFile();
      final nextSettings = Map<String, dynamic>.from(_userSettings)
        ..['notifications'] = _dailyReminder
        ..['grade'] = _grade;

      final payload = jsonEncode(nextSettings);
      await file.writeAsString(payload, flush: true);

      if (!mounted) {
        return;
      }

      setState(() {
        _userSettings = nextSettings;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_Copy.savedSnack} (${_dailyReminder ? _Copy.on : _Copy.off}, Grade $_grade)',
          ),
        ),
      );
    } catch (err, stack) {
      debugPrint('Failed to save user settings: $err');
      debugPrint('$stack');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $err')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(_Space.page),
        children: [
          Text(
            _Copy.title,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: _Space.lg),

          // Daily reminder toggle (local-only for now)
          SwitchListTile(
            title: const Text(_Copy.reminderLabel),
            subtitle: const Text(_Copy.reminderSub),
            value: _dailyReminder,
            onChanged: (v) => setState(() => _dailyReminder = v),
          ),

          const SizedBox(height: _Space.md),

          // Grade selector kept simple to avoid committing to a full picker yet.
          Row(
            children: [
              const Text(_Copy.gradeLabel),
              const SizedBox(width: _Space.md),
              DropdownButton<int>(
                value: _grade,
                items: List.generate(12, (i) => i + 1)
                    .map((g) => DropdownMenuItem(value: g, child: Text('Grade $g')))
                    .toList(),
                onChanged: (g) => setState(() => _grade = g ?? _grade),
              ),
            ],
          ),

          const SizedBox(height: _Space.xl),

          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: _saving ? null : _saveSettings,
              child: Text(_saving ? _Copy.savingBtn : _Copy.saveBtn),
            ),
          ),

          const SizedBox(height: _Space.lg),
          Text(
            _Copy.footerHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// --------------------------- Design tokens ---------------------------
class _Space {
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double page = 20;
}

// --------------------------- Copy strings ---------------------------
class _Copy {
  static const title = 'Settings';
  static const reminderLabel = 'Daily study reminder';
  static const reminderSub = 'Get a local notification once per day.';
  static const gradeLabel = 'Grade:';
  static const saveBtn = 'Save';
  static const savingBtn = 'Saving…';
  static const savedSnack = 'Settings saved';
  static const on = 'on';
  static const off = 'off';
  static const footerHint = 'Tip: Start a session in Tutor to update your streak.';
}