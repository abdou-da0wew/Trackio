import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/l10n_text.dart';
import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../services/mock_auth_service.dart';
import '../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(text: 'demo@trackio.app');
  final _password = TextEditingController(text: 'trackio-demo');
  bool _busy = false;

  Future<void> _submit() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10nOf(context).errEnterEmail)),
      );
      return;
    }
    setState(() => _busy = true);
    final auth = context.read<AuthService>();
    final ok = await auth.login(email: email);
    if (!mounted) return;
    if (ok) {
      Navigator.pushNamedAndRemoveUntil(context, '/connect', (_) => false);
    } else {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10nOf(context).errEnterEmail)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tk = tkOf(context);
    final l = l10nOf(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 24, 26, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 22),
              const Align(child: TkWordmark(size: 30)),
              const SizedBox(height: 44),
              Text(
                l.loginWelcomeBack,
                style: GoogleFonts.rubik(fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: tk.textPrimary,
                  letterSpacing: -.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.loginSubtitle,
                style: TextStyle(fontSize: 14.5, color: tk.textSecondary),
              ),
              const SizedBox(height: 34),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () {},
                  child: Text(l.forgotPassword),
                ),
              ),
              const SizedBox(height: 12),
              GradientButton(
                label: _busy ? l.signingIn : l.signIn,
                icon: Icons.login_rounded,
                onTap: _busy ? null : _submit,
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l.newToTrackio,
                    style: TextStyle(color: tk.textSecondary, fontSize: 13.5),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/signup'),
                    child: Text(
                      l.createAccount,
                      style: TextStyle(
                        color: tk.accent,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _DemoBanner(text: l.demoLoginBanner),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoBanner extends StatelessWidget {
  final String text;
  const _DemoBanner({required this.text});
  @override
  Widget build(BuildContext context) {
    final tk = tkOf(context);
    return Container(
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
              text,
              style: TextStyle(fontSize: 12, color: tk.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty || _email.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10nOf(context).errFillNameEmail)),
      );
      return;
    }
    setState(() => _busy = true);
    await context.read<AuthService>().signUp(
          name: _name.text.trim(),
          email: _email.text.trim(),
        );
    if (!mounted) return;
    Navigator.pushNamed(context, '/otp');
  }

  @override
  Widget build(BuildContext context) {
    final tk = tkOf(context);
    final l = l10nOf(context);
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 8, 26, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Text(
                l.signupTitle,
                style: GoogleFonts.rubik(fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: tk.textPrimary,
                  letterSpacing: -.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.signupSubtitle,
                style: TextStyle(fontSize: 14.5, color: tk.textSecondary),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  hintText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 22),
              GradientButton(
                label: _busy ? l.creating : l.continueLabel,
                icon: Icons.arrow_forward_rounded,
                onTap: _busy ? null : _submit,
              ),
              const SizedBox(height: 26),
              _DemoBanner(text: l.demoSignupBanner),
            ],
          ),
        ),
      ),
    );
  }
}
