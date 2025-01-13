import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'main_screen.dart';
import 'add_configuration_screen.dart';
import 'configuration_detail_screen.dart';
import 'account_settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/main': (context) => const MainScreen(),
        '/add-configuration': (context) => const AddConfigurationScreen(),
        '/configuration-detail': (context) => ConfigurationDetailScreen(
              config: ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>,
            ),
        '/account-settings': (context) => const AccountSettingsScreen(),
      },
    );
  }
}