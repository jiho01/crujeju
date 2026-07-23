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
                          label: _reviewCountry ?? '국가',
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
        onSelect: () => _selectGuide(context),
      ),
    );
  }

  void _selectGuide(BuildContext context) {
    widget.appState.chooseGuide(widget.guide.id);
    setState(() {});
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
              '${widget.guide.name} 가이드가 방문 순서와 최종 가격을 제안해요. 알림이 오면 확인해 주세요.',
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
      onSelected: (country) => setState(() => _reviewCountry = country),
    );
  }

  void _showRatingFilter(BuildContext context) {
    _showReviewFilterSheet<int>(
      context: context,
      title: '후기 별점',
      allLabel: '전체 별점',
      options: const [5, 4, 3],
      selected: _reviewRating,
      labelBuilder: (rating) => '$rating점',
      onSelected: (rating) => setState(() => _reviewRating = rating),
    );
  }

  void _showReviewFilterSheet<T>({
    required BuildContext context,
    required String title,
    required String allLabel,
    required List<T> options,
    required T? selected,
    required String Function(T value) labelBuilder,
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
                child: Text(
                  review.country,
                  style: Theme.of(context).textTheme.labelSmall,
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
                      selected ? '일정 요청을 보냈어요' : '${formatWon(price)}부터 · 선택하기',
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
