import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/medicine.dart';
import '../providers/medicine_provider.dart';
import '../screens/medicines_screen.dart';

/// Card shell shared by the dashboard charts (PRD F21). The table icon swaps
/// the chart for a DataTable with the same numbers, which is the text
/// alternative for screen readers and for anyone who prefers a table.
class GlanceChartCard extends StatefulWidget {
  const GlanceChartCard({
    super.key,
    required this.title,
    required this.chart,
    required this.table,
  });

  final String title;
  final Widget chart;
  final Widget table;

  @override
  State<GlanceChartCard> createState() => _GlanceChartCardState();
}

class _GlanceChartCardState extends State<GlanceChartCard> {
  bool _showTable = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(_showTable ? Icons.bar_chart : Icons.table_chart),
                  tooltip: _showTable
                      ? l10n.glanceChartToggle
                      : l10n.glanceTableToggle,
                  onPressed: () => setState(() => _showTable = !_showTable),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _showTable ? widget.table : widget.chart,
          ],
        ),
      ),
    );
  }
}

/// Medicine stock: one row per medicine with days of stock left. Each row has
/// a marker at that medicine's refill threshold. Rows below the threshold use
/// the error colour and get a Refill action.
///
/// fl_chart 1.x has no horizontal bar mode, so the bars are drawn with plain
/// widgets. Medicines with no daily usage have no days figure and are skipped
/// with a note.
class GlanceMedicineStock extends ConsumerWidget {
  const GlanceMedicineStock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final medicines = ref.watch(medicinesProvider).value ?? const <Medicine>[];

    if (medicines.isEmpty) {
      return GlanceChartCard(
        title: l10n.glanceMedicinesTitle,
        chart: Text(l10n.medicinesEmpty),
        table: Text(l10n.medicinesEmpty),
      );
    }

    final rows = <_StockRow>[];
    for (final medicine in medicines) {
      final days = medicine.daysRemaining;
      if (days == null) continue;
      rows.add(_StockRow(
        name: medicine.name,
        days: days,
        threshold: medicine.refillThresholdDays,
      ));
    }
    final skipped = medicines.length - rows.length;
    final lowCount = rows.where((row) => row.isLow).length;

    final noDataNote = skipped > 0
        ? Text(l10n.glanceNoMedicineData(skipped))
        : null;

    if (rows.isEmpty) {
      return GlanceChartCard(
        title: l10n.glanceMedicinesTitle,
        chart: Text(l10n.glanceNoMedicineData(skipped)),
        table: Text(l10n.glanceNoMedicineData(skipped)),
      );
    }

    // Shared scale: the largest days or threshold, at least 1.
    var scale = 1;
    for (final row in rows) {
      scale = math.max(scale, math.max(row.days, row.threshold));
    }

    final chart = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: l10n.glanceMedicinesChartLabel(rows.length, lowCount),
          container: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final row in rows)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 96,
                          child: Text(
                            row.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth;
                              final barWidth = width * row.days / scale;
                              final markerX = width * row.threshold / scale;
                              final color = row.isLow
                                  ? scheme.error
                                  : scheme.primary;
                              return SizedBox(
                                height: 16,
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: scheme.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 0,
                                      top: 0,
                                      bottom: 0,
                                      width: barWidth,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: markerX - 1,
                                      top: -2,
                                      bottom: -2,
                                      width: 2,
                                      child: ColoredBox(
                                        color: scheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 28,
                          child: Text(
                            '${row.days}',
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                    if (row.isLow)
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const MedicinesScreen(),
                            ),
                          ),
                          child: Text(
                            '${l10n.glanceMedicineRefill}: ${row.name}',
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                  ],
                ),
            ],
          ),
        ),
        Text(l10n.glanceMedicinesSummary(lowCount, rows.length)),
        Text(l10n.glanceMedicineMarkerLabel),
        ?noDataNote,
      ],
    );

    final table = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              DataColumn(label: Text(l10n.glanceTableMedicine)),
              DataColumn(
                label: Text(l10n.glanceTableDaysLeft),
                numeric: true,
              ),
              DataColumn(
                label: Text(l10n.glanceTableRefillAt),
                numeric: true,
              ),
            ],
            rows: [
              for (final row in rows)
                DataRow(
                  color: row.isLow
                      ? WidgetStatePropertyAll(
                          scheme.errorContainer.withValues(alpha: 0.4),
                        )
                      : null,
                  cells: [
                    DataCell(Text(row.name)),
                    DataCell(Text('${row.days}')),
                    DataCell(Text('${row.threshold}')),
                  ],
                ),
            ],
          ),
        ),
        ?noDataNote,
      ],
    );

    return GlanceChartCard(
      title: l10n.glanceMedicinesTitle,
      chart: chart,
      table: table,
    );
  }
}

class _StockRow {
  const _StockRow({
    required this.name,
    required this.days,
    required this.threshold,
  });

  final String name;
  final int days;
  final int threshold;

  bool get isLow => days < threshold;
}
