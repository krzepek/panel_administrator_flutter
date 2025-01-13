import 'dart:async';
import 'package:flutter/material.dart';
import 'database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Map<String, dynamic>> _configurations = [];
  Map<String, Map<String, dynamic>> _dynamicInfo = {};
  final _auth = FirebaseAuth.instance;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initializeDatabaseAndFetchConfigurations();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeDatabaseAndFetchConfigurations() async {
    await _databaseService.initialize();
    await _fetchConfigurations();
    _refreshDatabaseInfo();
    _startPeriodicRefresh();
  }

  Future<void> _fetchConfigurations() async {
    try {
      final userId = _auth.currentUser?.uid ?? '';
      final configurations = await _databaseService.fetchConfigurations(userId);
      setState(() {
        _configurations = configurations;
      });
    } catch (e) {
      print('Error fetching configurations: $e');
    }
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (mounted) {
        _refreshDatabaseInfo();
      }
    });
  }

  Future<void> _refreshDatabaseInfo() async {
    final updatedInfo = <String, Map<String, dynamic>>{};

    for (var config in _configurations) {
      final configId = config['id'].toString();
      try {
        final dbInfo = await _databaseService.fetchDatabaseInfo(config);
        updatedInfo[configId] = dbInfo;
      } catch (e) {
        updatedInfo[configId] = {'status': 'Error', 'size': '0'};
      }
    }

    setState(() {
      _dynamicInfo = updatedInfo;
    });
  }

  Future<void> _deleteConfiguration(String id) async {
    try {
      final userId = _auth.currentUser?.uid ?? '';
      await _databaseService.deleteConfiguration(id, userId);
      await _fetchConfigurations();
    } catch (e) {
      print('Error deleting configuration: $e');
    }
  }

  void _navigateToDetails(Map<String, dynamic> config) {
    _refreshTimer?.cancel();
    Navigator.pushNamed(context, '/configuration-detail', arguments: config).then((_) {
      _fetchConfigurations().then((_) => _refreshDatabaseInfo());
      _startPeriodicRefresh();
    });
  }

  void _navigateToAddConfiguration() {
    _refreshTimer?.cancel();
    Navigator.pushNamed(context, '/add-configuration').then((_) {
        _fetchConfigurations().then((_) => _refreshDatabaseInfo());
        _startPeriodicRefresh();
    });
  }

  void _logout() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
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
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchConfigurations();
          await _refreshDatabaseInfo();
        },
        child: _configurations.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _configurations.length,
                itemBuilder: (context, index) {
                  final config = _configurations[index];
                  final dynamicInfo = _dynamicInfo[config['id'].toString()] ?? {'status': 'Unknown', 'size': 0};

                  // Determine diode color
                  final diodeColor = dynamicInfo['status'] == 'Online'
                      ? Colors.green
                      : (dynamicInfo['status'] == 'Error' ? Colors.red : Colors.grey);

                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      leading: _buildStatusDiode(diodeColor), // Diode for status
                      title: _buildTitle(config),
                      subtitle: Text(
                        'Status: ${dynamicInfo['status']}\n Size: ${dynamicInfo['size'].toString()} MB',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteConfiguration(config['id'].toString()),
                      ),
                      onTap: () => _navigateToDetails(config),
                    ),
                  );
                },
              ),
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

  Widget _buildTitle(Map<String, dynamic> config) {
    return Text(
      config['configname'],
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
  }
}
