import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/formatters.dart';
import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/mock_auth_service.dart';
import '../../services/settings_service.dart';
import '../../services/simulation_engine.dart';
import '../../services/sound_service.dart';
import '../widgets/common.dart';
import '../widgets/map_markers.dart';
import '../widgets/radar_view.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback onGoMap;
  final VoidCallback onDemo;
  const DashboardScreen({super.key, required this.onGoMap, required this.onDemo});

  @override
  Widget build(BuildContext context) {
    final tk = tkOf(context);
    final engine = context.watch<SimulationEngine>();
    final auth = context.watch<AuthService>();
    final settings = context.read<SettingsService>();
    final sound = context.read<SoundService>();
    final st = StatusTheme.of(engine.status);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
          children: [
            // header
            Row(
              children: [
                const TkWordmark(size: 24),
                const Spacer(),
                _Avatar(name: auth.user?.name ?? 'Demo User'),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _greeting(auth.user?.name ?? 'there'),
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 23,
                fontWeight: FontWeight.w700,
                color: tk.textPrimary,
                letterSpacing: -.5,
              ),
            ),
            const SizedBox(height: 18),

            // hero radar card
            TkCard(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [tk.card, Prussian3.c200]
                    : [Colors.white, SmartBlue.c900.withValues(alpha: .45)],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      StatusPill(status: engine.status, pulse: engine.inDanger || engine.status == TrackStatus.tracking),
                      const Spacer(),
                      Text(
                        'updated ${Fmt.ago(engine.lastPhoneFix, DateTime.now())}',
                        style: TextStyle(fontSize: 11.5, color: tk.textTertiary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 205,
                    child: RadarView(
                      distanceM: engine.distance,
                      statusColor: st.color,
                      panic: engine.inDanger,
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -18),
                    child: Column(
                      children: [
                        Text(
                          Fmt.distance(engine.distance),
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 46,
                            height: 1,
                            fontWeight: FontWeight.w700,
                            color: tk.textPrimary,
                            letterSpacing: -1.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          engine.connectionCut
                              ? 'radio link down · retrying (${engine.radioRetries})'
                              : 'from your bag · fused GPS + ESP32 radio',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: engine.connectionCut ? Semantic.warning : tk.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      MetricChip(
                        icon: Icons.battery_5_bar_rounded,
                        label: '${engine.bag.batteryPct.round()}%',
                        tint: engine.bag.batteryPct < 20 ? Semantic.warning : tk.textSecondary,
                      ),
                      MetricChip(
                        icon: Icons.wifi_tethering_rounded,
                        label: engine.connectionCut ? 'link lost' : Fmt.rssi(engine.bag.rssi),
                        tint: engine.connectionCut ? Semantic.danger : null,
                      ),
                      MetricChip(
                        icon: Icons.gps_fixed_rounded,
                        label: engine.bagAccuracyM < 0 ? 'no fix' : '±${engine.bagAccuracyM.toStringAsFixed(1)} m',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // quick actions
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.travel_explore_rounded,
                    label: 'Locate bag',
                    onTap: onGoMap,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.notifications_active_rounded,
                    label: 'Ring tag',
                    onTap: () async {
                      await sound.playAlert(settings.sound);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Playing ${settings.sound.label} on the bag module')),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.science_rounded,
                    label: 'Demo mode',
                    onTap: onDemo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // mini map preview
            SectionLabel(
              'LIVE POSITION',
              trailing: GestureDetector(
                onTap: onGoMap,
                child: Row(
                  children: [
                    Text('Open map', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: tk.accent)),
                    Icon(Icons.chevron_right_rounded, size: 17, color: tk.accent),
                  ],
                ),
              ),
            ),
            TkCard(
              padding: EdgeInsets.zero,
              radius: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 158,
                  child: _MiniMap(engine: engine, dark: settings.themeDark),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // recent activity
            const SectionLabel('RECENT ACTIVITY'),
            ...engine.events.reversed.take(3).map(
                  (e) => EventTile(event: e),
                ),
          ],
        ),
      ),
    );
  }

  String _greeting(String name) {
    final h = DateTime.now().hour;
    final first = name.split(' ').first;
    if (h < 12) return 'Good morning, $first';
    if (h < 18) return 'Good afternoon, $first';
    return 'Good evening, $first';
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});
  @override
  Widget build(BuildContext context) {
    final tk = tkOf(context);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'T';
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: tk.ctaGradient),
      ),
      child: Text(
        initial,
        style: const TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tk = tkOf(context);
    return TkCard(
      padding: const EdgeInsets.symmetric(vertical: 15),
      radius: 17,
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 21, color: tk.accent),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: tk.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMap extends StatelessWidget {
  final SimulationEngine engine;
  final bool dark;
  const _MiniMap({required this.engine, required this.dark});

  @override
  Widget build(BuildContext context) {
    final url = dark
        ? 'https://services.arcgisonline.com/arcgis/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}'
        : 'https://services.arcgisonline.com/arcgis/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}';
    final mid = LatLng(
      (engine.phonePos.latitude + engine.bagPos.latitude) / 2,
      (engine.phonePos.longitude + engine.bagPos.longitude) / 2,
    );
    return AnimatedBuilder(
      animation: engine,
      builder: (context, _) => FlutterMap(
        options: MapOptions(
          initialCenter: mid,
          initialZoom: 16.4,
          interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
        ),
        children: [
          TileLayer(
            urlTemplate: url,
            userAgentPackageName: 'app.trackio.demo',
          ),
          PolylineLayer(
            polylines: [
              Polyline(points: engine.phoneRoute.toList(), strokeWidth: 3, color: SmartBlue.c600),
              Polyline(
                points: [engine.phonePos, engine.bagPos],
                strokeWidth: 1.6,
                color: Colors.white70,
                pattern: StrokePattern.dashed(segments: [5, 6]),
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              PhoneDotMarker(engine.phonePos),
              BagPinMarker(engine.bagPos, engine.status),
            ],
          ),
        ],
      ),
    );
  }
}

/// Reusable event tile (dashboard + history).
class EventTile extends StatelessWidget {
  final TrackEvent event;
  const EventTile({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final tk = tkOf(context);
    final (icon, color) = _style(event.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: tk.card,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: tk.stroke.withValues(alpha: .6)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.type.label,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: tk.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: tk.textTertiary, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            Fmt.clock(event.time),
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 11,
              color: tk.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  static (IconData, Color) _style(TrackEventType t) => switch (t) {
        TrackEventType.locationUpdate => (Icons.gps_fixed_rounded, SmartBlue.c600),
        TrackEventType.warning => (Icons.warning_amber_rounded, Semantic.warning),
        TrackEventType.lost => (Icons.location_off_rounded, Semantic.danger),
        TrackEventType.panicSent => (Icons.crisis_alert_rounded, Semantic.danger),
        TrackEventType.connectionLost => (Icons.link_off_rounded, Semantic.warning),
        TrackEventType.reconnect => (Icons.link_rounded, Sapphire.c700),
        TrackEventType.recovered => (Icons.navigation_rounded, Sapphire.c700),
        TrackEventType.found => (Icons.verified_rounded, Semantic.success),
      };
}
