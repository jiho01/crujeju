import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ai_assistant_sheet.dart';
import '../widgets/common.dart';

class PlaceDetailScreen extends StatefulWidget {
  const PlaceDetailScreen({
    required this.place,
    required this.appState,
    super.key,
  });

  final Place place;
  final AppState appState;

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final saved = widget.appState.isPlaceSaved(widget.place.id);
    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      body: AppPage(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 320,
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
                  onPressed: () => _toggleSaved(context),
                  icon: saved
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  foregroundColor: saved
                      ? AppColors.brand
                      : AppColors.textPrimary,
                  backgroundColor: Colors.white,
                  tooltip: '장소 저장',
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Hero(
                  tag: 'place-${widget.place.id}',
                  child: Image.asset(
                    widget.place.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const EmptyImageFallback(),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.place.category,
                      style: Theme.of(
                        context,
                      ).textTheme.labelMedium?.copyWith(color: AppColors.brand),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.place.name,
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                        ),
                        RatingLabel(rating: widget.place.rating),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        MetaPill(
                          label: '항구 ${widget.place.fromPort}분',
                          icon: Icons.directions_car_outlined,
                        ),
                        MetaPill(
                          label: '${widget.place.stayTime}분',
                          icon: Icons.schedule_rounded,
                        ),
                        MetaPill(
                          label: '${widget.place.crowd}한 편',
                          icon: Icons.groups_outlined,
                          selected: widget.place.crowd == '여유',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: _WideDivider()),
            SliverToBoxAdapter(
              child: _PlaceSection(
                title: '이곳은 어떤 곳인가요?',
                child: Text(
                  widget.place.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            if (widget.place.benefit != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 2),
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
                                widget.place.benefit!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: _PlaceSection(
                title: '방문 정보',
                child: Column(
                  children: [
                    DetailInfoRow(
                      icon: Icons.schedule_outlined,
                      label: '운영시간',
                      value: widget.place.hours,
                    ),
                    DetailInfoRow(
                      icon: Icons.location_on_outlined,
                      label: '위치',
                      value: widget.place.location,
                    ),
                    DetailInfoRow(
                      icon: Icons.anchor_rounded,
                      label: '강정항에서',
                      value: '차로 약 ${widget.place.fromPort}분',
                    ),
                    const DetailInfoRow(
                      icon: Icons.wb_sunny_outlined,
                      label: '추천 방문시간',
                      value: '오전 10:30–오후 2:30',
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _PlaceSection(
                title: '최근 크루즈 여행자 후기',
                child: SurfaceCard(
                  color: AppColors.surfaceSecondary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const RatingLabel(rating: 5),
                      const SizedBox(height: 10),
                      Text(
                        '사진으로 본 것보다 풍경이 더 좋았어요. 이동시간이 정확해서 짧은 기항 일정에도 부담이 없었어요.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Liam T. · 3주 전',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 112)),
          ],
        ),
      ),
      bottomNavigationBar: _PlaceBottomAction(
        saved: saved,
        onAi: () => showAiAssistant(
          context,
          initialQuestion: '${widget.place.name}을 현재 일정에 추가할 수 있어?',
        ),
        onSave: () => _toggleSaved(context),
      ),
    );
  }

  void _toggleSaved(BuildContext context) {
    widget.appState.togglePlace(widget.place.id);
    setState(() {});
    showAppSnack(
      context,
      widget.appState.isPlaceSaved(widget.place.id)
          ? '${widget.place.name}을 내 여행에 담았어요'
          : '${widget.place.name}을 내 여행에서 뺐어요',
    );
  }
}

class _PlaceSection extends StatelessWidget {
  const _PlaceSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 2),
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

class _WideDivider extends StatelessWidget {
  const _WideDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 24),
      child: SizedBox(
        height: 10,
        child: ColoredBox(color: AppColors.surfaceSecondary),
      ),
    );
  }
}

class _PlaceBottomAction extends StatelessWidget {
  const _PlaceBottomAction({
    required this.saved,
    required this.onAi,
    required this.onSave,
  });

  final bool saved;
  final VoidCallback onAi;
  final VoidCallback onSave;

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
                RoundIconButton(
                  icon: Icons.auto_awesome_rounded,
                  onPressed: onAi,
                  tooltip: 'AI에게 물어보기',
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: onSave,
                    child: Text(saved ? '내 여행에서 빼기' : '내 여행에 담기'),
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
