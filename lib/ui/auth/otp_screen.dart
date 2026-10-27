import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/l10n_text.dart';
import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../services/mock_auth_service.dart';
import '../widgets/common.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with SingleTickerProviderStateMixin {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _nodes = List.generate(6, (_) => FocusNode());
  bool _busy = false;
  bool _error = false;
  int _resendIn = 30;
  Timer? _timer;

  /// shake feedback for a wrong code
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  @override
  void initState() {
    super.initState();
    _tickResend();
  }

  void _tickResend() {
    _timer?.cancel();
    _resendIn = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _resendIn = math.max(0, _resendIn - 1));
      if (_resendIn == 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shake.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_code.length < 6) return;
    setState(() {
      _busy = true;
      _error = false;
    });
    final auth = context.read<AuthService>();
    await Future.delayed(const Duration(milliseconds: 650)); // demo latency
    final ok = await auth.verifyOtp(_code);
    if (!mounted) return;
    if (ok) {
      Navigator.pushNamedAndRemoveUntil(context, '/connect', (_) => false);
    } else {
      setState(() {
        _busy = false;
        _error = true;
      });
      _shake.forward(from: 0); // error micro-interaction: shake the boxes
    }
  }

  Future<void> _resend() async {
    await context.read<AuthService>().resendOtp();
    _tickResend();
    for (final c in _controllers) {
      c.clear();
    }
    _nodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final tk = tkOf(context);
    final l = l10nOf(context);
    final auth = context.watch<AuthService>();
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 8, 26, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tk.card,
                  border: Border.all(color: tk.stroke),
                ),
                child: Icon(Icons.mark_email_unread_outlined, size: 30, color: tk.accent),
              ),
              const SizedBox(height: 26),
              Text(
                l.otpTitle,
                style: GoogleFonts.rubik(fontSize: 27,
                  fontWeight: FontWeight.w700,
                  color: tk.textPrimary,
                  letterSpacing: -.7,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.otpSentTo(auth.pendingEmail ?? l.otpFallbackEmail),
                style: TextStyle(fontSize: 14, color: tk.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 30),
              // OTP boxes — shake horizontally when the code is wrong
              AnimatedBuilder(
                animation: _shake,
                builder: (context, child) {
                  final t = _shake.value;
                  final dx = t == 0 ? 0.0 : math.sin(t * math.pi * 3) * (1 - t) * 12;
                  return Transform.translate(offset: Offset(dx, 0), child: child!);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (i) => _box(i)),
                ),
              ),
              if (_error) ...[
                const SizedBox(height: 14),
                Text(
                  l.otpIncorrect,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: Semantic.danger),
                ),
              ],
              const SizedBox(height: 28),
              GradientButton(
                label: _busy ? l.otpVerifying : l.otpVerify,
                icon: Icons.shield_outlined,
                onTap: (_busy || _code.length < 6) ? null : _verify,
              ),
              const SizedBox(height: 14),
              Center(
                child: _resendIn > 0
                    ? Text(
                        l.otpResendIn(_resendIn),
                        style: TextStyle(fontSize: 13, color: tk.textTertiary),
                      )
                    : TextButton(onPressed: _resend, child: Text(l.otpResend)),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: SmartBlue.c600.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: SmartBlue.c600.withValues(alpha: .35)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.science_rounded, size: 17, color: tk.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        auth.demoOtp != null
                            ? l.otpDemoHint(auth.demoOtp!)
                            : l.otpDemoNoCode,
                        style: GoogleFonts.rubik(
                          fontSize: 12.5,
                          color: tk.textSecondary,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (auth.demoOtp != null)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.copy_rounded, size: 16, color: tk.accent),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: auth.demoOtp!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l.codeCopied)),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _box(int i) {
    final tk = tkOf(context);
    return SizedBox(
      width: 48,
      height: 58,
      child: TextField(
        controller: _controllers[i],
        focusNode: _nodes[i],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: GoogleFonts.rubik(fontSize: 22,
          fontWeight: FontWeight.w700,
          color: _error ? Semantic.danger : tk.textPrimary,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          errorStyle: const TextStyle(height: 0),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide(color: _error ? Semantic.danger : tk.stroke),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide(color: _error ? Semantic.danger : tk.accent, width: 1.6),
          ),
        ),
        onChanged: (v) {
          if (v.isNotEmpty && i < 5) {
            _nodes[i + 1].requestFocus();
          } else if (v.isEmpty && i > 0) {
            _nodes[i - 1].requestFocus();
          }
          if (_code.length == 6) FocusScope.of(context).unfocus();
          setState(() {});
        },
      ),
    );
  }
}
