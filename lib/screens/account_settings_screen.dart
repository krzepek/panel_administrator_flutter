import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/session_manager.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({Key? key}) : super(key: key);

  @override
  _AccountSettingsScreenState createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _auth = FirebaseAuth.instance;
  bool _obscureTextNew = true;
  bool _obscureTextConfirm = true;
  bool _obscureTextDelete = true;

  void _toggleVisibility(String field) {
    if(mounted) {
      setState(() {
        switch(field) {
          case "new": 
            _obscureTextNew = !_obscureTextNew;
          case "confirm": 
            _obscureTextConfirm = !_obscureTextConfirm;
          case "delete": 
            _obscureTextDelete = !_obscureTextDelete;
          default:
        }
      });
    }
  }

  // Wyświetla okno dialogowe do zmiany adresu e-mail (Firebase).
  Future<void> _changeEmail(BuildContext context) async {
    String? email;
    String? confirmEmail;

    SessionManager().resetSession(context);
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Change Email Address'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'New Email'),
                    onChanged: (value) => email = value,
                  ),
                  TextField(
                    decoration:
                        const InputDecoration(labelText: 'Confirm New Email'),
                    onChanged: (value) => confirmEmail = value,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    SessionManager().resetSession(context);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    SessionManager().resetSession(context);
                    if (email == null || confirmEmail == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in both fields.'),
                        ),
                      );
                      return;
                    }
                    if (email != confirmEmail) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Emails do not match.'),
                        ),
                      );
                      return;
                    }
                    try {
                      await _auth.currentUser
                          ?.updateEmail(email!);
                      if(context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Email address updated successfully.'),
                          ),
                        );
                      }
                      await _auth.signOut();
                      if(context.mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    } catch (e) {
                      if(context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Wyświetla okno dialogowe do zmiany hasła (Firebase).
  Future<void> _changePassword(BuildContext context) async {
    String? password;
    String? confirmPassword;
    
    SessionManager().resetSession(context);
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    obscureText: _obscureTextNew,
                    decoration: InputDecoration(
                      labelText: "New password",
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureTextNew ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => _toggleVisibility("new"),
                      ),
                    ),
                    onChanged: (value) => password = value,
                  ),
                  TextField(
                    obscureText: _obscureTextConfirm,
                    decoration: InputDecoration(
                      labelText: "Confirm password",
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureTextConfirm ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => _toggleVisibility("confirm"),
                      ),
                    ),
                    onChanged: (value) => confirmPassword = value,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    SessionManager().resetSession(context);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    SessionManager().resetSession(context);
                    if (password == null || confirmPassword == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in both fields.'),
                        ),
                      );
                      return;
                    }
                    if (password != confirmPassword) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Passwords do not match.'),
                        ),
                      );
                      return;
                    }
                    try {
                      await _auth.currentUser
                          ?.updatePassword(password!);
                      if(context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password updated successfully.'),
                          ),
                        );
                      }
                      await _auth.signOut();
                      if(context.mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    } catch (e) {
                      if(context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Usuwa konto użytkownika po jego ponownym uwierzytelnieniu.
  Future<void> _deleteAccount(BuildContext context) async {
    String? password;

    SessionManager().resetSession(context);
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Account Deletion'),
          content: const Text(
              'Are you sure you want to delete your account? All configurations will also be deleted.'),
          actions: [
            TextButton(
              onPressed: () async {
                SessionManager().resetSession(context);
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                SessionManager().resetSession(context);
                Navigator.of(context).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmation != true) return;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Confirm Deletion'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                      'Enter your password to confirm account deletion.'),
                  TextField(
                    obscureText: _obscureTextDelete,
                    decoration: InputDecoration(
                      labelText: "Password",
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureTextDelete ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => _toggleVisibility("delete"),
                      ),
                    ),
                    onChanged: (value) => password = value,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async{ 
                      SessionManager().resetSession(context);
                      Navigator.of(context).pop();
                    },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    SessionManager().resetSession(context);
                    if (password == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password is required.'),
                        ),
                      );
                      return;
                    }
                    try {
                      final user = _auth.currentUser;
                      final credential = EmailAuthProvider.credential(
                          email: user?.email ?? '', password: password!);
                      await user?.reauthenticateWithCredential(credential);
                      await user?.delete();
                      SessionManager().stopSession();
                      if(context.mounted) {
                        Navigator.of(context).pop();
                        Navigator.pushReplacementNamed(context, '/login');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Account deleted successfully.'),
                          ),
                        );
                      }
                    } catch (e) {
                      if(context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('I\'m Sure'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Change Email Address'),
            onTap: () => _changeEmail(context),
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Change Password'),
            onTap: () => _changePassword(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete Account'),
            onTap: () => _deleteAccount(context),
          ),
        ],
      ),
    );
  }
}