import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/firestore_service.dart';
import '../theme/studybuddy_theme.dart';

enum RangeType { day, week, month }

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  RangeType _range = RangeType.week;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    final db = context.read<FirestoreService>();

    final now = DateTime.now();
    final (from, to, buckets) = _rangeWindow(now, _range);

    return Scaffold(
      appBar: AppBar(title: const Text('Overzicht')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _RangeTabs(
                value: _range,
                onChanged: (r) => setState(() => _range = r),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: db.streamSessionsBetween(uid: user.uid, from: from, to: to),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final sessions = snap.data!.docs
                        .map((d) => d.data())
                        .where((m) => m['start'] != null && m['duration'] != null)
                        .toList();

                    final agg = _aggregate(sessions, buckets);

                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          _BarCard(agg: agg),
                          const SizedBox(height: 14),
                          _StatsCard(agg: agg, range: _range),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

({DateTime from, DateTime to, List<_Bucket> buckets}) _rangeWindow(DateTime now, RangeType r) {
  final today = DateTime(now.year, now.month, now.day);

  switch (r) {
    case RangeType.day:
      final from = today;
      final to = today.add(const Duration(days: 1));
      final buckets = List<_Bucket>.generate(
        24,
        (h) {
          final start = from.add(Duration(hours: h));
          final end = start.add(const Duration(hours: 1));
          return _Bucket(start: start, end: end, label: h.toString().padLeft(2, '0'));
        },
      );
      return (from: from, to: to, buckets: buckets);

    case RangeType.week:
      final from = today.subtract(const Duration(days: 6));
      final to = today.add(const Duration(days: 1));
      final fmt = DateFormat.E('nl');
      final buckets = List<_Bucket>.generate(7, (i) {
        final start = from.add(Duration(days: i));
        final end = start.add(const Duration(days: 1));
        return _Bucket(start: start, end: end, label: fmt.format(start));
      });
      return (from: from, to: to, buckets: buckets);

    case RangeType.month:
      final from = today.subtract(const Duration(days: 29));
      final to = today.add(const Duration(days: 1));
      final fmt = DateFormat.d('nl');
      final buckets = List<_Bucket>.generate(30, (i) {
        final start = from.add(Duration(days: i));
        final end = start.add(const Duration(days: 1));
        return _Bucket(start: start, end: end, label: fmt.format(start));
      });
      return (from: from, to: to, buckets: buckets);
  }
}

class _Bucket {
  final DateTime start;
  final DateTime end;
  final String label;
  const _Bucket({required this.start, required this.end, required this.label});
}

class _Agg {
  final List<_Bucket> buckets;
  final List<int> seconds; // per bucket
  final int totalSeconds;
  final int sessionCount;
  const _Agg({
    required this.buckets,
    required this.seconds,
    required this.totalSeconds,
    required this.sessionCount,
  });

  double get maxHours => seconds.isEmpty ? 1 : (seconds.reduce((a, b) => a > b ? a : b) / 3600).clamp(1, 99);
}

_Agg _aggregate(List<Map<String, dynamic>> sessions, List<_Bucket> buckets) {
  final seconds = List<int>.filled(buckets.length, 0);
  int total = 0;

  for (final s in sessions) {
    final ts = s['start'] as Timestamp;
    final start = ts.toDate();
    final dur = (s['duration'] as int);
    total += dur;

    for (var i = 0; i < buckets.length; i++) {
      final b = buckets[i];
      if (!start.isBefore(b.start) && start.isBefore(b.end)) {
        seconds[i] += dur;
        break;
      }
    }
  }

  return _Agg(
    buckets: buckets,
    seconds: seconds,
    totalSeconds: total,
    sessionCount: sessions.length,
  );
}

class _RangeTabs extends StatelessWidget {
  final RangeType value;
  final ValueChanged<RangeType> onChanged;
  const _RangeTabs({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<RangeType>(
      segments: const [
        ButtonSegment(value: RangeType.day, label: Text('Dag')),
        ButtonSegment(value: RangeType.week, label: Text('Week')),
        ButtonSegment(value: RangeType.month, label: Text('Maand')),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

class _BarCard extends StatelessWidget {
  final _Agg agg;
  const _BarCard({required this.agg});

  @override
  Widget build(BuildContext context) {
    final maxY = agg.maxHours;

    final groups = <BarChartGroupData>[];
    for (var i = 0; i < agg.seconds.length; i++) {
      final h = agg.seconds[i] / 3600.0;
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: h,
              width: 12,
              borderRadius: BorderRadius.circular(8),
              color: _pastelForIndex(i),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 240,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              barGroups: groups,
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text('${value.toStringAsFixed(0)}u'),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= agg.buckets.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(agg.buckets[i].label, style: const TextStyle(fontSize: 11)),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _pastelForIndex(int i) {
    const palette = [
      StudyBuddyTheme.peach,
      StudyBuddyTheme.pastelYellow,
      StudyBuddyTheme.pastelPink,
      StudyBuddyTheme.lavendel,
      StudyBuddyTheme.mint,
    ];
    return palette[i % palette.length];
  }
}

class _StatsCard extends StatelessWidget {
  final _Agg agg;
  final RangeType range;
  const _StatsCard({required this.agg, required this.range});

  String _fmtSeconds(int s) {
    final d = Duration(seconds: s);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}u ${m}m';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final days = range == RangeType.day ? 1 : (range == RangeType.week ? 7 : 30);
    final avgPerDay = (agg.totalSeconds / days).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _StatRow(
              icon: Icons.menu_book_rounded,
              label: 'Studietijd',
              value: _fmtSeconds(agg.totalSeconds),
            ),
            const SizedBox(height: 10),
            _StatRow(
              icon: Icons.timelapse_rounded,
              label: 'Sessies',
              value: agg.sessionCount.toString(),
            ),
            const SizedBox(height: 10),
            _StatRow(
              icon: Icons.star_rounded,
              label: 'Gem. per dag',
              value: _fmtSeconds(avgPerDay),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: StudyBuddyTheme.mint.withOpacity(0.22),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF3B3B3B)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
