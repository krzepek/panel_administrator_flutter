import 'dart:async';
import 'package:flutter/material.dart';
import '../services/token_service.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  final Duration sessionTimeout = Duration(minutes: 20);
  Timer? _inactivityTimer;
  bool _isSessionActive = false;

  void startSession(BuildContext context) {
    _isSessionActive = true;
    _resetTimer(context);
  }

  void resetSession(BuildContext context) {
    if (_isSessionActive) {
      _resetTimer(context);
    }
  }

  void _resetTimer(BuildContext context) async {
    try {
      _inactivityTimer?.cancel();
      await TokenService().prolongToken();
      _inactivityTimer = Timer(sessionTimeout, () async {
        await TokenService().clearToken();
        stopSession();
        if(context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session expired. Please log in again.')),
          );
          Navigator.pushReplacementNamed(context, '/login');
        }
      });
    } catch (e){
      await TokenService().clearToken();
      stopSession();
      if(context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Please log in again.')),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  void stopSession() {
    _inactivityTimer?.cancel();
    _isSessionActive = false;
  }

  bool checkSession() {
    return _isSessionActive;
  }
}
