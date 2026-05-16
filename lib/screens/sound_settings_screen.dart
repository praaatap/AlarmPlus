import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/alarm_providers.dart';

class SoundSettingsScreen extends ConsumerStatefulWidget {
  const SoundSettingsScreen({super.key});

  static const routeName = '/sound-settings';

  @override
  ConsumerState<SoundSettingsScreen> createState() => _SoundSettingsScreenState();
}

class _SoundSettingsScreenState extends ConsumerState<SoundSettingsScreen> {
  static const _volumeKey = 'sound.alarm.volume';
  static const _soundKey = 'sound.alarm.selected';

  final _player = AudioPlayer();

  double _volume = 0.8;
  String _selectedSound = 'default';
  bool _loading = true;
  bool _previewing = false;

  static const _sounds = <String, String>{
    'default': 'Default Ringtone',
    'assets/sounds/rain.mp3': 'Rain',
    'assets/sounds/ocean.mp3': 'Ocean',
    'assets/sounds/forest.mp3': 'Forest',
    'assets/sounds/white_noise.mp3': 'White Noise',
    'assets/sounds/brown_noise.mp3': 'Brown Noise',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _volume = (prefs.getDouble(_volumeKey) ?? 0.8).clamp(0.0, 1.0);
      _selectedSound = prefs.getString(_soundKey) ?? 'default';
      _loading = false;
    });
  }

  Future<void> _saveVolume(double v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_volumeKey, v);
  }

  Future<void> _saveSound(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_soundKey, key);
  }

  Future<void> _preview(String key) async {
    await _player.stop();
    if (key == 'default' || _previewing && _selectedSound == key) {
      setState(() => _previewing = false);
      return;
    }
    setState(() => _previewing = true);
    await _player.setVolume(_volume);
    await _player.play(AssetSource(key.replaceFirst('assets/', '')));
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _previewing = false);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vibrationEnabled = ref.watch(vibrationEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sound & Vibration'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
              children: [
                _SectionHeader('ALARM VOLUME'),
                const SizedBox(height: 8),
                _Card(
                  child: Row(
                    children: [
                      const Icon(Icons.volume_down_rounded,
                          color: Color(0xFF94A3B8)),
                      Expanded(
                        child: Slider(
                          value: _volume,
                          min: 0,
                          max: 1,
                          activeColor: const Color(0xFF22C55E),
                          onChanged: (v) => setState(() => _volume = v),
                          onChangeEnd: _saveVolume,
                        ),
                      ),
                      const Icon(Icons.volume_up_rounded,
                          color: Color(0xFF94A3B8)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _SectionHeader('ALARM SOUND'),
                const SizedBox(height: 8),
                ..._sounds.entries.map((entry) {
                  final selected = _selectedSound == entry.key;
                  return _Card(
                    onTap: () async {
                      setState(() => _selectedSound = entry.key);
                      await _saveSound(entry.key);
                      await _preview(entry.key);
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.value,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                          ),
                        ),
                        if (selected && _previewing)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF22C55E),
                            ),
                          )
                        else if (entry.key != 'default')
                          Icon(
                            Icons.play_circle_outline_rounded,
                            color: selected
                                ? const Color(0xFF22C55E)
                                : const Color(0xFFCBD5E1),
                          ),
                        const SizedBox(width: 8),
                        if (selected)
                          const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF22C55E)),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 20),
                _SectionHeader('VIBRATION'),
                const SizedBox(height: 8),
                _Card(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Vibrate on alarm ring',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text('Haptic feedback when alarm rings',
                                style:
                                    Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      Switch(
                        value: vibrationEnabled,
                        onChanged: (v) =>
                            ref.read(vibrationEnabledProvider.notifier).state =
                                v,
                        thumbColor:
                            const MaterialStatePropertyAll(Colors.white),
                        trackColor:
                            MaterialStateProperty.resolveWith<Color?>((s) =>
                                s.contains(MaterialState.selected)
                                    ? const Color(0xFF22C55E)
                                    : const Color(0xFFE2E8F0)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.bodySmall);
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: child,
      ),
    );
  }
}
