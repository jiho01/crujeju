import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.fontSize = 20});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const LinearGradient(
        colors: [AppColors.brandNavy, AppColors.brand, AppColors.ocean],
        stops: [0, .52, 1],
      ).createShader(bounds),
      child: Text(
        'CRUJEJU',
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          height: 1.1,
          fontWeight: FontWeight.w800,
          letterSpacing: .45,
        ),
      ),
    );
  }
}

class BrandHeaderMark extends StatelessWidget {
  const BrandHeaderMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 38,
          height: 38,
          child: Transform.scale(
            scale: 1.2,
            child: Image.asset('assets/images/crujeju_icon.png'),
          ),
        ),
        const SizedBox(width: 10),
        const BrandWordmark(fontSize: 18),
      ],
    );
  }
}

String formatWon(int amount) {
  final digits = amount.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return '${buffer.toString()}원';
}

void showAppSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF52D69A), size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}

class AppPage extends StatelessWidget {
  const AppPage({
    required this.child,
    super.key,
    this.backgroundColor = AppColors.surface,
    this.padding,
  });

  final Widget child;
  final Color backgroundColor;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceSecondary,
      child: Align(
        alignment: Alignment.topCenter,
        child: ColoredBox(
          color: backgroundColor,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
          ),
        ),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.action,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 8)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                visualDensity: VisualDensity.compact,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel!),
                  const Icon(Icons.chevron_right_rounded, size: 18),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.color = AppColors.surfaceSecondary,
    this.onTap,
    this.radius = 20,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color color;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              child: InkWell(onTap: onTap, child: content),
            ),
    );
  }
}

class MetaPill extends StatelessWidget {
  const MetaPill({
    required this.label,
    super.key,
    this.icon,
    this.selected = false,
    this.compact = false,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.brand : AppColors.textSecondary;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: selected ? AppColors.brandWeak : AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 14 : 16, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class RatingLabel extends StatelessWidget {
  const RatingLabel({
    required this.rating,
    super.key,
    this.reviews,
    this.light = false,
  });

  final double rating;
  final int? reviews;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final textColor = light ? Colors.white : AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 17, color: Color(0xFFFFB43B)),
        const SizedBox(width: 3),
        Text(
          '$rating${reviews == null ? '' : ' · 후기 $reviews'}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: textColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    required this.icon,
    required this.onPressed,
    super.key,
    this.backgroundColor = AppColors.surfaceSecondary,
    this.foregroundColor = AppColors.textPrimary,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 22),
      color: foregroundColor,
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor,
        fixedSize: const Size.square(44),
        minimumSize: const Size.square(44),
        maximumSize: const Size.square(44),
        padding: EdgeInsets.zero,
        shape: const CircleBorder(),
      ),
    );
  }
}

class EmptyImageFallback extends StatelessWidget {
  const EmptyImageFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.surfaceSecondary,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}

class DetailInfoRow extends StatelessWidget {
  const DetailInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.surfaceSecondary,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String countryFlag(String country) {
  return switch (country) {
    '대한민국' => '🇰🇷',
    '미국' => '🇺🇸',
    '캐나다' => '🇨🇦',
    '중국' => '🇨🇳',
    '일본' => '🇯🇵',
    '싱가포르' => '🇸🇬',
    '호주' => '🇦🇺',
    '영국' => '🇬🇧',
    '프랑스' => '🇫🇷',
    '독일' => '🇩🇪',
    _ => '🌐',
  };
}
