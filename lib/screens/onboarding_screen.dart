import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({required this.onCompleted, super.key});

  final Future<void> Function(OnboardingData data) onCompleted;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _searchController = TextEditingController();

  int _step = 0;
  String _language = '한국어';
  String _currency = 'KRW';
  int _travelerCount = 2;
  String _port = '강정항';
  String _date = '7월 30일';
  String _query = '';
  CruiseOption? _selectedCruise;
  final Set<String> _interests = {};
  String? _transport;
  bool _submitting = false;

  static const _languages = [
    ('한국어', 'KO'),
    ('English', 'EN'),
    ('中文', 'ZH'),
    ('日本語', 'JA'),
  ];

  static const _currencies = [
    ('KRW', '대한민국 원', '₩'),
    ('USD', '미국 달러', r'$'),
    ('JPY', '일본 엔', '¥'),
    ('CNY', '중국 위안', '元'),
  ];

  static const _interestOptions = [
    ('자연', Icons.landscape_outlined),
    ('맛집', Icons.restaurant_outlined),
    ('쇼핑', Icons.shopping_bag_outlined),
    ('사진', Icons.photo_camera_outlined),
    ('역사·문화', Icons.account_balance_outlined),
    ('액티비티', Icons.kayaking_outlined),
  ];

  static const _transportOptions = [
    ('밴', '5–8인', Icons.airport_shuttle_outlined),
    ('승용차', '2–4인', Icons.directions_car_outlined),
    ('오토바이', '1인', Icons.two_wheeler_outlined),
    ('택시', '호출형', Icons.local_taxi_outlined),
  ];

  List<CruiseOption> get _visibleCruises {
    return AppData.cruises.where((cruise) {
      final matchesPort = cruise.port == _port;
      final matchesDate = cruise.date == _date;
      final searchable = '${cruise.shipName} ${cruise.company}'.toLowerCase();
      final matchesQuery = searchable.contains(_query.trim().toLowerCase());
      return matchesPort && matchesDate && matchesQuery;
    }).toList();
  }

  bool get _canContinue {
    return switch (_step) {
      0 => _language.isNotEmpty && _currency.isNotEmpty,
      1 => _selectedCruise != null,
      2 => _interests.isNotEmpty && _transport != null,
      _ => false,
    };
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      body: AppPage(
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: SafeArea(
            child: Column(
              children: [
                _OnboardingHeader(step: _step),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (value) => setState(() => _step = value),
                    children: [
                      _buildBasicStep(),
                      _buildCruiseStep(),
                      _buildPreferenceStep(),
                    ],
                  ),
                ),
                _BottomNavigation(
                  step: _step,
                  enabled: _canContinue && !_submitting,
                  loading: _submitting,
                  onPrevious: _goPrevious,
                  onNext: _goNext,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicStep() {
    return SingleChildScrollView(
      key: const PageStorageKey('onboarding-basic'),
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepTitle(
            eyebrow: '기본 설정',
            title: '여행에 맞게\n기본 정보를 설정해요',
            description: '언어와 통화는 나중에 설정에서 바꿀 수 있어요.',
          ),
          const SizedBox(height: 34),
          _FieldLabel(label: '사용 언어', value: _language),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _languages.map((language) {
                  return SizedBox(
                    width: width,
                    child: _SelectionTile(
                      title: language.$1,
                      trailing: language.$2,
                      selected: _language == language.$1,
                      onTap: () => setState(() => _language = language.$1),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 28),
          _FieldLabel(label: '표시 통화', value: _currency),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _currencies.map((currency) {
                  return SizedBox(
                    width: width,
                    child: _SelectionTile(
                      title: currency.$1,
                      subtitle: currency.$2,
                      trailing: currency.$3,
                      selected: _currency == currency.$1,
                      onTap: () => setState(() => _currency = currency.$1),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 28),
          const _FieldLabel(label: '여행 인원'),
          const SizedBox(height: 12),
          _TravelerCounter(
            count: _travelerCount,
            onDecrease: _travelerCount <= 1
                ? null
                : () => setState(() => _travelerCount--),
            onIncrease: _travelerCount >= 12
                ? null
                : () => setState(() => _travelerCount++),
          ),
        ],
      ),
    );
  }

  Widget _buildCruiseStep() {
    final cruises = _visibleCruises;
    return CustomScrollView(
      key: const PageStorageKey('onboarding-cruise'),
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 26, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _StepTitle(
              eyebrow: '크루즈 정보',
              title: '제주에 오는\n크루즈를 선택해요',
              description: '항구와 날짜를 고르면 입출항 일정을 자동으로 불러와요.',
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _PortSelector(
              selectedPort: _port,
              onChanged: (port) {
                setState(() {
                  _port = port;
                  if (_selectedCruise?.port != port) _selectedCruise = null;
                });
              },
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _DatePickerButton(
              key: const ValueKey('onboarding-date-picker'),
              date: _date,
              onTap: _selectCruiseDate,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          sliver: SliverToBoxAdapter(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: '선박명 또는 크루즈 회사 검색',
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
        ),
        if (cruises.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyCruiseResult(query: _query),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            sliver: SliverList.separated(
              itemCount: cruises.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final cruise = cruises[index];
                return _CruiseCard(
                  cruise: cruise,
                  selected: _selectedCruise?.id == cruise.id,
                  onTap: () => setState(() => _selectedCruise = cruise),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPreferenceStep() {
    return SingleChildScrollView(
      key: const PageStorageKey('onboarding-preference'),
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepTitle(
            eyebrow: '여행 취향',
            title: '어떤 제주 여행을\n원하는지 알려주세요',
            description: '선택한 취향에 맞춰 장소와 가이드를 추천해요.',
          ),
          const SizedBox(height: 34),
          _FieldLabel(
            label: '관심 분야',
            value: _interests.isEmpty
                ? '여러 개 선택할 수 있어요'
                : '${_interests.length}개 선택',
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _interestOptions.map((interest) {
                  final selected = _interests.contains(interest.$1);
                  return SizedBox(
                    width: width,
                    child: _IconSelectionTile(
                      title: interest.$1,
                      icon: interest.$2,
                      selected: selected,
                      onTap: () {
                        setState(() {
                          if (!selected) {
                            _interests.add(interest.$1);
                          } else {
                            _interests.remove(interest.$1);
                          }
                        });
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 30),
          _FieldLabel(label: '희망 이동수단', value: _transport),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _transportOptions.map((transport) {
                  return SizedBox(
                    width: width,
                    child: _IconSelectionTile(
                      title: transport.$1,
                      subtitle: transport.$2,
                      icon: transport.$3,
                      selected: _transport == transport.$1,
                      onTap: () => setState(() => _transport = transport.$1),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _selectCruiseDate() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('ko'),
      initialDate: _calendarDateForLabel(_date, today),
      firstDate: today,
      lastDate: DateTime(today.year + 2, 12, 31),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText: '입항 날짜 선택',
      cancelText: '취소',
      confirmText: '선택',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          datePickerTheme: DatePickerThemeData(
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            headerBackgroundColor: AppColors.brandWeak,
            headerForegroundColor: AppColors.textPrimary,
            dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
              return states.contains(WidgetState.selected)
                  ? AppColors.brand
                  : null;
            }),
            dayForegroundColor: WidgetStateProperty.resolveWith((states) {
              return states.contains(WidgetState.selected)
                  ? Colors.white
                  : AppColors.textPrimary;
            }),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;

    final date = '${picked.month}월 ${picked.day}일';
    setState(() {
      _date = date;
      if (_selectedCruise?.date != date) _selectedCruise = null;
    });
  }

  void _goPrevious() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_step == 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _goNext() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_canContinue) return;

    if (_step < 2) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    setState(() => _submitting = true);
    await widget.onCompleted(
      OnboardingData(
        language: _language,
        currency: _currency,
        travelerCount: _travelerCount,
        cruise: _selectedCruise!,
        interests: _interests.toList(),
        transport: _transport!,
      ),
    );
    if (mounted) setState(() => _submitting = false);
  }
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              const BrandHeaderMark(),
              const Spacer(),
              Text(
                '${step + 1}/3',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                height: 4,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
                clipBehavior: Clip.antiAlias,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  width: constraints.maxWidth * (step + 1) / 3,
                  decoration: BoxDecoration(
                    color: AppColors.brand,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StepTitle extends StatelessWidget {
  const _StepTitle({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: AppColors.brand),
        ),
        const SizedBox(height: 8),
        Text(title, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 10),
        Text(
          description,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.titleSmall),
        ),
        if (value != null)
          Text(
            value!,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.textTertiary),
          ),
      ],
    );
  }
}

class _SelectionTile extends StatelessWidget {
  const _SelectionTile({
    required this.title,
    required this.trailing,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final String trailing;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.brandWeak : AppColors.surfaceSecondary,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 76,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.brand : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.labelMedium),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                trailing,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? AppColors.brand : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TravelerCounter extends StatelessWidget {
  const _TravelerCounter({
    required this.count,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int count;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      radius: 16,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '함께 여행하는 인원',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  '본인을 포함해 선택해 주세요',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDecrease,
            icon: const Icon(Icons.remove_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              disabledForegroundColor: AppColors.textTertiary.withValues(
                alpha: .3,
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              '$count명',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          IconButton(
            onPressed: onIncrease,
            icon: const Icon(Icons.add_rounded),
            color: AppColors.brand,
            style: IconButton.styleFrom(backgroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _DatePickerButton extends StatelessWidget {
  const _DatePickerButton({required this.date, required this.onTap, super.key});

  final String date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceSecondary,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.brandWeak,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.brand,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('입항 날짜', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 2),
                    Text(date, style: Theme.of(context).textTheme.titleSmall),
                  ],
                ),
              ),
              Text(
                '달력에서 선택',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.brand),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.brand,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PortSelector extends StatelessWidget {
  const _PortSelector({required this.selectedPort, required this.onChanged});

  final String selectedPort;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: ['제주항', '강정항'].map((port) {
          final selected = selectedPort == port;
          return Expanded(
            child: Material(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => onChanged(port),
                borderRadius: BorderRadius.circular(12),
                child: Center(
                  child: Text(
                    port,
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
        }).toList(),
      ),
    );
  }
}

DateTime _calendarDateForLabel(String label, DateTime today) {
  final match = RegExp(r'(\d+)월\s*(\d+)일').firstMatch(label);
  if (match == null) return today;
  final month = int.tryParse(match.group(1)!) ?? today.month;
  final day = int.tryParse(match.group(2)!) ?? today.day;
  var date = DateTime(today.year, month, day);
  if (date.isBefore(today)) date = DateTime(today.year + 1, month, day);
  return date;
}

class _CruiseCard extends StatelessWidget {
  const _CruiseCard({
    required this.cruise,
    required this.selected,
    required this.onTap,
  });

  final CruiseOption cruise;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.brandWeak : AppColors.surfaceSecondary,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.brand : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : AppColors.brandWeak,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.directions_boat_rounded,
                  color: AppColors.brand,
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
                            cruise.shipName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        if (selected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.brand,
                            size: 21,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cruise.company,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${cruise.port} · ${cruise.arrival} 입항 · ${cruise.departure} 출항',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
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

class _EmptyCruiseResult extends StatelessWidget {
  const _EmptyCruiseResult({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.directions_boat_outlined,
            size: 44,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            query.isEmpty ? '이 날짜에는 입항 예정이 없어요' : '검색한 선박을 찾지 못했어요',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '다른 날짜나 선박명으로 찾아보세요',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _IconSelectionTile extends StatelessWidget {
  const _IconSelectionTile({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.brandWeak : AppColors.surfaceSecondary,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 82,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.brand : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: selected ? AppColors.brand : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.labelMedium),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
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

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({
    required this.step,
    required this.enabled,
    required this.loading,
    required this.onPrevious,
    required this.onNext,
  });

  final int step;
  final bool enabled;
  final bool loading;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final nextButton = FilledButton(
      onPressed: enabled ? onNext : null,
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(step == 2 ? '여행 준비 시작하기' : '다음'),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_rounded, size: 19),
              ],
            ),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: step == 0
          ? SizedBox(width: double.infinity, child: nextButton)
          : Row(
              children: [
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: onPrevious,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 54),
                      backgroundColor: AppColors.surfaceSecondary,
                      side: BorderSide.none,
                    ),
                    child: const Text('이전'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(flex: 3, child: nextButton),
              ],
            ),
    );
  }
}

class AppLaunchScreen extends StatelessWidget {
  const AppLaunchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPage(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 92,
                height: 92,
                child: Image.asset('assets/images/crujeju_icon.png'),
              ),
              const SizedBox(height: 12),
              const BrandWordmark(fontSize: 22),
              const SizedBox(height: 24),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
