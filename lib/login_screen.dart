import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'token_service.dart';
import 'session_manager.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  Future<void> loginUser(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final userId = userCredential.user?.uid ?? '';
      await TokenService().generateToken(userId);
      if(mounted) {
        SessionManager().startSession(context);
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Login'),
          automaticallyImplyLeading: false,
          ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final email = _emailController.text.trim();
                  final password = _passwordController.text.trim();
                  loginUser(email, password);
                },
                child: const Text('Login'),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                child: const Text('Forgot Password?'),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: const Text('Don\'t have an account? Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
