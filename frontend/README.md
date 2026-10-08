# LH02_frontend
LH02 해커톤 공통 프론트엔드 — 이미지·텍스트 입력, 지도 API, AI 분석 결과 화면

## 팀 공통 기본 실행 환경

현재는 주제 선정 전 웹 프론트와 백엔드의 통신 환경을 준비합니다. 기본 화면의 **연결 테스트** 버튼을 누르면 백엔드 상태 확인 API를 호출하고 HTTP 상태와 응답 본문을 표시합니다. 화면을 열기만 하면 요청을 보내지 않습니다.

### Flutter 버전과 설치 확인

- 팀 공통 기준: **Flutter 3.44.7 stable**, Framework revision `84fc5cbb22`
- Dart: 위 Flutter에 포함된 **Dart 3.12.2** 사용
- SDK를 임의로 업그레이드하거나 Dart를 별도로 설치하지 않습니다.
- Flutter SDK 3.44.7을 준비하고 SDK의 `bin` 폴더를 Windows 사용자 PATH에 추가한 뒤 PowerShell을 다시 엽니다.
- 현재 PC의 SDK 경로는 `C:\Users\USER\flutter`입니다. 팀원의 설치 경로는 달라도 됩니다.

현재 PowerShell에서만 PATH를 설정하려면 아래 명령을 실행합니다. 설치 위치가 다르면 경로를 바꾸세요.

```powershell
$env:Path = "C:\Users\USER\flutter\bin;$env:Path"
flutter --version
flutter doctor
```

`flutter --version`에서 위 Flutter/Dart 버전을 확인합니다. `flutter doctor`의 Chrome 항목이 정상이어야 웹을 실행할 수 있습니다. Android 라이선스 문제는 Chrome 웹 실행을 막지 않습니다.

### 의존성 설치와 Chrome 실행

PowerShell에서 저장소 루트(본인 PC의 경로에 맞게 변경)로 이동합니다.

```powershell
Set-Location C:\limit_ai\LH02_frontend
flutter pub get
flutter run -d chrome --web-port 5173 --dart-define=API_BASE_URL=http://127.0.0.1:8081
```

브라우저에서 **연결 테스트** 버튼을 확인합니다. 백엔드 연동은 아래 절차를 따릅니다. 터미널에서 `q`를 누르면 실행이 종료됩니다. 앱 프로젝트의 `pubspec.lock`은 팀의 의존성 버전을 공유하기 위해 Git에 포함합니다.

macOS / Linux에서는 저장소 루트에서 실행합니다.

```sh
flutter pub get
flutter run -d chrome --web-hostname localhost --web-port 5173 --dart-define=API_BASE_URL=http://127.0.0.1:8081
```

프론트 주소를 `http://localhost:5173`으로 고정하면 백엔드 CORS 허용 주소를 일관되게 맞출 수 있습니다. Windows에서도 위 명령의 `--web-hostname localhost` 옵션을 사용할 수 있습니다.

### 분석, 테스트, 웹 빌드

```powershell
flutter analyze
flutter test
flutter build web
```

웹 빌드 결과는 `build\web`에 생성되며 Git에 포함하지 않습니다.

### 백엔드 주소 설정

백엔드는 별도로 실행해야 합니다. `lib/config/app_config.dart`의 `AppConfig.apiBaseUrl`은 `String.fromEnvironment`로 `API_BASE_URL`을 읽으며 기본값은 `http://127.0.0.1:8081`입니다. `HEALTH_CHECK_PATH`의 기본값은 `/health`이며, 버튼을 누르면 `GET http://127.0.0.1:8081/health`를 요청합니다.

백엔드의 경로가 다르면 실행/빌드 시 변경합니다. 아래는 백엔드가 `/actuator/health`를 제공하는 경우의 예시입니다.

```sh
flutter run -d chrome --web-hostname localhost --web-port 5173 --dart-define=API_BASE_URL=http://127.0.0.1:8081 --dart-define=HEALTH_CHECK_PATH=/actuator/health
```

`API_BASE_URL=http://127.0.0.1:8081/api`처럼 공통 경로가 있으면 `/api/health`를 호출합니다.

`127.0.0.1`은 앱을 실행하는 컴퓨터 자신을 가리킵니다. 팀원의 백엔드를 연결하려면 해당 팀원 PC의 접근 가능한 IP와 포트를 사용합니다. 예를 들어:

```powershell
flutter run -d chrome --web-port 5173 --dart-define=API_BASE_URL=http://192.168.0.10:8081
```

배포 서버를 연결할 때는 실제 서버 주소로 바꿉니다.

