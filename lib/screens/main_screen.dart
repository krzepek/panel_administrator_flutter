import 'dart:async';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/token_service.dart';
import '../services/session_manager.dart';

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
  bool _isLoading = true;
  String? _errorMessage;


  @override
  void initState() {
    super.initState();
    _initializeDatabaseAndFetchConfigurations();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    SessionManager().stopSession();
    super.dispose();
  }

  Future<void> _initializeDatabaseAndFetchConfigurations() async {
    try{
      final isValid = await TokenService().isTokenValid();
      if(mounted) {
        if (!isValid) {
          await TokenService().clearToken();
          if(mounted) {
            
          }
          return;
        }

        await _databaseService.initialize(context);
        await _fetchConfigurations();
        await _refreshDatabaseInfo();
        await _startPeriodicRefresh();
      }
    } catch (e) {
      if(mounted) {
        setState(() {
          _isLoading = false;
          _configurations = [];
          _errorMessage = '$e';
        });
      }
    }
  }

  // Pobiera konfiguracje baz danych z serwera i wyświetla je w liście.
  Future<void> _fetchConfigurations() async {
    if(mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      await _databaseService.ensureConnectionOpen();
      final userId = _auth.currentUser?.uid ?? '';
      if(mounted) {
        final configurations = await _databaseService.fetchConfigurations(userId, context);
        setState(() {
          _configurations = configurations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if(mounted) {
        setState(() {
          _isLoading = false;
          _configurations = [];
          _errorMessage = 'Error fetching configurations: $e';
        });
      }
    }
  }

  // Regularnie odświeża informacje o statusie i rozmiarze każdej bazy.
  Future<void> _startPeriodicRefresh() async {
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (timer) async {
      if (mounted) {
        await _refreshDatabaseInfo();
      }
    });
  }

  // Pobiera informacje o statusie i rozmiarze każdej bazy.
  Future<void> _refreshDatabaseInfo() async {
    try {
      if(SessionManager().checkSession()) {
        await _databaseService.ensureConnectionOpen();

        final updatedInfo = <String, Map<String, dynamic>>{};
        for (var config in _configurations) {
          final configId = config['id'].toString();
          try {
            if(mounted) {
              final dbInfo = await _databaseService.fetchDatabaseInfo(config, context);
              updatedInfo[configId] = dbInfo;
            }
          } catch (e) {
            updatedInfo[configId] = {'status': 'Error', 'size': '0'};
          }
        }

        if (mounted) {
          setState(() {
            _dynamicInfo = updatedInfo;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _configurations = [];
          _dynamicInfo = {};
          _errorMessage = 'Lost connection to the database. Please check your connection.';
        });
      }
    }
  }

  // Wyświetla okno dialogowe z potwierdzeniem usunięcia konfiguracji.
  Future<bool?> _showDeleteConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this configuration?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Cancel
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Confirm
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Usuwa konfigurację z serwera.
  Future<void> _deleteConfiguration(String id) async {
    SessionManager().resetSession(context);
    final shouldDelete = await _showDeleteConfirmationDialog();
    if (shouldDelete == true) {
      try {
        final userId = _auth.currentUser?.uid ?? '';
        if(mounted) {
        await _databaseService.deleteConfiguration(id, userId, context);
        }
        await _fetchConfigurations();
      } catch (e) {
        print('Error deleting configuration: $e');
      }
    }
  }

  // Przechodzi do ekranu szczegółów konfiguracji.
  void _navigateToDetails(Map<String, dynamic> config, dynamic status) {
    SessionManager().resetSession(context);
    _refreshTimer?.cancel();
    Navigator.pushNamed(
      context,
      '/configuration-detail',
      arguments: {
        'config': config,
        'status': status,
      },
    ).then((_) {
      _fetchConfigurations().then((_) => _refreshDatabaseInfo());
      _startPeriodicRefresh();
    });
  }

  // Przechodzi do ekranu dodawania nowej konfiguracji.
  void _navigateToAddConfiguration() {
    SessionManager().resetSession(context);
    _refreshTimer?.cancel();
    Navigator.pushNamed(context, '/add-configuration').then((_) {
        _fetchConfigurations().then((_) => _refreshDatabaseInfo());
        _startPeriodicRefresh();
    });
  }

  void _logout() async {
    SessionManager().stopSession();
    await TokenService().clearToken();
    await _auth.signOut();
    if(mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
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
                SessionManager().resetSession(context);
                Navigator.of(context).pop();
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
          SessionManager().resetSession(context);
          await _fetchConfigurations();
          await _refreshDatabaseInfo();
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.warning, color: Colors.red, size: 60),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : _configurations.isEmpty
                    ? ListView(
                      physics: AlwaysScrollableScrollPhysics(),
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.info_outline, color: Colors.blue, size: 60),
                              SizedBox(height: 16),
                              Text(
                                'No configurations found.\nPull down to refresh.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _configurations.length,
                        itemBuilder: (context, index) {
                          final config = _configurations[index];
                          final dynamicInfo =
                              _dynamicInfo[config['id'].toString()] ?? {'status': 'Unknown', 'size': 0};

                          final diodeColor = dynamicInfo['status'] == 'Online'
                              ? Colors.green
                              : (dynamicInfo['status'] == 'Error' ? Colors.red : Colors.grey);

                          return Card(
                            margin: const EdgeInsets.all(8),
                            child: ListTile(
                              leading: _buildStatusDiode(diodeColor),
                              title: _buildTitle(config),
                              subtitle: Text(
                                'Status: ${dynamicInfo['status']}\n Size: ${dynamicInfo['size'].toString()} MB',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteConfiguration(config['id'].toString()),
                              ),
                              onTap: () => _navigateToDetails(config, dynamicInfo['status']),
                            ),
                          );
                        },
                      ),
      ),
      bottomNavigationBar: BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: FloatingActionButton(
              onPressed: _navigateToAddConfiguration,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    ),
    );
  }

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
