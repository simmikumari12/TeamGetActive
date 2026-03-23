import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../../data/models/habit.dart';
import '../../data/repositories/habit_repository.dart';
import '../../data/repositories/log_repository.dart';
import '../constants/app_constants.dart';
import '../services/prefs_service.dart';
import '../utils/streak_utils.dart';

/// Context passed into every real-time chat response.
class BuddyChatContext {
  final String userName;
  final String personality;
  final int todayDone;
  final int todayTotal;
  final int bestStreak;
  final double weeklyRate;
  final List<String> incompleteToday;

  const BuddyChatContext({
    required this.userName,
    required this.personality,
    required this.todayDone,
    required this.todayTotal,
    required this.bestStreak,
    required this.weeklyRate,
    required this.incompleteToday,
  });
}

/// Rule-based buddy message + micro-goal generator.
/// No external API calls. Generates once per day and caches in SharedPreferences.
class BuddyService {
  BuddyService._();
  static final BuddyService instance = BuddyService._();

  /// Returns today's (pep message, micro-goal). Uses cache if already generated today.
  Future<(String, String)> getMessages() async {
    if (PrefsService.instance.isBuddyMessageFresh) {
      return (
        PrefsService.instance.lastBuddyMessage ?? _fallback(),
        PrefsService.instance.lastMicroGoal ?? _fallbackGoal(),
      );
    }
    final result = await _generate();
    await PrefsService.instance.cacheMessages(result.$1, result.$2);
    return result;
  }

  /// Convenience method — returns just the pep message.
  Future<String> getMessage() async => (await getMessages()).$1;

  /// Convenience method — returns just the micro-goal.
  Future<String> getMicroGoal() async => (await getMessages()).$2;

