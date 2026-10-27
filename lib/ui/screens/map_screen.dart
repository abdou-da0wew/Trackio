import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/formatters.dart';
import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../core/l10n_text.dart';
import '../../services/settings_service.dart';
import '../../services/simulation_engine.dart';
import '../../services/tracking/tracking_controller.dart';
import '../../services/tracking/tracking_engine.dart';
import '../widgets/common.dart';
import '../widgets/map_markers.dart';
import '../widgets/relative_radar_map.dart';

class MapScreen extends StatefulWidget {
  final VoidCallback onDemo;
  const MapScreen({super.key, required this.onDemo});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TrackingController>();
    final engine = controller.engine;
    return engine.isLive
        ? _RelativeMapScaffold(engine: engine, onDemo: widget.onDemo)
        : _GeoMapScaffold(
            engine: engine as SimulationEngine,
            onDemo: widget.onDemo,
          );
  }
}

/// Live BLE source: polar radar — the module reports no GPS coordinates.
class _RelativeMapScaffold extends StatelessWidget {
  final TrackingEngine engine;
  final VoidCallback onDemo;
  const _RelativeMapScaffold({required this.engine, required this.onDemo});

  @override
  Widget build(BuildContext context) {
    final tk = tkOf(context);
    final l = l10nOf(context);
    final st = StatusTheme.of(engine.status);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: engine,
              builder: (context, _) => RelativeRadarMap(
                distanceM: engine.distance,
                bearingDeg: engine.bearingDeg,
                confidence: engine.bearingConfidence,
                statusColor: st.color,
                panic: engine.inDanger,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: engine,
                    builder: (context, _) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: tk.card.withValues(alpha: .94),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: tk.stroke),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .25), blurRadius: 18)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StatusPill(status: engine.status, pulse: engine.inDanger),
                          const SizedBox(width: 10),
                          Text(
                            l.dist(engine.distance),
                            style: GoogleFonts.rubik(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: tk.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton2(
                    icon: Icons.bluetooth_rounded,
                    bg: tk.card.withValues(alpha: .94),
                    onTap: onDemo,
                    tooltip: l.devicePanelTitle,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _LiveBagCard(engine: engine),
          ),
        ],
      ),
    );
  }
}

/// Simulation source: the original geographic Esri-tile map.
class _GeoMapScaffold extends StatefulWidget {
  final SimulationEngine engine;
  final VoidCallback onDemo;
  const _GeoMapScaffold({required this.engine, required this.onDemo});

  @override
  State<_GeoMapScaffold> createState() => _GeoMapScaffoldState();
}

class _GeoMapScaffoldState extends State<_GeoMapScaffold> {
  final MapController _map = MapController();
  bool _follow = false;

  void _fitBoth(SimulationEngine e) {
    _map.fitCamera(
      CameraFit.coordinates(
        coordinates: [e.phonePos, e.bagPos],
        padding: const EdgeInsets.fromLTRB(70, 130, 70, 210),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tk = tkOf(context);
    final l = l10nOf(context);
    final engine = widget.engine;
    final settings = context.watch<SettingsService>();
    final st = StatusTheme.of(engine.status);
    final dark = settings.themeDark;

    // follow mode: keep phone centred as the sim walks
    if (_follow && !engine.inDanger) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _map.move(engine.phonePos, _map.camera.zoom, id: 'follow');
      });
    }

