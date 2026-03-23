import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/services/buddy_service.dart';
import '../../../core/services/prefs_service.dart';
import '../../../core/utils/streak_utils.dart';
import '../../../data/repositories/habit_repository.dart';
import '../../../data/repositories/log_repository.dart';

// ---------------------------------------------------------------------------
// Chat bubble data
// ---------------------------------------------------------------------------

class _ChatMessage {
  final String text;
  final bool isUser;
  const _ChatMessage({required this.text, required this.isUser});
}

// ---------------------------------------------------------------------------
// Buddy Chat Screen
// ---------------------------------------------------------------------------

class BuddyChatScreen extends StatefulWidget {
  const BuddyChatScreen({super.key});

  @override
  State<BuddyChatScreen> createState() => _BuddyChatScreenState();
}

class _BuddyChatScreenState extends State<BuddyChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  BuddyChatContext? _ctx;
  String _apiKey = '';
  bool _loading = true;
  bool _typing = false;

  static const _quickReplies = [
    'How am I doing?',
    "What's left today?",
    'I need motivation',
    'Give me a challenge',
    "What's my streak?",
    'Suggest a new habit',
    'I\'m stressed',
    'Tips',
  ];

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    final habits = await HabitRepository.instance.getAll();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final from = now.subtract(const Duration(days: 30));

    final completedToday =
        await LogRepository.instance.getCompletedHabitIdsForDate(today);

    int bestStreak = 0;
    double totalRate = 0;
    for (final h in habits) {
      final logs =
          await LogRepository.instance.getLogsInRange(h.id!, from, now);
      final s = StreakUtils.computeStreak(logs);
      if (s > bestStreak) bestStreak = s;
      totalRate += StreakUtils.completionRate(logs, 7);
    }
    final weeklyRate = habits.isEmpty ? 0.0 : totalRate / habits.length;

    final incompleteToday = habits
        .where((h) => !completedToday.contains(h.id))
        .map((h) => h.title)
        .toList();

    final ctx = BuddyChatContext(
      userName: PrefsService.instance.userName,
      personality: PrefsService.instance.buddyPersonality,
      todayDone: completedToday.length,
      todayTotal: habits.length,
      bestStreak: bestStreak,
      weeklyRate: weeklyRate,
      incompleteToday: incompleteToday,
    );

    final greeting = BuddyService.instance.greet(ctx);
    final apiKey = PrefsService.instance.claudeApiKey;

    if (!mounted) return;
    setState(() {
      _ctx = ctx;
      _apiKey = apiKey;
      _messages.add(_ChatMessage(text: greeting, isUser: false));
      // If no API key is set, surface a hint so the user knows they can unlock it
      if (apiKey.isEmpty) {
        _messages.add(_ChatMessage(
          text: 'Tip: Set a Claude API key in Settings to unlock "ask me anything" mode!',
          isUser: false,
        ));
      }
      _loading = false;
    });
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _ctx == null || _typing) return;
    _controller.clear();

    setState(() {
      _messages.add(_ChatMessage(text: trimmed, isUser: true));
      _typing = true;
    });
    _scrollToBottom();

    final reply =
        await BuddyService.instance.chatAsync(trimmed, _ctx!, _apiKey);

    if (!mounted) return;
    setState(() {
      _typing = false;
      _messages.add(_ChatMessage(text: reply, isUser: false));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final personality = PrefsService.instance.buddyPersonality;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryPurple,
              child: const Icon(Icons.smart_toy_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(personality, style: AppTextStyles.titleLarge),
                Text(
                  _apiKey.isNotEmpty ? 'AI-powered' : 'Rule-based',
                  style: AppTextStyles.caption.copyWith(
                    color: _apiKey.isNotEmpty
                        ? Colors.green
                        : AppColors.textLight,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'API Key Settings',
            onPressed: () =>
                Navigator.pushNamed(context, '/settings').then((_) {
              // Reload API key if user updated it in settings
              setState(() => _apiKey = PrefsService.instance.claudeApiKey);
            }),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Message list ─────────────────────────────────
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: _messages.length + (_typing ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (_typing && i == _messages.length) {
                        return const _TypingIndicator();
                      }
                      return _BubbleTile(message: _messages[i]);
                    },
                  ),
                ),

                // ── Quick reply chips ────────────────────────────
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    separatorBuilder: (_, i) => const SizedBox(width: 8),
                    itemCount: _quickReplies.length,
                    itemBuilder: (context, i) => ActionChip(
                      label: Text(_quickReplies[i],
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.primaryPurple)),
                      backgroundColor:
                          AppColors.primaryPurple.withValues(alpha: 0.08),
                      side: BorderSide(
                          color:
                              AppColors.primaryPurple.withValues(alpha: 0.3)),
                      onPressed: _typing ? null : () => _send(_quickReplies[i]),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ── Input bar ────────────────────────────────────
                _InputBar(
                  controller: _controller,
                  onSend: _send,
                  enabled: !_typing,
                ),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chat bubble
// ---------------------------------------------------------------------------

class _BubbleTile extends StatelessWidget {
  final _ChatMessage message;
  const _BubbleTile({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryPurple : Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser
              ? null
              : Border.all(
                  color: AppColors.primaryPurple.withValues(alpha: 0.15)),
        ),
        child: Text(
          message.text,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isUser ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Typing indicator (three animated dots)
// ---------------------------------------------------------------------------

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(
              color: AppColors.primaryPurple.withValues(alpha: 0.15)),
        ),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final delay = i / 3;
                final opacity = (((_ctrl.value + delay) % 1.0) < 0.5) ? 1.0 : 0.3;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryPurple.withValues(alpha: opacity),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Input bar
// ---------------------------------------------------------------------------

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSend;
  final bool enabled;
  const _InputBar(
      {required this.controller,
      required this.onSend,
      this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 8, 10),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
              top: BorderSide(
                  color: AppColors.primaryPurple.withValues(alpha: 0.15))),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                textInputAction: TextInputAction.send,
                onSubmitted: enabled ? onSend : null,
                decoration: InputDecoration(
                  hintText: enabled
                      ? 'Ask your buddy anything…'
                      : 'Thinking…',
                  hintStyle: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textLight),
                  filled: true,
                  fillColor:
                      AppColors.primaryPurple.withValues(alpha: 0.05),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                        color:
                            AppColors.primaryPurple.withValues(alpha: 0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                        color:
                            AppColors.primaryPurple.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                        color: AppColors.primaryPurple, width: 1.5),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                        color: AppColors.primaryPurple.withValues(alpha: 0.1)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _CircleButton(
              icon: Icons.send_rounded,
              onTap: enabled ? () => onSend(controller.text) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _CircleButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppColors.primaryPurple
              : AppColors.primaryPurple.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
