/// Records when the user unlocked a specific badge.
/// Stored in the user_badges table.
class UserBadge {
  final int? id;
  final int badgeId;
  final DateTime unlockedAt;

  const UserBadge({
    this.id,
    required this.badgeId,
    required this.unlockedAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'badge_id': badgeId,
        'unlocked_at': unlockedAt.toIso8601String(),
      };

  factory UserBadge.fromMap(Map<String, dynamic> map) => UserBadge(
        id: map['id'] as int,
        badgeId: map['badge_id'] as int,
        unlockedAt: DateTime.parse(map['unlocked_at'] as String),
      );
}
