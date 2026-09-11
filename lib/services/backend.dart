import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class AuthService {
  static const _requestTimeout = Duration(seconds: 15);
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  String? get authUserId => _auth.currentUser?.uid;

  Future<AppUser> signUp({required String email, required String password, required String name, required UserRole role, required String phone, required String village}) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password).timeout(_requestTimeout);
    final user = AppUser(uid: credential.user!.uid, name: name.trim(), role: role, phone: phone.trim(), village: village.trim());
    await _db.collection('users').doc(user.uid).set({'uid': user.uid, 'name': user.name, 'role': role == UserRole.farmer ? 'farmer' : 'buyer', 'phone': user.phone, 'village': user.village}).timeout(_requestTimeout);
    return user;
  }

  Future<void> signIn(String email, String password) => _auth.signInWithEmailAndPassword(email: email.trim(), password: password).timeout(_requestTimeout);
  Future<void> signOut() => _auth.signOut();
  Stream<User?> get authChanges => _auth.authStateChanges();
  Future<AppUser?> profile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get().timeout(_requestTimeout);
    return doc.exists ? AppUser.fromDoc(doc) : null;
  }
}

class FarmRepository {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  Stream<Listing> listing(String id) => _db.collection('listings').doc(id).snapshots().map(Listing.fromDoc);
  Stream<List<Listing>> listed() => _db.collection('listings').where('status', isEqualTo: 'listed').snapshots().map((s) => s.docs.map(Listing.fromDoc).toList());
  Stream<List<Listing>> farmerListings(String uid) => _db.collection('listings').where('farmerId', isEqualTo: uid).snapshots().map((s) => s.docs.map(Listing.fromDoc).toList());
  Stream<List<Order>> buyerOrders(String uid) => _db.collection('orders').where('buyerId', isEqualTo: uid).snapshots().map((s) => s.docs.map(Order.fromDoc).toList());

  Future<String> uploadPhoto(XFile file, String uid) async {
    final ref = _storage.ref('listing_photos/$uid/${_uuid.v4()}.jpg');
    await ref.putData(await file.readAsBytes(), SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<void> addListing({required AppUser farmer, required String cropName, required double quantityKg, required double pricePerUnit, required String photoUrl}) async {
    final lotId = 'FC-${DateTime.now().millisecondsSinceEpoch}-${_uuid.v4().substring(0, 6).toUpperCase()}';
    await _db.collection('listings').add({'lotId': lotId, 'farmerId': farmer.uid, 'farmerName': farmer.name, 'cropName': cropName.trim(), 'quantityKg': quantityKg, 'pricePerUnit': pricePerUnit, 'village': farmer.village, 'photoUrl': photoUrl, 'status': 'listed', 'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> placeOrder({required Listing listing, required String buyerId}) async {
    final orderRef = _db.collection('orders').doc();
    final listingRef = _db.collection('listings').doc(listing.id);
    await _db.runTransaction((transaction) async {
      final current = await transaction.get(listingRef);
      if (current.data()?['status'] != 'listed') throw StateError('This lot is no longer available.');
      transaction.set(orderRef, {'listingId': listing.id, 'buyerId': buyerId, 'farmerId': listing.farmerId, 'status': 'pending_payment', 'amount': listing.quantityKg * listing.pricePerUnit, 'createdAt': FieldValue.serverTimestamp()});
      transaction.update(listingRef, {'status': 'reserved'});
    });
  }

  Future<void> updateOrder(String orderId, String status, String listingId) async {
    await _db.collection('orders').doc(orderId).update({'status': status, 'updatedAt': FieldValue.serverTimestamp()});
    if (status == 'delivered' || status == 'released') await _db.collection('listings').doc(listingId).update({'status': status == 'released' ? 'sold' : 'delivered'});
  }
}
