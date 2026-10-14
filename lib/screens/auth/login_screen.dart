import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import 'register_screen.dart';

/// Shown whenever nobody is signed in.
/// Calls [onLogin] with the username after a successful sign-in or
/// a successful registration.
class LoginScreen extends StatefulWidget {
  final ValueChanged<String> onLogin;

  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final username = _userCtrl.text.trim().toLowerCase();
    if (AuthService.signIn(username, _passCtrl.text)) {
      widget.onLogin(username);
    } else {
      setState(() => _error = 'Incorrect username or password.');
    }
  }

  Future<void> _openRegister() async {
    final username = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
    if (username != null && mounted) widget.onLogin(username);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.lightbulb_outline,
                        size: 48, color: scheme.primary),
                    const SizedBox(height: 12),
                    const Text(
                      'Radiant',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Municipal traffic light monitoring',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _userCtrl,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter your username'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _obscure ? 'Show password' : 'Hide password',
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Enter your password'
                          : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(color: scheme.error)),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Log In'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _openRegister,
                      child: const Text("Don't have an account? Register"),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Prototype demo account\nUsername: admin   Password: radiant123',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}