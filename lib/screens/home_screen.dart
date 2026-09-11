import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';

class HomeScreen extends StatefulWidget { const HomeScreen({super.key}); @override State<HomeScreen> createState() => _HomeScreenState(); }
class _HomeScreenState extends State<HomeScreen> {
  int index = 0;
  Future<void> _logout(AppState app) async {
    await app.logout();
    if (mounted) context.go('/auth');
  }
  @override Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final user = app.user;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final farmer = user.role == UserRole.farmer;
    final pages = farmer ? const [_Dashboard(title: 'Farmer workspace', icon: Icons.agriculture), _QuickPage(label: 'List produce', route: '/list', icon: Icons.add_box), _QuickPage(label: 'My listings', route: '/my-listings', icon: Icons.inventory_2)] : const [_Dashboard(title: 'Buyer marketplace', icon: Icons.storefront), _QuickPage(label: 'Browse listings', route: '/browse', icon: Icons.search), _QuickPage(label: 'My orders', route: '/orders', icon: Icons.receipt_long)];
    return Scaffold(appBar: AppBar(title: Text(farmer ? 'FarmConnect · Farmer' : 'FarmConnect · Buyer'), actions: [IconButton(tooltip: 'Sign out', onPressed: () => _logout(app), icon: const Icon(Icons.logout))]), body: pages[index], bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (i) => setState(() => index = i), destinations: [NavigationDestination(icon: const Icon(Icons.home_outlined), label: 'Home'), NavigationDestination(icon: Icon(farmer ? Icons.add_box : Icons.search), label: farmer ? 'List' : 'Browse'), NavigationDestination(icon: Icon(farmer ? Icons.inventory_2 : Icons.receipt_long), label: farmer ? 'Listings' : 'Orders')]), floatingActionButton: index == 0 ? FloatingActionButton.extended(onPressed: () => context.push(farmer ? '/list' : '/browse'), icon: Icon(farmer ? Icons.add : Icons.search), label: Text(farmer ? 'List produce' : 'Browse')) : null);
  }
}
class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user!;
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Welcome, ${user.name}', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                Text(user.village.isEmpty ? 'Ready for a productive day?' : user.village, style: theme.textTheme.bodyLarge?.copyWith(color: Colors.black54)),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(24)),
                  child: Row(children: [Icon(icon, size: 42, color: Colors.white), const SizedBox(width: 16), Expanded(child: Text(user.role == UserRole.farmer ? "Share today's harvest with nearby buyers." : 'Find fresh produce directly from local farms.', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)))]),
                ),
                const SizedBox(height: 16),
                Card(child: ListTile(contentPadding: const EdgeInsets.all(16), leading: CircleAvatar(backgroundColor: theme.colorScheme.secondaryContainer, child: Icon(Icons.verified_user, color: theme.colorScheme.primary)), title: Text(roleName(user.role), style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: const Text('Your marketplace profile is active.'))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
class _QuickPage extends StatelessWidget { const _QuickPage({required this.label, required this.route, required this.icon}); final String label, route; final IconData icon; @override Widget build(BuildContext context) => Center(child: FilledButton.icon(onPressed: () => context.push(route), icon: Icon(icon), label: Text(label))); }
