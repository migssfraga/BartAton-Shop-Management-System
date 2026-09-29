import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  Map<String, dynamic>? _cachedUserData;

  Future<Map<String, dynamic>?> getCurrentUserData({bool forceRefresh = false}) async {
    if (_cachedUserData != null && !forceRefresh) {
      return _cachedUserData;
    }

    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      _cachedUserData = doc.data();
      return _cachedUserData;
    }
    return null;
  }

  void clearCache() {
    _cachedUserData = null;
  }
}
