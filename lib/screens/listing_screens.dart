import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../services/backend.dart';

class ListProduceScreen extends StatefulWidget { const ListProduceScreen({super.key}); @override State<ListProduceScreen> createState() => _ListProduceState(); }
class _ListProduceState extends State<ListProduceScreen> {
  final crop = TextEditingController(), qty = TextEditingController(), price = TextEditingController(); XFile? photo; bool busy = false;
  @override void dispose() { crop.dispose(); qty.dispose(); price.dispose(); super.dispose(); }
  Future<void> save() async { final user = context.read<AppState>().user!; if (crop.text.isEmpty || double.tryParse(qty.text) == null || double.tryParse(price.text) == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter crop, quantity, and price.'))); return; } setState(() => busy = true); try { var url = ''; if (photo != null) url = await FarmRepository().uploadPhoto(photo!, user.uid); await FarmRepository().addListing(farmer: user, cropName: crop.text, quantityKg: double.parse(qty.text), pricePerUnit: double.parse(price.text), photoUrl: url); if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produce listed.'))); context.pop(); } } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); } if (mounted) setState(() => busy = false); }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('List produce')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(controller: crop, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Crop name')),
            const SizedBox(height: 12),
            TextField(controller: qty, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Quantity (kg)'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(controller: price, textInputAction: TextInputAction.done, decoration: const InputDecoration(labelText: 'Price per kg'), keyboardType: TextInputType.number, onSubmitted: (_) { if (!busy) save(); }),
            const SizedBox(height: 18),
            OutlinedButton.icon(onPressed: busy ? null : () async { final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 75); if (picked != null) setState(() => photo = picked); }, icon: const Icon(Icons.camera_alt), label: Text(photo == null ? 'Take crop photo' : 'Photo selected')),
            const SizedBox(height: 24),
            FilledButton(onPressed: busy ? null : save, child: Text(busy ? 'Saving...' : 'Publish listing')),
          ],
        ),
      ),
    ),
  );
}

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = context.read<AppState>().user!.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('My listings')),
      body: StreamBuilder<List<Listing>>(
        stream: FarmRepository().farmerListings(uid),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          if (snap.data!.isEmpty) return const Center(child: Text('No produce listed yet.'));
          return ListView(children: snap.data!.map((l) => ListingTile(listing: l)).toList());
        },
      ),
    );
  }
}

class BrowseListingsScreen extends StatefulWidget {
  const BrowseListingsScreen({super.key});
  @override
  State<BrowseListingsScreen> createState() => _BrowseState();
}

class _BrowseState extends State<BrowseListingsScreen> {
  String filter = '';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Browse listings')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(onChanged: (v) => setState(() => filter = v.toLowerCase()), decoration: InputDecoration(prefixIcon: const Icon(Icons.search), labelText: 'Filter crop or village', suffixIcon: filter.isEmpty ? null : IconButton(tooltip: 'Clear search', onPressed: () => setState(() => filter = ''), icon: const Icon(Icons.clear)))),
          ),
          Expanded(
            child: StreamBuilder<List<Listing>>(
              stream: FarmRepository().listed(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final items = snap.data!.where((l) => l.cropName.toLowerCase().contains(filter) || l.village.toLowerCase().contains(filter)).toList();
                if (items.isEmpty) return const Center(child: Text('No matching produce found.'));
                return RefreshIndicator(onRefresh: () async => setState(() {}), child: ListView(children: items.map((l) => ListingTile(listing: l, onTap: () => context.push('/listing-detail', extra: l))).toList()));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ListingTile extends StatelessWidget {
  const ListingTile({super.key, required this.listing, this.onTap});
  final Listing listing;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: listing.photoUrl.isEmpty ? const Icon(Icons.eco, size: 38) : Image.network(listing.photoUrl, width: 52, height: 52, fit: BoxFit.cover),
        title: Text('${listing.cropName} · ${listing.quantityKg} kg'),
        subtitle: Text('${listing.village} · ₹${listing.pricePerUnit.toStringAsFixed(2)}/kg\nLot ${listing.lotId}'),
        isThreeLine: true,
        trailing: Chip(label: Text(listing.status)),
      ),
    );
  }
}

class ListingDetailScreen extends StatelessWidget {
  const ListingDetailScreen({super.key, required this.listing});
  final Listing listing;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(listing.cropName)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (listing.photoUrl.isNotEmpty) Image.network(listing.photoUrl, height: 220, fit: BoxFit.cover),
          const SizedBox(height: 18),
          Text(listing.cropName, style: Theme.of(context).textTheme.headlineMedium),
          Text('Lot ID: ${listing.lotId}'),
          Text('${listing.quantityKg} kg available from ${listing.village}'),
          Text('₹${listing.pricePerUnit.toStringAsFixed(2)} per kg'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: listing.status != 'listed'
                ? null
                : () async {
                    try {
                      await FarmRepository().placeOrder(listing: listing, buyerId: context.read<AppState>().user!.uid);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order created.')));
                        context.go('/orders');
                      }
                    } catch (e) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  },
            icon: const Icon(Icons.shopping_cart),
            label: const Text('Place order'),
          ),
        ],
      ),
    );
  }
}
