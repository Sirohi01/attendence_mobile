import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/attendance_provider.dart';
import '../models/attendance_model.dart';

class AttendanceHistoryScreen extends ConsumerStatefulWidget {
  const AttendanceHistoryScreen({super.key});
  @override
  ConsumerState<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends ConsumerState<AttendanceHistoryScreen> {
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() => ref.read(attendanceHistoryProvider.notifier).loadHistory(month: _month, year: _year);

  void _changeMonth(int delta) {
    setState(() {
      _month += delta;
      if (_month > 12) { _month = 1; _year++; }
      if (_month < 1) { _month = 12; _year--; }
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(attendanceHistoryProvider);
    final monthName = DateFormat('MMMM yyyy').format(DateTime(_year, _month));

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance History')),
      body: Column(children: [
        // Month selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          color: AppColors.surface,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeMonth(-1)),
            Text(monthName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeMonth(1)),
          ]),
        ),

        Expanded(child: historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (data) {
            final records = (data['records'] as List).map((e) => AttendanceRecord.fromJson(e)).toList();
            final summary = data['summary'] as Map<String, dynamic>;
            return Column(children: [
              _SummaryBar(summary: summary),
              Expanded(
                child: records.isEmpty
                    ? const Center(child: Text('No records found'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: records.length,
                        itemBuilder: (ctx, i) => _AttendanceItem(record: records[i]),
                      ),
              ),
            ]);
          },
        )),
      ]),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final Map<String, dynamic> summary;
  const _SummaryBar({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: AppColors.surface,
      child: Row(children: [
        _SummaryItem(label: 'Present', value: summary['present'].toString(), color: AppColors.presentGreen),
        _SummaryItem(label: 'Absent', value: summary['absent'].toString(), color: AppColors.absentRed),
        _SummaryItem(label: 'Late', value: summary['late'].toString(), color: AppColors.lateOrange),
        _SummaryItem(label: 'Leave', value: summary['onLeave'].toString(), color: AppColors.leaveBlue),
        _SummaryItem(label: 'Half Day', value: summary['halfDay'].toString(), color: AppColors.warning),
      ]),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
    ]),
  );
}

class _AttendanceItem extends StatelessWidget {
  final AttendanceRecord record;
  const _AttendanceItem({required this.record});

  Color get _statusColor {
    switch (record.status) {
      case 'present': return AppColors.presentGreen;
      case 'late': return AppColors.lateOrange;
      case 'absent': return AppColors.absentRed;
      case 'half_day': return AppColors.warning;
      case 'on_leave': return AppColors.leaveBlue;
      default: return AppColors.textSecondary;
    }
  }

  String get _statusLabel => record.status.replaceAll('_', ' ').toUpperCase();

  @override
  Widget build(BuildContext context) {
    final checkIn = record.checkIn?.time;
    final checkOut = record.checkOut?.time;
    final fmt = DateFormat('HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider)),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: _statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(record.date.day.toString(),
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _statusColor))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(DateFormat('EEE, MMM d').format(record.date),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: _statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
              child: Text(_statusLabel, style: TextStyle(color: _statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 4),
          if (checkIn != null)
            Text('In: ${fmt.format(checkIn)}${checkOut != null ? '   Out: ${fmt.format(checkOut)}' : ''}   •   ${record.workingHours.toStringAsFixed(1)}h',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))
          else
            const Text('No attendance recorded', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
        ])),
      ]),
    );
  }
}
