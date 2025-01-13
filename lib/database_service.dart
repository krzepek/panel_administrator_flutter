import 'dart:convert';

import 'package:mysql1/mysql1.dart';
import 'package:postgres/postgres.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:mssql_connection/mssql_connection.dart';

class DatabaseService {
  Future<Map<String, dynamic>> fetchDatabaseInfo(Map<String, dynamic> config) async {
    switch (config['dbClass']) {
      case 'pgsql':
        return await _fetchPostgreSQLInfo(
          config['dbUrl'],
          config['dbPort'],
          config['dbUser'],
          config['dbPassword'],
          config['dbName'],
        );
      case 'mysql':
        return await _fetchMySQLInfo(
          config['dbUrl'],
          config['dbPort'],
          config['dbUser'],
          config['dbPassword'],
          config['dbName'],
        );
      case 'mssql':
        return await _fetchMsSQLInfo(
          config['dbUrl'],
          config['dbPort'],
          config['dbUser'],
          config['dbPassword'],
          config['dbName'],
        );
      case 'mongodb':
        return await _fetchMongoDBInfo(config['dbUrl']);
      default:
        return {'status': 'Unknown', 'size': 0};
    }
  }

  Future<Map<String, dynamic>> _fetchPostgreSQLInfo(
      String host, int port, String user, String password, String dbName) async {
    try {
      final connection = PostgreSQLConnection(host, port, dbName, username: user, password: password);
      await connection.open();

      // Use a Map for substitutionValues
      final results = await connection.query(
        'SELECT pg_database_size(@dbName) / 1024 / 1024 AS size',
        substitutionValues: {'dbName': dbName},
      );

      await connection.close();
      return {'status': 'Online', 'size': results.first[0] ?? 0};
    } catch (e) {
      return {'status': 'Error', 'size': 0};
    }
  }

  Future<Map<String, dynamic>> _fetchMySQLInfo(
      String host, int port, String user, String password, String dbName) async {
    try {
      final settings = ConnectionSettings(
        host: host,
        port: port,
        user: user,
        password: password,
        db: dbName,
      );
      final conn = await MySqlConnection.connect(settings);
      final results = await conn.query(
        'SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS size '
        'FROM information_schema.tables WHERE table_schema = ?',
        [dbName],
      );
      await conn.close();
      return {'status': 'Online', 'size': results.first['size'] ?? 0};
    } catch (e) {
      return {'status': 'Error', 'size': 0};
    }
  }

  Future<Map<String, dynamic>> _fetchMsSQLInfo(
      String host, int port, String user, String password, String dbName) async {
    try {
      final mssqlConnection = MssqlConnection.getInstance();
      final connected = await mssqlConnection.connect(
        ip: host,
        port: port.toString(),
        databaseName: dbName,
        username: user,
        password: password,
        timeoutInSeconds: 15,
      );

      if (connected) {
        final query = '''
          SELECT SUM(size) * 8.0 / 1024 AS size
          FROM sys.master_files
          WHERE database_id = DB_ID('$dbName');
        ''';
        final results = await mssqlConnection.writeData(query);

        await mssqlConnection.disconnect();

        if (results.isNotEmpty) {
          return {
            'status': 'Online',
            'size': jsonDecode(results)['size'] ?? 0,
          };
        }
      }
      return {'status': 'Online', 'size': 0};
    } catch (e) {
      return {'status': 'Error', 'size': 0};
    }
  }

  Future<Map<String, dynamic>> _fetchMongoDBInfo(String connectionString) async {
    try {
      final db = Db(connectionString);
      await db.open();
      final stats = await db.serverStatus();
      await db.close();
      return {'status': 'Online', 'size': stats['dataSize'] ?? 0};
    } catch (e) {
      return {'status': 'Error', 'size': 0};
    }
  }
}
