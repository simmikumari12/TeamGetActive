/// A user's written weekly reflection saved to the weekly_reflections table.
/// One record per calendar week (keyed on the Monday date).
class WeeklyReflection {
  final int? id;
  final DateTime weekStart; // Monday of the reflection week
  final String? reflectionText;
  final String? winsText;
  final String? obstaclesText;
  final String? nextFocusText;
  final DateTime createdAt;

  const WeeklyReflection({
    this.id,
    required this.weekStart,
    this.reflectionText,
    this.winsText,
    this.obstaclesText,
    this.nextFocusText,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'week_start': weekStart.toIso8601String().substring(0, 10),
        'reflection_text': reflectionText,
        'wins_text': winsText,
        'obstacles_text': obstaclesText,
        'next_focus_text': nextFocusText,
        'created_at': createdAt.toIso8601String(),
      };

  factory WeeklyReflection.fromMap(Map<String, dynamic> map) => WeeklyReflection(
        id: map['id'] as int,
        weekStart: DateTime.parse(map['week_start'] as String),
        reflectionText: map['reflection_text'] as String?,
        winsText: map['wins_text'] as String?,
        obstaclesText: map['obstacles_text'] as String?,
        nextFocusText: map['next_focus_text'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
