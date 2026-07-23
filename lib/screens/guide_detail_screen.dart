import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/guide_chat.dart';

class GuideDetailScreen extends StatefulWidget {
  const GuideDetailScreen({
    required this.guide,
    required this.appState,
    super.key,
  });

  final Guide guide;
  final AppState appState;

  @override
  State<GuideDetailScreen> createState() => _GuideDetailScreenState();
}

class _GuideDetailScreenState extends State<GuideDetailScreen> {
  bool _favorite = false;
  String? _reviewCountry;
  int? _reviewRating;

  @override
  Widget build(BuildContext context) {
    final selected = widget.appState.selectedGuideId == widget.guide.id;
    final allReviews = AppData.guideReviews
        .where((review) => review.guideId == widget.guide.id)
        .toList();
    final countries =
        allReviews.map((review) => review.country).toSet().toList()..sort();
    final reviews = allReviews.where((review) {
      final matchesCountry =
          _reviewCountry == null || review.country == _reviewCountry;
      final matchesRating =
          _reviewRating == null || review.rating == _reviewRating;
      return matchesCountry && matchesRating;
    }).toList();
    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      body: AppPage(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 360,
              pinned: true,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              leading: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: RoundIconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icons.arrow_back_rounded,
                  backgroundColor: Colors.white,
                  tooltip: '뒤로가기',
                ),
              ),
              actions: [
                RoundIconButton(
                  onPressed: () => setState(() => _favorite = !_favorite),
                  icon: _favorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  foregroundColor: _favorite
                      ? AppColors.brand
                      : AppColors.textPrimary,
                  backgroundColor: Colors.white,
                  tooltip: '가이드 저장',
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Hero(
                  tag: 'guide-${widget.guide.id}',
                  child: Image.asset(
                    widget.guide.image,
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.35),
                    errorBuilder: (_, _, _) => const EmptyImageFallback(),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        MetaPill(
                          label: widget.guide.badge,
                          selected: true,
                          compact: true,
                        ),
                        const Spacer(),
                        RatingLabel(
                          rating: widget.guide.rating,
                          reviews: widget.guide.reviewCount,
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    Text(
                      widget.guide.name,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${widget.guide.languages.join(' · ')} · 차량 ${widget.guide.carSeats}인',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SurfaceCard(
                      color: AppColors.brandWeak,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${widget.guide.match}',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: AppColors.brand),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '내 일정과 ${widget.guide.match}% 잘 맞아요',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${widget.appState.cruise.port} 픽업 · 희망 장소 3곳 전문',
                                  style: Theme.of(context).textTheme.bodySmall,
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
            SliverToBoxAdapter(child: _SectionDivider()),
            SliverToBoxAdapter(
              child: _DetailSection(
                title: '안녕하세요, ${widget.guide.name}예요',
                child: Text(
                  widget.guide.intro,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _DetailSection(
                title: '제가 만드는 여행',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.guide.style,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.guide.tags
                          .map((tag) => MetaPill(label: tag))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(child: _SectionDivider()),
            SliverToBoxAdapter(
              child: _DetailSection(
                title: '이용 정보',
                child: Column(
                  children: [
                    DetailInfoRow(
                      icon: Icons.payments_outlined,
                      label: '6시간 투어',
                      value: '${formatWon(widget.guide.price)}부터',
                    ),
                    const DetailInfoRow(
                      icon: Icons.schedule_rounded,
                      label: '예약 가능시간',
                      value: '7월 30일 · 오전 10:00–오후 4:30',
                    ),
                    DetailInfoRow(
                      icon: Icons.directions_car_outlined,
                      label: '이동수단',
                      value: '가이드 차량 · 최대 ${widget.guide.carSeats}명',
                    ),
                    const DetailInfoRow(
                      icon: Icons.verified_user_outlined,
                      label: '안전과 인증',
                      value: '신원·차량·보험 확인 완료',
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _DetailSection(
                title: '여행자 후기 ${widget.guide.reviewCount}',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _ReviewFilterButton(
                          key: const ValueKey('review-country-filter'),
                          label: _reviewCountry == null
                              ? '국가'
                              : '${countryFlag(_reviewCountry!)} $_reviewCountry',
                          selected: _reviewCountry != null,
                          onTap: () => _showCountryFilter(context, countries),
                        ),
                        const SizedBox(width: 8),
                        _ReviewFilterButton(
                          key: const ValueKey('review-rating-filter'),
                          label: _reviewRating == null
                              ? '별점'
                              : '$_reviewRating점',
                          selected: _reviewRating != null,
                          onTap: () => _showRatingFilter(context),
                        ),
                        const Spacer(),
                        Text(
                          '${reviews.length}개 표시',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (reviews.isEmpty)
                      SurfaceCard(
                        color: AppColors.surfaceSecondary,
                        child: Center(
                          child: Text(
                            '선택한 조건의 후기가 없어요',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      )
                    else
                      for (final review in reviews)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _GuideReviewCard(review: review),
                        ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
      bottomNavigationBar: _GuideBottomAction(
        price: widget.guide.price,
        selected: selected,
        onChat: () => showGuideChatSheet(
          context,
          guide: widget.guide,
          appState: widget.appState,
        ),
        onSelect: () => _showBookingOptions(context),
      ),
    );
  }

  Future<void> _showBookingOptions(BuildContext context) async {
    final transportOptions = [
      _BookingTransportOption(
        title: '가이드 승용차',
        detail: '최대 ${widget.guide.carSeats}인 · 기본 포함',
        icon: Icons.directions_car_outlined,
        priceDelta: 0,
      ),
      const _BookingTransportOption(
        title: '프리미엄 밴',
        detail: '최대 8인 · 넓은 좌석과 짐 공간',
        icon: Icons.airport_shuttle_outlined,
        priceDelta: 70000,
      ),
      const _BookingTransportOption(
        title: '택시 동행',
        detail: '택시비 별도 · 가까운 코스에 적합',
        icon: Icons.local_taxi_outlined,
        priceDelta: -30000,
      ),
    ];
    var selectedTransport = transportOptions.first;
    var selectedLanguage = widget.guide.languages.first;
    var selectedTimeRange = const RangeValues(10, 16);

    final selection = await showModalBottomSheet<_GuideBookingSelection>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final durationMinutes =
              ((selectedTimeRange.end - selectedTimeRange.start) * 60).round();
          final durationPriceDelta = ((durationMinutes - 360) ~/ 30) * 12500;
          final total =
              widget.guide.price +
              selectedTransport.priceDelta +
              durationPriceDelta;
          final startTime = _formatBookingTime(selectedTimeRange.start);
          final endTime = _formatBookingTime(selectedTimeRange.end);
          return FractionallySizedBox(
            key: const ValueKey('guide-booking-options'),
            heightFactor: .92,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 2, 12, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '예약 옵션을 선택해요',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '언어와 이동수단, 투어 시간을 한 번에 정할 수 있어요.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '사용 언어',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.guide.languages.map((language) {
                            return ChoiceChip(
                              key: ValueKey('booking-language-$language'),
                              label: Text(language),
                              selected: language == selectedLanguage,
                              showCheckmark: false,
                              onSelected: (_) => setSheetState(
                                () => selectedLanguage = language,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 26),
                        Text(
                          '이동수단',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        for (final option in transportOptions)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 9),
                            child: _BookingOptionTile(
                              key: ValueKey(
                                option.title == '프리미엄 밴'
                                    ? 'transport-premium-van'
                                    : 'transport-${option.title}',
                              ),
                              option: option,
                              selected: option == selectedTransport,
                              onTap: () => setSheetState(
                                () => selectedTransport = option,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          '투어 시간',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                          decoration: BoxDecoration(
                            color: AppColors.brandWeak,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.brand.withValues(alpha: .16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.schedule_rounded,
                                    size: 20,
                                    color: AppColors.brand,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '$startTime – $endTime',
                                      key: const ValueKey(
                                        'booking-time-summary',
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: AppColors.brandNavy,
                                          ),
                                    ),
                                  ),
                                  Text(
                                    _formatBookingDuration(durationMinutes),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(color: AppColors.brand),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '양쪽 손잡이를 드래그해 시작과 종료 시간을 함께 정하세요.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              RangeSlider(
                                key: const ValueKey('booking-time-range'),
                                values: selectedTimeRange,
                                min: 9,
                                max: 18,
                                divisions: 18,
                                labels: RangeLabels(startTime, endTime),
                                onChanged: (value) {
                                  if (value.end - value.start < 3) return;
                                  setSheetState(
                                    () => selectedTimeRange = RangeValues(
                                      (value.start * 2).round() / 2,
                                      (value.end * 2).round() / 2,
                                    ),
                                  );
                                },
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '09:00',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                  Text(
                                    '최소 3시간',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  Text(
                                    '18:00',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        SurfaceCard(
                          color: AppColors.surfaceSecondary,
                          child: Column(
                            children: [
                              _BookingPriceRow(
                                label: '6시간 기본 요금',
                                value: formatWon(widget.guide.price),
                              ),
                              const SizedBox(height: 9),
                              _BookingPriceRow(
                                label: selectedTransport.title,
                                value: _priceDeltaLabel(
                                  selectedTransport.priceDelta,
                                ),
                              ),
                              const SizedBox(height: 9),
                              _BookingPriceRow(
                                label:
                                    '$startTime–$endTime · ${_formatBookingDuration(durationMinutes)}',
                                value: _priceDeltaLabel(durationPriceDelta),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '예상 결제금액',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                formatWon(total),
                                key: const ValueKey('guide-booking-total'),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 158,
                          child: FilledButton(
                            key: const ValueKey('guide-booking-submit'),
                            onPressed: () => Navigator.pop(
                              sheetContext,
                              _GuideBookingSelection(
                                transport: selectedTransport.title,
                                language: selectedLanguage,
                                startTime: startTime,
                                endTime: endTime,
                                durationMinutes: durationMinutes,
                                total: total,
                              ),
                            ),
                            child: const Text('이 일정 요청하기'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    if (selection == null || !mounted) return;

    widget.appState.chooseGuide(widget.guide.id);
    setState(() {});
    if (!context.mounted) return;
    _showBookingComplete(context, selection);
  }

  void _showBookingComplete(
    BuildContext context,
    _GuideBookingSelection selection,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.successWeak,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 34,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '일정 요청을 보냈어요',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${selection.transport} · ${selection.language}\n'
              '${selection.startTime}–${selection.endTime} · '
              '${_formatBookingDuration(selection.durationMinutes)}\n'
              '예상금액 ${formatWon(selection.total)}',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCountryFilter(BuildContext context, List<String> countries) {
    _showReviewFilterSheet<String>(
      context: context,
      title: '후기 국가',
      allLabel: '전체 국가',
      options: countries,
      selected: _reviewCountry,
      labelBuilder: (country) => country,
      leadingBuilder: (country) =>
          Text(countryFlag(country), style: const TextStyle(fontSize: 22)),
      onSelected: (country) => setState(() => _reviewCountry = country),
    );
  }

  void _showRatingFilter(BuildContext context) {
    var draftRating = (_reviewRating ?? 5).toDouble();
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final rating = draftRating.round();
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '후기 별점',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '좌우로 드래그해 1점부터 5점까지 선택하세요.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            5,
                            (index) => Icon(
                              index < rating
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: AppColors.warning,
                              size: 30,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$rating점',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                  Slider(
                    key: const ValueKey('review-rating-slider'),
                    value: draftRating,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: '$rating점',
                    onChanged: (value) =>
                        setSheetState(() => draftRating = value),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() => _reviewRating = null);
                          Navigator.pop(sheetContext);
                        },
                        child: const Text('전체 별점'),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 132,
                        child: FilledButton(
                          key: const ValueKey('review-rating-apply'),
                          onPressed: () {
                            setState(() => _reviewRating = rating);
                            Navigator.pop(sheetContext);
                          },
                          child: const Text('적용'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showReviewFilterSheet<T>({
    required BuildContext context,
    required String title,
    required String allLabel,
    required List<T> options,
    required T? selected,
    required String Function(T value) labelBuilder,
    Widget Function(T value)? leadingBuilder,
    required ValueChanged<T?> onSelected,
  }) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(allLabel),
                trailing: selected == null
                    ? const Icon(Icons.check_rounded, color: AppColors.brand)
                    : null,
                onTap: () {
                  onSelected(null);
                  Navigator.pop(context);
                },
              ),
              for (final option in options)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: leadingBuilder?.call(option),
                  title: Text(labelBuilder(option)),
                  trailing: selected == option
                      ? const Icon(Icons.check_rounded, color: AppColors.brand)
                      : null,
                  onTap: () {
                    onSelected(option);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingTransportOption {
  const _BookingTransportOption({
    required this.title,
    required this.detail,
    required this.icon,
    required this.priceDelta,
  });

  final String title;
  final String detail;
  final IconData icon;
  final int priceDelta;
}

class _GuideBookingSelection {
  const _GuideBookingSelection({
    required this.transport,
    required this.language,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.total,
  });

  final String transport;
  final String language;
  final String startTime;
  final String endTime;
  final int durationMinutes;
  final int total;
}

String _formatBookingTime(double value) {
  final totalMinutes = (value * 60).round();
  final hour = totalMinutes ~/ 60;
  final minute = totalMinutes % 60;
  return '${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')}';
}

String _formatBookingDuration(int durationMinutes) {
  final hours = durationMinutes ~/ 60;
  final minutes = durationMinutes % 60;
  return minutes == 0 ? '$hours시간' : '$hours시간 $minutes분';
}

class _BookingOptionTile extends StatelessWidget {
  const _BookingOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final _BookingTransportOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.brandWeak : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.brand : AppColors.line,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : AppColors.surfaceSecondary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  option.icon,
                  size: 20,
                  color: selected ? AppColors.brand : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.detail,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _priceDeltaLabel(option.priceDelta),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected ? AppColors.brand : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 21,
                color: selected ? AppColors.brand : AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingPriceRow extends StatelessWidget {
  const _BookingPriceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Text(value, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

String _priceDeltaLabel(int amount) {
  if (amount == 0) return '포함';
  return '${amount > 0 ? '+' : '-'}${formatWon(amount.abs())}';
}

class _ReviewFilterButton extends StatelessWidget {
  const _ReviewFilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.brandWeak : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? AppColors.brand : AppColors.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? AppColors.brand : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: selected ? AppColors.brand : AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideReviewCard extends StatelessWidget {
  const _GuideReviewCard({required this.review});

  final GuideReview review;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('guide-review-${review.author}'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RatingLabel(rating: review.rating.toDouble()),
              const Spacer(),
              Text(review.date, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 10),
          Text(review.content, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      countryFlag(review.country),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      review.country,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${review.author} · ${review.cruise}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
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

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 26),
      child: SizedBox(
        height: 10,
        child: ColoredBox(color: AppColors.surfaceSecondary),
      ),
    );
  }
}

class _GuideBottomAction extends StatelessWidget {
  const _GuideBottomAction({
    required this.price,
    required this.selected,
    required this.onChat,
    required this.onSelect,
  });

  final int price;
  final bool selected;
  final VoidCallback onChat;
  final VoidCallback onSelect;

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
                SizedBox(
                  width: 96,
                  child: OutlinedButton.icon(
                    key: const ValueKey('guide-detail-chat-button'),
                    onPressed: onChat,
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 18,
                    ),
                    label: const Text('채팅'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 54),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: selected ? null : onSelect,
                    child: Text(
                      selected ? '일정 요청 완료' : '${formatWon(price)}부터 · 옵션 선택',
                    ),
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
