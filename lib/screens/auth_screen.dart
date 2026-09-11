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
  @override Widget build(BuildContext context) => Scaffold(body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('FarmConnect', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)), const Text('A fairer path from field to table'), const SizedBox(height: 32), SegmentedButton<bool>(segments: const [ButtonSegment(value: true, label: Text('Create account')), ButtonSegment(value: false, label: Text('Sign in'))], selected: {signup}, onSelectionChanged: (v) => setState(() => signup = v.first)), const SizedBox(height: 20), if (signup) ...[TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name')), const SizedBox(height: 12)], TextField(controller: email, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress), const SizedBox(height: 12), TextField(controller: password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true), if (signup) ...[const SizedBox(height: 12), TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')), const SizedBox(height: 12), TextField(controller: village, decoration: const InputDecoration(labelText: 'Village / location')), const SizedBox(height: 16), DropdownButtonFormField<UserRole>(initialValue: role, decoration: const InputDecoration(labelText: 'I am a'), items: UserRole.values.map((r) => DropdownMenuItem(value: r, child: Text(roleName(r)))).toList(), onChanged: (v) => setState(() => role = v!))], const SizedBox(height: 24), FilledButton(onPressed: busy ? null : submit, child: Text(busy ? 'Please wait...' : signup ? 'Create account' : 'Sign in'))])))));
}
