import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AddConfigurationScreen extends StatefulWidget {
  const AddConfigurationScreen({Key? key}) : super(key: key);

  @override
  _AddConfigurationScreenState createState() => _AddConfigurationScreenState();
}

class _AddConfigurationScreenState extends State<AddConfigurationScreen> {
  final _dbNameController = TextEditingController();
  final _dbUrlController = TextEditingController();
  final _dbUserController = TextEditingController();
  final _dbPasswordController = TextEditingController();
  final _dbPortController = TextEditingController();
  final _dbConnectionStringController = TextEditingController();
  String _dbClass = 'mysql';
  final _auth = FirebaseAuth.instance;
  final _dbRef = FirebaseDatabase.instance.ref();

  void _saveConfiguration() async {
    final userId = _auth.currentUser?.uid ?? '';
    final id = _dbRef.child('databases/$userId').push().key;
    final config = {
      'id': id,
      'dbName': _dbNameController.text,
      'dbUrl': _dbUrlController.text,
      'dbUser': _dbUserController.text,
      'dbPassword': _dbPasswordController.text,
      'dbPort': int.tryParse(_dbPortController.text) ?? 0,
      'dbConnectionString': _dbClass == 'mongodb' ? _dbConnectionStringController.text : '',
      'dbClass': _dbClass,
      'dbStatus': 'Unknown',
      'dbSize': 0,
      'creationDate': DateTime.now().millisecondsSinceEpoch,
    };

    await _dbRef.child('databases/$userId/$id').set(config);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Configuration')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _dbNameController,
              decoration: const InputDecoration(labelText: 'Database Name'),
            ),
            DropdownButtonFormField<String>(
              value: _dbClass,
              items: const [
                DropdownMenuItem(value: 'mongodb', child: Text('mongodb')),
                DropdownMenuItem(value: 'mysql', child: Text('mysql')),
                DropdownMenuItem(value: 'mssql', child: Text('mssql')),
                DropdownMenuItem(value: 'pgsql', child: Text('pgsql')),
              ],
              onChanged: (value) {
                setState(() {
                  _dbClass = value!;
                });
              },
              decoration: const InputDecoration(labelText: 'Database Type'),
            ),
            if (['mysql', 'mssql', 'pgsql'].contains(_dbClass)) ...[
              TextFormField(
                controller: _dbUrlController,
                decoration: const InputDecoration(labelText: 'URL'),
              ),
              TextFormField(
                controller: _dbUserController,
                decoration: const InputDecoration(labelText: 'User'),
              ),
              TextFormField(
                controller: _dbPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              TextFormField(
                controller: _dbPortController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Port'),
              ),
            ] else ...[
              TextFormField(
                controller: _dbConnectionStringController,
                decoration: const InputDecoration(labelText: 'Connection String'),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveConfiguration,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
