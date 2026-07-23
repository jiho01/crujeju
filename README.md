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

## 검증

```bash
flutter analyze
flutter test
```
