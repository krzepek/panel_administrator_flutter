import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'database_service.dart';

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
  final _configNameController = TextEditingController();
  late String _dbType;
  bool _isEditing = false;
  final _auth = FirebaseAuth.instance;
  final DatabaseService _databaseService = DatabaseService();
  final List<String> databaseTypes = ['mysql', 'mssql', 'mongodb', 'pgsql'];

  @override
  void initState() {
    super.initState();
    final config = widget.config;
    _dbNameController.text = config['dbname'];
    _dbUrlController.text = config['dburl'];
    _dbUserController.text = config['dbuser'];
    _dbPasswordController.text = config['dbpassword'];
    _dbPortController.text = config['dbport'] != '' ? config['dbport'].toString() : '';
    _dbConnectionStringController.text = config['dbconnectionstring'];
    _dbType = config['dbclass'];
    _configNameController.text = config['configname'];
  }

  @override
  void dispose() {
    _dbNameController.dispose();
    _dbUrlController.dispose();
    _dbUserController.dispose();
    _dbPasswordController.dispose();
    _dbPortController.dispose();
    _dbConnectionStringController.dispose();
    super.dispose();
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
      'dbname': ['mysql', 'mssql', 'pgsql'].contains(_dbType) ? _dbNameController.text : '',
      'dburl': ['mysql', 'mssql', 'pgsql'].contains(_dbType) ? _dbUrlController.text : '',
      'dbuser': ['mysql', 'mssql', 'pgsql'].contains(_dbType) ? _dbUserController.text : '',
      'dbpassword': ['mysql', 'mssql', 'pgsql'].contains(_dbType) ? _dbPasswordController.text : '',
      'dbport': ['mysql', 'mssql', 'pgsql'].contains(_dbType) ? int.tryParse(_dbPortController.text) ?? 0 : 0,
      'dbconnectionstring': _dbType == 'mongodb' ? _dbConnectionStringController.text : '',
      'dbclass': _dbType,
      'configname': _configNameController.text,
    };

    try {
      await _databaseService.updateConfiguration(configId.toString(), userId, updatedConfig);
      if(mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error updating configuration: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildTitle(),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.cancel : Icons.edit),
            onPressed: _toggleEditMode,
          ),
        ],
      ),
      body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                controller: _configNameController,
                decoration: const InputDecoration(labelText: 'Configuration Name'),
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
                  controller: _dbNameController,
                  decoration: const InputDecoration(labelText: 'Database Name'),
                  enabled: _isEditing,
                ),
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
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      _configNameController.text,
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
  }
}
