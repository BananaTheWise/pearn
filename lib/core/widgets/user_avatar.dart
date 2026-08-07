import 'package:flutter/material.dart';

/// Reusable user avatar widget.
///
/// Displays:
/// - Network profile image when [imageUrl] is available
/// - Initials when there is no image
/// - Optional online indicator
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double radius;
  final bool showOnline;
  final bool isOnline;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = 24,
    this.showOnline = false,
    this.isOnline = false,
    this.onTap, Object? avatarType,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: radius,
      backgroundImage: _hasImage
          ? NetworkImage(imageUrl!)
          : null,
      child: _hasImage
          ? null
          : Text(
              _getInitials(),
              style: TextStyle(
                fontSize: radius * 0.75,
                fontWeight: FontWeight.bold,
              ),
            ),
    );

    final avatarWithStatus = showOnline
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              avatar,
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: radius * 0.45,
                  height: radius * 0.45,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOnline ? Colors.green : Colors.grey,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          )
        : avatar;

    if (onTap == null) {
      return avatarWithStatus;
    }

    return GestureDetector(
      onTap: onTap,
      child: avatarWithStatus,
    );
  }

  bool get _hasImage {
    return imageUrl != null && imageUrl!.trim().isNotEmpty;
  }

  String _getInitials() {
    if (name == null || name!.trim().isEmpty) {
      return '?';
    }

    final parts = name!
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}