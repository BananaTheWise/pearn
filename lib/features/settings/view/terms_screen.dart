import 'package:flutter/material.dart';

/// Suggested location: lib/features/settings/view/terms_screen.dart
///
/// Static Terms & Conditions page.
///
/// NOTE: This is a starting draft written for Pearn's specific model (free
/// courses, community-contributed content via GitHub, optional donations).
/// It is NOT legal advice — have an actual lawyer review this before you
/// rely on it, especially the liability, content-ownership, and governing
/// law sections, which need your jurisdiction filled in.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Last updated: [DATE]',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          const _Clause(
            number: '1',
            title: 'Acceptance of Terms',
            body: 'By creating an account or using Pearn, you agree to these '
                'Terms & Conditions. If you don\'t agree, please don\'t use '
                'the app.',
          ),
          const _Clause(
            number: '2',
            title: 'Free Access',
            body: 'All courses on Pearn are provided free of charge. Pearn '
                'does not charge learners to access course content, and does '
                'not charge tutors to publish it. We do not sell courses, '
                'take commissions, or gate content behind payment.',
          ),
          const _Clause(
            number: '3',
            title: 'Accounts',
            body: 'You\'re responsible for the accuracy of the information you '
                'provide and for keeping your account credentials secure. You '
                'must be old enough to use this app under the laws that apply '
                'to you.',
          ),
          const _Clause(
            number: '4',
            title: 'Course Content & Contributions',
            body: 'Tutors submit courses by contributing to the public '
                'pearn_courses repository and are reviewed by an administrator '
                'before publication. By submitting a course, you confirm you '
                'own or have the right to share that content, and you grant '
                'Pearn a non-exclusive license to host and display it within '
                'the app. You retain ownership of your own content.',
          ),
          const _Clause(
            number: '5',
            title: 'Acceptable Use',
            body: 'You agree not to use Pearn to upload unlawful, harmful, or '
                'infringing content, to harass other users, or to attempt to '
                'disrupt or gain unauthorized access to the service.',
          ),
          const _Clause(
            number: '6',
            title: 'Donations',
            body: 'Pearn may accept optional donations to help cover server '
                'and maintenance costs. Donations are voluntary, non-'
                'refundable unless required by law, and do not unlock any '
                'paid features — because there aren\'t any.',
          ),
          const _Clause(
            number: '7',
            title: 'Third-Party Links',
            body: 'Course pages may link to a tutor\'s external profile, site, '
                'or repository. Pearn isn\'t responsible for the content or '
                'practices of those external destinations.',
          ),
          const _Clause(
            number: '8',
            title: '"As Is" — No Warranty',
            body: 'Pearn is provided "as is," without warranties of any kind. '
                'We don\'t guarantee the app or its content will be error-'
                'free, uninterrupted, or fit for any particular purpose.',
          ),
          const _Clause(
            number: '9',
            title: 'Limitation of Liability',
            body: 'To the fullest extent permitted by law, Pearn and its '
                'maintainers aren\'t liable for indirect, incidental, or '
                'consequential damages arising from your use of the app.',
          ),
          const _Clause(
            number: '10',
            title: 'Changes to These Terms',
            body: 'We may update these terms from time to time. Continued use '
                'of Pearn after changes take effect means you accept the '
                'updated terms.',
          ),
          const _Clause(
            number: '11',
            title: 'Governing Law',
            body: 'These terms are governed by the laws of [YOUR JURISDICTION], '
                'without regard to its conflict-of-law provisions.',
          ),
          const _Clause(
            number: '12',
            title: 'Contact',
            body: 'Questions about these terms? Reach out to [ADMIN EMAIL].',
          ),
        ],
      ),
    );
  }
}

class _Clause extends StatelessWidget {
  final String number;
  final String title;
  final String body;

  const _Clause({
    required this.number,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. $title',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(body, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}