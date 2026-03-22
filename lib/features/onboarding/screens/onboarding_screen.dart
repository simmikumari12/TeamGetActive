import 'package:flutter/material.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/prefs_service.dart';

/// Three-page onboarding flow shown only on first install.
/// Collects the user's name and preferred AI buddy personality,
/// then marks onboarding complete and navigates to the dashboard.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _currentPage = 0;
  String _selectedPersonality = AppConstants.buddyPersonalities.first;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 1) {
      // Validate name field before advancing
      if (!_formKey.currentState!.validate()) return;
    }
    _pageController.nextPage(
      duration: AppConstants.slideTransitionDuration,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finish() async {
    await PrefsService.instance.setUserName(_nameController.text.trim());
    await PrefsService.instance.setBuddyPersonality(_selectedPersonality);
    await PrefsService.instance.setOnboardingDone();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRouter.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Progress dots
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => _Dot(active: i == _currentPage)),
              ),
            ),
            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _WelcomePage(onNext: _nextPage),
                  _NamePage(
                    formKey: _formKey,
                    controller: _nameController,
                    onNext: _nextPage,
                  ),
                  _PersonalityPage(
                    selected: _selectedPersonality,
                    onSelect: (p) => setState(() => _selectedPersonality = p),
                    onFinish: _finish,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 1 — Welcome
// ---------------------------------------------------------------------------

class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple,
              borderRadius: BorderRadius.circular(32),
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          Text('Welcome to\nHabit Mastery League',
              textAlign: TextAlign.center,
              style: AppTextStyles.displayMedium),
          const SizedBox(height: 16),
          Text(
            'Turn your daily habits into missions.\nEarn XP, build streaks, and level up your life.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge,
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: onNext,
            child: const Text("Let's go"),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 2 — Name input
// ---------------------------------------------------------------------------

class _NamePage extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final VoidCallback onNext;

  const _NamePage({
    required this.formKey,
    required this.controller,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What should we\ncall you?', style: AppTextStyles.displayMedium),
            const SizedBox(height: 12),
            Text('Your name appears on your progress dashboard.',
                style: AppTextStyles.bodyLarge),
            const SizedBox(height: 32),
            TextFormField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Enter your name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter a name';
                if (v.trim().length < 2) return 'Name must be at least 2 characters';
                return null;
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onNext,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 3 — Buddy personality picker
// ---------------------------------------------------------------------------

class _PersonalityPage extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onFinish;

  const _PersonalityPage({
    required this.selected,
    required this.onSelect,
    required this.onFinish,
  });

  static const Map<String, IconData> _icons = {
    'Encouraging Coach': Icons.sports,
    'Strict Trainer':    Icons.fitness_center,
    'Calm Mentor':       Icons.self_improvement,
    'Playful Friend':    Icons.celebration,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose your\nHabit Buddy', style: AppTextStyles.displayMedium),
          const SizedBox(height: 12),
          Text('Your buddy sends daily micro-goals and pep messages.',
              style: AppTextStyles.bodyLarge),
          const SizedBox(height: 28),
          ...AppConstants.buddyPersonalities.map((p) => _PersonalityTile(
                label: p,
                icon: _icons[p] ?? Icons.star,
                isSelected: p == selected,
                onTap: () => onSelect(p),
              )),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: onFinish,
            child: const Text('Start my journey'),
          ),
        ],
      ),
    );
  }
}

class _PersonalityTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PersonalityTile({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPurple : AppColors.lightCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryPurple : AppColors.lightDivider,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? Colors.white : AppColors.primaryPurple),
            const SizedBox(width: 14),
            Text(
              label,
              style: AppTextStyles.titleLarge.copyWith(
                color: isSelected ? Colors.white : AppColors.textDark,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Progress dot indicator
// ---------------------------------------------------------------------------

class _Dot extends StatelessWidget {
  final bool active;
  const _Dot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppColors.primaryPurple : AppColors.lightDivider,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
