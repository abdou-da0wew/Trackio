import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/l10n_text.dart';
import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../services/ble/ble_permissions.dart';
import '../../services/ble/ble_profile.dart';
import '../../services/ble/esp32_ble_service.dart';
import '../../services/tracking/tracking_controller.dart';
import '../widgets/common.dart';

/// Device-connection gate. The normal post-login route: the app runs on
/// the live BLE engine, and this screen establishes the bonded link to
/// the ESP32 module before the tracking shell opens.
class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  bool _permissionOk = true;
  bool _autoRouted = false;

  @override
  void initState() {
    super.initState();
    _refreshPermission();
  }

  Future<void> _refreshPermission() async {
    final ok = await BlePermissions.isGranted;
    if (mounted) setState(() => _permissionOk = ok);
  }

  Future<void> _requestPermission() async {
    final ok = await BlePermissions.requestScan();
    if (!mounted) return;
    setState(() => _permissionOk = ok);
    if (ok) _startScan();
  }

  Future<void> _startScan() async {
    final ble = context.read<Esp32BleService>();
    final ok = await BlePermissions.requestScan();
    if (!mounted) return;
    setState(() => _permissionOk = ok);
    if (ok) await ble.startScan();
  }

  void _openShell() {
    Navigator.pushNamedAndRemoveUntil(context, '/shell', (_) => false);
  }

  void _useSimulation() {
    context.read<TrackingController>().useSimulation();
    _openShell();
  }

  @override
  Widget build(BuildContext context) {
    final tk = tkOf(context);
    final l = l10nOf(context);
    final ble = context.watch<Esp32BleService>();

    // Auto-enter the shell once the live link is established.
    if (ble.isConnected && !_autoRouted) {
      _autoRouted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _openShell());
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
          children: [
            const TkWordmark(size: 24),
            const SizedBox(height: 26),
            Icon(Icons.bluetooth_searching_rounded, size: 44, color: tk.accent),
            const SizedBox(height: 14),
            Text(
              l.connectTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.rubik(
                fontSize: 23,
                fontWeight: FontWeight.w700,
                color: tk.textPrimary,
                letterSpacing: -.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.connectSubtitle(BleProfile.deviceNamePrefix),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.5, color: tk.textSecondary),
            ),
            const SizedBox(height: 22),

            _PasskeyCard(),
            const SizedBox(height: 18),

            // ── phase-specific body ──
            if (ble.phase == BlePhase.unsupported)
              _MessageCard(
                icon: Icons.bluetooth_disabled_rounded,
                color: Semantic.warning,
                title: l.connectUnsupported,
              )
            else if (ble.phase == BlePhase.bluetoothOff)
              _MessageCard(
                icon: Icons.bluetooth_disabled_rounded,
                color: Semantic.warning,
                title: l.connectBluetoothOff,
                actionLabel: l.connectTurnOn,
                onAction: () => ble.requestEnableBluetooth(),
              )
            else if (!_permissionOk)
              _MessageCard(
                icon: Icons.lock_outline_rounded,
                color: Semantic.warning,
                title: l.connectPermissionTitle,
                actionLabel: l.connectGrantPermission,
                onAction: _requestPermission,
              )
            else ...[
              _ProgressSection(ble: ble, l: l),
              const SizedBox(height: 16),
              _ScanList(ble: ble, onScan: _startScan),
            ],

            const SizedBox(height: 22),
            if (ble.savedDeviceId != null && !ble.isConnected)
              TextButton.icon(
                onPressed: () => ble.forgetDevice(),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: Text(l.connectForget),
                style: TextButton.styleFrom(foregroundColor: Semantic.danger),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _useSimulation,
              icon: const Icon(Icons.science_rounded, size: 19),
              label: Text(l.connectContinueSim),
            ),
            const SizedBox(height: 8),
            Text(
              l.connectSimNote,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: tk.textTertiary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

/// Static passkey reminder — the OS pairing dialog asks for this number.
class _PasskeyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tk = tkOf(context);
    final l = l10nOf(context);
    return TkCard(
      color: tk.bgDeep,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tk.accent.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.key_rounded, color: tk.accent, size: 21),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.connectPasskeyTitle,
                  style: GoogleFonts.rubik(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: tk.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l.connectPasskeyBody(BleProfile.pairingPasskey),
                  style: TextStyle(fontSize: 11.5, color: tk.textTertiary, height: 1.35),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: tk.card,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: tk.stroke),
            ),
            child: Text(
              BleProfile.pairingPasskey,
              style: GoogleFonts.rubik(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                color: tk.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Connecting / pairing / reconnecting / connected status block.
class _ProgressSection extends StatelessWidget {
  final Esp32BleService ble;
  final AppLocalizations l;
  const _ProgressSection({required this.ble, required this.l});

  @override
  Widget build(BuildContext context) {
    final tk = tkOf(context);
    final busy = ble.phase == BlePhase.scanning ||
        ble.phase == BlePhase.connecting ||
        ble.phase == BlePhase.pairing ||
        ble.phase == BlePhase.discovering ||
        ble.phase == BlePhase.reconnecting;

    final (icon, title, color) = switch (ble.phase) {
      BlePhase.connected => (Icons.verified_rounded, l.connectConnected, Semantic.success),
      BlePhase.pairing => (Icons.key_rounded, l.connectPairing, tk.accent),
      BlePhase.connecting || BlePhase.discovering =>
        (Icons.bluetooth_rounded, l.connectConnecting(ble.connectedName ?? BleProfile.deviceNamePrefix), tk.accent),
      BlePhase.reconnecting =>
        (Icons.sync_problem_rounded, l.connectReconnecting(ble.reconnectAttempts), Semantic.warning),
      _ => (Icons.radar_rounded, l.connectSearchHint, tk.textSecondary),
    };

    return TkCard(
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: busy
                ? CircularProgressIndicator(strokeWidth: 2.4, color: color)
                : Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.rubik(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: tk.textPrimary,
                  ),
                ),
                if (ble.errorMessage != null &&
                    ble.errorMessage != 'reconnect_exhausted') ...[
                  const SizedBox(height: 3),
                  Text(
                    ble.errorMessage!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Semantic.danger),
                  ),
                ],
              ],
            ),
          ),
          if (ble.isConnected)
            GradientButton(
              label: l.connectOpenTracker,
              height: 42,
              onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/shell', (_) => false),
            ),
          if (ble.phase == BlePhase.idle && ble.savedDeviceId != null)
            OutlinedButton(
              onPressed: () => ble.retry(),
              child: Text(l.connectRetry),
            ),
        ],
      ),
    );
  }
}

