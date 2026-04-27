import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PremiumFeature {
  dailyWakePlanner,
  weeklyWakePlanner,
  sleepCoachPro,
  adaptiveAlarmTuning,
  rotatingAlarmSounds,
  weekendDriftGuard,
  recoveryDayPlanner,
  smartDismissModes,
}

class PremiumService {
  static const lifetimePriceInr = 299;
  static const _premiumUnlockedKey = 'premium.lifetime.unlocked';

  static Future<bool> isLifetimePremiumUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_premiumUnlockedKey) ?? false;
  }

  static Future<void> unlockLifetimePremium() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumUnlockedKey, true);
  }

  static Future<void> lockLifetimePremium() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumUnlockedKey, false);
  }

  static Future<bool> canUse(PremiumFeature feature) async {
    return isLifetimePremiumUnlocked();
  }

  static String featureTitle(PremiumFeature feature) {
    switch (feature) {
      case PremiumFeature.dailyWakePlanner:
        return 'Daily Wake Planner';
      case PremiumFeature.weeklyWakePlanner:
        return 'Weekly Wake Planner';
      case PremiumFeature.sleepCoachPro:
        return 'Sleep Coach Pro';
      case PremiumFeature.adaptiveAlarmTuning:
        return 'Adaptive Alarm Tuning';
      case PremiumFeature.rotatingAlarmSounds:
        return 'Rotating Alarm Sounds';
      case PremiumFeature.weekendDriftGuard:
        return 'Weekend Drift Guard';
      case PremiumFeature.recoveryDayPlanner:
        return 'Recovery Day Planner';
      case PremiumFeature.smartDismissModes:
        return 'Smart Dismiss Modes';
    }
  }

  static String featureDescription(PremiumFeature feature) {
    switch (feature) {
      case PremiumFeature.dailyWakePlanner:
        return 'Smart daily wake suggestions based on your day type and routine.';
      case PremiumFeature.weeklyWakePlanner:
        return 'A full weekly alarm planner with commute and sleep patterns.';
      case PremiumFeature.sleepCoachPro:
        return 'Teen sleep debt, consistency score, and smarter bedtime coaching.';
      case PremiumFeature.adaptiveAlarmTuning:
        return 'Mood and sleep check-ins that auto-tune your next wake-up time.';
      case PremiumFeature.rotatingAlarmSounds:
        return 'Dynamic sound rotation to reduce alarm fatigue.';
      case PremiumFeature.weekendDriftGuard:
        return 'Protects teens from sleeping too late on weekends and breaking their weekday rhythm.';
      case PremiumFeature.recoveryDayPlanner:
        return 'Builds a next-day recovery plan when sleep debt or poor sleep quality shows up.';
      case PremiumFeature.smartDismissModes:
        return 'Advanced stop challenges that reduce snoozing and help users actually get up.';
    }
  }

  static List<PremiumFeature> bundleFeatures() {
    return const [
      PremiumFeature.sleepCoachPro,
      PremiumFeature.recoveryDayPlanner,
      PremiumFeature.weekendDriftGuard,
      PremiumFeature.adaptiveAlarmTuning,
      PremiumFeature.dailyWakePlanner,
      PremiumFeature.weeklyWakePlanner,
      PremiumFeature.rotatingAlarmSounds,
      PremiumFeature.smartDismissModes,
    ];
  }

  static List<String> bundleLabels() {
    return bundleFeatures().map(featureTitle).toList(growable: false);
  }

  static String paywallMessage(PremiumFeature feature) {
    return '${featureTitle(feature)} is part of Lifetime Premium for ₹$lifetimePriceInr.\n\n${featureDescription(feature)}';
  }

  static Future<bool> showLifetimePaywall(
    BuildContext context,
    PremiumFeature feature,
  ) async {
    final unlocked = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unlock ${featureTitle(feature)}'),
        content: Text(paywallMessage(feature)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unlock Lifetime ₹299'),
          ),
        ],
      ),
    );

    if (unlocked == true) {
      await unlockLifetimePremium();
      return true;
    }

    return false;
  }
}
