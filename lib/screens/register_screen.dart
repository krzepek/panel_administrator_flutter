import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/session_manager.dart';
import '../services/token_service.dart';
import '../models/password_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repeatPasswordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  void registerUser() async {
    if (_passwordController.text.trim() !=
        _repeatPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    try {
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account created successfully!'))
        );
      }
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
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
          SnackBar(content: Text('Registration failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            PasswordField(
                  controller: _passwordController,
                  label: 'Password',
                  enabled: true,
            ),
            PasswordField(
                  controller: _repeatPasswordController,
                  label: 'Repeat Password',
                  enabled: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: registerUser,
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