/// Live scan results + scan control.
class _ScanList extends StatelessWidget {
  final Esp32BleService ble;
  final VoidCallback onScan;
  const _ScanList({required this.ble, required this.onScan});

  @override
  Widget build(BuildContext context) {
    final tk = tkOf(context);
    final l = l10nOf(context);
    final scanning = ble.phase == BlePhase.scanning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ble.savedDeviceId != null && ble.connectedName != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              l.connectLastModule(ble.connectedName!),
              style: TextStyle(fontSize: 11.5, color: tk.textTertiary),
            ),
          ),
        GradientButton(
          label: scanning ? l.connectScanning : l.connectScan,
          icon: scanning ? null : Icons.refresh_rounded,
          onTap: scanning ? null : onScan,
        ),
        const SizedBox(height: 14),
        if (ble.scanResults.isEmpty && !scanning)
          _EmptyScan(ble: ble)
        else
          TkCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                for (final d in ble.scanResults)
                  ListTile(
                    enabled: !scanning &&
                        ble.phase != BlePhase.connecting &&
                        ble.phase != BlePhase.pairing,
                    leading: const Icon(Icons.bluetooth_rounded),
                    title: Text(
                      d.name,
                      style: GoogleFonts.rubik(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: tk.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      d.id,
                      style: TextStyle(fontSize: 10.5, color: tk.textTertiary),
                    ),
                    trailing: Text(
                      '${d.rssi} dBm',
                      style: GoogleFonts.rubik(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tk.textSecondary,
                      ),
                    ),
                    onTap: () => ble.connectDevice(d),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _EmptyScan extends StatelessWidget {
  final Esp32BleService ble;
  const _EmptyScan({required this.ble});
  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final tk = tkOf(context);
    return TkCard(
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, color: tk.textTertiary, size: 30),
          const SizedBox(height: 10),
          Text(l.connectNoDevices,
              style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w700, color: tk.textSecondary)),
          const SizedBox(height: 4),
          Text(
            l.connectNoDevicesHint,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: tk.textTertiary, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _MessageCard({
    required this.icon,
    required this.color,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return TkCard(
      child: Column(
        children: [
          Icon(icon, color: color, size: 34),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.rubik(fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 14),
            GradientButton(label: actionLabel!, onTap: onAction),
          ],
        ],
      ),
    );
  }
}
