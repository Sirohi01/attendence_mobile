import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../models/leave_model.dart';
import '../providers/leave_provider.dart';

class LeaveListScreen extends ConsumerStatefulWidget {
  const LeaveListScreen({super.key});
  @override
  ConsumerState<LeaveListScreen> createState() => _LeaveListScreenState();
}

class _LeaveListScreenState extends ConsumerState<LeaveListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _tabs = ['All', 'Pending', 'Approved', 'Rejected'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(leaveListProvider.notifier).loadLeaves());
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final leavesAsync = ref.watch(leaveListProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Management'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(AppConstants.applyLeaveRoute),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Apply Leave', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: leavesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (leaves) {
          return TabBarView(
            controller: _tabCtrl,
            children: _tabs.map((tab) {
              final filtered = tab == 'All' ? leaves : leaves.where((l) => l.status == tab.toLowerCase()).toList();
              if (filtered.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.event_note_outlined, size: 60, color: AppColors.textHint),
                const SizedBox(height: 12),
                Text('No ${tab.toLowerCase()} leaves', style: const TextStyle(color: AppColors.textSecondary)),
              ]));
              return RefreshIndicator(
                onRefresh: () => ref.read(leaveListProvider.notifier).loadLeaves(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => _LeaveCard(leave: filtered[i]),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _LeaveCard extends StatelessWidget {
  final LeaveModel leave;
  const _LeaveCard({required this.leave});

  Color get _statusColor {
    switch (leave.status) {
      case 'approved': return AppColors.success;
      case 'rejected': return AppColors.error;
      case 'cancelled': return AppColors.textSecondary;
      default: return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
            child: Text(leave.leaveType.replaceAll('_', ' ').toUpperCase(),
                style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: _statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Text(leave.status.toUpperCase(),
                style: TextStyle(color: _statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.date_range, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text('${fmt.format(leave.startDate)} – ${fmt.format(leave.endDate)}',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const Spacer(),
          Text('${leave.totalDays} ${leave.totalDays == 1 ? 'day' : 'days'}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ]),
        const SizedBox(height: 8),
        Text(leave.reason, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        if (leave.rejectionReason != null) ...[
          const SizedBox(height: 6),
          Text('Reason: ${leave.rejectionReason}',
              style: const TextStyle(color: AppColors.error, fontSize: 12, fontStyle: FontStyle.italic)),
        ],
      ]),
    );
  }
}
