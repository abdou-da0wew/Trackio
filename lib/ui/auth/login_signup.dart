import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    setState(() => _busy = true);
    final auth = context.read<AuthService>();
    final ok = await auth.login(email: _email.text);
    if (!mounted) return;
    if (ok) {
      Navigator.pushNamedAndRemoveUntil(context, '/shell', (_) => false);
    } else {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an email to continue the demo')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tk = tkOf(context);
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
                'Welcome back',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: tk.textPrimary,
                  letterSpacing: -.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to keep your bag within reach.',
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
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 12),
              GradientButton(
                label: _busy ? 'Signing in…' : 'Sign in',
                icon: Icons.login_rounded,
                onTap: _busy ? null : _submit,
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'New to Trackio? ',
                    style: TextStyle(color: tk.textSecondary, fontSize: 13.5),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/signup'),
                    child: Text(
                      'Create an account',
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
              _DemoBanner(text: 'Demo build — any credentials sign you in.'),
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
        const SnackBar(content: Text('Fill your name and email to continue')),
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
                'Create your account',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: tk.textPrimary,
                  letterSpacing: -.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'One account for every bag you track.',
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
                label: _busy ? 'Creating…' : 'Continue',
                icon: Icons.arrow_forward_rounded,
                onTap: _busy ? null : _submit,
              ),
              const SizedBox(height: 26),
              _DemoBanner(text: 'Demo build — signup generates a mock OTP shown on the next screen.'),
            ],
          ),
        ),
      ),
    );
  }
}
