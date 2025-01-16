import 'dart:convert';
import 'dart:math';

import 'package:mysql1/mysql1.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:mssql_connection/mssql_connection.dart';
import 'package:postgres/postgres.dart';

class DatabaseService {
  final PostgreSQLConnection _connection = PostgreSQLConnection(
    '192.168.12.63',
    5432,
    'panel_administratora',
    username: 'admin',
    password: 'paneladministratora2025!',
  );

  Future<void> initialize() async {
    await _connection.open();
    await _createTableIfNotExists();
  }

  Future<void> _createTableIfNotExists() async {
    await _connection.query('''
      CREATE TABLE IF NOT EXISTS configurations (
        id SERIAL PRIMARY KEY,
        firebase_user_id VARCHAR(255) NOT NULL,
        configname VARCHAR(255) NOT NULL,
        dbname VARCHAR(255) NOT NULL,
        dburl VARCHAR(255) NOT NULL,
        dbuser VARCHAR(255) NOT NULL,
        dbpassword VARCHAR(255) NOT NULL,
        dbport INTEGER NOT NULL,
        dbclass VARCHAR(50) NOT NULL,
        ssl VARCHAR(3) NOT NULL,
        cluster VARCHAR(255) NOT NULL
      );
    ''');
  }

  Future<void> ensureConnectionOpen() async {
    if (_connection.isClosed) {
      await _connection.open();
    }
  }

  Future<List<Map<String, dynamic>>> fetchConfigurations(String firebaseUserId) async {
    await ensureConnectionOpen();
    final results = await _connection.mappedResultsQuery(
      'SELECT * FROM configurations WHERE firebase_user_id = @firebaseUserId',
      substitutionValues: {'firebaseUserId': firebaseUserId},
    );
    return results.map((row) => row['configurations']!).toList();
  }

  Future<void> addConfiguration(String firebaseUserId, Map<String, dynamic> config) async {
    await ensureConnectionOpen();
    await _connection.query(
      'INSERT INTO configurations (firebase_user_id, configname, dbname, dburl, dbuser, dbpassword, dbport, dbclass, ssl, cluster) VALUES (@firebaseUserId, @configname, @dbname, @dburl, @dbuser, @dbpassword, @dbport, @dbclass, @ssl, @cluster)',
      substitutionValues: {'firebaseUserId': firebaseUserId, ...config},
    );
  }

  Future<void> updateConfiguration(String id, String firebaseUserId, Map<String, dynamic> updatedConfig) async {
    await ensureConnectionOpen();
    await _connection.query(
      'UPDATE configurations SET configname = @configname, dbname = @dbname, dburl = @dburl, dbuser = @dbuser, dbpassword = @dbpassword, dbport = @dbport, dbclass = @dbclass, ssl = @ssl, cluster = @cluster WHERE id = @id AND firebase_user_id = @firebaseUserId',
      substitutionValues: {'id': id, 'firebaseUserId': firebaseUserId, ...updatedConfig},
    );
  }

  Future<void> deleteConfiguration(String id, String firebaseUserId) async {
    await ensureConnectionOpen();
    await _connection.query(
      'DELETE FROM configurations WHERE id = @id AND firebase_user_id = @firebaseUserId',
      substitutionValues: {'id': id, 'firebaseUserId': firebaseUserId},
    );
  }

  Future<Map<String, dynamic>> fetchDatabaseInfo(Map<String, dynamic> config) async {
    switch (config['dbclass']) {
      case 'pgsql':
        return await _fetchPostgreSQLInfo(
          config['dburl'],
          config['dbport'],
          config['dbuser'],
          config['dbpassword'],
          config['dbname'],
          config['ssl'],
        );
      case 'mysql':
        return await _fetchMySQLInfo(
          config['dburl'],
          config['dbport'],
          config['dbuser'],
          config['dbpassword'],
          config['dbname'],
          config['ssl'],
        );
      case 'mssql':
        return await _fetchMsSQLInfo(
          config['dburl'],
          config['dbport'],
          config['dbuser'],
          config['dbpassword'],
          config['dbname'],
          config['ssl'],
        );
      case 'mongodb':
        return await _fetchMongoDBInfo(
          config['dburl'],
          config['dbport'],
          config['dbuser'],
          config['dbpassword'],
          config['dbname'],
          config['ssl'],
          config['cluster'],
        );
      default:
        return {'status': 'Unknown', 'size': '0'};
    }
  }

  Future<Map<String, dynamic>> _fetchPostgreSQLInfo(
      String host, int port, String user, String password, String dbName, String ssl) async {
    try {
      final connection = PostgreSQLConnection(
        host,
        port,
        dbName,
        username: user,
        password: password,
        timeoutInSeconds: 5,
        useSSL: ssl == 'yes' ? true : false);
      await connection.open();

      final results = await connection.query(
        'SELECT pg_database_size(@dbname) / 1024 / 1024 AS size',
        substitutionValues: {'dbname': dbName},
      );

      await connection.close();
      return {'status': 'Online', 'size': results.first[0].toString()};
    } catch (e) {
      print('Error fetching PostgreSQL info: $e');
      return {'status': 'Error', 'size': '0'};
    }
  }

  Future<Map<String, dynamic>> _fetchMySQLInfo(
      String host, int port, String user, String password, String dbName, String ssl) async {
    try {
      final settings = ConnectionSettings(
        host: host,
        port: port,
        user: user,
        password: password,
        db: dbName,
      );
      
      final conn = await MySqlConnection.connect(settings);
      await Future.delayed(Duration(seconds: 1));
      try {
        final results = await conn.query(
          'SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS size FROM information_schema.TABLES WHERE table_schema = ? GROUP BY table_schema;', [dbName]
        );
        if (results.isNotEmpty) {
          return {'status': 'Online', 'size': results.first['size'].toString()};
        } else {
          return {'status': 'Online', 'size': "0"};
        }
      } finally {
        await conn.close();
      }
    } catch (e) {
      print('Error fetching MySQL info: $e');
      return {'status': 'Error', 'size': '0'};
    }
  }

  Future<Map<String, dynamic>> _fetchMsSQLInfo(
      String host, int port, String user, String password, String dbName, String ssl) async {
    try {
      final mssqlConnection = MssqlConnection.getInstance();
      final connected = await mssqlConnection.connect(
        ip: host,
        port: port.toString(),
        databaseName: dbName,
        username: user,
        password: password,
        timeoutInSeconds: 5,
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
            'size': jsonDecode(results)['size'].toString(),
          };
        }
      }
      return {'status': 'Online', 'size': '0'};
    } catch (e) {
      return {'status': 'Error', 'size': '0'};
    }
  }

  Future<Map<String, dynamic>> _fetchMongoDBInfo(String host, int port, String user, String password, String dbName, String ssl, String cluster) async {
    try {
      String connectionString = 'mongodb+srv://$user:$password@$cluster.$host:$port/$dbName?ssl=${ssl == 'yes' ? 'true' : 'false'}';
      var db = await Db.create(connectionString);
      await db.open(writeConcern: WriteConcern(wtimeout: 5));
      final stats = await db.runCommand({'dbStats': 1});
      await db.close();
      if(stats['dataSize'] == null) {
        return {'status': 'Online', 'size': '0'};
      } else {
        double size = int.parse(stats['dataSize'].toString())/(1024*1024);
        return {'status': 'Online', 'size': size.toStringAsFixed(2)};
      }
    } catch (e) {
      print('Error fetching MongoDB info: $e');
      return {'status': 'Error', 'size': '0'};
    }
  }
}