import 'package:flutter/material.dart';

/// Calming care pledge agreed at onboarding and accessible on Home
/// (Design Spec section 2 & 5).
class CarePledgeCard extends StatefulWidget {
  const CarePledgeCard({super.key});

  @override
  State<CarePledgeCard> createState() => _CarePledgeCardState();
}

class _CarePledgeCardState extends State<CarePledgeCard> {
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.volunteer_activism_outlined,
              color: scheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Family Care Pledge',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      InkWell(
                        onTap: () => setState(() => _isCollapsed = !_isCollapsed),
                        child: Icon(
                          _isCollapsed ? Icons.expand_more : Icons.expand_less,
                          size: 18,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  if (!_isCollapsed) ...[
                    const SizedBox(height: 4),
                    Text(
                      '“We will share the care, and tell each other when we need a break.”',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
