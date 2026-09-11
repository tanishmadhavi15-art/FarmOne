import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { farmer, buyer }

UserRole roleFrom(String? value) => value == 'buyer' ? UserRole.buyer : UserRole.farmer;
String roleName(UserRole role) => role == UserRole.farmer ? 'Farmer' : 'Buyer';

class AppUser {
  const AppUser({required this.uid, required this.name, required this.role, required this.phone, required this.village});
  final String uid;
  final String name;
  final UserRole role;
  final String phone;
  final String village;

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser(uid: data['uid'] as String? ?? doc.id, name: data['name'] as String? ?? '', role: roleFrom(data['role'] as String?), phone: data['phone'] as String? ?? '', village: data['village'] as String? ?? '');
  }
}

class Listing {
  const Listing({required this.id, required this.lotId, required this.farmerId, required this.farmerName, required this.cropName, required this.quantityKg, required this.pricePerUnit, required this.village, required this.photoUrl, required this.status});
  final String id;
  final String lotId;
  final String farmerId;
  final String farmerName;
  final String cropName;
  final double quantityKg;
  final double pricePerUnit;
  final String village;
  final String photoUrl;
  final String status;

  factory Listing.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Listing(id: doc.id, lotId: data['lotId'] as String? ?? '', farmerId: data['farmerId'] as String? ?? '', farmerName: data['farmerName'] as String? ?? '', cropName: data['cropName'] as String? ?? '', quantityKg: (data['quantityKg'] as num? ?? 0).toDouble(), pricePerUnit: (data['pricePerUnit'] as num? ?? 0).toDouble(), village: data['village'] as String? ?? '', photoUrl: data['photoUrl'] as String? ?? '', status: data['status'] as String? ?? 'listed');
  }
}

class Order {
  const Order({required this.id, required this.listingId, required this.buyerId, required this.farmerId, required this.status, required this.amount});
  final String id;
  final String listingId;
  final String buyerId;
  final String farmerId;
  final String status;
  final double amount;

  factory Order.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Order(id: doc.id, listingId: data['listingId'] as String? ?? '', buyerId: data['buyerId'] as String? ?? '', farmerId: data['farmerId'] as String? ?? '', status: data['status'] as String? ?? 'pending_payment', amount: (data['amount'] as num? ?? 0).toDouble());
  }
}
