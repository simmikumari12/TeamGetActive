/// A motivational challenge the user can complete for bonus points.
/// Stored in the challenges table.
class Challenge {
  final int? id;
  final String title;
  final String description;
  final String challengeType; // 'streak' | 'completion_count' | 'perfect_week'
  final int targetValue;
  final int rewardPoints;
  final bool isActive;
  final DateTime createdAt;

  const Challenge({
    this.id,
    required this.title,
    required this.description,
    this.challengeType = 'streak',
    required this.targetValue,
    this.rewardPoints = 100,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'description': description,
        'challenge_type': challengeType,
        'target_value': targetValue,
        'reward_points': rewardPoints,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory Challenge.fromMap(Map<String, dynamic> map) => Challenge(
        id: map['id'] as int,
        title: map['title'] as String,
        description: map['description'] as String,
        challengeType: map['challenge_type'] as String? ?? 'streak',
        targetValue: map['target_value'] as int,
        rewardPoints: map['reward_points'] as int? ?? 100,
        isActive: (map['is_active'] as int? ?? 1) == 1,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
