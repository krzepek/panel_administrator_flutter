import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:mssql_connection/mssql_connection.dart';
import 'package:postgres/postgres.dart';
import '../config.dart';
import 'token_service.dart';
import '../utils/encryption_util.dart';

class DatabaseService {
  PostgreSQLConnection _connection = PostgreSQLConnection(
    dbHost,
    dbPort,
    dbName,
    username: dbUsername,
    password: dbPassword,
    timeoutInSeconds: 10,
  );

  final TokenService _tokenService = TokenService();

  Future<void> initialize(BuildContext context) async {
    try{
      await ensureTokenIsValid(context);
      await ensureConnectionOpen();
      await _createTableIfNotExists();
    } catch (e) {
      throw '$e';
    }
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
    try {
      if (_connection.isClosed) {
        await _connection.open();
      }
    } catch (e) {
      await _recreateConnection();
    }
  }

  Future<void> _recreateConnection() async {
    try {
      if (!_connection.isClosed) {
        await _connection.close();
      }

      _connection = PostgreSQLConnection(
        dbHost,
        dbPort,
        dbName,
        username: dbUsername,
        password: dbPassword,
        timeoutInSeconds: 10,
      );

      await _connection.open();
    } catch (e) {
      throw "Failed to recreate the connection.";
    }
  }

