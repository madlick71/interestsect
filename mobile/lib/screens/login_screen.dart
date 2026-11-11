import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  bool _sent = false;
  String? _error;

  Future<void> _sendMagicLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    setState(() => _error = null);
    try {
      await Supabase.instance.client.auth.signInWithOtp(email: email);
      if (mounted) setState(() => _sent = true);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'interestsect',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Das soziale Netzwerk für echte Treffen.\n30 Tage kostenlos testen.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 32),
              if (_sent) ...[
                const Icon(Icons.mark_email_read_outlined, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Prüfe dein Postfach — wir haben dir einen Anmeldelink geschickt.',
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-Mail',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _sendMagicLink,
                  child: const Text('Login-Link senden'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