    final url = dark
        ? 'https://services.arcgisonline.com/arcgis/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}'
        : 'https://services.arcgisonline.com/arcgis/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}';

    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: engine,
            builder: (context, _) => FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: engine.phonePos,
                initialZoom: 16.2,
                minZoom: 3,
                maxZoom: 18.5,
                onMapEvent: (_) {
                  if (_follow) setState(() => _follow = false);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: url,
                  userAgentPackageName: 'app.trackio',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: engine.phoneRoute.toList(),
                      strokeWidth: 3.6,
                      color: SmartBlue.c600.withValues(alpha: .9),
                      pattern: const StrokePattern.dotted(),
                    ),
                    Polyline(
                      points: engine.bagRoute.toList(),
                      strokeWidth: 2.6,
                      color: Prussian3.c800.withValues(alpha: .75),
                    ),
                    Polyline(
                      points: [engine.phonePos, engine.bagPos],
                      strokeWidth: 1.8,
                      color: st.color,
                      pattern: StrokePattern.dashed(segments: [7, 7]),
                    ),
                  ],
                ),
                CircleLayer(
                  circles: [
                    if (engine.bagAccuracyM > 0)
                      CircleMarker(
                        point: engine.bagPos,
                        radius: engine.bagAccuracyM,
                        useRadiusInMeter: true,
                        color: st.color.withValues(alpha: .10),
                        borderColor: st.color.withValues(alpha: .45),
                        borderStrokeWidth: 1.4,
                      ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    if (engine.inDanger) PanicPulseMarker(engine.bagPos),
                    DistanceLabelMarker(
                      LatLng(
                        (engine.phonePos.latitude + engine.bagPos.latitude) / 2,
                        (engine.phonePos.longitude + engine.bagPos.longitude) / 2,
                      ),
                      l.dist(engine.distance),
                      color: st.color,
                    ),
                    BagPinMarker(engine.bagPos, engine.status),
                    PhoneDotMarker(engine.phonePos),
                  ],
                ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('Esri · © OpenStreetMap contributors'),
                  ],
                  showFlutterMapAttribution: false,
                ),
              ],
            ),
          ),

          // top status bar (+ connection-lost error banner)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: engine.connectionCut
                        ? Container(
                            key: const ValueKey('linkDown'),
                            margin: const EdgeInsets.only(top: 52),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Semantic.warning.withValues(alpha: .16),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Semantic.warning.withValues(alpha: .55)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.link_off_rounded, size: 15, color: Semantic.warning),
                                const SizedBox(width: 7),
                                Text(
                                  l.mapSignalLost(engine.radioRetries),
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Semantic.warning),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('linkOk')),
                  ),
                  Row(
                children: [
                  AnimatedBuilder(
                    animation: engine,
                    builder: (context, _) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: tk.card.withValues(alpha: .94),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: tk.stroke),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: .25), blurRadius: 18),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StatusPill(status: engine.status, pulse: engine.inDanger),
                          const SizedBox(width: 10),
                          Text(
                            l.dist(engine.distance),
                            style: GoogleFonts.rubik(fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: tk.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton2(
                    icon: Icons.science_rounded,
                    bg: tk.card.withValues(alpha: .94),
                    onTap: widget.onDemo,
                    tooltip: l.mapTooltipDemo,
                  ),
                ],
              ),
                ],
              ),
            ),
          ),

          // right-side map controls
          Positioned(
            right: 14,
            bottom: 118,
            child: Column(
              children: [
                IconButton2(
                  icon: Icons.my_location_rounded,
                  bg: tk.card.withValues(alpha: .94),
                  onTap: () {
                    setState(() => _follow = true);
                    _map.move(engine.phonePos, _map.camera.zoom > 15.5 ? _map.camera.zoom : 16.4, id: 'phone');
                  },
                  tooltip: l.tooltipFollow,
                ),
                const SizedBox(height: 10),
                IconButton2(
                  icon: Icons.backpack_rounded,
                  bg: tk.card.withValues(alpha: .94),
                  onTap: () => _map.move(engine.bagPos, _map.camera.zoom > 15.5 ? _map.camera.zoom : 16.4, id: 'bag'),
                  tooltip: l.tooltipCenterBag,
                ),
                const SizedBox(height: 10),
                IconButton2(
                  icon: Icons.fit_screen_rounded,
                  bg: tk.card.withValues(alpha: .94),
                  onTap: () => _fitBoth(engine),
                  tooltip: l.tooltipFitBoth,
                ),
              ],
            ),
          ),

          // bottom bag card
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _LiveBagCard(engine: engine),
          ),
        ],
      ),
    );
  }
}

/// Bottom module card shared by both map sources.
class _LiveBagCard extends StatelessWidget {
  final TrackingEngine engine;
  const _LiveBagCard({required this.engine});

  @override
  Widget build(BuildContext context) {
    final tk = tkOf(context);
    final l = l10nOf(context);
    final st = StatusTheme.of(engine.status);
    return TkCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: AnimatedBuilder(
        animation: engine,
        builder: (context, _) {
          final b = engine.bag;
          final subtitle = engine.isLive
              ? (engine.connectionCut
                  ? l.mapSignalLost(engine.radioRetries)
                  : [
                      Fmt.rssi(b.rssi),
                      if (engine.bearingDeg != null) '${l.bleBearing} ${engine.bearingDeg!.round()}°',
                      if (engine.bearingConfidence > 0) '${l.bleConfidence} ${engine.bearingConfidence}%',
                      l.bleWiredPower,
                    ].join('  ·  '))
              : l.bagFixLine(
                  engine.bagAccuracyM < 0 ? '—' : engine.bagAccuracyM.toStringAsFixed(1),
                  Fmt.rssi(b.rssi),
                  b.batteryPct.round(),
                );
          return Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: st.color.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.bluetooth_rounded, color: st.color, size: 22),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.name,
                      style: GoogleFonts.rubik(fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: tk.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: tk.textTertiary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              IconButton2(
                icon: Icons.notifications_active_rounded,
                fg: tk.accent,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.buzzQueued)),
                ),
                tooltip: l.ringTag,
              ),
            ],
          );
        },
      ),
    );
  }
}
