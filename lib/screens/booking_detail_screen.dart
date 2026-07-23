import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/guide_chat.dart';

class BookingDetailScreen extends StatelessWidget {
  const BookingDetailScreen({
    required this.guide,
    required this.appState,
    required this.onCardRequested,
    super.key,
  });

  final Guide guide;
  final AppState appState;
  final VoidCallback onCardRequested;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final booking = appState.bookingForGuide(guide.id);
        return Scaffold(
          backgroundColor: AppColors.surfaceSecondary,
          body: AppPage(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _BookingHeader(onBack: () => Navigator.pop(context)),
                  Expanded(
                    child: booking == null
                        ? const _MissingBooking()
                        : SingleChildScrollView(
                            key: const ValueKey('booking-detail-scroll'),
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _BookingHero(guide: guide, booking: booking),
                                const SizedBox(height: 28),
                                Text(
                                  '예약 정보',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 12),
                                _BookingOptionGrid(
                                  booking: booking,
                                  travelers: appState.travelerCount,
                                ),
                                const SizedBox(height: 28),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '제주에서의 하루',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge,
                                      ),
                                    ),
                                    MetaPill(
                                      label:
                                          booking.status ==
                                              GuideBookingStatus.accepted
                                          ? '가이드 확정'
                                          : '가이드 작성',
                                      selected: true,
                                      compact: true,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  booking.status == GuideBookingStatus.accepted
                                      ? '${guide.name} 가이드가 확정한 일정이에요'
                                      : '${guide.name} 가이드가 예약 조건에 맞춰 준비한 일정이에요',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                _GuideSchedule(
                                  booking: booking,
                                  guide: guide,
                                  appState: appState,
                                ),
                                const SizedBox(height: 28),
                                Text(
                                  '연결된 카드',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 12),
                                _ConnectedCard(
                                  appState: appState,
                                  onTap: onCardRequested,
                                ),
                                const SizedBox(height: 28),
                                Text(
                                  '결제 정보',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 12),
                                _PriceSummary(
                                  booking: booking,
                                  cardIssued: appState.cardIssued,
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: booking == null
              ? null
              : _BookingBottomBar(
                  total: booking.total,
                  onChat: () => showGuideChatSheet(
                    context,
                    guide: guide,
                    appState: appState,
                  ),
                ),
        );
      },
    );
  }
}

class _BookingHeader extends StatelessWidget {
  const _BookingHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          RoundIconButton(
            icon: Icons.arrow_back_rounded,
            onPressed: onBack,
            tooltip: '뒤로가기',
          ),
          const SizedBox(width: 8),
          Text('예약 정보', style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _BookingHero extends StatelessWidget {
  const _BookingHero({required this.guide, required this.booking});

  final Guide guide;
  final GuideBooking booking;

  @override
  Widget build(BuildContext context) {
    final status = _bookingStatus(booking.status);
    return Container(
      key: const ValueKey('booking-detail-hero'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEAF7FB), Color(0xFFF2F5FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.brand.withValues(alpha: .12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: status.background,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(status.icon, size: 15, color: status.color),
                const SizedBox(width: 5),
                Text(
                  status.label,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: status.color),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  guide.image,
                  width: 76,
                  height: 76,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.35),
                  errorBuilder: (_, _, _) => const EmptyImageFallback(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${guide.name} 가이드',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      guide.badge,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 17,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${guide.rating.toStringAsFixed(1)} · 후기 ${guide.reviewCount}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookingOptionGrid extends StatelessWidget {
  const _BookingOptionGrid({required this.booking, required this.travelers});

  final GuideBooking booking;
  final int travelers;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.schedule_rounded,
        '투어 시간',
        '${booking.startTime}–${booking.endTime}\n${_durationLabel(booking.durationMinutes)}',
      ),
      (Icons.directions_car_rounded, '이동 수단', booking.transport),
      (Icons.translate_rounded, '사용 언어', booking.language),
      (Icons.groups_2_outlined, '여행 인원', '$travelers명'),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 112),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(item.$1, size: 21, color: AppColors.brand),
                      const SizedBox(height: 11),
                      Text(
                        item.$2,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.$3,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _GuideSchedule extends StatelessWidget {
  const _GuideSchedule({
    required this.booking,
    required this.guide,
    required this.appState,
  });

  final GuideBooking booking;
  final Guide guide;
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final savedPlaces = AppData.places
        .where((place) => appState.isPlaceSaved(place.id))
        .toList();
    final firstPlace = savedPlaces.isEmpty
        ? AppData.places.first
        : savedPlaces[0];
    final secondPlace = savedPlaces.length > 1
        ? savedPlaces[1]
        : AppData.places[1];
    final schedule = [
      (
        booking.startTime,
        '${appState.cruise.port}에서 미팅',
        '${guide.name} 가이드와 일정 확인',
      ),
      (
        _offsetBookingTime(
          booking.startTime,
          booking.durationMinutes * 22 ~/ 100,
        ),
        firstPlace.name,
        '${firstPlace.category} · ${firstPlace.stayTime}분',
      ),
      (
        _offsetBookingTime(
          booking.startTime,
          booking.durationMinutes * 48 ~/ 100,
        ),
        '제주 로컬 식당',
        '가이드 추천 점심 · 60분',
      ),
      (
        _offsetBookingTime(
          booking.startTime,
          booking.durationMinutes * 70 ~/ 100,
        ),
        secondPlace.name,
        '${secondPlace.category} · ${secondPlace.stayTime}분',
      ),
      (
        booking.endTime,
        '${appState.cruise.port} 복귀',
        '출항 ${appState.cruise.departure} · 안전하게 승선',
      ),
    ];
    return SurfaceCard(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 2),
      child: Column(
        children: [
          for (var index = 0; index < schedule.length; index++)
            _BookingTimelineRow(
              time: schedule[index].$1,
              title: schedule[index].$2,
              detail: schedule[index].$3,
              last: index == schedule.length - 1,
            ),
        ],
      ),
    );
  }
}

class _BookingTimelineRow extends StatelessWidget {
  const _BookingTimelineRow({
    required this.time,
    required this.title,
    required this.detail,
    required this.last,
  });

  final String time;
  final String title;
  final String detail;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 48,
          child: Text(
            time,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        SizedBox(
          width: 20,
          child: Column(
            children: [
              Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: last ? AppColors.brand : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.brand, width: 2),
                ),
              ),
              if (!last) Container(width: 1, height: 50, color: AppColors.line),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ConnectedCard extends StatelessWidget {
  const _ConnectedCard({required this.appState, required this.onTap});

  final AppState appState;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final issued = appState.cardIssued;
    final awaiting = appState.cardAwaitingPickup;
    final title = issued
        ? 'CRUJEJU 카드 · 8026'
        : awaiting
        ? '카드 수령 대기'
        : '연결된 카드 없음';
    final description = issued
        ? '${formatWon(appState.cardBalance)} 사용 가능 · '
              '${appState.cardOnline ? '온라인 동기화' : '오프라인'}'
        : awaiting
        ? '${appState.cruise.port} 1번 키오스크에서 수령해요'
        : '가이드 투어 결제를 위해 미리 준비할 수 있어요';
    return SurfaceCard(
      key: const ValueKey('booking-connected-card'),
      color: const Color(0xFFEAF4FF),
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              issued
                  ? Icons.credit_card_rounded
                  : awaiting
                  ? Icons.qr_code_2_rounded
                  : Icons.add_card_rounded,
              color: AppColors.brand,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            issued
                ? '카드 보기'
                : awaiting
                ? '수령 정보'
                : '준비하기',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.brand),
          ),
          const SizedBox(width: 2),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.brand,
            size: 19,
          ),
        ],
      ),
    );
  }
}

