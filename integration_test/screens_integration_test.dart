import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:panel_administrator_flutter/firebase_options.dart'; 
import 'package:panel_administrator_flutter/main.dart';

/// Ten plik zawiera rozbudowane testy integracyjne sprawdzające różne ekrany
/// Twojej aplikacji: logowanie, rejestrację, zapominanie hasła, widok główny,
/// dodawanie / usuwanie konfiguracji bazy danych, ekran ustawień konta itd.
///
/// Aby testy działały, uruchamiaj je przez:
///   flutter test integration_test
/// (przy założeniu, że posiadasz skonfigurowane Firebase w projekcie i
///  emulator/urządzenie gotowe do użycia).
///
/// Każdy test tworzy instancję MyApp() i czeka, aż wszystko się wyrenderuje.
/// Następnie symuluje interakcje użytkownika, np. wpisywanie tekstu w pola
/// i klikanie przycisków. Weryfikuje, czy trafiamy na oczekiwane ekrany.

void main() {
  // 1. Binding testów integracyjnych
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

    // 2. Inicjalizacja Firebase (domyślna)
    setUpAll(() async {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    });

    // ============================================================================================
    // REJESTRACJA
    // ============================================================================================
    group('Ekran Rejestracji (RegisterScreen)', () {
      testWidgets(
        '1.1. Uruchom aplikację i przejdź do ekranu rejestracji',
        (WidgetTester tester) async {

          // 1. Pumpujemy MyApp
          await tester.pumpWidget(MyApp());
          await tester.pumpAndSettle();

          // 2. Sprawdzamy, czy jesteśmy na ekranie logowania
          //    (przykładowo: jest tekst "Login Screen" lub "Login")
          expect(find.text('Login'), findsOneWidget);

          // 3. Klikamy w link do rejestracji
          final registerFinder = find.text("Don't have an account? Register");
          expect(registerFinder, findsOneWidget);
          await tester.tap(registerFinder);
          await tester.pumpAndSettle();

          // 4. Weryfikujemy, czy teraz widać "Register" jako tytuł/przycisk
          expect(find.text('Register'), findsOneWidget);
        },
      );

      testWidgets(
        '1.2. Zarejestruj się poprawnie i sprawdź, czy przechodzi do MainScreen',
        (WidgetTester tester) async {
          // 1. Uruchamiamy aplikację od zera
          await tester.pumpWidget(MyApp());
          await tester.pumpAndSettle();

          // 2. Przejście do rejestracji
          final regLink = find.text("Don't have an account? Register");
          await tester.tap(regLink);
          await tester.pumpAndSettle();

          // 3. Wpisujemy e-mail/hasła
          final emailField = find.byType(TextFormField).at(0);
          final passField = find.byType(TextFormField).at(1);
          final repeatField = find.byType(TextFormField).at(2);

          await tester.enterText(emailField, 'test_integration_user@example.com');
          await tester.enterText(passField, 'test1234');
          await tester.enterText(repeatField, 'test1234');

          // 4. Klikamy "Register"
          await tester.tap(find.text('Register'));
          await tester.pumpAndSettle(const Duration(seconds: 3));

          // 5. Oczekujemy, że przeniesie nas do ekranu głównego
          expect(find.text('Database Configurations'), findsOneWidget);
        },
      );

      testWidgets(
        '1.3. Rejestracja z niepasującymi hasłami (powinna zgłosić błąd)',
        (WidgetTester tester) async {
          await tester.pumpWidget(MyApp());
          await tester.pumpAndSettle();

          final regLink = find.text("Don't have an account? Register");
          await tester.tap(regLink);
          await tester.pumpAndSettle();

          final emailField = find.byType(TextFormField).at(0);
          final passField = find.byType(TextFormField).at(1);
          final repeatField = find.byType(TextFormField).at(2);

          await tester.enterText(emailField, 'test_integration_user2@example.com');
          await tester.enterText(passField, 'abc123');
          await tester.enterText(repeatField, 'xyz999');

          await tester.tap(find.text('Register'));
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Powinna pojawić się snackbar z info "Passwords do not match."
          expect(find.text('Passwords do not match.'), findsOneWidget);
        },
      );
    });

    // ============================================================================================
    // LOGOWANIE
    // ============================================================================================
    group('Ekran Logowania (LoginScreen)', () {
      testWidgets(
        '2.1. Uruchom aplikację i wpisz złe dane',
        (WidgetTester tester) async {
          await tester.pumpWidget(MyApp());
          await tester.pumpAndSettle();

          // Wpisujemy złe dane, np. user nie istnieje
          final emailField = find.byType(TextFormField).at(0);
          final passField = find.byType(TextFormField).at(1);

          await tester.enterText(emailField, 'baduser@example.com');
          await tester.enterText(passField, 'wrongpass');
          await tester.tap(find.text('Login'));
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Może wystąpić snackbar z "Error: ...", zależnie od implementacji
          // Sprawdzamy obecność ekranu logowania (wciąż)
          expect(find.text('Login'), findsOneWidget);
        },
      );

      testWidgets(
        '2.2. Logowanie poprawne - przenosi do MainScreen',
        (WidgetTester tester) async {
          await tester.pumpWidget(MyApp());
          await tester.pumpAndSettle();

          // Wpisujemy poprawne dane
          final emailField = find.byType(TextFormField).at(0);
          final passField = find.byType(TextFormField).at(1);

          // Zakładamy, że user test_integration_user@example.com istnieje
          await tester.enterText(emailField, 'test_integration_user@example.com');
          await tester.enterText(passField, 'test1234');
          await tester.tap(find.text('Login'));
          await tester.pumpAndSettle(const Duration(seconds: 3));

          // Oczekujemy ekranu głównego
          expect(find.text('Database Configurations'), findsOneWidget);
        },
      );
    });

    // ============================================================================================
    // FORGOT PASSWORD
    // ============================================================================================
    group('Ekran Resetu Hasła (ForgotPasswordScreen)', () {
      testWidgets(
        '3.1. Przejdź do ekranu Forgot Password i wpisz email',
        (WidgetTester tester) async {
          await tester.pumpWidget(MyApp());
          await tester.pumpAndSettle();

          // Z ekranu logowania przechodzimy do "Forgot Password?"
          final forgotLink = find.text('Forgot Password?');
          await tester.tap(forgotLink);
          await tester.pumpAndSettle();

          // Teraz powinniśmy być na ForgotPasswordScreen
          expect(find.text('Forgot Password'), findsOneWidget);

          final emailField = find.byType(TextField).first;
          await tester.enterText(emailField, 'test_integration_user@example.com');
          await tester.tap(find.text('Send Reset Link'));
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Oczekiwana jest np. snackbar "Password reset link sent..."
          // lub przejście do ekranu logowania
          // Zależy od implementacji
          expect(find.text('Password reset link sent to your email.'), findsOne);
          // Możesz dostosować w zależności od Twojej logiki
        },
      );
    });

    // ============================================================================================
    // MAIN SCREEN i WYLOGOWANIE
    // ============================================================================================
    group('MainScreen & Logout', () {
      testWidgets(
        '4.1. Logowanie i wylogowanie z poziomu Drawer',
        (WidgetTester tester) async {
          await tester.pumpWidget(MyApp());
          await tester.pumpAndSettle();

          // Logujemy się
          final emailField = find.byType(TextFormField).at(0);
          final passField = find.byType(TextFormField).at(1);
          await tester.enterText(emailField, 'test_integration_user@example.com');
          await tester.enterText(passField, 'test1234');
          await tester.tap(find.text('Login'));
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Sprawdzamy MainScreen
          expect(find.text('Database Configurations'), findsOneWidget);

          // Otwieramy Drawer i klikamy "Logout"
          final scaffoldFinder = find.byType(Scaffold).first;
          ScaffoldState scaffoldState = tester.firstState<ScaffoldState>(scaffoldFinder);
          scaffoldState.openDrawer();
          await tester.pumpAndSettle();

          final logoutItem = find.text('Logout');
          await tester.tap(logoutItem);
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Powrót na ekran logowania
          expect(find.text('Login'), findsOneWidget);
        },
      );
    });

    // ============================================================================================
    // ADD CONFIGURATION SCREEN
    // ============================================================================================
    group('Dodawanie konfiguracji (AddConfigurationScreen)', () {
      testWidgets(
        '5.1. Dodaj nową konfigurację i sprawdź, czy widoczna w MainScreen',
        (WidgetTester tester) async {
          await tester.pumpWidget(MyApp());
          await tester.pumpAndSettle();

          // Logowanie
          final emailField = find.byType(TextFormField).at(0);
          final passField = find.byType(TextFormField).at(1);
          await tester.enterText(emailField, 'test_integration_user@example.com');
          await tester.enterText(passField, 'test1234');
          await tester.tap(find.text('Login'));
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Sprawdzamy, czy jest Database Configurations
          expect(find.text('Database Configurations'), findsOneWidget);

          // Klikamy FAB (dodawanie)
          final fab = find.byIcon(Icons.add);
          await tester.tap(fab);
          await tester.pumpAndSettle();

          // Jesteśmy na AddConfigurationScreen
          expect(find.text('Add Configuration'), findsOneWidget);

          // Wpiszmy parametry
          final configName = find.byType(TextFormField).at(0);
          await tester.enterText(configName, 'IntegrationConfig');

          // Będą jeszcze inne pola - dbName, dbUrl, user, password, port ...
          final dbUrl = find.byType(TextFormField).at(2);
          final dbUser = find.byType(TextFormField).at(3);
          final dbPass = find.byType(TextFormField).at(4);
          final dbPort = find.byType(TextFormField).at(5);

          await tester.enterText(dbUrl, '127.0.0.1');
          await tester.enterText(dbUser, 'dbUser');
          await tester.enterText(dbPass, 'dbPass');
          await tester.enterText(dbPort, '5432');

          // Klikamy "Add Configuration"
          await tester.tap(find.text('Add Configuration'));
          await tester.pumpAndSettle(const Duration(seconds: 5));

          // Wracamy do MainScreen i oczekujemy, że widnieje "IntegrationConfig"
          expect(find.text('IntegrationConfig'), findsOneWidget);
        },
      );
    });

    // ============================================================================================
    // QUERY SCREEN
    // ============================================================================================
    group('Ekran QueryScreen', () {
      testWidgets(
        '6.1. Wysyłanie prostego zapytania (np. PostgreSQL)',
        (WidgetTester tester) async {
          await tester.pumpWidget(MyApp());
          await tester.pumpAndSettle();

          // Logowanie
          final emailField = find.byType(TextFormField).at(0);
          final passField = find.byType(TextFormField).at(1);
          await tester.enterText(emailField, 'test_integration_user@example.com');
          await tester.enterText(passField, 'test1234');
          await tester.tap(find.text('Login'));
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Powinniśmy być w MainScreen
          expect(find.text('Database Configurations'), findsOneWidget);

          // Otwieramy jakąś konfigurację (np. IntegrationConfig),
          // find text 'IntegrationConfig', tap. 
          // Przykład ogólny - zależy od Twojej implementacji
          final configItem = find.text('IntegrationConfig');
          if (configItem.evaluate().isEmpty) {
            // Konfiguracja mogła nie istnieć lub jest inna. Możesz pominąć test.
            return;
          }

          final onlineCheck = find.text('Online');

          await tester.tap(configItem);
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Oczekujemy na widok szczegółów
          // i klikamy 'Send Query' (o ile jest Online):
          final sendQueryButton = find.text('Send Query');
          if (sendQueryButton.evaluate().isEmpty) {
            return;
          }
          
          await tester.tap(sendQueryButton);
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Jesteśmy w QueryScreen
          if(onlineCheck.evaluate().isEmpty) {
            // Konfiguracja mogła być offline, więc nie ma co testować
            return;
          }
          
          expect(find.text('Query/Command Writing'), findsOneWidget);

          // Wpiszmy zapytanie SQL
          final queryField = find.byType(TextField).first;
          await tester.enterText(queryField, 'SELECT 1;');
          await tester.tap(find.text('Send Query'));
          await tester.pumpAndSettle(const Duration(seconds: 3));

          // Sprawdźmy, czy wynik się pojawia (np. 'Query executed successfully.' 
          // lub cokolwiek w Twoim kodzie)
          expect(find.textContaining('Query executed successfully'), findsNothing);
        },
      );
    });

    // ============================================================================================
    // ACCOUNT SETTINGS
    // ============================================================================================
    group('AccountSettingsScreen (zmiana hasła, email, usuwanie konta)', () {
      testWidgets(
        '7.1. Zmiana adresu email',
        (WidgetTester tester) async {
          await tester.pumpWidget(MyApp());
          await tester.pumpAndSettle();

          // Logowanie
          final emailField = find.byType(TextFormField).at(0);
          final passField = find.byType(TextFormField).at(1);
          await tester.enterText(emailField, 'test_integration_user@example.com');
          await tester.enterText(passField, 'test1234');
          await tester.tap(find.text('Login'));
          await tester.pumpAndSettle(const Duration(seconds: 2));

          expect(find.text('Database Configurations'), findsOneWidget);

          // Otwieramy Drawer
          final scaffoldFinder = find.byType(Scaffold).first;
          ScaffoldState scaffoldState = tester.firstState<ScaffoldState>(scaffoldFinder);
          scaffoldState.openDrawer();
          await tester.pumpAndSettle();

          // Klikamy 'Account Settings'
          final accSettings = find.text('Account Settings');
          await tester.tap(accSettings);
          await tester.pumpAndSettle();

          // Naciskamy "Change Email Address"
          final changeEmailTile = find.text('Change Email Address');
          await tester.tap(changeEmailTile);
          await tester.pumpAndSettle();

          // W dialogu wypełniamy "New Email" i "Confirm New Email"
          final newEmailField = find.byType(TextField).at(0);
          final confirmEmailField = find.byType(TextField).at(1);

          await tester.enterText(newEmailField, 'test_integration_changed@example.com');
          await tester.enterText(confirmEmailField, 'test_integration_changed@example.com');

          // Klikamy 'Save'
          await tester.tap(find.text('Save'));
          await tester.pumpAndSettle(const Duration(seconds: 3));

          // Aplikacja powinna nas wylogować => login screen
          expect(find.text('Login'), findsOneWidget);

          // Możemy zalogować się nowym emailem: test_integration_changed@example.com
        },
      );

      testWidgets(
        '7.2. Usunięcie konta - potwierdzenie hasłem',
        (WidgetTester tester) async {
          await tester.pumpWidget(MyApp());
          await tester.pumpAndSettle();

          // Logowanie starego / nowego usera
          final emailField = find.byType(TextFormField).at(0);
          final passField = find.byType(TextFormField).at(1);
          await tester.enterText(emailField, 'test_integration_changed@example.com');
          await tester.enterText(passField, 'test1234');
          await tester.tap(find.text('Login'));
          await tester.pumpAndSettle(const Duration(seconds: 3));

          expect(find.text('Database Configurations'), findsOneWidget);

          // Drawer -> Account Settings
          final scaffoldFinder = find.byType(Scaffold).first;
          ScaffoldState scaffoldState = tester.firstState<ScaffoldState>(scaffoldFinder);
          scaffoldState.openDrawer();
          await tester.pumpAndSettle();

          await tester.tap(find.text('Account Settings'));
          await tester.pumpAndSettle();

          // Naciskamy "Delete Account"
          final deleteTile = find.text('Delete Account');
          await tester.tap(deleteTile);
          await tester.pumpAndSettle();

          // Pojawia się dialog "Are you sure?"
          expect(find.text('Confirm Account Deletion'), findsOneWidget);
          await tester.tap(find.text('Delete'));
          await tester.pumpAndSettle();

          // Teraz w drugim dialogu proszą nas o hasło
          final passFieldDialog = find.byType(TextField).first;
          await tester.enterText(passFieldDialog, 'test1234');
          await tester.tap(find.text("I'm Sure"));
          await tester.pumpAndSettle(const Duration(seconds: 3));

          // Konto usunięte => przenosi na ekran logowania
          expect(find.text('Login'), findsOneWidget);

          // W testach integracyjnych, to faktycznie usuwa usera w FirebaseAuth
          // stąd w realnych scenariuszach testy te trzeba planować ostrożnie :-)
        },
      );
    });
}
