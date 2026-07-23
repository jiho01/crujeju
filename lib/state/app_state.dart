import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/app_data.dart';
import '../models/models.dart';

enum CardStatus { notApplied, awaitingPickup, active }

class AppState extends ChangeNotifier {
  final Set<String> _savedPlaceIds = {'saeyeongyo', 'oseolrok'};
  String? _selectedGuideId;
  bool _cardLocked = false;
  CardStatus _cardStatus = CardStatus.notApplied;
  int _cardBalance = 0;
  int _pendingCardBalance = 0;
  bool _cardOnline = true;
  bool _initialized = false;
  bool _onboardingComplete = false;
  final Map<String, List<GuideMessage>> _guideMessages = {
    'mina': [
      const GuideMessage(
        text: '안녕하세요. 입항 시간에 맞춰 강정항에서 만날 수 있어요.',
        fromUser: false,
        time: '오전 9:18',
      ),
      const GuideMessage(
        text: '부모님과 함께라 걷는 거리가 짧은 코스를 원해요.',
        fromUser: true,
        time: '오전 9:24',
      ),
      const GuideMessage(
        text: '새연교와 오설록 중심으로 편안한 동선을 준비해 볼게요.',
        fromUser: false,
        time: '오전 9:26',
      ),
    ],
    'jason': [
      const GuideMessage(
        text: '제주의 역사와 자연을 함께 볼 수 있는 일정으로 제안드릴게요.',
        fromUser: false,
        time: '어제',
      ),
    ],
    'sora': [
      const GuideMessage(
        text: '조용한 카페와 사진 명소를 중심으로 안내할 수 있어요.',
        fromUser: false,
        time: '화요일',
      ),
    ],
    'deokchun': [
      const GuideMessage(
        text: '반갑습니다! 하고 싶은 것만 딱 말씀해 주세요. 복잡한 동선은 제가 시원하게 정리해 드릴게요.',
        fromUser: false,
        time: '오전 8:42',
      ),
    ],
  };
  final Map<String, int> _guideUnreadCounts = {
    'mina': 1,
    'jason': 2,
    'sora': 0,
    'deokchun': 1,
  };
  final Map<String, GuideBooking> _guideBookings = {};

  String language = '한국어';
  String currency = 'KRW';
  int travelerCount = 2;
  CruiseOption cruise = AppData.cruises.first;
  List<String> interests = const ['자연', '맛집'];
  String transport = '밴';

  Set<String> get savedPlaceIds => Set.unmodifiable(_savedPlaceIds);
  String? get selectedGuideId => _selectedGuideId;
  bool get cardLocked => _cardLocked;
  bool get cardIssued => _cardStatus == CardStatus.active;
  bool get cardApplicationComplete => _cardStatus != CardStatus.notApplied;
  bool get cardAwaitingPickup => _cardStatus == CardStatus.awaitingPickup;
  bool get cardOnline => _cardOnline;
  int get cardBalance => _cardBalance;
  bool get initialized => _initialized;
  bool get onboardingComplete => _onboardingComplete;

  List<GuideMessage> messagesForGuide(String guideId) =>
      List.unmodifiable(_guideMessages[guideId] ?? const []);

  int unreadCountForGuide(String guideId) => _guideUnreadCounts[guideId] ?? 0;

  GuideBooking? bookingForGuide(String guideId) => _guideBookings[guideId];

  void markGuideConversationRead(String guideId) {
    if ((_guideUnreadCounts[guideId] ?? 0) == 0) return;
    _guideUnreadCounts[guideId] = 0;
    notifyListeners();
  }

  void sendGuideMessage(String guideId, String text) {
    final value = text.trim();
    if (value.isEmpty) return;
    _guideMessages
        .putIfAbsent(guideId, () => [])
        .add(
          GuideMessage(text: value, fromUser: true, time: _currentClockLabel()),
        );
    notifyListeners();
  }

  void addGuideReply(String guideId, String text) {
    _guideMessages
        .putIfAbsent(guideId, () => [])
        .add(
          GuideMessage(text: text, fromUser: false, time: _currentClockLabel()),
        );
    notifyListeners();
  }

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    language = preferences.getString('language') ?? language;
    currency = preferences.getString('currency') ?? currency;
    travelerCount = preferences.getInt('traveler_count') ?? travelerCount;
    interests = preferences.getStringList('interests') ?? interests;
    transport = preferences.getString('transport') ?? transport;

    final cruiseId = preferences.getString('cruise_id');
    if (cruiseId != null) {
      cruise = AppData.cruises.firstWhere(
        (option) => option.id == cruiseId,
        orElse: () => cruise,
      );
    }

