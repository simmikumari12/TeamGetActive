/// Represents a user-created habit mission stored in the habits table.
class Habit {
  final int? id;
  final String title;
  final String? description;
  final String category;
  final String difficulty; // 'easy' | 'medium' | 'hard'
  final String frequencyType; // 'daily' | 'weekly'
  final int targetCount;
  final int colorIndex; // Index into AppColors.categoryColors
  final String iconName; // Material icon name string
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isArchived;

  const Habit({
    this.id,
    required this.title,
    this.description,
    this.category = 'Other',
    this.difficulty = 'medium',
    this.frequencyType = 'daily',
    this.targetCount = 1,
    this.colorIndex = 0,
    this.iconName = 'star',
    required this.createdAt,
    required this.updatedAt,
    this.isArchived = false,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'description': description,
        'category': category,
        'difficulty': difficulty,
        'frequency_type': frequencyType,
        'target_count': targetCount,
        'color_index': colorIndex,
        'icon_name': iconName,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'is_archived': isArchived ? 1 : 0,
      };

  factory Habit.fromMap(Map<String, dynamic> map) => Habit(
        id: map['id'] as int,
        title: map['title'] as String,
        description: map['description'] as String?,
        category: map['category'] as String? ?? 'Other',
        difficulty: map['difficulty'] as String? ?? 'medium',
        frequencyType: map['frequency_type'] as String? ?? 'daily',
        targetCount: map['target_count'] as int? ?? 1,
        colorIndex: map['color_index'] as int? ?? 0,
        iconName: map['icon_name'] as String? ?? 'star',
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
        isArchived: (map['is_archived'] as int? ?? 0) == 1,
      );

  Habit copyWith({
    int? id,
    String? title,
    String? description,
    String? category,
    String? difficulty,
    String? frequencyType,
    int? targetCount,
    int? colorIndex,
    String? iconName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArchived,
  }) =>
      Habit(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        category: category ?? this.category,
        difficulty: difficulty ?? this.difficulty,
        frequencyType: frequencyType ?? this.frequencyType,
        targetCount: targetCount ?? this.targetCount,
        colorIndex: colorIndex ?? this.colorIndex,
        iconName: iconName ?? this.iconName,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isArchived: isArchived ?? this.isArchived,
      );
}
