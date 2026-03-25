import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/alarm_providers.dart';
import '../services/ai_service.dart';
import '../services/premium_service.dart';
import '../services/smart_alarm_service.dart';
import 'ai_chat_screen.dart';
import 'alarm_ring_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late Future<bool> _premiumFuture;
  late Future<AlarmReliabilityStatus> _reliabilityFuture;
  late Future<DismissChallengeType> _dismissChallengeFuture;
  late Future<int> _windDownFuture;
  late Future<AlarmStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _refreshAsyncTiles();
  }

  void _refreshAsyncTiles() {
    _premiumFuture = PremiumService.isLifetimePremiumUnlocked();
    _reliabilityFuture = SmartAlarmService.getReliabilityStatus();
    _dismissChallengeFuture = SmartAlarmService.getDismissChallenge();
    _windDownFuture = SmartAlarmService.getWindDownMinutes();
    _statsFuture = SmartAlarmService.getStats();
  }

  void _refreshAndRebuild() {
    setState(_refreshAsyncTiles);
  }

  @override
  Widget build(BuildContext context) {
    final vibrationEnabled = ref.watch(vibrationEnabledProvider);
    final aiSuggestionsEnabled = ref.watch(aiSuggestionsEnabledProvider);
    final themeDark = ref.watch(themeDarkProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
        children: [
          Text('SETTINGS', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          FutureBuilder<bool>(
            future: _premiumFuture,
            builder: (context, snapshot) {
              final unlocked = snapshot.data ?? false;
              return _SettingTile(
                title: 'Lifetime Premium',
                subtitle: unlocked
                    ? 'Unlocked · AI planner, sleep coach pro, adaptive alarms'
                    : '₹299 one-time · unlock pro planning and teen sleep features',
                trailing: Icon(
                  unlocked
                      ? Icons.workspace_premium_rounded
                      : Icons.lock_outline_rounded,
                ),
                onTap: () => _showPremiumDialog(context, unlocked),
              );
            },
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              'Premium bundle: ${PremiumService.bundleLabels().join(' · ')}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          _SettingTile(
            title: 'Sound',
            subtitle: 'Wake tone and ring volume',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {},
          ),
          _SettingTile(
            title: 'Vibration',
            subtitle: 'Use vibration on alarm ring',
            trailing: Switch(
              value: vibrationEnabled,
              onChanged: (value) =>
                  ref.read(vibrationEnabledProvider.notifier).state = value,
              activeTrackColor: const Color(0xFF22C55E),
              activeThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFE2E8F0),
            ),
          ),
          _SettingTile(
            title: 'AI Suggestions',
            subtitle: 'Smart label and schedule hints',
            trailing: Switch(
              value: aiSuggestionsEnabled,
              onChanged: (value) =>
                  ref.read(aiSuggestionsEnabledProvider.notifier).state = value,
              activeTrackColor: const Color(0xFF22C55E),
              activeThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFE2E8F0),
            ),
          ),
          _SettingTile(
            title: 'Theme Toggle',
            subtitle: 'Prepared for future dark mode',
            trailing: Switch(
              value: themeDark,
              onChanged: (value) =>
                  ref.read(themeDarkProvider.notifier).state = value,
              activeTrackColor: const Color(0xFF22C55E),
              activeThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFE2E8F0),
            ),
          ),
          const SizedBox(height: 12),
          _SettingTile(
            title: 'Open AI Assistant',
            subtitle: 'Plan your day with FlowMind',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () =>
                Navigator.of(context).pushNamed(AiChatScreen.routeName),
          ),
          _SettingTile(
            title: 'AI Keys & SDK',
            subtitle: 'Gemini, Groq, and Genkit endpoint configuration',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showAiConfigSheet(context),
          ),
          _SettingTile(
            title: 'Preview Alarm Ring Screen',
            subtitle: 'Stop / Snooze full-screen preview',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () =>
                Navigator.of(context).pushNamed(AlarmRingScreen.routeName),
          ),
          FutureBuilder<AlarmReliabilityStatus>(
            future: _reliabilityFuture,
            builder: (context, snapshot) {
              final status = snapshot.data;
              final subtitle = status == null
                  ? 'Checking notification and exact alarm health'
                  : 'Notif: ${status.notificationsGranted ? 'ON' : 'OFF'} · Exact: ${status.exactAlarmGranted ? 'ON' : 'OFF'}';
              return _SettingTile(
                title: 'Alarm Reliability Dashboard',
                subtitle: subtitle,
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showReliabilityDialog(context, status),
              );
            },
          ),
          FutureBuilder<DismissChallengeType>(
            future: _dismissChallengeFuture,
            builder: (context, snapshot) {
              final challenge = snapshot.data ?? DismissChallengeType.none;
              return _SettingTile(
                title: 'Dismiss Challenge',
                subtitle: 'Current: ${challenge.name.toUpperCase()}',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showChallengePicker(context, challenge),
              );
            },
          ),
          FutureBuilder<int>(
            future: _windDownFuture,
            builder: (context, snapshot) {
              final minutes = snapshot.data ?? 30;
              return _SettingTile(
                title: 'Pre-Alarm Wind-Down',
                subtitle: '$minutes min before sleep + checklist',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showWindDownPicker(context, minutes),
              );
            },
          ),
          FutureBuilder<AlarmStats>(
            future: _statsFuture,
            builder: (context, snapshot) {
              final stats = snapshot.data;
              return _SettingTile(
                title: 'Streaks & Wake Metrics',
                subtitle: stats == null
                    ? 'Loading streaks...'
                    : 'Streak ${stats.currentStreak}, best ${stats.bestStreak}, snooze ${stats.snoozeCount}',
                trailing: const Icon(Icons.insights_outlined),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAiConfigSheet(BuildContext context) {
    final snapshot = AiService.runtimeConfigSnapshot();
    final geminiController = TextEditingController(
      text: snapshot['geminiApiKey'] ?? '',
    );
    final groqController = TextEditingController(
      text: snapshot['groqApiKey'] ?? '',
    );
    final dailyController = TextEditingController(
      text: snapshot['dailyFlowUrl'] ?? '',
    );
    final weeklyController = TextEditingController(
      text: snapshot['weeklyFlowUrl'] ?? '',
    );
    final suggestController = TextEditingController(
      text: snapshot['suggestFlowUrl'] ?? '',
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Keys & SDK',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: geminiController,
                  decoration: const InputDecoration(
                    labelText: 'Gemini API Key',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: groqController,
                  decoration: const InputDecoration(
                    labelText: 'Groq API Key',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: suggestController,
                  decoration: const InputDecoration(
                    labelText: 'Genkit Suggest Flow URL',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: dailyController,
                  decoration: const InputDecoration(
                    labelText: 'Genkit Daily Flow URL',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: weeklyController,
                  decoration: const InputDecoration(
                    labelText: 'Genkit Weekly Flow URL',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await AiService.saveRuntimeConfig(
                        geminiApiKey: geminiController.text,
                        groqApiKey: groqController.text,
                        dailyFlowUrl: dailyController.text,
                        weeklyFlowUrl: weeklyController.text,
                        suggestFlowUrl: suggestController.text,
                      );

                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'AI configuration saved and applied.',
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Save AI Configuration'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      geminiController.dispose();
      groqController.dispose();
      dailyController.dispose();
      weeklyController.dispose();
      suggestController.dispose();
    });
  }

  Future<void> _showPremiumDialog(BuildContext context, bool unlocked) async {
    if (unlocked) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Lifetime Premium'),
          content: const Text(
            'Lifetime premium is already unlocked on this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }

    await PremiumService.showLifetimePaywall(
      context,
      PremiumFeature.sleepCoachPro,
    );
    _refreshAndRebuild();
  }

  void _showReliabilityDialog(
    BuildContext context,
    AlarmReliabilityStatus? status,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alarm Reliability Dashboard'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scheduled alarms are managed with native exact mode.'),
            const SizedBox(height: 8),
            Text(
              'Notifications: ${status?.notificationsGranted == true ? 'Granted' : 'Missing'}',
            ),
            Text(
              'Exact Alarm: ${status?.exactAlarmGranted == true ? 'Granted' : 'Missing'}',
            ),
            Text(
              'Battery Optimization: ${status?.batteryOptimizationIgnored == true ? 'Ignored' : 'Active'}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showChallengePicker(
    BuildContext context,
    DismissChallengeType current,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => FutureBuilder<bool>(
        future: PremiumService.canUse(PremiumFeature.smartDismissModes),
        builder: (context, snapshot) {
          final unlocked = snapshot.data ?? false;
          return ListView(
            children: DismissChallengeType.values.map((type) {
              final needsPremium = type != DismissChallengeType.none;
              return ListTile(
                title: Text(type.name.toUpperCase()),
                subtitle: needsPremium && !unlocked
                    ? const Text('Premium')
                    : null,
                trailing: current == type ? const Icon(Icons.check) : null,
                onTap: () async {
                  if (needsPremium && !unlocked) {
                    await PremiumService.showLifetimePaywall(
                      context,
                      PremiumFeature.smartDismissModes,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                    return;
                  }

                  await SmartAlarmService.setDismissChallenge(type);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                  _refreshAndRebuild();
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _showWindDownPicker(BuildContext context, int current) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final minutes in const [30, 45, 60])
            ListTile(
              title: Text('$minutes minutes'),
              trailing: current == minutes ? const Icon(Icons.check) : null,
              onTap: () async {
                await SmartAlarmService.setWindDownMinutes(minutes);
                if (context.mounted) {
                  Navigator.pop(context);
                }
                _refreshAndRebuild();
              },
            ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing,
          ],
        ),
      ),
    );
  }
}
