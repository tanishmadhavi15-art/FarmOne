import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override State<AuthScreen> createState() => _AuthScreenState();
}
class _AuthScreenState extends State<AuthScreen> {
  final email = TextEditingController(), password = TextEditingController(), name = TextEditingController(), phone = TextEditingController(), village = TextEditingController();
  bool signup = true, busy = false;
  String progress = '';
  UserRole role = UserRole.farmer;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();
    phone.dispose();
    village.dispose();
    super.dispose();
  }
  Future<void> submit() async {
    setState(() {
      busy = true;
      progress = signup ? 'Creating account...' : 'Signing in...';
    });
    try {
      final state = context.read<AppState>();
      if (signup) {
        final user = await state.auth.signUp(email: email.text, password: password.text, name: name.text, role: role, phone: phone.text, village: village.text);
        state.setUser(user);
      } else {
        await state.auth.signIn(email.text, password.text);
        if (mounted) setState(() => progress = 'Loading profile...');
        try {
          await state.loadProfile(state.authUserId!);
        } on TimeoutException {
          throw StateError('Login succeeded, but Firestore profile loading timed out. Check that Firestore is enabled and the app has internet access.');
        }
        if (state.user == null) throw StateError('Account found, but no profile exists. Create the account again or contact support.');
      }
      if (mounted) context.go('/home');
    } catch (e) {
      if (!mounted) return;
        final message = e is TimeoutException
          ? 'Firebase sign-in is taking too long. Check your internet connection and Firebase Auth setup.'
          : e.toString().contains('operation-not-allowed')
          ? 'Enable Email/Password in Firebase Console: Authentication > Sign-in method.'
            : e.toString().contains('invalid-credential') || e.toString().contains('wrong-password') || e.toString().contains('user-not-found')
              ? 'Email or password is incorrect.'
          : e.toString().contains('email-already-in-use')
              ? 'That email already has an account. Sign in instead.'
              : e.toString().contains('weak-password')
                  ? 'Use a password with at least 6 characters.'
                  : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
    if (mounted) {
      setState(() {
        busy = false;
        progress = '';
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xffe3f1e5), Color(0xfff8f6ed)])),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.grass, color: Colors.white)), const SizedBox(width: 14), const Text('FarmConnect', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800))]),
                      const SizedBox(height: 8),
                      Text('A fairer path from field to table', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.black54)),
                      const SizedBox(height: 28),
                      SegmentedButton<bool>(
                        segments: const [ButtonSegment(value: true, label: Text('Create account')), ButtonSegment(value: false, label: Text('Sign in'))],
                        selected: {signup},
                        onSelectionChanged: busy ? null : (v) => setState(() => signup = v.first),
                      ),
                      const SizedBox(height: 20),
                      if (signup) ...[
                        TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline))),
                        const SizedBox(height: 12),
                      ],
                      TextField(controller: email, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)), keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 12),
                      TextField(controller: password, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)), obscureText: true),
                      if (signup) ...[
                        const SizedBox(height: 12),
                        TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined))),
                        const SizedBox(height: 12),
                        TextField(controller: village, decoration: const InputDecoration(labelText: 'Village / location', prefixIcon: Icon(Icons.place_outlined))),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<UserRole>(initialValue: role, decoration: const InputDecoration(labelText: 'I am a', prefixIcon: Icon(Icons.badge_outlined)), items: UserRole.values.map((r) => DropdownMenuItem(value: r, child: Text(roleName(r)))).toList(), onChanged: (v) => setState(() => role = v!)),
                      ],
                      const SizedBox(height: 24),
                      if (busy) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(progress, textAlign: TextAlign.center)),
                      FilledButton(onPressed: busy ? null : submit, child: Text(busy ? 'Please wait...' : signup ? 'Create account' : 'Sign in')),
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
