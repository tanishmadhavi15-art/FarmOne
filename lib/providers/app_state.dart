import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/backend.dart';

class AppState extends ChangeNotifier {
  final auth = AuthService();
  String? get authUserId => auth.authUserId;
  AppUser? user;
  bool loading = false;

  Future<void> loadProfile(String uid) async {
    loading = true;
    notifyListeners();
    user = await auth.profile(uid);
    loading = false;
    notifyListeners();
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
