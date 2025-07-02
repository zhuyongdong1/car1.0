class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  ApiException({
    required this.message,
    this.statusCode,
    this.code,
  });

  @override
  String toString() {
    return 'ApiException: $message${statusCode != null ? ' (状态码: $statusCode)' : ''}${code != null ? ' (错误码: $code)' : ''}';
  }
}