class _PriceSummary extends StatelessWidget {
  const _PriceSummary({required this.booking, required this.cardIssued});

  final GuideBooking booking;
  final bool cardIssued;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _PriceRow(label: '가이드 예약 금액', value: formatWon(booking.total)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(),
          ),
          _PriceRow(
            label: '결제 수단',
            value: cardIssued ? 'CRUJEJU 카드' : '예약 확정 후 선택',
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 17,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '예약 변경 시 시간과 차량 옵션에 따라 최종 금액이 달라질 수 있어요.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Text(value, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

class _BookingBottomBar extends StatelessWidget {
  const _BookingBottomBar({required this.total, required this.onChat});

  final int total;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceSecondary,
      child: Center(
        heightFactor: 1,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '예약 금액',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        formatWon(total),
                        key: const ValueKey('booking-detail-total'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 170,
                  child: FilledButton.icon(
                    key: const ValueKey('booking-detail-chat'),
                    onPressed: onChat,
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 19,
                    ),
                    label: const Text('가이드와 채팅'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MissingBooking extends StatelessWidget {
  const _MissingBooking();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.event_busy_outlined,
              size: 42,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              '확인할 예약 정보가 없어요',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

({String label, Color color, Color background, IconData icon}) _bookingStatus(
  GuideBookingStatus status,
) {
  return switch (status) {
    GuideBookingStatus.pending => (
      label: '가이드 확인 대기',
      color: AppColors.warning,
      background: AppColors.warningWeak,
      icon: Icons.hourglass_top_rounded,
    ),
    GuideBookingStatus.accepted => (
      label: '예약 확정',
      color: AppColors.success,
      background: AppColors.successWeak,
      icon: Icons.check_circle_rounded,
    ),
    GuideBookingStatus.modified => (
      label: '변경 제안 확인',
      color: AppColors.brand,
      background: AppColors.brandWeak,
      icon: Icons.edit_calendar_rounded,
    ),
    GuideBookingStatus.rejected => (
      label: '예약 거절',
      color: AppColors.danger,
      background: AppColors.dangerWeak,
      icon: Icons.cancel_rounded,
    ),
  };
}

String _durationLabel(int minutes) {
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  return remainder == 0 ? '$hours시간' : '$hours시간 $remainder분';
}

String _offsetBookingTime(String time, int offsetMinutes) {
  final parts = time.split(':');
  if (parts.length != 2) return time;
  final base =
      (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  final value = (base + offsetMinutes) % (24 * 60);
  return '${(value ~/ 60).toString().padLeft(2, '0')}:'
      '${(value % 60).toString().padLeft(2, '0')}';
}
