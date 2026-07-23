import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'guide_detail_screen.dart';
import 'messages_screen.dart';

class GuidesScreen extends StatefulWidget {
  const GuidesScreen({
    required this.appState,
    required this.onCardApplicationRequested,
    super.key,
  });

  final AppState appState;
  final VoidCallback onCardApplicationRequested;

  @override
  State<GuidesScreen> createState() => _GuidesScreenState();
}

class _GuidesScreenState extends State<GuidesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _filter = '추천순';
  final Set<String> _selectedLanguages = {};
  final Set<String> _selectedTransports = {};
  final Set<String> _selectedStyles = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final guides = AppData.guides.where((guide) {
      final haystack =
          '${guide.name} ${guide.languages.join(' ')} ${guide.tags.join(' ')}';
      final matchesQuery = haystack.toLowerCase().contains(
        _query.toLowerCase(),
      );
      final matchesLanguage =
          _selectedLanguages.isEmpty ||
          _selectedLanguages.any(guide.languages.contains);
      final guideTransport = guide.carSeats >= 5 ? '밴' : '승용차';
      final matchesTransport =
          _selectedTransports.isEmpty ||
          _selectedTransports.contains(guideTransport);
      final matchesStyle =
          _selectedStyles.isEmpty ||
          _selectedStyles.any((style) => _guideMatchesStyle(guide, style));
      return matchesQuery &&
          matchesLanguage &&
          matchesTransport &&
          matchesStyle;
    }).toList();
    switch (_filter) {
      case '평점순':
        guides.sort((a, b) => b.rating.compareTo(a.rating));
      case '가격 낮은 순':
        guides.sort((a, b) => a.price.compareTo(b.price));
      case '리뷰 많은 순':
        guides.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
      default:
        guides.sort((a, b) => b.match.compareTo(a.match));
    }

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          PageHeader(
            title: '가이드',
            subtitle: '내 기항 일정에 예약 가능한 분들이에요',
            action: RoundIconButton(
              key: const ValueKey('guide-messages-button'),
              icon: Icons.chat_bubble_outline_rounded,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MessagesScreen(appState: widget.appState),
                ),
              ),
              tooltip: '가이드 메시지',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              key: const ValueKey('guide-search'),
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: '이름, 언어, 여행 스타일로 찾아보세요',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 68,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 0, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FilterButton(
                    buttonKey: const ValueKey('guide-filter-sort'),
                    label: '정렬',
                    value: _filter == '추천순' ? null : _filter,
                    icon: Icons.swap_vert_rounded,
                    onTap: () => _showSortSheet(context),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: VerticalDivider(indent: 8, endIndent: 8),
                  ),
                  Expanded(
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(right: 20),
                      children: [
                        _FilterButton(
                          buttonKey: const ValueKey('guide-filter-language'),
                          label: '언어',
                          value: _selectionSummary(_selectedLanguages),
                          icon: Icons.language_rounded,
                          onTap: () => _showLanguageSheet(context),
                        ),
                        const SizedBox(width: 8),
                        _FilterButton(
                          buttonKey: const ValueKey('guide-filter-transport'),
                          label: '이동수단',
                          value: _selectionSummary(_selectedTransports),
                          icon: Icons.directions_car_outlined,
                          onTap: () => _showTransportSheet(context),
                        ),
                        const SizedBox(width: 8),
                        _FilterButton(
                          buttonKey: const ValueKey('guide-filter-style'),
                          label: '여행 스타일',
                          value: _selectionSummary(_selectedStyles),
                          icon: Icons.category_outlined,
                          onTap: () => _showStyleSheet(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: CustomScrollView(
              key: const PageStorageKey('guides-scroll'),
              slivers: [
                if (widget.appState.selectedGuideId != null)
                  SliverToBoxAdapter(
                    child: SurfaceCard(
                      margin: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      color: AppColors.successWeak,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '가이드에게 일정 요청을 보냈어요',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  sliver: guides.isEmpty
                      ? SliverToBoxAdapter(child: _EmptyGuides(query: _query))
                      : SliverList.separated(
                          itemCount: guides.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final guide = guides[index];
                            return _GuideCard(
                              guide: guide,
                              selected:
                                  widget.appState.selectedGuideId == guide.id,
                              onTap: () => _openGuide(context, guide),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openGuide(BuildContext context, Guide guide) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GuideDetailScreen(
          guide: guide,
          appState: widget.appState,
          onCardApplicationRequested: widget.onCardApplicationRequested,
        ),
      ),
    );
  }

  String? _selectionSummary(Set<String> values) {
    if (values.isEmpty) return null;
    if (values.length == 1) return values.first;
    return '${values.length}개';
  }

  bool _guideMatchesStyle(Guide guide, String style) {
    return switch (style) {
      '사진 여행' => guide.tags.any((tag) => tag.contains('사진')),
      '맛집 여행' => guide.tags.any(
        (tag) => tag.contains('맛집') || tag.contains('카페'),
      ),
      '역사·문화' => guide.tags.any(
        (tag) => tag.contains('역사') || tag.contains('문화'),
      ),
      '가족 여행' => guide.tags.any((tag) => tag.contains('가족')),
      _ => true,
    };
  }

  void _showSortSheet(BuildContext context) {
    const options = ['추천순', '일정 적합도순', '평점순', '가격 낮은 순', '리뷰 많은 순'];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: .62,
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              Text('정렬', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 10),
              for (final option in options)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(option),
                  trailing: _filter == option
                      ? const Icon(Icons.check_rounded, color: AppColors.brand)
                      : null,
                  onTap: () {
                    setState(() => _filter = option);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLanguageSheet(BuildContext context) async {
    final values = await _showOptionSheet(
      context: context,
      title: '언어',
      description: '안내받고 싶은 언어를 선택해요',
      options: const ['한국어', 'English', '中文', '日本語'],
      selected: _selectedLanguages,
    );
    if (values == null || !mounted) return;
    setState(() {
      _selectedLanguages
        ..clear()
        ..addAll(values);
    });
  }

  Future<void> _showTransportSheet(BuildContext context) async {
    final values = await _showOptionSheet(
      context: context,
      title: '이동수단',
      description: '가이드가 운행할 차량 종류를 선택해요',
      options: const ['승용차', '밴'],
      selected: _selectedTransports,
    );
    if (values == null || !mounted) return;
    setState(() {
      _selectedTransports
        ..clear()
        ..addAll(values);
    });
  }

  Future<void> _showStyleSheet(BuildContext context) async {
    final values = await _showOptionSheet(
      context: context,
      title: '여행 스타일',
      description: '가장 원하는 여행 분위기를 선택해요',
      options: const ['사진 여행', '맛집 여행', '역사·문화', '가족 여행'],
      selected: _selectedStyles,
    );
    if (values == null || !mounted) return;
    setState(() {
      _selectedStyles
        ..clear()
        ..addAll(values);
    });
  }

  Future<Set<String>?> _showOptionSheet({
    required BuildContext context,
    required String title,
    required String description,
    required List<String> options,
    required Set<String> selected,
  }) {
    final draft = Set<String>.of(selected);
    return showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => FractionallySizedBox(
          heightFactor: .72,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: [
                        _FilterOptionRow(
                          label: '전체',
                          selected: draft.isEmpty,
                          onTap: () => setSheetState(draft.clear),
                        ),
                        for (final option in options)
                          _FilterOptionRow(
                            label: option,
                            selected: draft.contains(option),
                            onTap: () => setSheetState(() {
                              if (!draft.add(option)) draft.remove(option);
                            }),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () =>
                          Navigator.pop(context, Set<String>.of(draft)),
                      child: Text(
                        draft.isEmpty ? '전체 가이드 보기' : '${draft.length}개 조건 적용',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.onTap,
    required this.icon,
    this.buttonKey,
    this.value,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;
  final IconData icon;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    final selected = value != null;
    return Material(
      color: selected ? AppColors.brandWeak : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: selected ? AppColors.brand : AppColors.line),
      ),
      child: InkWell(
        key: buttonKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? AppColors.brand : AppColors.textSecondary,
              ),
              const SizedBox(width: 7),
              Text(
                value == null ? label : '$label · $value',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? AppColors.brand : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 5),
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

class _FilterOptionRow extends StatelessWidget {
  const _FilterOptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minTileHeight: 52,
      title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
      trailing: selected
          ? const Icon(Icons.check_rounded, color: AppColors.brand)
          : null,
      onTap: onTap,
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.guide,
    required this.selected,
    required this.onTap,
  });

  final Guide guide;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: ValueKey('guide-card-${guide.id}'),
      color: AppColors.surfaceSecondary,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 210,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    guide.image,
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.4),
                    errorBuilder: (_, _, _) => const EmptyImageFallback(),
                  ),
                  Positioned(
                    left: 14,
                    top: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.success : Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        selected ? '선택한 가이드' : '일정 적합도 ${guide.match}%',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: selected ? Colors.white : AppColors.brand,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          guide.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      RatingLabel(
                        rating: guide.rating,
                        reviews: guide.reviewCount,
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    guide.badge,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.brand),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: guide.tags
                        .map((tag) => MetaPill(label: tag, compact: true))
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(
                        Icons.translate_rounded,
                        size: 18,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          guide.languages.join(' · '),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Text(
                        '${formatWon(guide.price)}부터',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyGuides extends StatelessWidget {
  const _EmptyGuides({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 70),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 44,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 14),
          Text(
            '“$query”와 맞는 가이드가 없어요',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '다른 이름이나 언어로 찾아보세요',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
