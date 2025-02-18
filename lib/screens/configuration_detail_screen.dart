import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/session_manager.dart';
import '../services/database_service.dart';
import '../models/password_field.dart';

class ConfigurationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> config;
  final dynamic status;

  const ConfigurationDetailScreen({Key? key, required this.config, required this.status}) : super(key: key);

  @override
  _ConfigurationDetailScreenState createState() => _ConfigurationDetailScreenState();
}

class _ConfigurationDetailScreenState extends State<ConfigurationDetailScreen> {
  final _dbNameController = TextEditingController();
  final _dbUrlController = TextEditingController();
  final _dbUserController = TextEditingController();
  final _dbPasswordController = TextEditingController();
  final _dbPortController = TextEditingController();
  final _clusterController = TextEditingController();
  final _configNameController = TextEditingController();
  late String _dbType;
  late String _sslType;
  bool _isEditing = false;
  final _auth = FirebaseAuth.instance;
  final DatabaseService _databaseService = DatabaseService();
  final List<String> databaseTypes = ['mysql', 'mssql', 'mongodb', 'pgsql'];
  final List<String> sslTypes = ['yes', 'no'];

  @override
  void initState() {
    super.initState();
    final config = widget.config;
    _dbNameController.text = config['dbname'];
    _dbUrlController.text = config['dburl'];
    _dbUserController.text = config['dbuser'];
    _dbPasswordController.text = config['dbpassword'];
    _dbPortController.text = config['dbport'] != '' ? config['dbport'].toString() : '';
    _clusterController.text = config['cluster'];
    _dbType = config['dbclass'];
    _configNameController.text = config['configname'];
    _sslType = config['ssl'];
  }

  @override
  void dispose() {
    _dbNameController.dispose();
    _dbUrlController.dispose();
    _dbUserController.dispose();
    _dbPasswordController.dispose();
    _dbPortController.dispose();
    _clusterController.dispose();
    super.dispose();
  }

  // Przełącza tryb edycji konfiguracji (pola włączone/wyłączone).
  void _toggleEditMode() {
    if(mounted) {
      setState(() {
        _isEditing = !_isEditing;
      });
    }
  }

  // Zapisuje zmodyfikowaną konfigurację w bazie (DatabaseService).
  void _saveConfiguration() async {
    final userId = _auth.currentUser?.uid ?? '';
    final configId = widget.config['id'];
    final updatedConfig = {
      'dbname': _dbNameController.text,
      'dburl': _dbUrlController.text,
      'dbuser': _dbUserController.text,
      'dbpassword': _dbPasswordController.text,
      'dbport': int.tryParse(_dbPortController.text) ?? 0,
      'cluster': _dbType == 'mongodb' ? _clusterController.text: '',
      'ssl': _sslType,
      'dbclass': _dbType,
      'configname': _configNameController.text,
    };

    try {
      await _databaseService.updateConfiguration(configId.toString(), userId, updatedConfig, context);
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
                        if(mounted) {
                          setState(() {
                            _dbType = value!;
                          });
                        }
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
                PasswordField(
                  controller: _dbPasswordController,
                  label: 'Password',
                  enabled: _isEditing,
                ),
                TextFormField(
                  controller: _dbPortController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Port'),
                  enabled: _isEditing,
                ),
                DropdownButtonFormField<String>(
                  value: _sslType,
                  items: sslTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: _isEditing
                      ? (value) {
                          if(mounted) {
                            setState(() {
                              _sslType = value!;
                            });
                          }
                        }
                      : null,
                  decoration: const InputDecoration(labelText: 'Require SSL'),
                ),
              ] else if (_dbType == 'mongodb') ...[
                TextFormField(
                  controller: _dbNameController,
                  decoration: const InputDecoration(labelText: 'Database Name'),
                  enabled: _isEditing,
                ),
                TextFormField(
                  controller: _clusterController,
                  decoration: const InputDecoration(labelText: 'Cluster'),
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
                PasswordField(
                  controller: _dbPasswordController,
                  label: 'Password',
                  enabled: _isEditing,
                ),
                TextFormField(
                  controller: _dbPortController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Port'),
                  enabled: _isEditing,
                ),
                DropdownButtonFormField<String>(
                  value: _sslType,
                  items: sslTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: _isEditing
                      ? (value) {
                          if(mounted) {
                            setState(() {
                              _sslType = value!;
                            });
                          }
                        }
                      : null,
                  decoration: const InputDecoration(labelText: 'Require SSL'),
                ),
              ],
              const SizedBox(height: 16),
              if (_isEditing)
                ElevatedButton(
                  onPressed: () async {
                    SessionManager().resetSession(context);
                    _saveConfiguration;
                  },
                  child: const Text('Save'),
                ),
              ElevatedButton(
                onPressed: widget.status == 'Online'
                    ? () async {
                        SessionManager().resetSession(context);
                        Navigator.pushNamed(context, '/query-screen', arguments: widget.config,);
                       }
                    : null,
                child: const Text('Send Query'),
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
