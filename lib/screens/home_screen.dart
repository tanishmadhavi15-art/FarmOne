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
    return Scaffold(appBar: AppBar(title: Text(farmer ? 'Farmer workspace' : 'Buyer marketplace'), actions: [IconButton(tooltip: 'Sign out', onPressed: () => _logout(app), icon: const Icon(Icons.logout))]), body: pages[index], bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (i) => setState(() => index = i), destinations: [NavigationDestination(icon: const Icon(Icons.home_outlined), label: 'Home'), NavigationDestination(icon: Icon(farmer ? Icons.add_box : Icons.search), label: farmer ? 'List' : 'Browse'), NavigationDestination(icon: Icon(farmer ? Icons.inventory_2 : Icons.receipt_long), label: farmer ? 'Listings' : 'Orders')]), floatingActionButton: index == 0 ? FloatingActionButton.extended(onPressed: () => context.go(farmer ? '/list' : '/browse'), icon: Icon(farmer ? Icons.add : Icons.search), label: Text(farmer ? 'List produce' : 'Browse produce')) : null);
  }
}
class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user!;
    final buyer = user.role == UserRole.buyer;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      children: [
        Text('Good to see you,', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(user.name, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 24),
        Card(
          color: Theme.of(context).colorScheme.primary,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(children: [
              Icon(icon, color: Colors.white, size: 42),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(buyer ? 'Find fresh produce directly from local farms.' : 'Share your harvest with nearby buyers.', style: const TextStyle(color: Colors.white70)),
              ])),
            ]),
          ),
        ),
        const SizedBox(height: 18),
        Text(buyer ? 'Your marketplace' : 'Your workspace', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Card(child: ListTile(leading: Icon(Icons.location_on_outlined, color: Theme.of(context).colorScheme.primary), title: Text(user.village.isEmpty ? 'Location not set' : user.village), subtitle: const Text('Your local marketplace'))),
        const SizedBox(height: 12),
        Card(child: ListTile(leading: Icon(Icons.verified_user_outlined, color: Theme.of(context).colorScheme.primary), title: Text(roleName(user.role)), subtitle: const Text('Account role saved securely in Firestore.'))),
      ],
    );
  }
}
class _QuickPage extends StatelessWidget {
  const _QuickPage({required this.label, required this.route, required this.icon});
  final String label, route;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBrowse = route == '/browse';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      children: [
        Text(isBrowse ? 'Discover local produce' : label, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(isBrowse ? 'Fresh harvests, transparent prices, and direct connections.' : 'Keep your marketplace activity organized in one place.', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 24),
        Card(
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(children: [
              Icon(icon, size: 42, color: theme.colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(child: Text(isBrowse ? 'Find the next ingredient for your business or home.' : 'Your records will appear here as you use FarmConnect.', style: theme.textTheme.titleMedium)),
            ]),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(onPressed: () => context.go(route), icon: Icon(icon), label: Text(isBrowse ? 'Browse available produce' : label)),
      ],
    );
  }
}
