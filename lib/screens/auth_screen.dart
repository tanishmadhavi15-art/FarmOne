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
        await state.loadProfile(state.authUserId!);
      }
      if (mounted) context.go('/home');
    } catch (e) {
      if (!mounted) return;
      final message = e is TimeoutException
          ? 'Firebase is taking too long to respond. Check your internet connection and Firebase setup.'
          : e.toString().contains('operation-not-allowed')
          ? 'Enable Email/Password in Firebase Console: Authentication > Sign-in method.'
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
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [theme.colorScheme.primaryContainer, const Color(0xfff7f8f5), const Color(0xfff7f8f5)])),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Container(width: 64, height: 64, alignment: Alignment.center, decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.agriculture, color: Colors.white, size: 34)),
                  const SizedBox(height: 20),
                  Text('FarmConnect', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text('A fairer path from field to table', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 28),
                  Card(child: Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    SegmentedButton<bool>(segments: const [ButtonSegment(value: true, label: Text('Create account')), ButtonSegment(value: false, label: Text('Sign in'))], selected: {signup}, onSelectionChanged: (v) => setState(() => signup = v.first)),
                    const SizedBox(height: 22),
                    Text(signup ? 'Create your account' : 'Welcome back', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(signup ? 'Join a local network for better produce.' : 'Sign in to continue to your marketplace.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 20),
                    if (signup) ...[TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline))), const SizedBox(height: 12)],
                    TextField(controller: email, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)), keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    TextField(controller: password, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)), obscureText: true),
                    if (signup) ...[const SizedBox(height: 12), TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined))), const SizedBox(height: 12), TextField(controller: village, decoration: const InputDecoration(labelText: 'Village / location', prefixIcon: Icon(Icons.location_on_outlined))), const SizedBox(height: 12), DropdownButtonFormField<UserRole>(initialValue: role, decoration: const InputDecoration(labelText: 'I am a', prefixIcon: Icon(Icons.badge_outlined)), items: UserRole.values.map((r) => DropdownMenuItem(value: r, child: Text(roleName(r)))).toList(), onChanged: (v) => setState(() => role = v!))],
                    const SizedBox(height: 24),
                    FilledButton(onPressed: busy ? null : submit, child: Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text(busy ? progress : signup ? 'Create account' : 'Sign in'))),
                  ]))),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
