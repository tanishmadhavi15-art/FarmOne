import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/backend.dart';

class AppState extends ChangeNotifier {
  final auth = AuthService();
  String? get authUserId => auth.authUserId;
  AppUser? user;
  bool loading = true;

  AppState() {
    auth.authChanges.listen((firebaseUser) async {
      if (firebaseUser == null) {
        user = null;
        loading = false;
        notifyListeners();
      } else {
        try {
          await loadProfile(firebaseUser.uid);
        } catch (_) {
          user = null;
        }
        loading = false;
        notifyListeners();
      }
    });
  }

  Future<void> loadProfile(String uid) async {
    loading = true;
    notifyListeners();
    try {
      user = await auth.profile(uid);
    } catch (_) {
      user = null;
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setUser(AppUser value) {
    user = value;
    notifyListeners();
  }

  Future<void> logout() async {
    await auth.signOut();
    user = null;
    notifyListeners();
  }
}
