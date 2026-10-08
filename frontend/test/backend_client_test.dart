import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lh02_frontend/services/backend_client.dart';

void main() {
  test('공통 API 경로를 유지하고 백엔드 응답을 읽는다', () async {
    final client = BackendClient(
      baseUrl: 'http://localhost:8081/api/',
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), 'http://localhost:8081/api/health');
        return http.Response('{"status":"ok"}', 200);
      }),
    );
    addTearDown(client.close);

    final result = await client.checkHealth();
    expect(result.statusCode, 200);
    expect(result.formattedBody, '{\n  "status": "ok"\n}');
  });

  test('상태 확인 경로를 변경하고 빈 응답도 처리한다', () async {
    final client = BackendClient(
      healthCheckPath: '/actuator/health',
      client: MockClient((request) async {
        expect(request.url.path, '/actuator/health');
        return http.Response('', 204);
      }),
    );
    addTearDown(client.close);
    expect((await client.checkHealth()).formattedBody, '(응답 본문 없음)');
  });

  test('JSON이 아닌 응답도 연결 결과에 표시한다', () async {
    final client = BackendClient(
      client: MockClient((_) async => http.Response('OK', 200)),
    );
    addTearDown(client.close);
    expect((await client.checkHealth()).formattedBody, 'OK');
  });

  test('HTTP 오류를 성공으로 처리하지 않는다', () async {
    final client = BackendClient(
      client: MockClient((_) async => http.Response('Unavailable', 503)),
    );
    addTearDown(client.close);
    await expectLater(
      client.checkHealth(),
      throwsA(
        isA<BackendConnectionException>().having(
          (error) => error.message,
          'message',
          contains('HTTP 503'),
        ),
      ),
    );
  });

  test('브라우저 네트워크 오류에서 CORS 원인을 단정하지 않는다', () async {
    final client = BackendClient(
      client: MockClient(
        (_) async => throw http.ClientException('Failed to fetch'),
      ),
    );
    addTearDown(client.close);
    await expectLater(
      client.checkHealth(),
      throwsA(
        isA<BackendConnectionException>().having(
          (error) => error.message,
          'message',
          contains('네트워크 또는 백엔드 CORS'),
        ),
      ),
    );
  });

  test('응답이 오지 않으면 제한 시간 이후 실패한다', () async {
    final response = Completer<http.Response>();
    final client = BackendClient(
      timeout: const Duration(milliseconds: 1),
      client: MockClient((_) => response.future),
    );
    addTearDown(client.close);
    await expectLater(
      client.checkHealth(),
      throwsA(
        isA<BackendConnectionException>().having(
          (error) => error.message,
          'message',
          contains('시간이 초과'),
        ),
      ),
    );
    response.complete(http.Response('OK', 200));
  });

  test('잘못된 설정은 요청을 보내기 전에 실패한다', () async {
    for (final settings in [
      ('file:///tmp', '/health'),
      ('http://localhost:8081', 'https://other.example/health'),
      ('http://localhost:8081/api', '../health'),
    ]) {
      final client = BackendClient(
        baseUrl: settings.$1,
        healthCheckPath: settings.$2,
        client: MockClient((_) async {
          fail('잘못된 주소로 요청을 보내면 안 됩니다.');
        }),
      );
      addTearDown(client.close);
      await expectLater(
        client.checkHealth(),
        throwsA(isA<BackendConnectionException>()),
      );
    }
  });
}
