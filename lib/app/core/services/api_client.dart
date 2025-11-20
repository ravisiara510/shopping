// lib/core/services/api_client.dart
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../../routes/app_pages.dart';
import '../../services/auth_service.dart';
import '../config/environment.dart';
import '../utils/appString/app_storage_string.dart';
import '../data/sharedPre.dart';
import 'api_exceptions.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  late Dio dio;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: Environment.apiUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          final customException = ApiException.fromDioError(e);

          // Handle 401 globally at the interceptor level
          if (customException.isUnauthorized) {
            try {
              final authService = Get.find<AuthService>();
              await authService.handleUnauthorizedError();
            } catch (e) {
              // If AuthService is not available, handle directly
              await SharedpreferenceUtil.clear();
              Get.offAllNamed(Routes.SIGN_UP);
            }
          }

          return handler.reject(customException);
        },
      ),
    );
  }

  Future<String?> _getToken() async {
    return SharedpreferenceUtil.getString(AppStorage.userToken);
  }
}
