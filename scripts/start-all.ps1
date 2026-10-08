# 백엔드(8081)와 프론트(Flutter 웹, 5173)를 함께 실행
# 사용: powershell -ExecutionPolicy Bypass -File scripts\start-all.ps1 [-BackendOnly]
param(
    [switch]$BackendOnly
)
$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$backendPort = 8081
$frontendPort = 5173

# 1) 백엔드: 새 PowerShell 창에서 실행 (창을 닫으면 서버도 꺼짐)
$backendScript = Join-Path $root "backend\scripts\start.ps1"
Start-Process powershell -ArgumentList @("-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$backendScript`"", "-Port", $backendPort)
Write-Host "백엔드를 새 창에서 시작했습니다: http://127.0.0.1:$backendPort/docs"
Write-Host "(처음 실행이면 패키지 설치 때문에 1~2분 걸릴 수 있습니다)"

if ($BackendOnly) { return }

# 2) 프론트: 이 창에서 Flutter 웹 실행
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host ""
    Write-Host "flutter 명령을 찾을 수 없어 프론트는 실행하지 않았습니다." -ForegroundColor Yellow
    Write-Host "Flutter 3.44.7을 설치하고 bin 폴더를 PATH에 추가한 뒤 다시 실행하세요. (frontend\README.md 참고)"
    return
}

Set-Location (Join-Path $root "frontend")
flutter pub get
if ($LASTEXITCODE -ne 0) { throw "flutter pub get 실패" }
flutter run -d chrome --web-hostname localhost --web-port $frontendPort --dart-define=API_BASE_URL=http://127.0.0.1:$backendPort
