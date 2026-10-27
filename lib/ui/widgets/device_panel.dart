import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/l10n_text.dart';
import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../services/ble/esp32_ble_service.dart';

/// Bottom sheet for the real ESP32 module: link status, firmware command
/// shortcuts (the exact interpreter from `main/commands.c`), drive-mode
/// controls and the live module response log.
class DevicePanel {
  static Future<void> show(BuildContext context, {required Esp32BleService ble}) {
    final tk = tkOf(context);
    final l = l10nOf(context);
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AnimatedBuilder(
        animation: ble,
        builder: (ctx, _) => Container(
          decoration: BoxDecoration(
            color: tk.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: tk.stroke)),
          ),
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: tk.stroke,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.bluetooth_rounded, size: 20, color: tk.accent),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        l.devicePanelTitle,
                        style: GoogleFonts.rubik(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: tk.textPrimary,
                        ),
                      ),
                    ),
                    _PhaseChip(phase: ble.phase),
                  ],
                ),
                const SizedBox(height: 14),
                _InfoRow(ble: ble),
                const SizedBox(height: 16),

                // Read-only diagnostics — safe in any mode.
                _Section('GATT'),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: [
                    _CmdButton(label: 'PING', enabled: ble.isConnected, onTap: () => ble.sendCommand('PING')),
                    _CmdButton(label: 'VER', enabled: ble.isConnected, onTap: () => ble.sendCommand('VER')),
                    _CmdButton(label: 'STAT', enabled: ble.isConnected, onTap: () => ble.sendCommand('STAT')),
                    _CmdButton(label: 'GET ALL', enabled: ble.isConnected, onTap: () => ble.sendCommand('GET ALL')),
                  ],
                ),
                const SizedBox(height: 16),

                // Follow-car drive controls (firmware MODE/ARM interpreter).
                _Section(l.deviceStatus),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: [
                    _CmdButton(label: 'MODE IDLE', enabled: ble.isConnected, onTap: () => ble.sendCommand('MODE IDLE')),
                    _CmdButton(label: 'MODE FOLLOW', enabled: ble.isConnected, onTap: () => ble.sendCommand('MODE FOLLOW')),
                    _CmdButton(label: 'MODE MANUAL', enabled: ble.isConnected, onTap: () => ble.sendCommand('MODE MANUAL')),
                    _CmdButton(label: 'ARM ON', enabled: ble.isConnected, onTap: () => ble.sendCommand('ARM ON')),
                    _CmdButton(label: 'ARM OFF', enabled: ble.isConnected, onTap: () => ble.sendCommand('ARM OFF')),
                  ],
                ),
                const SizedBox(height: 16),

                // Response log.
                _Section(l.deviceResponseLog),
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tk.bgDeep,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: tk.stroke.withValues(alpha: .6)),
                  ),
                  child: ble.responseLog.isEmpty
                      ? Text(
                          l.deviceEmptyLog,
                          style: TextStyle(fontSize: 11.5, color: tk.textTertiary),
                        )
                      : ListView(
                          shrinkWrap: true,
                          children: [
                            for (final line in ble.responseLog.reversed.take(12))
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  line,
                                  style: GoogleFonts.rubik(
                                    fontSize: 11,
                                    color: line.startsWith(RegExp(r'.*E \d'))
                                        ? Semantic.danger
                                        : tk.textSecondary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: ble.isConnected
                            ? () => ble.disconnect()
                            : () => ble.retry(),
                        icon: Icon(ble.isConnected ? Icons.link_off_rounded : Icons.refresh_rounded, size: 18),
                        label: Text(ble.isConnected ? l.deviceDisconnect : l.deviceReconnect),
                      ),
                    ),
                    if (ble.savedDeviceId != null) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => ble.forgetDevice(),
                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
                          label: Text(l.connectForget),
                          style: OutlinedButton.styleFrom(foregroundColor: Semantic.danger),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  const _Section(this.label);
  @override
  Widget build(BuildContext context) {
    final tk = tkOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.rubik(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          color: tk.textTertiary,
        ),
      ),
    );
  }
}

class _CmdButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const _CmdButton({required this.label, required this.enabled, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : .45,
      child: FilledButton.tonal(
        onPressed: enabled ? onTap : null,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          visualDensity: VisualDensity.compact,
        ),
        child: Text(
          label,
          style: GoogleFonts.rubik(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _PhaseChip extends StatelessWidget {
  final BlePhase phase;
  const _PhaseChip({required this.phase});
  @override
  Widget build(BuildContext context) {
    final connected = phase == BlePhase.connected;
    final busy = phase == BlePhase.connecting ||
        phase == BlePhase.pairing ||
        phase == BlePhase.discovering ||
        phase == BlePhase.reconnecting ||
        phase == BlePhase.scanning;
    final color = connected
        ? Semantic.success
        : busy
            ? Semantic.warning
            : tkOf(context).textTertiary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          phase.name,
          style: GoogleFonts.rubik(fontSize: 11, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final Esp32BleService ble;
  const _InfoRow({required this.ble});
  @override
  Widget build(BuildContext context) {
    final tk = tkOf(context);
    final frame = ble.lastFrame;
    final items = <(String, String)>[
      ('ID', ble.connectedId ?? ble.savedDeviceId ?? '—'),
      ('RSSI', frame == null ? '—' : '${frame.rssi} dBm'),
      ('DIST', frame == null ? '—' : '${frame.distanceM.toStringAsFixed(2)} m'),
      ('BRG', frame?.bearingDeg == null ? '—' : '${frame!.bearingDeg!.round()}° (${frame.confidence}%)'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (k, v) in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: tk.bgDeep,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: tk.stroke.withValues(alpha: .6)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  k,
                  style: GoogleFonts.rubik(fontSize: 10, fontWeight: FontWeight.w700, color: tk.textTertiary),
                ),
                const SizedBox(width: 7),
                Text(
                  v,
                  style: GoogleFonts.rubik(fontSize: 11.5, fontWeight: FontWeight.w600, color: tk.textPrimary),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
