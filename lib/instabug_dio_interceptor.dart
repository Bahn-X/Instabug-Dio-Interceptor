import 'package:dio/dio.dart';
import 'package:instabug_flutter/models/network_data.dart';
import 'package:instabug_flutter/NetworkLogger.dart';

class InstabugDioInterceptor extends Interceptor {
  static final Map<int, DateTime> _requests = <int, DateTime>{};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _requests[options.hashCode] = DateTime.now();
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    NetworkLogger.networkLog(_map(response));
    handler.next(response);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    if (err.response != null) {
      NetworkLogger.networkLog(_map(err.response!));
      handler.next(err);
    }
  }

  static DateTime? _getRequestTime(int requestHashCode) {
    if (_requests[requestHashCode] != null) {
      return _requests.remove(requestHashCode);
    }
    return null;
  }

  NetworkData _map(Response response) {
    final DateTime requestTime =
        _getRequestTime(response.requestOptions.hashCode) ?? DateTime.now();
    final DateTime responseTime = DateTime.now();
    final Map<String, dynamic> responseHeaders = <String, dynamic>{};
    response.headers
        .forEach((String name, dynamic value) => responseHeaders[name] = value);

    final NetworkData data = NetworkData(
      startTime: requestTime,
      endTime: responseTime,
      duration: responseTime.millisecondsSinceEpoch -
          requestTime.millisecondsSinceEpoch,
      url: response.requestOptions.uri.toString(),
      method: response.requestOptions.method,
      requestBody: response.requestOptions.data ?? "",
      requestHeaders: response.requestOptions.headers,
      contentType: response.requestOptions.contentType.toString(),
      status: response.statusCode ?? 0,
      responseBody: response.data ?? "",
      responseHeaders: responseHeaders,
    );
    return data;
  }
}
