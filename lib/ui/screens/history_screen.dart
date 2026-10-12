import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/formatters.dart';
import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/simulation_engine.dart';
import '../widgets/common.dart';
import '../screens/dashboard_screen.dart' show EventTile;

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tk = tkOf(context);
    final engine = context.watch<SimulationEngine>();

    final lostEvents = engine.events.where((e) => e.type == TrackEventType.lost).length;
    final avg = engine.distanceHistory.isEmpty
        ? 0.0
        : engine.distanceHistory.map((s) => s.meters).reduce((a, b) => a + b) /
            engine.distanceHistory.length;

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 26),
        children: [
          // summary
          Row(
            children: [
              Expanded(
                child: _Summary(
                  label: 'LOSS ALERTS',
                  value: '$lostEvents',
                  icon: Icons.crisis_alert_rounded,
                  color: Semantic.danger,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Summary(
                  label: 'AVG DISTANCE',
                  value: Fmt.distance(avg),
                  icon: Icons.straighten_rounded,
                  color: SmartBlue.c600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Summary(
                  label: 'DATA POINTS',
                  value: '${engine.distanceHistory.length}',
                  icon: Icons.query_stats_rounded,
                  color: Sapphire.c700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SectionLabel('DISTANCE TIMELINE'),
          TkCard(
            padding: const EdgeInsets.fromLTRB(14, 18, 18, 10),
            child: SizedBox(
              height: 190,
              child: _DistanceChart(samples: engine.distanceHistory),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legend(color: SmartBlue.c600, label: 'safe range'),
              const SizedBox(width: 18),
              _Legend(color: Semantic.danger, label: 'loss events'),
            ],
          ),
          const SizedBox(height: 22),
          SectionLabel('EVENT LOG'),
          if (engine.events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Text(
                'No events yet — start the demo scenario.',
                textAlign: TextAlign.center,
                style: TextStyle(color: tk.textTertiary, fontSize: 13),
              ),
            )
          else
            ...engine.events.reversed.take(60).map((e) => EventTile(event: e)),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _Summary({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final tk = tkOf(context);
    return TkCard(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.rubik(fontSize: 19,
              fontWeight: FontWeight.w700,
              color: tk.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 9, letterSpacing: 1.1, fontWeight: FontWeight.w700, color: tk.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 11.5, color: tkOf(context).textTertiary)),
      ],
    );
  }
}

class _DistanceChart extends StatelessWidget {
  final List<DistanceSample> samples;
  const _DistanceChart({required this.samples});

  @override
  Widget build(BuildContext context) {
    final tk = tkOf(context);
    if (samples.length < 2) {
      return Center(
        child: Text(
          'Collecting tracking data…',
          style: TextStyle(color: tk.textTertiary, fontSize: 12.5),
        ),
      );
    }
    final shown = samples.length > 90 ? samples.sublist(samples.length - 90) : samples;
    final spots = <FlSpot>[
      for (var i = 0; i < shown.length; i++)
        FlSpot(i.toDouble(), shown[i].meters),
    ];
    final maxY = (spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.25)
        .clamp(30.0, double.infinity);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (v) => FlLine(
            color: tk.stroke.withValues(alpha: .5),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: shown.length / 4,
              getTitlesWidget: (v, meta) {
                final idx = v.toInt().clamp(0, shown.length - 1);
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    Fmt.clock(shown[idx].time),
                    style: TextStyle(fontSize: 9.5, color: tk.textTertiary),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              interval: maxY / 4,
              getTitlesWidget: (v, meta) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  '${v.round()}m',
                  style: TextStyle(fontSize: 9.5, color: tk.textTertiary),
                ),
              ),
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => tk.bgDeep,
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      '${s.y.round()} m',
                      GoogleFonts.rubik(color: tk.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ))
                .toList(),
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: SimulationEngine.lostM,
              color: Semantic.danger.withValues(alpha: .55),
              strokeWidth: 1.2,
              dashArray: [6, 5],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                style: TextStyle(fontSize: 9, color: Semantic.danger, fontWeight: FontWeight.w700),
                labelResolver: (_) => 'loss limit',
              ),
            ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: .3,
            preventCurveOverShooting: true,
            barWidth: 2.4,
            color: SmartBlue.c600,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  SmartBlue.c600.withValues(alpha: .28),
                  SmartBlue.c600.withValues(alpha: .02),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
