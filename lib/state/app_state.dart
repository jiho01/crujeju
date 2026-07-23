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
  };
  final Map<String, int> _guideUnreadCounts = {
    'mina': 1,
    'jason': 2,
    'sora': 0,
  };

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
