# CRUJEJU

크루즈 기항 일정에 맞춰 제주 가이드, 관광지, 선불카드를 한 번에 준비하는 Flutter 앱 MVP입니다.

## 구현된 흐름

- 여행 준비 진행률과 크루즈 일정이 보이는 홈 대시보드
- 일정 적합도 기반 가이드 검색, 필터, 상세 정보, 일정 요청
- 관광지 목록/지도 전환, 장소 저장, 상세 정보와 AI 일정 검토
- 선불카드 잔액, 충전, 잠금, 결제내역, 수령 QR, 반납·환불 안내
- 앱 전반에서 사용할 수 있는 제주 AI 어시스턴트
- 390px 모바일부터 넓은 화면까지 대응하는 단일 컬럼 레이아웃

## 실행

```bash
flutter pub get
flutter run
```

웹 빌드는 다음 명령으로 만들 수 있습니다.

```bash
flutter build web --release
```

## Vercel 배포

Vercel은 저장소 루트의 `vercel.json`을 읽고 `public/` 폴더에 있는
Flutter Web 정적 번들을 배포합니다. 프로젝트를 Vercel에 연결할 때
Root Directory는 저장소 루트(`.`), Framework Preset은 `Other`로 설정합니다.
Build Command와 Output Directory는 `vercel.json`에 이미 정의되어 있습니다.

소스나 이미지가 변경되면 푸시하기 전에 다음 명령으로 배포 번들을 갱신합니다.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\prepare_vercel.ps1
```

배포 관련 폴더 구조는 다음과 같습니다.

```text
crujeju/
├─ lib/                       # Flutter 앱 소스
├─ assets/                    # 원본 이미지
├─ web/                       # Flutter Web 원본 템플릿
├─ public/                    # Vercel이 제공하는 빌드 결과물
├─ scripts/prepare_vercel.ps1 # public 갱신 스크립트
└─ vercel.json                # Vercel 빌드·라우팅 설정
```

## 검증

```bash
flutter analyze
flutter test
```
