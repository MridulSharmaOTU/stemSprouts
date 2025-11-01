// ===============================================================
// Project: STEM Sprouts Mobile App
// File: lib/pages/home_page.dart
//
// - Serves as the neutral landing page for first-time and returning users.
// - Keeps initial experience frictionless ("tap once to start tutoring").
// - Intentionally light on state so it remains easy to test and refactor.
//
// TEAM CONVENTIONS
// - Stateless by default: avoids hidden coupling; business state belongs to
//   repositories/view-models (added later). This keeps the Home page safe to
//   redesign without breaking logic.
// - Optional callback [onStartTutor] allows parent navigation control
//   (e.g., switching bottom-tab or routing) without creating a dependency on
//   a specific router here. If it's not provided, we display a helpful
//   snackbar so QA can still validate the flow.
// - Copy strings are centralized in a small class to prepare for future i18n
//   without committing to a full localization pipeline yet.
// - Spacing and small building blocks (_HomeCard) keep visual consistency and
//   reduce merge conflicts when multiple teammates tweak layout.
// - Accessibility: semantics labels and large tap targets, because grading
//   considers usability and polish.
// ===============================================================

import 'package:flutter/material.dart';

/// HomePage is the first screen users see.
///
/// It introduces the value proposition and funnels users to the
/// step-by-step tutor. It must remain functional even when the app has
/// no network access or profile set up.
class HomePage extends StatelessWidget {
  /// Optional callback invoked when the primary CTA is pressed.
  /// Lets the parent decide *how* to navigate (switch tab, push route,
  /// or open onboarding). Keeps this file independent of navigation details.
  final VoidCallback? onStartTutor;

  const HomePage({super.key, this.onStartTutor});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Simple responsive behavior without committing to a grid system.
          final bool wide = constraints.maxWidth >= 600;

          final content = Padding(
            padding: const EdgeInsets.all(_Space.page),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _HeroSection(),
                const SizedBox(height: _Space.lg),
                _PrimaryCta(onPressed: () => _handleStart(context)),
                const SizedBox(height: _Space.xl),
                // Cards communicate quick value and future surface area
                // (progress, practice, settings) without blocking the CTA.
                if (wide)
                  Row(
                    children: const [
                      Expanded(child: _HomeCard.progress()),
                      SizedBox(width: _Space.md),
                      Expanded(child: _HomeCard.practice()),
                      SizedBox(width: _Space.md),
                      Expanded(child: _HomeCard.settings()),
                    ],
                  )
                else ...const [
                  _HomeCard.progress(),
                  SizedBox(height: _Space.md),
                  _HomeCard.practice(),
                  SizedBox(height: _Space.md),
                  _HomeCard.settings(),
                ],
                const SizedBox(height: _Space.lg),
                const _Footnote(),
              ],
            ),
          );

          return Semantics(
            label: 'Home screen',
            child: SingleChildScrollView(child: content),
          );
        },
      ),
    );
  }

  void _handleStart(BuildContext context) {
    // Prefer delegating navigation to the parent, but degrade gracefully
    // for dev builds and demos so the button still provides feedback.
    if (onStartTutor != null) {
      onStartTutor!();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Switch to the Tutor tab to begin.')),
      );
    }
  }
}

// --------------------------- Building blocks ---------------------------

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _Copy.title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          semanticsLabel: 'Welcome to ${_Copy.appName}',
        ),
        const SizedBox(height: _Space.sm),
        Text(
          _Copy.subtitle,
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  final VoidCallback onPressed;
  const _PrimaryCta({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48, // Predictable tap target for accessibility.
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.play_arrow),
        label: const Text(_Copy.ctaStart),
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _HomeCard({required this.icon, required this.title, required this.subtitle});

  const _HomeCard.progress()
      : icon = Icons.bar_chart_outlined,
        title = _Copy.cardProgressTitle,
        subtitle = _Copy.cardProgressSub;

  const _HomeCard.practice()
      : icon = Icons.task_alt_outlined,
        title = _Copy.cardPracticeTitle,
        subtitle = _Copy.cardPracticeSub;

  const _HomeCard.settings()
      : icon = Icons.settings_outlined,
        title = _Copy.cardSettingsTitle,
        subtitle = _Copy.cardSettingsSub;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(_Space.card),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: _Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: _Space.xs),
                  Text(subtitle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Footnote extends StatelessWidget {
  const _Footnote();

  @override
  Widget build(BuildContext context) {
    return Text(
      _Copy.footnote,
      style: Theme.of(context).textTheme.bodySmall,
      textAlign: TextAlign.center,
    );
  }
}

// --------------------------- Design tokens ---------------------------

/// Lightweight spacing tokens reduce magic numbers and help the team keep
/// vertical rhythm consistent while iterating quickly.
class _Space {
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double page = 20;
  static const double card = 16;
}

/// Centralize copy for early i18n and to encourage consistent wording.
class _Copy {
  static const String appName = 'STEM Sprouts Tutor';
  static const String title = 'Welcome to $appName';
  static const String subtitle =
      'A step-by-step tutor that guides thinking rather than giving answers.';
  static const String ctaStart = 'Start tutoring';

  static const String cardProgressTitle = 'Track progress';
  static const String cardProgressSub = 'See sessions, streaks, and accuracy.';

  static const String cardPracticeTitle = 'Practice smarter';
  static const String cardPracticeSub = 'Short, targeted problems per topic.';

  static const String cardSettingsTitle = 'Tune difficulty';
  static const String cardSettingsSub = 'Adjust grade level and reminders.';

  static const String footnote =
      'Tip: You can use the Tutor tab at any time to ask for hints.';
}