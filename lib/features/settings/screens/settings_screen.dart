import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/prefs_service.dart';
import '../../../core/services/theme_notifier.dart';

/// Settings screen — theme, profile, buddy personality, notifications.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ThemePreference _theme;
  late String _userName;
  late String _personality;
  late bool _notifications;

  @override
  void initState() {
    super.initState();
    _theme = PrefsService.instance.themeMode;
    _userName = PrefsService.instance.userName;
    _personality = PrefsService.instance.buddyPersonality;
    _notifications = PrefsService.instance.notificationsEnabled;
  }

  Future<void> _editName() async {
    final ctrl = TextEditingController(text: _userName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Your Name'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter your name'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    if (result != null && result.length >= 2) {
      await PrefsService.instance.setUserName(result);
      setState(() => _userName = result);
    }
    ctrl.dispose();
  }

  Future<void> _setTheme(ThemePreference pref) async {
    await context.read<ThemeNotifier>().setMode(pref);
    setState(() => _theme = pref);
  }

  Future<void> _setPersonality(String p) async {
    await PrefsService.instance.setBuddyPersonality(p);
    setState(() => _personality = p);
  }

  Future<void> _setNotifications(bool val) async {
    await PrefsService.instance.setNotificationsEnabled(val);
    setState(() => _notifications = val);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _SectionLabel('Profile'),
          ListTile(
            leading: const Icon(Icons.person_outline_rounded),
            title: const Text('Your Name'),
            subtitle: Text(_userName, style: AppTextStyles.bodyMedium),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _editName,
          ),
          const Divider(height: 1),
          _SectionLabel('Appearance'),
          RadioGroup<ThemePreference>(
            groupValue: _theme,
            onChanged: (v) => _setTheme(v!),
            child: Column(
              children: ThemePreference.values
                  .map((pref) => RadioListTile<ThemePreference>(
                        value: pref,
                        title: Text(_themeLabel(pref)),
                        secondary: Icon(_themeIcon(pref)),
                      ))
                  .toList(),
            ),
          ),
          const Divider(height: 1),
          _SectionLabel('AI Buddy Personality'),
          RadioGroup<String>(
            groupValue: _personality,
            onChanged: (v) => _setPersonality(v!),
            child: Column(
              children: AppConstants.buddyPersonalities
                  .map((p) => RadioListTile<String>(
                        value: p,
                        title: Text(p),
                        secondary: Icon(_personalityIcon(p)),
                      ))
                  .toList(),
            ),
          ),
          const Divider(height: 1),
          _SectionLabel('Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Daily Reminders'),
            subtitle: const Text('Coming in a future update'),
            value: _notifications,
            onChanged: _setNotifications,
            activeThumbColor: AppColors.primaryPurple,
          ),
          const Divider(height: 1),
          _SectionLabel('About'),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('Version'),
            trailing: Text(AppConstants.appVersion,
                style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }

  String _themeLabel(ThemePreference p) {
    switch (p) {
      case ThemePreference.light:
        return 'Light';
      case ThemePreference.dark:
        return 'Dark';
      case ThemePreference.system:
        return 'System default';
    }
  }

  IconData _themeIcon(ThemePreference p) {
    switch (p) {
      case ThemePreference.light:
        return Icons.light_mode_rounded;
      case ThemePreference.dark:
        return Icons.dark_mode_rounded;
      case ThemePreference.system:
        return Icons.brightness_auto_rounded;
    }
  }

  IconData _personalityIcon(String p) {
    switch (p) {
      case 'Encouraging Coach':
        return Icons.sports_rounded;
      case 'Strict Trainer':
        return Icons.fitness_center_rounded;
      case 'Calm Mentor':
        return Icons.self_improvement_rounded;
      case 'Playful Friend':
        return Icons.emoji_emotions_rounded;
      default:
        return Icons.person_rounded;
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primaryPurple,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
