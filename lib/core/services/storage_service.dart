import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alarm_plus/features/alarm/models/alarm_model.dart';

class StorageService {
  static const String _alarmsKey = 'flowmind_alarms';

  static Box? _alarmsBox;
  // In-memory fallback if Hive fails to open
  static final Map<String, Map<dynamic, dynamic>> _memoryFallback = {};
  static bool _usingFallback = false;

  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      _alarmsBox = await Hive.openBox(_alarmsKey);
      _usingFallback = false;
    } catch (e) {
      debugPrint('StorageService: Hive init failed, using in-memory fallback: $e');
      _usingFallback = true;
    }
  }

  static Future<void> saveString(String key, String value) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(key, value);
    } catch (e) {
      debugPrint('StorageService.saveString failed: $e');
    }
  }

  static Future<String?> loadString(String key) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return preferences.getString(key);
    } catch (e) {
      debugPrint('StorageService.loadString failed: $e');
      return null;
    }
  }

  static List<AlarmModel> getAllAlarms() {
    final Iterable<dynamic> values = _usingFallback
        ? _memoryFallback.values
        : (_alarmsBox?.values ?? const []);

    return values
        .whereType<Map>()
        .map((item) {
          try {
            return AlarmModel.fromMap(item);
          } catch (e) {
            debugPrint('Failed to parse alarm: $e');
            return null;
          }
        })
        .whereType<AlarmModel>()
        .toList()
      ..sort((a, b) {
        final aMinutes = (a.time.hour * 60) + a.time.minute;
        final bMinutes = (b.time.hour * 60) + b.time.minute;
        return aMinutes.compareTo(bMinutes);
      });
  }

  static Future<void> saveAlarm(AlarmModel alarm) async {
    final data = alarm.toMap();
    if (_usingFallback) {
      _memoryFallback[alarm.id] = data;
      return;
    }
    try {
      await _alarmsBox!.put(alarm.id, data);
    } catch (e) {
      debugPrint('StorageService.saveAlarm failed, using fallback: $e');
      _memoryFallback[alarm.id] = data;
    }
  }

  static Future<void> deleteAlarm(String id) async {
    _memoryFallback.remove(id);
    if (!_usingFallback) {
      try {
        await _alarmsBox!.delete(id);
      } catch (e) {
        debugPrint('StorageService.deleteAlarm failed: $e');
      }
    }
  }

  static AlarmModel? getAlarm(String id) {
    final raw = _usingFallback ? _memoryFallback[id] : _alarmsBox?.get(id);
    if (raw is Map) {
      try {
        return AlarmModel.fromMap(raw);
      } catch (e) {
        debugPrint('StorageService.getAlarm parse failed: $e');
      }
    }
    return null;
  }
}
