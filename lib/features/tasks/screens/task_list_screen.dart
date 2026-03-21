import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});
  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(myTasksProvider.notifier).loadTasks());
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(myTasksProvider);
    final filters = ['all', 'todo', 'in_progress', 'review', 'done'];

    return Scaffold(
      appBar: AppBar(title: const Text('My Tasks')),
      body: Column(children: [
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: filters.length,
            itemBuilder: (ctx, i) {
              final f = filters[i];
              final selected = _filter == f;
              return GestureDetector(
                onTap: () => setState(() => _filter = f),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                  ),
                  child: Text(f.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : AppColors.textSecondary)),
                ),
              );
            },
          ),
        ),
        Expanded(child: tasksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (tasks) {
            final filtered = _filter == 'all' ? tasks : tasks.where((t) => t.status == _filter).toList();
            if (filtered.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.task_outlined, size: 60, color: AppColors.textHint),
              const SizedBox(height: 12),
              Text('No ${_filter} tasks', style: const TextStyle(color: AppColors.textSecondary)),
            ]));
            return RefreshIndicator(
              onRefresh: () => ref.read(myTasksProvider.notifier).loadTasks(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (ctx, i) => _TaskCard(task: filtered[i]),
              ),
            );
          },
        )),
      ]),
    );
  }
}

class _TaskCard extends ConsumerWidget {
  final TaskModel task;
  const _TaskCard({required this.task});

  Color get _priorityColor {
    switch (task.priority) {
      case 'urgent': return AppColors.error;
      case 'high': return AppColors.warning;
      case 'medium': return AppColors.primary;
      default: return AppColors.textSecondary;
    }
  }

  Color get _statusColor {
    switch (task.status) {
      case 'done': return AppColors.success;
      case 'in_progress': return AppColors.primary;
      case 'review': return AppColors.warning;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.go('/tasks/${task.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: task.isOverdue ? AppColors.error.withOpacity(0.3) : AppColors.divider),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: _priorityColor, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(child: Text(task.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: _statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
              child: Text(task.status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: _statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ]),
          if (task.description != null) ...[
            const SizedBox(height: 6),
            Text(task.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
          const SizedBox(height: 10),
          Row(children: [
            if (task.dueDate != null) ...[
              Icon(Icons.schedule, size: 13, color: task.isOverdue ? AppColors.error : AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(DateFormat('MMM d').format(task.dueDate!),
                  style: TextStyle(fontSize: 12, color: task.isOverdue ? AppColors.error : AppColors.textSecondary, fontWeight: task.isOverdue ? FontWeight.w600 : FontWeight.normal)),
              if (task.isOverdue) ...[const SizedBox(width: 4), const Text('• OVERDUE', style: TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.w700))],
            ],
            const Spacer(),
            _StatusDropdown(task: task),
          ]),
        ]),
      ),
    );
  }
}

class _StatusDropdown extends ConsumerWidget {
  final TaskModel task;
  const _StatusDropdown({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statuses = ['todo', 'in_progress', 'review', 'done'];
    return DropdownButton<String>(
      value: task.status,
      underline: const SizedBox(),
      isDense: true,
      style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
      items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s.replaceAll('_', ' ')))).toList(),
      onChanged: (newStatus) async {
        if (newStatus != null && newStatus != task.status) {
          await ref.read(myTasksProvider.notifier).updateStatus(task.id, newStatus);
        }
      },
    );
  }
}
