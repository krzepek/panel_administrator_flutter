import 'package:flutter/material.dart';
import '../services/session_manager.dart';
import '../main.dart';

// Obserwator trasy, który resetuje sesję użytkownika po zmianie trasy.
class NavigationObserver extends RouteObserver<PageRoute<dynamic>> {

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    _handleRouteChange();
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    _handleRouteChange();
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _handleRouteChange();
  }

  // Resetuje sesję użytkownika po zmianie trasy.
  void _handleRouteChange() {
    final context = navigatorKey.currentContext;
    if (context != null) {
      SessionManager().resetSession(context);
    }
  }
}
