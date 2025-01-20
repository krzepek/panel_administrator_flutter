import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_screen.dart';
import 'screens/add_configuration_screen.dart';
import 'screens/configuration_detail_screen.dart';
import 'screens/account_settings_screen.dart';
import 'screens/query_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'utils/route_observer.dart';

final RouteObserver<PageRoute<dynamic>> routeObserver = NavigationObserver();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [routeObserver],
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/main': (context) => const MainScreen(),
        '/add-configuration': (context) => const AddConfigurationScreen(),
        '/configuration-detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ConfigurationDetailScreen(
            config: args['config'] as Map<String, dynamic>,
            status: args['status'],
          );
        },
        '/account-settings': (context) => const AccountSettingsScreen(),
        '/query-screen': (context) => QueryScreen(
              config: ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>,
            ),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
      },
    );
  }
}