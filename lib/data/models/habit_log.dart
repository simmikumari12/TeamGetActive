/// Records a single completion of a habit on a given date.
/// Stored in the habit_logs table.
class HabitLog {
  final int? id;
  final int habitId;
  final DateTime completedDate;
  final int completionValue; // 1 for boolean habits; rep count for counted habits
  final String? notes;
  final String? moodTag; // 'great' | 'okay' | 'tough'
  final int pointsEarned;

  const HabitLog({
    this.id,
    required this.habitId,
    required this.completedDate,
    this.completionValue = 1,
    this.notes,
    this.moodTag,
    this.pointsEarned = 0,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'habit_id': habitId,
        // Store only the date portion (YYYY-MM-DD) for easy day-level queries
        'completed_date': completedDate.toIso8601String().substring(0, 10),
        'completion_value': completionValue,
        'notes': notes,
        'mood_tag': moodTag,
        'points_earned': pointsEarned,
      };

  factory HabitLog.fromMap(Map<String, dynamic> map) => HabitLog(
        id: map['id'] as int,
        habitId: map['habit_id'] as int,
        completedDate: DateTime.parse(map['completed_date'] as String),
        completionValue: map['completion_value'] as int? ?? 1,
        notes: map['notes'] as String?,
        moodTag: map['mood_tag'] as String?,
        pointsEarned: map['points_earned'] as int? ?? 0,
      );
}
