import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../data/models/badge_model.dart';
import '../../../data/models/challenge.dart';
import '../../../data/repositories/badge_repository.dart';
import '../../../data/repositories/challenge_repository.dart';

/// Rewards tab — badge collection grid and active challenges list.
class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  List<BadgeModel> _badges = [];
  Set<int> _unlockedIds = {};
  List<Challenge> _challenges = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await ChallengeRepository.instance.seedIfEmpty();
    final badges = await BadgeRepository.instance.getAllBadges();
    final unlockedIds = await BadgeRepository.instance.getUnlockedBadgeIds();
    final challenges = await ChallengeRepository.instance.getActive();
    if (!mounted) return;
    setState(() {
      _badges = badges;
      _unlockedIds = unlockedIds;
      _challenges = challenges;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rewards')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SectionHeader(
                    title: 'Badges',
                    subtitle:
                        '${_unlockedIds.length} / ${_badges.length} unlocked',
                  ),
                  const SizedBox(height: 12),
                  _BadgeGrid(badges: _badges, unlockedIds: _unlockedIds),
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'Challenges',
                    subtitle: '${_challenges.length} active',
                  ),
                  const SizedBox(height: 12),
                  if (_challenges.isEmpty)
                    Center(
                      child: Text(
                        'No active challenges right now.',
                        style: AppTextStyles.bodyMedium,
                      ),
                    )
                  else
                    ..._challenges.map((c) => _ChallengeCard(challenge: c)),
                ],
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header row
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.headlineMedium),
        Text(subtitle,
            style: AppTextStyles.caption.copyWith(color: AppColors.textLight)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Badge grid
// ---------------------------------------------------------------------------

class _BadgeGrid extends StatelessWidget {
  final List<BadgeModel> badges;
  final Set<int> unlockedIds;
  const _BadgeGrid({required this.badges, required this.unlockedIds});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: badges.length,
      itemBuilder: (context, i) {
        final badge = badges[i];
        final unlocked = unlockedIds.contains(badge.id);
        return _BadgeTile(badge: badge, unlocked: unlocked);
      },
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final BadgeModel badge;
  final bool unlocked;
  const _BadgeTile({required this.badge, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: unlocked ? badge.description : badge.unlockCondition,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: unlocked
              ? AppColors.accentGold.withValues(alpha: 0.15)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unlocked ? AppColors.accentGold : AppColors.lightDivider,
            width: unlocked ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _iconData(badge.iconName),
              size: 36,
              color: unlocked ? AppColors.accentGold : AppColors.textLight,
            ),
            const SizedBox(height: 8),
            Text(
              badge.title,
              style: AppTextStyles.caption.copyWith(
                color: unlocked ? AppColors.textDark : AppColors.textLight,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconData(String name) {
    switch (name) {
      case 'flag':
        return Icons.flag_rounded;
      case 'local_fire_department':
        return Icons.local_fire_department_rounded;
      case 'military_tech':
        return Icons.military_tech_rounded;
      case 'workspace_premium':
        return Icons.workspace_premium_rounded;
      case 'emoji_events':
        return Icons.emoji_events_rounded;
      case 'add_task':
        return Icons.add_task_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'stars':
        return Icons.stars_rounded;
      case 'verified':
        return Icons.verified_rounded;
      case 'psychology':
        return Icons.psychology_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }
}

// ---------------------------------------------------------------------------
// Challenge card
// ---------------------------------------------------------------------------

class _ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  const _ChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: _typeColor(challenge.challengeType), width: 4),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(challenge.title, style: AppTextStyles.titleLarge),
                const SizedBox(height: 4),
                Text(challenge.description,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textLight)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accentGold,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '+${challenge.rewardPoints} XP',
              style: AppTextStyles.labelLarge
                  .copyWith(color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'streak':
        return AppColors.streakFire;
      case 'perfect_week':
        return AppColors.accentGold;
      case 'completion_count':
        return AppColors.accentGreen;
      default:
        return AppColors.primaryPurple;
    }
  }
}
