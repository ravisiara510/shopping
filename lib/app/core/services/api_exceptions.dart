// In api_exceptions.dart
import 'package:dio/dio.dart';

class ApiException extends DioException {
  final String message;
  final int? statusCode;

  ApiException._(this.message,
      {required super.requestOptions, this.statusCode});

  factory ApiException.fromDioError(DioException error) {
    String message = "Something went wrong";
    int? statusCode;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        message = "Connection timeout. Please try again.";
        break;
      case DioExceptionType.sendTimeout:
        message = "Send timeout. Please try again.";
        break;
      case DioExceptionType.receiveTimeout:
        message = "Receive timeout. Please try again.";
        break;
      case DioExceptionType.badResponse:
        statusCode = error.response?.statusCode ?? 0;
        message = _handleStatusCode(statusCode, error.response?.data);
        break;
      case DioExceptionType.cancel:
        message = "Request to API server was cancelled.";
        break;
      case DioExceptionType.connectionError:
        message = "No internet connection.";
        break;
      default:
        message = "Unexpected error occurred.";
        break;
    }
    return ApiException._(message,
        requestOptions: error.requestOptions, statusCode: statusCode);
  }

  static String _handleStatusCode(int statusCode, dynamic data) {
    switch (statusCode) {
      case 400:
        return data?['message'] ?? "Bad request";
      case 401:
        return "Unauthorized request. Please login again.";
      case 403:
        return "Forbidden access.";
      case 404:
        return "Resource not found.";
      case 500:
        return "Internal server error.";
      default:
        return "Received invalid status code: $statusCode";
    }
  }

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}
