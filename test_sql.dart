import 'package:mssql_connection/mssql_connection.dart';

void main() async {
  final conn = MssqlConnection.getInstance();
  try {
    print('Connecting...');
    bool result = await conn.connect(
      ip: '127.0.0.1', 
      port: '1434', 
      databaseName: 'QuanLyChiTieuDB', 
      username: 'sa', 
      password: 'QuanLyChiTieu@2026',
      timeoutInSeconds: 15,
    );
    print('Connection result: $result');
    if (result) {
      String version = await conn.getData('SELECT @@VERSION');
      print('Version: $version');
    }
  } catch (e) {
    print('Error: $e');
  }
  
  // Exit manually to prevent hanging
  print('Done.');
  // Using Future.delayed to ensure logs are flushed
  await Future.delayed(Duration(milliseconds: 100));
  return;
}