  Future<void> ensureTokenIsValid(BuildContext context) async {
  final isValid = await _tokenService.isTokenValid();
  if (!isValid) {
    if(context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid or expired token. Please log in again.')),
      );
    }
    await _tokenService.clearToken();
    if(context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}


  Future<List<Map<String, dynamic>>> fetchConfigurations(String firebaseUserId, BuildContext context) async {
    await ensureTokenIsValid(context);
    await ensureConnectionOpen();
    final results = await _connection.mappedResultsQuery(
      'SELECT * FROM configurations WHERE firebase_user_id = @firebaseUserId',
      substitutionValues: {'firebaseUserId': firebaseUserId},
    );
    final configurations = results.map((row) {
      final config = row['configurations']!;
      config['dbpassword'] = EncryptionUtil.decryptPassword(config['dbpassword']);
      return config;
    }).toList();

    return configurations;
  }

  Future<void> addConfiguration(String firebaseUserId, Map<String, dynamic> config, BuildContext context) async {
    await ensureTokenIsValid(context);
    await ensureConnectionOpen();
    config['dbpassword'] = EncryptionUtil.encryptPassword(config['dbpassword']);
    await _connection.query(
      'INSERT INTO configurations (firebase_user_id, configname, dbname, dburl, dbuser, dbpassword, dbport, dbclass, ssl, cluster) VALUES (@firebaseUserId, @configname, @dbname, @dburl, @dbuser, @dbpassword, @dbport, @dbclass, @ssl, @cluster)',
      substitutionValues: {'firebaseUserId': firebaseUserId, ...config},
    );
  }

  Future<void> updateConfiguration(String id, String firebaseUserId, Map<String, dynamic> updatedConfig, BuildContext context) async {
    await ensureTokenIsValid(context);
    await ensureConnectionOpen();
    updatedConfig['dbpassword'] = EncryptionUtil.encryptPassword(updatedConfig['dbpassword']);
    await _connection.query(
      'UPDATE configurations SET configname = @configname, dbname = @dbname, dburl = @dburl, dbuser = @dbuser, dbpassword = @dbpassword, dbport = @dbport, dbclass = @dbclass, ssl = @ssl, cluster = @cluster WHERE id = @id AND firebase_user_id = @firebaseUserId',
      substitutionValues: {'id': id, 'firebaseUserId': firebaseUserId, ...updatedConfig},
    );
  }

  Future<void> deleteConfiguration(String id, String firebaseUserId, BuildContext context) async {
    await ensureTokenIsValid(context);
    await ensureConnectionOpen();
    await _connection.query(
      'DELETE FROM configurations WHERE id = @id AND firebase_user_id = @firebaseUserId',
      substitutionValues: {'id': id, 'firebaseUserId': firebaseUserId},
    );
  }

  Future<Map<String, dynamic>> fetchDatabaseInfo(Map<String, dynamic> config, BuildContext context) async {
    switch (config['dbclass']) {
      case 'pgsql':
        return await _fetchPostgreSQLInfo(
          config['dburl'],
          config['dbport'],
          config['dbuser'],
          config['dbpassword'],
          config['dbname'],
          config['ssl'],
          context
        );
      case 'mysql':
        return await _fetchMySQLInfo(
          config['dburl'],
          config['dbport'],
          config['dbuser'],
          config['dbpassword'],
          config['dbname'],
          config['ssl'],
          context
        );
      case 'mssql':
        return await _fetchMsSQLInfo(
          config['dburl'],
          config['dbport'],
          config['dbuser'],
          config['dbpassword'],
          config['dbname'],
          config['ssl'],
          context
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
          context
        );
      default:
        return {'status': 'Unknown', 'size': '0'};
    }
  }

  Future<Map<String, dynamic>> _fetchPostgreSQLInfo(
      String host, int port, String user, String password, String dbName, String ssl, BuildContext context) async {
    try {
      await ensureTokenIsValid(context);
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
      return {'status': 'Error', 'size': '0'};
    }
  }

  Future<Map<String, dynamic>> _fetchMySQLInfo(
      String host, int port, String user, String password, String dbName, String ssl, BuildContext context) async {
    try {
      await ensureTokenIsValid(context);
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
      return {'status': 'Error', 'size': '0'};
    }
  }

  Future<Map<String, dynamic>> _fetchMsSQLInfo(
      String host, int port, String user, String password, String dbName, String ssl, BuildContext context) async {
    try {
      await ensureTokenIsValid(context);
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

  Future<Map<String, dynamic>> _fetchMongoDBInfo(String host, int port, String user, String password, String dbName, String ssl, String cluster, BuildContext context) async {
    try {
      await ensureTokenIsValid(context);
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
      return {'status': 'Error', 'size': '0'};
    }
  }

  Future<String> executePostgreSQLQuery(Map<String, dynamic> config, String query, BuildContext context) async {
    try {
      await ensureTokenIsValid(context);
      final connection = PostgreSQLConnection(
        config['dburl'],
        config['dbport'],
        config['dbname'],
        username: config['dbuser'],
        password: config['dbpassword'],
        useSSL: config['ssl'] == 'yes',
      );

      await connection.open();
      final results = await connection.query(query);
      await connection.close();
      if (results.isEmpty) {
        return 'Query executed successfully.';
      } else {
        return results.map((row) => row.toString()).join('\n');
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String> executeMySQLQuery(Map<String, dynamic> config, String query, BuildContext context) async {
    try {
      await ensureTokenIsValid(context);
      final settings = ConnectionSettings(
        host: config['dburl'],
        port: config['dbport'],
        user: config['dbuser'],
        password: config['dbpassword'],
        db: config['dbname'],
      );

      final conn = await MySqlConnection.connect(settings);
      await Future.delayed(Duration(seconds: 1));
      final results = await conn.query(query);
      await conn.close();
      if (results.isEmpty) {
        return 'Query executed successfully.';
      } else {
        return results.map((row) => row.toString()).join('\n');
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String> executeMSSQLQuery(Map<String, dynamic> config, String query, BuildContext context) async {
    try {
      await ensureTokenIsValid(context);
      final mssqlConnection = MssqlConnection.getInstance();
      
      final connected = await mssqlConnection.connect(
        ip: config['dburl'],
        port: config['dbport'].toString(),
        databaseName: config['dbname'],
        username: config['dbuser'],
        password: config['dbpassword'],
      );

      if (!connected) throw Exception('Connection failed.');

      final results = await mssqlConnection.writeData(query);
      await mssqlConnection.disconnect();

      if (results.isEmpty) {
        return 'Query executed successfully.';
      } else {
        return results;
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String> executeMongoDBQuery(Map<String, dynamic> config, String query, BuildContext context) async {
    String connectionString = 'mongodb+srv://${config["dbuser"]}:${config["dbpassword"]}@${config["cluster"]}.${config["dburl"]}:${config["dbport"]}/${config["dbname"]}?ssl=${config["ssl"] == 'yes' ? 'true' : 'false'}';
    var db = await Db.create(connectionString);
    try {
      await ensureTokenIsValid(context);
      await db.open();

      final collectionName = query.split('.')[0].trim();
      final command = query.split('.')[1].trim();

      final collection = db.collection(collectionName);
      dynamic result;

      if (command.startsWith('find')) {
        final filterStart = query.indexOf('(') + 1;
        final filterEnd = query.lastIndexOf(')');
        final filterString = query.substring(filterStart, filterEnd).trim();
        final filter = filterString.isNotEmpty ? jsonDecode(filterString) : {};

        result = await collection.find(filter).toList();
      } else if (command.startsWith('insert')) {
        final docString = query.substring(query.indexOf('(') + 1, query.lastIndexOf(')'));
        final document = jsonDecode(docString);

        result = await collection.insertOne(document);
      } else if (command.startsWith('update')) {
        final parts = query.substring(query.indexOf('(') + 1, query.lastIndexOf(')')).split(',');
        final filter = jsonDecode(parts[0].trim());
        final update = jsonDecode(parts[1].trim());
        result = await collection.updateOne(filter, update);
      } else if (command.startsWith('delete')) {
        final filterString = query.substring(query.indexOf('(') + 1, query.lastIndexOf(')')).trim();
        final filter = jsonDecode(filterString);

        result = await collection.deleteMany(filter);
      } else if (command.startsWith('aggregate')) {
        final pipelineString = query.substring(query.indexOf('['), query.lastIndexOf(']') + 1);
        final pipeline = jsonDecode(pipelineString) as List<dynamic>;

        result = await collection.aggregate(pipeline);
      } else {
        throw Exception('Unsupported command: $command');
      }

      await db.close();

      if (result is List) {
        return jsonEncode(result);
      } else if (result is WriteResult) {
        return 'Matched: ${result.nMatched}, Modified: ${result.nModified}, Inserted: ${result.nInserted}';
      } else {
        return result.toString();
      }
    } catch (e) {
      await db.close();
      return 'Error: $e';
    }
  }
}