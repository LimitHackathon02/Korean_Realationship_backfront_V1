import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lh02_frontend/config/app_config.dart';

class HealthCheckResult {
  const HealthCheckResult({required this.statusCode, required this.body});

  final int statusCode;
  final String body;

  String get formattedBody {
    if (body.isEmpty) return '(응답 본문 없음)';
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(body));
    } on FormatException {
      return body;
    }
  }
}

class BackendConnectionException implements Exception {
  const BackendConnectionException(this.message);

  final String message;
}

/// 웹에서는 브라우저의 CORS 정책을 그대로 적용하는 HTTP 클라이언트입니다.
class BackendClient {
  BackendClient({
    http.Client? client,
    this.baseUrl = AppConfig.apiBaseUrl,
    this.healthCheckPath = AppConfig.healthCheckPath,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  final String healthCheckPath;
  final Duration timeout;

  Uri get healthUri {
    final base = Uri.parse(baseUrl);
    final path = Uri.parse(healthCheckPath);
    if (!['http', 'https'].contains(base.scheme) ||
        base.host.isEmpty ||
        base.hasQuery ||
        base.hasFragment ||
        path.hasScheme ||
        path.hasAuthority ||
        path.hasFragment ||
        path.path.isEmpty ||
        path.pathSegments.any((segment) => segment == '..' || segment == '.')) {
      throw const FormatException('백엔드 주소 또는 상태 확인 경로가 잘못되었습니다.');
    }
    // API_BASE_URL의 /api 같은 공통 경로도 유지합니다.
    return base.replace(
      path:
          '${base.path.replaceFirst(RegExp(r'/+$'), '')}'
          '/${path.path.replaceFirst(RegExp(r'^/+'), '')}',
      query: path.hasQuery ? path.query : null,
    );
  }

  Future<HealthCheckResult> checkHealth() async {
    try {
      final response = await _client.get(healthUri).timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw BackendConnectionException(
          'HTTP ${response.statusCode}: 백엔드 상태와 상태 확인 경로를 확인하세요.',
        );
      }
      return HealthCheckResult(
        statusCode: response.statusCode,
        body: utf8.decode(response.bodyBytes, allowMalformed: true),
      );
    } on TimeoutException {
      throw const BackendConnectionException('요청 시간이 초과되었습니다. 백엔드 상태를 확인하세요.');
    } on http.ClientException {
      // 브라우저는 CORS 차단과 네트워크 오류를 동일하게 보고할 수 있습니다.
      throw const BackendConnectionException(
        '응답을 받지 못했습니다. 서버 실행, 주소, 네트워크 또는 백엔드 CORS 설정을 확인하세요.',
      );
    } on FormatException {
      throw const BackendConnectionException('백엔드 주소 또는 상태 확인 경로가 잘못되었습니다.');
    }
  }

  void close() => _client.close();
}
