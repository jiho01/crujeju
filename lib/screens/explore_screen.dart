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

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  String _category = '전체';
  String _query = '';
  Place? _selectedPlace;

  static const _categories = [
    ('전체', Icons.near_me_outlined),
    ('자연', Icons.landscape_outlined),
    ('맛집', Icons.restaurant_outlined),
    ('문화', Icons.museum_outlined),
  ];

  @override
  void dispose() {
    _searchController.dispose();
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
                        onChanged: _updateQuery,
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
        DraggableScrollableSheet(
          key: const ValueKey('explore-bottom-sheet'),
          controller: _sheetController,
          initialChildSize: .27,
          minChildSize: .17,
          maxChildSize: .94,
          snap: true,
          snapSizes: const [.17, .5, .94],
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
                      saved: widget.appState.isPlaceSaved(_selectedPlace!.id),
                      onBack: _showPlaceList,
                      onSave: () => _togglePlace(_selectedPlace!),
                    ),
            );
          },
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
    Alignment(-0.68, -0.25),
    Alignment(-0.25, 0.14),
    Alignment(0.12, -0.48),
    Alignment(0.68, -0.2),
    Alignment(0.56, 0.25),
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
                      alignment: const Alignment(-0.38, -0.48),
                      child: _FixedMapMarkerScale(
                        scale: _mapScale,
                        child: const _CruisePortMarker(
                          label: '제주항',
                          city: '제주시',
                        ),
                      ),
                    ),
                    Align(
                      alignment: const Alignment(-0.08, 0.42),
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
            width: 68,
            height: 82,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
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
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      place.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const EmptyImageFallback(),
                    ),
                  ),
                ),
                Positioned(
                  top: 53,
                  child: Container(
                    width: 26,
                    height: 26,
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
                    child: Icon(icon, size: 15, color: Colors.white),
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
    canvas.drawColor(const Color(0xFFD8EEF9), BlendMode.src);

    void drawLabel(
      String text,
      Offset center, {
      double size = 12,
      Color color = const Color(0xFF63798B),
      FontWeight weight = FontWeight.w600,
    }) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: color,
            fontSize: size,
            fontWeight: weight,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
      );
    }

    final ferryLine = Paint()
      ..color = const Color(0x5581AFC9)
      ..strokeWidth = 1.4;
    for (var i = 0; i < 7; i++) {
      final startY = size.height * (.05 + i * .035);
      canvas.drawLine(
        Offset(size.width * (.23 + i * .065), startY),
        Offset(size.width * (.43 + i * .04), size.height * .25),
        ferryLine,
      );
    }
    drawLabel('제주해협', Offset(size.width * .5, size.height * .13), size: 14);

    final island = Path()
      ..moveTo(size.width * .035, size.height * .47)
      ..cubicTo(
        size.width * .11,
        size.height * .31,
        size.width * .28,
        size.height * .27,
        size.width * .43,
        size.height * .30,
      )
      ..cubicTo(
        size.width * .60,
        size.height * .25,
        size.width * .87,
        size.height * .31,
        size.width * .965,
        size.height * .43,
      )
      ..cubicTo(
        size.width * .92,
        size.height * .56,
        size.width * .76,
        size.height * .64,
        size.width * .58,
        size.height * .66,
      )
      ..cubicTo(
        size.width * .42,
        size.height * .71,
        size.width * .16,
        size.height * .65,
        size.width * .035,
        size.height * .53,
      )
      ..close();
    canvas
      ..drawPath(
        island,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7,
      )
      ..drawPath(island, Paint()..color = const Color(0xFFEAF3E7));

    final park = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(size.width * .49, size.height * .48),
          width: size.width * .33,
          height: size.height * .25,
        ),
      );
    canvas.drawPath(park, Paint()..color = const Color(0xFFD6EBCF));

    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: .95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    final crossRoad = Path()
      ..moveTo(size.width * .08, size.height * .48)
      ..cubicTo(
        size.width * .3,
        size.height * .38,
        size.width * .68,
        size.height * .58,
        size.width * .92,
        size.height * .43,
      );
    final northRoad = Path()
      ..moveTo(size.width * .31, size.height * .31)
      ..quadraticBezierTo(
        size.width * .42,
        size.height * .48,
        size.width * .28,
        size.height * .63,
      );
    final eastRoad = Path()
      ..moveTo(size.width * .72, size.height * .31)
      ..quadraticBezierTo(
        size.width * .57,
        size.height * .46,
        size.width * .73,
        size.height * .62,
      );
    canvas
      ..drawPath(crossRoad, roadPaint)
      ..drawPath(northRoad, roadPaint)
      ..drawPath(eastRoad, roadPaint);

    final routePaint = Paint()
      ..color = const Color(0x335D9EC2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var i = 0; i < 5; i++) {
      canvas.drawLine(
        Offset(size.width * (.18 + i * .14), size.height * .34),
        Offset(size.width * (.27 + i * .11), size.height * .62),
        routePaint,
      );
    }

    drawLabel(
      '제주시',
      Offset(size.width * .5, size.height * .32),
      color: const Color(0xFF52666F),
    );
    drawLabel(
      '한라산',
      Offset(size.width * .5, size.height * .49),
      color: const Color(0xFF4E7C4B),
      weight: FontWeight.w700,
    );
    drawLabel(
      '서귀포시',
      Offset(size.width * .5, size.height * .64),
      color: const Color(0xFF52666F),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
