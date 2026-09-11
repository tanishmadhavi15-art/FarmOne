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
  @override
  void dispose() { crop.dispose(); qty.dispose(); price.dispose(); super.dispose(); }
  Future<void> save() async {
    final user = context.read<AppState>().user!;
    final parsedQty = double.tryParse(qty.text);
    final parsedPrice = double.tryParse(price.text);
    if (crop.text.trim().isEmpty || parsedQty == null || parsedQty <= 0 || parsedPrice == null || parsedPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a crop name and a quantity and price greater than zero.')));
      return;
    }
    setState(() => busy = true);
    try {
      var url = '';
      if (photo != null) url = await FarmRepository().uploadPhoto(photo!, user.uid);
      await FarmRepository().addListing(farmer: user, cropName: crop.text, quantityKg: parsedQty, pricePerUnit: parsedPrice, photoUrl: url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produce listed.')));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    if (mounted) setState(() => busy = false);
  }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('List produce')), body: ListView(padding: const EdgeInsets.all(20), children: [TextField(controller: crop, decoration: const InputDecoration(labelText: 'Crop name')), const SizedBox(height: 12), TextField(controller: qty, decoration: const InputDecoration(labelText: 'Quantity (kg)'), keyboardType: TextInputType.number), const SizedBox(height: 12), TextField(controller: price, decoration: const InputDecoration(labelText: 'Price per kg'), keyboardType: TextInputType.number), const SizedBox(height: 18), OutlinedButton.icon(onPressed: () async { final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 75); if (picked != null) setState(() => photo = picked); }, icon: const Icon(Icons.camera_alt), label: Text(photo == null ? 'Take crop photo' : 'Photo selected')), const SizedBox(height: 24), FilledButton(onPressed: busy ? null : save, child: Text(busy ? 'Saving...' : 'Publish listing'))]));
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
          if (snap.hasError) return const _StreamError(message: 'Your listings could not be loaded.', details: 'Check your connection and Firestore rules.');
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          if (snap.data!.isEmpty) return const _EmptyListings(filtered: false);
          return ListView(padding: const EdgeInsets.symmetric(vertical: 10), children: snap.data!.map((l) => ListingTile(listing: l)).toList());
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
            child: TextField(onChanged: (v) => setState(() => filter = v.toLowerCase()), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Filter crop or village')),
          ),
          Expanded(
            child: StreamBuilder<List<Listing>>(
              stream: FarmRepository().listed(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return _StreamError(message: 'Listings could not be loaded. Check your connection and Firestore rules.', details: snap.error.toString());
                }
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final items = snap.data!.where((l) => l.cropName.toLowerCase().contains(filter) || l.village.toLowerCase().contains(filter)).toList();
                if (items.isEmpty) {
                  return _EmptyListings(filtered: filter.isNotEmpty);
                }
                return LayoutBuilder(builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900 ? 3 : constraints.maxWidth >= 560 ? 2 : 1;
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: columns == 1 ? 2.25 : 1.05),
                    itemCount: items.length,
                    itemBuilder: (_, index) => ListingCard(listing: items[index], onTap: () => context.push('/listing-detail', extra: items[index])),
                  );
                });
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
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onTap,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: listing.photoUrl.isEmpty
              ? Container(width: 58, height: 58, color: const Color(0xffe5f1e7), child: const Icon(Icons.eco, color: Color(0xff17624a), size: 30))
              : Image.network(listing.photoUrl, width: 58, height: 58, fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(width: 58, height: 58, color: const Color(0xffe5f1e7), child: const Icon(Icons.eco, color: Color(0xff17624a)))),
        ),
        title: Text(listing.cropName, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${listing.village}  ·  ${listing.quantityKg.toStringAsFixed(0)} kg\nLot ${listing.lotId}'),
        isThreeLine: true,
        trailing: Text('₹${listing.pricePerUnit.toStringAsFixed(2)}\n/kg', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),
      ),
    );
  }
}

class ListingCard extends StatelessWidget {
  const ListingCard({super.key, required this.listing, this.onTap});
  final Listing listing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: SizedBox(width: double.infinity, child: listing.photoUrl.isEmpty
              ? Container(color: const Color(0xffe4f0e6), child: Icon(Icons.eco, size: 52, color: theme.colorScheme.primary))
              : Image.network(listing.photoUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(color: const Color(0xffe4f0e6), child: Icon(Icons.eco, size: 52, color: theme.colorScheme.primary))))),
          Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text(listing.cropName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))), Text('₹${listing.pricePerUnit.toStringAsFixed(0)}', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w800))]),
            const SizedBox(height: 6),
            Text('${listing.quantityKg.toStringAsFixed(0)} kg available  ·  ${listing.village}', maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
          ])),
        ]),
      ),
    );
  }
}

class _EmptyListings extends StatelessWidget {
  const _EmptyListings({required this.filtered});
  final bool filtered;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(filtered ? Icons.search_off : Icons.storefront, size: 52, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 16), Text(filtered ? 'No listings match your search' : 'No produce is available yet', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center), const SizedBox(height: 8), Text(filtered ? 'Try a different crop or village.' : 'New farmer listings will appear here as soon as they are published.', textAlign: TextAlign.center)])));
}

class _StreamError extends StatelessWidget {
  const _StreamError({required this.message, required this.details});
  final String message;
  final String details;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off, size: 48), const SizedBox(height: 16), Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 8), SelectableText(details, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall)])));
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
          if (listing.photoUrl.isNotEmpty) ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.network(listing.photoUrl, height: 220, fit: BoxFit.cover)),
          const SizedBox(height: 18),
          Text(listing.cropName, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Lot ${listing.lotId}', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 20),
          Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [
            _DetailRow(icon: Icons.scale_outlined, label: 'Available', value: '${listing.quantityKg.toStringAsFixed(0)} kg'),
            const Divider(height: 24),
            _DetailRow(icon: Icons.location_on_outlined, label: 'Location', value: listing.village),
            const Divider(height: 24),
            _DetailRow(icon: Icons.payments_outlined, label: 'Price per kg', value: '₹${listing.pricePerUnit.toStringAsFixed(2)}'),
          ]))),
          const SizedBox(height: 24),
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Row(children: [Icon(icon, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 12), Expanded(child: Text(label)), Text(value, style: const TextStyle(fontWeight: FontWeight.w700))]);
}
