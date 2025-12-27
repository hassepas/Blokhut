import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../theme/studybuddy_theme.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  bool _isRegister = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = context.read<AuthService>();
    try {
      if (_isRegister) {
        await auth.registerWithEmail(_emailC.text.trim(), _passC.text);
      } else {
        await auth.signInWithEmail(_emailC.text.trim(), _passC.text);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _google() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = context.read<AuthService>();
    try {
      await auth.signInWithGoogle();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('StudyBuddy')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _isRegister ? 'Account maken' : 'Inloggen',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      if (_error != null) ...[
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 8),
                      ],
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailC,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(labelText: 'E-mail'),
                              validator: (v) {
                                final s = (v ?? '').trim();
                                if (s.isEmpty) return 'Vul je e-mail in';
                                if (!s.contains('@')) return 'Ongeldig e-mailadres';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passC,
                              obscureText: true,
                              decoration: const InputDecoration(labelText: 'Wachtwoord'),
                              validator: (v) {
                                if ((v ?? '').length < 6) return 'Minstens 6 tekens';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loading ? null : _submitEmail,
                        child: Text(_isRegister ? 'Registreren' : 'Inloggen'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: _loading ? null : _google,
                        child: const Text('Verder met Google'),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () => setState(() => _isRegister = !_isRegister),
                        child: Text(_isRegister
                            ? 'Heb je al een account? Inloggen'
                            : 'Nog geen account? Registreren'),
                      ),
                      const SizedBox(height: 8),
                      if (_loading)
                        const LinearProgressIndicator(color: StudyBuddyTheme.mint),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