  Future<(String, String)> _generate() async {
    final name = PrefsService.instance.userName;
    final personality = PrefsService.instance.buddyPersonality;
    final habits = await HabitRepository.instance.getAll();

    if (habits.isEmpty) {
      return (_welcomeMessage(name, personality), _welcomeGoal(personality));
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final from = now.subtract(const Duration(days: 30));

    // Collect stats for message
    int maxStreak = 0;
    double totalRate = 0;
    for (final h in habits) {
      final logs = await LogRepository.instance.getLogsInRange(h.id!, from, now);
      final s = StreakUtils.computeStreak(logs);
      if (s > maxStreak) maxStreak = s;
      totalRate += StreakUtils.completionRate(logs, 7);
    }
    final avgRate = totalRate / habits.length;

    // Collect incomplete habits for micro-goal
    final completedToday =
        await LogRepository.instance.getCompletedHabitIdsForDate(today);
    final incomplete =
        habits.where((h) => !completedToday.contains(h.id)).toList();

    final message =
        _buildMessage(name, personality, maxStreak, avgRate, habits.length);
    final microGoal = _buildMicroGoal(name, personality, incomplete, maxStreak);

    return (message, microGoal);
  }

  // ---------------------------------------------------------------------------
  // Pep message
  // ---------------------------------------------------------------------------

  String _buildMessage(
    String name,
    String personality,
    int maxStreak,
    double avgRate,
    int habitCount,
  ) {
    final pct = (avgRate * 100).round();

    if (personality == AppConstants.buddyPersonalities[1]) {
      // Strict Trainer
      if (maxStreak == 0) return '$name, zero streak is unacceptable. Get moving — now.';
      if (pct < 50) return 'Only $pct%? $name, you\'re capable of more. No excuses.';
      if (maxStreak >= 7) return '$maxStreak days straight, $name. Acceptable. Keep the pace.';
      return '$name, $pct% this week. Push harder tomorrow.';
    }

    if (personality == AppConstants.buddyPersonalities[2]) {
      // Calm Mentor
      if (maxStreak == 0) return 'Every journey begins with a single step, $name. Begin today.';
      if (pct < 50) return 'Progress, not perfection, $name. Each small effort shapes who you become.';
      if (maxStreak >= 7) return 'A $maxStreak-day streak speaks to your commitment, $name. Stay present.';
      return 'You\'re doing meaningful work, $name. $pct% completion is a real foundation.';
    }

    if (personality == AppConstants.buddyPersonalities[3]) {
      // Playful Friend
      if (maxStreak == 0) return 'Hey $name! 👀 Your habits miss you — time to show up!';
      if (pct < 50) return '$pct%? $name you\'ve totally got this, let\'s gooo!';
      if (maxStreak >= 7) return 'SEVEN days?! $name you\'re literally unstoppable 🔥';
      return 'Look at you, $name! $pct% this week, keeping it real 💪';
    }

    // Default: Encouraging Coach
    if (maxStreak == 0) return 'Ready to start, $name? Every streak begins with today\'s first check-in!';
    if (pct < 50) return 'You\'re at $pct% this week, $name. Small wins add up — keep going!';
    if (maxStreak >= 7) return 'Incredible, $name! A $maxStreak-day streak shows real dedication. You\'re building something lasting.';
    return 'Great work, $name! $pct% completion this week across $habitCount habits. You\'re on track!';
  }

  // ---------------------------------------------------------------------------
  // Micro-goal
  // ---------------------------------------------------------------------------

  String _buildMicroGoal(
    String name,
    String personality,
    List<Habit> incomplete,
    int maxStreak,
  ) {
    if (incomplete.isEmpty) {
      return _allDoneGoal(personality);
    }

    // Pick target habit: prefer easy first for momentum
    final easy = incomplete.where((h) => h.difficulty == 'easy').toList();
    final hard = incomplete.where((h) => h.difficulty == 'hard').toList();
    final target = personality == AppConstants.buddyPersonalities[1]
        ? (hard.isNotEmpty ? hard.first : incomplete.first) // Strict Trainer attacks hard first
        : (easy.isNotEmpty ? easy.first : incomplete.first);

    final timeEst = _timeEstimate(target.difficulty);

    if (personality == AppConstants.buddyPersonalities[1]) {
      return 'Attack "${target.title}" first — no warm-up needed. Do it now.';
    }
    if (personality == AppConstants.buddyPersonalities[2]) {
      return 'Begin with "${target.title}". $timeEst of focused effort is all it takes.';
    }
    if (personality == AppConstants.buddyPersonalities[3]) {
      return '🎯 Knock out "${target.title}" first — $timeEst and you\'re winning already!';
    }
    // Encouraging Coach
    if (maxStreak >= 3) {
      return 'Keep the streak alive: start with "${target.title}" ($timeEst). You\'ve got momentum!';
    }
    return 'Today\'s focus: "${target.title}" — just $timeEst. Start there and build up.';
  }

  String _allDoneGoal(String personality) {
    if (personality == AppConstants.buddyPersonalities[1]) {
      return 'All done. Now think about raising the difficulty tomorrow.';
    }
    if (personality == AppConstants.buddyPersonalities[2]) {
      return 'All missions complete. Take a quiet moment to acknowledge your consistency.';
    }
    if (personality == AppConstants.buddyPersonalities[3]) {
      return '🎉 All done!! You totally crushed today — treat yourself!';
    }
    return 'All missions complete! Spend 5 minutes reflecting on what went well today.';
  }

  String _timeEstimate(String difficulty) {
    switch (difficulty) {
      case 'easy':   return '5–10 min';
      case 'medium': return '15–30 min';
      case 'hard':   return '30–60 min';
      default:       return 'a few minutes';
    }
  }

  // ---------------------------------------------------------------------------
  // Welcome messages (no habits yet)
  // ---------------------------------------------------------------------------

  String _welcomeMessage(String name, String personality) {
    if (personality == AppConstants.buddyPersonalities[1]) {
      return '$name, no habits created yet. Fix that immediately.';
    }
    if (personality == AppConstants.buddyPersonalities[2]) {
      return 'Welcome, $name. Add your first habit and let the journey unfold.';
    }
    if (personality == AppConstants.buddyPersonalities[3]) {
      return 'Hey $name! Add your first habit and let\'s get this party started 🎉';
    }
    return 'Welcome, $name! Add your first habit to get started on your journey.';
  }

  String _welcomeGoal(String personality) {
    if (personality == AppConstants.buddyPersonalities[1]) {
      return 'Create at least one habit. That is today\'s only acceptable goal.';
    }
    if (personality == AppConstants.buddyPersonalities[2]) {
      return 'Micro-goal: add one habit that truly matters to you today.';
    }
    if (personality == AppConstants.buddyPersonalities[3]) {
      return '✨ Micro-goal: create your first habit and let\'s kick things off!';
    }
    return 'Micro-goal: create your first habit and check it off today!';
  }

  // ---------------------------------------------------------------------------
  // Weekly coach insight (data-driven, shown on Insights tab)
  // ---------------------------------------------------------------------------

  /// Generates a weekly analysis based on real stats — not cached, called fresh
  /// each time the Insights tab loads.
  String getWeeklyCoachInsight({
    required double thisWeekRate,
    required double lastWeekRate,
    required int thisWeekXp,
    required int bestStreak,
    required String? bestHabit,
    required List<String> skippedAllWeek,
  }) {
    final name = PrefsService.instance.userName;
    final personality = PrefsService.instance.buddyPersonality;
    final pct = (thisWeekRate * 100).round();
    final lastPct = (lastWeekRate * 100).round();
    final improved = thisWeekRate >= lastWeekRate;
    final diff = ((thisWeekRate - lastWeekRate).abs() * 100).round();

    final sb = StringBuffer();

    // Week-over-week comparison
    if (lastWeekRate == 0 && thisWeekRate == 0) {
      sb.write('No completions logged yet this week, $name. ');
    } else if (lastWeekRate == 0) {
      sb.write('$pct% completion in your first tracked week, $name. ');
    } else if (improved && diff > 0) {
      sb.write('Up $diff% from last week — $pct% vs $lastPct%, $name. ');
    } else if (!improved && diff > 0) {
      sb.write('Down $diff% from last week ($pct% vs $lastPct%), $name. ');
    } else {
      sb.write('Consistent at $pct% — matching last week\'s pace, $name. ');
    }

    // Best streak callout
    if (bestHabit != null && bestStreak >= 3) {
      sb.write('"$bestHabit" leads with a $bestStreak-day streak. ');
    }

    // XP earned
    if (thisWeekXp > 0) {
      sb.write('$thisWeekXp XP earned this week. ');
    }

    // Skipped habits
    if (skippedAllWeek.isNotEmpty) {
      if (skippedAllWeek.length == 1) {
        sb.write('"${skippedAllWeek.first}" hasn\'t been touched this week — ');
      } else {
        sb.write('${skippedAllWeek.length} habits untouched this week — ');
      }

      if (personality == AppConstants.buddyPersonalities[1]) {
        sb.write('unacceptable. Fix it before Sunday.');
      } else if (personality == AppConstants.buddyPersonalities[2]) {
        sb.write('even one small effort before Sunday will break the pattern.');
      } else if (personality == AppConstants.buddyPersonalities[3]) {
        sb.write('you\'ve still got time to turn it around! 💪');
      } else {
        sb.write('there\'s still time to make progress before the week ends.');
      }
    } else if (pct >= 80) {
      if (personality == AppConstants.buddyPersonalities[1]) {
        sb.write('Solid week. Now raise the bar next week.');
      } else if (personality == AppConstants.buddyPersonalities[2]) {
        sb.write('Your consistency this week is the foundation of lasting change.');
      } else if (personality == AppConstants.buddyPersonalities[3]) {
        sb.write('You\'re absolutely crushing it this week 🔥');
      } else {
        sb.write('Outstanding week — you\'re building real momentum!');
      }
    }

    return sb.toString().trim().isEmpty
        ? 'Keep working through the week, $name.'
        : sb.toString().trim();
  }

  // ---------------------------------------------------------------------------
  // Real-time chat — responds to user messages using actual habit context
  // ---------------------------------------------------------------------------

  /// Opening greeting when the chat screen first loads.
  String greet(BuddyChatContext ctx) {
    final name = ctx.userName;
    final p = ctx.personality;
    final done = ctx.todayDone;
    final total = ctx.todayTotal;

    if (p == AppConstants.buddyPersonalities[1]) {
      // Strict Trainer
      if (done == total && total > 0) return '$name. All $total habits done. Not bad. What do you want?';
      return '$name. $done/$total done so far. Talk.';
    }
    if (p == AppConstants.buddyPersonalities[2]) {
      // Calm Mentor
      return 'Good to see you, $name. You\'ve completed $done of $total habits today. What\'s on your mind?';
    }
    if (p == AppConstants.buddyPersonalities[3]) {
      // Playful Friend
      if (done == total && total > 0) return 'YESSS $name!! All $total habits crushed! 🎉 What\'s up?';
      return 'Hey $name! 👋 $done/$total done — let\'s gooo! What do you need?';
    }
    // Encouraging Coach
    if (done == total && total > 0) {
      return 'Amazing, $name! Every habit checked off today. How can I help you keep the momentum going?';
    }
    return 'Hey $name! You\'re at $done/$total habits today. What\'s on your mind — need motivation, a challenge, or just a check-in?';
  }

  /// Responds using rule-based matching. Returns the matched response or
  /// falls back to the default redirect message.
  String chat(String message, BuddyChatContext ctx) =>
      _matchRule(message, ctx) ?? _chatDefault(ctx, ctx.personality, ctx.userName);

  /// Same as [chat] but falls back to the Claude API when no rule matches
  /// and [apiKey] is non-empty. Always async so the chat screen can await it.
  Future<String> chatAsync(
      String message, BuddyChatContext ctx, String apiKey) async {
    final rule = _matchRule(message, ctx);
    if (rule != null) return rule;
    if (apiKey.isEmpty) return _chatDefault(ctx, ctx.personality, ctx.userName);

    try {
      final pct = (ctx.weeklyRate * 100).round();
      final incomplete = ctx.incompleteToday.isEmpty
          ? 'none'
          : ctx.incompleteToday.join(', ');
      final systemPrompt =
          'You are a personal wellness coach and AI buddy named "${ctx.personality}" '
          'inside a habit-tracking app called Get Active. '
          'Your scope is self-improvement and human wellbeing: fitness, nutrition, '
          'sleep, mental health, stress, productivity, motivation, relationships, '
          'mindset, recovery, and anything that helps the user live better. '
          'Answer these questions fully and helpfully — including specific questions '
          'like "what should I eat before the gym" or "how do I deal with burnout". '
          'If a question is clearly outside self-improvement (e.g. finance, coding, '
          'politics, credit scores, legal advice), politely say that\'s outside your '
          'scope and offer to help with something wellness-related instead. '
          'User context (use when relevant): '
          'name: ${ctx.userName}, '
          'today: ${ctx.todayDone}/${ctx.todayTotal} habits done, '
          'best streak: ${ctx.bestStreak} days, '
          'weekly completion: $pct%, '
          'habits not yet done: $incomplete. '
          'Keep answers concise (2–5 sentences). '
          'Tone: ${_personalityTone(ctx.personality)}.';

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'max_tokens': 200,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': message},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (data['choices'] as List).first['message']['content'] as String;
      }
      if (response.statusCode == 429) {
        // Rate limited — wait 3 seconds and retry once automatically
        await Future.delayed(const Duration(seconds: 3));
        final retry = await http.post(
          Uri.parse('https://api.openai.com/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'content-type': 'application/json',
          },
          body: jsonEncode({
            'model': 'gpt-4o-mini',
            'max_tokens': 200,
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': message},
            ],
          }),
        );
        if (retry.statusCode == 200) {
          final data = jsonDecode(retry.body) as Map<String, dynamic>;
          return (data['choices'] as List).first['message']['content'] as String;
        }
        return 'Still rate limited — you\'re on the free tier (3 requests/min). Wait a moment and try again.';
      }
      if (response.statusCode == 401) {
        return 'API key invalid or expired. Go to Settings → OpenAI API Key and re-enter it.';
      }
      return 'OpenAI returned an error (${response.statusCode}). Check your API key in Settings.';
    } on Exception catch (e) {
      return 'Could not reach OpenAI — check your internet connection. ($e)';
    }
  }

  /// Returns a matched response string, or null if no rule matches.
  String? _matchRule(String message, BuddyChatContext ctx) {
    final lower = message.toLowerCase();
    final p = ctx.personality;
    final name = ctx.userName;

    if (_has(lower, ['how am i', 'progress', 'stats', "how'm i", 'doing'])) {
      return _chatProgress(ctx);
    }
    if (_has(lower, ['motivat', 'unmotivated', 'no motivation', 'feeling lazy', 'give up on my habits', 'want to quit', 'struggling with my habits', 'hard to stay on track'])) {
      return _chatMotivation(ctx, p, name);
    }
    if (_has(lower, ['challenge', 'bonus', 'something new', 'extra', 'fun mission', 'surprise'])) {
      return _chatChallenge(ctx, p, name);
    }
    if (_has(lower, ['streak', 'days in a row', 'consecutive', 'fire'])) {
      return _chatStreak(ctx, p, name);
    }
    if (_has(lower, ["what's left", 'remaining habits', 'not done today', 'incomplete habits', 'what habits', 'which habits', 'what to do today', 'what should i do today', 'what should i work on'])) {
      return _chatWhatToDo(ctx, p, name);
    }
    if (_has(lower, ['all done', 'i did it', 'crushed it', 'completed all', 'finished everything'])) {
      return _chatAllDone(ctx, p, name);
    }
    if (_has(lower, ['help', 'what can you', 'commands', 'can you do', 'options'])) {
      return _chatHelp(p, name);
    }
    if (_has(lower, ['hi', 'hello', 'hey', 'good morning', 'good afternoon', 'good evening', 'sup', 'yo'])) {
      return greet(ctx);
    }
    if (_has(lower, ['xp', 'points', 'level', 'score'])) {
      return _chatXp(ctx, p, name);
    }
    // "suggest a habit" / "recommend a habit" checked BEFORE generic tip
    if (_has(lower, ['what habit', 'new habit', 'add a habit', 'suggest a habit', 'good habit', 'recommend a habit', 'which habit'])) {
      return _chatNewHabit(p, name);
    }
    // Habit-meta questions only — generic wellness questions go to GPT
    if (_has(lower, ['habit tip', 'habit trick', 'habit advice', 'how to build a habit', 'habit loop', 'habit science'])) {
      return _chatTip(ctx, p, name);
    }
    if (_has(lower, ['habit science', 'how habits form', '21 day myth', 'habit research', 'cue routine reward'])) {
      return _chatHabitScience(p, name);
    }
    if (_has(lower, ['missed my habit', 'skipped my habit', 'broke my streak', 'failed my habit', 'back on track with'])) {
      return _chatBounceBack(ctx, p, name);
    }
    if (_has(lower, ['rest day from habits', 'skip my habits', 'day off from habits'])) {
      return _chatRestDay(ctx, p, name);
    }
    if (_has(lower, ['stay consistent with', 'keep my habits', 'maintain my streak', 'habit stick'])) {
      return _chatConsistency(ctx, p, name);
    }
    if (_has(lower, ['reward myself for', 'celebrate my habit', 'earned my reward'])) {
      return _chatReward(ctx, p, name);
    }

    return null;
  }

  String _personalityTone(String p) {
    if (p == AppConstants.buddyPersonalities[1]) return 'direct, tough, and no-nonsense';
    if (p == AppConstants.buddyPersonalities[2]) return 'calm, thoughtful, and wise';
    if (p == AppConstants.buddyPersonalities[3]) return 'upbeat, fun, and enthusiastic (use emojis sparingly)';
    return 'encouraging, warm, and supportive';
  }

  bool _has(String text, List<String> keywords) =>
      keywords.any((k) => text.contains(k));

  String _chatProgress(BuddyChatContext ctx) {
    final pct = (ctx.weeklyRate * 100).round();
    final done = ctx.todayDone;
    final total = ctx.todayTotal;
    final streak = ctx.bestStreak;
    final p = ctx.personality;

    if (p == AppConstants.buddyPersonalities[1]) {
      return 'Today: $done/$total. Weekly rate: $pct%. Streak: $streak days. '
          '${pct >= 70 ? 'Acceptable.' : 'Not good enough. Push harder.'}';
    }
    if (p == AppConstants.buddyPersonalities[2]) {
      return 'Today you\'ve completed $done of $total habits. Your weekly completion rate is $pct% '
          'and your best streak is $streak days. '
          '${streak >= 5 ? 'That consistency is building something real.' : 'Each day you show up, the habit deepens.'}';
    }
    if (p == AppConstants.buddyPersonalities[3]) {
      return '$done/$total today, $pct% this week, $streak-day streak! '
          '${pct >= 60 ? 'You\'re totally killing it 🔥' : 'You\'ve got this — bounce-back time! 💪'}';
    }
    return 'Here\'s your snapshot: $done/$total habits done today, $pct% completion this week, '
        'and a $streak-day streak going. '
        '${pct >= 70 ? 'You\'re in great shape — keep it up!' : 'There\'s room to grow, and you\'re still showing up!'}';
  }

  String _chatMotivation(BuddyChatContext ctx, String p, String name) {
    final streak = ctx.bestStreak;
    if (p == AppConstants.buddyPersonalities[1]) {
      return 'Stop. Feelings don\'t do reps. Pick one habit right now and do it. '
          '${streak > 0 ? 'You have a $streak-day streak — don\'t let weakness end it.' : 'Start the streak today.'}';
    }
    if (p == AppConstants.buddyPersonalities[2]) {
      return 'Struggling is not failure — it\'s proof you\'re trying, $name. '
          'You don\'t need to feel motivated to act. Just start with the smallest possible step. '
          '${ctx.incompleteToday.isNotEmpty ? '"${ctx.incompleteToday.first}" only needs a few minutes.' : 'Even resting intentionally is part of the journey.'}';
    }
    if (p == AppConstants.buddyPersonalities[3]) {
      return 'Hey, we ALL have those days $name! 😅 Here\'s the secret: just do ONE tiny thing. '
          '${ctx.incompleteToday.isNotEmpty ? 'Pick "${ctx.incompleteToday.first}" — it\'s probably easier than you think! You can do it!! 🎉' : 'You\'ve already done everything today — that\'s WILD!!'}';
    }
    return 'Motivation comes and goes, $name — but habits stick around. '
        'You\'ve already built a $streak-day streak, which means you\'ve done this before on days you didn\'t feel like it. '
        '${ctx.incompleteToday.isNotEmpty ? 'Try starting with "${ctx.incompleteToday.first}" — just the first 2 minutes.' : 'You\'re actually all done for today — give yourself credit!'}';
  }

  String _chatChallenge(BuddyChatContext ctx, String p, String name) {
    final hour = DateTime.now().hour;
    final challenges = [
      if (hour < 12) ...[
        'Do 10 jumping jacks right now before your next habit.',
        'Drink a full glass of water before your next meal.',
        'Write down your #1 intention for today in one sentence.',
      ] else if (hour < 17) ...[
        'Stand up and walk for 3 minutes — no phone.',
        'Do a 2-minute tidy of the space you\'re in.',
        'Close all tabs and focus on one thing for the next 25 minutes.',
      ] else ...[
        'Do a 5-minute stretch or breathing exercise before bed.',
        'Write 3 things you\'re grateful for from today.',
        'Prep one thing for tomorrow morning to make it easier.',
      ],
    ];

    final seed = DateTime.now().day + DateTime.now().month;
    final pick = challenges[seed % challenges.length];

    if (p == AppConstants.buddyPersonalities[1]) return 'Bonus mission: $pick. Do it now.';
    if (p == AppConstants.buddyPersonalities[2]) return 'Here\'s a mindful bonus for you, $name: $pick';
    if (p == AppConstants.buddyPersonalities[3]) return '🎯 Bonus mission unlocked for $name: $pick  — GO!';
    return '🎯 Here\'s a bonus mission for you, $name: $pick';
  }

  String _chatStreak(BuddyChatContext ctx, String p, String name) {
    final s = ctx.bestStreak;
    if (s == 0) {
      if (p == AppConstants.buddyPersonalities[1]) return 'Zero streak. Fix it today.';
      if (p == AppConstants.buddyPersonalities[3]) return 'No streak yet $name — today is DAY 1! Let\'s gooo 🔥';
      return 'No streak yet, $name — every streak starts with a single day. Make today day 1!';
    }
    if (p == AppConstants.buddyPersonalities[1]) return '$s days. Keep it or lose it.';
    if (p == AppConstants.buddyPersonalities[2]) return 'You have a $s-day streak, $name. That\'s $s consecutive days of showing up. That\'s character.';
    if (p == AppConstants.buddyPersonalities[3]) return '$s DAYS IN A ROW $name!! That\'s absolutely insane 🔥🔥🔥';
    return 'You\'re on a $s-day streak, $name! '
        '${s >= 7 ? 'That\'s a whole week of showing up — incredible consistency.' : 'Keep it going — every day makes the chain stronger!'}';
  }

  String _chatWhatToDo(BuddyChatContext ctx, String p, String name) {
    if (ctx.incompleteToday.isEmpty) {
      if (p == AppConstants.buddyPersonalities[1]) return 'Nothing left. All done. Rest.';
      if (p == AppConstants.buddyPersonalities[3]) return 'NOTHING! You crushed everything today $name!! 🎉';
      return 'Nothing left, $name! Every habit is complete for today. Go enjoy the rest of your day — you earned it!';
    }
    final first = ctx.incompleteToday.first;
    final count = ctx.incompleteToday.length;
    if (p == AppConstants.buddyPersonalities[1]) return '$count left. Start with "$first". Now.';
    if (p == AppConstants.buddyPersonalities[2]) return '$count habits remaining today, $name. I\'d suggest starting with "$first" — it\'ll create momentum for the rest.';
    if (p == AppConstants.buddyPersonalities[3]) return '$count left $name! Start with "$first" — smash it and the rest will feel easy! 🚀';
    return 'You have $count habit${count == 1 ? '' : 's'} left today. I\'d start with "$first" to build momentum. You\'ve got this!';
  }

  String _chatAllDone(BuddyChatContext ctx, String p, String name) {
    if (ctx.todayDone < ctx.todayTotal) {
      return _chatWhatToDo(ctx, p, name);
    }
    if (p == AppConstants.buddyPersonalities[1]) return 'All done. That\'s the minimum. Think about tomorrow.';
    if (p == AppConstants.buddyPersonalities[2]) return 'Well done, $name. You completed everything today. Take a moment to sit with that feeling — it\'s earned.';
    if (p == AppConstants.buddyPersonalities[3]) return 'YESSSSS $name!!! ALL DONE!!! You are literally my favourite person right now 🎉🔥💪';
    return 'You did it, $name! All habits complete for today. That\'s what consistency looks like — be proud of yourself!';
  }

  String _chatXp(BuddyChatContext ctx, String p, String name) {
    if (p == AppConstants.buddyPersonalities[1]) return 'Points are a byproduct of discipline. Focus on the habits, not the score.';
    if (p == AppConstants.buddyPersonalities[2]) return 'Your XP reflects your effort, $name. Check the Progress tab for a full breakdown of your level and streak history.';
    if (p == AppConstants.buddyPersonalities[3]) return 'XP and levels are in the Progress tab $name! More completions = more points = more levels!! 🌟';
    return 'Head to the Progress tab to see your full XP, level, and streak history, $name. Every completion earns points based on difficulty!';
  }

  String _chatTip(BuddyChatContext ctx, String p, String name) {
    final tips = [
      'Stack your habits — do them right after something you already do every day.',
      'The "2-minute rule": if a habit takes less than 2 minutes, do it right now.',
      'Track your habits at the same time each day — consistency in timing builds consistency in action.',
      'Missing once is an accident. Missing twice is starting a new habit. Never miss twice.',
      'Make the habit obvious, attractive, easy, and satisfying — that\'s the habit loop.',
    ];
    final seed = DateTime.now().day % tips.length;
    final tip = tips[seed];
    if (p == AppConstants.buddyPersonalities[1]) return 'Tip: $tip';
    if (p == AppConstants.buddyPersonalities[3]) return '💡 Hot tip for $name: $tip';
    return 'Here\'s a tip, $name: $tip';
  }

  String _chatHelp(String p, String name) {
    const options = '• "How am I doing?" — stats & progress\n'
        '• "What should I do?" — what\'s left today\n'
        '• "I need motivation" — pep talk\n'
        '• "Give me a challenge" — bonus mission\n'
        '• "What\'s my streak?" — streak update\n'
        '• "I\'m stressed" — stress support\n'
        '• "Talk about sleep" — recovery tips\n'
        '• "Suggest a new habit" — habit ideas\n'
        '• "I missed a day" — bounce back\n'
        '• "Tips" — habit science\n'
        '• Or just type anything — I\'ll do my best!';
    if (p == AppConstants.buddyPersonalities[1]) return 'Commands:\n$options';
    if (p == AppConstants.buddyPersonalities[3]) return 'Here\'s what I can do for you $name! 🎯\n$options';
    return 'Here\'s what you can ask me, $name:\n$options';
  }

  String _chatHabitScience(String p, String name) {
    if (p == AppConstants.buddyPersonalities[1]) {
      return 'A habit takes 18–254 days to form — 21 is a myth. What matters: do it consistently. Every rep rewires the brain. Keep moving.';
    }
    if (p == AppConstants.buddyPersonalities[2]) {
      return 'Habits work through a cue–routine–reward loop, $name. The brain automates what it repeats. Research shows it takes an average of 66 days — patience and consistency are the real tools.';
    }
    if (p == AppConstants.buddyPersonalities[3]) {
      return 'Habit science is SO cool $name!! 🧠 Your brain literally rewires itself when you repeat something — 66 days on average to go automatic. Keep those streaks going!';
    }
    return 'Habits form through repetition — your brain builds neural pathways each time. It takes ~66 days on average (not 21), so be patient with yourself, $name. The cue → action → reward loop is the key.';
  }

  String _chatBounceBack(BuddyChatContext ctx, String p, String name) {
    if (p == AppConstants.buddyPersonalities[1]) {
      return 'You fell. Get up. Missing once is human. Missing twice is a choice. Do one habit now — restart the clock.';
    }
    if (p == AppConstants.buddyPersonalities[2]) {
      return 'Setbacks are built into every meaningful journey, $name. The question isn\'t whether you slipped — it\'s what you do next. One action, however small, is how you return.';
    }
    if (p == AppConstants.buddyPersonalities[3]) {
      return 'Hey, we ALL slip up $name — that\'s literally just being human! 💙 The comeback starts NOW. Do one tiny habit today and you\'re already back on track! 🎉';
    }
    return 'Missing a day doesn\'t erase your progress, $name — it\'s part of the journey. The key rule: never miss twice. Do one habit right now and the streak restarts from here.';
  }

  String _chatReward(BuddyChatContext ctx, String p, String name) {
    final remaining = ctx.todayTotal - ctx.todayDone;
    if (remaining > 0) {
      if (p == AppConstants.buddyPersonalities[1]) return 'Rewards come after work. Finish the remaining $remaining habits first.';
      if (p == AppConstants.buddyPersonalities[3]) return 'Almost there $name! Knock out the last $remaining habits and THEN celebrate!! 🎊';
      return 'You\'re so close, $name — finish the last $remaining and then absolutely reward yourself!';
    }
    if (p == AppConstants.buddyPersonalities[1]) return 'All done. The satisfaction of completion is your reward. Earn tomorrow\'s too.';
    if (p == AppConstants.buddyPersonalities[2]) return 'You\'ve earned a real rest, $name. Take time to acknowledge what you completed — that recognition is what makes habits stick.';
    if (p == AppConstants.buddyPersonalities[3]) return 'ALL DONE $name?! TREAT YOURSELF!! 🎉🎊 You absolutely earned something nice — go enjoy it!!';
    return 'You completed everything today, $name — that\'s worth celebrating! Do something that genuinely recharges you. You\'ve earned it.';
  }

  String _chatNewHabit(String p, String name) {
    const suggestions = [
      'Morning: 10 minutes of stretching before looking at your phone.',
      'Evening: Write 3 things you\'re grateful for each night.',
      'Daily: Drink a full glass of water first thing every morning.',
      'Weekly: A 30-minute walk outdoors — just you and your thoughts.',
      'Daily: Read 10 pages of a book before bed.',
    ];
    final pick = suggestions[DateTime.now().day % suggestions.length];
    if (p == AppConstants.buddyPersonalities[1]) return 'Suggestion: $pick Start small, do it daily, make it non-negotiable.';
    if (p == AppConstants.buddyPersonalities[2]) return 'Here\'s one worth considering, $name: $pick Build it into your existing routine for the best chance of it sticking.';
    if (p == AppConstants.buddyPersonalities[3]) return '✨ New habit idea for $name: $pick — try it for a week and see how it feels!';
    return 'Here\'s a habit to consider adding, $name: $pick Start with 7 days and see how it fits your life.';
  }

  String _chatConsistency(BuddyChatContext ctx, String p, String name) {
    final streak = ctx.bestStreak;
    final rate = (ctx.weeklyRate * 100).round();
    if (p == AppConstants.buddyPersonalities[1]) {
      return 'Consistency beats intensity every time. Your $streak-day streak and $rate% rate prove you can do this. Keep the standard.';
    }
    if (p == AppConstants.buddyPersonalities[2]) {
      return 'Consistency is not about being perfect, $name — it\'s about always returning. Your $streak-day streak and $rate% weekly rate show the pattern is forming.';
    }
    if (p == AppConstants.buddyPersonalities[3]) {
      return '$streak days strong and $rate% weekly rate $name — you are CONSISTENT and it shows!! 🔥 The secret? Just keep showing up, even imperfectly!';
    }
    return 'Consistency is the real secret, $name. Your $streak-day streak and $rate% weekly rate show it\'s working. Show up on the hard days — those are the ones that build the habit.';
  }

  String _chatRestDay(BuddyChatContext ctx, String p, String name) {
    if (p == AppConstants.buddyPersonalities[1]) {
      return 'Rest days are programmed recovery — not weakness. Active recovery beats full inactivity. Come back stronger tomorrow.';
    }
    if (p == AppConstants.buddyPersonalities[2]) {
      return 'Rest is not the opposite of progress, $name — it\'s part of it. Even on lighter days, a short walk or one page of a book keeps the pattern alive.';
    }
    if (p == AppConstants.buddyPersonalities[3]) {
      return 'Rest days are SO important $name!! 😴 Your body literally grows when you rest. Even a gentle walk counts — don\'t feel guilty for taking care of yourself!';
    }
    return 'Rest days are essential, $name — they\'re when your body adapts and grows. On lighter days, try a scaled-down version of a habit to keep the momentum without overdoing it.';
  }

  String _chatDefault(BuddyChatContext ctx, String p, String name) {
    if (p == AppConstants.buddyPersonalities[1]) return 'I don\'t understand that. Ask about your progress, streak, or remaining tasks.';
    if (p == AppConstants.buddyPersonalities[2]) return 'I\'m not sure what you mean, $name. Try asking about your progress, what to focus on, or ask for a tip.';
    if (p == AppConstants.buddyPersonalities[3]) return 'Hmm, didn\'t quite catch that $name! 😅 Try asking "how am I doing?" or "give me a challenge"!';
    return 'Not sure what you mean, $name. Try asking "how am I doing?", "what\'s left today?", or "give me a challenge"!';
  }

  // ---------------------------------------------------------------------------
  // Daily bonus missions — fresh micro-challenges based on categories + time
  // ---------------------------------------------------------------------------

  /// Returns 2 daily bonus missions seeded by today's date (consistent all day).
  List<String> getDailyBonusMissions(List<Habit> habits, int hour) {
    final categories = habits.map((h) => h.category).toSet();
    final slot = hour < 12 ? 0 : hour < 17 ? 1 : 2; // 0=morning 1=afternoon 2=evening
    final seed = DateTime.now().year * 10000 +
        DateTime.now().month * 100 +
        DateTime.now().day;
    final rng = Random(seed);

    final pool = <String>[];

    for (final cat in categories) {
      final catMissions = _missionPool[cat];
      if (catMissions != null) pool.addAll(catMissions[slot]);
    }
    // Always include general missions
    pool.addAll(_missionPool['General']![slot]);

    if (pool.length < 2) {
      return ['Do one thing today that future-you will thank you for.',
              'Take 5 minutes to tidy your immediate space.'];
    }
    pool.shuffle(rng);
    return pool.take(2).toList();
  }

  // mission pool: category -> [morning[], afternoon[], evening[]]
  static const Map<String, List<List<String>>> _missionPool = {
    'Fitness': [
      ['Do 10 jumping jacks before your first habit', 'Hold a plank for 30 seconds'],
      ['Stand up and do 5 slow squats right now', 'Take a brisk 5-minute walk outside'],
      ['Do a 5-minute stretch before bed', '20 bodyweight squats before you sleep'],
    ],
    'Health': [
      ['Drink a full glass of water before breakfast', 'Eat a piece of fruit as your first food'],
      ['Replace one snack with water or fruit this afternoon', 'Step outside for 3 minutes of fresh air'],
      ['No screens for 30 minutes before bed tonight', 'Drink one more glass of water right now'],
    ],
    'Mindfulness': [
      ['Take 5 slow deep breaths before checking your phone', 'Write one sentence about how you feel right now'],
      ['Spend 3 minutes outside just observing — no phone', 'Close your eyes and breathe for 60 seconds'],
      ['Write 3 things you\'re grateful for from today', 'Do a 2-minute body scan before sleep'],
    ],
    'Learning': [
      ['Read one article or listen to 10 min of a podcast', 'Learn and write down one new word or fact'],
      ['Watch a 5-minute educational video', 'Teach someone one thing you learned recently'],
      ['Review your notes from something you learned this week', 'Write a 3-sentence summary of something new you learned today'],
    ],
    'Productivity': [
      ['Write your top 3 priorities for today before starting', 'Clear your most-dreaded task in the first 30 minutes'],
      ['Close all unused tabs and apps right now', 'Do a 25-minute focused work sprint — no distractions'],
      ['Lay out everything you need for tomorrow morning', 'Reply to one thing you\'ve been putting off'],
    ],
    'General': [
      ['Make your bed before anything else today', 'Send a kind message to someone you appreciate'],
      ['Tidy one area of your space for 5 minutes', 'Do something you\'ve been procrastinating for just 2 minutes'],
      ['Prepare one thing for tomorrow to make the morning easier', 'Reflect: what was the best part of today?'],
    ],
  };

  String _fallback() => 'Keep going — every day counts!';
  String _fallbackGoal() => 'Complete at least one habit today to build momentum.';
}
