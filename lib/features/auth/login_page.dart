import 'package:e_guru/core/auth_store.dart';
import 'package:e_guru/features/auth/registration_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(sessionMessageProvider, (previous, next) {
      if (next != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Clear the message after showing
        Future.microtask(() {
          ref.read(sessionMessageProvider.notifier).state = null;
        });
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('e_guru Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
            TextField(
              controller: _password,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading
                  ? null
                  : () async {
                      final email = _email.text.trim();
                      final password = _password.text;

                      if (email.isEmpty || password.isEmpty) {
                        setState(() => _error = 'Please fill out all fields.');
                        return;
                      }

                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');
                      if (!emailRegex.hasMatch(email)) {
                        setState(() => _error = 'Please enter a valid email address.');
                        return;
                      }

                      setState(() {
                        _loading = true;
                        _error = null;
                      });
                      try {
                        await ref.read(authSessionProvider.notifier).login(
                              email,
                              password,
                            );
                      } catch (e) {
                        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
                      } finally {
                        if (mounted) setState(() => _loading = false);
                      }
                    },
              child: Text(_loading ? 'Please wait...' : 'Login'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegistrationPage()),
                );
              },
              child: const Text("Don't have an account? Register here"),
            ),
          ],
        ),
      ),
    );
  }
}
