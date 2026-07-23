import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ai_assistant_sheet.dart';
import '../widgets/common.dart';
import 'place_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({required this.appState, super.key});

  final AppState appState;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showMap = false;
  String _category = '전체';
  String _query = '';
  Place _selectedPlace = AppData.places.first;

  @override
  void dispose() {
    _searchController.dispose();
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
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          PageHeader(
            title: '둘러보기',
            subtitle: '기항 시간 안에 다녀올 수 있는 장소예요',
            action: _SavedPlacesHeaderButton(
              count: widget.appState.savedPlaceIds.length,
              onTap: () => _showSavedPlaces(context),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: '장소, 음식, 지역을 찾아보세요',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: _SegmentedSwitch(
              showMap: _showMap,
              onChanged: (value) => setState(() => _showMap = value),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: ['전체', '자연', '맛집', '문화'].map((category) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: _category == category,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _category = category),
                    labelStyle: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(
                          color: _category == category
                              ? AppColors.brand
                              : AppColors.textSecondary,
                        ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _showMap ? _buildMap() : _buildList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final places = _filteredPlaces;
    if (places.isEmpty) {
      return Center(
        key: const ValueKey('empty'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.travel_explore_rounded,
              size: 44,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              '조건에 맞는 장소가 없어요',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '검색어나 카테고리를 바꿔보세요',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      key: const ValueKey('list'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      itemCount: places.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final place = places[index];
        return _PlaceCard(
          place: place,
          saved: widget.appState.isPlaceSaved(place.id),
          onTap: () => _openPlace(place),
          onSave: () => _togglePlace(place),
        );
      },
    );
  }

  Widget _buildMap() {
    final places = _filteredPlaces;
    if (places.isEmpty) {
      return const Center(key: ValueKey('map'), child: Text('지도에 표시할 장소가 없어요'));
    }
    final selectedPlace = places.any((place) => place.id == _selectedPlace.id)
        ? _selectedPlace
        : places.first;
    return _MapView(
      key: const ValueKey('map'),
      places: places,
      selectedPlace: selectedPlace,
      saved: widget.appState.isPlaceSaved(selectedPlace.id),
      onSelected: (place) => setState(() => _selectedPlace = place),
      onDetail: _openPlace,
      onSave: () => _togglePlace(selectedPlace),
    );
  }

  void _togglePlace(Place place) {
    widget.appState.togglePlace(place.id);
    showAppSnack(
      context,
      widget.appState.isPlaceSaved(place.id)
          ? '${place.name}을 내 여행에 담았어요'
          : '${place.name}을 내 여행에서 뺐어요',
    );
  }

  void _openPlace(Place place) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PlaceDetailScreen(place: place, appState: widget.appState),
      ),
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
                    _openPlace(saved[i]);
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

class _SavedPlacesHeaderButton extends StatelessWidget {
  const _SavedPlacesHeaderButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '내 여행 $count곳',
      button: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          RoundIconButton(
            key: const ValueKey('explore-saved-button'),
            icon: Icons.shopping_bag_outlined,
            onPressed: onTap,
            backgroundColor: AppColors.brandWeak,
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
    );
  }
}

class _SegmentedSwitch extends StatelessWidget {
  const _SegmentedSwitch({required this.showMap, required this.onChanged});

  final bool showMap;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _Segment(
            label: '목록',
            selected: !showMap,
            onTap: () => onChanged(false),
          ),
          _Segment(
            label: '지도',
            selected: showMap,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected
                    ? AppColors.textPrimary
                    : AppColors.textTertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
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
    return Material(
      color: AppColors.surfaceSecondary,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 186,
                  width: double.infinity,
                  child: Image.asset(
                    place.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const EmptyImageFallback(),
                  ),
                ),
                if (place.guidePick)
                  Positioned(
                    left: 14,
                    top: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '가이드 추천',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.brand,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: 12,
                  top: 12,
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
                          : Colors.black.withValues(alpha: 0.32),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.category,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: AppColors.brand),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          place.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      RatingLabel(rating: place.rating),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      MetaPill(
                        label: '항구 ${place.fromPort}분',
                        icon: Icons.directions_car_outlined,
                        compact: true,
                      ),
                      MetaPill(
                        label: '${place.stayTime}분',
                        icon: Icons.schedule_rounded,
                        compact: true,
                      ),
                      MetaPill(
                        label: place.crowd,
                        icon: Icons.groups_outlined,
                        selected: place.crowd == '여유',
                        compact: true,
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

class _MapView extends StatefulWidget {
  const _MapView({
    required this.places,
    required this.selectedPlace,
    required this.saved,
    required this.onSelected,
    required this.onDetail,
    required this.onSave,
    super.key,
  });

  final List<Place> places;
  final Place selectedPlace;
  final bool saved;
  final ValueChanged<Place> onSelected;
  final ValueChanged<Place> onDetail;
  final VoidCallback onSave;

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
  bool _previewVisible = false;
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: LayoutBuilder(
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
                        Positioned.fill(
                          child: CustomPaint(painter: _MapPainter()),
                        ),
                        Align(
                          alignment: Alignment(-0.38, -0.48),
                          child: _FixedMapMarkerScale(
                            scale: _mapScale,
                            child: const _CruisePortMarker(
                              label: '제주항',
                              city: '제주시',
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment(-0.08, 0.42),
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
                            alignment: _MapView
                                ._positions[i % _MapView._positions.length],
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
                                    widget.places[i].id ==
                                    widget.selectedPlace.id,
                                onTap: () {
                                  widget.onSelected(widget.places[i]);
                                  setState(() => _previewVisible = true);
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const Positioned(left: 14, top: 14, child: _MapHotLegend()),
              Positioned(
                right: 14,
                top: 14,
                child: Column(
                  children: [
                    _MapControl(
                      key: const ValueKey('map-zoom-in'),
                      icon: Icons.add_rounded,
                      tooltip: '지도 확대',
                      onTap: () => _zoom(1.35),
                    ),
                    SizedBox(height: 9),
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
              if (_previewVisible)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: _MapPlacePreview(
                    place: widget.selectedPlace,
                    saved: widget.saved,
                    onTap: () => widget.onDetail(widget.selectedPlace),
                    onSave: widget.onSave,
                  ),
                ),
            ],
          ),
        ),
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

class _MapPlacePreview extends StatelessWidget {
  const _MapPlacePreview({
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
    return Material(
      key: const ValueKey('map-place-preview'),
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  place.image,
                  width: 78,
                  height: 72,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '항구 ${place.fromPort}분 · ${place.stayTime}분 머물러요',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        RatingLabel(rating: place.rating),
                        const SizedBox(width: 8),
                        Icon(
                          _hotSpotIcon(place),
                          size: 15,
                          color: _hotSpotColor(place),
                        ),
                        const SizedBox(width: 3),
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
                onPressed: onSave,
                icon: Icon(
                  saved
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                ),
                color: saved ? AppColors.brand : AppColors.textTertiary,
              ),
            ],
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
