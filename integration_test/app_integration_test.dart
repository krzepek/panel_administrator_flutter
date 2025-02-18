// file: integration_test/app_integration_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:panel_administrator_flutter/firebase_options.dart'; 
// Plik generowany przez FlutterFire CLI z konfiguracją Twojego projektu
import 'package:panel_administrator_flutter/main.dart'; 
// Zakładam, że w main.dart wywołujesz runApp(MyApp()) i masz zdefiniowane wszystkie trasy

void main() {
  // Uruchom bindingi testów integracyjnych
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    setUpAll(() async {
      // Inicjalizacja Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    });

    testWidgets('1. Uruchom aplikację i przejdź do ekranu rejestracji', (WidgetTester tester) async {
      // 1. Uruchom cały widget MyApp (lub cokolwiek uruchamiasz w main())
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // 2. Sprawdź, czy jesteśmy na ekranie logowania (szukamy np. tekstu "Login")
      expect(find.text('Login Screen'), findsOneWidget);

      // 3. Przejdź do ekranu rejestracji
      final registerFinder = find.text('Don\'t have an account? Register');
      expect(registerFinder, findsOneWidget);
      await tester.tap(registerFinder);
      await tester.pumpAndSettle();

      // 4. Na ekranie rejestracji sprawdzamy, czy jest przycisk "Register"
      expect(find.text('Register Screen'), findsOneWidget);
    });

    testWidgets('2. Zarejestruj się i przejdź do MainScreen', (WidgetTester tester) async {
      // Znowu uruchamiamy aplikację:
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Przechodzimy do rejestracji
      final registerFinder = find.text('Don\'t have an account? Register');
      await tester.tap(registerFinder);
      await tester.pumpAndSettle();

      // Wpiszmy jakiś adres e-mail i hasła
      final emailField = find.byType(TextFormField).at(0); // w RegisterScreen email jest pierwszym
      final passField = find.byType(TextFormField).at(1);
      final repeatPassField = find.byType(TextFormField).at(2);

      await tester.enterText(emailField, 'test_integration@gmail.com');
      await tester.enterText(passField, 'test1234');
      await tester.enterText(repeatPassField, 'test1234');

      // Klikamy w 'Register'
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Oczekujemy, że przeniesie nas do MainScreen (szukamy np. "Database Configurations")
      expect(find.text('Database Configurations'), findsOneWidget);
    });

    testWidgets('3. Wyloguj się i zaloguj ponownie', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      final emailField = find.byType(TextFormField).at(0); 
      final passField = find.byType(TextFormField).at(1);

      await tester.enterText(emailField, 'test_integration@gmail.com');
      await tester.enterText(passField, 'test1234');
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Sprawdzamy, czy jesteśmy na MainScreen
      expect(find.text('Database Configurations'), findsOneWidget);

      // Otwieramy szufladę (drawer)
      final scaffoldFinder = find.byType(Scaffold);
      ScaffoldState scaffoldState = tester.firstState<ScaffoldState>(scaffoldFinder);
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Klikamy logout
      final logoutFinder = find.text('Logout');
      await tester.tap(logoutFinder);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Teraz oczekujemy, że wróciliśmy na ekran logowania
      expect(find.text('Login Screen'), findsOneWidget);

      // Logowanie
      final newEmailField = find.byType(TextFormField).at(0); 
      final newPassField = find.byType(TextFormField).at(1);

      await tester.enterText(newEmailField, 'test_integration@gmail.com');
      await tester.enterText(newPassField, 'test1234');
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Powrót do MainScreen
      expect(find.text('Database Configurations'), findsOneWidget);
    });

    testWidgets('4. Dodawanie i usuwanie konfiguracji', (WidgetTester tester) async {
      // Zakładamy, że jesteśmy zalogowani (albo używamy scenariusza z poprzednich testów)
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final emailField = find.byType(TextFormField).at(0); 
      final passField = find.byType(TextFormField).at(1);

      await tester.enterText(emailField, 'test_integration@gmail.com');
      await tester.enterText(passField, 'test1234');
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Sprawdzamy, czy jesteśmy na MainScreen
      expect(find.text('Database Configurations'), findsOneWidget);

      // Klikamy w FAB by dodać konfigurację
      final fabFinder = find.byIcon(Icons.add);
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      // Jesteśmy na AddConfigurationScreen
      expect(find.text('Add Configuration'), findsOneWidget);

      // Wypełniamy nazwy, itp.
      await tester.enterText(find.byType(TextFormField).at(0), 'TestConfig');
      // Domyślny DB type to "mysql", spr. np. 'URL'
      await tester.enterText(find.byType(TextFormField).at(2), '127.0.0.1');
      await tester.enterText(find.byType(TextFormField).at(3), 'testuser');
      await tester.enterText(find.byType(TextFormField).at(4), 'pass');
      await tester.enterText(find.byType(TextFormField).at(5), '3306');

      // Zapisujemy
      final addConfigButton = find.text('Add Configuration');
      await tester.tap(addConfigButton);
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Wracamy do MainScreen, powinien pojawić się kafelek "TestConfig"
      expect(find.text('TestConfig'), findsOneWidget);

      // Usuwamy tę konfigurację (ikona kosza)
      final deleteIcon = find.descendant(
        of: find.byType(Card).last,
        matching: find.byIcon(Icons.delete),
      );
      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();

      // Powinien pojawić się dialog "Confirm Delete"
      expect(find.text('Confirm Delete'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Sprawdzamy, czy zniknął "TestConfig"
      expect(find.text('TestConfig'), findsNothing);
    });

    testWidgets('5. Zmiana hasła w Account Settings', (WidgetTester tester) async {
      // Najpierw uruchom app, zakładamy, że jestesmy zalogowani
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final emailField = find.byType(TextFormField).at(0); 
      final passField = find.byType(TextFormField).at(1);

      await tester.enterText(emailField, 'test_integration@gmail.com');
      await tester.enterText(passField, 'test1234');
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Sprawdzamy, czy jesteśmy na MainScreen
      expect(find.text('Database Configurations'), findsOneWidget);

      // Otwieramy Drawer
      final scaffoldFinder = find.byType(Scaffold).first;
      ScaffoldState scaffoldState = tester.firstState<ScaffoldState>(scaffoldFinder);
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Klikamy 'Account Settings'
      await tester.tap(find.text('Account Settings'));
      await tester.pumpAndSettle();

      // Teraz ekrany z listTile: 'Change Password'
      expect(find.text('Change Password'), findsOneWidget);
      await tester.tap(find.text('Change Password'));
      await tester.pumpAndSettle( const Duration(seconds: 5));

      final newPassField = find.byType(TextField).first;
      final confirmPassField = find.byType(TextField).last;

      // Dialog z polami 'New password' i 'Confirm password'
      await tester.enterText(newPassField, 'newPass123');
      await tester.enterText(confirmPassField, 'newPass123');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Po pomyślnej zmianie wylogowuje usera
      // Spodziewamy się ekranu logowania
      expect(find.text('Login'), findsOneWidget);
    });
  });
}
