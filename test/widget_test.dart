import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:crujeju/app.dart';
import 'package:crujeju/data/app_data.dart';
import 'package:crujeju/models/models.dart';
import 'package:crujeju/screens/main_shell.dart';
import 'package:crujeju/screens/onboarding_screen.dart';
import 'package:crujeju/state/app_state.dart';
import 'package:crujeju/theme/app_theme.dart';
import 'package:crujeju/widgets/common.dart';
import 'package:crujeju/widgets/guide_chat.dart';

void main() {
  testWidgets('홈에서 핵심 여행 정보를 보여준다', (tester) async {
    final appState = AppState();
    addTearDown(appState.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MainShell(appState: appState),
      ),
    );
    await tester.pumpAndSettle();

    final brandLogo = find.byKey(const ValueKey('crujeju-brand-logo'));
    expect(brandLogo, findsOneWidget);
    expect(
      (tester.widget<Image>(brandLogo).image as AssetImage).assetName,
      'assets/images/crujeju_logo_transparent.png',
    );
    expect(find.text('CRUJEJU'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/crujeju_icon.png',
      ),
      findsNothing,
    );
    expect(find.byType(BrandHeaderMark), findsOneWidget);
    expect(find.text('곧, 제주에서 만나요'), findsOneWidget);
    expect(find.text('내 일정에 맞는 가이드'), findsNothing);
    expect(find.text('함께할 가이드'), findsNothing);
    expect(find.text('제주에서의 하루'), findsNothing);
    expect(
      find.byKey(const ValueKey('home-booking-quick-action')),
      findsNothing,
    );
    expect(find.text('홈'), findsOneWidget);
    expect(find.text('가이드'), findsWidgets);
    expect(find.text('둘러보기'), findsOneWidget);
    expect(find.text('카드'), findsWidgets);
  });

  testWidgets('가이드 예약 후 홈에서 예약 정보와 채팅을 연다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final appState = AppState()..issueCard(240000);
    addTearDown(appState.dispose);
    final guide = AppData.guides.first;
    appState.submitGuideBooking(
      GuideBooking(
        guideId: guide.id,
        transport: '가이드 승용차',
        language: '한국어',
        startTime: '10:00',
        endTime: '16:00',
        durationMinutes: 360,
        total: 180000,
      ),
    );
    appState.acceptGuideBooking(guide.id);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MainShell(appState: appState),
      ),
    );
    await tester.pumpAndSettle();

    final bookingButton = find.byKey(
      const ValueKey('home-booking-quick-action'),
    );
    final assistantButton = find.byKey(const ValueKey('global-ai-assistant'));
    expect(bookingButton, findsOneWidget);
    expect(tester.getSize(bookingButton).width, greaterThan(250));
    expect(tester.getTopLeft(bookingButton).dx, closeTo(20, .1));
    expect(
      tester.getTopRight(bookingButton).dx,
      lessThan(tester.getTopLeft(assistantButton).dx),
    );
    expect(find.textContaining('예약 확정'), findsOneWidget);

    await tester.tap(bookingButton);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('booking-detail-hero')), findsOneWidget);
    expect(find.text('${guide.name} 가이드'), findsWidgets);
    expect(find.text('제주에서의 하루'), findsOneWidget);
    expect(find.text('연결된 카드'), findsOneWidget);
    expect(find.text('CRUJEJU 카드 · 8026'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('booking-detail-total')))
          .data,
      '180,000원',
    );

    await tester.tap(find.byKey(const ValueKey('booking-detail-chat')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('guide-chat-input')), findsOneWidget);
  });

  testWidgets('모바일 크기에서 네 개의 핵심 탭을 이동한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final appState = AppState();
    addTearDown(appState.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MainShell(appState: appState),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bottom-tab-1')));
    await tester.pumpAndSettle();
    expect(find.text('내 기항 일정에 예약 가능한 분들이에요'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bottom-tab-2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('explore-map-search')), findsOneWidget);
    expect(find.byKey(const ValueKey('explore-bottom-sheet')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bottom-tab-3')));
    await tester.pumpAndSettle();
    expect(find.text('환전 없이 제주 어디서나 결제해요'), findsOneWidget);
  });

  testWidgets('첫 실행에서 3단계 초기 설정을 완료한다', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const JejuCruiseApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('crujeju-brand-logo')), findsOneWidget);
    expect(find.byType(BrandHeaderMark), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);
    expect(find.text('이전'), findsNothing);
    expect(find.textContaining('기본 정보를 설정해요'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pump();
    expect(find.text('Basic settings'), findsOneWidget);
    expect(find.textContaining('Set up the basics'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    await tester.tap(find.text('한국어'));
    await tester.pump();
    expect(find.textContaining('기본 정보를 설정해요'), findsOneWidget);

    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('2/3'), findsOneWidget);
    expect(find.text('이전'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('onboarding-date-picker')));
    await tester.pumpAndSettle();
    expect(find.text('입항 날짜 선택'), findsOneWidget);
    expect(find.byType(CalendarDatePicker), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Celebrity Millennium'));
    await tester.pump();
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('3/3'), findsOneWidget);

    await tester.tap(find.text('자연'));
    await tester.pump();
    await tester.ensureVisible(find.text('밴'));
    await tester.tap(find.text('밴'));
    await tester.pump();
    await tester.ensureVisible(find.text('여행 준비 시작하기'));
    await tester.tap(find.text('여행 준비 시작하기'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('crujeju-brand-logo')), findsOneWidget);
    expect(find.text('곧, 제주에서 만나요'), findsOneWidget);
  });

  testWidgets('선박 검색 키보드를 닫으면 이전 화면 위치로 돌아온다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: OnboardingScreen(onCompleted: (_) async {}),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    final search = find.byKey(const ValueKey('onboarding-cruise-search'));
    final initialSearchTop = tester.getTopLeft(search).dy;

    await tester.tap(search);
    await tester.pump();
    tester.view.viewInsets = const FakeViewPadding(bottom: 360);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(search).dy, closeTo(initialSearchTop, 1));

    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(search).dy, closeTo(initialSearchTop, 1));
    expect(tester.widget<TextField>(search).focusNode?.hasFocus, isFalse);
  });

  testWidgets('홈을 스크롤해도 브랜드 상단바는 고정된다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final appState = AppState();
    addTearDown(appState.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MainShell(appState: appState),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('crujeju-brand-logo')), findsOneWidget);
  });

  testWidgets('미발급 카드 신청을 완료하면 잔액 화면으로 전환된다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final appState = AppState();
    addTearDown(appState.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MainShell(appState: appState),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bottom-tab-3')));
    await tester.pumpAndSettle();
    expect(find.text('아직 연결된 카드가 없어요'), findsOneWidget);

    final applyButton = find.text('CRUJEJU 카드 신청하기');
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();
    expect(find.text('1/4'), findsOneWidget);

    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('2/4'), findsOneWidget);

    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('3/4'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('card-charge-amount-input')),
      findsOneWidget,
    );
    expect(find.text('10만원'), findsOneWidget);
    expect(find.text('50만원'), findsOneWidget);
    expect(find.text('100만원'), findsOneWidget);
    expect(find.textContaining('AI 추천금액'), findsNothing);

    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('4/4'), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    final completeButton = find.text('총 금액 결제하고 신청하기');
    await tester.ensureVisible(completeButton);
    await tester.tap(completeButton);
    await tester.pumpAndSettle();

    expect(appState.cardAwaitingPickup, isTrue);
    expect(appState.cardIssued, isFalse);
    expect(appState.cardBalance, 0);
    expect(find.text('카드가 준비됐어요'), findsOneWidget);
    final pickupImage = find.byKey(const ValueKey('pickup-location-image'));
    expect(pickupImage, findsOneWidget);
    expect(tester.getSize(pickupImage).height, 196);
    expect(find.byKey(const ValueKey('pickup-location-map')), findsOneWidget);
    expect(find.text('5412 •••• •••• 8026'), findsNothing);
    expect(find.text('100,000원'), findsNothing);

    final pickupButton = find.byKey(const ValueKey('card-pickup-complete'));
    await tester.scrollUntilVisible(
      pickupButton,
      350,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(pickupButton);
    await tester.pumpAndSettle();

    expect(appState.cardIssued, isTrue);
    expect(appState.cardAwaitingPickup, isFalse);
    expect(appState.cardBalance, 100000);
    expect(find.text('사용 가능한 금액'), findsOneWidget);
    expect(find.text('100,000원'), findsOneWidget);
    expect(find.text('잔액 동기화 중'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('card-sync-status')));
    await tester.pump();
    expect(appState.cardOnline, isFalse);
    expect(find.text('동기화 안 됨'), findsOneWidget);
  });

  testWidgets('가이드 상단 검색과 조건 필터가 고정되고 언어가 적용된다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final appState = AppState();
    addTearDown(appState.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MainShell(appState: appState),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bottom-tab-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('guide-search')), findsOneWidget);
    expect(find.byKey(const ValueKey('guide-filter-language')), findsOneWidget);

    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    expect(find.text('가이드'), findsWidgets);
    expect(find.byKey(const ValueKey('guide-search')), findsOneWidget);
    expect(find.byKey(const ValueKey('guide-filter-language')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('guide-filter-language')));
    await tester.pumpAndSettle();
    expect(find.text('안내받고 싶은 언어를 선택해요'), findsOneWidget);
    await tester.tap(find.text('日本語'));
    await tester.pump();
    await tester.tap(find.text('English'));
    await tester.pump();
    await tester.tap(find.text('2개 조건 적용'));
    await tester.pumpAndSettle();

    expect(find.text('언어 · 2개'), findsOneWidget);
  });

  testWidgets('김덕춘 가이드 프로필과 시원시원한 여행 스타일을 보여준다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final appState = AppState();
    addTearDown(appState.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MainShell(appState: appState),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bottom-tab-1')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('guide-search')), '김덕춘');
    await tester.pumpAndSettle();

    final guideCard = find.byKey(const ValueKey('guide-card-deokchun'));
    expect(guideCard, findsOneWidget);
    expect(find.text('베테랑 로컬 가이드'), findsOneWidget);
    expect(find.text('오름 트레킹'), findsOneWidget);

    await tester.tap(guideCard);
    await tester.pumpAndSettle();
    expect(find.text('김덕춘'), findsOneWidget);
    expect(find.textContaining('결정은 빠르게, 분위기는 화끈하게!'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/guide_deokchun.png',
      ),
      findsOneWidget,
    );
    final styleText = find.textContaining('설명은 핵심만, 여행의 텐션은 끝까지');
    await tester.scrollUntilVisible(
      styleText,
      350,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(styleText, findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('guide-detail-chat-button')));
    await tester.pumpAndSettle();
    expect(find.textContaining('복잡한 동선은 제가 시원하게 정리해 드릴게요.'), findsOneWidget);
  });

  testWidgets('둘러보기를 제외한 핵심 탭에서 우측 하단 AI 도우미를 연다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final appState = AppState();
    addTearDown(appState.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MainShell(appState: appState),
      ),
    );
    await tester.pumpAndSettle();

    for (var index = 0; index < 4; index++) {
      if (index > 0) {
        await tester.tap(find.byKey(ValueKey('bottom-tab-$index')));
        await tester.pumpAndSettle();
      }

      final assistantButton = find.byKey(const ValueKey('global-ai-assistant'));
      if (index == 2) {
        expect(assistantButton, findsNothing);
        continue;
      }
      expect(assistantButton, findsOneWidget);
      await tester.tap(assistantButton);
      await tester.pumpAndSettle();
      expect(find.text('제주 AI'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded).last);
      await tester.pumpAndSettle();
    }
  });

  testWidgets('둘러보기 지도 마커에서 정보 확인 후 장소 상세로 이동한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final appState = AppState();
    addTearDown(appState.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MainShell(appState: appState),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bottom-tab-2')));
    await tester.pumpAndSettle();
    final search = find.byKey(const ValueKey('explore-map-search'));
    final savedButton = find.byKey(const ValueKey('explore-saved-button'));
    expect(find.byKey(const ValueKey('explore-map-layout')), findsOneWidget);
    expect(search, findsOneWidget);
    expect(savedButton, findsOneWidget);
    expect(
      tester.getTopLeft(savedButton).dx,
      greaterThan(tester.getTopLeft(search).dx),
    );
    expect(find.byKey(const ValueKey('explore-category-전체')), findsOneWidget);
    expect(find.byKey(const ValueKey('explore-category-자연')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('explore-place-list-sheet')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('explore-place-row-saeyeongyo')),
      findsOneWidget,
    );
    expect(find.text('목록'), findsNothing);
    expect(find.text('지도'), findsNothing);
    expect(find.byKey(const ValueKey('global-ai-assistant')), findsNothing);

    expect(find.textContaining('제주 전체'), findsNothing);
    expect(find.text('결제 집중'), findsOneWidget);
    expect(find.text('인기 상승'), findsOneWidget);
    expect(find.text('꾸준한 인기'), findsOneWidget);
    expect(find.text('최근 결제 214건'), findsNothing);
    expect(find.text('제주항 · 제주시'), findsOneWidget);
    expect(find.text('강정항 · 서귀포'), findsOneWidget);
    final oceanBackground = find.byKey(
      const ValueKey('explore-map-ocean-background'),
    );
    expect(oceanBackground, findsOneWidget);
    expect(
      tester.widget<ColoredBox>(oceanBackground).color,
      const Color(0xFFD7EEF7),
    );
    final jejuPort = find.byKey(const ValueKey('map-port-jeju'));
    final gangjeongPort = find.byKey(const ValueKey('map-port-gangjeong'));
    expect(
      tester.getCenter(jejuPort).dy,
      lessThan(tester.getCenter(gangjeongPort).dy),
    );
    expect(
      tester.getCenter(gangjeongPort).dx,
      lessThan(tester.getCenter(jejuPort).dx),
    );
    expect(find.byKey(const ValueKey('map-zoom-in')), findsOneWidget);
    expect(find.byKey(const ValueKey('map-zoom-out')), findsOneWidget);
    expect(find.byIcon(Icons.local_fire_department_rounded), findsWidgets);

    final marker = find.byKey(const ValueKey('map-marker-saeyeongyo'));
    final fixedMarker = find.byKey(
      const ValueKey('fixed-map-marker-saeyeongyo'),
    );
    expect(marker, findsOneWidget);
    expect(fixedMarker, findsOneWidget);
    final fixedTransform = find.byKey(
      const ValueKey('fixed-map-marker-transform-saeyeongyo'),
    );
    expect(
      tester.widget<Transform>(fixedTransform).transform.storage[0],
      closeTo(1, .001),
    );

    await tester.tap(find.byKey(const ValueKey('map-zoom-in')));
    await tester.pump();
    expect(
      tester.widget<Transform>(fixedTransform).transform.storage[0],
      closeTo(1 / 1.35, .001),
    );
    await tester.tap(find.byKey(const ValueKey('map-reset-position')));
    await tester.tap(find.byKey(const ValueKey('map-zoom-out')));
    await tester.tap(find.byKey(const ValueKey('map-zoom-out')));
    await tester.pump();
    expect(oceanBackground, findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('map-reset-position')));
    await tester.pump();

    await tester.tap(marker);
    await tester.pumpAndSettle();
    expect(find.text('최근 결제 214건'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('explore-place-detail-saeyeongyo')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('explore-selected-place-name')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('explore-place-back-to-list')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('map-place-preview')), findsNothing);

    final detailScroll = find.byKey(
      const ValueKey('explore-place-detail-scroll'),
    );
    for (var index = 0; index < 4; index++) {
      await tester.drag(detailScroll, const Offset(0, -500));
      await tester.pumpAndSettle();
    }
    final placeReviewTitle = find.text('최근 크루즈 여행자 후기 3');
    expect(placeReviewTitle, findsOneWidget);
  });

  testWidgets('둘러보기 목록을 펼쳐도 검색 태그 아래에서 멈춘다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final appState = AppState();
    addTearDown(appState.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MainShell(appState: appState),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bottom-tab-2')));
    await tester.pumpAndSettle();

    final tag = find.byKey(const ValueKey('explore-category-전체'));
    final list = find.byKey(const ValueKey('explore-place-list-scroll'));
    await tester.drag(list, const Offset(0, -900));
    await tester.pumpAndSettle();

    final tagBottom = tester.getBottomLeft(tag).dy;
    final sheetTop = tester.getTopLeft(list).dy;
    expect(sheetTop, greaterThanOrEqualTo(tagBottom + 10));
    expect(sheetTop, lessThanOrEqualTo(tagBottom + 14));
  });

  testWidgets('지도 검색 키보드를 닫으면 하단 목록 위치를 복원한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.view.resetViewInsets);
    final appState = AppState();
    addTearDown(appState.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MainShell(appState: appState),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bottom-tab-2')));
    await tester.pumpAndSettle();

    final search = find.byKey(const ValueKey('explore-map-search'));
    final list = find.byKey(const ValueKey('explore-place-list-scroll'));
    final initialSearchTop = tester.getTopLeft(search).dy;
    final initialSheetTop = tester.getTopLeft(list).dy;

    await tester.tap(search);
    await tester.pump();
    tester.view.viewInsets = const FakeViewPadding(bottom: 360);
    await tester.pumpAndSettle();
    await tester.drag(list, const Offset(0, -260));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(list).dy, lessThan(initialSheetTop - 20));

    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(search).dy, closeTo(initialSearchTop, 1));
    expect(tester.getTopLeft(list).dy, closeTo(initialSheetTop, 1));
    expect(tester.widget<TextField>(search).focusNode?.hasFocus, isFalse);
  });

  testWidgets('발급된 홈 카드 요약에 카드 번호와 잔액을 표시한다', (tester) async {
    final appState = AppState()..issueCard(200000);
    addTearDown(appState.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MainShell(appState: appState),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('5412 •••• •••• 8026'), findsOneWidget);
    expect(find.text('200,000원'), findsOneWidget);
    expect(find.text('AI에게 제주 여행을 물어보세요'), findsNothing);
  });

  testWidgets('카드 내역을 한 패널에서 최신순과 무채색 아이콘으로 보여준다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final appState = AppState()..issueCard(200000);
    addTearDown(appState.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MainShell(appState: appState),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bottom-tab-3')));
    await tester.pumpAndSettle();

    final chargeAmount = tester.widget<Text>(find.text('+200,000원'));
    final usedAmount = tester.widget<Text>(find.text('-28,400원'));
    final cafeIcon = tester.widget<Icon>(
      find.byIcon(Icons.local_cafe_outlined),
    );
    expect(chargeAmount.style?.color, AppColors.success);
    expect(usedAmount.style?.color, AppColors.danger);
    expect(cafeIcon.color, AppColors.textSecondary);
    expect(find.text('AI 소비 가이드'), findsNothing);

    final chargeCard = find.byKey(const ValueKey('payment-CRUJEJU 카드 충전'));
    final cafeCard = find.byKey(const ValueKey('payment-제주 티하우스'));
    final restaurantCard = find.byKey(const ValueKey('payment-바다담은 식당'));
    final shoppingCard = find.byKey(const ValueKey('payment-서귀포 올레마켓'));
    final panel = find.byKey(const ValueKey('payment-list-panel'));
    final decoration = tester.widget<Container>(panel).decoration;
    expect((decoration as BoxDecoration).border, isNotNull);
    expect(
      tester.getTopLeft(shoppingCard).dy,
      lessThan(tester.getTopLeft(restaurantCard).dy),
    );
    expect(
      tester.getTopLeft(restaurantCard).dy,
      lessThan(tester.getTopLeft(cafeCard).dy),
    );
    expect(
      tester.getTopLeft(cafeCard).dy,
      lessThan(tester.getTopLeft(chargeCard).dy),
    );
  });

  testWidgets('가이드 후기에서 국가와 별점을 필터링한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final appState = AppState();
    addTearDown(appState.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MainShell(appState: appState),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bottom-tab-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('미나 리'));
    await tester.pumpAndSettle();

    final backIcon = find.byIcon(Icons.arrow_back_rounded);
    final backButtonFinder = find.ancestor(
      of: backIcon,
      matching: find.byType(IconButton),
    );
    final backButton = tester.widget<IconButton>(backButtonFinder);
    expect(
      backButton.style?.fixedSize?.resolve(<WidgetState>{}),
      const Size.square(44),
    );
    expect(
      backButton.style?.shape?.resolve(<WidgetState>{}),
      isA<CircleBorder>(),
    );
    final countryFilter = find.byKey(const ValueKey('review-country-filter'));
    await tester.scrollUntilVisible(
      countryFilter,
      550,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('4개 표시'), findsOneWidget);

    await tester.tap(countryFilter);
    await tester.pumpAndSettle();
    await tester.tap(find.text('미국').last);
    await tester.pumpAndSettle();
    expect(find.text('1개 표시'), findsOneWidget);
    expect(find.byKey(const ValueKey('guide-review-Emma C.')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('review-rating-filter')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('review-rating-slider')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('review-rating-apply')));
    await tester.pumpAndSettle();
    expect(find.text('미국'), findsWidgets);
    expect(find.text('5점'), findsOneWidget);
  });

  testWidgets('가이드 탭 메시지 목록에서 대화를 열고 메시지를 보낸다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final appState = AppState();
    addTearDown(appState.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MainShell(appState: appState),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bottom-tab-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('guide-messages-button')));
    await tester.pumpAndSettle();

    expect(find.text('메시지'), findsOneWidget);
    expect(find.byKey(const ValueKey('message-thread-mina')), findsOneWidget);
    expect(find.byKey(const ValueKey('message-thread-jason')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('message-thread-mina')));
    await tester.pumpAndSettle();
    expect(find.text('미나 리 가이드'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('guide-chat-input')),
      '항구에서 바로 만날 수 있나요?',
    );
    await tester.tap(find.byKey(const ValueKey('guide-chat-send')));
    await tester.pump();
    expect(find.text('항구에서 바로 만날 수 있나요?'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('자세히 준비해서 안내드릴게요'), findsOneWidget);
  });

  testWidgets('가이드 상세의 채팅 버튼이 대화 팝업을 연다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final appState = AppState();
    addTearDown(appState.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MainShell(appState: appState),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bottom-tab-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('미나 리'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('guide-detail-chat-button')));
    await tester.pumpAndSettle();

    expect(find.text('미나 리 가이드'), findsOneWidget);
    expect(find.byKey(const ValueKey('guide-chat-input')), findsOneWidget);
    expect(find.text('새연교와 오설록 중심으로 편안한 동선을 준비해 볼게요.'), findsOneWidget);
  });

  testWidgets('가이드 예약 요청을 채팅에서 수정하고 수락한 뒤 대화를 이어간다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final appState = AppState();
    addTearDown(appState.dispose);
    final guide = AppData.guides.first;
    appState.submitGuideBooking(
      GuideBooking(
        guideId: guide.id,
        transport: '가이드 승용차',
        language: '한국어',
        startTime: '10:00',
        endTime: '16:00',
        durationMinutes: 360,
        total: guide.price,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: GuideChatPanel(guide: guide, appState: appState),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('guide-booking-request-card')),
      findsOneWidget,
    );
    expect(find.text('가이드 확인 대기'), findsOneWidget);
    expect(find.textContaining('가이드 일정 요청을 보냈어요.'), findsOneWidget);
    expect(find.byKey(const ValueKey('guide-booking-accept')), findsOneWidget);
    expect(find.byKey(const ValueKey('guide-booking-reject')), findsOneWidget);
    expect(find.byKey(const ValueKey('guide-booking-itinerary')), findsNothing);
    expect(
      find.byKey(const ValueKey('guide-booking-saved-place-saeyeongyo')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('guide-booking-saved-place-oseolrok')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('guide-booking-date')))
          .data,
      appState.cruise.date,
    );
    expect(find.text('저장한 장소'), findsOneWidget);
    expect(find.text('가이드 계획 일정'), findsNothing);
    expect(find.text('선택 장소 반영'), findsNothing);
    expect(find.byKey(const ValueKey('guide-booking-route')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('guide-booking-toggle')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('guide-booking-expanded-content')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('guide-booking-accept')), findsNothing);
    expect(find.byKey(const ValueKey('guide-booking-date')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('guide-booking-toggle')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('guide-booking-expanded-content')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('guide-booking-accept')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('guide-booking-modify')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('chat-booking-modify-sheet')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('chat-booking-transport-프리미엄 밴')),
    );
    await tester.tap(
      find.byKey(const ValueKey('chat-booking-language-English')),
    );
    final timeRange = find.byKey(const ValueKey('chat-booking-time-range'));
    await tester.ensureVisible(timeRange);
    tester.widget<RangeSlider>(timeRange).onChanged!(const RangeValues(10, 17));
    await tester.pump();
    expect(find.text('245,000원'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('chat-booking-modify-submit')));
    await tester.pumpAndSettle();
    final modifiedBooking = appState.bookingForGuide(guide.id);
    expect(modifiedBooking?.status, GuideBookingStatus.modified);
    expect(modifiedBooking?.language, 'English');
    expect(modifiedBooking?.transport, '프리미엄 밴');
    expect(modifiedBooking?.total, 245000);
    expect(find.text('수정 제안'), findsOneWidget);
    expect(find.textContaining('투어 옵션을 수정해 제안했어요.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('guide-booking-accept')));
    await tester.pump();
    expect(
      appState.bookingForGuide(guide.id)?.status,
      GuideBookingStatus.accepted,
    );
    expect(find.text('예약 수락'), findsOneWidget);
    expect(find.textContaining('일정 요청을 수락했어요.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('guide-chat-input')),
      '수정된 일정으로 진행할게요.',
    );
    await tester.tap(find.byKey(const ValueKey('guide-chat-send')));
    await tester.pump();
    expect(
      appState
          .messagesForGuide(guide.id)
          .any((message) => message.text == '수정된 일정으로 진행할게요.'),
      isTrue,
    );
    expect(
      appState
          .messagesForGuide(guide.id)
          .any((message) => message.text.contains('가이드 일정 요청을 보냈어요.')),
      isTrue,
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
  });

  testWidgets('가이드 예약 옵션에 따라 예상 가격이 실시간으로 바뀐다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final appState = AppState();
    addTearDown(appState.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MainShell(appState: appState),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bottom-tab-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('미나 리'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('옵션 선택'));
    await tester.pumpAndSettle();

    final total = find.byKey(const ValueKey('guide-booking-total'));
    expect(tester.widget<Text>(total).data, '150,000원');

    await tester.tap(find.byKey(const ValueKey('transport-premium-van')));
    await tester.pump();
    expect(tester.widget<Text>(total).data, '220,000원');

    await tester.tap(find.byKey(const ValueKey('booking-language-English')));
    await tester.pump();

    final timeRange = find.byKey(const ValueKey('booking-time-range'));
    await tester.ensureVisible(timeRange);
    tester.widget<RangeSlider>(timeRange).onChanged!(const RangeValues(10, 17));
    await tester.pump();
    expect(tester.widget<Text>(total).data, '245,000원');
    expect(find.text('10:00 – 17:00'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('guide-booking-submit')));
    await tester.pumpAndSettle();
    expect(appState.selectedGuideId, 'mina');
    expect(
      appState.bookingForGuide('mina')?.status,
      GuideBookingStatus.pending,
    );
    expect(find.textContaining('프리미엄 밴 · English'), findsOneWidget);
    expect(find.textContaining('10:00–17:00 · 7시간'), findsOneWidget);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('prepaid-card-recommendation')),
      findsOneWidget,
    );
    expect(find.text('CRUJEJU 선불카드'), findsOneWidget);
    expect(find.text('환전 없이'), findsOneWidget);

    await tester.binding.setSurfaceSize(const Size(320, 844));
    await tester.pumpAndSettle();
    final applyButton = find.byKey(const ValueKey('recommended-card-apply'));
    final laterButton = find.byKey(const ValueKey('recommended-card-later'));
    expect(
      tester.getTopLeft(laterButton).dy,
      greaterThan(tester.getTopLeft(applyButton).dy),
    );
    final laterText = tester.widget<Text>(find.text('다음에 할게요'));
    expect(laterText.maxLines, 1);
    expect(laterText.softWrap, isFalse);

    await tester.tap(applyButton);
    await tester.pumpAndSettle();
    expect(find.text('카드 신청'), findsOneWidget);
    expect(find.text('1/4'), findsOneWidget);
    expect(find.textContaining('카드를 어디서'), findsOneWidget);
  });
}
