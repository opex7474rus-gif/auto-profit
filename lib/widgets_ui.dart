import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String text;
  final IconData icon;
  final Widget? trailing;

  const SectionTitle({
    super.key,
    required this.text,
    required this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              size: 15,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class PaddedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;

  const PaddedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(padding: padding, child: child),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Color statusColor(String status) {
  switch (status) {
    case 'Куплен':
      return const Color(0xFF3B82F6);
    case 'В ремонте':
      return const Color(0xFFF59E0B);
    case 'Готов к продаже':
      return const Color(0xFF8B5CF6);
    case 'На продаже':
      return const Color(0xFF06B6D4);
    case 'Продан':
      return const Color(0xFF10B981);
    default:
      return Colors.grey;
  }
}

IconData statusIcon(String status) {
  switch (status) {
    case 'Куплен':
      return Icons.shopping_cart_outlined;
    case 'В ремонте':
      return Icons.build_outlined;
    case 'Готов к продаже':
      return Icons.checklist_rtl;
    case 'На продаже':
      return Icons.sell_outlined;
    case 'Продан':
      return Icons.check_circle_outline;
    default:
      return Icons.circle_outlined;
  }
}

class StatusChip extends StatelessWidget {
  final String status;
  final bool compact;

  const StatusChip({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = statusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon(status), size: compact ? 11 : 13, color: c),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: c,
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool highlight;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: highlight
                  ? [color, color.withValues(alpha: 0.78)]
                  : [
                      color.withValues(alpha: isDark ? 0.18 : 0.10),
                      color.withValues(alpha: isDark ? 0.08 : 0.03),
                    ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.25 : 0.15),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: highlight
                          ? Colors.white.withValues(alpha: 0.22)
                          : color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: highlight ? Colors.white : color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: highlight
                            ? Colors.white.withValues(alpha: 0.92)
                            : theme.colorScheme.onSurfaceVariant,
                        height: 1.15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: highlight
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                    letterSpacing: -0.4,
                  ),
                  maxLines: 1,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                    color: highlight
                        ? Colors.white.withValues(alpha: 0.85)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
