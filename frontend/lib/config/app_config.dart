/// 공개 백엔드 주소만 설정합니다. 비밀 API 키는 백엔드에서 관리합니다.
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8081',
  );

  /// 백엔드의 실제 상태 확인 경로에 맞춰 실행/빌드 시 변경할 수 있습니다.
  static const String healthCheckPath = String.fromEnvironment(
    'HEALTH_CHECK_PATH',
    defaultValue: '/health',
  );
}
