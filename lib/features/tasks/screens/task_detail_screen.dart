import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../models/task_model.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});
  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  TaskModel? _task;
  bool _loading = true;
  final _commentCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _loadTask(); }

  Future<void> _loadTask() async {
    try {
      final res = await ref.read(apiClientProvider).get('/tasks/${widget.taskId}');
      setState(() { _task = TaskModel.fromJson(res.data['data']); _loading = false; });
    } catch (e) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_task == null) return const Scaffold(body: Center(child: Text('Task not found')));
    final t = _task!;
    return Scaffold(
      appBar: AppBar(title: const Text('Task Detail')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text(t.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: [
          _Chip(t.priority.toUpperCase(), color: AppColors.warning),
          _Chip(t.status.replaceAll('_', ' ').toUpperCase(), color: AppColors.primary),
          if (t.isOverdue) const _Chip('OVERDUE', color: AppColors.error),
        ]),
        const SizedBox(height: 16),
        if (t.description != null) ...[
          const Text('Description', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 6),
          Text(t.description!, style: const TextStyle(color: AppColors.textSecondary, height: 1.6)),
          const SizedBox(height: 16),
        ],
        if (t.dueDate != null) ...[
          Row(children: [
            const Icon(Icons.schedule, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text('Due: ${DateFormat('MMM d, yyyy').format(t.dueDate!)}',
                style: TextStyle(color: t.isOverdue ? AppColors.error : AppColors.textSecondary)),
          ]),
          const SizedBox(height: 16),
        ],
        const Divider(),
        const SizedBox(height: 12),
        const Text('Add Comment', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: TextFormField(
            controller: _commentCtrl, maxLines: 3,
            decoration: InputDecoration(hintText: 'Write a comment...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          )),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              if (_commentCtrl.text.trim().isEmpty) return;
              await ref.read(apiClientProvider).post('/tasks/${t.id}/comments', data: {'text': _commentCtrl.text.trim()});
              _commentCtrl.clear();
              await _loadTask();
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(56, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Icon(Icons.send),
          ),
        ]),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, {required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
  );
}
