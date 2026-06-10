import 'package:mssql_connection/mssql_connection.dart';

class SqlServerHelper {
  static final SqlServerHelper instance = SqlServerHelper._init();
  MssqlConnection? _connection;

  SqlServerHelper._init();

  Future<MssqlConnection> get connection async {
    if (_connection != null) return _connection!;
    _connection = await _connectToDb();
    return _connection!;
  }

  Future<MssqlConnection> _connectToDb() async {
    final conn = MssqlConnection.getInstance();

    // Thay thế bằng thông tin thật của SQL Server của bạn
    await conn.connect(
      ip: '192.168.100.160', // Đã cập nhật thành IP Wi-Fi của máy tính bạn
      port: '1434', // Đã đổi sang 1434 do 1433 bị trùng
      databaseName: 'QuanLyChiTieuDB', 
      username: 'sa', 
      password: 'QuanLyChiTieu@2026',
      timeoutInSeconds: 15,
    );

    return conn;
  }

  Future<void> disconnect() async {
    if (_connection != null) {
      // Package mssql_connection quản lý kết nối tự động hoặc có thể disconnect tuỳ version
      // Nếu có hàm disconnect thì gọi ở đây
    }
  }

  // Hàm thực thi Query (Dành cho SELECT)
  Future<String> executeQuery(String query) async {
    final conn = await connection;
    return await conn.getData(query);
  }

  // Hàm thực thi lệnh thay đổi dữ liệu (INSERT, UPDATE, DELETE)
  Future<String> executeWrite(String query) async {
    final conn = await connection;
    return await conn.writeData(query);
  }
  
  // Lệnh có tham số chống SQL Injection
  Future<String> executeWriteWithParams(String query, Map<String, dynamic> params) async {
    final conn = await connection;
    return await conn.writeDataWithParams(query, params);
  }
}
