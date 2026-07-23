import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ai_assistant_sheet.dart';
import '../widgets/common.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({required this.appState, super.key});

  final AppState appState;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  String _category = '전체';
  String _query = '';
  Place? _selectedPlace;
  bool _keyboardWasVisible = false;
  double? _sheetSizeBeforeKeyboard;
  double _maxSheetSize = .80;

  static const _categories = [
    ('전체', Icons.near_me_outlined),
    ('자연', Icons.landscape_outlined),
    ('맛집', Icons.restaurant_outlined),
    ('문화', Icons.museum_outlined),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchFocusNode.addListener(_handleSearchFocus);
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    final keyboardVisible = View.of(context).viewInsets.bottom > 0;
    if (keyboardVisible && !_keyboardWasVisible) {
      _captureSheetSize();
    } else if (!keyboardVisible && _keyboardWasVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _restoreMapAfterKeyboard();
      });
    }
    _keyboardWasVisible = keyboardVisible;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchFocusNode.removeListener(_handleSearchFocus);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  List<Place> get _filteredPlaces => AppData.places.where((place) {
    final categoryMatched =
        _category == '전체' ||
        (_category == '자연' &&
            (place.category.contains('자연') || place.category.contains('바다'))) ||
        (_category == '맛집' &&
            (place.category.contains('맛집') || place.category.contains('시장'))) ||
        (_category == '문화' && place.category.contains('문화'));
    final queryMatched = '${place.name} ${place.category} ${place.location}'
        .toLowerCase()
        .contains(_query.toLowerCase());
    return categoryMatched && queryMatched;
  }).toList();

  @override
  Widget build(BuildContext context) {
    final places = _filteredPlaces;
    return Stack(
      key: const ValueKey('explore-map-layout'),
      children: [
        Positioned.fill(
          child: _MapView(
            key: const ValueKey('map'),
            places: places,
            selectedPlace: _selectedPlace,
            onSelected: _selectPlace,
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          top: MediaQuery.paddingOf(context).top + 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.white,
                      elevation: 4,
                      shadowColor: const Color(0x260F1720),
                      borderRadius: BorderRadius.circular(18),
                      child: TextField(
                        key: const ValueKey('explore-map-search'),
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: _updateQuery,
                        onSubmitted: (_) => _searchFocusNode.unfocus(),
                        onTapOutside: (_) => _searchFocusNode.unfocus(),
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: '장소, 음식, 지역을 찾아보세요',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    _updateQuery('');
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(
                              color: AppColors.brand,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _SavedPlacesHeaderButton(
                    count: widget.appState.savedPlaceIds.length,
                    onTap: () => _showSavedPlaces(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return _MapCategoryChip(
                      key: ValueKey('explore-category-${category.$1}'),
                      label: category.$1,
                      icon: category.$2,
                      selected: _category == category.$1,
                      onTap: () => _updateCategory(category.$1),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const searchHeight = 56.0;
              const headerGap = 10.0;
              const tagHeight = 42.0;
              const sheetGap = 12.0;
              final topInset = MediaQuery.paddingOf(context).top;
              final reservedTop =
                  topInset +
                  12 +
                  searchHeight +
                  headerGap +
                  tagHeight +
                  sheetGap;
              final maxSheetSize =
                  ((constraints.maxHeight - reservedTop) /
                          constraints.maxHeight)
                      .clamp(.55, .90)
                      .toDouble();
              _maxSheetSize = maxSheetSize;

              return DraggableScrollableSheet(
                key: const ValueKey('explore-bottom-sheet'),
                controller: _sheetController,
                initialChildSize: .27,
                minChildSize: .17,
                maxChildSize: maxSheetSize,
                snap: true,
                snapSizes: [.17, .5, maxSheetSize],
                builder: (context, scrollController) {
                  return Material(
                    color: Colors.white,
                    elevation: 12,
                    shadowColor: const Color(0x330F1720),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _selectedPlace == null
                        ? _ExplorePlaceListSheet(
                            key: const ValueKey('explore-place-list-sheet'),
                            controller: scrollController,
                            places: places,
                            onSelected: _selectPlace,
                          )
                        : _ExplorePlaceDetailSheet(
                            key: ValueKey(
                              'explore-place-detail-${_selectedPlace!.id}',
                            ),
                            controller: scrollController,
                            place: _selectedPlace!,
                            saved: widget.appState.isPlaceSaved(
                              _selectedPlace!.id,
                            ),
                            onBack: _showPlaceList,
                            onSave: () => _togglePlace(_selectedPlace!),
                          ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _updateQuery(String value) {
    setState(() {
      _query = value;
      _selectedPlace = null;
    });
  }

  void _handleSearchFocus() {
    if (_searchFocusNode.hasFocus) {
      _captureSheetSize();
    } else if (!_keyboardWasVisible) {
      _sheetSizeBeforeKeyboard = null;
    }
  }

  void _captureSheetSize() {
    if (!_sheetController.isAttached) return;
    _sheetSizeBeforeKeyboard ??= _sheetController.size;
  }

  void _restoreMapAfterKeyboard() {
    if (!mounted) return;
    final previousSize = _sheetSizeBeforeKeyboard;
    _sheetSizeBeforeKeyboard = null;
    _searchFocusNode.unfocus();
    if (previousSize == null || !_sheetController.isAttached) return;
    final target = previousSize.clamp(.17, _maxSheetSize).toDouble();
    if ((_sheetController.size - target).abs() < .001) return;
    _sheetController.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _updateCategory(String value) {
    setState(() {
      _category = value;
      _selectedPlace = null;
    });
  }

  void _selectPlace(Place place) {
    setState(() => _selectedPlace = place);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_sheetController.isAttached) return;
      final target = _sheetController.size < .34 ? .34 : _sheetController.size;
      _sheetController.animateTo(
        target.clamp(.17, .94),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _showPlaceList() {
    setState(() => _selectedPlace = null);
  }

  void _togglePlace(Place place) {
    widget.appState.togglePlace(place.id);
    setState(() {});
    showAppSnack(
      context,
      widget.appState.isPlaceSaved(place.id)
          ? '${place.name}을 내 여행에 담았어요'
          : '${place.name}을 내 여행에서 뺐어요',
    );
  }

  void _showSavedPlaces(BuildContext context) {
    final saved = AppData.places
        .where((place) => widget.appState.isPlaceSaved(place.id))
        .toList();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('내 여행', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              '${saved.length}곳 · 예상 방문시간 ${saved.fold<int>(0, (sum, place) => sum + place.stayTime)}분',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            if (saved.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('아직 담은 장소가 없어요')),
              )
            else
              for (var i = 0; i < saved.length; i++)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      saved[i].image,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(saved[i].name),
                  subtitle: Text(i == 0 ? '반드시 방문' : '시간이 되면 방문'),
                  trailing: const Icon(
                    Icons.drag_handle_rounded,
                    color: AppColors.textTertiary,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _selectPlace(saved[i]);
                  },
                ),
            if (saved.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    showAiAssistant(
                      context,
                      initialQuestion: '선택한 장소를 모두 방문할 수 있어?',
                    );
                  },
                  icon: const Icon(Icons.auto_awesome_rounded, size: 19),
                  label: const Text('AI로 일정 가능 여부 확인하기'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MapCategoryChip extends StatelessWidget {
  const _MapCategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.brand : Colors.white,
      elevation: selected ? 3 : 2,
      shadowColor: const Color(0x250F1720),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExploreSheetHandle extends StatelessWidget {
  const _ExploreSheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42,
        height: 5,
        margin: const EdgeInsets.only(top: 10, bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.line,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _ExplorePlaceListSheet extends StatelessWidget {
  const _ExplorePlaceListSheet({
    required this.controller,
    required this.places,
    required this.onSelected,
    super.key,
  });

  final ScrollController controller;
  final List<Place> places;
  final ValueChanged<Place> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('explore-place-list-scroll'),
      controller: controller,
      padding: EdgeInsets.zero,
      children: [
        const _ExploreSheetHandle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: [
              Text('주변 관광지', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              Text(
                '${places.length}곳',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        if (places.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 60),
            child: Column(
              children: [
                const Icon(
                  Icons.travel_explore_rounded,
                  size: 40,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(height: 10),
                Text(
                  '조건에 맞는 장소가 없어요',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '검색어나 태그를 바꿔보세요',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          )
        else
          for (final place in places)
            _ExplorePlaceRow(place: place, onTap: () => onSelected(place)),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _ExplorePlaceRow extends StatelessWidget {
  const _ExplorePlaceRow({required this.place, required this.onTap});

  final Place place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('explore-place-row-${place.id}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 16, 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                place.image,
                width: 78,
                height: 74,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const EmptyImageFallback(),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          place.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      RatingLabel(rating: place.rating),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${place.category} · 항구 ${place.fromPort}분',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        _hotSpotIcon(place),
                        size: 15,
                        color: _hotSpotColor(place),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${_hotSpotLabel(place)} · 결제 ${_formatCount(place.paymentCount)}건',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: _hotSpotColor(place)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExplorePlaceDetailSheet extends StatelessWidget {
  const _ExplorePlaceDetailSheet({
    required this.controller,
    required this.place,
    required this.saved,
    required this.onBack,
    required this.onSave,
    super.key,
  });

  final ScrollController controller;
  final Place place;
  final bool saved;
  final VoidCallback onBack;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final reviews = AppData.placeReviews
        .where((review) => review.placeId == place.id)
        .toList();
    return ListView(
      key: const ValueKey('explore-place-detail-scroll'),
      controller: controller,
      padding: EdgeInsets.zero,
      children: [
        const _ExploreSheetHandle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
          child: Row(
            children: [
              IconButton(
                key: const ValueKey('explore-place-back-to-list'),
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: '목록으로',
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  place.image,
                  width: 76,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const EmptyImageFallback(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.category,
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: AppColors.brand),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      place.name,
                      key: const ValueKey('explore-selected-place-name'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        RatingLabel(rating: place.rating),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '최근 결제 ${_formatCount(place.paymentCount)}건',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: _hotSpotColor(place)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const ValueKey('explore-place-save'),
                onPressed: onSave,
                icon: Icon(
                  saved
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                ),
                color: saved ? AppColors.brand : AppColors.textTertiary,
                tooltip: '내 여행에 담기',
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              place.image,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const EmptyImageFallback(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              MetaPill(
                label: '항구 ${place.fromPort}분',
                icon: Icons.directions_car_outlined,
              ),
              MetaPill(
                label: '${place.stayTime}분',
                icon: Icons.schedule_rounded,
              ),
              MetaPill(
                label: '${place.crowd}한 편',
                icon: Icons.groups_outlined,
                selected: place.crowd == '여유',
              ),
            ],
          ),
        ),
        _ExploreDetailSection(
          title: '이곳은 어떤 곳인가요?',
          child: Text(
            place.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        if (place.benefit != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: SurfaceCard(
              color: AppColors.brandWeak,
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.credit_card_rounded,
                      color: AppColors.brand,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '카드 혜택이 있어요',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          place.benefit!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        _ExploreDetailSection(
          title: '방문 정보',
          child: Column(
            children: [
              DetailInfoRow(
                icon: Icons.schedule_outlined,
                label: '운영시간',
                value: place.hours,
              ),
              DetailInfoRow(
                icon: Icons.location_on_outlined,
                label: '위치',
                value: place.location,
              ),
              DetailInfoRow(
                icon: Icons.anchor_rounded,
                label: '크루즈 항구에서',
                value: '차로 약 ${place.fromPort}분',
              ),
            ],
          ),
        ),
        _ExploreDetailSection(
          title: '최근 크루즈 여행자 후기 ${reviews.length}',
          child: Column(
            children: [
              if (reviews.isEmpty)
                Text(
                  '아직 등록된 후기가 없어요',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                for (final review in reviews)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ExplorePlaceReview(review: review),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}

class _ExploreDetailSection extends StatelessWidget {
  const _ExploreDetailSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ExplorePlaceReview extends StatelessWidget {
  const _ExplorePlaceReview({required this.review});

  final PlaceReview review;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      color: AppColors.surfaceSecondary,
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
          const SizedBox(height: 9),
          Text(review.content, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 11),
          Row(
            children: [
              Text(
                countryFlag(review.country),
                style: const TextStyle(fontSize: 17),
              ),
              const SizedBox(width: 6),
              Text(
                '${review.country} · ${review.author}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SavedPlacesHeaderButton extends StatelessWidget {
  const _SavedPlacesHeaderButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '내 여행 $count곳',
      button: true,
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x260F1720),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            RoundIconButton(
              key: const ValueKey('explore-saved-button'),
              icon: Icons.shopping_bag_outlined,
              onPressed: onTap,
              backgroundColor: Colors.white,
              foregroundColor: AppColors.brand,
              tooltip: '내 여행',
            ),
            Positioned(
              right: -3,
              top: -3,
              child: Container(
                constraints: const BoxConstraints(minWidth: 20),
                height: 20,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  '$count',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapView extends StatefulWidget {
  const _MapView({
    required this.places,
    required this.selectedPlace,
    required this.onSelected,
    super.key,
  });

  final List<Place> places;
  final Place? selectedPlace;
  final ValueChanged<Place> onSelected;

  static const _positions = [
    Alignment(0.05, 0.04),
    Alignment(-0.58, 0.00),
    Alignment(-0.25, 0.08),
    Alignment(0.12, -0.17),
    Alignment(0.68, -0.04),
  ];

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  final TransformationController _mapController = TransformationController();
  double _mapScale = 1;

  @override
  void initState() {
    super.initState();
    _mapController.addListener(_handleMapTransform);
  }

  @override
  void dispose() {
    _mapController.removeListener(_handleMapTransform);
    _mapController.dispose();
    super.dispose();
  }

  void _handleMapTransform() {
    final nextScale = _mapController.value.entry(0, 0).abs();
    if (!mounted || (nextScale - _mapScale).abs() < .001) return;
    setState(() => _mapScale = nextScale);
  }

  void _zoom(double factor) {
    final currentScale = _mapController.value.entry(0, 0).abs();
    final targetScale = (currentScale * factor).clamp(.8, 3.0);
    final nextTransform = _mapController.value.clone()
      ..setEntry(0, 0, targetScale)
      ..setEntry(1, 1, targetScale);
    setState(() => _mapScale = targetScale);
    _mapController.value = nextTransform;
  }

  void _resetMap() {
    setState(() => _mapScale = 1);
    _mapController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: _mapController,
              minScale: .8,
              maxScale: 3,
              boundaryMargin: const EdgeInsets.all(180),
              panEnabled: true,
              scaleEnabled: true,
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: Stack(
                  children: [
                    Positioned.fill(child: CustomPaint(painter: _MapPainter())),
                    Align(
                      alignment: const Alignment(-0.08, -0.18),
                      child: _FixedMapMarkerScale(
                        scale: _mapScale,
                        child: const _CruisePortMarker(
                          label: '제주항',
                          city: '제주시',
                        ),
                      ),
                    ),
                    Align(
                      alignment: const Alignment(-0.30, 0.08),
                      child: _FixedMapMarkerScale(
                        scale: _mapScale,
                        child: const _CruisePortMarker(
                          label: '강정항',
                          city: '서귀포',
                        ),
                      ),
                    ),
                    for (var i = 0; i < widget.places.length; i++)
                      Align(
                        alignment:
                            _MapView._positions[i % _MapView._positions.length],
                        child: _FixedMapMarkerScale(
                          key: ValueKey(
                            'fixed-map-marker-${widget.places[i].id}',
                          ),
                          transformKey: ValueKey(
                            'fixed-map-marker-transform-${widget.places[i].id}',
                          ),
                          scale: _mapScale,
                          child: _MapPhotoMarker(
                            place: widget.places[i],
                            selected:
                                widget.places[i].id == widget.selectedPlace?.id,
                            onTap: () => widget.onSelected(widget.places[i]),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(left: 14, top: 142, child: _MapHotLegend()),
          Positioned(
            right: 14,
            top: 142,
            child: Column(
              children: [
                _MapControl(
                  key: const ValueKey('map-zoom-in'),
                  icon: Icons.add_rounded,
                  tooltip: '지도 확대',
                  onTap: () => _zoom(1.35),
                ),
                const SizedBox(height: 9),
                _MapControl(
                  key: const ValueKey('map-zoom-out'),
                  icon: Icons.remove_rounded,
                  tooltip: '지도 축소',
                  onTap: () => _zoom(1 / 1.35),
                ),
                const SizedBox(height: 9),
                _MapControl(
                  key: const ValueKey('map-reset-position'),
                  icon: Icons.center_focus_strong_rounded,
                  tooltip: '지도 위치 초기화',
                  onTap: _resetMap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FixedMapMarkerScale extends StatelessWidget {
  const _FixedMapMarkerScale({
    required this.scale,
    required this.child,
    this.transformKey,
    super.key,
  });

  final double scale;
  final Widget child;
  final Key? transformKey;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      key: transformKey,
      scale: 1 / scale,
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _CruisePortMarker extends StatelessWidget {
  const _CruisePortMarker({required this.label, required this.city});

  final String label;
  final String city;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 5, 9, 5),
      decoration: BoxDecoration(
        color: AppColors.brandNavy,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x29123A63),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.anchor_rounded, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            '$label · $city',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _MapControl extends StatelessWidget {
  const _MapControl({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 3,
        shadowColor: const Color(0x1C0F1720),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, size: 20, color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _MapHotLegend extends StatelessWidget {
  const _MapHotLegend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F1720),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MapLegendItem(
            icon: Icons.local_fire_department_rounded,
            color: AppColors.danger,
            label: '결제 집중',
          ),
          SizedBox(height: 5),
          _MapLegendItem(
            icon: Icons.trending_up_rounded,
            color: AppColors.warning,
            label: '인기 상승',
          ),
          SizedBox(height: 5),
          _MapLegendItem(
            icon: Icons.star_rounded,
            color: AppColors.brand,
            label: '꾸준한 인기',
          ),
        ],
      ),
    );
  }
}

class _MapLegendItem extends StatelessWidget {
  const _MapLegendItem({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _MapPhotoMarker extends StatelessWidget {
  const _MapPhotoMarker({
    required this.place,
    required this.selected,
    required this.onTap,
  });

  final Place place;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _hotSpotColor(place);
    final icon = _hotSpotIcon(place);
    return Semantics(
      button: true,
      label:
          '${place.name} 정보 보기, ${_hotSpotLabel(place)}, 최근 결제 ${place.paymentCount}건',
      child: GestureDetector(
        key: ValueKey('map-marker-${place.id}'),
        onTap: onTap,
        child: AnimatedScale(
          scale: selected ? 1.08 : 1,
          duration: const Duration(milliseconds: 180),
          child: SizedBox(
            width: 58,
            height: 70,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? AppColors.brand : Colors.white,
                      width: selected ? 2.5 : 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x2A0F1720),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      place.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const EmptyImageFallback(),
                    ),
                  ),
                ),
                Positioned(
                  top: 44,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: .32),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(icon, size: 14, color: Colors.white),
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

Color _hotSpotColor(Place place) {
  if (place.paymentCount >= 800) return AppColors.danger;
  if (place.paymentCount >= 500) return AppColors.warning;
  return AppColors.brand;
}

IconData _hotSpotIcon(Place place) {
  if (place.paymentCount >= 800) {
    return Icons.local_fire_department_rounded;
  }
  if (place.paymentCount >= 500) return Icons.trending_up_rounded;
  return Icons.star_rounded;
}

String _hotSpotLabel(Place place) {
  if (place.paymentCount >= 800) return '결제 집중 장소';
  if (place.paymentCount >= 500) return '인기 상승 장소';
  return '꾸준한 인기 장소';
}

String _formatCount(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    double mapY(double y) => size.height * .46 + (y - .49) * size.width;

    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFCDEAF8), Color(0xFFDDF2FA), Color(0xFFC8E7F4)],
          stops: [0, .48, 1],
        ).createShader(bounds),
    );

    void drawLabel(
      String text,
      Offset center, {
      double size = 12,
      Color color = const Color(0xFF63798B),
      FontWeight weight = FontWeight.w600,
      double letterSpacing = 0,
    }) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: color,
            fontSize: size,
            fontWeight: weight,
            height: 1,
            letterSpacing: letterSpacing,
            shadows: const [
              Shadow(
                color: Color(0xB3FFFFFF),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
      );
    }

    void drawTown(String name, double x, double y, {bool major = false}) {
      final center = Offset(size.width * x, mapY(y));
      canvas.drawCircle(
        center,
        major ? 3.6 : 2.7,
        Paint()
          ..color = major ? const Color(0xFF4E6F66) : const Color(0xFF789086),
      );
      drawLabel(
        name,
        center.translate(0, major ? 13 : 11),
        size: major ? 11.5 : 9.5,
        color: major ? const Color(0xFF405B55) : const Color(0xFF657A72),
        weight: major ? FontWeight.w700 : FontWeight.w600,
      );
    }

    void drawRoad(Path path, {bool primary = false}) {
      canvas.drawPath(
        path,
        Paint()
          ..color = primary ? const Color(0xFFB8C8BE) : const Color(0xFFC9D5CE)
          ..style = PaintingStyle.stroke
          ..strokeWidth = primary ? 5.4 : 3.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = primary ? Colors.white : const Color(0xFFF8FAF7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = primary ? 3.5 : 2.1
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    void drawRoadShield(String number, double x, double y) {
      final center = Offset(size.width * x, mapY(y));
      final textPainter = TextPainter(
        text: TextSpan(
          text: number,
          style: const TextStyle(
            color: Color(0xFF7A6A45),
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final rect = Rect.fromCenter(
        center: center,
        width: textPainter.width + 9,
        height: 16,
      );
      canvas
        ..drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          Paint()..color = const Color(0xFFFFF7D9),
        )
        ..drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          Paint()
            ..color = const Color(0xFFD8C68B)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      textPainter.paint(
        canvas,
        Offset(
          center.dx - textPainter.width / 2,
          center.dy - textPainter.height / 2,
        ),
      );
    }

    final waterDetail = Paint()
      ..color = const Color(0x3383B8D2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    for (var row = 0; row < 5; row++) {
      for (var column = 0; column < 6; column++) {
        final center = Offset(
          size.width * (.08 + column * .18 + (row.isOdd ? .05 : 0)),
          size.height * (.08 + row * .19),
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: center,
            width: size.width * .045,
            height: size.height * .012,
          ),
          0,
          3.14,
          false,
          waterDetail,
        );
      }
    }

    final ferryPaint = Paint()
      ..color = const Color(0x4D6FA9C6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15;
    for (var index = 0; index < 3; index++) {
      final route = Path()
        ..moveTo(size.width * (.43 + index * .035), mapY(.29))
        ..cubicTo(
          size.width * (.40 + index * .03),
          size.height * .20,
          size.width * (.34 + index * .05),
          size.height * .12,
          size.width * (.28 + index * .11),
          size.height * .035,
        );
      canvas.drawPath(route, ferryPaint);
    }
    drawLabel(
      '제 주 해 협',
      Offset(size.width * .52, size.height * .12),
      size: 13,
      color: const Color(0xFF5E8EA7),
      weight: FontWeight.w700,
      letterSpacing: 1.2,
    );

    final island = Path()
      ..moveTo(size.width * .025, mapY(.49))
      ..cubicTo(
        size.width * .055,
        mapY(.43),
        size.width * .105,
        mapY(.375),
        size.width * .19,
        mapY(.345),
      )
      ..cubicTo(
        size.width * .285,
        mapY(.305),
        size.width * .38,
        mapY(.315),
        size.width * .47,
        mapY(.295),
      )
      ..cubicTo(
        size.width * .58,
        mapY(.275),
        size.width * .66,
        mapY(.29),
        size.width * .75,
        mapY(.315),
      )
      ..cubicTo(
        size.width * .84,
        mapY(.335),
        size.width * .93,
        mapY(.375),
        size.width * .975,
        mapY(.445),
      )
      ..cubicTo(
        size.width * .995,
        mapY(.485),
        size.width * .955,
        mapY(.535),
        size.width * .89,
        mapY(.565),
      )
      ..cubicTo(
        size.width * .81,
        mapY(.605),
        size.width * .69,
        mapY(.63),
        size.width * .59,
        mapY(.655),
      )
      ..cubicTo(
        size.width * .49,
        mapY(.69),
        size.width * .38,
        mapY(.705),
        size.width * .28,
        mapY(.68),
      )
      ..cubicTo(
        size.width * .18,
        mapY(.66),
        size.width * .09,
        mapY(.605),
        size.width * .038,
        mapY(.55),
      )
      ..close();

    canvas.save();
    canvas.translate(0, size.width * .012);
    canvas.drawPath(
      island,
      Paint()
        ..color = const Color(0x3D31576A)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.restore();

    canvas
      ..drawPath(
        island,
        Paint()
          ..color = const Color(0xE6FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9,
      )
      ..drawPath(
        island,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF4F1DD), Color(0xFFE6F0D9), Color(0xFFDCEBD4)],
          ).createShader(bounds),
      )
      ..drawPath(
        island,
        Paint()
          ..color = const Color(0xFF97B39D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );

    canvas.save();
    canvas.clipPath(island);

    final westernFields = Path()
      ..moveTo(size.width * .06, mapY(.47))
      ..cubicTo(
        size.width * .16,
        mapY(.38),
        size.width * .27,
        mapY(.39),
        size.width * .35,
        mapY(.45),
      )
      ..cubicTo(
        size.width * .28,
        mapY(.55),
        size.width * .18,
        mapY(.61),
        size.width * .08,
        mapY(.56),
      )
      ..close();
    canvas.drawPath(westernFields, Paint()..color = const Color(0x55F7EDC7));

    final easternForest = Path()
      ..moveTo(size.width * .63, mapY(.35))
      ..cubicTo(
        size.width * .78,
        mapY(.33),
        size.width * .91,
        mapY(.40),
        size.width * .94,
        mapY(.48),
      )
      ..cubicTo(
        size.width * .84,
        mapY(.58),
        size.width * .72,
        mapY(.60),
        size.width * .61,
        mapY(.55),
      )
      ..close();
    canvas.drawPath(easternForest, Paint()..color = const Color(0x3DAED39F));

    final mountainBounds = Rect.fromCenter(
      center: Offset(size.width * .50, mapY(.49)),
      width: size.width * .43,
      height: size.width * .31,
    );
    canvas.drawOval(
      mountainBounds,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFC1DDAE), Color(0x99CFE4BE), Color(0x00DDECCF)],
          stops: [0, .58, 1],
        ).createShader(mountainBounds),
    );

    final fieldPaint = Paint()
      ..color = const Color(0x287D9D82)
      ..strokeWidth = .8;
    for (var index = 0; index < 9; index++) {
      final x = size.width * (.10 + index * .10);
      canvas.drawLine(
        Offset(x, mapY(.35)),
        Offset(x - size.width * .07, mapY(.64)),
        fieldPaint,
      );
    }

    for (var level = 0; level < 4; level++) {
      final inset = level * .035;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * .50, mapY(.49)),
          width: size.width * (.36 - inset),
          height: size.width * (.245 - inset * .7),
        ),
        Paint()
          ..color = const Color(0x55749B68)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    final coastRoad = Path()
      ..moveTo(size.width * .07, mapY(.49))
      ..cubicTo(
        size.width * .20,
        mapY(.355),
        size.width * .37,
        mapY(.345),
        size.width * .50,
        mapY(.33),
      )
      ..cubicTo(
        size.width * .68,
        mapY(.31),
        size.width * .84,
        mapY(.37),
        size.width * .92,
        mapY(.46),
      )
      ..cubicTo(
        size.width * .85,
        mapY(.57),
        size.width * .68,
        mapY(.61),
        size.width * .51,
        mapY(.65),
      )
      ..cubicTo(
        size.width * .34,
        mapY(.68),
        size.width * .15,
        mapY(.62),
        size.width * .07,
        mapY(.52),
      );
    drawRoad(coastRoad, primary: true);

    final centralRoad = Path()
      ..moveTo(size.width * .49, mapY(.33))
      ..cubicTo(
        size.width * .46,
        mapY(.41),
        size.width * .49,
        mapY(.54),
        size.width * .47,
        mapY(.65),
      );
    final westRoad = Path()
      ..moveTo(size.width * .19, mapY(.37))
      ..cubicTo(
        size.width * .31,
        mapY(.43),
        size.width * .34,
        mapY(.54),
        size.width * .30,
        mapY(.66),
      );
    final eastRoad = Path()
      ..moveTo(size.width * .78, mapY(.36))
      ..cubicTo(
        size.width * .68,
        mapY(.42),
        size.width * .65,
        mapY(.53),
        size.width * .72,
        mapY(.60),
      );
    final beltRoad = Path()
      ..moveTo(size.width * .12, mapY(.51))
      ..cubicTo(
        size.width * .33,
        mapY(.43),
        size.width * .67,
        mapY(.56),
        size.width * .90,
        mapY(.45),
      );
    drawRoad(centralRoad, primary: true);
    drawRoad(westRoad);
    drawRoad(eastRoad);
    drawRoad(beltRoad);

    canvas.restore();

    final summit = Offset(size.width * .50, mapY(.49));
    canvas
      ..drawCircle(summit, 7, Paint()..color = const Color(0xFFD7E9C8))
      ..drawCircle(
        summit,
        7,
        Paint()
          ..color = const Color(0xFF6E9664)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      )
      ..drawCircle(summit, 2.5, Paint()..color = const Color(0xFF6E9664));

    drawRoadShield('1131', .56, .565);
    drawRoadShield('1115', .30, .48);
    drawRoadShield('1132', .75, .49);

    drawTown('제주시', .50, .335, major: true);
    drawTown('애월', .24, .39);
    drawTown('한림', .13, .46);
    drawTown('성산', .84, .43);
    drawTown('표선', .78, .56);
    drawTown('중문', .34, .61);
    drawTown('서귀포', .50, .645, major: true);

    drawLabel(
      '한라산\n1,947m',
      summit.translate(0, 18),
      size: 10.5,
      color: const Color(0xFF4D7749),
      weight: FontWeight.w700,
    );

    void drawSmallIsland(
      String label,
      double x,
      double y,
      double width,
      double height,
    ) {
      final rect = Rect.fromCenter(
        center: Offset(size.width * x, mapY(y)),
        width: size.width * width,
        height: size.width * height,
      );
      canvas
        ..drawOval(
          rect.inflate(2),
          Paint()..color = Colors.white.withValues(alpha: .82),
        )
        ..drawOval(rect, Paint()..color = const Color(0xFFDCEBD3));
      drawLabel(
        label,
        rect.center.translate(0, rect.height / 2 + 8),
        size: 8.5,
        color: const Color(0xFF678296),
      );
    }

    drawSmallIsland('우도', .975, .39, .025, .020);
    drawSmallIsland('비양도', .10, .34, .020, .014);
    drawSmallIsland('가파도', .28, .735, .025, .013);
    drawSmallIsland('마라도', .23, .785, .018, .012);

    drawLabel(
      '한라산국립공원',
      Offset(size.width * .61, mapY(.52)),
      size: 8.8,
      color: const Color(0xFF6D9365),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
