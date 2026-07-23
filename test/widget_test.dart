import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:crujeju/app.dart';
import 'package:crujeju/screens/main_shell.dart';
import 'package:crujeju/state/app_state.dart';
import 'package:crujeju/theme/app_theme.dart';
import 'package:crujeju/widgets/common.dart';

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

    expect(find.text('CRUJEJU'), findsOneWidget);
    expect(find.byType(BrandHeaderMark), findsOneWidget);
    expect(find.text('곧, 제주에서 만나요'), findsOneWidget);
    expect(find.text('홈'), findsOneWidget);
    expect(find.text('가이드'), findsWidgets);
    expect(find.text('둘러보기'), findsOneWidget);
    expect(find.text('카드'), findsWidgets);
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
    expect(find.text('기항 시간 안에 다녀올 수 있는 장소예요'), findsOneWidget);

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

    expect(find.text('CRUJEJU'), findsOneWidget);
    expect(find.byType(BrandHeaderMark), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);
    expect(find.text('이전'), findsNothing);
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

    expect(find.text('CRUJEJU'), findsOneWidget);
    expect(find.text('곧, 제주에서 만나요'), findsOneWidget);
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

    expect(find.text('CRUJEJU'), findsOneWidget);
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
    expect(find.byKey(const ValueKey('pickup-location-image')), findsOneWidget);
    expect(find.byKey(const ValueKey('pickup-location-map')), findsOneWidget);
    expect(find.text('5412 •••• •••• 8026'), findsNothing);
    expect(find.text('200,000원'), findsNothing);

    final pickupButton = find.byKey(const ValueKey('card-pickup-complete'));
    await tester.scrollUntilVisible(
      pickupButton,
      450,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(pickupButton);
    await tester.pumpAndSettle();

    expect(appState.cardIssued, isTrue);
    expect(appState.cardAwaitingPickup, isFalse);
    expect(appState.cardBalance, 200000);
    expect(find.text('사용 가능한 금액'), findsOneWidget);
    expect(find.text('200,000원'), findsOneWidget);
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

  testWidgets('모든 핵심 탭에서 우측 하단 AI 도우미를 연다', (tester) async {
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
      expect(assistantButton, findsOneWidget);
      await tester.tap(assistantButton);
      await tester.pumpAndSettle();
      expect(find.text('제주 AI'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded).last);
      await tester.pumpAndSettle();
    }
  });

  testWidgets('둘러보기 지도 사진 마커에서 장소 상세로 이동한다', (tester) async {
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
    expect(find.byKey(const ValueKey('explore-saved-button')), findsOneWidget);
    await tester.tap(find.text('지도'));
    await tester.pumpAndSettle();

    expect(find.text('결제 집중'), findsOneWidget);
    expect(find.text('인기 상승'), findsOneWidget);
    expect(find.text('꾸준한 인기'), findsOneWidget);
    expect(find.text('최근 결제 214건'), findsOneWidget);
    expect(find.byIcon(Icons.local_fire_department_rounded), findsWidgets);

    final marker = find.byKey(const ValueKey('map-marker-saeyeongyo'));
    expect(marker, findsOneWidget);
    await tester.tap(marker);
    await tester.pumpAndSettle();
    expect(find.text('새연교'), findsWidgets);
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

  testWidgets('카드 충전과 사용 내역을 금액 및 카테고리 색으로 구분한다', (tester) async {
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
    expect(cafeIcon.color, AppColors.warning);

    final chargeCard = find.byKey(const ValueKey('payment-CRUJEJU 카드 충전'));
    final cafeCard = find.byKey(const ValueKey('payment-제주 티하우스'));
    final restaurantCard = find.byKey(const ValueKey('payment-바다담은 식당'));
    final shoppingCard = find.byKey(const ValueKey('payment-서귀포 올레마켓'));
    final decoration = tester.widget<Container>(chargeCard).decoration;
    expect((decoration as BoxDecoration).border, isNotNull);
    expect(
      tester.getTopLeft(chargeCard).dy,
      lessThan(tester.getTopLeft(cafeCard).dy),
    );
    expect(
      tester.getTopLeft(cafeCard).dy,
      lessThan(tester.getTopLeft(restaurantCard).dy),
    );
    expect(
      tester.getTopLeft(restaurantCard).dy,
      lessThan(tester.getTopLeft(shoppingCard).dy),
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
    await tester.tap(find.text('5점'));
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
}
