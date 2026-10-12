import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/l10n_text.dart';
import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../services/mock_auth_service.dart';
import '../../services/settings_service.dart';
import '../../services/simulation_engine.dart';
import '../../services/sound_service.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tk = tkOf(context);
    final l = l10nOf(context);
    final settings = context.watch<SettingsService>();
    final sound = context.read<SoundService>();
    final auth = context.watch<AuthService>();
    final engine = context.watch<SimulationEngine>();

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
        children: [
          // ── appearance ──
          SectionLabel(l.sectionAppearance),
          TkCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _ThemeOption(
                  icon: Icons.dark_mode_rounded,
                  label: l.themeDark,
                  selected: settings.themeDark,
                  onTap: () => settings.setThemeDark(true),
                ),
                const SizedBox(width: 12),
                _ThemeOption(
                  icon: Icons.light_mode_rounded,
                  label: l.themeLight,
                  selected: !settings.themeDark,
                  onTap: () => settings.setThemeDark(false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ── language ──
          SectionLabel(l.sectionLanguage),
          TkCard(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'system', icon: const Icon(Icons.language_rounded, size: 17), label: Text(l.langSystem)),
                ButtonSegment(value: 'en', label: Text(l.langEnglish)),
                ButtonSegment(value: 'ar', label: Text(l.langArabic)),
              ],
              selected: {settings.localeMode},
              onSelectionChanged: (s) => settings.setLocaleMode(s.first),
              showSelectedIcon: false,
            ),
          ),
          const SizedBox(height: 22),

          // ── alert sound ──
          SectionLabel(l.sectionSound),
          TkCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: RadioGroup<AlertSound>(
              groupValue: settings.sound,
              onChanged: (v) {
                if (v != null) settings.setSound(v);
              },
              child: Column(
                children: [
                for (final s in AlertSound.values)
                  ListTile(
                    leading: Icon(
                      s == AlertSound.sonarPing
                          ? Icons.sensors_rounded
                          : s == AlertSound.alarmPulse
                              ? Icons.alarm_rounded
                              : Icons.music_note_rounded,
                      color: settings.sound == s ? tk.accent : tk.textTertiary,
                    ),
                    title: Text(
                      l.soundLabel(s),
                      style: GoogleFonts.rubik(fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: settings.sound == s ? tk.textPrimary : tk.textSecondary,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.play_circle_fill_rounded,
                              size: 24, color: tk.accent),
                          onPressed: () => sound.playAlert(s),
                          tooltip: l.soundPreview,
                        ),
                        Radio<AlertSound>(value: s),
                      ],
                    ),
                    onTap: () => settings.setSound(s),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),

          // ── intervals ──
          SectionLabel(l.sectionIntervals),
          TkCard(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
            child: Column(
              children: [
                _IntervalSlider(
                  label: l.intervalPhoneGps,
                  value: settings.phoneGpsIntervalS,
                  min: 2,
                  max: 15,
                  onChanged: settings.setPhoneInterval,
                ),
                _IntervalSlider(
                  label: l.intervalBagGps,
                  value: settings.bagGpsIntervalS,
                  min: 5,
                  max: 30,
                  onChanged: settings.setBagInterval,
                ),
                _IntervalSlider(
                  label: l.intervalRecheck,
                  value: settings.recheckIntervalS,
                  min: 10,
                  max: 60,
                  onChanged: settings.setRecheckInterval,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 10),
                  child: Text(
                    l.intervalsNote,
                    style: TextStyle(fontSize: 11.5, color: tk.textTertiary, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ── backend ──
          SectionLabel(l.sectionConnection),
          TkCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.storage_rounded),
                  title: Text(
                    l.backendSupabase,
                    style: GoogleFonts.rubik(fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: tk.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    engine.scenarioRunning ? l.supabaseSyncing : l.supabaseAuth,
                    style: TextStyle(fontSize: 11.5, color: tk.textTertiary),
                  ),
                  trailing: _StatusDot(ok: true, label: l.connected, downLabel: l.down),
                ),
                ListTile(
                  leading: const Icon(Icons.cloud_done_rounded),
                  title: Text(
                    l.backendTigris,
                    style: GoogleFonts.rubik(fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: tk.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    l.tigrisSubtitle,
                    style: TextStyle(fontSize: 11.5, color: tk.textTertiary),
                  ),
                  trailing: _StatusDot(ok: true, label: l.connected, downLabel: l.down),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ── account ──
          SectionLabel(l.sectionAccount),
          TkCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: tk.ctaGradient),
                  ),
                  child: Text(
                    (auth.user?.name.isNotEmpty ?? false) ? auth.user!.name[0].toUpperCase() : 'T',
                    style: GoogleFonts.rubik(fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.user?.name ?? l.demoUser,
                        style: GoogleFonts.rubik(fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: tk.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        auth.user?.email ?? '—',
                        style: TextStyle(fontSize: 12, color: tk.textTertiary),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () => _confirmSignOut(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text(l.signOut),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Center(
            child: Text(
              l.versionLine,
              style: TextStyle(fontSize: 11.5, color: tk.textTertiary),
            ),
          ),
        ],
      ),
    );
  }

  /// Confirmation state before signing out — no accidental logouts mid-demo.
  void _confirmSignOut(BuildContext context) {
    final l = l10nOf(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.signOutTitle),
        content: Text(l.signOutBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthService>().signOut();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
            },
            child: Text(l.confirm),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeOption({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tk = tkOf(context);
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        child: Material(
          color: selected ? tk.accent.withValues(alpha: .14) : tk.bgDeep,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: selected ? tk.accent : Colors.transparent,
                  width: 1.4,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: selected ? tk.accent : tk.textTertiary),
                  const SizedBox(width: 9),
                  Text(
                    label,
                    style: GoogleFonts.rubik(fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? tk.accent : tk.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IntervalSlider extends StatelessWidget {
  final String label;
  final int value;
  final double min;
  final double max;
  final ValueChanged<int> onChanged;
  const _IntervalSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tk = tkOf(context);
    final l = l10nOf(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tk.textSecondary),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: tk.accent.withValues(alpha: .13),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                l.intervalSeconds(value),
                style: GoogleFonts.rubik(fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: tk.accent,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min,
          max: max,
          divisions: (max - min).round(),
          label: l.intervalSeconds(value),
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  final bool ok;
  final String label;
  final String downLabel;
  const _StatusDot({required this.ok, required this.label, required this.downLabel});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ok ? Semantic.success : Semantic.danger,
            boxShadow: [BoxShadow(color: Semantic.success.withValues(alpha: .5), blurRadius: 6)],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          ok ? label : downLabel,
          style: TextStyle(fontSize: 11.5, color: tkOf(context).textTertiary),
        ),
      ],
    );
  }
}
