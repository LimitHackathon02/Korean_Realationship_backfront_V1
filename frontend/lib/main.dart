import 'package:flutter/material.dart';
import 'package:lh02_frontend/services/backend_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.backendClient});

  final BackendClient? backendClient;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LH02 프론트엔드',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, fontFamily: 'Pretendard'),
      home: BackendConnectionPage(backendClient: backendClient),
    );
  }
}

class BackendConnectionPage extends StatefulWidget {
  const BackendConnectionPage({super.key, this.backendClient});

  final BackendClient? backendClient;

  @override
  State<BackendConnectionPage> createState() => _BackendConnectionPageState();
}

class _BackendConnectionPageState extends State<BackendConnectionPage> {
  late final BackendClient _client = widget.backendClient ?? BackendClient();
  bool _isChecking = false;
  HealthCheckResult? _result;
  String? _error;

  Future<void> _checkConnection() async {
    setState(() {
      _isChecking = true;
      _result = null;
      _error = null;
    });
    try {
      final result = await _client.checkHealth();
      if (!mounted) return;
      setState(() => _result = result);
    } on BackendConnectionException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = '연결 확인 중 오류가 발생했습니다. 잠시 후 다시 시도하세요.');
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  void dispose() {
    if (widget.backendClient == null) _client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LH02 프론트엔드 실행 확인')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '백엔드 연결 확인',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                const Text('백엔드 서버를 실행한 뒤 버튼을 눌러 응답을 확인하세요.'),
                const SizedBox(height: 20),
                Text('서버 주소', style: Theme.of(context).textTheme.labelLarge),
                SelectableText(_client.baseUrl),
                const SizedBox(height: 12),
                Text('상태 확인 경로', style: Theme.of(context).textTheme.labelLarge),
                SelectableText(_client.healthCheckPath),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isChecking ? null : _checkConnection,
                  child: Text(_isChecking ? '확인 중…' : '연결 테스트'),
                ),
                const SizedBox(height: 20),
                if (_isChecking)
                  const Center(child: CircularProgressIndicator())
                else if (_error != null)
                  Text(
                    '연결 실패\n$_error',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  )
                else if (_result != null) ...[
                  Text(
                    '연결 성공 · HTTP ${_result!.statusCode}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  SelectableText(_result!.formattedBody),
                ] else
                  const Text('아직 연결을 확인하지 않았습니다.'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
