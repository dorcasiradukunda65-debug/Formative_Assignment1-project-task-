import 'package:flutter/material.dart';
import '../models/team_member.dart';

/// Reusable avatar widget for team members displaying initials and dynamic color.
class MemberAvatar extends StatelessWidget {
  final TeamMember? member;
  final double radius;
  final bool showTooltip;

  const MemberAvatar({
    super.key,
    required this.member,
    this.radius = 18,
    this.showTooltip = true,
  });

  Color _resolveColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) {
      return const Color(0xFF6366F1);
    }
    try {
      final cleanHex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$cleanHex', radix: 16));
    } catch (_) {
      return const Color(0xFF6366F1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveMember = member;
    final initials = effectiveMember?.initials ?? '?';
    final backgroundColor = _resolveColor(effectiveMember?.avatarColorHex);

    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.75,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    if (showTooltip && effectiveMember != null) {
      return Tooltip(
        message: '${effectiveMember.name} • ${effectiveMember.role}',
        child: avatar,
      );
    }

    return avatar;
  }
}
