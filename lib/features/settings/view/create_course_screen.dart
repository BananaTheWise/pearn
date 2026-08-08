import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Suggested location: lib/features/settings/view/create_course_screen.dart
///
/// Requires the `url_launcher` package. Add to pubspec.yaml:
///   dependencies:
///     url_launcher: ^6.3.0
/// then run `flutter pub get`.
///
/// TODO: replace `_kAdminEmail` with your real inbox before shipping.
///
/// Android note: launching a `mailto:` link requires a `<queries>` entry in
/// AndroidManifest.xml on Android 11+, or `canLaunchUrl`/`launchUrl` may
/// report no app can handle it even when one is installed:
///   <queries>
///     <intent>
///       <action android:name="android.intent.action.SENDTO" />
///       <data android:scheme="mailto" />
///     </intent>
///   </queries>
class CreateCourseScreen extends StatelessWidget {
  const CreateCourseScreen({super.key});

  static const String _kAdminEmail = 'admin@pearn.app';
  static const String _kCoursesRepoUrl =
      'https://github.com/BananaTheWise/pearn_courses';

  Future<void> _openRepo(BuildContext context) async {
    final uri = Uri.parse(_kCoursesRepoUrl);
    bool launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the repository link.')),
      );
    }
  }

  Future<void> _emailAdmin(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _kAdminEmail,
      query: _encodeQueryParams({
        'subject': 'New course submission for Pearn',
        'body': 'Hi Pearn team,\n\n'
            'I\'ve created a branch in pearn_courses for a new course.\n\n'
            'Branch name: \n'
            'Course title: \n'
            'Short description: \n\n'
            'Thanks!',
      }),
    );

    bool launched = false;
    try {
      launched = await launchUrl(uri);
    } catch (_) {
      launched = false;
    }
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No email app found. You can copy the admin address instead.',
          ),
        ),
      );
    }
  }

  Future<void> _copyEmail(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: _kAdminEmail));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin email copied to clipboard.')),
      );
    }
  }

  static String _encodeQueryParams(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Create a Course')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Courses on Pearn are always free — for learners and for tutors. '
            'Publishing one is a two-step process:',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          _Step(
            number: 1,
            title: 'Create a branch',
            body:
                'Fork or create a new branch in the pearn_courses repository '
                'and add your course folder following the existing '
                'structure (see the other course folders for the expected '
                'layout).',
            action: OutlinedButton.icon(
              onPressed: () => _openRepo(context),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open pearn_courses on GitHub'),
            ),
          ),
          _Step(
            number: 2,
            title: 'Email the admin for review',
            body: 'Once your branch is ready, email the admin with your '
                'branch name and a short description. We\'ll review it and '
                'merge it in so it appears in the app.',
            action: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => _emailAdmin(context),
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('Email Admin'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _copyEmail(context),
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Copy Address'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Repository: $_kCoursesRepoUrl',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Admin contact: $_kAdminEmail',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final String title;
  final String body;
  final Widget action;

  const _Step({
    required this.number,
    required this.title,
    required this.body,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(body, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 14),
            action,
          ],
        ),
      ),
    );
  }
}