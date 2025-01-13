// Updated add_configuration_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'database_service.dart';

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
  final _configNameController = TextEditingController();
  String _dbType = 'mysql'; // Default type
  final List<String> databaseTypes = ['mysql', 'mssql', 'mongodb', 'pgsql'];
  final _auth = FirebaseAuth.instance;
  final DatabaseService _databaseService = DatabaseService();

  void _saveConfiguration() async {
    final userId = _auth.currentUser?.uid ?? '';

    final newConfig = {
      'configname': _configNameController.text,
      'dbname': ['mysql', 'mssql', 'pgsql'].contains(_dbType) ?_dbNameController.text : '',
      'dburl': ['mysql', 'mssql', 'pgsql'].contains(_dbType) ? _dbUrlController.text : '',
      'dbuser': ['mysql', 'mssql', 'pgsql'].contains(_dbType) ? _dbUserController.text : '',
      'dbpassword': ['mysql', 'mssql', 'pgsql'].contains(_dbType) ? _dbPasswordController.text : '',
      'dbport': ['mysql', 'mssql', 'pgsql'].contains(_dbType) ? int.tryParse(_dbPortController.text) ?? 0 : 0,
      'dbconnectionstring': _dbType == 'mongodb' ? _dbConnectionStringController.text : '',
      'dbclass': _dbType,
    };

    try {
      await _databaseService.addConfiguration(userId, newConfig);
      if(mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error adding configuration: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Configuration')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            shrinkWrap: true,
            children: [
              TextFormField(
                controller: _configNameController,
                decoration: const InputDecoration(labelText: 'Configuration Name'),
              ),
              DropdownButtonFormField<String>(
                value: _dbType,
                items: databaseTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _dbType = value!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Database Type'),
              ),
              if (['mysql', 'mssql', 'pgsql'].contains(_dbType)) ...[
                TextFormField(
                  controller: _dbNameController,
                  decoration: const InputDecoration(labelText: 'Database Name'),
                ),
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
              ] else if (_dbType == 'mongodb') ...[
                TextFormField(
                  controller: _dbConnectionStringController,
                  decoration: const InputDecoration(labelText: 'Connection String'),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveConfiguration,
                child: const Text('Add Configuration'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
