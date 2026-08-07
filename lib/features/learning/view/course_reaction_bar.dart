import 'package:flutter/material.dart';

/// Reusable widget that displays a set of course reaction buttons.
///
/// This widget is **only** for courses. It does not call any repository,
/// service, or backend. All state and actions are controlled via callbacks
/// from the presenter.
class CourseReactionBar extends StatelessWidget {
  /// The list of emojis available for reaction (e.g. ['👍', '❤️']).
  final List<String> reactionTypes;

  /// The emoji the current user has selected, or `null` if none.
  final String? userReaction;

  /// A map from emoji string to the number of reactions of that type.
  /// If not provided, counts are not displayed.
  final Map<String, int>? reactionCounts;

  /// Total number of reactions across all types (optional).
  final int? totalReactions;

  /// Called when the user taps a reaction emoji.
  /// The selected emoji string is passed as argument.
  final ValueChanged<String> onReactionSelected;

  const CourseReactionBar({
    super.key,
    required this.reactionTypes,
    required this.userReaction,
    this.reactionCounts,
    this.totalReactions,
    required this.onReactionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Total count label (optional)
            if (totalReactions != null) ...[
              Text(
                '$totalReactions',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
            ],
            // Reaction buttons
            ...reactionTypes.map((emoji) {
              final isSelected = userReaction == emoji;
              final count = reactionCounts?[emoji] ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onReactionSelected(emoji),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: isSelected
                        ? BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          )
                        : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 22)),
                        if (reactionCounts != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '$count',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}