import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'database_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _auth = FirebaseAuth.instance;
  final _dbRef = FirebaseDatabase.instance.ref();
  final DatabaseService _databaseService = DatabaseService();
  List<Map<String, dynamic>> _configurations = [];
  Map<String, Map<String, dynamic>> _dynamicInfo = {};
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initializeConfigurationsAndRefresh();
    _startPeriodicRefresh();
  }

  Future<void> _initializeConfigurationsAndRefresh() async {
  await _fetchConfigurations();
  await _refreshDatabaseInfo();
}

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (mounted) {
        _refreshDatabaseInfo();
      }
    });
  }

  Future<void> _fetchConfigurations() async {
    final userId = _auth.currentUser?.uid ?? '';
    final snapshot = await _dbRef.child('databases/$userId').get();

    if (snapshot.exists) {
      setState(() {
        final data = snapshot.value as Map<dynamic, dynamic>;
        _configurations = data.entries.map((e) {
          final value = Map<String, dynamic>.from(e.value as Map);
          return {'id': e.key.toString(), ...value};
        }).toList();
      });
    }
  }

  Future<void> _refreshDatabaseInfo() async {
    final userId = _auth.currentUser?.uid ?? '';
    final updatedInfo = <String, Map<String, dynamic>>{};

    for (var config in _configurations) {
      final configId = config['id'];
      try {
        final dbInfo = await _databaseService.fetchDatabaseInfo(config);
        updatedInfo[configId] = dbInfo;

        await _dbRef.child('databases/$userId/$configId').update({
          'dbSize': dbInfo['size'],
          'lastChecked': DateTime.now().millisecondsSinceEpoch,
        });
      } catch (e) {
        updatedInfo[configId] = {'status': 'Error', 'size': 0};
      }
    }

    setState(() {
      _dynamicInfo = updatedInfo;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Database Configurations')),
      drawer: Drawer(
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(_auth.currentUser?.email ?? 'Guest'),
              accountEmail: const Text(''),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Account Settings'),
              onTap: () {
                Navigator.pushNamed(context, '/account-settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: _configurations.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _configurations.length,
              itemBuilder: (context, index) {
                final config = _configurations[index];
                final dynamicInfo = _dynamicInfo[config['id']] ?? {'status': 'Unknown', 'size': 0};

                // Determine diode color
                final diodeColor = dynamicInfo['status'] == 'Online'
                    ? Colors.green
                    : (dynamicInfo['status'] == 'Error' ? Colors.red : Colors.grey);

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: _buildStatusDiode(diodeColor), // Diode for status
                    title: Text(config['dbName']),
                    subtitle: Text(
                      'Status: ${dynamicInfo['status']}\nSize: ${dynamicInfo['size']} MB',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteConfiguration(config['id']),
                    ),
                    onTap: () => _navigateToDetails(config),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddConfiguration,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Builds the diode widget for status indication
  Widget _buildStatusDiode(Color color) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  void _deleteConfiguration(String id) async {
    final userId = _auth.currentUser?.uid ?? '';
    await _dbRef.child('databases/$userId/$id').remove();
    _fetchConfigurations();
  }

  void _navigateToDetails(Map<String, dynamic> config) {
    Navigator.pushNamed(context, '/configuration-detail', arguments: config).then((_) {
      _fetchConfigurations();
    });
  }

  void _logout() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _navigateToAddConfiguration() {
    Navigator.pushNamed(context, '/add-configuration').then((_) {
      _fetchConfigurations();
    });
  }
}
