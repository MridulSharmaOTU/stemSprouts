// ===============================================================
// File: lib/main.dart
//
// - Single entry point that wires up a four-tab scaffold: Home, Tutor, Progress, Settings.
// - Keeps navigation local and simple for day-1 demos and grading.
// - Uses Material 3 theme for a modern look with minimal config.
//
// Notes
// - RootScaffold is stateful only for the current tab index.
// - Pages are imported as lightweight widgets and remain decoupled from routing.
// - HomePage receives an onStartTutor callback so the primary CTA can switch tabs.
// ===============================================================

import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/tutor_chat_page.dart';
import 'pages/progress_page.dart';
import 'pages/settings_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'STEM Sprouts',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const RootScaffold(),
    );
  }
}

class RootScaffold extends StatefulWidget {
  const RootScaffold({super.key});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  int _index = 0; // 0: Home, 1: Tutor, 2: Progress, 3: Settings

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      // Home gets a callback so its CTA can move to the Tutor tab without
      // importing routing concerns into the page itself.
      HomePage(onStartTutor: () => setState(() => _index = 1)),
      const TutorChatPage(),
      const ProgressPage(),
      const SettingsPage(),
    ];

    final titles = <String>['Home', 'Tutor', 'Progress', 'Settings'];

    return Scaffold(
      appBar: AppBar(title: Text(titles[_index])),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Tutor',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}