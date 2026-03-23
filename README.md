# Habit Mastery League

A gamified habit tracker built with Flutter and SQLite. Track daily habits, earn XP, level up, unlock badges, and reflect weekly — all stored locally with no cloud dependency.

**Target audience:** Anyone who wants to build consistent habits through game-like motivation, without relying on an internet connection or cloud service.

---

## Team Members

| Name | Role |
|---|---|
| Quang Tran | UI / Full Stack, Infrastructure|
| Tu Nguyen | UI / Backend  |

---

## Features

| Tab | Description |
|---|---|
| **Home** | Check off today's habits, view XP progress card |
| **Habits** | Create, edit, and archive habits with difficulty and category |
| **Progress** | Per-habit streak counts and 28-day completion heatmap |
| **Insights** | AI buddy message (rule-based, 4 personalities) + weekly reflection form |
| **Rewards** | Badge collection grid and active challenges |

**Settings** — live theme switching (light/dark/system), display name, buddy personality.

**Gamification:**
- XP per completion = `basePoints (10) × difficultyMultiplier × streakBonus`
- Difficulty multipliers — easy: 1×, medium: 1.5×, hard: 2×
- Streak bonus — 2× when streak ≥ 7 days
- Level up every 500 XP
- 10 badges unlocked automatically based on milestones

---

## Technologies Used

| Technology | Version / Details |
|---|---|
| Flutter | 3.41 |
| Dart | 3.11 |
| `sqflite` | Local SQLite database |
| `shared_preferences` | User settings and buddy message cache |
| `provider` | `ThemeNotifier` for live theme switching |
| `intl` | Date formatting |

---

## Installation Instructions

**Requirements:** Flutter 3.32+ (uses `RadioGroup` and `withValues` APIs)

```bash
# 1. Clone the repo
git clone https://github.com/kaiser1x/TeamGetActive.git
cd TeamGetActive/team_get_active

# 2. Install dependencies
flutter pub get

# 3. Run on a connected device or emulator
flutter run

# 4. (Optional) Run the smoke test
flutter test
```

> Make sure you have a device connected or an emulator running before `flutter run`.

---

## Usage Guide

1. **Onboarding** — On first launch, enter your name and choose a buddy personality across 3 intro screens.
2. **Home tab** — Tap the checkbox next to each habit to log it for today. Your XP bar and level update instantly.
3. **Habits tab** — Tap **+** to create a new habit. Set a title, category, difficulty, and frequency. Long-press a habit to edit or archive it.
4. **Progress tab** — View your current streak per habit and a 28-day heatmap showing completion history.
5. **Insights tab** — Read your AI buddy's daily message and fill in the weekly reflection form (wins, obstacles, next focus).
6. **Rewards tab** — Browse earned badges and view active challenges with progress indicators.
7. **Settings** — Change your display name, buddy personality, and switch between light, dark, or system theme.

> Screenshots: _(add screenshots to an `assets/screenshots/` folder and link them here)_

---

## Database Schema

All data is stored locally in a SQLite database managed by `sqflite`.

### `habits`
| Column | Type | Description |
|---|---|---|
| `id` | INTEGER PK | Auto-incremented ID |
| `title` | TEXT | Habit name |
| `description` | TEXT | Optional description |
| `category` | TEXT | e.g. Health, Learning, Other |
| `difficulty` | TEXT | `easy`, `medium`, or `hard` |
| `frequency_type` | TEXT | e.g. `daily` |
| `target_count` | INTEGER | Times to complete per period |
| `color_index` | INTEGER | UI colour index |
| `icon_name` | TEXT | Material icon name |
| `created_at` | TEXT | ISO 8601 timestamp |
| `updated_at` | TEXT | ISO 8601 timestamp |
| `is_archived` | INTEGER | `0` = active, `1` = archived |

### `habit_logs`
| Column | Type | Description |
|---|---|---|
| `id` | INTEGER PK | Auto-incremented ID |
| `habit_id` | INTEGER FK | References `habits.id` (cascade delete) |
| `completed_date` | TEXT | ISO 8601 date |
| `completion_value` | INTEGER | Units completed |
| `notes` | TEXT | Optional note |
| `mood_tag` | TEXT | Optional mood label |
| `points_earned` | INTEGER | XP awarded for this log |

### `weekly_reflections`
| Column | Type | Description |
|---|---|---|
| `id` | INTEGER PK | Auto-incremented ID |
| `week_start` | TEXT | UNIQUE — ISO 8601 date of Monday |
| `reflection_text` | TEXT | General reflection |
| `wins_text` | TEXT | Wins this week |
| `obstacles_text` | TEXT | Obstacles faced |
| `next_focus_text` | TEXT | Focus for next week |
| `created_at` | TEXT | ISO 8601 timestamp |

### `badges`
| Column | Type | Description |
|---|---|---|
| `id` | INTEGER PK | Auto-incremented ID |
| `code` | TEXT UNIQUE | Internal identifier |
| `title` | TEXT | Display name |
| `description` | TEXT | Badge description |
| `unlock_condition` | TEXT | Human-readable condition |
| `icon_name` | TEXT | Material icon name |

### `user_badges`
| Column | Type | Description |
|---|---|---|
| `id` | INTEGER PK | Auto-incremented ID |
| `badge_id` | INTEGER FK | References `badges.id` |
| `unlocked_at` | TEXT | ISO 8601 timestamp |

### `challenges`
| Column | Type | Description |
|---|---|---|
| `id` | INTEGER PK | Auto-incremented ID |
| `title` | TEXT | Challenge name |
| `description` | TEXT | Challenge description |
| `challenge_type` | TEXT | e.g. `streak` |
| `target_value` | INTEGER | Goal to reach |
| `reward_points` | INTEGER | XP awarded on completion |
| `is_active` | INTEGER | `0` = inactive, `1` = active |
| `created_at` | TEXT | ISO 8601 timestamp |

---

## Known Issues

- No cloud sync — data is device-local only; uninstalling the app deletes all data.
- The AI buddy messages are rule-based, not AI-generated — responses follow fixed templates per personality.
- No export/backup feature for habit data.
- Weekly reflection is one entry per week; editing a past week's reflection is not currently supported.

---

## Future Enhancements

- Cloud backup and cross-device sync
- Notification reminders for daily habits
- Social/friend leaderboard to compete on XP
- Custom badge creation
- Data export to CSV
- Widget support for home screen quick-check

---

## License

This project is licensed under the MIT License.

```
MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
```
