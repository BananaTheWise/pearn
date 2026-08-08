import 'package:flutter/material.dart';

/// Suggested location: lib/features/settings/view/about_screen.dart
///
/// Static "About" page — no presenter needed, there's nothing dynamic to
/// load here, just content.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('About Pearn')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Icon(Icons.school_rounded, size: 56, color: colorScheme.primary),
                const SizedBox(height: 12),
                Text(
                  'Pearn',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const _Section(
            title: 'Our Mission',
            body: 'Pearn is a free learning platform. Every course on Pearn is '
                'free for learners to take — no subscriptions, no paywalls, '
                'no hidden fees, ever.',
          ),
          const _Section(
            title: 'Free for Tutors, Too',
            body: 'Anyone who wants to teach on Pearn can create and publish a '
                'course at no cost. We don\'t charge tutors to publish, and we '
                'don\'t take a cut of anything — courses on Pearn are never '
                'sold in the first place.',
          ),
          const _Section(
            title: 'How We Cover Costs',
            body: 'Running servers and keeping the app maintained costs money. '
                'Any funds Pearn receives — through optional donations — go '
                'directly toward hosting, infrastructure, and upkeep. Pearn is '
                'not a commercial product and isn\'t designed to generate '
                'profit.',
          ),
          const _Section(
            title: 'Meet the Tutors',
            body: 'Course pages link out to each tutor\'s own page or profile. '
                'If a course helps you, you\'re welcome to find and support the '
                'person who made it directly — that support goes to them, not '
                'to Pearn.',
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(body, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}