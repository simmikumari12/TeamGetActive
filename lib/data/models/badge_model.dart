/// A badge definition seeded into the badges table at first launch.
/// BadgeModel is read-only — records are never edited by the user.
class BadgeModel {
  final int? id;
  final String code; // Unique identifier used in unlock logic
  final String title;
  final String description;
  final String unlockCondition; // Human-readable unlock rule shown in UI
  final String iconName;

  const BadgeModel({
    this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.unlockCondition,
    this.iconName = 'emoji_events',
  });

  factory BadgeModel.fromMap(Map<String, dynamic> map) => BadgeModel(
        id: map['id'] as int,
        code: map['code'] as String,
        title: map['title'] as String,
        description: map['description'] as String,
        unlockCondition: map['unlock_condition'] as String,
        iconName: map['icon_name'] as String? ?? 'emoji_events',
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'code': code,
        'title': title,
        'description': description,
        'unlock_condition': unlockCondition,
        'icon_name': iconName,
      };
}
