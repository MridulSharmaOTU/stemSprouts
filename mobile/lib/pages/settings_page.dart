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
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _dailyReminder = false; // demo default; wire to storage later
  int _grade = 3; // demo default; 1..12 typical range

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final jsonString =
      await rootBundle.loadString('lib/data/user-settings.json');
      final Map<String, dynamic> data =
      jsonDecode(jsonString) as Map<String, dynamic>;

      final bool? notifications = data['notifications'] as bool?;
      final num? grade = data['grade'] as num?;

      if (!mounted) {
        return;
      }

      setState(() {
        if (notifications != null) {
          _dailyReminder = notifications;
        }
        if (grade != null) {
          final int parsedGrade = grade.round().clamp(1, 12).toInt();
          _grade = parsedGrade;
        }
      });
    } catch (err, stack) {
      debugPrint('Failed to load user settings: $err');
      debugPrint('$stack');
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
              onPressed: () {
                // Replace with persistence call later.
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${_Copy.savedSnack} (${_dailyReminder ? _Copy.on : _Copy.off}, Grade $_grade)',
                    ),
                  ),
                );
              },
              child: const Text(_Copy.saveBtn),
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
  static const savedSnack = 'Settings saved';
  static const on = 'on';
  static const off = 'off';
  static const footerHint = 'Tip: Start a session in Tutor to update your streak.';
}