    // 브라우저 새로고침과 앱 재실행 때마다 기본 설정부터 시작해요.
    _onboardingComplete = false;
    _initialized = true;
    notifyListeners();
  }

  Future<void> completeOnboarding(OnboardingData data) async {
    language = data.language;
    currency = data.currency;
    travelerCount = data.travelerCount;
    cruise = data.cruise;
    interests = List.unmodifiable(data.interests);
    transport = data.transport;
    _onboardingComplete = true;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setString('language', language),
      preferences.setString('currency', currency),
      preferences.setInt('traveler_count', travelerCount),
      preferences.setString('cruise_id', cruise.id),
      preferences.setStringList('interests', interests),
      preferences.setString('transport', transport),
    ]);
  }

  bool isPlaceSaved(String id) => _savedPlaceIds.contains(id);

  void togglePlace(String id) {
    if (!_savedPlaceIds.add(id)) {
      _savedPlaceIds.remove(id);
    }
    notifyListeners();
  }

  void chooseGuide(String id) {
    _selectedGuideId = id;
    notifyListeners();
  }

  void submitGuideBooking(GuideBooking booking) {
    _selectedGuideId = booking.guideId;
    _guideBookings[booking.guideId] = booking.copyWith(
      status: GuideBookingStatus.pending,
    );
    _guideMessages.putIfAbsent(booking.guideId, () => []).addAll([
      GuideMessage(
        text:
            '가이드 일정 요청을 보냈어요.\n'
            '${booking.startTime}–${booking.endTime} · '
            '${_durationLabel(booking.durationMinutes)} · ${booking.language}\n'
            '${booking.transport} · ${_wonLabel(booking.total)}',
        fromUser: true,
        time: _currentClockLabel(),
      ),
      GuideMessage(
        text: '예약 요청이 도착했어요. 가이드가 일정을 확인하고 있어요.',
        fromUser: false,
        time: _currentClockLabel(),
      ),
    ]);
    _guideUnreadCounts[booking.guideId] = 1;
    notifyListeners();
  }

  void acceptGuideBooking(String guideId) {
    final booking = _guideBookings[guideId];
    if (booking == null) return;
    _guideBookings[guideId] = booking.copyWith(
      status: GuideBookingStatus.accepted,
    );
    _appendGuideBookingReply(
      guideId,
      '일정 요청을 수락했어요. '
      '${booking.startTime}에 약속한 장소에서 만나요.',
    );
  }

  void rejectGuideBooking(String guideId) {
    final booking = _guideBookings[guideId];
    if (booking == null) return;
    if (_selectedGuideId == guideId) {
      _selectedGuideId = null;
    }
    _guideBookings[guideId] = booking.copyWith(
      status: GuideBookingStatus.rejected,
    );
    _appendGuideBookingReply(
      guideId,
      '이번 일정은 진행하기 어려워 요청을 거절했어요. '
      '채팅으로 다른 시간을 조율해 주세요.',
    );
  }

  void modifyGuideBooking(String guideId, GuideBooking updated) {
    if (!_guideBookings.containsKey(guideId)) return;
    final booking = updated.copyWith(status: GuideBookingStatus.modified);
    _guideBookings[guideId] = booking;
    _appendGuideBookingReply(
      guideId,
      '투어 옵션을 수정해 제안했어요.\n'
      '${booking.startTime}–${booking.endTime} · '
      '${_durationLabel(booking.durationMinutes)} · ${booking.language}\n'
      '${booking.transport} · ${_wonLabel(booking.total)}',
    );
  }

  void _appendGuideBookingReply(String guideId, String text) {
    _guideMessages
        .putIfAbsent(guideId, () => [])
        .add(
          GuideMessage(text: text, fromUser: false, time: _currentClockLabel()),
        );
    _guideUnreadCounts[guideId] = 0;
    notifyListeners();
  }

  void toggleCardLock() {
    _cardLocked = !_cardLocked;
    notifyListeners();
  }

  void issueCard(int initialBalance) {
    _cardStatus = CardStatus.active;
    _cardBalance = initialBalance;
    _pendingCardBalance = 0;
    _cardLocked = false;
    notifyListeners();
  }

  void applyForCard(int initialBalance) {
    _cardStatus = CardStatus.awaitingPickup;
    _pendingCardBalance = initialBalance;
    _cardBalance = 0;
    _cardLocked = false;
    notifyListeners();
  }

  void receiveCard() {
    if (_cardStatus != CardStatus.awaitingPickup) return;
    _cardStatus = CardStatus.active;
    _cardBalance = _pendingCardBalance;
    _pendingCardBalance = 0;
    _cardOnline = true;
    notifyListeners();
  }

  void toggleCardConnection() {
    if (!cardIssued) return;
    _cardOnline = !_cardOnline;
    notifyListeners();
  }

  void chargeCard(int amount) {
    if (!cardIssued || amount <= 0) return;
    _cardBalance += amount;
    notifyListeners();
  }
}

String _currentClockLabel() {
  final now = DateTime.now();
  final period = now.hour < 12 ? '오전' : '오후';
  final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
  return '$period $hour:${now.minute.toString().padLeft(2, '0')}';
}

String _durationLabel(int durationMinutes) {
  final hours = durationMinutes ~/ 60;
  final minutes = durationMinutes % 60;
  return minutes == 0 ? '$hours시간' : '$hours시간 $minutes분';
}

String _wonLabel(int amount) {
  final digits = amount.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[index]);
  }
  return '$buffer원';
}
