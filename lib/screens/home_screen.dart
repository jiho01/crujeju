import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'place_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.appState,
    required this.onTabChanged,
    super.key,
    this.onBookingRequested,
  });

  final AppState appState;
  final ValueChanged<int> onTabChanged;
  final VoidCallback? onBookingRequested;

  @override
  Widget build(BuildContext context) {
    final selectedGuide = appState.selectedGuideId == null
        ? null
        : AppData.guides.firstWhere(
            (guide) => guide.id == appState.selectedGuideId,
          );

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _HomeHeader(onNotification: () => _showNotice(context)),
          Expanded(
            child: CustomScrollView(
              key: const PageStorageKey('home-scroll'),
              slivers: [
                SliverToBoxAdapter(
                  child: _CruiseSummary(
                    cruise: appState.cruise,
                    onTap: () => _showCruiseInfo(context),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _CardSummary(
                    issued: appState.cardIssued,
                    awaitingPickup: appState.cardAwaitingPickup,
                    balance: appState.cardBalance,
                    port: appState.cruise.port,
                    onTap: () => onTabChanged(3),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 30)),
                const SliverToBoxAdapter(
                  child: SectionHeader(
                    title: '여행 준비',
                    subtitle: '장소 · 가이드 · 카드',
                  ),
                ),
                SliverToBoxAdapter(
                  child: _PreparationOptions(
                    savedPlaceCount: appState.savedPlaceIds.length,
                    selectedGuideName: selectedGuide?.name,
                    cardIssued: appState.cardIssued,
                    cardAwaitingPickup: appState.cardAwaitingPickup,
                    cardBalance: appState.cardBalance,
                    cardPickupPort: appState.cruise.port,
                    onPlaces: () => onTabChanged(2),
                    onGuide: selectedGuide != null && onBookingRequested != null
                        ? onBookingRequested!
                        : () => onTabChanged(1),
                    onCard: () => onTabChanged(3),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: '지금 일정에 더할 수 있어요',
                    subtitle: '이동시간과 항구 복귀시간을 함께 계산했어요',
                    actionLabel: '더 보기',
                    onAction: () => onTabChanged(2),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 258,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        final place = AppData.places[index + 2];
                        return _PlaceMiniCard(
                          place: place,
                          saved: appState.isPlaceSaved(place.id),
                          onTap: () => _openPlace(context, place),
                          onSave: () {
                            appState.togglePlace(place.id);
                            showAppSnack(
                              context,
                              appState.isPlaceSaved(place.id)
                                  ? '${place.name}을 내 여행에 담았어요'
                                  : '${place.name}을 내 여행에서 뺐어요',
                            );
                          },
                        );
                      },
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemCount: 3,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openPlace(BuildContext context, Place place) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlaceDetailScreen(place: place, appState: appState),
      ),
    );
  }

  void _showNotice(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('새 알림', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            DetailInfoRow(
              icon: Icons.directions_boat_filled_outlined,
              label: '크루즈 일정',
              value:
                  '${appState.cruise.port} 입항 시간이 확인됐어요 · ${appState.cruise.arrival}',
            ),
            DetailInfoRow(
              icon: Icons.credit_card_rounded,
              label: '선불카드',
              value: '수령 QR이 준비됐어요 · ${appState.cruise.port} 1번 키오스크',
            ),
          ],
        ),
      ),
    );
  }

  void _showCruiseInfo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('제주 기항 일정', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              '${appState.cruise.shipName} · ${appState.cruise.date}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            DetailInfoRow(
              icon: Icons.anchor_rounded,
              label: '입항 항구',
              value: appState.cruise.port,
            ),
            DetailInfoRow(
              icon: Icons.login_rounded,
              label: '입항',
              value: appState.cruise.arrival,
            ),
            DetailInfoRow(
              icon: Icons.logout_rounded,
              label: '출항',
              value: appState.cruise.departure,
            ),
            DetailInfoRow(
              icon: Icons.timer_outlined,
              label: '권장 관광시간',
              value:
                  '${_offsetTime(appState.cruise.arrival, 60)}–${_offsetTime(appState.cruise.departure, -90)}',
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onNotification});

  final VoidCallback onNotification;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          const BrandHeaderMark(),
          const Spacer(),
          Stack(
            children: [
              RoundIconButton(
                icon: Icons.notifications_none_rounded,
                onPressed: onNotification,
                tooltip: '알림',
              ),
              const Positioned(
                right: 8,
                top: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(width: 7, height: 7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CruiseSummary extends StatelessWidget {
  const _CruiseSummary({required this.cruise, required this.onTap});

  final CruiseOption cruise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 164,
                    width: double.infinity,
                    child: Image.asset(
                      'assets/images/place_saeyeongyo.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const EmptyImageFallback(),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 15,
                            color: AppColors.brand,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _cruiseCountdownLabel(cruise.date),
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: AppColors.brand),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '곧, 제주에서 만나요',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cruise.shipName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.brandWeak,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.anchor_rounded,
                                  color: AppColors.brand,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cruise.port,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${cruise.date} · ${cruise.arrival} 입항 · ${cruise.departure} 출항',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Divider(),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                color: AppColors.brand,
                                size: 21,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  '안전한 관광시간 ${_offsetTime(cruise.arrival, 60)}–${_offsetTime(cruise.departure, -90)}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelMedium,
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 21,
                                color: AppColors.textTertiary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _cruiseCountdownLabel(String dateLabel) {
  final match = RegExp(r'(\d+)월\s*(\d+)일').firstMatch(dateLabel);
  if (match == null) return dateLabel;
  final now = DateTime.now();
  var target = DateTime(
    now.year,
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
  );
  final today = DateTime(now.year, now.month, now.day);
  if (target.isBefore(today)) {
    target = DateTime(target.year + 1, target.month, target.day);
  }
  final days = target.difference(today).inDays;
  return days == 0 ? '오늘 제주에 도착해요' : '제주까지 $days일';
}

class _PreparationOptions extends StatelessWidget {
  const _PreparationOptions({
    required this.savedPlaceCount,
    required this.selectedGuideName,
    required this.cardIssued,
    required this.cardAwaitingPickup,
    required this.cardBalance,
    required this.cardPickupPort,
    required this.onPlaces,
    required this.onGuide,
    required this.onCard,
  });

  final int savedPlaceCount;
  final String? selectedGuideName;
  final bool cardIssued;
  final bool cardAwaitingPickup;
  final int cardBalance;
  final String cardPickupPort;
  final VoidCallback onPlaces;
  final VoidCallback onGuide;
  final VoidCallback onCard;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: AppColors.surfaceSecondary,
      child: Column(
        children: [
          _PreparationOptionRow(
            icon: Icons.map_outlined,
            accent: AppColors.ocean,
            accentBackground: AppColors.oceanWeak,
            title: '가고 싶은 장소',
            status: savedPlaceCount == 0
                ? '아직 담은 장소가 없어요'
                : '$savedPlaceCount곳 담았어요',
            actionLabel: '둘러보기',
            onTap: onPlaces,
          ),
          const Divider(indent: 52),
          _PreparationOptionRow(
            icon: Icons.person_search_outlined,
            accent: AppColors.brand,
            accentBackground: AppColors.brandWeak,
            title: '가이드',
            status: selectedGuideName == null
                ? '필요할 때 예약할 수 있어요'
                : '$selectedGuideName 가이드에게 요청했어요',
            actionLabel: selectedGuideName == null ? '찾기' : '확인',
            onTap: onGuide,
          ),
          const Divider(indent: 52),
          _PreparationOptionRow(
            icon: Icons.credit_card_outlined,
            accent: AppColors.brandNavy,
            accentBackground: AppColors.brandNavyWeak,
            title: 'CRUJEJU 카드',
            status: cardIssued
                ? '${formatWon(cardBalance)} 사용 가능'
                : cardAwaitingPickup
                ? '$cardPickupPort 키오스크에서 수령해요'
                : '아직 연결된 카드가 없어요',
            actionLabel: cardIssued
                ? '확인'
                : cardAwaitingPickup
                ? '수령'
                : '신청',
            onTap: onCard,
          ),
        ],
      ),
    );
  }
}

class _PreparationOptionRow extends StatelessWidget {
  const _PreparationOptionRow({
    required this.icon,
    required this.accent,
    required this.accentBackground,
    required this.title,
    required this.status,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final Color accentBackground;
  final String title;
  final String status;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 2),
                    Text(status, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                actionLabel,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.brand),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right_rounded,
                size: 19,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _offsetTime(String time, int offsetMinutes) {
  final parts = time.split(':');
  if (parts.length != 2) return time;
  final baseMinutes =
      (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  final value = (baseMinutes + offsetMinutes) % (24 * 60);
  final hours = value ~/ 60;
  final minutes = value % 60;
  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
}

class _PlaceMiniCard extends StatelessWidget {
  const _PlaceMiniCard({
    required this.place,
    required this.saved,
    required this.onTap,
    required this.onSave,
  });

  final Place place;
  final bool saved;
  final VoidCallback onTap;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 218,
      child: Material(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 132,
                    width: double.infinity,
                    child: Image.asset(place.image, fit: BoxFit.cover),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: IconButton(
                      onPressed: onSave,
                      icon: Icon(
                        saved
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                      ),
                      color: saved ? AppColors.brand : Colors.white,
                      style: IconButton.styleFrom(
                        backgroundColor: saved
                            ? Colors.white
                            : Colors.black.withValues(alpha: 0.35),
                        minimumSize: const Size(40, 40),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '강정항 ${place.fromPort}분 · ${place.stayTime}분 머물러요',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardSummary extends StatelessWidget {
  const _CardSummary({
    required this.issued,
    required this.awaitingPickup,
    required this.balance,
    required this.port,
    required this.onTap,
  });

  final bool issued;
  final bool awaitingPickup;
  final int balance;
  final String port;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(16),
      color: AppColors.surfaceSecondary,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.brandWeak,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.credit_card_rounded,
              color: AppColors.brand,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issued
                      ? '5412 •••• •••• 8026'
                      : awaitingPickup
                      ? '카드 수령 준비 완료'
                      : '카드 미연결',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  issued
                      ? formatWon(balance)
                      : awaitingPickup
                      ? '$port · 1번 키오스크'
                      : '카드가 연결되지 않았어요',
                  style:
                      (issued
                              ? Theme.of(context).textTheme.titleLarge
                              : Theme.of(context).textTheme.titleSmall)
                          ?.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                ),
              ],
            ),
          ),
          MetaPill(
            label: issued
                ? '사용 가능'
                : awaitingPickup
                ? '수령 QR'
                : '신청하기',
            selected: issued || awaitingPickup,
            compact: true,
          ),
          const SizedBox(width: 2),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}
