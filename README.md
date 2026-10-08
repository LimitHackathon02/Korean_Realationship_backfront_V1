# Korean_Realationship_backfront_V1

한국어 관계 기반 메시지 코치의 **백엔드(FastAPI) + 프론트(Flutter 웹)** 통합 저장소입니다.

| 폴더 | 내용 | 가져온 곳 |
|---|---|---|
| `backend/` | 메시지 코치 API (작성·코칭·해석·리허설·상대 관리), HyperCLOVA X 연결 | `Korean-relationship-based-messaging-AI` 저장소 `backend-only` 브랜치 (0b44017) |
| `frontend/` | Flutter 웹 앱 (현재: 백엔드 연결 테스트 화면) | `LH02_Frontend` 저장소 `feat/cors-readiness` 브랜치 (2b59906) |

원래 저장소들은 그대로 두고, 이 저장소에서만 서로 연결되도록 맞췄습니다.

## 연결 구성

```
브라우저 http://localhost:5173  (Flutter 웹)
        │  API_BASE_URL = http://127.0.0.1:8081
        ▼
백엔드 http://127.0.0.1:8081  (FastAPI)
        │  GET /health        프론트 연결 테스트
        │  /api/*             기능 API (문서: /docs)
        ▼
HyperCLOVA X  (.env에 키를 넣었을 때만. 기본은 MOCK)
```

| 항목 | 값 | 설정 위치 |
|---|---|---|
| 백엔드 포트 | `8081` | `backend/scripts/start.ps1` |
| 프론트 포트 | `5173` | `scripts/start-all.ps1` (`--web-port`) |
| 프론트가 부르는 백엔드 주소 | `http://127.0.0.1:8081` | `frontend/lib/config/app_config.dart` 기본값 (`--dart-define=API_BASE_URL=...`로 변경) |
| 연결 테스트 경로 | `GET /health` → `{"status":"ok","mock":...}` | `backend/app/routes/health.py` |
| CORS 허용 | `localhost:5173`, `127.0.0.1:5173`, `localhost:3000` | `backend/.env`의 `CORS_ORIGINS` |

## 실행 (Windows PowerShell)

### 준비물

- Python 3.11 이상 (백엔드)
- Flutter 3.44.7 stable + Chrome (프론트) — 설치 방법은 [frontend/README.md](frontend/README.md)

### 한 번에 실행

저장소 루트에서:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\start-all.ps1
```

1. 새 창에서 백엔드가 뜹니다. 처음이면 `.venv` 생성과 패키지 설치를 자동으로 합니다.
2. 현재 창에서 Flutter 웹이 Chrome으로 열립니다 (`http://localhost:5173`).
3. 화면의 **연결 테스트** 버튼을 누르면 `연결 성공 · HTTP 200`이 나옵니다.

Flutter가 없으면 백엔드만 뜨고 안내 문구가 나옵니다. 백엔드만 띄우려면 `-BackendOnly`를 붙입니다.

### 따로 실행

```powershell
# 창 1: 백엔드
cd backend
powershell -ExecutionPolicy Bypass -File scripts\start.ps1

# 창 2: 프론트
cd frontend
flutter pub get
flutter run -d chrome --web-hostname localhost --web-port 5173 --dart-define=API_BASE_URL=http://127.0.0.1:8081
```

### 실제 HyperCLOVA X 사용

기본은 MOCK(가짜 응답, 크레딧 0)입니다. `backend/.env`에서 아래처럼 바꾸고 백엔드를 다시 시작합니다.

```
MOCK_MODE=0
CLOVA_API_KEY=발급받은_키
```

API 키는 **백엔드 `.env`에만** 넣습니다. 프론트 코드나 `--dart-define`에는 넣지 않습니다 (빌드에 포함돼 공개됨). `.env`는 Git에 올라가지 않습니다.

## 다른 PC에서 접속하기 (같은 Wi-Fi)

1. 백엔드 PC의 IP를 확인합니다: `ipconfig` → IPv4 주소 (예: `192.168.0.10`)
2. 백엔드를 외부 접속 허용으로 실행합니다. `backend/scripts/start.ps1`의 `"--host", "127.0.0.1"`을 `"0.0.0.0"`으로 바꾸고, Windows 방화벽에서 8081 포트 접속을 허용합니다.
3. 프론트 실행 시 주소를 그 IP로 지정합니다: `--dart-define=API_BASE_URL=http://192.168.0.10:8081`
4. 프론트를 다른 주소(예: `http://192.168.0.20:5173`)로 연다면 그 주소를 `backend/.env`의 `CORS_ORIGINS`에 추가합니다.

## 발표용 빌드

```powershell
cd frontend
flutter build web --dart-define=API_BASE_URL=http://127.0.0.1:8081
python -m http.server 5173 --bind 127.0.0.1 --directory build/web
```

백엔드도 함께 실행돼 있어야 합니다.

## 더 보기

- API 목록, 프론트 연결 예시, 기능별로 떼어 쓰기: [backend/README.md](backend/README.md)
- 무엇을 바꾸려면 어디를 고치는지: [backend/DEV_GUIDE.md](backend/DEV_GUIDE.md)
- Flutter 설치와 연결 테스트 절차: [frontend/README.md](frontend/README.md)
