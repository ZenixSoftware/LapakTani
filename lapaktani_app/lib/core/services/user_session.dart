import 'package:flutter/foundation.dart';
import '../../features/auth/auth_repository.dart';
import 'api_service.dart';

class UserSession {
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  final ValueNotifier<User?> userNotifier = ValueNotifier<User?>(null);

  User? get currentUser => userNotifier.value;
  bool get isAuthenticated => userNotifier.value != null;

  Future<void> init() async {
    try {
      final userMap = await ApiService().getUser();
      if (userMap != null && userMap.isNotEmpty) {
        final user = User.fromJson(userMap);
        AuthRepository.setCurrentUser(user);
        userNotifier.value = user;
      } else {
        userNotifier.value = AuthRepository().currentUser;
      }
    } catch (_) {
      userNotifier.value = AuthRepository().currentUser;
    }
  }

  void setUser(User? user) {
    AuthRepository.setCurrentUser(user);
    userNotifier.value = user;
  }

  Future<void> clear() async {
    await AuthRepository().signOut();
    userNotifier.value = null;
  }
}

