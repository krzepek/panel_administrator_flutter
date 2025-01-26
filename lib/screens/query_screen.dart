import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/session_manager.dart';

class QueryScreen extends StatefulWidget {
  final Map<String, dynamic> config;

  const QueryScreen({Key? key, required this.config}) : super(key: key);

  @override
  _QueryScreenState createState() => _QueryScreenState();
}

class _QueryScreenState extends State<QueryScreen> {
  final TextEditingController _queryController = TextEditingController();
  String? _result;
  bool _isLoading = false;

  Future<void> _sendQuery() async {
    if(mounted) {
      setState(() {
        _isLoading = true;
        _result = null;
      });
    }
    try {
      final result = await _executeQuery(
        widget.config,
        _queryController.text.trim(),
      );
      if(mounted) {
        setState(() {
          _result = result;
        });
      }
    } catch (e) {
      if(mounted) {
        setState(() {
          _result = 'Error: $e';
        });
      }
    } finally {
      if(mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String> _executeQuery(Map<String, dynamic> config, String query) async {
    final dbService = DatabaseService();

    switch (config['dbclass']) {
      case 'pgsql':
        return await dbService.executePostgreSQLQuery(config, query, context);
      case 'mysql':
        return await dbService.executeMySQLQuery(config, query, context);
      case 'mssql':
        return await dbService.executeMSSQLQuery(config, query, context);
      case 'mongodb':
        return await dbService.executeMongoDBQuery(config, query, context);
      default:
        throw Exception('Unsupported database type: ${config['dbclass']}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Query/Command Writing')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _queryController,
              decoration: InputDecoration(
                labelText: widget.config['dbclass'] == 'mongodb' ? 'Enter your MongoDB command' : 'Enter your SQL query',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                  try{
                  SessionManager().resetSession(context);
                  _sendQuery;
                  } catch (e) {
                    print("Moze tutaj $e");
                  }
                },
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Text(widget.config['dbclass'] == 'mongodb' ? 'Send Command' : 'Send Query'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: _result != null
                    ? Text(
                        _result!,
                        style: const TextStyle(fontFamily: 'Courier'),
                      )
                    : const Text('No results to display'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
