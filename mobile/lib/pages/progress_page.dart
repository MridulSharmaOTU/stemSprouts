// ===============================================================
// File: lib/pages/progress_page.dart
//
// - Bare-bones progress screen that compiles and is safe to iterate on.
// - Keeps state out of the page for now; real data will come from a repository
//   or API in a later milestone per the proposal.
// - Mirrors visual elements from Home (cards, spacing) for consistency.
//
// Notes
// - Stateless first: easier parallel work (UI vs. data plumbing).
// - Copy strings collected in one place for quick edits and future i18n.
// - Simple placeholders (chart box) so QA can verify layout without packages.
// ===============================================================

import 'package:flutter/material.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder values until storage/API is wired.
    const sessionsCompleted = 0;
    const masteredTopics = 0;
    const currentStreak = 0;

    return SafeArea(
      child: Container(
        color: const Color.fromARGB(235, 129, 190, 255),
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

          // Overview card: quick stats that are easy to demo.
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(_Space.card),
              child: Column(
                children: [
                  _StatTile(
                    icon: Icons.check_circle_outline,
                    title: _Copy.sessions,
                    trailing: '$sessionsCompleted',
                  ),
                  const Divider(),
                  _StatTile(
                    icon: Icons.school_outlined,
                    title: _Copy.mastered,
                    trailing: '$masteredTopics',
                  ),
                  const Divider(),
                  _StatTile(
                    icon: Icons.local_fire_department_outlined,
                    title: _Copy.streak,
                    trailing: '$currentStreak',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: _Space.lg),

          // Minimal chart placeholder: replace with a real chart later.
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.3),
              ),
            ),
            child: SizedBox(
              height: 140,
              child: Center(
                child: Text(
                  _Copy.chartPlaceholder,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ),

          const SizedBox(height: _Space.md),
          Text(
            _Copy.footerHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon; 
  final String title; 
  final String trailing;
  const _StatTile({required this.icon, required this.title, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      trailing: Text(trailing, style: Theme.of(context).textTheme.titleMedium),
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
  static const double card = 16;
}

// --------------------------- Copy strings ---------------------------
class _Copy {
  static const title = 'Your progress';
  static const sessions = 'Sessions completed';
  static const mastered = 'Mastered topics';
  static const streak = 'Current streak (days)';
  static const chartPlaceholder = 'Accuracy (last 7 days) — chart placeholder';
  static const footerHint = 'Tip: Open Tutor and complete one problem daily to build a streak.';
}