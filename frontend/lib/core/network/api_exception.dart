class ApiException implements Exception {
  const ApiException(this.code, this.detail, {this.statusCode});

  final String code;
  final String detail;
  final int? statusCode;

  @override
  String toString() => 'ApiException($code, $detail)';
}