```powershell
flutter run -d chrome --web-port 5173 --dart-define=API_BASE_URL=https://api.example.com
flutter build web --dart-define=API_BASE_URL=https://api.example.com
```

위 주소는 예시입니다. `--dart-define`은 실행/빌드 시 적용되므로 주소를 변경하면 다시 실행하거나 빌드합니다.

웹에서 백엔드를 호출할 때는 백엔드에서 CORS를 설정하여 프론트엔드 origin(로컬 Chrome 실행은 `http://localhost:5173`)을 허용해야 합니다. 팀원 백엔드는 네트워크에서 접근할 수 있도록 별도로 실행되어 있어야 합니다.

### 백엔드에서 준비할 것

이 브랜치는 프론트 연동 준비만 포함합니다. `LH02_backend`의 실제 경로와 CORS 설정은 아직 확인하거나 변경하지 않았습니다. 백엔드 팀과 다음 항목을 맞춥니다.

- 상태 확인용 `GET /health` 제공: 예시 응답은 HTTP 200과 `{"status":"ok"}`입니다. 이미 상태 확인 API가 있으면 `HEALTH_CHECK_PATH`를 그 경로로 변경합니다.
- 응답에 `Access-Control-Allow-Origin: http://localhost:5173` 설정. 브라우저에서 `127.0.0.1:5173`으로도 접속한다면 해당 origin도 허용 목록에 추가합니다. origin에는 경로와 마지막 `/`를 넣지 않습니다.
- 오류 응답에도 CORS 헤더 적용. 그렇지 않으면 브라우저에서 실제 HTTP 오류 대신 네트워크 오류처럼 보일 수 있습니다.
- 이후 JSON POST나 인증 헤더를 사용하게 되면 `OPTIONS` 사전 요청과 해당 메서드·헤더도 허용합니다. 현재 테스트는 추가 헤더와 쿠키 없이 GET만 보내므로 사전 요청이나 인증 연동까지 검증하지 않습니다.

프론트에서 CORS 허용 헤더를 붙이거나 `no-cors`로 우회하지 않습니다. CORS 허용은 백엔드 응답에서 설정해야 합니다. 참고: [MDN CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CORS).

### 브라우저 연결 테스트

1. 백엔드를 `8081` 포트에서 실행하고 상태 확인 API와 CORS를 준비합니다.
2. 위 명령으로 Flutter 웹을 실행하고 `http://localhost:5173`에 접속합니다.
3. **연결 테스트**를 누릅니다. HTTP 2xx 응답을 읽으면 **연결 성공**과 응답 본문이 표시됩니다. 이는 브라우저에서 응답을 읽었다는 뜻이며, 응답 JSON의 업무 상태까지 판정하지는 않습니다.
4. Chrome 개발자 도구의 Network에서 요청 URL과 상태 코드를 확인합니다. 실패하면 Console의 CORS 오류도 확인합니다.
5. 백엔드를 중지한 뒤 다시 누르면 **연결 실패**가 표시됩니다. 응답이 지연되면 10초 후 시간 초과를 표시하며 재시도할 수 있습니다.

브라우저는 CORS 차단과 서버 미실행·네트워크 오류를 같은 요청 실패로 전달할 수 있으므로 화면은 원인을 단정하지 않습니다. HTTP 404가 보이면 상태 확인 경로를, HTTP 5xx가 보이면 백엔드 상태를 확인합니다. `curl`이나 Postman의 성공만으로 브라우저 CORS를 검증할 수는 없습니다.

자동 테스트(`flutter test`)는 응답 처리와 화면 상태를 검증합니다. 실제 백엔드 CORS 검증은 위 브라우저 절차가 별도로 필요합니다.

### 로컬 발표 준비

발표 노트북에서 백엔드와 프론트를 함께 실행합니다. Flutter 웹 릴리스 빌드도 같은 주소 설정으로 만들 수 있습니다.

```sh
flutter build web --dart-define=API_BASE_URL=http://127.0.0.1:8081
python3 -m http.server 5173 --bind 127.0.0.1 --directory build/web
```

브라우저에서 `http://localhost:5173`에 접속하고 백엔드도 실행되어 있어야 합니다. 다른 상태 확인 경로를 쓴다면 빌드 명령에도 `--dart-define=HEALTH_CHECK_PATH=...`를 추가합니다. 로컬 서버를 사용해도 이후 연결하는 외부 AI·지도 API에는 인터넷이 필요할 수 있습니다.

네이버 API 키는 백엔드에서만 관리합니다. 프론트 코드, 설정, `--dart-define`에 비밀 키를 넣지 않습니다. 프론트 빌드에 포함된 설정 값은 사용자에게 공개됩니다.
