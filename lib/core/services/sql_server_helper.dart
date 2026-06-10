import 'dart:convert';
import 'package:http/http.dart' as http;

class SqlServerHelper {
  static final SqlServerHelper instance = SqlServerHelper._init();
  
  // URL của Backend API Node.js đang chạy trên máy tính
  // Lưu ý: 10.0.2.2 là localhost của máy tính khi dùng Android Emulator
  // Hoặc dùng IP Wi-Fi (vd: 192.168.100.160) nếu dùng điện thoại thật (Redmi Note 8 Pro)
  static const String baseUrl = 'http://192.168.100.160:3000'; 

  SqlServerHelper._init();

  // Hàm thực thi Query (Dành cho SELECT)
  Future<String> executeQuery(String query) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/query'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query}),
      );

      if (response.statusCode == 200) {
        return response.body; // Trả về chuỗi JSON của kết quả
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error executing query via API: $e');
      rethrow;
    }
  }

  // Hàm thực thi lệnh thay đổi dữ liệu (INSERT, UPDATE, DELETE)
  Future<String> executeWrite(String query) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/execute'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query}),
      );

      if (response.statusCode == 200) {
        return response.body; // Trả về chuỗi JSON
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error executing write via API: $e');
      rethrow;
    }
  }
  
  // Lệnh có tham số chống SQL Injection
  Future<String> executeWriteWithParams(String query, Map<String, dynamic> params) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/execute'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': query,
          'params': params,
        }),
      );

      if (response.statusCode == 200) {
        return response.body; // Trả về chuỗi JSON
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error executing write with params via API: $e');
      rethrow;
    }
  }
}
