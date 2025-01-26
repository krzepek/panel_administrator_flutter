import 'package:flutter/material.dart';
import '../services/session_manager.dart';
import '../main.dart';

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

  void _handleRouteChange() {
    final context = navigatorKey.currentContext;
    if (context != null) {
      SessionManager().resetSession(context);
    }
  }
}
