import 'package:dio/dio.dart';
import 'package:du_student_app/api/api_client.dart';

/// The same HTTP calls the admin site makes.
class Admin {
  Admin(this._dio);
  final Dio _dio;

  static Future<Admin> login() async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:4000/api'));
    final res = await dio.post<Map<String, dynamic>>('/auth/admin/login', data: {'identifier': 'admin', 'password': 'admin123'});
    final token = (res.data!['data'] as Map<String, dynamic>)['accessToken'] as String;
    dio.options.headers['Authorization'] = 'Bearer $token';
    return Admin(dio);
  }

  Future<dynamic> get(String path, [Map<String, dynamic>? query]) async => (await _dio.get<Map<String, dynamic>>('/admin$path', queryParameters: query)).data!['data'];
  Future<dynamic> post(String path, Object body) async => (await _dio.post<Map<String, dynamic>>('/admin$path', data: body)).data!['data'];
  Future<dynamic> put(String path, Object body) async => (await _dio.put<Map<String, dynamic>>('/admin$path', data: body)).data!['data'];
  Future<void> delete(String path) => _dio.delete<dynamic>('/admin$path');
}

class MemoryTokenStoreForE2e implements TokenStore {
  TokenPair? tokens;

  @override
  Future<TokenPair?> read() async => tokens;
  @override
  Future<void> write(TokenPair tokens, {bool? remember}) async => this.tokens = tokens;
  @override
  Future<void> clear() async => tokens = null;
}
