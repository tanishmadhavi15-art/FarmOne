import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/backend.dart';

class AppState extends ChangeNotifier {
  final auth = AuthService();
  String? get authUserId => auth.authUserId;
  AppUser? user;
<<<<<<< HEAD
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
=======
  bool loading = false;
>>>>>>> 7c071d1421e496099bdd5c1308300f72eaf8f22e

  Future<void> loadProfile(String uid) async {
    loading = true;
    notifyListeners();
<<<<<<< HEAD
    try {
      user = await auth.profile(uid);
    } catch (_) {
      user = null;
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
=======
    user = await auth.profile(uid);
    loading = false;
    notifyListeners();
>>>>>>> 7c071d1421e496099bdd5c1308300f72eaf8f22e
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
