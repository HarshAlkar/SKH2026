class ApiResponse<T> {
  final T? data;
  final String? message;
  final bool success;

  ApiResponse({this.data, this.message, required this.success});

  factory ApiResponse.success(T data, {String? message}) {
    return ApiResponse(data: data, message: message, success: true);
  }

  factory ApiResponse.error(String message) {
    return ApiResponse(message: message, success: false);
  }
}
