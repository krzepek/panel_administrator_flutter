import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ConfigurationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> config;

  const ConfigurationDetailScreen({Key? key, required this.config}) : super(key: key);

  @override
  _ConfigurationDetailScreenState createState() => _ConfigurationDetailScreenState();
}

class _ConfigurationDetailScreenState extends State<ConfigurationDetailScreen> {
  final _dbNameController = TextEditingController();
  final _dbUrlController = TextEditingController();
  final _dbUserController = TextEditingController();
  final _dbPasswordController = TextEditingController();
  final _dbPortController = TextEditingController();
  final _dbConnectionStringController = TextEditingController();
  late String _dbType;
  bool _isEditing = false;
  final _auth = FirebaseAuth.instance;
  final _dbRef = FirebaseDatabase.instance.ref();

  final List<String> databaseTypes = ['mysql', 'mssql', 'mongodb', 'pgsql'];

  @override
  void initState() {
    super.initState();
    final config = widget.config;
    _dbNameController.text = config['dbName'];
    _dbUrlController.text = config['dbUrl'];
    _dbUserController.text = config['dbUser'];
    _dbPasswordController.text = config['dbPassword'];
    _dbPortController.text = config['dbPort'].toString();
    _dbConnectionStringController.text = config['dbConnectionString'];
    _dbType = config['dbClass']; // Assume this stores specific type like 'mysql', 'mongodb', etc.
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveConfiguration() async {
    final userId = _auth.currentUser?.uid ?? '';
    final configId = widget.config['id'];
    final updatedConfig = {
      'dbName': _dbNameController.text,
      'dbUrl': ['mysql', 'mssql', 'pgsql'].contains(_dbType) ? _dbUrlController.text : '',
      'dbUser': ['mysql', 'mssql', 'pgsql'].contains(_dbType) ? _dbUserController.text : '',
      'dbPassword': ['mysql', 'mssql', 'pgsql'].contains(_dbType) ? _dbPasswordController.text : '',
      'dbPort': ['mysql', 'mssql', 'pgsql'].contains(_dbType) ? int.tryParse(_dbPortController.text) ?? 0 : 0,
      'dbConnectionString': _dbType == 'mongodb' ? _dbConnectionStringController.text : '',
      'dbClass': _dbType,
    };

    await _dbRef.child('databases/$userId/$configId').update(updatedConfig);
    Navigator.pop(context, true); // Return true to refresh the previous screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.config['dbName']),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.cancel : Icons.edit),
            onPressed: _toggleEditMode,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _dbNameController,
              decoration: const InputDecoration(labelText: 'Database Name'),
              enabled: _isEditing,
            ),
            DropdownButtonFormField<String>(
              value: _dbType,
              items: databaseTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: _isEditing
                  ? (value) {
                      setState(() {
                        _dbType = value!;
                      });
                    }
                  : null,
              decoration: const InputDecoration(labelText: 'Database Type'),
            ),
            if (['mysql', 'mssql', 'pgsql'].contains(_dbType)) ...[
              TextFormField(
                controller: _dbUrlController,
                decoration: const InputDecoration(labelText: 'URL'),
                enabled: _isEditing,
              ),
              TextFormField(
                controller: _dbUserController,
                decoration: const InputDecoration(labelText: 'User'),
                enabled: _isEditing,
              ),
              TextFormField(
                controller: _dbPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                enabled: _isEditing,
              ),
              TextFormField(
                controller: _dbPortController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Port'),
                enabled: _isEditing,
              ),
            ] else if (_dbType == 'mongodb') ...[
              TextFormField(
                controller: _dbConnectionStringController,
                decoration: const InputDecoration(labelText: 'Connection String'),
                enabled: _isEditing,
              ),
            ],
            const SizedBox(height: 16),
            if (_isEditing)
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
