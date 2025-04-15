import 'package:flutter/material.dart';

class UserState extends ChangeNotifier {
  bool _isLoggedIn = false;
  String _userId = '';
  String _profileImagePath = 'images/user.png';

  bool get isLoggedIn => _isLoggedIn;
  String get userId => _userId;
  String get profileImagePath => _profileImagePath;

  void login(String userId) {
    _isLoggedIn = true;
    _userId = userId;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _userId = '';
    _profileImagePath = 'images/user.png';
    notifyListeners();
  }

  void setProfileImage(String path) {
    _profileImagePath = path;
    notifyListeners();
  }
}