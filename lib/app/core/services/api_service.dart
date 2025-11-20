// lib/core/services/api_service.dart
import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:http_parser/http_parser.dart';
import 'package:get/get.dart';
import '../../services/auth_service.dart';
import '../data/sharedPre.dart';
import '../utils/appString/app_storage_string.dart';
import 'api_client.dart';
import 'api_exceptions.dart';

class ApiService {
  final dio.Dio _dio = ApiClient().dio;
  final AuthService _authService = Get.find<AuthService>();

  // ==========================================================
  // ================ COMMON REQUEST METHODS =================
  // ==========================================================

  // -------------------- GET --------------------
  Future<dio.Response> getRequest(String endpoint,
      {Map<String, dynamic>? queryParams}) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParams,
        options: dio.Options(headers: _defaultHeaders()),
      );
      return response;
    } on dio.DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<dio.Response> getRequestAuth(String endpoint,
      {Map<String, dynamic>? queryParams}) async {
    try {
      final token = await _getAuthToken();
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParams,
        options: dio.Options(headers: _authHeaders(token)),
      );
      return response;
    } on dio.DioException catch (e) {
      final apiException = ApiException.fromDioError(e);
      if (apiException.isUnauthorized) {
        await _authService.handleUnauthorizedError();
      }
      rethrow;
    }
  }

  // -------------------- POST --------------------
  Future<dio.Response> postRequest(String endpoint, dynamic data) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        options: dio.Options(headers: _defaultHeaders()),
      );
      return response;
    } on dio.DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<dio.Response> postRequestAuth(String endpoint, dynamic data) async {
    try {
      final token = await _getAuthToken();
      final response = await _dio.post(
        endpoint,
        data: data,
        options: dio.Options(headers: _authHeaders(token)),
      );
      return response;
    } on dio.DioException catch (e) {
      final apiException = ApiException.fromDioError(e);
      if (apiException.isUnauthorized) {
        await _authService.handleUnauthorizedError();
      }
      rethrow;
    }
  }

  // -------------------- PUT --------------------
  Future<dio.Response> putRequest(String endpoint, dynamic data) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
        options: dio.Options(headers: _defaultHeaders()),
      );
      return response;
    } on dio.DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<dio.Response> putRequestAuth(String endpoint, dynamic data) async {
    try {
      final token = await _getAuthToken();
      final response = await _dio.put(
        endpoint,
        data: data,
        options: dio.Options(headers: _authHeaders(token)),
      );
      return response;
    } on dio.DioException catch (e) {
      final apiException = ApiException.fromDioError(e);
      if (apiException.isUnauthorized) {
        await _authService.handleUnauthorizedError();
      }
      rethrow;
    }
  }

  // -------------------- DELETE --------------------
  Future<dio.Response> deleteRequest(String endpoint,
      {Map<String, dynamic>? queryParams}) async {
    try {
      final response = await _dio.delete(
        endpoint,
        queryParameters: queryParams,
        options: dio.Options(headers: _defaultHeaders()),
      );
      return response;
    } on dio.DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<dio.Response> deleteRequestAuth(String endpoint,
      {Map<String, dynamic>? queryParams}) async {
    try {
      final token = await _getAuthToken();
      final response = await _dio.delete(
        endpoint,
        queryParameters: queryParams,
        options: dio.Options(headers: _authHeaders(token)),
      );
      return response;
    } on dio.DioException catch (e) {
      final apiException = ApiException.fromDioError(e);
      if (apiException.isUnauthorized) {
        await _authService.handleUnauthorizedError();
      }
      rethrow;
    }
  }

  // ==========================================================
  // =============== UNIVERSAL FILE UPLOAD ===================
  // ==========================================================

  /// 🔹 Upload files (image, pdf, etc.) WITHOUT authentication
  Future<dio.Response> uploadFiles(
    String endpoint, {
    required Map<String, dynamic> fields,
    required List<File> files,
    String fileFieldName = 'files',
    dio.ProgressCallback? onProgress,
  }) async {
    try {
      // Convert files to MultipartFile list
      final fileList = await Future.wait(
        files.map(
          (file) async => await dio.MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
            contentType: _getMediaType(file.path),
          ),
        ),
      );

      final formData = dio.FormData.fromMap({
        ...fields,
        fileFieldName: fileList.length == 1 ? fileList.first : fileList,
      });

      final response = await _dio.post(
        endpoint,
        data: formData,
        onSendProgress: onProgress,
        options: dio.Options(
          headers: _defaultHeaders(),
          contentType: 'multipart/form-data',
        ),
      );

      return response;
    } on dio.DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// 🔹 Upload files (image, pdf, etc.) WITH authentication
  Future<dio.Response> uploadFilesAuth(
    String endpoint, {
    required Map<String, dynamic> fields,
    required List<File> files,
    String fileFieldName = 'documents',
    dio.ProgressCallback? onProgress,
  }) async {
    try {
      final token = await _getAuthToken();

      final fileList = await Future.wait(
        files.map(
          (file) async => await dio.MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
            contentType: _getMediaType(file.path),
          ),
        ),
      );

      final formData = dio.FormData.fromMap({
        ...fields,
        fileFieldName: fileList.length == 1 ? fileList.first : fileList,
      });

      final response = await _dio.post(
        endpoint,
        data: formData,
        onSendProgress: onProgress,
        options: dio.Options(
          headers: _authHeaders(token),
          contentType: 'multipart/form-data',
        ),
      );

      return response;
    } on dio.DioException catch (e) {
      final apiException = ApiException.fromDioError(e);
      if (apiException.isUnauthorized) {
        await _authService.handleUnauthorizedError();
      }
      rethrow;
    }
  }

  // ==========================================================
  // =============== Helper Utilities =========================
  // ==========================================================

  MediaType _getMediaType(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'pdf':
        return MediaType('application', 'pdf');
      case 'mp4':
        return MediaType('video', 'mp4');
      case 'doc':
      case 'docx':
        return MediaType('application', 'msword');
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  Map<String, String> _defaultHeaders() {
    return {'Accept': 'application/json'};
  }

  Map<String, String> _authHeaders(String? token) {
    return {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<String?> _getAuthToken() async {
    return SharedpreferenceUtil.getString(AppStorage.userToken);
  }
}
