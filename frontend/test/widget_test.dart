import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lh02_frontend/main.dart';
import 'package:lh02_frontend/services/backend_client.dart';

void main() {
  testWidgets('버튼을 누르기 전에는 요청을 보내지 않는다', (tester) async {
    var requests = 0;
    final client = BackendClient(
      client: MockClient((_) async {
        requests++;
        return http.Response('{"status":"ok"}', 200);
      }),
    );
    addTearDown(client.close);
    await tester.pumpWidget(MyApp(backendClient: client));
    expect(find.text('LH02 프론트엔드 실행 확인'), findsOneWidget);
    expect(find.text('아직 연결을 확인하지 않았습니다.'), findsOneWidget);
    expect(requests, 0);
    await tester.tap(find.text('연결 테스트'));
    await tester.pumpAndSettle();
    expect(requests, 1);
    expect(find.text('연결 성공 · HTTP 200'), findsOneWidget);
    expect(find.textContaining('"status": "ok"'), findsOneWidget);
  });

  testWidgets('실패 후 재시도하면 이전 오류를 지우고 성공을 표시한다', (tester) async {
    var requests = 0;
    final client = BackendClient(
      client: MockClient((_) async {
        requests++;
        return requests == 1
            ? http.Response('Not Found', 404)
            : http.Response('{"status":"ok"}', 200);
      }),
    );
    addTearDown(client.close);
    await tester.pumpWidget(MyApp(backendClient: client));
    await tester.tap(find.text('연결 테스트'));
    await tester.pumpAndSettle();
    expect(find.textContaining('HTTP 404'), findsOneWidget);
    await tester.tap(find.text('연결 테스트'));
    await tester.pumpAndSettle();
    expect(find.textContaining('HTTP 404'), findsNothing);
    expect(find.text('연결 성공 · HTTP 200'), findsOneWidget);
  });

  testWidgets('요청 중에는 중복 실행을 막고 화면을 닫아도 오류가 없다', (tester) async {
    final response = Completer<http.Response>();
    final client = BackendClient(client: MockClient((_) => response.future));
    addTearDown(client.close);
    await tester.pumpWidget(MyApp(backendClient: client));
    await tester.tap(find.text('연결 테스트'));
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    response.complete(http.Response('{"status":"ok"}', 200));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
